module Temporal.Logger
  ( module Exports
  , Logger
  , LoggerF
  , runLogger
  , log
  , trace
  , debug
  , info
  , warn
  , error
  ) where

import Data.Log.Level (LogLevel) as Exports
import Prelude
  ( Unit
  , ($)
  , pure
  , bind
  , discard
  , unit
  )
import Control.Monad.Free (Free, foldFree, wrap)
import Data.NaturalTransformation (type (~>))
import Data.Log.Formatter.Pretty (prettyFormatter)
import Data.Log.Level (LogLevel(..)) as DLL
import Data.Map (empty)
import Data.JSDate (now)
import Effect (Effect)
import Effect.Class (liftEffect)
import Effect.Console (log) as EC
-- TODO inject platform dependency

data LoggerF n
  = Log DLL.LogLevel String n

type Logger n
  = Free LoggerF n

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

runLogger :: Logger ~> Effect
runLogger p = foldFree logger p
