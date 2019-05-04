package tink.websocket.servers;

#if nodejs
import tink.http.Request;
import tink.websocket.Message;
import tink.websocket.Server;
import haxe.Constraints;
import haxe.extern.EitherType;
import js.html.ArrayBuffer;
import js.node.http.IncomingMessage;

using tink.CoreApi;

class NodeWsServer implements Server {
	public var clientConnected(default, null):Signal<ConnectedClient>;
	
	var server:NativeServer;
	
	public function new(opt) {
		server = new NativeServer(opt);
		clientConnected = Signal.generate(function(trigger) {
			server.on('connection', function(socket, request:IncomingMessage) {
				trigger((new NodeWsConnectedClient(
					request.connection.remoteAddress,
					IncomingRequestHeader.fromIncomingMessage(request),
					socket
				):ConnectedClient));
			});
		});
	}
	
	public function close():Future<Noise> {
		return Future.async(function(cb) {
			server.close(cb.bind(Noise));
		});
	}
}

class NodeWsConnectedClient implements ConnectedClient {
	
	public var clientIp(default, null):String;
	public var header(default, null):IncomingRequestHeader;
	public var closed(default, null):Future<Noise>;
	public var messageReceived(default, null):Signal<Message>;
	
	var socket:NativeSocket;
	
	public function new(clientIp, header, socket) {
		this.clientIp = clientIp;
		this.header = header;
		this.socket = socket;
		
		closed = Future.async(function(cb) {
			socket.once('close', cb.bind(Noise));
		});
		
		messageReceived = Signal.generate(function(trigger) {
			socket.on('message', function(message) {
				trigger(Text(message));
			});
		});
	}
	
	public function send(message:Message):Void {
		socket.send(switch message {
			case Text(v): v;
			case Binary(v): v.toBytes().getData();
		});
	}
	public function close():Void {
		socket.close();
	}
}

@:jsRequire('ws', 'Server')
private extern class NativeServer {
	function new(opt:{});
	function on(event:String, f:Function):Void;
	function close(f:Function):Void;
}

extern class NativeSocket {
	function on(event:String, f:Function):Void;
	function once(event:String, f:Function):Void;
	function send(data:EitherType<String, ArrayBuffer>):Void;
	function close():Void;
}
#end