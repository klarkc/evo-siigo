module Temporal.Exchange
  ( ExchangeI
  , ExchangeO
  , Exchange
  , ExchangeF
  , ISO(..)
  , useInput
  , output
  , runExchange
  ) where

import Prelude
  ( ($)
  , (<>)
  , (<$>)
  , class Show
  , pure
  , show
  , bind
  )
import Control.Monad.Error.Class (liftEither, liftMaybe)
import Control.Monad.Free (Free, wrap, foldFree)
import Effect.Exception (Error, error)
import Effect.Aff
import Data.Bifunctor (lmap)
import Data.Argonaut
  ( class EncodeJson
  , class DecodeJson
  , Json
  , decodeJson
  , encodeJson
  , JsonDecodeError(TypeMismatch)
  )
import Data.Argonaut.Encode.Encoders (encodeString)
import Data.Argonaut.Decode.Decoders (decodeString)
import Effect.Unsafe (unsafePerformEffect)
import Data.DateTime (DateTime)
import Data.JSDate (fromDateTime, toDateTime, toISOString, parse)
import Data.Show.Generic (genericShow)
import Data.Generic.Rep (class Generic)

type ExchangeI = Json
type ExchangeO = Json


newtype ISO = ISO DateTime

derive instance Generic ISO _

instance Show ISO where
  show = genericShow

instance EncodeJson ISO where
  encodeJson (ISO dt) = encodeString
     $ unsafePerformEffect
     $ toISOString 
     $ fromDateTime dt

instance DecodeJson ISO where
  decodeJson json = do
     s <- decodeString json
     dt <- liftMaybe (TypeMismatch s) $ toDateTime $ unsafePerformEffect $ parse s
     pure $ ISO dt

data ExchangeF inp out next
  = UseInput ExchangeI (inp -> next)
  | WriteOutput out (ExchangeO -> next)

type Exchange inp out next = Free (ExchangeF inp out) next

useInput :: forall inp out. ExchangeI -> Exchange inp out inp
useInput i = wrap $ UseInput i pure

output :: forall inp out. out -> Exchange inp out ExchangeO
output o = wrap $ WriteOutput o pure

parseError :: forall a. Show a => a -> Error
parseError err = error $ "Failed to parse input: " <> show err

exchange :: forall inp out next. DecodeJson inp => EncodeJson out => ExchangeF inp out next -> Aff next
exchange = case _ of
  UseInput i reply -> reply <$> liftEither (parseError `lmap` decodeJson i)
  WriteOutput out reply -> pure $ reply $ encodeJson $ out

runExchange :: forall inp out next. DecodeJson inp => EncodeJson out => Exchange inp out next -> Aff next
runExchange p = foldFree exchange p
