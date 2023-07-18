module Temporal.Client.Workflow
  ( startWorkflow
  , WorkflowClient
  , WorkflowHandle
  , WorkflowStartOptions
  ) where

import Prelude (($), bind)
import Effect.Class (liftEffect)
import Effect.Aff.Class (liftAff)
import Effect.Aff.Unlift (class MonadUnliftAff, unliftAff, askUnliftAff)
import Promise (class Flatten)
import Promise.Aff (Promise, toAff, fromAff)
import Data.Function.Uncurried (Fn3, runFn3)

data WorkflowClient

data WorkflowHandle

type WorkflowStartOptions
  = { taskQueue :: String
    , workflowId :: String
    }

foreign import startWorkflowImpl :: forall a. Fn3 WorkflowClient (Promise a) WorkflowStartOptions (Promise WorkflowHandle)

startWorkflow_ :: forall a. WorkflowClient -> Promise a -> WorkflowStartOptions -> Promise WorkflowHandle
startWorkflow_ = runFn3 startWorkflowImpl

startWorkflow :: forall a b r m. Flatten a b => MonadUnliftAff m => { workflow :: WorkflowClient | r } -> m a -> WorkflowStartOptions -> m WorkflowHandle
startWorkflow { workflow } wfDef wfStartOpt = do
  unlifter <- askUnliftAff
  wfPromise <- liftEffect $ fromAff $ unliftAff unlifter wfDef
  liftAff $ toAff $ startWorkflow_ workflow wfPromise wfStartOpt
