module Evo.Activities (EvoResponse, Fetch, EvoSaleID, EvoSale, readEvoSale) where

import Prelude
  ( ($)
  , (<>)
  , Void
  , Unit
  , pure
  , bind
  )
import Effect.Aff (Aff)
import Fetch (ResponseR, Response)
import Fetch.Yoga.Json (fromJSON)
import Foreign (Foreign)

type Fetch a = String -> Aff a

type EvoSaleID
  = String

type EvoSale
  = { id :: EvoSaleID }

type EvoResponse = { json :: EvoSale }

baseUrl :: String
baseUrl = "https://evo-integracao.w12app.com.br"

readEvoSale :: Fetch Response -> EvoSaleID -> Aff EvoSale
readEvoSale fetch id = do
  let
    url = baseUrl <> "/api/v1/sales/" <> id
  { json } <- fetch url
  res :: EvoResponse <- fromJSON json
  pure res.json
