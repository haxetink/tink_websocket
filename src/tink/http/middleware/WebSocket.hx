package tink.http.middleware;

import tink.websocket.*;
import tink.streams.Stream;
import tink.http.Middleware;
import tink.http.Request;
import tink.http.Response;

using tink.io.Source;
using tink.CoreApi;

@:require(tink_http_middleware)
class WebSocket implements MiddlewareObject {
	var ws:ServerHandler;
	
	public function new(ws, ?authenticator) {
		this.ws = ws;
		if(authenticator != null) authenticate = authenticator;
	}
	
	dynamic function authenticate(header:RequestHeader):Promise<Noise> {
		return Noise;
	}
		
	public function apply(handler:tink.http.Handler):tink.http.Handler {
		return function(req:IncomingRequest):Future<OutgoingResponse> {
			var header:IncomingHandshakeRequestHeader = req.header;
			return switch [header.validate(), req.body] {
				case [Success(_), Plain(src)]:
					authenticate(req.header).flatMap(function(o) {
						return Future.sync(switch o {
							case Success(_):
								new OutgoingResponse(
									new OutgoingHandshakeResponseHeader(header.key),
									ws({
										clientIp: req.clientIp,
										header: header,
										stream: src.parseStream(new Parser()),
									}).toUnmaskedChunkStream()
								);
							case Failure(e):
								OutgoingResponse.reportError(e);
						});
					});
				default:
					handler.process(req);
			}
		}
	}
}