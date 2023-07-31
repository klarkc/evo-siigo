module Activities
  ( module EA
  , activities
  , options
  ) where

import Prelude (($))
import Effect.Unsafe (unsafePerformEffect)
import Promise.Aff (Promise, fromAff)
import Evo.Activities (EvoSaleID, EvoSale, readEvoSale) as EA
import Temporal.Workflow (ActivityOptions)

options :: ActivityOptions
options = { startToCloseTimeout: 60000 }

-- FIXME unsafePerformEffect usage
activities :: { readEvoSale :: EA.EvoSaleID -> Promise EA.EvoSale }
activities =
  { readEvoSale: \args -> unsafePerformEffect $ fromAff $ EA.readEvoSale args
  }
