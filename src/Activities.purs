module Activities
  (
    Activities
  , ActivitiesI
  , ActivitiesI_
  , createActivities
  ) where

import Promise (Promise)
import Temporal.Exchange (ExchangeI, ExchangeO)
import Evo.Activities
  ( loadEvoAuthHeaders
  )

type ActivitiesI_ actFr = ( loadEvoAuthHeaders :: actFr )
type ActivitiesI = ActivitiesI_ (ExchangeI -> Promise ExchangeO) 

type Activities = Record ActivitiesI

createActivities :: Activities
createActivities = { loadEvoAuthHeaders }
