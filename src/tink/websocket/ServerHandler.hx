package tink.websocket;

using tink.CoreApi;

typedef Incoming = {
	clientIp:String,
	header:IncomingHandshakeRequestHeader,
	stream:RawMessageStream<Error>,
}
typedef ServerHandler = Incoming->RawMessageStream<Noise>;