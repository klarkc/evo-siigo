module Workflows where

import Prelude (($), bind, pure)
import Effect.Unsafe (unsafePerformEffect)
import Effect.Class (liftEffect)
import Promise (Promise)
import Promise.Aff (fromAff, toAff)
import Temporal.Workflow (proxyActivities)
import Activities (EvoSale, options)

type SaleID
  = String

data Sale
  = SaleFromEvo EvoSale

-- FIXME unsafePerformEffect usage
processSale :: SaleID -> Promise Sale
processSale saleID =
  unsafePerformEffect
    $ fromAff do
        { readEvoSale } <- liftEffect $ proxyActivities options
        evoSale <- toAff $ readEvoSale saleID
        pure $ SaleFromEvo evoSale
