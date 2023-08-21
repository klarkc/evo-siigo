module Temporal.Node.Activity.Unsafe (unsafeRunActivity) where

import Prelude (($))
import Temporal.Node.Activity (Activity, runActivity)
import Temporal.Promise.Unsafe (unsafeFromAff)
import Data.Argonaut (class DecodeJson, class EncodeJson)
import Promise (class Flatten, Promise)

unsafeRunActivity :: forall @inp @out n. DecodeJson inp => Flatten n n => EncodeJson out => Activity inp out n -> Promise n
unsafeRunActivity p = unsafeFromAff $ runActivity p
