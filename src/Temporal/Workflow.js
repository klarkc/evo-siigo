import Workflow from "@temporalio/workflow"

export function proxyActivitiesImpl(options) {
	console.log('proxyActivitiesImpl', options)
	return Workflow.proxyActivities(options)
}
