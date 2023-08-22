module Siigo 
  ( SiigoAuthHeaders
  , SiigoAuthToken
  , SiigoResponse
  , SiigoNewInvoice
  , SiigoNewInvoiceItem
  , SiigoNewInvoicePayment
  , SiigoInvoice
  , SiigoDate(SiigoDate)
  , SiigoPagination
  , SiigoIden
  , SiigoDocID
  , SiigoSellerID 
  , SiigoPaymentID
  , SiigoAddress
  ) where

import Prelude (($), bind, pure, bottom)
import Control.Monad.Error.Class (liftEither)
import Data.Bifunctor (lmap)
import Data.List (List(Nil), (:))
import Data.Formatter.DateTime
  ( FormatterCommand(YearFull, MonthTwoDigits, DayOfMonthTwoDigits, Placeholder)
  , unformat
  , format
  )
import Data.Date (Date)
import Data.DateTime (DateTime(DateTime))
import Data.Argonaut
  ( class EncodeJson
  , class DecodeJson
  , JsonDecodeError(TypeMismatch)
  )
import Data.Argonaut.Decode.Decoders (decodeString)
import Data.Argonaut.Encode.Encoders (encodeString)

type SiigoIden
  = String

type SiigoPagination
  = { total_results :: Int
    }

type SiigoInvoice
  = {}

type SiigoAuthHeaders
  = { authorization :: String }

type SiigoAuthToken
  = { access_token :: String }

type SiigoResponse
  = { pagination :: SiigoPagination
    }

type SiigoNewInvoiceItem
  = { code :: String
    , quantity :: Int
    , price :: Number
    , discount :: Number
    }

type SiigoNewInvoicePayment
  = { id :: SiigoPaymentID
    , value :: Number
    , due_date :: SiigoDate
    }

type SiigoSellerID
  = Int

type SiigoNewInvoice
  = { document :: { id :: SiigoDocID }
    , date :: SiigoDate
    , customer :: { identification :: SiigoIden }
    , seller :: SiigoSellerID
    , items :: Array SiigoNewInvoiceItem 
    , payments :: Array SiigoNewInvoicePayment
    }

type SiigoPaymentID
  = Int

type SiigoDocID
  = Int

newtype SiigoDate
  = SiigoDate Date

dateFormatter :: List FormatterCommand
dateFormatter = YearFull
              : Placeholder "-"
              : MonthTwoDigits 
              : Placeholder "-"
              : DayOfMonthTwoDigits
              : Nil

instance DecodeJson SiigoDate where
  decodeJson json = do
     s <- decodeString json
     (DateTime d _) <- liftEither
      $ TypeMismatch `lmap` unformat dateFormatter s
     pure $ SiigoDate $ d

instance EncodeJson SiigoDate where
  encodeJson (SiigoDate d) = encodeString
    $ format dateFormatter
    $ DateTime d bottom

type SiigoAddress
  = { cityName :: String
    , stateName :: String
    , countryName :: String
    , countryCode :: String
    , stateCode :: String
    , cityCode :: String
    }
