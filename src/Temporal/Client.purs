module Temporal.Client
  ( createClient
  , defaultClientOptions
  , IClientOptions
  , ClientOptions
  , IClient
  , Client
  , module C
  , module W
  ) where

import Effect (Effect)
import Effect.Uncurried (EffectFn2, runEffectFn2)
import Temporal.Client.Connection
  ( Connection
  , ConnectionCtor
  , ConnectionOptions
  , close
  , connect
  , defaultConnectionOptions
  ) as C
import Temporal.Client.Workflow
  ( WorkflowClient
  , WorkflowHandle
  , WorkflowStartOptions
  , startWorkflow
  , result
  ) as W

foreign import data ClientCtor :: Type

type IClientOptions = (connection :: C.Connection)

type ClientOptions = Record IClientOptions

type IClient = (workflow :: W.WorkflowClient)

type Client = Record IClient

foreign import clientCtor :: ClientCtor

foreign import defaultClientOptionsImpl :: ClientCtor -> ClientOptions

foreign import createClientImpl :: EffectFn2 ClientCtor ClientOptions Client

defaultClientOptions :: ClientOptions
defaultClientOptions = defaultClientOptionsImpl clientCtor

createClient :: ClientOptions -> Effect Client
createClient = runEffectFn2 createClientImpl clientCtor
