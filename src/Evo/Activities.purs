module Evo.Activities
  (
   EvoSaleID
  , EvoSale
  , EvoReceivableID
  , EvoReceivable
  , EvoMemberID
  , EvoMember
  , EvoAuthHeaders
  , EvoAuthHeadersI
  , loadEvoAuthHeaders
  , readEvoSale
  , readEvoMember
  ) where

import Prelude
  ( (<>)
  , ($)
  , bind
  , pure
  , discard
  )
import Promise (Promise)
import Temporal.Activity
  ( liftOperation
  , liftLogger
  , output
  , useInput
  )
import Temporal.Exchange
  ( ExchangeI
  , ExchangeO
  )
import Temporal.Activity.Unsafe (unsafeRunActivity)
import Temporal.Platform
  ( lookupEnv
  , base64
  , fetch
  , awaitFetch
  )
import Temporal.Logger (info)

type EvoInput
  = ( headers :: EvoAuthHeaders )

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

type EvoAuthHeadersI
  = ( authorization :: String
    )

type EvoAuthHeaders
  = Record EvoAuthHeadersI

baseUrl :: String
baseUrl = "https://evo-integracao.w12app.com.br"

buildURL :: String -> String
buildURL path = baseUrl <> "/api/v1/" <> path

loadEvoAuthHeaders :: ExchangeI -> Promise ExchangeO
loadEvoAuthHeaders _ = unsafeRunActivity @{} @EvoAuthHeaders do
    authHeaders <- liftOperation do
        username <- lookupEnv "EVO_USERNAME"
        password <- lookupEnv "EVO_PASSWORD"
        auth_ <- base64 $ username <> ":" <> password
        pure { authorization: "Basic " <> auth_ }
    output authHeaders

readEvoSale :: ExchangeI -> Promise ExchangeO
readEvoSale i = unsafeRunActivity @{ id :: String | EvoInput }  @EvoSale do
    { id, headers } <- useInput i
    let
      url = buildURL $ "sales/" <> id
      options = { headers }
    liftLogger $ info $ "GET " <> url
    evoSale <- liftOperation $ awaitFetch $ fetch url options
    output evoSale

readEvoMember :: ExchangeI -> Promise ExchangeO
readEvoMember i = unsafeRunActivity @{ id :: String | EvoInput }  @EvoMember do
    { id, headers } <- useInput i
    let
      url = buildURL $ "members/" <> id
      options = { headers }
    liftLogger $ info $ "GET " <> url
    evoMember <- liftOperation $ awaitFetch $ fetch url options
    output evoMember
