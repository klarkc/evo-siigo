import { Worker, bundleWorkflowCode } from "@temporalio/worker"

export function createWorkerImpl(options) {
	return Worker.create(options)
}

export function runWorkerImpl(worker) {
	return worker.run()
}

export function bundleWorkflowCodeImpl(options) {
	const webpackConfigHook = (config) => {
		return config
	}
	return bundleWorkflowCode({
		...options,
		webpackConfigHook,
	})
}
