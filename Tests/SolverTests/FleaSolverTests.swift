import XCTest
import Tptp
import Utile
@testable import Solver

class FleaSolverTests: ATestCase {

    func testBruteForce() {
        guard let file = Tptp.File(problem: "PUZ001-1") else {
            XCTFail()
            return
        }


        let start = Date.now

        var heap = Set<[Tptp.Term]>()

        var fileClauses = file.namedClauses
        fileClauses.append(contentsOf: file.namedAxioms)

        if let axioms = Tptp.Term.typedSymbols.equalityAxioms {
            fileClauses.append(contentsOf: axioms)
        }

        var clauses = fileClauses.compactMap { clause -> Tptp.NamedClause? in
            let (inserted, _) = heap.insert(clause.literals)
            return inserted ? clause : nil
        }

        print("clauses: \(clauses.count) (\(fileClauses.count))")
        let context = Yices.Context()
        var trie = PrefixTree<Pair<Int,Int>, Int>()

        var clauseIndex = 0

        while clauseIndex < clauses.count {
            defer { clauseIndex += 1 }
            let clause = clauses[clauseIndex]
            let literals = clause.literals
            if clauseIndex % 100 == 0 || clauseIndex == clauses.count - 1 {
                print(clauseIndex, "of", clauses.count, Date.now.timeIntervalSince(start).pretty, clause.literals)
            }

            let encoded = context.encode(literals: literals)
            context.assert(clause: encoded)

            guard context.isSatisfiable else {
                print("UNSAT", file.headers[.Status])
                return
            }




            for (literalIndex, literal) in literals.enumerated() {
                let negated = literal.lowercased.negated!

                if let candidates = trie.unifiables(paths: negated.paths, wildcard: Tptp.Term.wildcard) {
                    for candidateLocator in candidates {
                        let candidateClause = clauses[candidateLocator.lhs]
                        let candidateLiteral = candidateClause.literals[candidateLocator.rhs]

                        if let unifier: [Tptp.Term : Tptp.Term] = negated =?= candidateLiteral {
                            // print(negated, "=?=", candidateLiteral, "->", unifier)
                            let lhs = clause.literals.map { ($0.lowercased * unifier).uppercased }
                            let rhs = candidateClause.literals.map { ($0 * unifier) }
                            let (linserted, _) = heap.insert(lhs)
                            let (rinserted, _) = heap.insert(rhs)
                            // print(linserted, lhs)
                            // print(rinserted, rhs)

                            if linserted { clauses.append(Tptp.NamedClause(name: clause.name + "+" + candidateClause.name, role: .conflict, literals: lhs)) }
                            if rinserted { clauses.append(Tptp.NamedClause(name: candidateClause.name + "+" + clause.name, role: .conflict, literals: rhs)) }


                        } else {
                            // print(negated, "=/=", candidateLiteral)
                        }



                    }
                }



                let locator = Pair(clauseIndex, literalIndex)
                let paths = literal.paths
                for path in paths {
                    trie.insert(locator, at: path)
                }

            }






        }

        print("SAT", file.headers[.Status])
    }

}