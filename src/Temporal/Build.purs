module Temporal.Build (
    Build
  , BuildF
  , Fn
  , EffectFn
  , useInput
  , output
  , runBuild
   ) where

import Prelude
  ( ($)
  , (<>)
  , (<$>)
  , class Functor
  , class Show
  , pure
  , show
  )
import Control.Monad.Error.Class (liftEither)
import Control.Monad.Free (Free, wrap, foldFree)
import Effect (Effect)
import Effect.Exception (Error, error)
import Promise (Promise, resolve) 
import Data.Bifunctor (lmap)
import Foreign (Foreign)
import Yoga.JSON (class WriteForeign, class ReadForeign, read, write)

type Fn = Foreign -> Promise Foreign

type EffectFn = Foreign -> Effect (Promise Foreign)

type EffectFn_ a = Foreign -> Effect a

data BuildF inp out next =
  UseInput Foreign (inp -> next)
  | WriteOutput out (Foreign -> next)
  | WrapPromise Foreign (Promise Foreign -> next)

derive instance Functor (BuildF inp out)

type Build inp out next = Free (BuildF inp out) next 

useInput :: forall inp out. Foreign -> Build inp out inp
useInput i = wrap $ UseInput i pure

output :: forall inp out. out -> Build inp out (Promise Foreign)
output o = wrap $ WriteOutput o (\fr -> wrap $ WrapPromise fr pure)

parseError :: forall a. Show a => a -> Error
parseError err = error $ "Failed to parse input: " <> show err

build :: forall inp out next. ReadForeign inp => WriteForeign out => BuildF inp out next -> Effect next
build = case _ of
  UseInput i reply -> reply <$> liftEither (parseError `lmap` read i)
  WriteOutput out reply -> pure $ reply $ write out
  WrapPromise outFr reply -> pure $ reply $ resolve outFr

runBuild :: forall inp out next. ReadForeign inp => WriteForeign out => Build inp out next -> Effect next
runBuild p = foldFree build p
