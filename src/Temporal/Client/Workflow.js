export function startWorkflowImpl(wfClient, wfType, wfStartOptions) {
	console.log('wfType', wfType)
	return wfClient.start(wfType, wfStartOptions)
}

export function resultImpl(wfHandler) {
	console.log('calling result', wfHandler.result.toString());
	debugger
	return wfHandler.result().then((...args) => {
		console.log('result done', JSON.stringify(args));
		debugger
		return args;
	})
}
