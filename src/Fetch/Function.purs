module Fetch.Function (Fetch) where

import Effect.Aff (Aff)
import Fetch (Response)

type Fetch a
  = String -> Record a -> Aff Response
