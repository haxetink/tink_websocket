package;

import haxe.io.Bytes;
import tink.streams.Stream;
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
		var sender = Signal.trigger();
		var client = new JsClient('ws://echo.websocket.org');
		client.connect(new SignalStream(sender.asSignal())).forEach(function(message:Message) {
			switch message {
				case Text(v): asserts.assert(v == 'payload' + c++);
				default: asserts.fail('Unexpected message');
			}
			return if(c < n) {
				sender.trigger(Data(Message.Text('payload$c')));
				Resume;
			} else {
				sender.trigger(End);
				asserts.done();
				Finish;
			}
		}).handle(function(o) trace(Std.string(o)));
		sender.trigger(Data(Message.Text('payload$c')));
		return asserts;
	}
}