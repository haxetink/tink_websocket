package;

import tink.websocket.*;
import tink.streams.Stream;
import tink.streams.Accumulator;

using tink.CoreApi;

class Playground {
	static function main() {
		var handler = Acceptor.wrap(function(stream) {
			var s = MessageStream.ofChunkStream(stream);
			s.forEach(function(m) {
				trace(Date.now().toString() + ': Received:' + Std.string(m));
				return Resume;
			}).handle(function(_) {});
			
			var pings = new Accumulator();
			
			s = s.filter(function(i:Message) return i.match(Message.Text(_))).blend(pings);
			
			s.forEach(function(m) {
				trace(Date.now().toString() + ': Sending:' + Std.string(m));
				return Resume;
			}).handle(function(_) {});
			
			var timer = new haxe.Timer(1000);
			timer.run = function() pings.yield(Data(Message.Ping(tink.Chunk.EMPTY)));
			
			return s.toUnmaskedChunkStream().idealize(function(o) {
				trace(o);
				return Empty.make();
			});
		});
		
		tink.tcp.nodejs.NodejsAcceptor.inst.bind(18088).handle(function(o) switch o {
			case Success(openPort):
				openPort.setHandler(handler);
				trace('running');
				
			case Failure(e):
				trace('failed: $e');
		});
	}
}