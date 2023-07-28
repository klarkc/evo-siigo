module Evo.Activities (EvoSaleID, EvoSale, readEvoSale) where

import Prelude
  ( ($)
  , (<>)
  , discard
  , pure
  )
import Effect.Aff (Aff)
import Effect.Console (log)
import Effect.Class (liftEffect)

type EvoSaleID
  = String

type EvoSale
  = { id :: EvoSaleID }

readEvoSale :: EvoSaleID -> Aff EvoSale
readEvoSale id = do
  liftEffect $ log $ "reading evo sale " <> id
  pure $ { id }
