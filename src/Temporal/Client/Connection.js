import { Connection } from "@temporalio/client"

export const connectionCtor = Connection

export function connectImpl(ctor) {
	return function(options) {
		return function(onError, onSuccess) {
			ctor.connect(ctor, options)
				.then(onSuccess)
				.catch(onError)
			return function(cancelError, onCancelerError, onCancellerSuccess) {
				// TODO cancel pending connection
				onCancellerSuccess()
			}
		}
	}
}
