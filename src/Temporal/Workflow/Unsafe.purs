module Temporal.Workflow.Unsafe (unsafeRunWorkflow) where

import Prelude (($))
import Temporal.Workflow (Workflow, runWorkflow)
import Temporal.Promise.Unsafe (unsafeFromAff)
import Yoga.JSON (class ReadForeign, class WriteForeign)
import Promise (class Flatten, Promise)

unsafeRunWorkflow :: forall @act @inp @out n. ReadForeign inp => Flatten n n => WriteForeign out => Workflow act inp out n -> Promise n
unsafeRunWorkflow p = unsafeFromAff $ runWorkflow p
