module Temporal.Workflow
  ( ProxyActivityOptions
  , Duration
  , ActivityForeign
  , Workflow
  , WorkflowF
  , runWorkflow
  , proxyActivities
  , proxyLocalActivities
  , output
  , useInput
  , runActivity
  , liftExchange
  , defaultProxyOptions
  ) where

import Prelude
  ( ($)
  , (<$>)
  , (<<<)
  , pure
  , bind
  )
import Effect(Effect)
import Effect.Uncurried (EffectFn1, runEffectFn1)
import Effect.Aff (Aff, forkAff, joinFiber)
import Effect.Class (liftEffect)
import Promise (Promise)
import Promise.Aff (toAff)
import Foreign (Foreign, unsafeFromForeign, unsafeToForeign)
import Control.Monad.Free (Free, foldFree, liftF, hoistFree, wrap)
import Data.NaturalTransformation (type (~>))
import Data.Function.Uncurried (Fn1, runFn1)
import Yoga.JSON (class WriteForeign, class ReadForeign)
import Temporal.Exchange
  ( Exchange
  , ExchangeF
  , runExchange
  , output
  , useInput
  ) as TE

type ActivityForeign = Fn1 Foreign (Promise Foreign)

runActivityForeign :: ActivityForeign -> Foreign -> Promise Foreign
runActivityForeign fn fnInp = runFn1 fn fnInp

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

data WorkflowF act inp out n =
  LiftExchange (TE.ExchangeF inp out n)
  | ProxyActivities ProxyActivityOptions (Record act -> n)
  | ProxyLocalActivities ProxyActivityOptions (Record act -> n)
  | RunActivity ActivityForeign Foreign (Foreign -> n)

type Workflow act inp out n = Free (WorkflowF act inp out) n

liftExchange :: forall act inp out. TE.Exchange inp out ~> Workflow act inp out
liftExchange = hoistFree LiftExchange

output :: forall act inp out. out -> Workflow act inp out Foreign
output = liftExchange <<< TE.output

useInput :: forall act inp out. Foreign -> Workflow act inp out inp
useInput = liftExchange <<< TE.useInput

proxyActivities :: forall act inp out. ProxyActivityOptions -> Workflow act inp out (Record act)
proxyActivities options = wrap $ ProxyActivities options pure

proxyLocalActivities :: forall act inp out. ProxyActivityOptions -> Workflow act inp out (Record act)
proxyLocalActivities options = wrap $ ProxyLocalActivities options pure

runActivity :: forall act actIn inp out a. ActivityForeign -> actIn -> Workflow act inp out a
runActivity actFr actIn = wrap $ RunActivity actFr (unsafeToForeign actIn) (pure <<< unsafeFromForeign)

workflow :: forall act inp out. ReadForeign inp => WriteForeign out => WorkflowF act inp out ~> Aff
workflow = case _ of
  LiftExchange exchangeF -> TE.runExchange $ liftF exchangeF
  ProxyActivities opt reply -> liftEffect $ reply <$> proxyActivities_ opt
  ProxyLocalActivities opt reply -> liftEffect $ reply <$> proxyLocalActivities_ opt
  RunActivity wfAcFr wfAcIn reply -> do
     wfAcFib <- forkAff $ toAff $ runActivityForeign wfAcFr wfAcIn
     wfAcFr_ <- joinFiber wfAcFib
     pure $ reply $ wfAcFr_

runWorkflow :: forall @act @inp @out. ReadForeign inp => WriteForeign out => Workflow act inp out ~> Aff
runWorkflow p = foldFree workflow p
