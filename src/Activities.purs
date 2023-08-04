module Activities
  ( module EA
  , createActivities
  , options
  ) where

import Prelude ((<<<), ($), map)
import Promise.Aff (Promise)
import Evo.Activities
  ( EvoOptions
  , Fetch
  , EvoSaleID
  , EvoSale
  , EvoMemberID
  , EvoMember
  , EvoRequestHeaders
  , readEvoSale
  , readEvoMember
  )
  as EA
import Temporal.Workflow (ActivityOptions)
import Promise.Unsafe (unsafeFromAff)
import Foreign (Foreign, unsafeToForeign)
import Effect.Aff (Aff)

type Activities
  = { readEvoSale :: EA.EvoSaleID -> Promise Foreign
    , readEvoMember :: EA.EvoMemberID -> Promise Foreign
    }

options :: ActivityOptions
options = { startToCloseTimeout: 60000 }

unsafeToActivity :: forall b t. (b -> Aff t) -> b -> Promise Foreign
unsafeToActivity fn = unsafeFromAff <<< map unsafeToForeign <<< fn

-- TODO remove unsafeToActivity usage
createActivities :: { evo :: EA.EvoOptions ( headers :: EA.EvoRequestHeaders ) } -> Activities
createActivities { evo } =
  { readEvoSale: unsafeToActivity $ EA.readEvoSale evo
  , readEvoMember: unsafeToActivity $ EA.readEvoMember evo
  }
