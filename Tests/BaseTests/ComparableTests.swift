import XCTest
@testable import Base

final class ComparableTests: ATestCase {
    func testEmbank() {
        XCTAssertEqual(5, embank(lo: 4, hi: 6, 5))
        XCTAssertEqual(5, embank(lo: 5, hi: 6, 5))
        XCTAssertEqual(5, embank(lo: 5, hi: 5, 5))
        XCTAssertEqual(5, embank(lo: 4, hi: 5, 5))

        XCTAssertEqual(5, embank(lo: 5, hi: 6, 4))
        XCTAssertEqual(5, embank(lo: 5, hi: 5, 4))
        XCTAssertEqual(5, embank(lo: 5, hi: 5, 6))
        XCTAssertEqual(5, embank(lo: 4, hi: 5, 6))

        XCTAssertNil(embank(lo: 6, hi: 5, 5))
        XCTAssertNil(embank(lo: 6, hi: 4, 5))
        XCTAssertNil(embank(lo: 5, hi: 4, 5))
    }
}
