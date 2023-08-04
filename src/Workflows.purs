module Workflows (Customer, processSale) where

import Prelude
  ( ($)
  , (>>=)
  , (==)
  , Unit
  , bind
  , pure
  , discard
  , unit
  )
import Control.Monad.Reader (ReaderT, runReaderT, ask)
import Control.Monad.Logger.Trans (LoggerT, runLoggerT)
import Control.Monad.Logger.Class as Log
import Control.Monad.State (StateT, modify_, get, evalStateT)
import Effect.Aff (Aff)
import Effect.Aff.Class (liftAff)
import Effect.Class (class MonadEffect, liftEffect)
import Effect.Console (log) as EC
import Promise (Promise)
import Promise.Aff (toAff)
import Promise.Unsafe (unsafeFromAff)
import Temporal.Workflow (proxyActivities)
import Activities (EvoMember, EvoSale, options)
import Data.Array (length, filter)
import Data.Maybe (Maybe(Nothing, Just))
import Data.Log.Message (Message)
import Data.Log.Formatter.Pretty (prettyFormatter)
import Data.Log.Tag (empty)

type SaleID
  = String

data Sale
  = SaleFromEvo EvoSale

data Customer
  = CustomerFromEvo EvoMember

type ProcessSaleOutput
  = Maybe Customer

type WorkflowT a s m b
  = ReaderT a (StateT s (LoggerT m)) b

type Workflow a s b
  = WorkflowT a s Aff b

runWorkflowT :: forall a b s m. MonadEffect m => WorkflowT a s m b -> a -> s -> m b
runWorkflowT w i st = runLoggerT (evalStateT (runReaderT w i) st) logMessage

logMessage :: forall m. MonadEffect m => Message -> m Unit
logMessage msg = liftEffect $ prettyFormatter msg >>= EC.log

runWorkflow :: forall a b s. Workflow a s b -> a -> s -> Aff b
runWorkflow = runWorkflowT

type ProcessSaleState
  = { sale :: Maybe Sale
    , customer :: Maybe Customer
    }

-- FIXME unsafeFromAff usage
processSale :: SaleID -> Promise ProcessSaleOutput
processSale i =
  unsafeFromAff
    $ runWorkflow processSale_ i
        { sale: Nothing
        , customer: Nothing
        }

processSale_ :: Workflow SaleID ProcessSaleState ProcessSaleOutput
processSale_ = do
  fetchSaleFromEvo
  fetchCustomerFromEvo
  { customer } <- get
  pure customer

fetchSaleFromEvo :: Workflow SaleID ProcessSaleState Unit
fetchSaleFromEvo = do
  saleID <- ask
  { readEvoSale } <- proxyActivities options
  evoSale <- liftAff $ toAff $ readEvoSale saleID
  let pendingRecv = filter (\r -> r.status.name == "open") evoSale.receivables
  case length pendingRecv of
    0 -> modify_ \r -> r { sale = Just $ SaleFromEvo evoSale }
    _ -> Log.debug empty "Discarding sale with pending receivables"

fetchCustomerFromEvo :: Workflow SaleID ProcessSaleState Unit
fetchCustomerFromEvo = do
  { readEvoMember } <- proxyActivities options
  st <- get
  case st of
    { sale: Just (SaleFromEvo evoSale) } -> do
      evoMember <- liftAff $ toAff $ readEvoMember evoSale.idMember
      modify_ \r -> r { customer = Just $ evoMember }
    _ -> pure unit
