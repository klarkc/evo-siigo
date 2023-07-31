module Activities
  ( module EA
  , activities
  , options
  ) where

import Prelude ((<<<))
import Promise.Aff (Promise)
import Evo.Activities (EvoSaleID, EvoSale, readEvoSale) as EA
import Temporal.Workflow (ActivityOptions)
import Promise.Unsafe (unsafeFromAff)

options :: ActivityOptions
options = { startToCloseTimeout: 60000 }

-- FIXME unsafeFromAff usage
activities :: { readEvoSale :: EA.EvoSaleID -> Promise EA.EvoSale }
activities =
  { readEvoSale: unsafeFromAff <<< EA.readEvoSale
  }
