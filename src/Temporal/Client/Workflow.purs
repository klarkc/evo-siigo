module Temporal.Client.Workflow
  ( startWorkflow
  , result
  , WorkflowClient
  , WorkflowHandle
  , WorkflowStartOptions
  ) where

import Prelude (($), (<<<), bind)
import Effect.Class (liftEffect)
import Effect.Aff (Aff)
import Effect.Aff.Class (liftAff)
import Effect.Aff.Unlift (class MonadUnliftAff, unliftAff, askUnliftAff)
import Promise (class Flatten)
import Promise.Aff (Promise, toAff, fromAff)
import Data.Function.Uncurried (Fn1, Fn3, runFn1, runFn3)
import Temporal.Workflow (Workflow)

data WorkflowClient

data WorkflowHandle

type WorkflowStartOptions
  = { taskQueue :: String
    , workflowId :: String
    }

foreign import startWorkflowImpl :: forall a. Fn3 WorkflowClient a WorkflowStartOptions (Promise WorkflowHandle)

startWorkflow_ :: forall a. WorkflowClient -> a -> WorkflowStartOptions -> Promise WorkflowHandle
startWorkflow_ = runFn3 startWorkflowImpl

startWorkflow :: forall a r. { workflow :: WorkflowClient | r } -> a -> WorkflowStartOptions -> Aff WorkflowHandle
startWorkflow { workflow } wfType wfStartOpt =
  toAff
    $ startWorkflow_ workflow wfType wfStartOpt

foreign import resultImpl :: forall a. Fn1 WorkflowHandle (Promise a)

result_ :: forall a. WorkflowHandle -> Promise a
result_ = runFn1 resultImpl

result :: forall a. WorkflowHandle -> Aff a
result = toAff <<< result_
