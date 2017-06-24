package tink.websocket;

import tink.Chunk;

enum RawMessage {
	Text(v:String);
	Binary(b:Chunk);
	ConnectionClose;
	Ping(b:Chunk);
	Pong(b:Chunk);
}
