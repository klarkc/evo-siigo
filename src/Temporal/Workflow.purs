module Temporal.Workflow
  ( ProxyActivityOptions
  , Duration
  , WorkflowBuild
  , WorkflowBuildF
  , Workflow
  , ActivityForeign
  , runWorkflowBuild
  , proxyActivities
  , proxyLocalActivities
  , output
  , useInput
  , runActivity
  , liftBuild
  , defaultProxyOptions
  ) where

import Debug (spy)
import Prelude(
($),
  (<$>),
  (<<<), pure, bind, void, flip,
  const,
  discard)
import Effect(Effect)
import Effect.Uncurried (EffectFn1, runEffectFn1)
import Effect.Exception (Error, error)
import Effect.Aff (Aff, launchAff_, forkAff, joinFiber)
import Effect.Class (liftEffect)
import Control.Monad.State (StateT, execStateT)
import Control.Monad.Error.Class (liftMaybe, liftEither)
import Promise (Rejection, Promise, then_, race, thenOrCatch)
import Promise.Aff (toAff)
import Foreign (Foreign, unsafeFromForeign)
import Control.Monad.Free (Free, foldFree, liftF, hoistFree, wrap)
import Temporal.Build (Fn, Build, BuildF, runBuild, output, useInput) as B
import Data.NaturalTransformation (type (~>))
import Data.Newtype (class Newtype, unwrap)
import Data.Maybe (Maybe(Nothing))
import Data.Either (Either(Left, Right))
import Data.Function.Uncurried (Fn0, runFn0)
import Yoga.JSON (class WriteForeign, class ReadForeign)

type Workflow = B.Fn

type ActivityForeign = Fn0 (Promise Foreign)

runActivityForeign fn = runFn0 fn

type Duration = Int

type ProxyActivityOptions = { startToCloseTimeout :: Duration }

defaultProxyOptions :: ProxyActivityOptions
defaultProxyOptions = { startToCloseTimeout: 5000 }

foreign import proxyActivitiesImpl :: forall r. EffectFn1 ProxyActivityOptions (Record r)

proxyActivities_ :: forall r. ProxyActivityOptions -> Effect (Record r)
proxyActivities_ = runEffectFn1 proxyActivitiesImpl

foreign import proxyLocalActivitiesImpl :: forall r. EffectFn1 ProxyActivityOptions (Record r)

proxyLocalActivities_ :: forall r. ProxyActivityOptions -> Effect (Record r)
proxyLocalActivities_ = runEffectFn1 proxyLocalActivitiesImpl

data WorkflowBuildF act inp out n =
  Building (B.BuildF inp out n)
  | ProxyActivities ProxyActivityOptions (Record act -> n)
  | ProxyLocalActivities ProxyActivityOptions (Record act -> n)
  | RunActivity ActivityForeign (Foreign -> n)

type WorkflowBuild act inp out n = Free (WorkflowBuildF act inp out) n

liftBuild :: forall act inp out. B.Build inp out ~> WorkflowBuild act inp out
liftBuild = hoistFree Building

output :: forall act inp out. out -> WorkflowBuild act inp out Foreign
output = liftBuild <<< B.output

useInput :: forall act inp out. Foreign -> WorkflowBuild act inp out inp
useInput = liftBuild <<< B.useInput

proxyActivities :: forall act inp out. ProxyActivityOptions -> WorkflowBuild act inp out (Record act)
proxyActivities options = wrap $ ProxyActivities options pure

proxyLocalActivities :: forall act inp out. ProxyActivityOptions -> WorkflowBuild act inp out (Record act)
proxyLocalActivities options = wrap $ ProxyLocalActivities options pure

runActivity :: forall act inp out a. ActivityForeign -> WorkflowBuild act inp out a
runActivity actFr = wrap $ RunActivity actFr (pure <<< unsafeFromForeign)

workflowBuild :: forall act inp out. ReadForeign inp => WriteForeign out => WorkflowBuildF act inp out ~> Aff
workflowBuild = case _ of
  Building buildF -> B.runBuild $ liftF buildF
  ProxyActivities opt reply -> liftEffect $ reply <$> proxyActivities_ opt
  ProxyLocalActivities opt reply -> liftEffect $ reply <$> proxyLocalActivities_ opt
  RunActivity wfAcFr reply -> do
     wfAcFib <- forkAff $ toAff $ spy "wfAc" $ runActivityForeign wfAcFr
     wfAcFr <- joinFiber wfAcFib
     pure $ reply $ spy "wfAcFr" $ wfAcFr

runWorkflowBuild :: forall @act @inp @out. ReadForeign inp => WriteForeign out => WorkflowBuild act inp out ~> Aff
runWorkflowBuild p = foldFree workflowBuild p
