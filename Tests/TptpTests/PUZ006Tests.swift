import Base
import CTptpParsing
import Foundation
import XCTest
import CYices
import CZ3Api

@testable import Tptp
@testable import Solver

public class PUZ006Tests: ATestCase {

    func testFilePUZ006m1() {
        let context = Yices.Context()

        guard let problem = Tptp.File(problem: "PUZ006-1", options: .fileUrl),
              let problemUrl = problem.url else {
            XCTFail("Problem could not be read")
            return
        }
        print(problemUrl)
        XCTAssertTrue(problemUrl.lastPathComponent.hasSuffix("PUZ006-1.p"))
        XCTAssertTrue(problem.containsIncludes)

        var collection = [(name: String, role: String, literals: [Tptp.Term], encoded: [term_t], selected: Int?)]()

        for child in problem.cnfs {
            let term = Tptp.Term.create(tree: child)
            let name = term!.symbol
            let role = term!.nodes!.first!
            let clause = term!.nodes!.last!
            let literals = clause.nodes!

            // let formula = context.encode(clause: clause)!
            // context.assert(formula: formula)
            let encoded = context.encode(literals: literals)
            context.assert(clause: encoded)

            let tuple = (name: name, role: role.symbol, literals: literals, encoded: encoded, selected: nil as Int?)
            collection.append(tuple)
        }


        let includes = problem.axiomSources
        guard let axioms = Tptp.File(url: includes.first!.2), let axiomsUrl = axioms.url else {
            XCTFail("Axioms could not be read")
            return
        }

        XCTAssertTrue(axiomsUrl.lastPathComponent.hasSuffix("PUZ001-0.ax"))
        XCTAssertFalse(axioms.containsIncludes)

        for child in axioms.cnfs {
            guard let term = Tptp.Term.create(tree: child),
                  let role = term.nodes?.first,
                  let clause = term.nodes?.last,
                  let literals = clause.nodes else {
                XCTFail()
                break
            }

            XCTAssertEqual(term.symbol, child.symbol!)

            // let formula = context.encode(clause: clause)!
            // context.assert(formula: formula)
            let encoded = context.encode(literals: literals)
            context.assert(clause: encoded)

            let tuple = (name: term.symbol, role: role.symbol, literals: literals, encoded: encoded, selected: nil as Int?)
            collection.append(tuple)
        }

        XCTAssertTrue(context.isSatisfiable)
        guard let model = context.createModel() else {
            XCTFail("No model for satisfiable context")
            return
        }

        for (offset, element) in collection.enumerated() {
            // select literal
            for (selected, literal) in element.encoded.enumerated() {
                if model.satisfies(formula: literal)! {
                    collection[offset].selected = selected
                    break;
                }
            }
        }

        for tuple in collection {
            guard let index = tuple.selected else {
                XCTFail("No literal selected for \(tuple.literals)")
                return
            }

            print(tuple.literals[index], "selected from ", tuple.literals, tuple.role)
        }
    }

    func testWebPUZ006m1_v4() {
        guard URL.useTptpOrg else { return }
        
        guard
                let file = Tptp.File(problem: "PUZ006-1", options: .fileUrl), let url = file.url,
                let webFile = Tptp.File(problem: "PUZ006-1", options: .webUrl), let webUrl = webFile.url
        else {
            XCTFail()
            return
        }

        let fileClauses = file.cnfs.map { Tptp.Term.create(tree: $0)}
        let webClauses = webFile.cnfs.map { Tptp.Term.create(tree: $0)}
        XCTAssertEqual(fileClauses, webClauses)

        let fileIncludes = file.includes.map { Tptp.Term.create(tree: $0) }
        let webIncludes = webFile.includes.map { Tptp.Term.create(tree: $0) }
        XCTAssertEqual(fileIncludes.count, webIncludes.count)

        print(fileIncludes)
        print(webIncludes)

        let urls = file.axiomSources
        let webUrls = webFile.axiomSources

        for (a,b) in zip(urls, webUrls) {
            guard let fileA = Tptp.File(url: a.2), let fileB = Tptp.File(url: b.2) else {
                XCTFail()
                break
            }

            XCTAssertEqual(fileA.containsIncludes, fileB.containsIncludes)

            let axioms = fileA.cnfs.map { Tptp.Term.create(tree: $0)}
            let webAxioms = fileB.cnfs.map { Tptp.Term.create(tree: $0)}

            XCTAssertEqual(axioms.count, webAxioms.count)
            XCTAssertEqual(axioms, webAxioms)

        }

        print(url)
        print (urls)
        print(webUrl)
        print (webUrls)

    }

}
