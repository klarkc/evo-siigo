module Node.Siigo.Activities
  ( searchSiigoCustomers
  , loadSiigoAuthHeaders
  , createSiigoInvoice
  , searchSiigoAddresses
  ) where

import Prelude
  ( ($)
  , (<>)
  , (<<<)
  , bind
  , discard
  , pure
  , show
  )
import Control.Alt ((<|>))
import Control.Alternative (guard)
import Data.Maybe (Maybe)
import Data.Array ((!!), mapMaybe)
import Data.Bifunctor (lmap)
import Data.Argonaut.Encode (toJsonString)
import Data.String (toUpper)
import Data.String.Unicode (caselessMatch)
import Effect.Exception (error)
import Promise (Promise)
import Record (union)
import Text.CSV (parse)
import Temporal.Exchange (ExchangeI, ExchangeO)
import Temporal.Logger (LoggerE(LoggerE), info, liftEither)
import Temporal.Node.Activity (liftOperation, useInput, output)
import Temporal.Node.Activity.Unsafe (unsafeRunActivity)
import Temporal.Node.Platform
  ( Method(POST)
  , fetch
  , lookupEnv
  , awaitFetch
  , awaitFetch_
  , liftLogger
  )
import Siigo
  ( SiigoAuthHeaders
  , SiigoAuthToken
  , SiigoInvoice
  , SiigoResponse
  , SiigoNewInvoice
  , SiigoAddress
  )

type SiigoError
  = { "Code" :: String
    , "Message" :: String
    , "Params" :: Array String
    , "Detail" :: String
    }

type SiigoErrorResponse
  = { "Errors" :: Array SiigoError
    }

type SiigoInput
  = ( headers :: SiigoAuthHeaders )

createSiigoInvoice :: ExchangeI -> Promise ExchangeO
createSiigoInvoice i = unsafeRunActivity @{ invoice :: SiigoNewInvoice | SiigoInput } @SiigoInvoice do
    input <- useInput i
    let
      url = buildURL $ "invoices"
      method = POST
      body = toJsonString input.invoice
      headers = union input.headers { "Content-Type": "application/json" }
      options = { method, headers, body }
    res <- liftOperation do
       liftLogger $ info $ "POST " <> url
       awaitFetch @SiigoError $ fetch url options
    output res

searchSiigoCustomers :: ExchangeI -> Promise ExchangeO
searchSiigoCustomers i = unsafeRunActivity @{ iden :: String | SiigoInput } @SiigoResponse do
    { iden, headers } <- useInput i
    let
      url = buildURL $ "customers?identification=" <> iden
      options = { headers }
    res <- liftOperation do
       liftLogger $ info $ "GET " <> url
       awaitFetch @SiigoError $ fetch url options
    output res

loadSiigoAuthHeaders :: ExchangeI -> Promise ExchangeO
loadSiigoAuthHeaders _ = unsafeRunActivity @{} @SiigoAuthHeaders do
    let url = baseUrl <> "/auth"
    authHeaders <- liftOperation do
        username <- lookupEnv "SIIGO_USERNAME"
        access_key <- lookupEnv "SIIGO_ACCESS_KEY"
        let headers = { "Content-Type": "application/json" }
            body = toJsonString { username, access_key }
            options =
              { method: POST
              , headers
              , body
              }
        liftLogger $ info $ "POST " <> url
        { access_token } :: SiigoAuthToken <- awaitFetch @SiigoErrorResponse $ fetch url options
        pure { authorization: "Bearer " <> access_token }
    output authHeaders

type SearchSiigoAddressesParams = SiigoAddress

addrFromCsvRow :: SearchSiigoAddressesParams -> Array String -> Maybe SiigoAddress 
addrFromCsvRow p r = let eq_ s = guard <<< caselessMatch s in do
 cityName <- r !! 2
 cityName `eq_` p.cityName
 stateName <- r !! 1
 stateName `eq_` p.stateName
 countryName <- r !! 0 
 countryCode <- r !! 3
 (   countryName `eq_` p.countryName
 <|> countryCode `eq_` p.countryCode
 )
 stateCode <- r !! 4
 cityCode <- r !! 5
 pure { cityName
      , stateName
      , countryName
      , countryCode: toUpper countryCode
      , stateCode
      , cityCode
      }

searchSiigoAddresses :: ExchangeI -> Promise ExchangeO
searchSiigoAddresses i = unsafeRunActivity @SearchSiigoAddressesParams @(Array SiigoAddress) do
    p <- useInput i
    csv<- liftOperation do
       url <- lookupEnv "SIIGO_ADDRESS_CSV_URL"
       res <- awaitFetch_ $ fetch url {}
       liftLogger
        $ liftEither
        $ (\err -> LoggerE $ error $ "CSV parsing failed with: " <> show err ) `lmap` parse res
    output $ mapMaybe (addrFromCsvRow p) csv

buildURL :: String -> String
buildURL path = baseUrl <> "/v1/" <> path

baseUrl :: String
baseUrl = "https://api.siigo.com"
