module Temporal.Client.Connection
  ( connect
  , close
  , defaultConnectionOptions
  , ConnectionCtor
  , ConnectionOptions
  , Connection
  ) where

import Prelude (($), Unit)
import Effect.Aff (Aff)
import Effect.Aff.Compat (EffectFnAff, fromEffectFnAff)

foreign import data ConnectionCtor :: Type

foreign import data Connection :: Type

type ConnectionOptions
  = {}

foreign import connectionCtor :: ConnectionCtor

foreign import connectImpl :: ConnectionCtor -> ConnectionOptions -> EffectFnAff Connection

foreign import closeImpl :: Connection -> EffectFnAff Unit

defaultConnectionOptions :: ConnectionOptions
defaultConnectionOptions = {}

connect :: ConnectionOptions -> Aff Connection
connect opt = fromEffectFnAff $ connectImpl connectionCtor opt

close :: Connection -> Aff Unit
close con = fromEffectFnAff $ closeImpl con
