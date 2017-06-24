package tink.websocket;

import tink.websocket.RawMessage;
import tink.streams.Stream;

@:forward
abstract PongStream<Q>(RawMessageStream<Q>) to RawMessageStream<Q> {
	public function new(raw:RawMessageStream<Q>)
		this = raw.regroup(function(m) return Converted(switch m[0] {
			case Ping(v): Stream.single(Pong(v));
			default: Empty.make();
		}));
}