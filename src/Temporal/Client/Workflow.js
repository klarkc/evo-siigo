async function fn() {
	return 'foo';
}

export function startWorkflowImpl(wfClient, wfDefProm, wfStartOptions) {
	// start expects AsyncFunction
	// so we wrap the promise inside of it
	const asyncFn = async function(...args) {
		return wfDefProm(...args)
	}
	return wfClient.start(asyncFn, wfStartOptions)
}
