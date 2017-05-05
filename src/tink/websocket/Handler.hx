package tink.websocket;

import tink.streams.IdealStream;
import tink.streams.RealStream;
import tink.Chunk;

using tink.CoreApi;

private typedef Impl = RealStream<Chunk>->IdealStream<Chunk>;

@:callable
abstract Handler(Impl) from Impl to Impl {
	public inline function asAcceptor():tink.tcp.Handler
		return Acceptor.wrap(this);
	public inline function asConnector(url:tink.Url):tink.tcp.Handler
		return Connector.wrap(url, this);
}