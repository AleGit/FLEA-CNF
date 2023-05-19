import Foundation
import Base
import Tptp

struct Demo {
    static func syslog() {
        let (_, t) = Time.measure {

            Syslog.notice {
                "{ \(Syslog.defaultLogLevel), \(Syslog.logLevel()) } ⊆ [ \(Syslog.minimalLogLevel), \(Syslog.maximalLogLevel) ]"
            }
            Syslog.multiple {
                "💤"
            }
        }
        Syslog.notice { "time: \(t)"}
    }

    static func measure() {
        let (_, x) = Time.measure {
            // testHWV134m1()
            puz0001m1()
        }
        Syslog.debug { "\(x)" }
    }
}

extension Demo {
    static func hwv134m1() {
        guard let tptpFile = Tptp.File(problem: "HWV134-1"),
              let tptpFileNode = Tptp.Term.create(file: tptpFile),
              let nodes = tptpFileNode.nodes
        else {
            print("FAIL \(#line)")
            return
        }

        assert(tptpFileNode.symbol.hasSuffix("HWV134-1.p"))

        var count = 0

        for annotatedFormula in nodes {
            // assert(PRLC_CNF, annotatedFormula.type == annotatedFormula.symbol)

            guard let cnf_formula = annotatedFormula.nodes?.last else {
                print("FAIL \(#line)")
                return
            }
            assert("|" == cnf_formula.symbol)
            // assert(PRLC_CONNECTIVE == cnf_formula.type)
            count += 1
        }

        assert(2_332_428 == count, nok)
    }

    static func puz0001m1() {
        guard let tptpFile = Tptp.File(problem: "PUZ001-1"),
              let tptpFileNode = Tptp.Term.create(file: tptpFile),
              let nodes = tptpFileNode.nodes
        else {
            print("FAIL \(#line)")
            return
        }
        print(tptpFileNode.symbol)
        assert(tptpFileNode.symbol.hasSuffix("PUZ001-1.p"), tptpFileNode.symbol)
        assert(12 == nodes.count, "\(nodes.count)")
    }
}

extension Demo {
    static func tptpTermSizes() {
        let problems = Runtime.problems
        print(Tptp.Term.sizes)
        if let problem = problems.first, let file = Tptp.File(problem: problem) {
            let result = (file.headers, file.namedClauses, file.namedAxioms)
            print(result.0.count, result.1.count, result.2.count)
        }

        print(Tptp.Term.sizes)

        Tptp.Term.reset() // dangerous

        print(Tptp.Term.sizes)

        if let problem = problems.last, let file = Tptp.File(problem: problem, options: .webUrl) {
            let result = (file.headers, file.namedClauses, file.namedAxioms)
            print(result.0.count, result.1.count, result.2.count)
        }

        print(Tptp.Term.sizes)
    }
}
