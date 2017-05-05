package;

import haxe.io.Bytes;
import tink.streams.Stream;
import tink.streams.Accumulator;
import tink.websocket.*;
import tink.Chunk;

using tink.CoreApi;
using tink.io.Source;

@:asserts
class TestWebSocket {
	public function new() {}
	
	@:variant((this.arrayToBytes([129, 131, 61]):tink.io.Source.IdealSource).append(this.arrayToBytes([84, 35, 6, 112, 16, 109])), '81833d54230670106d', '3d542306', '70106d', 'MDN')
	@:variant(this.arrayToBytes([129, 131, 61, 84, 35, 6, 112, 16, 109]), '81833d54230670106d', '3d542306', '70106d', 'MDN')
	@:variant(tink.Chunk.ofHex('818823fb87c8539afea44c9ae3f9'), '818823fb87c8539afea44c9ae3f9', '23fb87c8', '539afea44c9ae3f9', 'payload1')
	public function parseSingleFrame(source:IdealSource, whole:String, key:String, masked:String, unmasked:String) {
		source.parseStream(new Parser()).forEach(function(chunk:Chunk) {
			var frame:Frame = chunk;
			asserts.assert(chunk.toBytes().toHex() == whole);
			asserts.assert(frame.fin == true);
			asserts.assert(frame.opcode == 1);
			asserts.assert(frame.masked == true);
			asserts.assert(frame.maskingKey.toHex() == key);
			asserts.assert(frame.maskedPayload.toHex() == masked);
			asserts.assert(frame.unmaskedPayload.toString() == unmasked);
			return Resume;
		}).handle(function(o) {
			asserts.assert(o == Depleted);
			asserts.done();
		});
		return asserts;
	}
	
	public function parseConsecutiveFrame() {
		var frame = [129, 131, 61, 84, 35, 6, 112, 16, 109];
		var source:IdealSource = arrayToBytes(frame.concat(frame).concat(frame));
		var num = 0;
		source.parseStream(new Parser()).forEach(function(chunk:Chunk) {
			asserts.assert(chunk.toBytes().toHex() == '81833d54230670106d');
			var frame:Frame = chunk;
			asserts.assert(frame.fin == true);
			asserts.assert(frame.opcode == 1);
			asserts.assert(frame.masked == true);
			asserts.assert(frame.maskingKey.toHex() == '3d542306');
			asserts.assert(frame.maskedPayload.toHex() == '70106d');
			asserts.assert(frame.unmaskedPayload.toString() == 'MDN');
			num++;
			return Resume;
		}).handle(function(o) {
			asserts.assert(o == Depleted);
			asserts.assert(num == 3);
			asserts.done();
		});
		return asserts;
	}
	
	public function echo() {
		_echo('http://echo.websocket.org', 'echo.websocket.org', 80, asserts).handle(function(_) asserts.done());
		return asserts;
	}
	
	public function tcpServer() {
		
		var handler = Acceptor.wrap(function(stream) {
			// sends back the same frame unmasked
			return stream.map(function(chunk:Chunk) return Frame.fromChunk(chunk).unmask().toChunk()).idealize(null);
		});
		
		tink.tcp.nodejs.NodejsAcceptor.inst.bind(18088).handle(function(o) switch o {
			case Success(openPort):
				openPort.setHandler(handler);
				_echo('http://localhost:18088', 'localhost', 18088, asserts).handle(function(_) {
					openPort.shutdown(true).handle(asserts.done);
				});
				
			case Failure(e):
				asserts.fail(e);
		});
		
		return asserts;
	}
	
	function http(port:Int, container:tink.http.Container, asserts:tink.unit.AssertionBuffer) {
		var handler:tink.http.Handler = function(req) return Future.sync(('done':tink.http.Response.OutgoingResponse));
		handler = handler.applyMiddleware(new tink.http.middleware.WebSocket(function(stream) return stream.map(function(chunk:Chunk) return Frame.fromChunk(chunk).unmask().toChunk()).idealize(null)));
		
		container.run(handler).handle(function(o) switch o {
			case Running(r):
				_echo('http://localhost:$port', 'localhost', port, asserts).handle(function(_) {
					// trace('shutting down');
					// r.shutdown(false).handle(asserts.done);
					asserts.done();
				});
				
			case Shutdown: 
				trace('shutdown');
				
			case Failed(e):
				asserts.fail(e);
		});
		
		
		return asserts;
		
	}
	
	
	public function tcpContainer() {
		var container = new tink.http.containers.TcpContainer(tink.tcp.nodejs.NodejsAcceptor.inst.bind.bind(18090));
		return http(18090, container, asserts);
	}
	
	public function nodeContainer() {
		var container = new tink.http.containers.NodeContainer(18089);
		return http(18089, container, asserts);
	}
	
	function _echo(url, host, port, asserts:tink.unit.AssertionBuffer) {
		return Future.async(function(cb) {
			var c = 0;
			var n = 7;
			var sender = new Accumulator();
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
				
				return MessageStream.lift(sender).toChunkStream();
			});
			
			tink.tcp.nodejs.NodejsConnector.connect({host: host, port: port}, handler).handle(function(o) trace(Std.string(o)));
			
			for(i in 0...n) sender.yield(Data(Message.Text('payload' + (i + 1))));
			sender.yield(End);
		});
	}
	
	function arrayToBytes(a:Array<Int>):Chunk {
		var bytes = Bytes.alloc(a.length);
		for(i in 0...a.length) bytes.set(i, a[i]);
		return bytes;
	}
}