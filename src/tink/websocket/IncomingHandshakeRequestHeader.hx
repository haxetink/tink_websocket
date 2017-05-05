package tink.websocket;

import tink.http.Request;
import tink.io.StreamParser;

using tink.CoreApi;

abstract IncomingHandshakeRequestHeader(IncomingRequestHeader) from IncomingRequestHeader to IncomingRequestHeader {
	
	public var key(get, never):String;
	
	public function validate() {
		
		var errors = [];
		function ensureHeader(name:String, ?value:String) 
			switch this.byName(name) {
				case Failure(f): errors.push('Header $name not found');
				case Success(v) if(value == null || (v:String).toLowerCase() == value): // ok
				case Success(v): errors.push('Header value for $name is expected to be $value, but got $v');
			}
			
		ensureHeader('upgrade', 'websocket');
		ensureHeader('connection', 'upgrade');
		ensureHeader('sec-websocket-key');
		ensureHeader('sec-websocket-version', '13');
		
		return 
			if(errors.length > 0)
				Failure(Error.withData('Invalid request header', errors));
			else
				Success(Noise);
	}
	
	inline function get_key() return this.byName('sec-websocket-key').sure();
	
	public static inline function parser():StreamParser<IncomingHandshakeRequestHeader>
		return IncomingRequestHeader.parser();
}