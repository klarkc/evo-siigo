module Temporal.Workflow
  ( ActivityOptions
  , Activities
  , Duration
  , proxyActivities
  , proxyLocalActivities
  ) where

import Prelude ((<<<))
import Effect(Effect)
import Effect.Uncurried (EffectFn1, runEffectFn1)
import Effect.Class (liftEffect)

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
