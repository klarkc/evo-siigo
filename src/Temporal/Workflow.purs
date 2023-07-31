module Temporal.Workflow
  ( ActivityOptions
  , Activities
  , ActivityFunction(..)
  , Duration
  , proxyActivities
  , proxyLocalActivities
  ) where

import Effect(Effect)
import Effect.Aff (Aff)
import Effect.Uncurried (EffectFn1, runEffectFn1)
import Data.Newtype (class Newtype)

newtype ActivityFunction a b
  = ActivityFunction (a -> Aff b)

derive instance Newtype (ActivityFunction a b) _

type Activities r = Record r 

type Duration = Int

type ActivityOptions = { startToCloseTimeout :: Duration }


foreign import proxyActivitiesImpl :: forall r. EffectFn1 ActivityOptions (Activities r)

proxyActivities :: forall r. ActivityOptions -> Effect (Activities r)
proxyActivities = runEffectFn1 proxyActivitiesImpl

foreign import proxyLocalActivitiesImpl :: forall r. EffectFn1 ActivityOptions (Activities r)

proxyLocalActivities :: forall r. ActivityOptions -> Effect (Activities r)
proxyLocalActivities = runEffectFn1 proxyLocalActivitiesImpl
