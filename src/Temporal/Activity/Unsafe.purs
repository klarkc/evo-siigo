module Temporal.Activity.Unsafe (unsafeRunActivity) where

import Prelude (($))
import Temporal.Activity (Activity, runActivity)
import Yoga.JSON (class ReadForeign, class WriteForeign)
import Promise (class Flatten, Promise)
import Promise.Unsafe (unsafeFromAff)

unsafeRunActivity :: forall @inp @out n. ReadForeign inp => Flatten n n => WriteForeign out => Activity inp out n -> Promise n
unsafeRunActivity p = unsafeFromAff $ runActivity p
