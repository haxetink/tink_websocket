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

using tink.CoreApi;

class TcpClient implements Client {
	
	var url:Url;
	
	public function new(url)
		this.url = url;
	
	public function connect(outgoing:RawMessageStream<Noise>):RawMessageStream<Error> {
		var stream = Stream.promise(Future.async(function(cb) {
			var handler = Connector.wrap(url, function(stream) {
				trace('got stream');
				cb(Success(stream));
				var pong = new PongStream(stream).idealize(function(e) return Empty.make());
				return RawMessageStream.lift(outgoing).blend(pong);
			});
			
			var port = switch [url.host.port, url.scheme] {
				case [null, 'wss' | 'https']: 443;
				case [null, _]: 80;
				case [v, _]: v;
			}
			
			tink.tcp.nodejs.NodejsConnector.connect({host: url.host.name, port: port}, handler)
				.handle(function(o) trace(o));
		}));
		
		stream.forEach(function(o) {
			trace(o);
			return Resume;
		}).handle(function(o) trace(o));
		
		return stream;
	}
}