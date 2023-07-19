import { Worker } from "@temporalio/worker"

export const workerCtor = Worker

export function createWorkerImpl(workerCtor, options) {
	return workerCtor.create(options)
}

export function runWorkerImpl(worker) {
	return worker.run()
}
