module Workflows where

import Prelude (($), Void)
import Effect.Unsafe (unsafePerformEffect)
import Promise (Promise)
import Promise.Aff (fromAff)
import Activities (readSale)

-- FIXME unsafePerformEffect usage
processSale :: Void -> Promise String
processSale _ = unsafePerformEffect $ fromAff readSale
