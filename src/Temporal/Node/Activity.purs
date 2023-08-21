module Temporal.Node.Activity
  (
    Activity
  , ActivityF
  , runActivity
  , liftOperation
  , output
  , useInput
  ) where

import Prelude
  ( ($)
  , (<<<)
  )
import Control.Monad.Free (Free, foldFree, liftF, hoistFree)
import Effect.Aff (Aff)
import Data.NaturalTransformation (type (~>))
import Data.Argonaut (class DecodeJson, class EncodeJson)
import Temporal.Exchange
  ( Exchange
  , ExchangeF
  , ExchangeI
  , ExchangeO
  , runExchange
  , output
  , useInput
  ) as TE
import Temporal.Node.Platform
  ( Operation
  , OperationF
  , runOperation
  ) as TP

type Activity inp out n = Free (ActivityF inp out) n

data ActivityF inp out n
  = LiftOperation (TP.OperationF n)
  | LiftExchange (TE.ExchangeF inp out n)


liftOperation :: forall inp out. TP.Operation ~> Activity inp out
liftOperation = hoistFree LiftOperation

liftExchange :: forall inp out. TE.Exchange inp out ~> Activity inp out
liftExchange = hoistFree LiftExchange

output :: forall inp out. out -> Activity inp out TE.ExchangeO
output = liftExchange <<< TE.output

useInput :: forall inp out. TE.ExchangeI -> Activity inp out inp
useInput = liftExchange <<< TE.useInput

activity :: forall inp out. DecodeJson inp => EncodeJson out => ActivityF inp out ~> Aff
activity = case _ of
  LiftOperation execF -> TP.runOperation $ liftF execF
  LiftExchange exchangeF -> TE.runExchange $ liftF exchangeF

runActivity :: forall @inp @out. DecodeJson inp => EncodeJson out => Activity inp out ~> Aff
runActivity p = foldFree activity p
