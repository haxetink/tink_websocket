package;

import haxe.io.Bytes;
import tink.streams.Stream;
import tink.websocket.*;
import tink.Chunk;

using tink.websocket.ClientHandler;
using tink.CoreApi;
using tink.io.Source;

@:asserts
class TcpConnectorTest {
	public function new() {}
	
	
	public function echo() {
		_echo('ws://echo.websocket.org', 'echo.websocket.org', 80, asserts).handle(function(_) asserts.done());
		return asserts;
	}
	
	function _echo(url, host, port, asserts:tink.unit.AssertionBuffer) {
		return Future.async(function(cb) {
			var c = 0;
			var n = 7;
			var sender = Signal.trigger();
			var outgoing = new SignalStream(sender);
			var handler:ClientHandler = function(stream) {
				stream.forEach(function(message:RawMessage) {
					switch message {
						case Text(v): asserts.assert(v == 'payload' + ++c);
						default: asserts.fail('Unexpected message');
					}
					if(c == n) cb(Noise);
					return c < n ? Resume : Finish;
				});
				
				return RawMessageStream.lift(outgoing);
			}
			
			tink.tcp.nodejs.NodejsConnector.connect({host: host, port: port}, handler.toTcpHandler(url)).eager();
			
			for(i in 0...n) sender.trigger(Data(RawMessage.Text('payload' + (i + 1))));
			sender.trigger(End);
		});
	}
}