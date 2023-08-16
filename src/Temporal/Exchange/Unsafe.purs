module Temporal.Exchange.Unsafe (unsafeRunExchange) where

import Prelude (($))
import Yoga.JSON (class ReadForeign, class WriteForeign)
import Foreign (Foreign)
import Promise (Promise, class Flatten)
import Temporal.Promise.Unsafe (unsafeFromAff)
import Temporal.Exchange (Exchange, ExchangeO, runExchange)

unsafeRunExchange  :: forall @inp @out n. ReadForeign inp => WriteForeign out => Flatten n _ => Exchange inp out n -> Promise ExchangeO
unsafeRunExchange p = unsafeFromAff $ runExchange p
