package tink.websocket;

import tink.streams.Stream;
import tink.streams.IdealStream;
import tink.streams.RealStream;
import tink.io.StreamParser;
import tink.Url;
import tink.Chunk;

using tink.CoreApi;
using tink.io.Source;

class Connector {
	public static function wrap(url:Url, handler:ClientHandler, ?onError:Error->RealStream<Chunk>):tink.tcp.Handler {
		if(onError == null) onError = function(_) return Empty.make();
		
		return function(i:tink.tcp.Incoming):Future<tink.tcp.Outgoing> {
			return Future.sync({
				stream: Generator.stream(function(step) {
					var header = new OutgoingHandshakeRequestHeader(url);
					var accept = header.accept;
					var promise = i.stream.parse(IncomingHandshakeResponseHeader.parser())
						.next(function(o) return o.a.validate(accept).map(function(_) return o.b))
						.next(function(rest):Stream<Chunk, Noise> return handler(RawMessageStream.ofChunkStream(rest.parseStream(new Parser()))).toMaskedChunkStream(MaskingKey.random));
					step(Link((header.toString():Chunk), Stream.promise(promise).idealize(onError)));
				}),
				allowHalfOpen: true,
			});
		}
	}
}

