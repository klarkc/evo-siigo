module Evo 
  ( EvoAuthHeadersI
  , EvoAuthHeaders
  , EvoSale
  , EvoMember
  , EvoMemberID
  , EvoSaleID
  , EvoReceivable
  , EvoDate
  , EvoSaleItem
  , EvoReceivableID
  , EvoContact
  ) where

import Data.Maybe (Maybe)
import Temporal.Exchange (ISO)

type EvoSale
  = { idSale :: EvoSaleID
    , idMember :: EvoMemberID
    , saleDate :: EvoDate
    , receivables :: Array EvoReceivable
    , saleItens :: Array EvoSaleItem
    }

type EvoMember
  = { idMember :: EvoMemberID
    , firstName :: String
    , document :: String
    , contacts :: Array EvoContact
    }

type EvoContact
  = { contactType :: String
    , description :: String
    }

type EvoAuthHeadersI
  = ( authorization :: String
    )

type EvoAuthHeaders
  = Record EvoAuthHeadersI

type EvoSaleID
  = Int

type EvoReceivableID
  = Int

type EvoMemberID
  = Int

type EvoDate
  = ISO

type EvoReceivable
  = { idReceivable :: EvoReceivableID
    , status ::
        { id :: Int
        , name :: String
        }
    , ammount :: Number
    , dueDate :: EvoDate
    }

type EvoSaleItem
  = { quantity :: Int
    , itemValue :: Number
    , discount :: Maybe Number
    }
