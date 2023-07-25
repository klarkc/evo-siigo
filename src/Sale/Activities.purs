module Sale.Activities (SaleID, Sale, readSale) where

import Prelude (($), (<>), pure, discard)
import Effect.Aff (Aff)
import Effect.Console (log)
import Effect.Class (liftEffect)

type SaleID
  = String

type Sale
  = { id :: String }

readSale :: SaleID -> Aff Sale
readSale saleID = do
  liftEffect $ log $ "reading sale " <> saleID
  pure $ { id: saleID }
