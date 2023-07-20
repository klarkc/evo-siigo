export function startWorkflowImpl(wfClient, wfType, wfStartOptions) {
	return wfClient.start(wfType, wfStartOptions)
}

export function resultImpl(wfHandler) {
	return wfHandler.result()
}
