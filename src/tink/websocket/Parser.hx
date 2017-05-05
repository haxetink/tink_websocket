package tink.websocket;

import haxe.ds.Option;
import tink.io.StreamParser;
import tink.Chunk;
import tink.chunk.*;

using tink.CoreApi;

class Parser implements StreamParserObject<Chunk> {
	var mask:Bool; // mask bit of the frame
	var length = 0; // total length of frame
	var required = 0; // required length for next read
	var out:Chunk;
	
	public function new() {
		reset();
	}
	
	public function eof(rest:ChunkCursor) {
		return switch progress(rest) {
			case Done(result): Success(result);
			case Progressed: Failure(new Error('Unexpected end of input'));
			case Failed(e): Failure(e);
		}
	}
	
	public function progress(cursor:ChunkCursor) {
		if(cursor.length < required) return Progressed;
		return switch length {
			case 0:
				cursor.next();
				var secondByte = cursor.currentByte;
				mask = secondByte >> 7 == 1;
				required = switch secondByte & 127 {
					case 127: length = -2; 8;
					case 126: length = -1; 2;
					case len: length = len + 2 + (mask ? 4 : 0); length - 2;
				}
				cursor.next();
				out = out & cursor.left();
				Progressed;
			
			case -1 | -2:
				length = 0;
				for(i in 0...required) {
					length = length << 8 + cursor.currentByte;
					cursor.next();
				}
				length += 2 + required + (mask ? 4 : 0);
				required = length - 2 - required;
				out = out & cursor.left();
				Progressed;
			
			default:
				var ret = Done(out & cursor.right().slice(0, required));
				cursor.moveBy(required);
				reset();
				ret;
		}
	}
	
	function reset() {
		out = Chunk.EMPTY;
		length = 0;
		required = 2;
	}
}