package tink.websocket;

import tink.state.*;
import tink.streams.Stream;
import tink.streams.RealStream;
import tink.streams.IdealStream;
import tink.Chunk;

using tink.CoreApi;

class Client {
	
	public var connected(get, null):Observable<Bool>;
	public var messageReceived(get, null):Signal<Message>;
	
	var connector:Connector;
	
	var connectedState:State<Bool>;
	var messageReceivedTrigger:SignalTrigger<Message>;
	
	var outgoingTrigger:SignalTrigger<Yield<RawMessage, Noise>>;
	
	public function new(connector) {
		this.connector = connector;
		
		outgoingTrigger = Signal.trigger();
		var outgoing = new SignalStream(outgoingTrigger);
		
		messageReceivedTrigger = Signal.trigger();
		connectedState = new State(true);
		
		connector.connect(outgoing).forEach(function(message:RawMessage) {
			switch message {
				case Text(v): messageReceivedTrigger.trigger(Text(v));
				case Binary(v): messageReceivedTrigger.trigger(Binary(v));
				case _: // discard
			}
			return Resume;
		}).handle(function(o) switch o {
			case Depleted: close();
			case Failed(err): close(); // TODO: signal the error
			case _: // should not happen
		});
	}
	
	public function send(message:Message) {
		outgoingTrigger.trigger(Data(switch message {
			case Text(v): RawMessage.Text(v);
			case Binary(v): RawMessage.Binary(v);
		}));
	}
	
	public function close() {
		outgoingTrigger.trigger(End);
		connectedState.set(false);
	}
	
	inline function get_connected()
		return connectedState.observe();
		
	inline function get_messageReceived()
		return messageReceivedTrigger.asSignal();
}


interface Connector {
	/**
	 *  Create a new WebSocket connection.
	 *  Note that the connection will be closed when either stream is depleted,
	 *  so beware not to end the outgoing stream until you are done with the connection.
	 *  @param outgoing - Outgoing message stream
	 *  @return Incoming message stream
	 */
	function connect(outgoing:RawMessageStream<Noise>):RawMessageStream<Error>;
}
