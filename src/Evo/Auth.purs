module Evo.Auth where
--module Evo.Auth (EvoAuthHeaders, evoAuth) where

--import Prelude (($), (<>), bind, pure)
--import Effect.Aff (Aff)
--import Effect.Class (liftEffect)
--import Env (Environment)
--
--type EvoAuthHeaders
--  = ( authorization :: String
--    )
--
--evoAuth :: forall r. Environment r EvoAuthHeaders -> Aff (Record EvoAuthHeaders)
--evoAuth env =
--  liftEffect do
--    username <- env.lookupEnv "EVO_USERNAME"
--    password <- env.lookupEnv "EVO_PASSWORD"
--    auth_ <- env.base64 $ username <> ":" <> password
--    pure { authorization: "Basic " <> auth_ }
