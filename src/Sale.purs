module Sale
  ( SaleDocument
  , Sale(..)
  ) where

import Evo (EvoSale)

type SaleDocument
  = String

data Sale
  = SaleFromEvo EvoSale
