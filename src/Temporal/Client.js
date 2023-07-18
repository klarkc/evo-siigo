import { Client } from "@temporalio/client"

export const clientCtor = Client

export function defaultClientOptionsImpl(clientCtor) {
	// default options is hidden in clientCtor constructor as {}
	return {}
}

export function createClientImpl(clientCtor, options) {
	return new clientCtor(options)
}
