import Base
import Solver
import XCTest

class Z3ContextPublicTests: Z3TestCase {

  func testVersion() {
    #if os(macOS)
    let expected = "Z3 • 4.12.1.0"
    #else
    let expected = "Z3 • 4.8.12.0"
    #endif
    let context = Z3.Context()
    let actual = context.name + " • " + context.version

    Syslog.notice { actual }
    XCTAssertEqual(expected, actual)
    Syslog.debug { Z3.Context().name }
  }
}
