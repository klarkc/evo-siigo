module Activities
  ( module EA
  , createActivities
  , options
  ) where

import Evo.Activities
  ( EvoOptions
  , EvoSaleID
  , EvoSale
  , EvoMemberID
  , EvoMember
  , EvoRequestHeaders
  , readEvoSale
  , readEvoMember
  )
  as EA
import Siigo.Activities
  ( SiigoOptions
  , searchSiigoCustomers
  )
  as SA
import Temporal.Workflow (ActivityOptions)
import Temporal.Activity (Activity)

type Activities
  = { readEvoSale :: Activity
    , readEvoMember :: Activity
    , searchSiigoCustomers :: Activity
    }

options :: ActivityOptions
options = { startToCloseTimeout: 60000 }

-- TODO remove unsafeToActivity usage
createActivities :: { evo :: EA.EvoOptions, siigo :: SA.SiigoOptions } -> Activities
createActivities { evo, siigo } =
  { readEvoSale: EA.readEvoSale evo
  , readEvoMember: EA.readEvoMember evo
  , searchSiigoCustomers: SA.searchSiigoCustomers siigo
  }
