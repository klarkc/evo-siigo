module Node.Evo.Activities
  ( loadEvoAuthHeaders
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
import Temporal.Node.Activity
  ( liftOperation
  , output
  , useInput
  )
import Temporal.Exchange
  ( ExchangeI
  , ExchangeO
  )
import Temporal.Logger (info)
import Temporal.Node.Activity.Unsafe (unsafeRunActivity)
import Temporal.Node.Platform
  ( lookupEnv
  , base64
  , fetch
  , awaitFetch
  , liftLogger
  )
import Evo
  ( EvoAuthHeaders
  , EvoSale
  , EvoMember
  )

type EvoError
  = {}

type EvoInput
  = ( headers :: EvoAuthHeaders )

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
    evoSale <- liftOperation do
      liftLogger $ info $ "GET " <> url
      awaitFetch @EvoError $ fetch url options
    output evoSale

readEvoMember :: ExchangeI -> Promise ExchangeO
readEvoMember i = unsafeRunActivity @{ id :: String | EvoInput }  @EvoMember do
    { id, headers } <- useInput i
    let
      url = buildURL $ "members/" <> id
      options = { headers }
    evoMember <- liftOperation do
       liftLogger $ info $ "GET " <> url
       awaitFetch @EvoError $ fetch url options
    output evoMember
