import Base
import XCTest

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
