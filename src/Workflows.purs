module Workflows where

import Prelude (($), bind, pure)
import Effect.Unsafe (unsafePerformEffect)
import Promise (Promise)
import Promise.Aff (fromAff)
import Evo.Activities (EvoSale, readEvoSale)

type SaleID = String
data Sale = SaleFromEvo EvoSale

-- FIXME unsafePerformEffect usage
processSale :: SaleID -> Promise Sale
processSale saleID =
  unsafePerformEffect
    $ fromAff do
        evoSale <- readEvoSale saleID
        pure $ SaleFromEvo evoSale
