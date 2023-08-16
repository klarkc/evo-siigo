module Temporal.Exchange
  ( ExchangeI
  , ExchangeO
  , Exchange
  , ExchangeF
  , useInput
  , output
  , runExchange
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
import Effect.Exception (Error, error)
import Effect.Aff
import Data.Bifunctor (lmap)
import Foreign (Foreign)
import Yoga.JSON (class WriteForeign, class ReadForeign, read, write)

type ExchangeI = Foreign
type ExchangeO = Foreign

data ExchangeF inp out next
  = UseInput ExchangeI (inp -> next)
  | WriteOutput out (ExchangeO -> next)

derive instance Functor (ExchangeF inp out)

type Exchange inp out next = Free (ExchangeF inp out) next

useInput :: forall inp out. ExchangeI -> Exchange inp out inp
useInput i = wrap $ UseInput i pure

output :: forall inp out. out -> Exchange inp out ExchangeO
output o = wrap $ WriteOutput o pure

parseError :: forall a. Show a => a -> Error
parseError err = error $ "Failed to parse input: " <> show err

exchange :: forall inp out next. ReadForeign inp => WriteForeign out => ExchangeF inp out next -> Aff next
exchange = case _ of
  UseInput i reply -> reply <$> liftEither (parseError `lmap` read i)
  WriteOutput out reply -> pure $ reply $ write out

runExchange :: forall inp out next. ReadForeign inp => WriteForeign out => Exchange inp out next -> Aff next
runExchange p = foldFree exchange p
