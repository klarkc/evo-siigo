module Workflows (processSale) where

import Debug (spy)
import Prelude
  ( ($)
  , (<>)
  , bind
  , show
  )
import Temporal.Workflow (ActivityForeign, Workflow, useInput, proxyActivities, defaultProxyOptions, output, runActivity)
import Temporal.Workflow.Unsafe (unsafeRunWorkflowBuild)
import Activities (ActivitiesI_)
import Evo.Activities (EvoAuthHeaders)
import Promise (Promise)
import Foreign (Foreign)

type SaleID = String

type EvoAuthHeaders_ = Record EvoAuthHeaders

type ActivitiesForeign = ActivitiesI_ ActivityForeign

--loadEvoAuthHeaders :: WorkflowBuild EvoAuthHeaders_ Foreign
--loadEvoAuthHeaders = ?q LoadEvoAuthHeaders

processSale :: Workflow
processSale i = unsafeRunWorkflowBuild @ActivitiesForeign @String @EvoAuthHeaders_ do
  saleID :: SaleID <- useInput i
  { loadEvoAuthHeaders } <- proxyActivities defaultProxyOptions
  authHeaders <- runActivity loadEvoAuthHeaders
  output authHeaders

--authEvo :: forall a. Workflow a ProcessSaleState Unit
--authEvo = do
--  { loadEvoAuthHeaders } <- proxyActivities options
--  authHeaders <- liftAff $ toAff $ spy "loadEvoAuthHeaders" $ loadEvoAuthHeaders 
--  pure unit
  --modify_ \r -> r { authHeaders = authHeaders }

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
--logMessage :: forall m. MonadEffect m => Message -> m Unit
--logMessage msg = liftEffect $ prettyFormatter msg >>= EC.log
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

--fetchSaleFromEvo :: Workflow SaleID ProcessSaleState Unit
--fetchSaleFromEvo = do
--  saleID <- ask
--  { readEvoSale } <- proxyActivities options
--  evoSale <- liftAff $ toAff $ readEvoSale saleID
--  let pendingRecv = filter (\r -> r.status.name == "open") evoSale.receivables
--  case length pendingRecv of
--    0 -> modify_ \r -> r { sale = Just $ SaleFromEvo evoSale }
--    _ -> Log.debug empty "Discarding sale with pending receivables"
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
