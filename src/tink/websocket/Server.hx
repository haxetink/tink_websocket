package tink.websocket;

import tink.http.Request;
import tink.websocket.Message;

using tink.CoreApi;

interface Server {
	var clientConnected(default, null):Signal<ConnectedClient>;
	function close():Future<Noise>;
}

interface ConnectedClient {
	var clientIp(default, null):String;
	var header(default, null):IncomingRequestHeader;
	var closed(default, null):Future<Noise>;
	var messageReceived(default, null):Signal<Message>;
	function send(message:Message):Void;
	function close():Void;
}
