module Activities
  (
    Activities
  , ActivitiesI
  , ActivitiesI_
  , createActivities
  ) where

import Evo.Activities
  ( loadEvoAuthHeaders
  )
import Temporal.Activity (Activity)

type ActivitiesI_ actFr = ( loadEvoAuthHeaders :: actFr )
type ActivitiesI = ActivitiesI_ Activity 

type Activities = Record ActivitiesI

createActivities :: Activities
createActivities = { loadEvoAuthHeaders }
