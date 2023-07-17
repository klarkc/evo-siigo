module Temporal.Client.Connection
  ( connect
  , defaultConnectionOptions
  , ConnectionCtor
  , ConnectionOptions
  , Connection
  ) where

import Prelude (($))
import Effect.Aff (Aff)
import Effect.Aff.Compat (EffectFnAff, fromEffectFnAff)

foreign import data ConnectionCtor :: Type

foreign import data Connection :: Type

type ConnectionOptions
  = {}

foreign import connectImpl :: ConnectionCtor -> ConnectionOptions -> EffectFnAff Connection

foreign import connectionCtor :: ConnectionCtor

defaultConnectionOptions :: ConnectionOptions
defaultConnectionOptions = {}

connect :: ConnectionOptions -> Aff Connection
connect opt = fromEffectFnAff $ connectImpl connectionCtor opt
