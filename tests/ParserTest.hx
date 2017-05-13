package;

import haxe.io.Bytes;
import tink.streams.Stream;
import tink.websocket.*;
import tink.Chunk;

using tink.CoreApi;
using tink.io.Source;

@:asserts
class ParserTest {
	public function new() {}
	
	@:variant((this.arrayToBytes([129, 131, 61]):tink.io.Source.IdealSource).append(this.arrayToBytes([84, 35, 6, 112, 16, 109])), '81833d54230670106d', '3d542306', '70106d', 'MDN')
	@:variant(this.arrayToBytes([129, 131, 61, 84, 35, 6, 112, 16, 109]), '81833d54230670106d', '3d542306', '70106d', 'MDN')
	@:variant(tink.Chunk.ofHex('818823fb87c8539afea44c9ae3f9'), '818823fb87c8539afea44c9ae3f9', '23fb87c8', '539afea44c9ae3f9', 'payload1')
	public function parseSingleFrame(source:IdealSource, whole:String, key:String, masked:String, unmasked:String) {
		source.parseStream(new Parser()).forEach(function(chunk:Chunk) {
			var frame:Frame = chunk;
			asserts.assert(chunk.toBytes().toHex() == whole);
			asserts.assert(frame.fin == true);
			asserts.assert(frame.opcode == 1);
			asserts.assert(frame.masked == true);
			asserts.assert(frame.maskingKey.toHex() == key);
			asserts.assert(frame.maskedPayload.toHex() == masked);
			asserts.assert(frame.unmaskedPayload.toString() == unmasked);
			return Resume;
		}).handle(function(o) {
			asserts.assert(o == Depleted);
			asserts.done();
		});
		return asserts;
	}
	
	public function parseConsecutiveFrame() {
		var frame = [129, 131, 61, 84, 35, 6, 112, 16, 109];
		var source:IdealSource = arrayToBytes(frame.concat(frame).concat(frame));
		var num = 0;
		source.parseStream(new Parser()).forEach(function(chunk:Chunk) {
			asserts.assert(chunk.toBytes().toHex() == '81833d54230670106d');
			var frame:Frame = chunk;
			asserts.assert(frame.fin == true);
			asserts.assert(frame.opcode == 1);
			asserts.assert(frame.masked == true);
			asserts.assert(frame.maskingKey.toHex() == '3d542306');
			asserts.assert(frame.maskedPayload.toHex() == '70106d');
			asserts.assert(frame.unmaskedPayload.toString() == 'MDN');
			num++;
			return Resume;
		}).handle(function(o) {
			asserts.assert(o == Depleted);
			asserts.assert(num == 3);
			asserts.done();
		});
		return asserts;
	}
	
	function arrayToBytes(a:Array<Int>):Chunk {
		var bytes = Bytes.alloc(a.length);
		for(i in 0...a.length) bytes.set(i, a[i]);
		return bytes;
	}
}