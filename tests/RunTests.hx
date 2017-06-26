package;

import tink.testrunner.*;
import tink.unit.*;


class RunTests {
	static function main() {
		tink.websocket.servers.TheServer;
		Runner.run(TestBatch.make([
			#if nodejs new ConnectorTest(), #end
			#if nodejs new AcceptorTest(), #end
			new ParserTest(),
			new ClientTest(),
		])).handle(Runner.exit);
	}
}