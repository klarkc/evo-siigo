module Node.Activities
  ( Activities
  , createActivities
  ) where

import Node.Evo.Activities
  ( loadEvoAuthHeaders
  , readEvoSale
  , readEvoMember
  )
import Node.Siigo.Activities
  ( loadSiigoAuthHeaders
  , searchSiigoCustomers
  , createSiigoInvoice
  , searchSiigoAddresses
  )
import Workflows (ActivitiesI)

type Activities = Record ActivitiesI

createActivities :: Activities
createActivities =
  { loadEvoAuthHeaders
  , readEvoSale
  , readEvoMember
  , loadSiigoAuthHeaders
  , searchSiigoCustomers
  , createSiigoInvoice
  , searchSiigoAddresses
  }
