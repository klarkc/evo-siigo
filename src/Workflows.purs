module Workflows
  ( ActivitiesI_
  , ActivitiesI
  , processSale
  ) where

import Prelude
  ( (==)
  , ($)
  , (<$>)
  , (>=)
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
import Temporal.Workflow
  ( ActivityJson
  , useInput
  , proxyActivities
  , defaultProxyOptions
  , output
  , runActivity
  , fromMaybe
  , liftLogger
  )
import Temporal.Workflow.Unsafe (unsafeRunWorkflow)
import Temporal.Exchange (ISO(ISO), ExchangeI, ExchangeO)
import Temporal.Logger (info, warn, liftMaybe)
import Evo (EvoAuthHeaders, EvoSale, EvoMember)
import Siigo 
  ( SiigoAuthHeaders
  , SiigoNewInvoice
  , SiigoInvoice
  , SiigoDate(SiigoDate)
  , SiigoResponse
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
  )

type ActivitiesI = ActivitiesI_ (ExchangeI -> Promise ExchangeO)

processSale :: ExchangeI -> Promise ExchangeO
processSale i = unsafeRunWorkflow @ActivitiesJson @String @(Maybe SiigoInvoice) do
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
      let isRegistered = siigoCustomers.pagination.total_results >= 0
      iden <- case isRegistered of
           true -> do
              liftLogger $ info "Customer already registered on Siigo, skipping registration"
              pure $ evoMember.document
           false -> do
              liftLogger $ info "Customer not registered on Siigo, registering"
              cellphone <- liftLogger $ liftMaybe
                "Evo member does not have valid Cellphone"
                $ head
                $ filter
                    (\c -> c.contactType == "Cellphone" && c.description /= "")
                    evoMember.contacts
              pure $ evoMember.document
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
      siigoInvoice :: SiigoInvoice <- runActivity act.createSiigoInvoice 
        { invoice:
            { document: { id: 12083 }
            , date: SiigoDate date
            , customer: { identification: iden }
            , seller: 312
            , items:
              [ { code: "c-10032124-2023-07-11-12-00-32"
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
