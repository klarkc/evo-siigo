module Temporal.Worker (Worker, createWorker, runWorker) where

import Prelude ((<<<), Unit)
import Data.Function.Uncurried (Fn1, Fn2, runFn1, runFn2)
import Effect.Aff (Aff)
import Promise.Aff (Promise, toAff)

type WorkerOptions
  = { taskQueue :: String }

data WorkerCtor

data Worker

foreign import workerCtor :: WorkerCtor

foreign import createWorkerImpl :: Fn2 WorkerCtor WorkerOptions (Promise Worker)

foreign import runWorkerImpl :: Fn1 Worker (Promise Unit)

createWorker_ :: WorkerOptions -> Promise Worker
createWorker_ = runFn2 createWorkerImpl workerCtor

createWorker :: WorkerOptions -> Aff Worker
createWorker = toAff <<< createWorker_

runWorker_ :: Worker -> Promise Unit
runWorker_ = runFn1 runWorkerImpl

runWorker :: Worker -> Aff Unit
runWorker = toAff <<< runWorker_
