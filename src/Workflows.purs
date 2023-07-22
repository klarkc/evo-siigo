module Workflows where

import Activities (readSale)
import Temporal.Workflow (Workflow)
import Type.Proxy (Proxy(Proxy))
import Data.Tuple.Nested ((/\))

type Workflows a
  = Proxy (Record a)

_processSales :: Proxy "processSales"
_processSales = Proxy

processSales :: Workflow _
processSales = runActivity _readSales

workflows :: Workflows (_processSale /\ _)
workflows = Proxy
