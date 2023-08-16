module Siigo.Activities
  ( SiigoResponse
  , SiigoPagination
  , searchSiigoCustomers
  , loadSiigoAuthHeaders
  ) where

import Prelude
  ( ($)
  , (<>)
  , bind
  , discard
  , pure
  )
import Yoga.JSON (writeJSON)
import Promise (Promise)
import Temporal.Exchange (ExchangeI, ExchangeO)
import Temporal.Activity (liftLogger, liftOperation, useInput, output)
import Temporal.Activity.Unsafe (unsafeRunActivity)
import Temporal.Logger (info)
import Temporal.Platform (Method(POST), awaitFetch, fetch, lookupEnv)

type SiigoAuthHeaders
  = { authorization :: String }

type SiigoAuthToken
  = { access_token :: String }

type SiigoInput
  = ( headers :: SiigoAuthHeaders )

type SiigoPagination
  = { total_results :: Int
    }

type SiigoResponse
  = { pagination :: SiigoPagination
    }

searchSiigoCustomers :: ExchangeI -> Promise ExchangeO
searchSiigoCustomers i = unsafeRunActivity @{ iden :: String | SiigoInput } @SiigoResponse do
    { iden, headers } <- useInput i
    let
      url = buildURL $ "customers?identification=" <> iden
      options = { headers }
    liftLogger $ info $ "GET " <> url
    res :: SiigoResponse <- liftOperation $ awaitFetch $ fetch url options
    output res

loadSiigoAuthHeaders :: ExchangeI -> Promise ExchangeO
loadSiigoAuthHeaders _ = unsafeRunActivity @{} @SiigoAuthHeaders do
    let url = baseUrl <> "/auth"
    liftLogger $ info $ "POST " <> url
    authHeaders <- liftOperation do
        username <- lookupEnv "SIIGO_USERNAME"
        access_key <- lookupEnv "SIIGO_ACCESS_KEY"
        let headers = { "Content-Type": "application/json" }
            body = writeJSON { username, access_key }
            options =
              { method: POST
              , headers
              , body
              }
        { access_token } :: SiigoAuthToken <- awaitFetch $ fetch url options
        pure { authorization: "Bearer " <> access_token }
    output authHeaders

buildURL :: String -> String
buildURL path = baseUrl <> "/v1/" <> path

baseUrl :: String
baseUrl = "https://api.siigo.com"
