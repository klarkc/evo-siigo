module Env.Node (lookupEnv, base64, module F) where

import Prelude (($), (>>=), (<>), bind)
import Effect (Effect)
import Effect.Exception (error)
import Control.Monad.Error.Class (liftMaybe)
import Node.Process (lookupEnv) as NP
import Node.Buffer (Buffer, fromString, toString) as NB
import Node.Encoding (Encoding(ASCII, Base64)) as NE
import Fetch (fetch) as F

lookupEnv :: String -> Effect String
lookupEnv var = NP.lookupEnv var >>= \m -> liftMaybe (error $ var <> " not defined") m

base64 :: String -> Effect String
base64 str = do
  buf :: NB.Buffer <- NB.fromString str NE.ASCII
  NB.toString NE.Base64 buf
