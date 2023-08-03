module Evo.Activities
  ( EvoOptions
  , Fetch
  , EvoSaleID
  , EvoSale
  , EvoReceivableID
  , EvoReceivable
  , readEvoSale
  ) where

import Prelude
  ( ($)
  , (<>)
  , bind
  , show
  , discard
  )
import Effect (Effect)
import Effect.Aff (Aff, throwError, error)
import Effect.Class (liftEffect)
import Effect.Console (log)
import Fetch (Response)
import Fetch.Yoga.Json (fromJSON)

type Fetch a
  = String -> Record a -> Aff Response

type EvoSaleID
  = Int

type EvoReceivableID
  = Int

type EvoReceivable
  = { idReceivable :: EvoReceivableID
    }

type EvoSale
  = { idSale :: EvoSaleID
    , receivables :: Array EvoReceivable
    }

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
    url = baseUrl <> "/api/v1/sales/" <> (show id)

    options =
      { headers: { authorization: "Basic " <> auth_ }
      }
  liftEffect do
    log $ "Fetching " <> url
    --log $ show options
  res <- fetch url options
  case res.status of
    200 -> fromJSON res.json
    _ -> throwError $ error $ "Request failed with " <> show res.status <> " status"
