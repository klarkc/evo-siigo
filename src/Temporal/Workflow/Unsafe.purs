module Temporal.Workflow.Unsafe (unsafeRunWorkflowBuild ) where

import Prelude ((>>>))
import Temporal.Workflow (WorkflowBuild, runWorkflowBuild)
import Yoga.JSON (class ReadForeign, class WriteForeign)
import Effect.Unsafe (unsafePerformEffect)

unsafeRunWorkflowBuild :: forall @inp @out n. ReadForeign inp => WriteForeign out => WorkflowBuild inp out n -> n
unsafeRunWorkflowBuild = runWorkflowBuild >>> unsafePerformEffect 
