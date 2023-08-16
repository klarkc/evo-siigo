module Temporal.Client.Connection
  ( connect
  , close
  , defaultConnectionOptions
  , ConnectionCtor
  , ConnectionOptions
  , Connection
  ) where

import Prelude ((<<<), Unit)
import Effect.Aff (Aff)
import Data.Function.Uncurried (Fn1, Fn2, runFn1, runFn2)
import Promise.Aff (Promise, toAff)

foreign import data ConnectionCtor :: Type

foreign import data Connection :: Type

type ConnectionOptions = {}

foreign import connectionCtor :: ConnectionCtor

foreign import connectImpl :: Fn2 ConnectionCtor ConnectionOptions (Promise Connection)

foreign import closeImpl :: Fn1 Connection (Promise Unit)

defaultConnectionOptions :: ConnectionOptions
defaultConnectionOptions = {}

connect_ :: ConnectionOptions -> Promise Connection
connect_ = runFn2 connectImpl connectionCtor

connect :: ConnectionOptions -> Aff Connection
connect = toAff <<< connect_

close_ :: Connection -> Promise Unit
close_ = runFn1 closeImpl

close :: Connection -> Aff Unit
close = toAff <<< close_
