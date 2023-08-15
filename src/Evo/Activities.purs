module Evo.Activities
  (
  -- EvoSaleID
  --, EvoSale
  --, EvoReceivableID
  --, EvoReceivable
  --, EvoMemberID
  --, EvoMember
  EvoAuthHeaders
  , EvoAuthHeadersI
  , loadEvoAuthHeaders
  --, readEvoSale
  --, readEvoMember
  ) where

import Prelude
  ( (<>)
  , ($)
  , bind
  , pure
  )
import Promise (Promise)
import Temporal.Activity
  ( Activity
  , liftOperation
  , output
  )
import Temporal.Exchange
  ( ExchangeI
  , ExchangeO
  )
import Temporal.Activity.Unsafe (unsafeRunActivity)
import Temporal.Platform
  ( lookupEnv
  , base64
  )

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

--baseUrl :: String
--baseUrl = "https://evo-integracao.w12app.com.br"
--
--buildURL :: String -> String
--buildURL path = baseUrl <> "/api/v1/" <> path
--
--askInputAuthHeaders :: forall r. Activity { authHeaders :: EvoAuthHeaders | r }
--askInputAuthHeaders = askInput >>= \r -> pure r.authHeaders

--askInputID :: forall r. Activity { id :: a | r }
--askInputID = askInput >>= \r -> pure r.id


loadEvoAuthHeaders :: ExchangeI -> Promise ExchangeO
loadEvoAuthHeaders _ = unsafeRunActivity @{} @EvoAuthHeaders do
    authHeaders <- liftOperation do
        username <- lookupEnv "EVO_USERNAME"
        password <- lookupEnv "EVO_PASSWORD"
        auth_ <- base64 $ username <> ":" <> password
        pure { authorization: "Basic " <> auth_ }
    output authHeaders

--readEvoSale :: Activity
--readEvoSale =
--  unsafeRunActivityM do
--    id :: EvoSaleID <- askInputID
--    headers <- askInputAuthHeaders
--    fetch <- askEnvFetch
--    evoSale :: EvoSale <-
--      liftAff do
--        let
--          url = buildURL $ "sales/" <> show id
--
--          options = { headers }
--        liftEffect $ log $ "Fetching " <> url
--        --log $ show options
--        res <- fetch url options
--        handleResponse res $ fromJSON res.json
--    pure evoSale
--
--readEvoMember :: Activity
--readEvoMember =
--  unsafeRunActivityM do
--    id :: EvoMemberID <- askInputID
--    headers :: Record EvoAuthHeaders <- askInputAuthHeaders
--    fetch <- askEnvFetch
--    evoMember :: EvoMember <-
--      liftAff do
--        let
--          url = buildURL $ "members/" <> show id
--
--          options = { headers }
--        liftEffect $ log $ "Fetching " <> url
--        res <- fetch url options
--        handleResponse res $ fromJSON res.json
--    pure evoMember
