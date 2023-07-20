module Workflows where

import Prelude (($), Void, Unit, show, bind, void)
import Effect.Aff (Aff)
import Effect.Console (log)
import Effect.Class (liftEffect)
import Activities (readSale)
import Data.Function.Uncurried (Fn0)

processSale :: Void -> Aff Unit
processSale _ = do
  sale <- readSale
  void $ liftEffect $ log $ show sale
