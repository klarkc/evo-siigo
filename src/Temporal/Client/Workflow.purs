module Temporal.Client.Workflow
  ( startWorkflow
  , WorkflowClient
  , WorkflowHandle
  , WorkflowStartOptions
  ) where

import Prelude (($))
import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Aff.Compat (EffectFnAff, fromEffectFnAff)
import Data.Function.Uncurried (Fn3, runFn3)

data WorkflowClient

data WorkflowHandle

data WorkflowStartOptions

foreign import startWorkflowImpl :: forall a. Fn3 WorkflowClient a WorkflowStartOptions (EffectFnAff WorkflowHandle)

startWorkflow :: forall a b. Record ( workflow :: WorkflowClient | a ) -> b -> WorkflowStartOptions -> Aff WorkflowHandle
startWorkflow client workflowDef startOptions = fromEffectFnAff $ runFn3 startWorkflowImpl client.workflow workflowDef startOptions
