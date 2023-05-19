import XCTest

class ATestCase: XCTestCase {
  /// set up logging once _before_ all tests of a test class
  public override class func setUp() {
    super.setUp()
  }

  /// teardown logging once _after_ all tests of a test class
  public override class func tearDown() {
    super.tearDown()
  }

  public func testTest() {
    print("*️⃣ ", type(of: self))
  }
}
