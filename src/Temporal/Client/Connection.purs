module Temporal.Client.Connection
  ( connect
  , ConnectionCtor
  , ConnectionOptions
  , Connection
  ) where

import Prelude (($))
import Effect.Aff (Aff)
import Effect.Aff.Compat (EffectFnAff, fromEffectFnAff)
import Data.Maybe (Maybe)

foreign import data ConnectionCtor :: Type

foreign import data Connection :: Type

data ConnectionOptions

foreign import connectImpl :: ConnectionCtor -> ConnectionOptions -> EffectFnAff Connection

connect :: ConnectionCtor -> ConnectionOptions -> Aff Connection
connect ctor opt = fromEffectFnAff $ connectImpl ctor opt
