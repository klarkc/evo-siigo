module Temporal.Build.Unsafe (unsafeRunBuild) where

import Prelude (($))
import Effect.Unsafe (unsafePerformEffect)
import Temporal.Build (Build, runBuild)
import Yoga.JSON (class ReadForeign, class WriteForeign)

unsafeRunBuild  :: forall @inp @out n. ReadForeign inp => WriteForeign out => Build inp out n -> n
unsafeRunBuild p = unsafePerformEffect $ runBuild p
