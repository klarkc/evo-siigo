module Activities where

import Prelude (($), pure, discard)
import Effect.Console (log)
import Effect.Class (liftEffect)
import Temporal.Activity (Activity(Activity))

readSale :: Activity "readSale" String
readSale =
  Activity do
    liftEffect $ log "reading sale"
    pure "this is the sale"
