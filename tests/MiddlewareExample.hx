package;

import tink.websocket.*;
import tink.http.containers.*;
import tink.http.middleware.*;
import tink.http.Response;
import tink.http.Request;
import tink.http.Handler;
import tink.websocket.ServerHandler;
import tink.websocket.servers.TinkServer;
import tink.streams.Stream.Empty;

using tink.CoreApi;

class MiddlewareExample {
	static function main() {
		var server = new TinkServer();
		server.clientConnected.handle(function(client) {
			trace('client connected from ${client.clientIp}');
			client.messageReceived.handle(function(message) trace(message));
			client.send(Text('Hello!'));
		});
		
		var handler:Handler = req -> Future.sync(('Done':OutgoingResponse));
		
		handler = handler.applyMiddleware(new WebSocket(
			// Choose either one from the following 2 lines:
				// websocketHandler
				server.handle
		));
		
		var container = new NodeContainer(8081, {upgradable: true});
		container.run(handler).eager();
	}
	
	static function websocketHandler(incoming:Incoming):RawMessageStream<Noise> {
		trace(incoming.clientIp);
		var source = incoming.stream;
		return source.idealize(_ -> Empty.make());
	}
}

/*
Run this in browser:
var ws = new WebSocket('ws://localhost:8081');
ws.onopen = function() { setInterval(function() { ws.send(new Date().toString()); }, 1000); }
ws.onmessage = console.log;
*/
