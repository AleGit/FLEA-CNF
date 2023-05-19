import XCTest
@testable import Utile

class UnificationTests: ATestCase {

    func testBasics() {

        // trivial cases
        var σ = Σ() as Σ
        for t in [x, y, a, b, fx, gx, fa, fb, ga, gb, fxy, gxy, fab, fax, fxa, gxa] {
            XCTAssertEqual(σ, (t =?= t as Σ?)?.simplified())
        }

        // simple cases
        σ = [x: a]
        for (lhs, rhs) in [(a, x), (fax, fxx), (fxx, fxa), (fxa, fax)] {
            XCTAssertEqual(σ, lhs =?= rhs, "\(lhs) =?= \(rhs)")
            XCTAssertEqual(σ, rhs =?= lhs, "\(rhs) =?= \(lhs)")
        }

        σ = [x: fa]
        for (lhs, rhs) in [(x, fa)] {
            XCTAssertEqual(σ, lhs =?= rhs, "\(lhs) =?= \(rhs)")
            XCTAssertEqual(σ, rhs =?= lhs, "\(rhs) =?= \(lhs)")
        }

        // variants
        σ = [x: y]
        for (lhs, rhs) in [(fx, fx * σ)] {
            XCTAssertTrue((lhs =?= rhs as Σ?)?.isRenamingOf(size:1) ?? false, "\(lhs) =?= \(rhs)")
            XCTAssertTrue((rhs =?= lhs as Σ?)?.isRenamingOf(size:1) ?? false, "\(rhs) =?= \(lhs)")
        }

        // variants
        σ = [x: y]
        for (lhs, rhs) in [(fxy, fxy * σ)] {
            let z = max(lhs.variables.count, rhs.variables.count)
            XCTAssertTrue((lhs =?= rhs as Σ?)?.isVariableSubstitution ?? false, "\(lhs) =?= \(rhs)")
            XCTAssertTrue((rhs =?= lhs as Σ?)?.isVariableSubstitution ?? false, "\(rhs) =?= \(lhs)")
            XCTAssertFalse((lhs =?= rhs as Σ?)?.isRenamingOf(size:z) ?? false, "\(lhs) =?= \(rhs)")
            XCTAssertFalse((rhs =?= lhs as Σ?)?.isRenamingOf(size:z) ?? false, "\(rhs) =?= \(lhs)")
        }

        // not unifiable
        for (lhs, rhs) in [(a, b),
                           (x, fx), (x, fax),
                           (fa, fb), (fxa, gxa),
        ] {
            XCTAssertNil(lhs =?= rhs as Σ?, "\(lhs) =?= \(rhs)")
            XCTAssertNil(rhs =?= lhs as Σ?, "\(rhs) =?= \(lhs)")

        }
    }

    func testMultiple() {

    }
}
