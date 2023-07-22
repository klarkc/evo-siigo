module Main where

import Prelude
  ( Unit
  , ($)
  , (<>)
  , (<$>)
  , bind
  , discard
  , pure
  , unit
  )
import Effect.Aff (Aff, launchAff_)
import Effect (Effect)
import Effect.Class (liftEffect)
import Effect.Console (log)
import Temporal.Client
  ( WorkflowHandle
  , Connection
  , defaultConnectionOptions
  , connect
  , startWorkflow
  , result
  , close
  , createClient
  , defaultClientOptions
  )
import Temporal.Worker (createWorker, runWorker, bundleWorkflowCode)
import Activities (readSale)
import Node.Path (resolve)
import Workflows (workflows)

taskQueue :: String
taskQueue = "sales"

--startWorker :: Aff Unit
--startWorker = do
--  workflowsPath <-
--    liftEffect
--      $ resolve [ "." ] "output/Workflows/index.js"
--  workflowBundle <-
--    bundleWorkflowCode
--      { workflowsPath
--      }
--  worker <-
--    createWorker
--      { taskQueue
--      , workflowBundle
--      , activities:
--          { readSale
--          }
--      }
--  runWorker worker
--
--getResults :: WorkflowHandle -> Connection -> Aff Unit
--getResults wfHandler con = do
--  res <- result wfHandler
--  liftEffect $ log ("closing: " <> res)
--  close con
--  liftEffect $ log "done"
main :: Effect Unit
main =
  launchAff_ do
    con <- connect defaultConnectionOptions
    client <- liftEffect $ createClient defaultClientOptions
    wfHandler <-
      -- we'll need to compile workflows and then import it on the JS side
      startWorkflow client processSale
        { taskQueue
        , workflowId: "process-sale-1"
        }
    pure unit

--(startWorker <> getResults wfHandler con)
