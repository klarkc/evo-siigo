module Main where

import Prelude
  ( Unit
  , ($)
  , bind
  , pure
  , unit
  )
import Effect.Aff (launchAff_)
import Effect (Effect)
import Effect.Class (liftEffect)
import Temporal.Client.Connection (defaultConnectionOptions, connect)
import Temporal.Client (createClient, defaultClientOptions)

main :: Effect Unit
main =
  launchAff_ do
    connection <- connect defaultConnectionOptions
    client <- liftEffect $ createClient defaultClientOptions
    pure unit
