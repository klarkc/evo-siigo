module Siigo.Activities
  ( SiigoOptions
  , SiigoRequestHeaders
  , SiigoIden
  , SiigoCustomer
  , searchSiigoCustomers
  ) where

import Prelude
  ( ($)
  , (<>)
  , show
  , discard
  , bind
  , pure
  )
import Fetch.Function (Fetch)
import Fetch.Response (handleResponse)
import Fetch.Yoga.Json (fromJSON)
import Effect.Aff.Class (liftAff)
import Effect.Class (liftEffect)
import Effect.Console (log)
import Temporal.Activity (Activity, askInput, unsafeRunActivityM)

type SiigoOptions
  = { fetch :: Fetch ( headers :: SiigoRequestHeaders )
    }

type SiigoRequestHeaders
  = {}

type SiigoCustomer
  = {}

type SiigoIden
  = String

searchSiigoCustomers :: SiigoOptions -> Activity
searchSiigoCustomers { fetch } = unsafeRunActivityM do
  iden :: SiigoIden <- askInput
  let
    url = buildURL $ "customers?identification=" <> show iden

    options = { headers: {} }
  customers :: Array SiigoCustomer <- liftAff do
    liftEffect $ log $ "Fetching " <> url
    res <- fetch url options
    handleResponse res $ fromJSON res.json
  pure customers

buildURL :: String -> String
buildURL path = baseUrl <> "/v1/" <> path

baseUrl :: String
baseUrl = "https://api.siigo.com"
