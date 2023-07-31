module Promise.Unsafe (unsafeFromAff) where

import Prelude ((<<<))
import Effect.Unsafe (unsafePerformEffect)
import Effect.Aff (Aff)
import Promise (class Flatten)
import Promise.Aff (Promise, fromAff)

unsafeFromAff :: forall a b. Flatten a b => Aff a -> Promise b
unsafeFromAff = unsafePerformEffect <<< fromAff
