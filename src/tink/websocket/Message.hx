package tink.websocket;

enum Message {
	Text(v:String);
	Binary(b:Chunk);
}
