module Temporal.Logger
  ( module Exports
  , Logger
  , LoggerF
  , LoggerE(LoggerE)
  , runLogger
  , log
  , trace
  , debug
  , info
  , warn
  , error
  , liftEither
  , liftMaybe
  , logAndThrow
  ) where

import Data.Log.Level (LogLevel) as Exports
import Prelude
  ( Unit
  , ($)
  , (*>)
  , pure
  , bind
  , discard
  , unit
  , show
  )
import Control.Monad.Free (Free, foldFree, wrap)
import Data.NaturalTransformation (type (~>))
import Data.Log.Formatter.Pretty (prettyFormatter)
import Data.Log.Level (LogLevel(..)) as DLL
import Data.Map (empty)
import Data.JSDate (now)
import Data.Maybe (Maybe(Nothing, Just))
import Data.Either (Either(Left, Right))
import Data.Newtype (class Newtype, wrap, unwrap) as DN
import Effect (Effect)
import Effect.Class (liftEffect)
import Effect.Console (log) as EC
import Effect.Exception (Error, error, throwException) as EE

newtype LoggerE = LoggerE EE.Error
derive instance DN.Newtype LoggerE _

data LoggerF n
  = Log DLL.LogLevel String n
  | Throw LoggerE

type Logger n = Free LoggerF n
--let lift = liftF $ LiftMaybe m
liftMaybe :: String -> Maybe ~> Logger
liftMaybe s Nothing = logAndThrow s
liftMaybe _ (Just v) = pure v

liftEither :: Either LoggerE ~> Logger
liftEither (Left e) = logAndThrow $ show $ DN.unwrap e
liftEither (Right v) = pure v

throw :: forall n. LoggerE -> Logger n
throw err = wrap $ Throw err 

logAndThrow :: forall n. String -> Logger n
logAndThrow s = error s *> (throw $ DN.wrap $ EE.error s)

log :: DLL.LogLevel -> String -> Logger Unit
log l s = wrap $ Log l s $ pure unit

trace :: String -> Logger Unit
trace = log DLL.Trace

debug :: String -> Logger Unit
debug = log DLL.Debug

info :: String -> Logger Unit
info = log DLL.Debug

warn :: String -> Logger Unit
warn = log DLL.Warn

error :: String -> Logger Unit
error = log DLL.Error

logger :: LoggerF ~> Effect
logger = case _ of
  Log level message next ->
    liftEffect do
      let
        tags = empty
      timestamp <- now
      s_ <- prettyFormatter { level, message, tags, timestamp }
      EC.log s_
      pure next
  Throw err -> EE.throwException $ DN.unwrap $ err

runLogger :: Logger ~> Effect
runLogger p = foldFree logger p
