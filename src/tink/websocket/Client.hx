package tink.websocket;

import tink.websocket.Message;
import tink.streams.IdealStream;
import tink.streams.RealStream;

interface Client {
	function connect(outgoing:IdealStream<Message>):RealStream<Message>;
}
