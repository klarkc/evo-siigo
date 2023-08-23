module Temporal.Workflow
  ( ProxyActivityOptions
  , Duration
  , ActivityJson
  , Workflow
  , WorkflowF
  , runWorkflow
  , proxyActivities
  , proxyLocalActivities
  , output
  , useInput
  , runActivity
  , liftExchange
  , liftLogger
  , liftedMaybe
  , fromNullable
  , fromMaybe
  , defaultProxyOptions
  ) where

import Prelude
  ( Unit
  , ($)
  , (<$>)
  , (<<<)
  , (*>)
  , (>>=)
  , pure
  , bind
  , show
  )
import Effect(Effect)
import Effect.Uncurried (EffectFn1, runEffectFn1)
import Effect.Aff (Aff, forkAff, joinFiber)
import Effect.Class (liftEffect) as EC
import Effect.Exception (error)
import Promise (Promise)
import Promise.Aff (toAff)
import Control.Monad.Free (Free, foldFree, liftF, hoistFree, wrap)
import Data.Maybe (Maybe(Nothing), fromMaybe) as DM
import Data.Nullable (Nullable, toMaybe)
import Data.NaturalTransformation (type (~>))
import Data.Newtype (wrap) as DN
import Data.Function.Uncurried (Fn1, runFn1)
import Data.Bifunctor (lmap)
import Data.Argonaut
  ( class EncodeJson
  , class DecodeJson
  , Json
  , encodeJson
  , decodeJson
  )
import Temporal.Exchange
  ( Exchange
  , ExchangeF
  , runExchange
  , output
  , useInput
  ) as TE
import Temporal.Logger
  ( LoggerF
  , Logger
  , runLogger
  , liftEither
  , liftMaybe
  ) as TL

type ActivityJson = Fn1 Json (Promise Json)

runActivityJson :: ActivityJson -> Json -> Promise Json
runActivityJson fn fnInp = runFn1 fn fnInp

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

data WorkflowF act inp out n
  = LiftExchange (TE.ExchangeF inp out n)
  | LiftLogger (TL.LoggerF n)
  | ProxyActivities ProxyActivityOptions (Record act -> n)
  | ProxyLocalActivities ProxyActivityOptions (Record act -> n)
  | RunActivity ActivityJson Json (Json -> n)

type Workflow act inp out n = Free (WorkflowF act inp out) n

liftExchange :: forall act inp out. TE.Exchange inp out ~> Workflow act inp out
liftExchange = hoistFree LiftExchange

liftLogger :: forall act inp out. TL.Logger ~> Workflow act inp out
liftLogger = hoistFree LiftLogger

liftedMaybe :: forall a act inp out. String -> Workflow act inp out (DM.Maybe a) -> Workflow act inp out a
liftedMaybe e m = m >>= liftLogger <<< TL.liftMaybe e

fromNullable :: forall act inp out a. a -> TL.Logger Unit -> Nullable a -> Workflow act inp out  a
fromNullable d log n = let m = toMaybe n
                        in fromMaybe d log m

fromMaybe :: forall act inp out a. a -> TL.Logger Unit -> DM.Maybe a -> Workflow act inp out  a
fromMaybe d log n = case n of
  DM.Nothing -> liftLogger log *> pure d
  _ -> pure $ DM.fromMaybe d n

output :: forall act inp out. out -> Workflow act inp out Json
output = liftExchange <<< TE.output

useInput :: forall act inp out. Json -> Workflow act inp out inp
useInput = liftExchange <<< TE.useInput

readActivityOutput :: forall act inp out actOut. DecodeJson actOut => Json -> Workflow act inp out actOut
readActivityOutput aOutFr = liftLogger
  $ TL.liftEither
  $ (DN.wrap <<< error <<< show) `lmap` decodeJson aOutFr

proxyActivities :: forall act inp out. ProxyActivityOptions -> Workflow act inp out (Record act)
proxyActivities options = wrap $ ProxyActivities options pure

proxyLocalActivities :: forall act inp out. ProxyActivityOptions -> Workflow act inp out (Record act)
proxyLocalActivities options = wrap $ ProxyLocalActivities options pure

runActivity :: forall act actInp actOut inp out. EncodeJson actInp => DecodeJson actOut => ActivityJson -> actInp -> Workflow act inp out actOut
runActivity aFr aIn = do
  let aInFr = encodeJson aIn
  wrap $ RunActivity aFr aInFr $ \aOutFr -> do
     aOut <- readActivityOutput aOutFr
     pure aOut

workflow :: forall act inp out. DecodeJson inp => EncodeJson out => WorkflowF act inp out ~> Aff
workflow = case _ of
  LiftExchange exchangeF -> TE.runExchange $ liftF exchangeF
  LiftLogger logF -> EC.liftEffect $ TL.runLogger $ liftF logF
  ProxyActivities opt reply -> EC.liftEffect $ reply <$> proxyActivities_ opt
  ProxyLocalActivities opt reply -> EC.liftEffect $ reply <$> proxyLocalActivities_ opt
  RunActivity wfAcFr wfAcIn reply -> do
     wfAcFib <- forkAff $ toAff $ runActivityJson wfAcFr wfAcIn
     wfAcFr_ <- joinFiber wfAcFib
     pure $ reply $ wfAcFr_

runWorkflow :: forall @act @inp @out. DecodeJson inp => EncodeJson out => Workflow act inp out ~> Aff
runWorkflow p = foldFree workflow p
