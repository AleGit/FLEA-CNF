import XCTest
@testable import Base

class SequenceTests: ATestCase {
    func predicate(_ number: Int) -> Bool {
        return number % 2 == 0
    }

    func testAll() {
        XCTAssertTrue([2, 4, 6].all(predicate))
        XCTAssertFalse([2, 4, 7].all(predicate))
        XCTAssertFalse([3, 5, 7].all(predicate))
    }

    func testOne() {
        XCTAssertTrue([2, 4, 6].one(predicate))
        XCTAssertTrue([2, 4, 7].one(predicate))
        XCTAssertFalse([3, 5, 7].one(predicate))
    }

    func testCount() {
        XCTAssertEqual(3, [2, 4, 6].count(predicate))
        XCTAssertEqual(2, [2, 4, 7].count(predicate))
        XCTAssertEqual(0, [3, 5, 7].count(predicate))
    }

}
