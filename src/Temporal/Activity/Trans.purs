module Temporal.Activity.Trans
  ( ActivityT
  , runActivityT
  , askInput
  ) where

import Control.Monad.Reader (ReaderT, runReaderT, ask)
import Control.Monad (class Monad)

type ActivityT :: forall k. Type -> (k -> Type) -> k -> Type
type ActivityT a m b
  = ReaderT a m b

runActivityT :: forall r m a. ReaderT r m a -> r -> m a
runActivityT = runReaderT

askInput :: forall a m. Monad m => ActivityT a m a
askInput = ask
