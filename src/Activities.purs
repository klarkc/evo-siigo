module Activities where

import Prelude (($), pure, discard)
import Effect.Aff (Aff)
import Effect.Console (log)
import Effect.Class (liftEffect)

readSale :: Aff String
readSale = do
  liftEffect $ log "reading sale"
  pure "this is the sale"
