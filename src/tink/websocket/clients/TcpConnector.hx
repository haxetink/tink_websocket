package tink.websocket.clients;

import haxe.io.Bytes;
import tink.Url;
import tink.websocket.Client;
import tink.websocket.RawMessage;
import tink.websocket.MaskingKey;
import tink.streams.Stream;
import tink.streams.IdealStream;
import tink.streams.RealStream;
import tink.Url;
import js.html.*;

using tink.websocket.ClientHandler;
using tink.CoreApi;

class TcpConnector implements Connector {
	
	var url:Url;
	
	public function new(url)
		this.url = url;
	
	public function connect(outgoing:RawMessageStream<Noise>):RawMessageStream<Error> {
		var stream = Stream.promise(Future.async(function(cb) {
			var handler:ClientHandler = function(stream) {
				cb(Success(stream));
				var pong = new PongStream(stream).idealize(function(e) return Empty.make());
				return RawMessageStream.lift(outgoing).blend(pong);
			}
			
			var port = switch [url.host.port, url.scheme] {
				case [null, 'wss' | 'https']: 443;
				case [null, _]: 80;
				case [v, _]: v;
			}
			
			tink.tcp.nodejs.NodejsConnector.connect({host: url.host.name, port: port}, handler.toTcpHandler(url))
				.eager();
		}));
		
		return stream;
	}
}