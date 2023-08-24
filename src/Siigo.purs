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
  , SiigoPersonType(..)
  , SiigoIdenType(..)
  , SiigoCustomer
  , SiigoCustomerR
  , SiigoNewCustomer
  , SiigoNewProduct
  , SiigoProductCode
  , SiigoProductType(..)
  , SiigoProduct
  ) where

import Prelude (($), bind, pure, bottom)
import Control.Monad.Error.Class (liftEither, throwError)
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
  , JsonDecodeError(TypeMismatch, UnexpectedValue)
  )
import Data.Argonaut.Decode.Decoders (decodeString)
import Data.Argonaut.Encode.Encoders (encodeString)

type SiigoIden
  = String

type SiigoPagination
  = { total_results :: Int
    }

type SiigoInvoice
  = { id :: String }

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

data SiigoPersonType = Person | Company

instance EncodeJson SiigoPersonType where
  encodeJson Person = encodeString "Person"
  encodeJson Company = encodeString "Company"

instance DecodeJson SiigoPersonType where
  decodeJson json = do
     s <- decodeString json
     case s of
          "Person" -> pure Person
          "Company" -> pure Company
          _ -> throwError $ UnexpectedValue json

data SiigoIdenType = CedulaDeCiudadania13

instance EncodeJson SiigoIdenType where
  encodeJson CedulaDeCiudadania13 = encodeString "13"

instance DecodeJson SiigoIdenType where
  decodeJson json = do
     s <- decodeString json
     case s of
          "13" -> pure CedulaDeCiudadania13
          _ -> throwError $ UnexpectedValue json

type SiigoCustomerR
  = ( identification :: SiigoIden
    )
type SiigoCustomer
  = Record SiigoCustomerR

type SiigoNewCustomer 
  = { person_type :: SiigoPersonType
    , id_type :: SiigoIdenType
    , name :: Array String
    , address ::
        { address :: String
        , city ::
          { country_code :: String
          , state_code :: String
          , city_code :: String
          }
        }
    , phones :: Array { number :: String }
    , contacts :: Array
        { first_name :: String
        , last_name :: String
        , email :: String
        , phone :: { number :: String }
        }
    , comments :: String
    | SiigoCustomerR
    }

type SiigoProductCode
  = String

data SiigoProductType = Service

instance EncodeJson SiigoProductType where
  encodeJson Service = encodeString "Service"

instance DecodeJson SiigoProductType where
  decodeJson json = do
     s <- decodeString json
     case s of
          "Service" -> pure Service
          _ -> throwError $ UnexpectedValue json

type SiigoNewProduct 
  = { name :: String 
    , description :: String
    , account_group :: Int
    , "type" :: SiigoProductType
    }

type SiigoProduct
  = { code :: SiigoProductCode
    }
