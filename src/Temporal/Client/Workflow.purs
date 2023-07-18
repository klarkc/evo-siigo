module Temporal.Client.Workflow
  ( startWorkflow
  , WorkflowClient
  , WorkflowHandle
  , WorkflowStartOptions
  ) where

import Prelude (($))
import Effect (Effect)
import Effect.Aff (Aff)
import Promise.Aff (Promise, toAff)
import Data.Function.Uncurried (Fn3, runFn3)

data WorkflowClient

data WorkflowHandle

type WorkflowStartOptions
  = {}

foreign import startWorkflowImpl :: forall a. Fn3 WorkflowClient a WorkflowStartOptions (Promise WorkflowHandle)

startWorkflow_ :: forall a. WorkflowClient -> a -> WorkflowStartOptions -> Promise WorkflowHandle
startWorkflow_ = runFn3 startWorkflowImpl

startWorkflow :: forall a b. { workflow :: WorkflowClient | a } -> b -> WorkflowStartOptions -> Aff WorkflowHandle
startWorkflow { workflow } wfDef wfStartOpt = toAff $ startWorkflow_ workflow wfDef wfStartOpt
