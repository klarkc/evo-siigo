module Temporal.Workflow.Unsafe (unsafeRunWorkflow) where

import Prelude (($))
import Temporal.Workflow (Workflow, runWorkflow)
import Temporal.Promise.Unsafe (unsafeFromAff)
import Data.Argonaut (class DecodeJson, class EncodeJson)
import Promise (class Flatten, Promise)

unsafeRunWorkflow :: forall @act @inp @out n. DecodeJson inp => Flatten n n => EncodeJson out => Workflow act inp out n -> Promise n
unsafeRunWorkflow p = unsafeFromAff $ runWorkflow p
