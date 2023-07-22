module Temporal.Workflow (Workflow) where

import Temporal.Activity (Activity)
import Type.Proxy (Proxy)

type Workflow a = Proxy (Record a)
