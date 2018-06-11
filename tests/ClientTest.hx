package;

import haxe.io.Bytes;
import tink.unit.*;
import tink.streams.Stream;
import tink.websocket.*;
import tink.websocket.clients.*;
import tink.Chunk;

using tink.CoreApi;
using tink.io.Source;

@:asserts
@:timeout(10000)
class ClientTest {
	var url = 'ws://echo.websocket.org';
	
	public function new() {}
	
	#if nodejs
	public function tcp() return run(asserts, new TcpClient(url));
	public function http() return run(asserts, new HttpClient(url, new tink.http.clients.NodeClient()));
	#elseif js
	public function js() return run(asserts, new JsClient(url));
	#end
	
	function run(asserts:AssertionBuffer, client:Client) {
		var c = 0;
		var n = 7;
		var sender = Signal.trigger();
		client.connect(new SignalStream(sender.asSignal())).forEach(function(message:RawMessage) {
			switch message {
				case Text(v): asserts.assert(v == 'payload' + c++);
				default: asserts.fail('Unexpected message');
			}
			return if(c < n) {
				sender.trigger(Data(RawMessage.Text('payload$c')));
				Resume;
			} else {
				sender.trigger(End);
				asserts.done();
				Finish;
			}
		}).handle(function(o) trace(Std.string(o)));
		sender.trigger(Data(RawMessage.Text('payload$c')));
		return asserts;
		
	}
}