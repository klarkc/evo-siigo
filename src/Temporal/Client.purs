module Temporal.Client
  ( createClient
  , defaultClientOptions
  , IClientOptions
  , ClientOptions
  , Client
  , module C
  ) where

import Effect (Effect)
import Effect.Uncurried as EU
import Temporal.Client.Connection as C

foreign import data ClientCtor :: Type

foreign import data Client :: Type

type IClientOptions
  = ( connection :: C.Connection )

type ClientOptions
  = Record IClientOptions

foreign import clientCtor :: ClientCtor

foreign import defaultClientOptionsImpl :: ClientCtor -> ClientOptions

foreign import createClientImpl :: EU.EffectFn2 ClientCtor ClientOptions Client

defaultClientOptions :: ClientOptions
defaultClientOptions = defaultClientOptionsImpl clientCtor

createClient :: ClientOptions -> Effect Client
createClient = EU.runEffectFn2 createClientImpl clientCtor
