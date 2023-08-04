module Temporal.Workflow
  ( ActivityOptions
  , Activities
  , ActivityFunction(..)
  , Duration
  , proxyActivities
  , proxyLocalActivities
  ) where

import Prelude ((<<<))
import Effect(Effect)
import Effect.Aff (Aff)
import Effect.Uncurried (EffectFn1, runEffectFn1)
import Effect.Class (liftEffect)
import Data.Newtype (class Newtype)

newtype ActivityFunction a b
  = ActivityFunction (a -> Aff b)

derive instance Newtype (ActivityFunction a b) _

type Activities r = Record r 

type Duration = Int

type ActivityOptions = { startToCloseTimeout :: Duration }


foreign import proxyActivitiesImpl :: forall r. EffectFn1 ActivityOptions (Activities r)

proxyActivities_ :: forall r. ActivityOptions -> Effect (Activities r)
proxyActivities_ = runEffectFn1 proxyActivitiesImpl

proxyActivities = liftEffect <<< proxyActivities_

foreign import proxyLocalActivitiesImpl :: forall r. EffectFn1 ActivityOptions (Activities r)

proxyLocalActivities_ :: forall r. ActivityOptions -> Effect (Activities r)
proxyLocalActivities_ = runEffectFn1 proxyLocalActivitiesImpl

proxyLocalActivities = liftEffect <<< proxyLocalActivities_
