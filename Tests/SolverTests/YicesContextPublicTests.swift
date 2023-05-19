import Base
import Solver
import XCTest

class YicesContextPublicTests : YicesTestCase {

    func testVersion() {
        let expected = "Yices2 • 2.6.4"
        let context = Yices.Context()
        let actual = context.name + " • " + context.version

        Syslog.notice { actual }
        Syslog.debug { Yices.Context().name }
        XCTAssertEqual(expected, actual)
    }
}
