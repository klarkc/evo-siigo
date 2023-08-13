module Temporal.Workflow
  ( ProxyActivityOptions
  , Activities
  , Duration
  , WorkflowBuild
  , WorkflowBuildF
  , Workflow
  , proxyActivities
  , proxyLocalActivities
  , runWorkflowBuild
  , liftBuild
  ) where

import Prelude(($), (<<<))
import Effect(Effect)
import Effect.Uncurried (EffectFn1, runEffectFn1)
import Effect.Class (liftEffect)
import Control.Monad.Free (Free, foldFree, liftF, hoistFree)
import Temporal.Build (Fn, Build, BuildF, runBuild)
import Data.NaturalTransformation (type (~>))
import Yoga.JSON (class WriteForeign, class ReadForeign)

type Workflow = Fn

type Activities r = Record r 

type Duration = Int

type ProxyActivityOptions = { startToCloseTimeout :: Duration }


foreign import proxyActivitiesImpl :: forall r. EffectFn1 ProxyActivityOptions (Activities r)

proxyActivities_ :: forall r. ProxyActivityOptions -> Effect (Activities r)
proxyActivities_ = runEffectFn1 proxyActivitiesImpl

proxyActivities :: forall r. ProxyActivityOptions -> Effect (Activities r)
proxyActivities = liftEffect <<< proxyActivities_

foreign import proxyLocalActivitiesImpl :: forall r. EffectFn1 ProxyActivityOptions (Activities r)

proxyLocalActivities_ :: forall r. ProxyActivityOptions -> Effect (Activities r)
proxyLocalActivities_ = runEffectFn1 proxyLocalActivitiesImpl


proxyLocalActivities :: forall r. ProxyActivityOptions -> Effect (Activities r)
proxyLocalActivities = liftEffect <<< proxyLocalActivities_

data WorkflowBuildF inp out n = Building (BuildF inp out n)
type WorkflowBuild inp out n = Free (WorkflowBuildF inp out) n

liftBuild :: forall inp out. Build inp out ~> WorkflowBuild inp out
liftBuild = hoistFree Building

workflowBuild :: forall inp out. ReadForeign inp => WriteForeign out => WorkflowBuildF inp out ~> Effect
workflowBuild = case _ of
  Building buildF -> runBuild $ liftF buildF

runWorkflowBuild :: forall @inp @out. ReadForeign inp => WriteForeign out => WorkflowBuild inp out ~> Effect
runWorkflowBuild p = foldFree workflowBuild p

