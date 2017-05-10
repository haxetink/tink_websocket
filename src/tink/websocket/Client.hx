package tink.websocket;

import tink.websocket.Message;
import tink.streams.IdealStream;
import tink.streams.RealStream;

interface Client {
	/**
	 *  Create a new WebSocket connection.
	 *  Note that the connection will be closed when either stream is depleted,
	 *  so beware not to end the outgoing stream until you are done with the connection.
	 *  @param outgoing - Outgoing message stream
	 *  @return Incoming message stream
	 */
	function connect(outgoing:IdealStream<Message>):RealStream<Message>;
}
