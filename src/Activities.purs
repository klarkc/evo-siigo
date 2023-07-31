module Activities
  ( module EA
  , createActivities
  , options
  ) where

import Prelude ((<<<))
import Promise.Aff (Promise)
import Evo.Activities (Fetch, EvoSaleID, EvoSale, readEvoSale) as EA
import Temporal.Workflow (ActivityOptions)
import Promise.Unsafe (unsafeFromAff)

options :: ActivityOptions
options = { startToCloseTimeout: 60000 }

-- FIXME unsafeFromAff usage
createActivities :: EA.Fetch _ -> { readEvoSale :: EA.EvoSaleID -> Promise EA.EvoSale }
createActivities fetch =
  { readEvoSale: unsafeFromAff <<< EA.readEvoSale fetch
  }
