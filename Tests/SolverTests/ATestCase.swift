import Base
import CYices
import XCTest

@testable import Solver

public class ATestCase: XCTestCase {

  /// set up logging once _before_ all tests of a test class
  public override class func setUp() {
    super.setUp()
    Syslog.openLog(options: .console, .pid, .perror, verbosely: false)
  }

  /// teardown logging once _after_ all tests of a test class
  public override class func tearDown() {
    Syslog.closeLog()
    super.tearDown()
  }

  public func testTest() {
    print("*️⃣ ", type(of: self))
  }
}

public class YicesTestCase: ATestCase {

  typealias Context = Yices.Context

  static var context: Context?

  public override class func setUp() {
    super.setUp()
    YicesTestCase.context = Context()
  }

  /// teardown logging once _after_ all tests of a test class
  public override class func tearDown() {
    YicesTestCase.context = nil
    super.tearDown()
  }

}

public class Z3TestCase: ATestCase {

  typealias Context = Z3.Context

}
