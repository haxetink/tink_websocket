package tink.websocket;

import tink.Chunk;
import tink.streams.Stream;

using tink.CoreApi;

@:forward
abstract RawMessageStream<Quality>(Stream<RawMessage, Quality>) to Stream<RawMessage, Quality> {
	
	public inline function append(other:RawMessageStream<Quality>):RawMessageStream<Quality>
		return this.append(other);
		
	public inline function prepend(other:RawMessageStream<Quality>):RawMessageStream<Quality>
		return this.prepend(other);
		
	public inline function filter(f:Filter<RawMessage, Quality>):RawMessageStream<Quality>
		return this.filter(f);
		
	public inline function blend(other:RawMessageStream<Quality>):RawMessageStream<Quality>
		return this.blend(other);
  
	@:from // `@:from` has higher priority than `from`, this prevents the value being inferred as chunk/frame stream
	public static inline function lift<Q>(s:Stream<RawMessage, Q>):RawMessageStream<Q>
		return cast s; // FIXME: the `cast` is to mitigate "Recursive implicit cast"
		
	@:from
	public static inline function ofChunkStream<Q>(s:Stream<Chunk, Q>):RawMessageStream<Q>
		return ofFrameStream(s.map(Frame.fromChunk));
	
	@:from
	public static inline function ofFrameStream<Q>(s:Stream<Frame, Q>):RawMessageStream<Q>
		return s.regroup(MessageRegrouper.get());
	
	public inline function toUnmaskedChunkStream():Stream<Chunk, Quality>
		return toMaskedChunkStream(function() return null);
	
	public inline function toUnmaskedFrameStream():Stream<Frame, Quality>
		return toMaskedFrameStream(function() return null);
	
	public function toMaskedChunkStream(key:Void->MaskingKey):Stream<Chunk, Quality>
		return toMaskedFrameStream(key).map(function(f:Frame) return f.toChunk());
	
	public function toMaskedFrameStream(key:Void->MaskingKey):Stream<Frame, Quality>
		return this.map(function(message) return Frame.ofMessage(message, key()));
}

class MessageRegrouper {
	public static function transform<Q>(s:Stream<Chunk, Q>)
		return s.map(Frame.fromChunk).regroup(get());
		
	public static function get<Q>():Regrouper<Frame, RawMessage, Q>
		return cast inst;
	
	static var inst:Regrouper<Frame, RawMessage, Noise> =
		function(frames:Array<Frame>, s) {
			var last = frames[frames.length - 1];
			if(!last.fin) return Untouched;
			
			function mergeBytes() {
				var out = Chunk.EMPTY;
				for(frame in frames) out = out & frame.unmaskedPayload;
				return out;
			}
			
			return Converted(Stream.single(switch frames[0].opcode {
				case Continuation:
					throw 'Unreachable'; // technically
				case Text:
					RawMessage.Text(mergeBytes().toString());
				case Binary:
					RawMessage.Binary(mergeBytes());
				case ConnectionClose:
					RawMessage.ConnectionClose;
				case Ping:
					RawMessage.Ping(mergeBytes());
				case Pong:
					RawMessage.Pong(mergeBytes());
			}));
		}
}