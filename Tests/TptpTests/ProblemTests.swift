import Base
import CTptpParsing
import Foundation
import XCTest
import CYices
import CZ3Api
import Utile

@testable import Tptp
@testable import Solver

public class ProblemTests: ATestCase {

  func testPUZ001m1() {
    guard let file = Tptp.File(problem: "PUZ001-1"),
      let node = Tptp.Term.create(file: file),
      let nodes = node.nodes
    else {
      XCTFail()
      return
    }

    XCTAssertTrue(node.symbol.hasSuffix("PUZ001-1.p"))

    for child in nodes {
      XCTAssertEqual(PRLC_CNF, child.type, child.description)

      guard let cnf_formula = child.nodes?[1] else {
        XCTFail()
        return
      }
      XCTAssertEqual("|", cnf_formula.symbol, cnf_formula.description)
      XCTAssertEqual(PRLC_CONNECTIVE, cnf_formula.type, cnf_formula.description)
    }

    XCTAssertEqual(nodes.count, 12)

    let cnf0 = nodes[0] // first cnf_formula
    XCTAssertEqual(cnf0.description, "cnf(agatha,hypothesis,\n\t( lives(agatha) )).")
    XCTAssertEqual(cnf0.symbol, "agatha")
    XCTAssertEqual(cnf0.type, PRLC_CNF)

    let role = cnf0.nodes![0]
    XCTAssertEqual(role.description, "hypothesis")
    XCTAssertEqual(role.symbol, "hypothesis")
    XCTAssertEqual(role.type, PRLC_ROLE)

    let clause = cnf0.nodes![1]
    XCTAssertEqual(clause.description, "lives(agatha)")
    XCTAssertEqual(clause.symbol, "|")
    XCTAssertEqual(clause.type, PRLC_CONNECTIVE)
    XCTAssertEqual(clause.nodes!.count, 1)

    let equation = clause.nodes![0]
    XCTAssertEqual(equation.description, "lives(agatha)")
    XCTAssertEqual(equation.symbol, "lives")
    XCTAssertEqual(equation.type, PRLC_PREDICATE)
    XCTAssertEqual(equation.type, Tptp.Term.predicate)
  }

  func testPUZ051m10() {
    guard let file = Tptp.File(problem: "PUZ051-10"),
          let node = Tptp.Term.create(file: file),
          let nodes = node.nodes
    else {
      XCTFail()
      return
    }

    XCTAssertTrue(node.symbol.hasSuffix("PUZ051-10.p"))

    for child in nodes {
      XCTAssertEqual(PRLC_CNF, child.type, child.description)

      guard let cnf_formula = child.nodes?[1] else {
        XCTFail()
        return
      }
      XCTAssertEqual("|", cnf_formula.symbol, cnf_formula.description)
      XCTAssertEqual(PRLC_CONNECTIVE, cnf_formula.type, cnf_formula.description)
    }

    XCTAssertEqual(nodes.count, 44)

    let cnf0 = nodes[0] // first cnf_formula
    XCTAssertEqual(cnf0.description, "cnf(ifeq_axiom,axiom,\n\t( ifeq(A,A,B,C) = B )).")
    XCTAssertEqual(cnf0.symbol, "ifeq_axiom")
    XCTAssertEqual(cnf0.type, PRLC_CNF)

    let role = cnf0.nodes![0]
    XCTAssertEqual(role.description, "axiom")
    XCTAssertEqual(role.symbol, "axiom")
    XCTAssertEqual(role.type, PRLC_ROLE)

    let clause = cnf0.nodes![1]
    XCTAssertEqual(clause.description, "ifeq(A,A,B,C) = B")
    XCTAssertEqual(clause.symbol, "|")
    XCTAssertEqual(clause.type, PRLC_CONNECTIVE)
    XCTAssertEqual(clause.nodes!.count, 1)

    let equation = clause.nodes![0]
    XCTAssertEqual(equation.description, "ifeq(A,A,B,C) = B")
    XCTAssertEqual(equation.symbol, "=")
    XCTAssertEqual(equation.type, PRLC_EQUATIONAL)
    XCTAssertEqual(equation.type, Tptp.Term.equational)

  }

  func testPUZ020m1() {
    guard let file = Tptp.File(problem: "PUZ020-1.p"),
          let node = Tptp.Term.create(file: file),
          let nodes = node.nodes
    else {
      XCTFail()
      return
    }

    XCTAssertTrue(node.symbol.hasSuffix("PUZ020-1.p"))

    for child in nodes {
      XCTAssertEqual(PRLC_CNF, child.type, child.description)

      guard let cnf_formula = child.nodes?[1] else {
        XCTFail()
        return
      }
      XCTAssertEqual("|", cnf_formula.symbol, cnf_formula.description)
      XCTAssertEqual(PRLC_CONNECTIVE, cnf_formula.type, cnf_formula.description)
    }

    XCTAssertEqual(nodes.count, 19)

    let cnf3 = nodes[3] // first cnf_formula
    XCTAssertEqual(cnf3.description, "cnf(people_do_not_equal_their_statements1,axiom,\n\t( ~says(X,Y) | X != Y )).")
    XCTAssertEqual(cnf3.symbol, "people_do_not_equal_their_statements1")
    XCTAssertEqual(cnf3.type, PRLC_CNF)

    let role = cnf3.nodes![0]
    XCTAssertEqual(role.description, "axiom")
    XCTAssertEqual(role.symbol, "axiom")
    XCTAssertEqual(role.type, PRLC_ROLE)

    let clause = cnf3.nodes![1]
    XCTAssertEqual(clause.description, "~says(X,Y) | X != Y")
    XCTAssertEqual(clause.symbol, "|")
    XCTAssertEqual(clause.type, PRLC_CONNECTIVE)
    XCTAssertEqual(clause.nodes!.count, 2)

    let yContext = Yices.Context()
    let yClause = yContext.encode(clause: clause)
    let yLiterals = clause.nodes!.map { t in yContext.encode(literal: t)!  }
    yContext.assert(formula: yClause!)
    XCTAssertTrue(yContext.isSatisfiable)
    let yModel = yContext.createModel()!
    XCTAssertTrue(yModel.satisfies(formula: yLiterals[0])!)
    XCTAssertFalse(yModel.satisfies(formula: yLiterals[1])!)

    let zContext = Z3.Context()
    let zClause = zContext.encode(clause: clause)
    let zLiterals = clause.nodes!.map { t in zContext.encode(literal: t)!  }
    zContext.assert(formula: zClause!)
    XCTAssertTrue(zContext.isSatisfiable)
    let zModel = zContext.createModel()!
    XCTAssertTrue(zModel.satisfies(formula: zLiterals[0])!)
    XCTAssertFalse(zModel.satisfies(formula: zLiterals[1])!)



    print("tptp ", clause,
            clause.nodes![0],
            clause.nodes![1],
            separator: " • ")
    print("Yices", yContext.string(formula: yClause!)!,
            yContext.string(formula: yLiterals[0])!,
            yContext.string(formula: yLiterals[1])!,
            yClause!, yLiterals[0], yLiterals[1],
            separator: " • ")
    print("Z3   ", zContext.string(formula: zClause!)!,
            zContext.string(formula: zLiterals[0])!,
            zContext.string(formula: zLiterals[1])!,
            zClause!, zLiterals[0], zLiterals[1],
            separator: " • ")




    let inequation = clause.nodes![1]
    XCTAssertEqual(inequation.description, "X != Y")
    XCTAssertEqual(inequation.symbol, "!=")
    XCTAssertEqual(inequation.type, PRLC_EQUATIONAL)
    XCTAssertEqual(inequation.type, Tptp.Term.equational)

  }

  func _testHWV134m1() {
    guard let tptpFile = Tptp.File(problem: "HWV134-1"),
      let tptpFileNode = Tptp.Term.create(file: tptpFile),
      let nodes = tptpFileNode.nodes
    else {
      XCTFail()
      return
    }

    XCTAssertTrue(tptpFileNode.symbol.hasSuffix("/HWV/HWV134-1.p"))

    var count = 0

    for annotatedFormula in nodes {
      XCTAssertEqual(PRLC_CNF, annotatedFormula.type, annotatedFormula.symbol)

      guard let cnf_formula = annotatedFormula.nodes?.last else {
        XCTFail()
        return
      }
      XCTAssertEqual("|", cnf_formula.symbol)
      XCTAssertEqual(PRLC_CONNECTIVE, cnf_formula.type)
      count += 1
    }

    XCTAssertEqual(2_332_428, count, nok)
  }

  func testNegatedLiterals() {
    let problem = "HWV101-1"
    guard let tptpFile = Tptp.File(problem: problem) else {
      XCTFail("'\(problem)' could not be read")
      return
    }

    XCTAssertEqual(0, tptpFile.namedAxioms.count)

    let clauses = tptpFile.namedClauses
    XCTAssertEqual(18527, clauses.count)

    for clause in clauses {
      for literal in clause.literals {
        switch (literal.type, literal.symbol) {
        case (Tptp.Term.equational, "!="):
          if let negated = literal.negated {
            XCTAssertEqual("=", negated.symbol)
            XCTAssertEqual(literal.nodes, negated.nodes)
            XCTAssertEqual(literal, negated.negated)
          } else {
            XCTFail("\(literal) was not negated")
          }

        case (Tptp.Term.equational, "="):
          if let negated = literal.negated {
            XCTAssertEqual("!=", negated.symbol)
            XCTAssertEqual(literal.nodes, negated.nodes)
            XCTAssertEqual(literal, negated.negated)
          } else {
            XCTFail("\(literal) was not negated")
          }

        case (Tptp.Term.predicate, let symbol):
          if let negated = literal.negated {
            XCTAssertEqual("~", negated.symbol)
            XCTAssertEqual(1, negated.nodes?.count ?? -1)
            XCTAssertEqual(symbol, negated.nodes?.first?.symbol ?? "n/a")
            XCTAssertEqual(literal, negated.negated)
          } else {
            XCTFail("\(literal) was not negated")
          }


        case (Tptp.Term.connective, "~"):
          XCTAssertEqual(1, literal.nodes?.count ?? -1)
          XCTAssertFalse(literal.nodes?.first?.symbol == "=") // ~ (a = b) is never used, a != b is used instead
          if let negated = literal.negated {
            XCTAssertEqual(literal.nodes?.first?.symbol ?? "n/a", negated.symbol)
            XCTAssertEqual(literal, negated.negated)
          } else {
            XCTFail("\(literal) was not negated")
          }

        case (let type, _):
          XCTFail("\(literal) should be negatable! Is \(type) a literal type?")
        }

      }
    }
  }

  func testClashingLiterals() {
    struct LiteralIndex: Hashable {
      let clauseIndex: Int
      let literalIndex: Int
    }

    let problem = "HWV101-1"
    guard let tptpFile = Tptp.File(problem: problem) else {
      XCTFail("'\(problem)' could not be read")
      return
    }

    XCTAssertEqual(0, tptpFile.namedAxioms.count)

    var trie = PrefixTree<LiteralIndex, Int>()

    let clauses = tptpFile.namedClauses
    XCTAssertEqual(18527, clauses.count)

    var dictionary = [Tptp.Term: Set<LiteralIndex>]()

    for (cidx, clause) in clauses.enumerated() {
      for (lidx, literal) in clause.literals.enumerated() {
        for path in literal.paths {
          trie.insert(LiteralIndex(clauseIndex: cidx, literalIndex: lidx), at: path)
          guard let negated = literal.negated else {
            XCTFail()
            return
          }
          guard let candidateIndices = trie.unifiables(paths: negated.paths, wildcard: Tptp.Term.wildcard) else {
            continue
          }
          let previousIndices = dictionary[literal] ?? Set<LiteralIndex>()
          XCTAssertTrue(candidateIndices.isSuperset(of: previousIndices))
          dictionary[literal] = candidateIndices

          let candidates = candidateIndices.map { (index: LiteralIndex) -> Tptp.Term in
            clauses[index.clauseIndex].literals[index.literalIndex]
          }

          XCTAssertEqual(candidateIndices.count, candidates.count)

          for candidate in candidates {
            XCTAssertEqual(negated.symbol, candidate.symbol)
            XCTAssertEqual(negated.nodes?.count, candidate.nodes?.count)



          }
        }
      }
    }

    let result = dictionary.map { key, value -> (Tptp.Term, Int) in
              (key, value.count)
            }
            .sorted { (a,b) in
            a.1 < b.1
            }

    print(result.first!.0, "...", result.count, "...", result.last!.0)
  }
}
