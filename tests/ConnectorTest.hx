package;

import haxe.io.Bytes;
import tink.streams.Stream;
import tink.websocket.*;
import tink.Chunk;

using tink.CoreApi;
using tink.io.Source;

@:asserts
class ConnectorTest {
	public function new() {}
	
	
	public function echo() {
		_echo('http://echo.websocket.org', 'echo.websocket.org', 80, asserts).handle(function(_) asserts.done());
		return asserts;
	}
	
	function _echo(url, host, port, asserts:tink.unit.AssertionBuffer) {
		return Future.async(function(cb) {
			var c = 0;
			var n = 7;
			var sender = Signal.trigger();
			var outgoing = new SignalStream(sender);
			var handler = Connector.wrap(url, function(stream) {
				MessageStream.ofChunkStream(stream)
					.forEach(function(message:Message) {
						switch message {
							case Text(v): asserts.assert(v == 'payload' + ++c);
							default: asserts.fail('Unexpected message');
						}
						if(c == n) cb(Noise);
						return c < n ? Resume : Finish;
					});
				
				return MessageStream.lift(outgoing).toUnmaskedChunkStream();
			});
			
			tink.tcp.nodejs.NodejsConnector.connect({host: host, port: port}, handler).handle(function(o) trace(Std.string(o)));
			
			for(i in 0...n) sender.trigger(Data(Message.Text('payload' + (i + 1))));
			sender.trigger(End);
		});
	}
}