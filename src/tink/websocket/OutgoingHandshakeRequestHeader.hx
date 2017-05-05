package tink.websocket;

import haxe.io.Bytes;
import haxe.crypto.*;
import tink.http.Request;
import tink.http.Header;
import tink.Url;

class OutgoingHandshakeRequestHeader extends OutgoingRequestHeader {
	
	public var key(default, null):String;
	public var accept(default, null):String;
	
	public function new(url:Url, ?key, ?fields) {
		super(GET, url.pathWithQuery, null, fields);
		
		this.key = switch key {
			case null: Base64.encode(Sha1.make(Bytes.ofString(Std.string(Math.random()))));
			default: key;
		}
		accept = Base64.encode(Sha1.make(Bytes.ofString(this.key + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11")));
		
		function fillHeader(name:String, value:String) {
			switch byName(name) {
				case Failure(_): this.fields.push(new HeaderField(name, value));
				default:
			}
		}
		
		fillHeader('host', url.host);
		fillHeader('upgrade', 'websocket');
		fillHeader('connection', 'upgrade');
		fillHeader('sec-websocket-key', this.key);
		fillHeader('sec-websocket-version', '13');
	}
}