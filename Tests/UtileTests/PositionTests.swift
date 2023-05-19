import XCTest
@testable import Utile

class PositionTests : ATestCase {
    lazy var p = [5,2,7]
    lazy var r = [5,6]
    lazy var q = [5,2,7,5,6]

    func testPrettyDescription() {
        XCTAssertEqual("ε", ε.prettyDescription)
        XCTAssertEqual("5.2.7", p.prettyDescription)
        XCTAssertEqual("5.2.7.5.6", q.prettyDescription)
        XCTAssertEqual("5.6", r.prettyDescription)
    }

    func testPrefix() {
        XCTAssertTrue( ε <= ε)
        XCTAssertTrue( ε <= p)
        XCTAssertTrue( ε <= q)
        XCTAssertTrue( ε <= r)

        XCTAssertFalse( p <= ε)
        XCTAssertTrue( p <= p)
        XCTAssertTrue( p <= q)
        XCTAssertFalse( p <= r)

        XCTAssertFalse( q <= ε)
        XCTAssertFalse( q <= p)
        XCTAssertTrue( q <= q)
        XCTAssertFalse( q <= r)

        XCTAssertFalse( r <= ε)
        XCTAssertFalse( r <= p)
        XCTAssertFalse( r <= q)
        XCTAssertTrue( r <= r)
    }

    func testStrictPrefix() {
        XCTAssertFalse( ε < ε)
        XCTAssertTrue( ε < p)
        XCTAssertTrue( ε < q)
        XCTAssertTrue( ε < r)

        XCTAssertFalse( p < ε)
        XCTAssertFalse( p < p)
        XCTAssertTrue( p < q)
        XCTAssertFalse( p < r)

        XCTAssertFalse( q < ε)
        XCTAssertFalse( q < p)
        XCTAssertFalse( q < q)
        XCTAssertFalse( q < r)

        XCTAssertFalse( r < ε)
        XCTAssertFalse( r < p)
        XCTAssertFalse( r < q)
        XCTAssertFalse( r < r)
    }

    func testParallel() {
        XCTAssertFalse( ε || ε)
        XCTAssertFalse( ε || p)
        XCTAssertFalse( ε || q)
        XCTAssertFalse( ε || r)

        XCTAssertFalse( p || ε)
        XCTAssertFalse( p || p)
        XCTAssertFalse( p || q)
        XCTAssertTrue( p || r)

        XCTAssertFalse( q || ε)
        XCTAssertFalse( q || p)
        XCTAssertFalse( q || q)
        XCTAssertTrue( q || r)

        XCTAssertFalse( r || ε)
        XCTAssertTrue( r || p)
        XCTAssertTrue( r || q)
        XCTAssertFalse( r || r)
    }

    func testPlus() {
        XCTAssertEqual( ε + ε, ε)
        XCTAssertEqual( ε + p, p)
        XCTAssertEqual( ε + q, q)
        XCTAssertEqual( ε + r, r)

        XCTAssertEqual( p + ε, p)
        XCTAssertEqual( p + p, [5,2,7,5,2,7])
        XCTAssertEqual( p + q, [5,2,7,5,2,7,5,6])
        XCTAssertEqual( p + r, [5,2,7,5,6])

        XCTAssertEqual( q + ε, q)
        XCTAssertEqual( q + p, [5,2,7,5,6,5,2,7])
        XCTAssertEqual( q + q, [5,2,7,5,6,5,2,7,5,6])
        XCTAssertEqual( q + r, [5,2,7,5,6,5,6])

        XCTAssertEqual( r + ε, r)
        XCTAssertEqual( r + p, [5,6,5,2,7])
        XCTAssertEqual( r + q, [5,6,5,2,7,5,6])
        XCTAssertEqual( r + r, [5,6,5,6])
    }

    func testMinus() {
        XCTAssertEqual( ε - ε, ε)
        XCTAssertEqual( ε - p, nil)
        XCTAssertEqual( ε - q, nil)
        XCTAssertEqual( ε - r, nil)

        XCTAssertEqual( p - ε, p)
        XCTAssertEqual( p - p, ε)
        XCTAssertEqual( p - q, nil)
        XCTAssertEqual( p - r, nil)

        XCTAssertEqual( q - ε, q)
        XCTAssertEqual( q - p, r)
        XCTAssertEqual( q - q, ε)
        XCTAssertEqual( q - r, nil)

        XCTAssertEqual( r - ε, r)
        XCTAssertEqual( r - p, nil)
        XCTAssertEqual( r - q, nil)
        XCTAssertEqual( r - r, ε)
    }



    func testEquals() {
        XCTAssertTrue( ε == ε)
        XCTAssertFalse( ε == p)
        XCTAssertFalse( ε == q)
        XCTAssertFalse( ε == r)

        XCTAssertFalse( p == ε)
        XCTAssertTrue( p == p)
        XCTAssertFalse( p == q)
        XCTAssertFalse( p == r)

        XCTAssertFalse( q == ε)
        XCTAssertFalse( q == p)
        XCTAssertTrue( q == q)
        XCTAssertFalse( q == r)

        XCTAssertFalse( r == ε)
        XCTAssertFalse( r == p)
        XCTAssertFalse( r == q)
        XCTAssertTrue( r == r)
    }
}
