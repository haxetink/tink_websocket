package;

import tink.testrunner.*;
import tink.unit.*;


class RunTests {
	static function main() {
		tink.websocket.IncomingHandshakeRequestHeader;
		Runner.run(TestBatch.make([
			#if nodejs new TcpConnectorTest(), #end
			#if nodejs new TcpAcceptorTest(), #end
			new ParserTest(),
			new ClientTest(),
			new HeaderTest(),
		])).handle(Runner.exit);
	}
}