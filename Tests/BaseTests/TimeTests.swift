import XCTest
@testable import Base

class TimeTests : ATestCase {

    func testMeasure() {
        let f = {
            () -> Time.Triple in
            let (_, t) = Time.measure {
            }
            return t
        }
        let (inner, outer) = Time.measure {
            return f()
        }

        XCTAssertTrue(inner.absolute < outer.absolute, "\(inner.absolute) ≥ \(outer.absolute)")
    }
}
