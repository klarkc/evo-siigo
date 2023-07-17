module Main where

import Prelude (Unit, bind, pure, unit)
import Effect.Aff (launchAff_)
import Effect (Effect)
import Temporal.Client.Connection (defaultConnectionOptions, connect)

main :: Effect Unit
main =
  launchAff_ do
    _ <- connect defaultConnectionOptions
    pure unit
