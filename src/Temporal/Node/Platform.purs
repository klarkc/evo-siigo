module Temporal.Node.Platform
  ( module Exports
  , Operation
  , OperationF
  , runOperation
  , liftLogger
  , lookupEnv
  , base64
  , awaitFetch
  ) where

import Data.Log.Level (LogLevel) as Exports
import Fetch (Method(..), Response, fetch) as Exports

import Prelude
  ( class Show
  , (<$>)
  , pure
  , bind
  , discard
  , ($)
  , (<>)
  , show
  )
import Control.Monad.Free (Free, foldFree, wrap, liftF, hoistFree)
import Data.NaturalTransformation (type (~>))
import Fetch (Response) as F
import Fetch.Argonaut.Json (fromJson)
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Data.Argonaut (class DecodeJson)
import Temporal.Logger
  ( LoggerF
  , Logger
  , runLogger
  , debug
  , error
  , logAndThrow
  ) as TL
-- TODO inject platform dependency
import Temporal.Node.Platform.Impl (lookupEnv, base64) as PN

data OperationF n
  = LiftLogger (TL.LoggerF n)
  | LookupEnv String (String -> n)
  | Base64 String (String -> n)
  | AwaitAff (Aff n)

type Operation n = Free OperationF n

liftLogger :: TL.Logger ~> Operation
liftLogger = hoistFree LiftLogger

awaitAff :: Aff ~> Operation
awaitAff aff = liftF $ AwaitAff  aff
  
lookupEnv :: String -> Operation String
lookupEnv s = wrap $ LookupEnv s pure

base64 :: String -> Operation String
base64 s = wrap $ Base64 s pure

awaitFetch :: forall @jsonError @json. DecodeJson json => DecodeJson jsonError => Show json => Show jsonError => Aff F.Response -> Operation json
awaitFetch res = do
  res_ <- awaitAff res
  let status = res_.status
  case status of
   200 -> do
      j <- awaitAff $ fromJson res_.json
      liftLogger $ TL.debug $ "RES " <> show j
      pure j
   s -> do
      jsonErr :: jsonError <- awaitAff $ fromJson res_.json
      liftLogger do
         TL.error $ "ERROR " <> show jsonErr
         TL.logAndThrow $ "Request failed with " <> show s <> " status"

operate :: OperationF ~> Aff
operate = case _ of
  LiftLogger logF -> liftEffect $ TL.runLogger $ liftF logF
  LookupEnv s reply -> reply <$> (liftEffect $ PN.lookupEnv s)
  Base64 s reply -> reply <$> (liftEffect $ PN.base64 s)
  AwaitAff aff -> aff

runOperation :: Operation ~> Aff
runOperation p = foldFree operate p
