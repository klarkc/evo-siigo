module Activities
  ( module EA
  , createActivities
  , options
  ) where

import Prelude ((<<<))
import Promise.Aff (Promise)
import Evo.Activities (EvoOptions, Fetch, EvoSaleID, EvoSale, readEvoSale) as EA
import Temporal.Workflow (ActivityOptions)
import Promise.Unsafe (unsafeFromAff)

options :: ActivityOptions
options = { startToCloseTimeout: 60000 }

-- FIXME unsafeFromAff usage
createActivities :: { evo :: EA.EvoOptions _ } -> { readEvoSale :: EA.EvoSaleID -> Promise EA.EvoSale }
createActivities { evo } =
  { readEvoSale: unsafeFromAff <<< EA.readEvoSale evo
  }
