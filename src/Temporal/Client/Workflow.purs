module Temporal.Client.Workflow
  ( startWorkflow
  , result
  , WorkflowClient
  , WorkflowHandle
  , WorkflowStartOptions
  ) where

import Prelude (($), (<<<))
import Effect.Aff (Aff)
import Promise.Aff (Promise, toAff)
import Data.Function.Uncurried (Fn1, Fn3, runFn1, runFn3)

data WorkflowClient

data WorkflowHandle

type WorkflowStartOptions a =
  { taskQueue :: String
  , workflowId :: String
  , args :: Array a
  }

foreign import startWorkflowImpl :: forall a b. Fn3 WorkflowClient a (WorkflowStartOptions b) (Promise WorkflowHandle)

startWorkflow_ :: forall a b. WorkflowClient -> a -> (WorkflowStartOptions b) -> Promise WorkflowHandle
startWorkflow_ = runFn3 startWorkflowImpl

startWorkflow :: forall a b r. { workflow :: WorkflowClient | r } -> a -> (WorkflowStartOptions b) -> Aff WorkflowHandle
startWorkflow { workflow } wfType wfStartOpt =
  toAff
    $ startWorkflow_ workflow wfType wfStartOpt

foreign import resultImpl :: forall a. Fn1 WorkflowHandle (Promise a)

result_ :: forall a. WorkflowHandle -> Promise a
result_ = runFn1 resultImpl

result :: forall a. WorkflowHandle -> Aff a
result = toAff <<< result_
