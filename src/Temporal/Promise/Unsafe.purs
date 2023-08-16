module Temporal.Promise.Unsafe (class UnsafeWarning, unsafeFromAff) where

import Prelude ((<<<))
import Effect.Unsafe (unsafePerformEffect)
import Effect.Aff (Aff)
import Promise (class Flatten)
import Promise.Aff (Promise, fromAff)
import Prim.TypeError (class Warn, Text)

class UnsafeWarning

instance warn :: Warn (Text "Unsafe perform effect") => UnsafeWarning

unsafeFromAff :: forall a b. UnsafeWarning => Flatten a b => Aff a -> Promise b
unsafeFromAff = unsafePerformEffect <<< fromAff
