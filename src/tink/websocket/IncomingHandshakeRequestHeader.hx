package tink.websocket;

import tink.http.Request;
import tink.io.StreamParser;

using StringTools;
using tink.CoreApi;

abstract IncomingHandshakeRequestHeader(IncomingRequestHeader) from IncomingRequestHeader to IncomingRequestHeader {
	
	public var key(get, never):String;
	
	public function validate() {
		
		var errors = [];
		function ensureHeader(name:String, check:String->Bool) 
			switch this.byName(name) {
				case Failure(f): errors.push('Header $name not found');
				case Success(v) if(check(v)): // ok
				case Success(v): errors.push('Invalid header "$name: $v"');
			}
			
		ensureHeader('upgrade', function(v) return v == 'websocket');
		ensureHeader('connection', function(v) return v != null && [for(i in v.split(',')) i.trim().toLowerCase()].indexOf('upgrade') != -1);
		ensureHeader('sec-websocket-key', function(v) return v != null);
		ensureHeader('sec-websocket-version', function(v) return v == '13');
		
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