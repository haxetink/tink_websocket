package;

import tink.testrunner.*;
import tink.unit.*;


class RunTests {
	static function main() {
		Runner.run(TestBatch.make([
			#if nodejs new TestWebSocket(), #end
			new TestClient(),
		])).handle(Runner.exit);
	}
}