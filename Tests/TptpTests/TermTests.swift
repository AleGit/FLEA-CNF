@testable import Tptp
import CTptpParsing
import XCTest

final class TermTests: ATestCase {
    typealias N = Tptp.Term

    let x = N.variable("X")
    let c = N.constant("c")
    let fxc = N.function("f", nodes: [N.variable("X"), N.constant("c")])
    let p = N.predicate("p",
            nodes: [
                N.variable("X"),
                N.constant("c"),
                N.function("f", nodes: [N.variable("X"), N.constant("c")])
            ]
    )

    lazy var eq = N.term(PRLC_EQUATIONAL, "=", nodes: [x,c])
    lazy var ne = N.term(PRLC_EQUATIONAL, "!=", nodes: [c,x])
    

    func testVariable() {
        XCTAssertEqual("X", x.symbol)
        XCTAssertEqual(0, x.key)
        XCTAssertEqual(PRLC_VARIABLE, x.type)
        XCTAssertNil(x.nodes)

        XCTAssertEqual([[-1]], x.paths)
    }

    func testConstant() {

        XCTAssertEqual("c", c.symbol)
        XCTAssertEqual(1, c.key)
        XCTAssertEqual(PRLC_VARIABLE, x.type)
        XCTAssertEqual(0, c.nodes?.count)

        XCTAssertEqual([[1]], c.paths)
    }

    func testFunction() {
        XCTAssertEqual("f", fxc.symbol)
        XCTAssertEqual(2, fxc.key)
        XCTAssertEqual(PRLC_FUNCTION, fxc.type)
        XCTAssertEqual(2, fxc.nodes?.count)

        // sharing!
        XCTAssertTrue(fxc.nodes?.first === x)
        XCTAssertTrue(fxc.nodes?.last === c)

        XCTAssertEqual([[2,0,-1], [2,1,1]], fxc.paths)
    }

    func testPredicate() {
        XCTAssertEqual("p", p.symbol)
        XCTAssertEqual(3, p.key)
        XCTAssertEqual(PRLC_PREDICATE, p.type)
        XCTAssertEqual(3, p.nodes?.count)

        XCTAssertTrue(p.nodes?[0] === x)
        XCTAssertTrue(p.nodes?[1] === c)
        XCTAssertTrue(p.nodes?[2] === fxc)

        XCTAssertEqual([ [3,0,-1], [3,1,1], [3,2,2,0,-1], [3,2,2,1,1] ], p.paths)
        XCTAssertEqual(p, p.negated?.negated)
    }

    func testEquation() {
        XCTAssertEqual("=", eq.symbol)
        XCTAssertEqual("!=", ne.symbol)
        XCTAssertEqual([[eq.key,0,-1], [eq.key,1,1]], eq.paths)
        XCTAssertEqual([[ne.key,0,1], [ne.key,1,-1]], ne.paths)

        XCTAssertEqual(eq, eq.negated?.negated)
        XCTAssertEqual(ne, ne.negated?.negated)
    }
}
