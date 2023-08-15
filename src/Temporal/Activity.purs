module Temporal.Activity
  (
    Activity
  , ActivityF
  , runActivity
  , liftOperation
  , liftLogger
  , output
  , useInput
  , module E
  ) where

import Temporal.Exchange (ExchangeI, ExchangeO) as E

import Prelude (($), (<<<))
import Control.Monad.Free (Free, foldFree, liftF, hoistFree)
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Data.NaturalTransformation (type (~>))
import Yoga.JSON (class ReadForeign, class WriteForeign)
import Temporal.Exchange
  ( Exchange
  , ExchangeF
  , ExchangeI
  , ExchangeO
  , runExchange
  , output
  , useInput
  ) as TE
import Temporal.Platform (Operation, OperationF, runOperation) as TP
import Temporal.Logger
  ( LoggerF
  , Logger
  , runLogger
  ) as TL

type Activity inp out n = Free (ActivityF inp out) n

data ActivityF inp out n
  = LiftOperation (TP.OperationF n)
  | LiftLogger (TL.LoggerF n)
  | LiftExchange (TE.ExchangeF inp out n)

liftOperation :: forall inp out. TP.Operation ~> Activity inp out
liftOperation = hoistFree LiftOperation

liftExchange :: forall inp out. TE.Exchange inp out ~> Activity inp out
liftExchange = hoistFree LiftExchange

liftLogger :: forall inp out. TL.Logger ~> Activity inp out
liftLogger = hoistFree LiftLogger

output :: forall inp out. out -> Activity inp out TE.ExchangeO
output = liftExchange <<< TE.output

useInput :: forall inp out. TE.ExchangeI -> Activity inp out inp
useInput = liftExchange <<< TE.useInput

activity :: forall inp out. ReadForeign inp => WriteForeign out => ActivityF inp out ~> Aff
activity = case _ of
  LiftOperation execF -> TP.runOperation $ liftF execF
  LiftLogger logF -> liftEffect $ TL.runLogger $ liftF logF
  LiftExchange exchangeF -> TE.runExchange $ liftF exchangeF

runActivity :: forall @inp @out. ReadForeign inp => WriteForeign out => Activity inp out ~> Aff
runActivity p = foldFree activity p
