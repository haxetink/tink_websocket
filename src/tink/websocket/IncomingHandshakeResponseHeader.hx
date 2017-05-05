package tink.websocket;

import tink.http.Response;
import tink.io.StreamParser;

using tink.CoreApi;

abstract IncomingHandshakeResponseHeader(ResponseHeader) from ResponseHeader to ResponseHeader {
	
	public function validate(accept:String) {
		if(this.statusCode != 101) return Failure(new Error('Unexpected response status code'));
		return switch this.byName('sec-websocket-accept') {
			case Success(v) if(v == accept): Success(Noise);
			default: Failure(new Error('Invalid accept'));
		}
	}
	
	public static inline function parser():StreamParser<IncomingHandshakeResponseHeader>
		return ResponseHeader.parser();
}