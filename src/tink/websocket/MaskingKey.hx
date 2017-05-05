package tink.websocket;

import haxe.io.Bytes;

@:forward
abstract MaskingKey(Chunk) {
	public function new(a, b, c, d) {
		var bytes = Bytes.alloc(4);
		bytes.set(0, a);
		bytes.set(1, b);
		bytes.set(2, c);
		bytes.set(3, d);
		this = bytes;
	}
	
	@:from
	public static function ofChunk(c:Chunk):MaskingKey {
		if(c.length != 4) throw 'Invalid key length, should be 4';
		return cast c;
	}
	
	public static function random() {
		return new MaskingKey(Std.random(256), Std.random(256), Std.random(256), Std.random(256));
	}
}