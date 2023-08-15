module Temporal.Activity
  (
  -- runActivity
  --, ActivityF
    Activity
  , ActivityBuildF
  , ActivityBuild
  ) where

import Temporal.Build (Fn, BuildF, Build)

type Activity = Fn

type ActivityBuildF inp out n = BuildF inp out n
type ActivityBuild inp out n = Build inp out n

--data ActivityF a
----  = LookupEnv String (String -> a)
--
--type Activity a
--  = Free ActivityF a
--
--runActivity :: forall a. Activity a -> Foreign -> Effect (Promise Unit)
--runActivity act i =
--  new
--    ( \resolve reject -> do
--        resolve $ spy "resolving" unit
--    )
