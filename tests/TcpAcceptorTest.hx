
package;

import haxe.io.Bytes;
import tink.streams.Stream;
import tink.websocket.*;
import tink.Chunk;

using tink.websocket.ServerHandler;
using tink.CoreApi;
using tink.io.Source;

@:asserts
class TcpAcceptorTest extends TcpConnectorTest {
	
	public function tcpServer() {
		
		var handler:ServerHandler = function(i) {
			// sends back the same frame unmasked
			return i.stream.idealize(function(_) return Empty.make());
		}
		
		tink.tcp.nodejs.NodejsAcceptor.inst.bind(18088).handle(function(o) switch o {
			case Success(openPort):
				openPort.setHandler(handler.toTcpHandler());
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
		handler = handler.applyMiddleware(new tink.http.middleware.WebSocket(function(i) return i.stream.idealize(function(_) return Empty.make())));
		
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
	
	// FIXME: timeout?
	// public function tcpContainer() {
	// 	var container = new tink.http.containers.TcpContainer(tink.tcp.nodejs.NodejsAcceptor.inst.bind.bind(18090));
	// 	return http(18090, container, asserts);
	// }
	
	// public function nodeContainer() {
	// 	var container = new tink.http.containers.NodeContainer(18089);
	// 	return http(18089, container, asserts);
	// }
}