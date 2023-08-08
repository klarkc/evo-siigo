module Evo.Activities
  ( EvoOptions
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
import Effect.Aff (Aff)
import Effect.Aff.Class (liftAff)
import Effect.Class (liftEffect)
import Effect.Console (log)
import Fetch.Yoga.Json (fromJSON)
import Fetch.Function (Fetch)
import Fetch.Response (handleResponse)
import Temporal.Activity (Activity, unsafeRunActivityM, askInput)

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
    , document :: String
    }

type EvoRequestHeaders
  = { authorization :: String }

type EvoOptions
  = { fetch :: Fetch ( headers :: EvoRequestHeaders )
    , base64 :: String -> Effect String
    , auth ::
        { username :: String
        , password :: String
        }
    }

baseUrl :: String
baseUrl = "https://evo-integracao.w12app.com.br"

buildHeaders :: EvoOptions -> Aff { authorization :: String }
buildHeaders { base64, auth } = do
  auth_ <- liftEffect $ base64 $ auth.username <> ":" <> auth.password
  pure { authorization: "Basic " <> auth_ }

buildURL :: String -> String
buildURL path = baseUrl <> "/api/v1/" <> path

readEvoSale :: EvoOptions -> Activity
readEvoSale opt@{ fetch } =
  unsafeRunActivityM do
    id :: EvoSaleID <- askInput
    evoSale :: EvoSale <- liftAff do
      headers <- buildHeaders opt
      let
        url = buildURL $ "sales/" <> show id

        options = { headers }
      liftEffect $ log $ "Fetching " <> url
      --log $ show options
      res <- fetch url options
      handleResponse res $ fromJSON res.json
    pure evoSale

readEvoMember :: EvoOptions -> Activity
readEvoMember opt@{ fetch } =
  unsafeRunActivityM do
    id :: EvoMemberID <- askInput
    evoMember :: EvoMember <-
      liftAff do
        headers <- liftAff $ buildHeaders opt
        let
          url = buildURL $ "members/" <> show id

          options = { headers }
        liftEffect $ log $ "Fetching " <> url
        res <- fetch url options
        handleResponse res $ fromJSON res.json
    pure evoMember
