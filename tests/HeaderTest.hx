package;

import tink.websocket.*;
import tink.http.Request;
import tink.http.Header;

@:asserts
class HeaderTest {
	public function new() {}
	
	public function connection() {
		var header:IncomingHandshakeRequestHeader = new IncomingRequestHeader(null, null, [
			new HeaderField('upgrade', 'websocket'),
			new HeaderField('connection', 'keep-alive, upgrade'),
			new HeaderField('sec-websocket-key', ''),
			new HeaderField('sec-websocket-version', '13'),
		]);
		asserts.assert(header.validate());
		return asserts.done();
	}
}