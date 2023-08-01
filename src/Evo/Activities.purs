module Evo.Activities (EvoOptions, EvoResponse, Fetch, EvoSaleID, EvoSale, readEvoSale) where

import Prelude
  ( ($)
  , (<>)
  , Void
  , Unit
  , pure
  , bind
  , show
  , discard
  )
import Effect (Effect)
import Effect.Aff (Error, Aff, throwError, error)
import Effect.Class (liftEffect)
import Effect.Console (log)
import Fetch (ResponseR, Response)
import Fetch.Yoga.Json (fromJSON)
import Foreign (Foreign)
import Type.Proxy (Proxy(Proxy))

type Fetch a
  = String -> Record a -> Aff Response

type EvoSaleID
  = String

type EvoSale
  = Foreign

type EvoResponse
  = { json :: EvoSale }

type EvoRequestHeaders
  = { authorization :: String }

type EvoOptions a
  = { fetch :: Fetch a
    , base64 :: String -> Effect String
    , auth ::
        { username :: String
        , password :: String
        }
    }

baseUrl :: String
baseUrl = "https://evo-integracao.w12app.com.br"

readEvoSale :: EvoOptions ( headers :: EvoRequestHeaders ) -> EvoSaleID -> Aff EvoSale
readEvoSale { fetch, base64, auth } id = do
  auth_ <- liftEffect $ base64 $ auth.username <> ":" <> auth.password
  let
    url = baseUrl <> "/api/v1/sales/" <> id

    options =
      { headers: { authorization: "Basic " <> auth_ }
      }
  liftEffect do
    log $ "Fetching " <> url
    log $ show options
  res <- fetch url options
  case res.status of
    200 -> do
      --{ json } :: EvoResponse <- fromJSON res.json
      fr <- res.json
      pure fr
    _ -> throwError $ error $ "Request failed with " <> show res.status <> " status"
