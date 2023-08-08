module Fetch.Response (handleResponse) where

import Prelude (($), (<>), show)
import Effect.Aff (Aff, throwError, error)

handleResponse :: forall r a. { status :: Int | r } -> Aff a -> Aff a
handleResponse res success = case res.status of
  200 -> success
  _ -> throwError $ error $ "Request failed with " <> show res.status <> " status"
