module Temporal.Workflow.Unsafe (unsafeRunWorkflowBuild ) where

import Prelude (($))
import Temporal.Workflow (WorkflowBuild, runWorkflowBuild)
import Yoga.JSON (class ReadForeign, class WriteForeign)
import Promise (class Flatten, Promise)
import Promise.Unsafe (unsafeFromAff)

unsafeRunWorkflowBuild :: forall @act @inp @out n. ReadForeign inp => Flatten n n => WriteForeign out => WorkflowBuild act inp out n -> Promise n
unsafeRunWorkflowBuild p = unsafeFromAff $ runWorkflowBuild p
