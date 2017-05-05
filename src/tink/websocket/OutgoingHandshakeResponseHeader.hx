package tink.websocket;

import haxe.io.Bytes;
import haxe.crypto.*;
import tink.http.Response;
import tink.http.Header;

class OutgoingHandshakeResponseHeader extends ResponseHeader {
	
	public var key(default, null):String;
	public var accept(default, null):String;
	
	public function new(key, ?fields) {
		super(101, 'Switching Protocols', fields);
		
		accept = Base64.encode(Sha1.make(Bytes.ofString(key + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11")));
		
		function fillHeader(name:String, value:String) {
			switch byName(name) {
				case Failure(_): this.fields.push(new HeaderField(name, value));
				default:
			}
		}
		
		fillHeader('upgrade', 'websocket');
		fillHeader('connection', 'upgrade');
		fillHeader('sec-websocket-accept', accept);
	}
}