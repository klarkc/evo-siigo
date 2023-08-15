module Temporal.Build.Unsafe (unsafeRunBuild) where

import Prelude (($))
import Effect.Unsafe (unsafePerformEffect)
import Temporal.Build (Build, runBuild)
import Yoga.JSON (class ReadForeign, class WriteForeign)
import Foreign (Foreign)
import Promise (Promise, class Flatten)
import Promise.Unsafe (unsafeFromAff)

unsafeRunBuild  :: forall @inp @out n. ReadForeign inp => WriteForeign out => Flatten n _ => Build inp out n -> Promise Foreign
unsafeRunBuild p = unsafeFromAff $ runBuild p
