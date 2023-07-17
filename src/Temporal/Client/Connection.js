// @temporalio/client
import { Connection } from './foreign'

export const connectionCtor = Connection

export function connectImpl(ctor) {
	return function (options) {
		return function (onError, onSuccess) {
			return ctor.connect.call(ctor, options);
		}
	}
}
