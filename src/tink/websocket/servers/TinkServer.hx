package tink.websocket.servers;

import tink.http.Request;
import tink.websocket.Server;
import tink.websocket.RawMessage;
import tink.websocket.RawMessageStream;
import tink.streams.Stream;
import tink.streams.RealStream;
import tink.streams.IdealStream;
import tink.Chunk;

using tink.CoreApi;

class TinkServer implements Server {
	
	public var clients(default, null):Array<ConnectedClient>;
	public var clientConnected(default, null):Signal<ConnectedClient>;
	public var errors(default, null):Signal<Error>;
	
	var connectedTrigger:SignalTrigger<ConnectedClient>;
	var errorsTrigger:SignalTrigger<Error>;
	
	public function new() {
		clients = [];
		clientConnected = connectedTrigger = Signal.trigger();
		errors = errorsTrigger = Signal.trigger();
	}
	
	public function close():Future<Noise> {
		throw 'not implemented';
	}
	
	public function handle(i):RawMessageStream<Noise> {
		var client = new TinkConnectedClient(i.clientIp, i.header, i.stream);
		clients.push(client);
		client.closed.handle(function() clients.remove(client));
		connectedTrigger.trigger(client);
		client.listen();
		return client.outgoing;
	}
}

@:allow(tink.websocket)
class TinkConnectedClient implements ConnectedClient {
	public var clientIp(default, null):String;
	public var header(default, null):IncomingRequestHeader;
	
	public var closed(default, null):Future<Noise>;
	public var messageReceived(default, null):Signal<Message>;
	var closedTrigger:FutureTrigger<Noise>;
	var messageReceivedTrigger:SignalTrigger<Message>;
	
	var outgoingTrigger:SignalTrigger<Yield<RawMessage, Noise>>;
	var outgoing:RawMessageStream<Noise>;
	
	var incoming:RawMessageStream<Error>;
	
	public function new(clientIp, header, incoming) {
		
		this.clientIp = clientIp;
		this.header = header;
		this.incoming = incoming;
		
		closed = closedTrigger = Future.trigger();
		messageReceived = messageReceivedTrigger = Signal.trigger();
		
		outgoingTrigger = Signal.trigger();
		outgoing = new SignalStream(outgoingTrigger);
	}
	
	function listen() {
		incoming.forEach(function(message:RawMessage) {
			switch message {
				case Text(v): messageReceivedTrigger.trigger(Text(v));
				case Binary(v): messageReceivedTrigger.trigger(Binary(v));
				case Ping(v): outgoingTrigger.trigger(Data(Pong(v)));
				case Pong(_): // do nothing;
				case ConnectionClose:
					close();
					return Finish;
			}
			return Resume;
		}).eager();
	}
	
	public function send(message:Message):Void {
		outgoingTrigger.trigger(Data(switch message {
			case Text(v): Text(v);
			case Binary(v): Binary(v);
		}));
	}
	
	public function close() {
		outgoingTrigger.trigger(End);
		closedTrigger.trigger(Noise);
	}
}
