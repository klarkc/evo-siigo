module Sale
  ( SaleDocument
  , Sale (SaleFromEvo)
  ) where

import Yoga.JSON (class WriteForeign, write)
import Evo (EvoSale)

type SaleDocument
  = String

data Sale
  = SaleFromEvo EvoSale

instance WriteForeign Sale where
  writeImpl (SaleFromEvo evoSale) = write evoSale
