module Temporal.Platform
  ( Operation
  , OperationF
  , runOperation
  , lookupEnv
  , base64
  ) where

import Prelude (($), (<$>), pure)
import Control.Monad.Free (Free, foldFree, wrap)
import Data.NaturalTransformation (type (~>))
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
-- TODO inject platform dependency
import Platform.Node (lookupEnv, base64) as PN

data OperationF n
  = LookupEnv String (String -> n)
  | Base64 String (String -> n)

type Operation n = Free OperationF n

lookupEnv :: String -> Operation String
lookupEnv s = wrap $ LookupEnv s pure

base64 :: String -> Operation String
base64 s = wrap $ Base64 s pure

operate :: OperationF ~> Aff
operate = case _ of
  LookupEnv s reply -> reply <$> (liftEffect $ PN.lookupEnv s)
  Base64 s reply -> reply <$> (liftEffect $ PN.base64 s)

runOperation :: Operation ~> Aff
runOperation p = foldFree operate p
