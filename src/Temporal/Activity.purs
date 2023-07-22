module Temporal.Activity (Activity(Activity)) where

import Effect.Aff (Aff)

data Activity :: Symbol -> Type -> Type
data Activity a b
  = Activity (Aff b)
