package tink.websocket.clients;

import haxe.io.Bytes;
import tink.Url;
import tink.websocket.Client;
import tink.websocket.Message;
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
	
	public function connect(outgoing:IdealStream<Message>):RealStream<Message> {
		return Stream.promise(Future.async(function(cb) {
			var handler = Connector.wrap(url, function(incoming) {
				cb(Success(MessageStream.ofChunkStream(incoming)));
				return MessageStream.lift(outgoing).toMaskedChunkStream(MaskingKey.random);
			});
			
			var port = switch [url.host.port, url.scheme] {
				case [null, 'wss' | 'https']: 443;
				case [null, _]: 80;
				case [v, _]: v;
			}
			tink.tcp.nodejs.NodejsConnector.connect({host: url.host.name, port: port}, handler).eager();
		}));
	}
}