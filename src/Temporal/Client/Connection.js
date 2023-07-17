export function connectImpl(ctor) {
	return function (options) {
		return function (onError, onSuccess) {
			return ctor.connect.call(ctor, options);
		}
	}
}
