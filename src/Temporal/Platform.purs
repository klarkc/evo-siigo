module Temporal.Platform
  ( module Exports
  , Operation
  , OperationF
  , runOperation
  , lookupEnv
  , base64
  , awaitFetch
  ) where

import Data.Log.Level (LogLevel) as Exports
import Fetch (Method(..), fetch) as Exports

import Prelude
  ( ($)
  , (<$>)
  , pure
  , bind
  )
import Control.Monad.Free (Free, foldFree, wrap, liftF, hoistFree)
import Data.NaturalTransformation (type (~>))
import Fetch (Response)
import Fetch.Yoga.Json (fromJSON)
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Yoga.JSON (class ReadForeign)
-- TODO inject platform dependency
import Temporal.Platform.Fetch.Response (handleResponse)
import Temporal.Platform.Node (lookupEnv, base64) as PN

data OperationF n
  = LiftAff (Aff n)
  | LookupEnv String (String -> n)
  | Base64 String (String -> n)
  | AwaitFetchResponse (Aff Response) (Response -> n)

type Operation n = Free OperationF n

liftAff :: Aff ~> Operation
liftAff aff = hoistFree LiftAff $ liftF aff

lookupEnv :: String -> Operation String
lookupEnv s = wrap $ LookupEnv s pure

base64 :: String -> Operation String
base64 s = wrap $ Base64 s pure

awaitFetch_ :: Aff Response -> Operation Response
awaitFetch_ res = wrap $ AwaitFetchResponse res pure 

awaitFetch :: forall @json. ReadForeign json => Aff Response -> Operation json
awaitFetch res = do
  res_ <- awaitFetch_ res
  liftAff $ handleResponse res_ $ fromJSON res_.json

operate :: OperationF ~> Aff
operate = case _ of
  LiftAff aff -> aff
  LookupEnv s reply -> reply <$> (liftEffect $ PN.lookupEnv s)
  Base64 s reply -> reply <$> (liftEffect $ PN.base64 s)
  AwaitFetchResponse res reply -> reply <$> res

runOperation :: Operation ~> Aff
runOperation p = foldFree operate p
