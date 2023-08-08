module Main where

import Prelude
  ( Unit
  , ($)
  , (<>)
  , (>>=)
  , bind
  , discard
  , pure
  )
import Control.Monad.Error.Class (liftMaybe)
import Effect.Aff (Aff, launchAff_)
import Effect (Effect)
import Effect.Class (liftEffect)
import Effect.Console (log)
import Effect.Exception (error)
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
import Node.Process (lookupEnv)
import Node.Buffer as NB
import Node.Encoding as NE
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
import Fetch (fetch)
import Dotenv (loadFile)

lookupEnv_ :: String -> Effect String
lookupEnv_ var = lookupEnv var >>= \m -> liftMaybe (error $ var <> " not defined") m

taskQueue :: String
taskQueue = "sales"

base64 :: String -> Effect String
base64 str = do
      buf :: NB.Buffer <- NB.fromString str NE.ASCII
      NB.toString NE.Base64 buf

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
  auth <- liftEffect do
    username <- lookupEnv_ "EVO_USERNAME"
    password <- lookupEnv_ "EVO_PASSWORD"
    pure { username, password }
  let evo = { fetch, base64, auth }
      siigo = { fetch }
  worker <-
    createWorker
      { taskQueue
      , workflowBundle
      , activities: createActivities { evo, siigo }
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
