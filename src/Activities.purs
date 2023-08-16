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
  , readEvoMember
  )
import Siigo.Activities
  ( loadSiigoAuthHeaders
  , searchSiigoCustomers
  )

type ActivitiesI_ actFr =
  ( loadEvoAuthHeaders :: actFr
  , readEvoSale :: actFr
  , readEvoMember :: actFr
  , loadSiigoAuthHeaders :: actFr
  , searchSiigoCustomers :: actFr
  )
type ActivitiesI = ActivitiesI_ (ExchangeI -> Promise ExchangeO) 

type Activities = Record ActivitiesI

createActivities :: Activities
createActivities =
  { loadEvoAuthHeaders
  , readEvoSale
  , readEvoMember
  , loadSiigoAuthHeaders
  , searchSiigoCustomers
  }
