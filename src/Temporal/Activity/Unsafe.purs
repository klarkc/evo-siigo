module Temporal.Activity.Unsafe
  ( Activity
  , unsafeRunActivityM
  ) where

import Prelude ((<$>))
import Foreign (Foreign, unsafeFromForeign, unsafeToForeign)
import Effect.Aff (Aff)
import Promise.Aff (Promise)
import Promise.Unsafe (unsafeFromAff)
import Temporal.Activity.Trans (ActivityT, runActivityT)

type Activity
  = Foreign -> Promise Foreign

type ActivityM a b
  = ActivityT a Aff b

unsafeRunActivityM :: forall a b. ActivityM a b -> Activity
unsafeRunActivityM act = \i ->
  let
    p = unsafeFromForeign i

    r = unsafeToForeign <$> runActivityT act p
  in
    unsafeFromAff r
