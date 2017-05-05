package tink.websocket;

import tink.Chunk;

enum Message {
	Text(v:String);
	Binary(b:Chunk);
	ConnectionClose;
	Ping(b:Chunk);
	Pong(b:Chunk);
}
