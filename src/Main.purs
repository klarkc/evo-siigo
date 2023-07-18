module Main where

import Prelude
  ( Unit
  , ($)
  , bind
  , pure
  , unit
  , discard
  )
import Effect.Aff (Aff, launchAff_)
import Effect (Effect)
import Effect.Class (liftEffect)
import Temporal.Client
  ( defaultConnectionOptions
  , connect
  , startWorkflow
  , close
  , createClient
  , defaultClientOptions
  )

processSale :: Aff Unit
processSale = pure unit

main :: Effect Unit
main =
  launchAff_ do
    connection <- connect defaultConnectionOptions
    client <- liftEffect $ createClient defaultClientOptions
    workflowHandler <-
      startWorkflow client processSale
        { taskQueue: "sales"
        , workflowId: "process-sale-1"
        }
    close connection
    pure unit
