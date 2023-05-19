//
// Created by Alexander on 17.08.22.
//

import XCTest
@testable import Solver
@testable import Tptp
import Utile
import Base
import CTptpParsing

class MiscTests: ATestCase {

    func testYicesContext() {
        let problem = "PUZ001-1"
        guard let file = Tptp.File(problem: problem) else {
            XCTFail("\(problem) was not found")
            return
        }
        XCTAssertTrue(file.identifier?.hasSuffix(problem + ".p") ?? false)
        XCTAssertFalse(file.containsIncludes)

        let context = Yices.Context()

        for cnf in file.cnfs {
            if let term = Tptp.Term.create(tree: cnf), let nodes = term.nodes, nodes.count == 2,
               let _ = nodes.first, let clause = nodes.last, let literals = clause.nodes {

                let ls = literals.map { literal in context.encode(literal: literal)!  }
                let c = context.disjunct(formulae: ls)

                context.assert(formula: c)
            }
        }

        XCTAssertTrue(context.isSatisfiable)
        XCTAssertNotNil(context.createModel())

        let count = file.symbols.reduce(0) { (a,b) in a + 1 }
        XCTAssertEqual(37, count)
    }

    func testZ3Context() {
        let problem = "PUZ001-1"
        guard let file = Tptp.File(problem: problem) else {
            XCTFail("\(problem) was not found")
            return
        }
        XCTAssertTrue(file.identifier?.hasSuffix(problem + ".p") ?? false)
        XCTAssertFalse(file.containsIncludes)

        let context = Z3.Context()

        for cnf in file.cnfs {
            if let term = Tptp.Term.create(tree: cnf), let nodes = term.nodes, nodes.count == 2,
               let _ = nodes.first, let clause = nodes.last, let literals = clause.nodes {

                let ls = literals.map { literal in context.encode(literal: literal)!  }
                let c = context.disjunct(formulae: ls)

                context.assert(formula: c)
            }
        }

        XCTAssertTrue(context.isSatisfiable)
        XCTAssertNotNil(context.createModel())

        let count = file.symbols.reduce(0) { (a,b) in a + 1 }
        XCTAssertEqual(37, count)
    }
}
