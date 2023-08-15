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
  , readEvoSale
  )

type ActivitiesI_ actFr =
  ( loadEvoAuthHeaders :: actFr
  , readEvoSale :: actFr
  )
type ActivitiesI = ActivitiesI_ (ExchangeI -> Promise ExchangeO) 

type Activities = Record ActivitiesI

createActivities :: Activities
createActivities =
  { loadEvoAuthHeaders
  , readEvoSale
  }
