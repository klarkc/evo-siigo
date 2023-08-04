module Evo.Activities
  ( EvoOptions
  , Fetch
  , EvoSaleID
  , EvoSale
  , EvoReceivableID
  , EvoReceivable
  , EvoMemberID
  , EvoMember
  , EvoRequestHeaders
  , readEvoSale
  , readEvoMember
  ) where

import Prelude
  ( ($)
  , (<>)
  , bind
  , show
  , discard
  , pure
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

type EvoMemberID
  = Int

type EvoReceivable
  = { idReceivable :: EvoReceivableID
    , status ::
        { id :: Int
        , name :: String
        }
    }

type EvoSale
  = { idSale :: EvoSaleID
    , idMember :: EvoMemberID
    , receivables :: Array EvoReceivable
    }

type EvoMember
  = { idMember :: EvoMemberID
    , firstName :: String
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

buildHeaders :: forall a. EvoOptions a -> Aff { authorization :: String }
buildHeaders { base64, auth } = do
  auth_ <- liftEffect $ base64 $ auth.username <> ":" <> auth.password
  pure { authorization: "Basic " <> auth_ }

buildURL :: String -> String
buildURL path = baseUrl <> "/api/v1/" <> path

handleRes :: forall r a. { status :: Int | r } -> Aff a -> Aff a
handleRes res success = case res.status of
  200 -> success
  _ -> throwError $ error $ "Request failed with " <> show res.status <> " status"

readEvoSale :: EvoOptions ( headers :: EvoRequestHeaders ) -> EvoSaleID -> Aff EvoSale
readEvoSale opt@{ fetch } id = do
  headers <- buildHeaders opt
  let
    url = buildURL $ "sales/" <> show id

    options = { headers }
  liftEffect do
    log $ "Fetching " <> url
  --log $ show options
  res <- fetch url options
  handleRes res $ fromJSON res.json

readEvoMember :: EvoOptions ( headers :: EvoRequestHeaders ) -> EvoMemberID -> Aff EvoMember
readEvoMember opt@{ fetch } id = do
  headers <- buildHeaders opt
  let
    url = buildURL $ "members/" <> show id

    options = { headers }
  liftEffect do
    log $ "Fetching " <> url
  --log $ show options
  res <- fetch url options
  handleRes res $ fromJSON res.json
