module Main (main) where

import Prelude
  ( Unit
  , ($)
  , (<>)
  , bind
  , discard
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
import Activities (createActivities)
import Node.Path (resolve)
import HTTPurple
 ( class Generic
 , RouteDuplex'
 , ServerM
 , (/)
 , serve
 , segment
 , mkRoute
 , noContent
 )
import Dotenv (loadFile)

taskQueue :: String
taskQueue = "sales"

startWorker :: Aff Unit
startWorker = do
  workflowsPath <-
    liftEffect
      $ resolve [ "." ] "output/Workflows/index.js"
  workflowBundle <-
    bundleWorkflowCode
      { workflowsPath
      }
  loadFile
  worker <-
    createWorker
      { taskQueue
      , workflowBundle
      , activities: createActivities
      }
  runWorker worker

getResults :: WorkflowHandle -> Connection -> Aff Unit
getResults wfHandler con = do
  _ <- result wfHandler
  liftEffect $ log "closing"
  close con
  liftEffect $ log "done"

runTemporal :: String -> Effect Unit
runTemporal saleID =
  launchAff_ do
    con <- connect defaultConnectionOptions
    client <- liftEffect $ createClient defaultClientOptions
    wfHandler <-
      startWorkflow client "processSale"
        { taskQueue
        , workflowId: "process-sale-1"
        , args: [ saleID ]
        }
    (startWorker <> getResults wfHandler con)

data Route = ProcessSale String
derive instance Generic Route _

route :: RouteDuplex' Route
route = mkRoute
  { "ProcessSale": "process-sale" / segment
  }

main :: ServerM
main = serve { port: 8080 } { route, router }
  where
  router { route: ProcessSale saleID } = do
     liftEffect $ runTemporal saleID
     noContent
