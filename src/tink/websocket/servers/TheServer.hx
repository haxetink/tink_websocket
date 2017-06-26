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

class TheServer implements Server {
	
	public var clients(default, null):Array<ConnectedClient>;
	public var connected(default, null):Signal<ConnectedClient>;
	
	var connectedTrigger:SignalTrigger<ConnectedClient>;
	
	public function new() {
		clients = [];
		connected = connectedTrigger = Signal.trigger();
	}
	
	public function close():Future<Noise> {
		throw 'not implemented';
	}
	
	public function handle(i):RawMessageStream<Noise> {
		var client = new TheConnectedClient(i.clientIp, i.header, i.stream);
		clients.push(client);
		client.closed.handle(function() clients.remove(client));
		connectedTrigger.trigger(client);
		return client.outgoing;
	}
}

@:allow(tink.websocket)
class TheConnectedClient implements ConnectedClient {
	public var clientIp(default, null):String;
	public var header(default, null):IncomingRequestHeader;
	
	public var closed(default, null):Future<Noise>;
	public var messageReceived(default, null):Signal<Chunk>;
	var closedTrigger:FutureTrigger<Noise>;
	var messageRecievedTrigger:SignalTrigger<Chunk>;
	
	var outgoingTrigger:SignalTrigger<Yield<RawMessage, Noise>>;
	var outgoing:RawMessageStream<Noise>;
	
	public function new(clientIp, header, incoming:RawMessageStream<Error>) {
		
		this.clientIp = clientIp;
		this.header = header;
		
		closed = closedTrigger = Future.trigger();
		messageReceived = messageRecievedTrigger = Signal.trigger();
		
		outgoingTrigger = Signal.trigger();
		outgoing = new SignalStream(outgoingTrigger);
		
		incoming.forEach(function(message:RawMessage) {
			switch message {
				case Text(v): messageRecievedTrigger.trigger(v);
				case Binary(v): messageRecievedTrigger.trigger(v);
				case Ping(v): outgoingTrigger.trigger(Data(Pong(v)));
				case Pong(_): // do nothing;
				case ConnectionClose:
					closedTrigger.trigger(Noise);
					outgoingTrigger.trigger(End);
					return Finish;
			}
			return Resume;
		}).eager();
	}
	
	public function send(chunk:Chunk):Void {
		outgoingTrigger.trigger(Data(Binary(chunk)));
	}
}
