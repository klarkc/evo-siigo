module Workflows (processSale) where

import Prelude
  ( (==)
  , ($)
  , bind
  , pure
  , discard
  )
import Promise (Promise)
import Data.Maybe (Maybe(Just, Nothing))
import Data.Array (filter, length)
import Temporal.Workflow
  ( ActivityForeign
  , useInput
  , proxyActivities
  , defaultProxyOptions
  , output
  , runActivity
  , liftLogger
  )
import Temporal.Workflow.Unsafe (unsafeRunWorkflow)
import Temporal.Exchange (ExchangeI, ExchangeO)
import Temporal.Logger (info)
import Activities (ActivitiesI_)
import Sale (Sale(SaleFromEvo))

--type SaleID = String

type ActivitiesForeign = ActivitiesI_ ActivityForeign

--fetchSaleFromEvo :: Workflow SaleID ProcessSaleState Unit
--fetchSaleFromEvo = do
--  saleID <- ask
--  { readEvoSale } <- proxyActivities options
--  evoSale <- liftAff $ toAff $ readEvoSale saleID
--  let pendingRecv = filter (\r -> r.status.name == "open") evoSale.receivables
--  case length pendingRecv of
--    0 -> modify_ \r -> r { sale = Just $ SaleFromEvo evoSale }
--    _ -> Log.debug empty "Discarding sale with pending receivables"

processSale :: ExchangeI -> Promise ExchangeO
processSale i = unsafeRunWorkflow @ActivitiesForeign @String @(Maybe Sale) do
  act <- proxyActivities defaultProxyOptions
  headers <- runActivity act.loadEvoAuthHeaders {}
  saleID <- useInput i
  evoSale <- runActivity act.readEvoSale { id: saleID, headers }
  let pendingRecv = filter (\r -> r.status.name == "open") evoSale.receivables
  sale <- case length pendingRecv of
    0 -> pure $ Just $ SaleFromEvo evoSale
    _ -> do
       liftLogger $ info "Discarding sale with pending receivables"
       pure Nothing
  output sale

--data Customer
--  = CustomerFromEvo EvoMember

--type ProcessSaleOutput
--  = Boolean
--
--type WorkflowT a s m b
--  = ReaderT a (StateT s (LoggerT m)) b
--
----type Workflow a s b
----  = WorkflowT a s Aff b
--
--runWorkflowT :: forall a b s m. MonadEffect m => WorkflowT a s m b -> a -> s -> m b
--runWorkflowT w i st = runLoggerT (evalStateT (runReaderT w i) st) logMessage
--
--
--runWorkflow :: forall a b s. Workflow a s b -> a -> s -> Aff b
--runWorkflow = runWorkflowT
--
--type ProcessSaleState
--  = {
--    --  sale :: Maybe Sale
--    --, customer :: Maybe Customer
--    --, isRegistered :: Boolean
--    }
--
--useSale :: Workflow SaleID ProcessSaleState Sale
--useSale = get >>= \{ sale } -> liftMaybe (error "No sale available") sale
--
--useCustomer :: Workflow SaleID ProcessSaleState Customer
--useCustomer = get >>= \{ customer } -> liftMaybe (error "No customer available") customer


  --unsafeFromAff
  --  $ runWorkflow processSale_ i
  --      {
  --      -- sale: Nothing
  --      --, customer: Nothing
  --      --, isRegistered: false
  --      }

--processSale_ :: Workflow SaleID ProcessSaleState Unit
--processSale_ = do
--  authEvo
--  --pure true
--  --fetchSaleFromEvo
--  --fetchCustomerFromEvo
--  --fetchIsRegisteredFromSiigo
--  --{ isRegistered } <- get
--  --pure isRegistered

--authEvo :: forall a. Workflow a ProcessSaleState Unit
--authEvo = do
--  { loadEvoAuthHeaders } <- proxyActivities options
--  authHeaders <- liftAff $ toAff $ spy "loadEvoAuthHeaders" $ loadEvoAuthHeaders 
--  pure unit
  --modify_ \r -> r { authHeaders = authHeaders }

--
--fetchCustomerFromEvo :: Workflow SaleID ProcessSaleState Unit
--fetchCustomerFromEvo = do
--  { readEvoMember } <- proxyActivities options
--  (SaleFromEvo evoSale) <- useSale
--  evoMember <- liftAff $ toAff $ readEvoMember evoSale.idMember
--  modify_ \r -> r { customer = Just $ (CustomerFromEvo evoMember) }
--
--fetchIsRegisteredFromSiigo :: Workflow SaleID ProcessSaleState Unit
--fetchIsRegisteredFromSiigo = do
--  (CustomerFromEvo evoMember) <- useCustomer
--  { searchSiigoCustomers } <- proxyActivities options
--  siigoCustomers <- liftAff $ toAff $ searchSiigoCustomers evoMember.document
--  let isRegistered = length siigoCustomers >= 0
--  modify_ \r -> r { isRegistered = isRegistered }
--  case isRegistered of
--       true -> Log.debug empty "Discarding customer already registered on Siigo"
--       _ -> pure unit
