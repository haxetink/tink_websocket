package tink.websocket.clients;

import tink.websocket.Client;
import tink.state.*;
import tink.streams.Stream;
import tink.streams.RealStream;
import tink.streams.IdealStream;
import tink.Chunk;

using tink.CoreApi;

class TheClient {
	
	public var connected(get, null):Observable<Bool>;
	public var messageReceived(get, null):Signal<Message>;
	
	var client:Client;
	
	var connectedState:State<Bool>;
	var messageReceivedTrigger:SignalTrigger<Message>;
	
	var outgoingTrigger:SignalTrigger<Yield<Message, Noise>>;
	
	public function new(client) {
		this.client = client;
		
		outgoingTrigger = Signal.trigger();
		var outgoing = new SignalStream(outgoingTrigger);
		
		messageReceivedTrigger = Signal.trigger();
		connectedState = new State(true);
		
		client.connect(outgoing).forEach(function(message:Message) {
			switch message {
				case Text(v): messageReceivedTrigger.trigger(Text(v));
				case Binary(v): messageReceivedTrigger.trigger(Binary(v));
			}
			return Resume;
		}).handle(function(o) switch o {
			case Depleted: close();
			case Failed(err): close(); // TODO: signal the error
			case _: // should not happen
		});
	}
	
	public function send(message:Message) {
		outgoingTrigger.trigger(Data(message));
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
