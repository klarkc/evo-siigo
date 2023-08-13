module Activities
  (
    Activities
  , createActivities
  ) where

import Evo.Activities
  ( loadEvoAuthHeaders
  )
import Temporal.Activity (Activity)

type Activities
  = { loadEvoAuthHeaders :: Activity
    }

createActivities :: Activities
createActivities = { loadEvoAuthHeaders }
