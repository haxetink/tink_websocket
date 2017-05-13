package;

import tink.testrunner.*;
import tink.unit.*;


class RunTests {
	static function main() {
		Runner.run(TestBatch.make([
			#if nodejs new ConnectorTest(), #end
			#if nodejs new AcceptorTest(), #end
			new ParserTest(),
			new ClientTest(),
		])).handle(Runner.exit);
	}
}