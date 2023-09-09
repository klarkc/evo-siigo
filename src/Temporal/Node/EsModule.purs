module Node.EsModule
  ( ModulePath
  , resolve
  )
  where

import Prelude (($))
import Effect.Aff (Aff)
import Effect.Aff.Compat (EffectFn1, runEffectFn1)
import Promise.Aff (Promise, toAffE)

type Specifier = String

type ModulePath = String

type ImportMeta
  = { resolve :: EffectFn1 Specifier (Promise ModulePath)
    }

foreign import importMeta :: ImportMeta

resolve :: Specifier -> Aff ModulePath
resolve s = toAffE $ runEffectFn1 importMeta.resolve s
