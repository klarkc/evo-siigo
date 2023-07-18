import { Connection } from "@temporalio/client"

export const connectionCtor = Connection

export function connectImpl(ctor, options) {
	return ctor.connect(options)
}

export function closeImpl(connection) {
	return connection.close()
}

