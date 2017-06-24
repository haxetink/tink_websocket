package tink.websocket;

import haxe.ds.Option;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import tink.io.Source;
import tink.websocket.RawMessage;
import tink.Chunk;

@:forward
abstract Frame(FrameBase) from FrameBase to FrameBase {
	
	@:to
	public inline function toSource():IdealSource
		return toChunk();
		
	@:to
	public inline function toChunk():Chunk
		return this.toChunk();
		
	@:from
	public static inline function fromChunk(v:Chunk)
		return FrameBase.fromChunk(v);
	
	public static function ofMessage(message:RawMessage, ?maskingKey:MaskingKey):Frame {
		var opcode = 0;
		var payload = null;
		switch message {
			case Text(v):
				opcode = Text;
				payload = Bytes.ofString(v);
			case Binary(b):
				opcode = Binary;
				payload = b;
			case ConnectionClose:
				opcode = ConnectionClose;
			case Ping(b):
				opcode = Ping;
				payload = b;
			case Pong(b):
				opcode = Pong;
				payload = b;
		}
		if(maskingKey != null) payload = Masker.mask(payload, maskingKey);
		return new FrameBase(true, false, false, false, opcode, maskingKey == null ? Unmasked(payload) : Masked(payload, maskingKey));
	}
	
	public function unmask():Frame {
		return switch this.payload {
			case Unmasked(_): this;
			case Masked(p, k): new FrameBase(this.fin, this.rsv1, this.rsv2, this.rsv3, this.opcode, Unmasked(Masker.unmask(p, k)));
		}
	}
	
	public function mask(key:MaskingKey):Frame {
		return switch this.payload {
			case Unmasked(p): new FrameBase(this.fin, this.rsv1, this.rsv2, this.rsv3, this.opcode, Masked(Masker.mask(p, key), key));
			case Masked(_): this;
		}
	}
}

class FrameBase {
	public var fin(default, null):Bool;
	public var rsv1(default, null):Bool;
	public var rsv2(default, null):Bool;
	public var rsv3(default, null):Bool;
	public var opcode(default, null):Opcode;
	public var masked(get, never):Bool;
	public var payloadLength(get, never):Int;
	public var maskingKey(get, null):MaskingKey;
	public var payload(default, null):Payload;
	public var maskedPayload(get, null):Chunk;
	public var unmaskedPayload(get, null):Chunk;
	
	public function new(fin, rsv1, rsv2, rsv3, opcode, payload) {
		this.fin = fin;
		this.rsv1 = rsv1;
		this.rsv2 = rsv2;
		this.rsv3 = rsv3;
		this.opcode = opcode;
		this.payload = payload;
	}
	
	public static function fromChunk(chunk:Chunk):Frame {
		var bytes = chunk.toBytes();
		var data = bytes.getData();
		var length = bytes.length;
		var pos = 0;
		
		// first byte
		var c = Bytes.fastGet(data, pos++);
		var fin = (c >> 7 & 1) == 1;
		var rsv1 = (c >> 6 & 1) == 1;
		var rsv2 = (c >> 5 & 1) == 1;
		var rsv3 = (c >> 4 & 1) == 1;
		var opcode = c & 0xf;
		
		// second byte & length
		var c = Bytes.fastGet(data, pos++);
		var mask = c >> 7 == 1;
		var len = switch c & 127 {
			case 127: var l = 0; for(i in 0...8) l = l << 8 + Bytes.fastGet(data, pos++); l;
			case 126: var l = 0; for(i in 0...2) l = l << 8 + Bytes.fastGet(data, pos++); l;
			case v: v;
		}
		
		// masking key
		var maskingKey = 
			if(mask) {
				var key = bytes.sub(pos, 4);
				pos += 4;
				MaskingKey.ofChunk(key);
			} else null;
			
		// payload
		var payload = bytes.sub(pos, length - pos);
		
		return new FrameBase(fin, rsv1, rsv2, rsv3, opcode, maskingKey == null ? Unmasked(payload) : Masked(payload, maskingKey));
	}
	
	public function toChunk():Chunk {
		var out = new BytesBuffer();
		
		// first byte:
		out.addByte(
			(this.fin ? 1 << 7 : 0) |
			(this.rsv1 ? 1 << 6 : 0) |
			(this.rsv2 ? 1 << 5 : 0) |
			(this.rsv3 ? 1 << 4 : 0) |
			this.opcode
		);
		
		// second byte:
		out.addByte(
			(this.masked ? 1 << 7 : 0) |
			(this.payloadLength < 126 ? this.payloadLength : 126) // TODO: support 64-bit length
		);
		
		// extended payload length: (TODO: support 64-bit length)
		if(this.payloadLength >= 126) {
			out.addByte(this.payloadLength >> 8 & 0xff);
			out.addByte(this.payloadLength & 0xff);
		}
		
		// masking key:
		if(this.masked) out.addBytes(this.maskingKey.toBytes(), 0, 4);
		
		// payload:
		var payload = this.maskedPayload;
		out.addBytes(payload, 0, payload.length);
		
		return out.getBytes();
	}
	
	inline function get_maskingKey()
		return switch payload {
			case Masked(_, m): m;
			case Unmasked(_): null;
		}
	
	inline function get_masked()
		return payload.match(Masked(_));
	
	inline function get_payloadLength()
		return switch payload {
			case Unmasked(p) | Masked(p, _): p.length;
		}
		
	function get_maskedPayload() {
		return switch payload {
			case Unmasked(p) | Masked(p, _): p;
		}
	}
		
	function get_unmaskedPayload() {
		return switch payload {
			case Unmasked(p): p;
			case Masked(p, k): Masker.unmask(p, k);
		}
	}
}

@:enum
abstract Opcode(Int) from Int to Int {
	var Continuation = 0x0;
	var Text = 0x1;
	var Binary = 0x2;
	var ConnectionClose = 0x8;
	var Ping = 0x9;
	var Pong = 0xa;
}

enum Payload {
	Masked(masked:Chunk, key:MaskingKey);
	Unmasked(unmasked:Chunk);
}

class Masker {
	
	public static function mask(unmasked:Chunk, key:MaskingKey):Chunk {
		var masked = Bytes.alloc(unmasked.length);
		var data = unmasked.toBytes().getData();
		var key = key.toBytes().getData();
		for(i in 0...unmasked.length) masked.set(i, Bytes.fastGet(data, i) ^ Bytes.fastGet(key, i % 4));
		return masked;
	}
	
	public static inline function unmask(masked:Chunk, key:MaskingKey):Chunk {
		return mask(masked, key);
	}
		
}