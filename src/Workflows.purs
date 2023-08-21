module Workflows
  ( ActivitiesI_
  , ActivitiesI
  , processSale
  ) where

import Prelude
  ( (==)
  , ($)
  , (>=)
  , bind
  , discard
  , show
  , pure
  )
import Promise (Promise)
import Data.Maybe (Maybe(Just, Nothing))
import Data.Array ((!!), filter, length)
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
import Siigo (SiigoAuthHeaders, SiigoResponse, SiigoNewInvoice, SiigoInvoice, SiigoDate(SiigoDate))

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
      let iden = evoMember.document
      siigoCustomers :: SiigoResponse <- runActivity act.searchSiigoCustomers
       { iden
       , headers: siigoHeaders
       }
      let isRegistered = siigoCustomers.pagination.total_results >= 0
      case isRegistered of
           true -> do
              liftLogger $ info "Discarding customer already registered on Siigo"
              pure Nothing
           _ -> do
              receivable <- liftLogger $ liftMaybe
                "Evo sale does not have any receivables"
                $ evoSale.receivables !! 0
              saleItem <- liftLogger $ liftMaybe
                "Evo sale does not have any sale itens"
                $ evoSale.saleItens !! 0
              discount <- fromMaybe
                0.0
                (warn "Evo sale discount is Nothing, reading as 0.0")
                saleItem.discount
              let (ISO (DateTime date _)) = evoSale.saleDate
                  (ISO (DateTime due_date _)) = receivable.dueDate
              siigoInvoice :: SiigoInvoice <- runActivity act.createSiigoInvoice 
                { invoice:
                    { document: { id: 994 }
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
                    , payments:
                      [ { id: 1
                        , value: receivable.ammount
                        , due_date: SiigoDate due_date
                        }
                      ]
                    } :: SiigoNewInvoice
                  , headers: siigoHeaders
                }
              pure $ Just $ siigoInvoice
    _ -> do
       liftLogger $ info "Discarding sale with pending receivables"
       pure Nothing
  output result
