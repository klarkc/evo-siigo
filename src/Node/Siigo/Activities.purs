module Node.Siigo.Activities
  ( searchSiigoCustomers
  , loadSiigoAuthHeaders
  , createSiigoInvoice
  ) where

import Prelude
  ( ($)
  , (<>)
  , bind
  , discard
  , pure
  )
import Data.Maybe (Maybe)
import Data.Argonaut.Encode (toJsonString)
import Promise (Promise)
import Record (union)
import Temporal.Exchange (ExchangeI, ExchangeO)
import Temporal.Logger (info)
import Temporal.Node.Activity (liftOperation, useInput, output)
import Temporal.Node.Activity.Unsafe (unsafeRunActivity)
import Temporal.Node.Platform (Method(POST), fetch, lookupEnv, awaitFetch, liftLogger)
import Siigo
  ( SiigoAuthHeaders
  , SiigoAuthToken
  , SiigoInvoice
  , SiigoResponse
  , SiigoNewInvoice
  )

type SiigoError
  = { "Code" :: String
    , "Message" :: String
    , "Params" :: Array String
    , "Detail" :: String
    }

type SiigoErrorResponse
  = { "Errors" :: Maybe (Array SiigoError)
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

buildURL :: String -> String
buildURL path = baseUrl <> "/v1/" <> path

baseUrl :: String
baseUrl = "https://api.siigo.com"
