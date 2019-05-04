package tink.websocket;

import tink.streams.Stream;
import tink.streams.IdealStream;
import tink.streams.RealStream;
import tink.io.StreamParser;
import tink.http.Request;
import tink.http.Response;
import tink.Url;
import tink.Chunk;

using tink.CoreApi;
using tink.io.Source;

typedef Incoming = {
	clientIp:String,
	header:IncomingHandshakeRequestHeader,
	stream:RawMessageStream<Error>,
}
typedef ServerHandler = Incoming->RawMessageStream<Noise>;

class ServerHandlerTools {
	#if tink_tcp
	public static function toTcpHandler(handler:ServerHandler, ?onError:Error->Void):tink.tcp.Handler {
		if(onError == null) onError = function(e) trace(e);
		
		return function(i:tink.tcp.Incoming):Future<tink.tcp.Outgoing> {
			return Future.sync({
				stream: Generator.stream(function(step) {
					i.stream.parse(IncomingHandshakeRequestHeader.parser())
						.handle(function(o) switch o {
							case Success({a: header, b: rest}):
								switch header.validate() {
									case Success(_): // ok
									case Failure(e): onError(e);
								}
								var reponseHeader = new OutgoingHandshakeResponseHeader(header.key);
								step(Link((reponseHeader.toString():Chunk), handler({
									clientIp: i.from.toString(),
									header: header,
									stream: rest.parseStream(new Parser()),
								}).toUnmaskedChunkStream()));
							case Failure(e):
								onError(e);
						});
				}),
				allowHalfOpen: true,
			});
		}
	}
	#end
}

