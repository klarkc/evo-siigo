module Workflows where

import Prelude (($))
import Effect.Unsafe (unsafePerformEffect)
import Promise (Promise)
import Promise.Aff (fromAff)
import Activities (SaleID, Sale, readSale)

-- FIXME unsafePerformEffect usage
processSale :: SaleID -> Promise Sale
processSale saleID = unsafePerformEffect $ fromAff $ readSale saleID
