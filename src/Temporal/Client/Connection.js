import { Connection } from "@temporalio/client"

const _notImplementedError = new Error("Not implemented");

function _notCancelable(cancelError, onCancelerError, onCancellerSuccess) {
	onCancelerError(_notImplementedError)
}

export const connectionCtor = Connection

export function connectImpl(ctor) {
	return function(options) {
		return function(onError, onSuccess) {
			ctor.connect(ctor, options)
				.then(onSuccess)
				.catch(onError)
			// TODO cancel pending connection
			return _notCancelable
		}
	}
}

export function closeImpl(connection) {
	return function(onError, onSuccess) {
		connection
			.close()
			.then(onSuccess)
			.catch(onError)
		// TODO cancel pending connection
		return _notCancelable
	}
}
