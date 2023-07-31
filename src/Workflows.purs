module Workflows where

import Prelude (($), bind, pure)
import Effect.Class (liftEffect)
import Promise (Promise)
import Promise.Aff (toAff)
import Promise.Unsafe (unsafeFromAff)
import Temporal.Workflow (proxyActivities)
import Activities (EvoSale, options)

type SaleID
  = String

data Sale
  = SaleFromEvo EvoSale

-- FIXME unsafeFromAff usage
processSale :: SaleID -> Promise Sale
processSale saleID =
  unsafeFromAff do
    { readEvoSale } <- liftEffect $ proxyActivities options
    evoSale <- toAff $ readEvoSale saleID
    pure $ SaleFromEvo evoSale
