module Workflows (processSale) where

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
import Data.Array (filter, length)
import Temporal.Workflow
  ( ActivityForeign
  , useInput
  , proxyActivities
  , defaultProxyOptions
  , output
  , runActivity
  , liftLogger
  )
import Temporal.Workflow.Unsafe (unsafeRunWorkflow)
import Temporal.Exchange (ExchangeI, ExchangeO)
import Temporal.Logger (info)
import Activities (ActivitiesI_)
import Evo.Activities (EvoSale, EvoMember)
import Siigo.Activities (SiigoResponse)

type ActivitiesForeign = ActivitiesI_ ActivityForeign

processSale :: ExchangeI -> Promise ExchangeO
processSale i = unsafeRunWorkflow @ActivitiesForeign @String @(Maybe SiigoResponse) do
  act <- proxyActivities defaultProxyOptions
  evoHeaders <- runActivity act.loadEvoAuthHeaders {}
  siigoHeaders <- runActivity act.loadSiigoAuthHeaders {}
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
      siigoRes :: SiigoResponse <- runActivity act.searchSiigoCustomers
       { iden: evoMember.document
       , headers: siigoHeaders
       }
      let isRegistered = siigoRes.pagination.total_results >= 0
      case isRegistered of
           true -> do
              liftLogger $ info "Discarding customer already registered on Siigo"
              pure $ Just siigoRes
           _ -> pure Nothing
    _ -> do
       liftLogger $ info "Discarding sale with pending receivables"
       pure Nothing
  output result


