module Temporal.Node.Activity.Trans
  ( ActivityT
  , runActivityT
  , askInput
  , askEnv
  , askEnvFetch
  ) where

import Prelude (($), (>>=), pure)
import Control.Monad.Reader (ReaderT, runReaderT, ask)
import Control.Monad (class Monad)
import Control.Monad.Trans.Class (lift)

type ActivityT :: forall k. Type -> Type -> (k -> Type) -> k -> Type
type ActivityT input env m output = ReaderT env (ReaderT input m) output

runActivityT :: forall input env m output. ActivityT input env m output -> env -> input -> m output
runActivityT act env = runReaderT $ runReaderT act env

askInput :: forall input env m. Monad m => ActivityT input env m input
askInput = lift ask

askEnv :: forall input env m. Monad m => ActivityT input env m env
askEnv = ask

askEnvFetch :: forall input r f m. Monad m => ActivityT input { fetch :: f | r } m f
askEnvFetch = askEnv >>= \r -> pure r.fetch
