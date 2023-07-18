module Main where

import Prelude
  ( Unit
  , ($)
  , bind
  , pure
  , unit
  , discard
  )
import Effect.Aff (launchAff_)
import Effect (Effect)
import Effect.Class (liftEffect)
import Temporal.Client.Connection
  ( defaultConnectionOptions
  , connect
  , close
  )
import Temporal.Client (createClient, defaultClientOptions)

main :: Effect Unit
main =
  launchAff_ do
    connection <- connect defaultConnectionOptions
    client <- liftEffect $ createClient defaultClientOptions
    close connection
    pure unit
