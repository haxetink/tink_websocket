package;

import haxe.io.Bytes;
import tink.streams.Stream;
import tink.streams.Accumulator;
import tink.websocket.*;
import tink.websocket.clients.*;
import tink.Chunk;

using tink.CoreApi;
using tink.io.Source;

@:asserts
@:timeout(10000)
class TestClient {
	public function new() {}
	
	public function client() {
		var c = 0;
		var n = 7;
		var sender = new Accumulator();
		var client = new JsClient('ws://echo.websocket.org');
		client.connect(sender).forEach(function(message:Message) {
			switch message {
				case Text(v): asserts.assert(v == 'payload' + ++c);
				default: asserts.fail('Unexpected message');
			}
			if(c == n) asserts.done();
			return c < n ? Resume : Finish;
		}).handle(function(o) trace(Std.string(o)));
		for(i in 0...n) sender.yield(Data(Message.Text('payload' + (i + 1))));
		sender.yield(End);
		return asserts;
	}
}