module Workflows
  ( ActivitiesI_
  , ActivitiesI
  , processSale
  ) where

import Prelude
  ( (==)
  , ($)
  , (<$>)
  , (>)
  , (&&)
  , (/=)
  , bind
  , discard
  , show
  , pure
  )
import Promise (Promise)
import Data.Maybe (Maybe(Just, Nothing))
import Data.Array (filter, length, head)
import Data.DateTime(DateTime(DateTime))
import Data.String (toUpper)
import Temporal.Workflow
  ( ActivityJson
  , useInput
  , proxyActivities
  , defaultProxyOptions
  , output
  , runActivity
  , fromMaybe
  , liftLogger
  , liftedMaybe
  )
import Temporal.Workflow.Unsafe (unsafeRunWorkflow)
import Temporal.Exchange (ISO(ISO), ExchangeI, ExchangeO)
import Temporal.Logger (info, warn, liftMaybe)
import Evo
  ( EvoSaleID
  , EvoAuthHeaders
  , EvoSale
  , EvoMember
  )
import Siigo 
  ( SiigoAuthHeaders
  , SiigoNewInvoice
  , SiigoInvoice
  , SiigoDate(SiigoDate)
  , SiigoResponse
  , SiigoAddress
  , SiigoPersonType(Person)
  , SiigoIdenType(CedulaDeCiudadania13)
  , SiigoCustomer
  , SiigoNewCustomer
  , SiigoNewProduct
  , SiigoProductType(Service)
  , SiigoProduct
  )

type ActivitiesJson = ActivitiesI_ ActivityJson

type ActivitiesI_ :: forall k. k -> Row k
type ActivitiesI_ actFr =
  ( loadEvoAuthHeaders :: actFr
  , readEvoSale :: actFr
  , readEvoMember :: actFr
  , loadSiigoAuthHeaders :: actFr
  , searchSiigoCustomers :: actFr
  , createSiigoInvoice :: actFr
  , searchSiigoAddress :: actFr
  , createSiigoCustomer :: actFr
  , createSiigoProduct :: actFr
  )

type ActivitiesI = ActivitiesI_ (ExchangeI -> Promise ExchangeO)

processSale :: ExchangeI -> Promise ExchangeO
processSale i = unsafeRunWorkflow @ActivitiesJson @EvoSaleID @(Maybe SiigoInvoice) do
  act <- proxyActivities defaultProxyOptions
  evoHeaders :: EvoAuthHeaders <- runActivity act.loadEvoAuthHeaders {}
  siigoHeaders :: SiigoAuthHeaders <- runActivity act.loadSiigoAuthHeaders {}
  saleID <- useInput i
  evoSale :: EvoSale <- runActivity act.readEvoSale
    { id: saleID
    , headers: evoHeaders
    }
  let pendingRecv = filter (\r -> r.status.name == "open") evoSale.receivables
  result <- case length pendingRecv of
    0 -> do
      evoMember :: EvoMember <- runActivity act.readEvoMember
       { id: show evoSale.idMember
       , headers: evoHeaders
       }
      siigoCustomers :: SiigoResponse <- runActivity act.searchSiigoCustomers
       { iden: evoMember.document
       , headers: siigoHeaders
       }
      let isRegistered = siigoCustomers.pagination.total_results > 0
      iden <- case isRegistered of
           true -> do
              liftLogger $ info "Customer already registered on Siigo, skipping registration"
              pure $ evoMember.document
           false -> do
              liftLogger $ info "Customer not registered on Siigo, registering"
              { description: cellphone } <- liftLogger $ liftMaybe
                "Evo member does not have valid Cellphone"
                $ head
                $ filter
                    (\c -> c.contactType == "Cellphone" && c.description /= "")
                    evoMember.contacts
              { description: email } <- liftLogger $ liftMaybe
                "Evo member does not have valid Email"
                $ head
                $ filter
                    (\c -> c.contactType == "E-mail" && c.description /= "")
                    evoMember.contacts
              address :: SiigoAddress <- liftedMaybe
                "Could not find a corresponding address for the given Evo address"
                $ runActivity act.searchSiigoAddress
                  { cityName: evoMember.city
                  , stateName: evoMember.state
                  , countryName: "Colombia"
                  , countryCode: "CO"
                  }
              customer :: SiigoCustomer <- runActivity act.createSiigoCustomer
                { customer:
                    { person_type: Person
                    , id_type: CedulaDeCiudadania13
                    , identification: evoMember.document
                    , name:
                        [ evoMember.firstName
                        , evoMember.lastName
                        ]
                    , address:
                        { address: evoMember.address
                        , city:
                          { country_code: toUpper $ address.countryCode
                          , state_code: address.stateCode
                          , city_code: address.cityCode
                          }
                        }
                    , phones: [ { number: cellphone } ] 
                    , contacts:
                        [ { first_name: evoMember.firstName
                          , last_name: evoMember.lastName
                          , email
                          , phone: { number: cellphone }
                          }
                        ]
                    , comments: "Imported from EVO"
                    } :: SiigoNewCustomer
                , headers: siigoHeaders
                }
              pure customer.identification
      saleItem <- liftLogger $ liftMaybe
        "Evo sale does not have any sale itens"
        $ head
        $ evoSale.saleItens
      discount <- fromMaybe
        0.0
        (warn "Evo sale discount is Nothing, reading as 0.0")
        saleItem.discount
      let (ISO (DateTime date _)) = evoSale.saleDate
          payments = (\{ ammount: value, dueDate: (ISO (DateTime d _))} -> {
            id: 2782,
            due_date: SiigoDate d,
            value
          }) <$> evoSale.receivables
      product :: SiigoProduct <- runActivity act.createSiigoProduct 
        { product:
            { name: saleItem.item
            , description: saleItem.description
            , account_group: 620
            , type: Service
            } :: SiigoNewProduct
          , headers: siigoHeaders
        }
      siigoInvoice :: SiigoInvoice <- runActivity act.createSiigoInvoice 
        { invoice:
            { document: { id: 12083 }
            , date: SiigoDate date
            , customer: { identification: iden }
            , seller: 312
            , items:
              [ { code: product.code
                , quantity: saleItem.quantity
                , price: saleItem.itemValue
                , discount
                }
              ]
            , payments
            } :: SiigoNewInvoice
          , headers: siigoHeaders
        }
      pure $ Just $ siigoInvoice
    _ -> do
       liftLogger $ info "Discarding sale with pending receivables"
       pure Nothing
  output result
