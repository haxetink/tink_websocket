package tink.websocket;

import tink.streams.Stream;

@:forward
abstract MessageStream<Q>(Stream<Message, Q>) from Stream<Message, Q> to Stream<Message, Q> {
	@:from
	public static function fromRawStream<Q>(raw:RawMessageStream<Q>):MessageStream<Q>
		return raw.regroup(function(m:Array<RawMessage>):RegroupResult<RawMessage, Message, Q> return Converted(switch m[0] {
			case Text(v): Stream.single(Message.Text(v));
			case Binary(v): Stream.single(Message.Binary(v));
			default: Empty.make();
		}));
	
	@:to
	public function toRawStream():RawMessageStream<Q>
		return this.regroup(function(m:Array<Message>) return Converted(switch m[0] {
			case Text(v): Stream.single(RawMessage.Text(v));
			case Binary(v): Stream.single(RawMessage.Binary(v));
		}));
}