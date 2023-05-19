import Foundation
@testable import Base
import XCTest
import CTptpParsing

#if os(Linux)
import FoundationNetworking
#endif

@testable import Tptp

public class FileTests: ATestCase {

    /// Create Tptp.File from string "f(X,z)".
    func test_fXz() {
        let string = "f(X,z)"
        guard
                let file = Tptp.File(string: string, variety: .variable, name: "tempTptpFile"),
                let root = file.root, let term = root.child,
                let role = term.child, let predicate = role.sibling,
                let function = predicate.child,
                let X = function.child, let z = X.sibling
                else {
            XCTFail()
            return
        }

        print(file.headers)
        print(file.namedClauses)
        print(file.namedAxioms)
        print(Tptp.Term.typedSymbols)

        XCTAssertNil(root.sibling)
        XCTAssertNil(term.sibling)
        XCTAssertNil(predicate.sibling)
        XCTAssertNil(function.sibling)
        XCTAssertNil(z.sibling)

        XCTAssertEqual(file.identifier, "tempTptpFile")

        XCTAssertEqual(root.symbol, "tempTptpFile")
        XCTAssertEqual(Tptp.File.Variety(of: root), .file)

        XCTAssertEqual(term.symbol, "tempTermName")
        XCTAssertEqual(Tptp.File.Variety(of: term), .fof)

        XCTAssertEqual(role.symbol, "axiom")
        XCTAssertEqual(Tptp.File.Variety(of: role), .role)

        XCTAssertEqual(predicate.symbol, "tempTermWrapperPredicate")
        XCTAssertEqual(Tptp.File.Variety(of: predicate), .predicate(1))

        XCTAssertEqual(function.symbol, "f")
        XCTAssertEqual(Tptp.File.Variety(of: function), .function(2))

        XCTAssertEqual(X.symbol, "X")
        XCTAssertEqual(Tptp.File.Variety(of: X), .variable)

        XCTAssertEqual(z.symbol, "z")
        XCTAssertEqual(Tptp.File.Variety(of: z), .function(0))
    }
}

/// PUZ - Puzzles
extension FileTests {

    /// Create Tptp.File from problem 'PUZ001-1.p'.
    func testProblemPUZ001m1() {
        guard let file = Tptp.File(problem: "PUZ001-1") ,
              let filePath = file.identifier, let root = file.root,
              let rootSymbol = root.symbol else {
            XCTFail()
            return
        }


        print(file.headers)
        print(file.namedClauses)
        print(file.namedAxioms)
        print(Tptp.Term.typedSymbols)

        XCTAssertTrue(filePath.hasSuffix("PUZ001-1.p"))
        XCTAssertTrue(rootSymbol.hasSuffix("PUZ001-1.p"))

        XCTAssertEqual(Tptp.File.Variety(of: root), .file)

        for child in root.children {
            XCTAssertEqual(PRLC_CNF, child.type)
            XCTAssertEqual(Tptp.File.Variety(of: child), .cnf)
        }
    }

    /// Create terms from axiom files.
    func testWebURLwithAxiom() {
        guard URL.useTptpOrg else { return }

        let terms = [
            URL(fileURLWithAxiom: "PUZ001-0.ax"),
            URL(webURLWithAxiom: "PUZ001-0.ax")
        ].compactMap {
            url -> Tptp.Term? in
            guard let url = url, let file = Tptp.File(url: url),
            let term = Tptp.Term.create(file: file) else {
                return nil
            }
            return term
        }

        guard let t1 = terms.first, let t2 = terms.last else {
            XCTFail()
            return
        }
        XCTAssertEqual(t1.nodes?.first, t2.nodes?.first)
        XCTAssertEqual(t1.nodes?.last, t2.nodes?.last)
    }

    /// Create Tptp.File from file 'PUZ006-1.p' and web url.
    func testWebPUZ006m1_v1() {
        guard URL.useTptpOrg else { return }
        
        let name = "PUZ006-1"
        guard let _ = Tptp.File(problem: name) else {
            XCTFail("Problem \(name) could not be loaded.")
            return
        }
        let localProblem, remoteProblem: Tptp.File?

        if let url = URL(webURLWithProblem: name) {
            remoteProblem = Tptp.File(url: url)
        } else {
            XCTFail("remote web url for \(name) could not be created")
            remoteProblem = nil
            return
        }

        guard URL.tptpDirectoryURL != nil else {
            XCTFail("Local TPTP directory was not found")
            return
        }

        if let url = URL(fileURLWithProblem: name) {
            print(url)
            localProblem = Tptp.File(url: url)
        } else {
            XCTFail("local file url for \(name) could not be created")
            localProblem = nil
            return
        }

        XCTAssertNotNil(localProblem, "Local problem \(name) could not be loaded")
        XCTAssertNotNil(remoteProblem, "Remote problem  \(name) could not be loaded")

        guard let local = localProblem, let remote = remoteProblem else {
            XCTFail()
            return
        }

        XCTAssertNotEqual(local.identifier, remote.identifier)
        XCTAssertEqual(local.inputs.count(), remote.inputs.count())
    }

    func testWebPUZ006m1_v2() {
        guard URL.useTptpOrg else { return }
        
        guard let url = URL(webURLWithProblem: "PUZ006-1"), let file = Tptp.File(url: url) else {
            XCTFail()
            return
        }

        XCTAssertEqual(Tptp.File.Variety(of: file.root!), .file)
        for child in file.root!.children {
            let type = Tptp.File.Variety(of: child)
            switch type {
            case .include:
                XCTAssertTrue(child.symbol! == "'Axioms/PUZ001-0.ax'" ||
                child.symbol! == "'Axioms/<a href=SeeTPTP?Category=Axioms&File=PUZ001-0.ax>PUZ001-0.ax</a>'")
            default:
                XCTAssertEqual(type, .cnf)
            }
        }

        XCTAssertEqual(url, file.url!)

        let includes = file.axiomSources
        XCTAssertEqual(1, includes.count)
        for include in includes {
            print(#function, "•", include)
        }
    }

    func testWebPUZ006m1_v3() {
        guard URL.useTptpOrg else { return }
        
        guard let url = URL(webURLWithProblem: "PUZ006-1"), let file = Tptp.File(url: url) else {
            XCTFail()
            return
        }

        XCTAssertEqual(file.identifier!, "https://www.tptp.org/cgi-bin/SeeTPTP?Category=Problems&Domain=PUZ&File=PUZ006-1.p")
        XCTAssertEqual(file.root!.symbol!, "https://www.tptp.org/cgi-bin/SeeTPTP?Category=Problems&Domain=PUZ&File=PUZ006-1.p")
        XCTAssertEqual(Tptp.File.Variety(of: file.root!), .file)
        for child in file.root!.children {
            let type = Tptp.File.Variety(of: child)
            switch type {
            case .include:
                XCTAssertEqual(child.symbol!, "'Axioms/<a href=SeeTPTP?Category=Axioms&File=PUZ001-0.ax>PUZ001-0.ax</a>'")
            default:
                XCTAssertEqual(type, .cnf)
            }
        }

        XCTAssertEqual(url, file.url!)

        let includes = file.axiomSources
        XCTAssertEqual(1, includes.count)
        for include in includes {
            print(#function, "•", include)
        }
    }
}

extension FileTests {
    ///
    func testANA007m1() {
        guard let problem = Tptp.File(problem: "ANA007-1", options: .fileUrl) else {
            XCTFail()
            return
        }

        let headers = problem.headers
        XCTAssertEqual(22, headers.count)
        for header in headers {
            print(header)
        }

        // check cnf
        let clauses = problem.namedClauses
        XCTAssertEqual(4, clauses.count)

        let terms = problem.cnfs.compactMap {
            Tptp.Term.create(tree: $0)
        }
        XCTAssertEqual(clauses.count, terms.count)

        for (clause, term) in zip(clauses, terms) {
            XCTAssertEqual(clause.literals, term.nodes!.last!.nodes!, clause.name)
        }

        // check includes (we assume only axiom files are included)
        let axioms = problem.namedAxioms
        let firstSetOfClauses = Set(axioms.map { $0.literals })

        let axiomFiles = problem.axiomSources.compactMap { (s, strings, url) -> Tptp.File? in
            XCTAssertTrue(strings.isEmpty)
            guard let file = Tptp.File(url: url) else {
                XCTFail(s)
                return nil
            }

            return file

        }
        XCTAssertEqual(3, axiomFiles.count)

        var secondSetOfLiterals = Set<[Tptp.Term]>()
        for axiomFile in axiomFiles {
            for axiomCnf in axiomFile.cnfs {
                guard let term = Tptp.Term.create(tree: axiomCnf),
                      let role = term.nodes?.first?.symbol,
                      let clause = term.nodes?.last,
                      let literals = clause.nodes else {
                    break
                }
                XCTAssertEqual(2, term.nodes?.count ?? 0)
                XCTAssertEqual("axiom", role)
                XCTAssertTrue(secondSetOfLiterals.insert(literals).inserted)
                // term.symbol
                // term.nodes.first.symbol -> role
                // term.nodes.last -> clause : Tptp.Term
                // clause.nodes -> literals: [Tptp.Term]

            }
        }

        XCTAssertEqual(firstSetOfClauses, secondSetOfLiterals)
    }

    func testWebContent() {
        guard URL.useTptpOrg else { return }
        
        for (domain, counter) in [("ANA", "007-1"),
                                  // ("HWV", "134-1"),
        ] {

            let problemName = "\(domain)\(counter)"
            let expectedSuffix = "Problems/\(domain)/\(problemName).p"
            let fileURL = URL(fileURLWithProblem: problemName)!
            let expectedWebUrlString =
                    "https://www.tptp.org/cgi-bin/SeeTPTP?Category=Problems&Domain=\(domain)&File=\(problemName).p"
            let webURL = URL(webURLWithProblem: problemName)!

            XCTAssertTrue(fileURL.absoluteString.hasSuffix(expectedSuffix))
            XCTAssertEqual(expectedWebUrlString, webURL.absoluteString)

            let (fileContent, fileDuration) = Time.measure {
                try! String(contentsOf: fileURL, encoding: .isoLatin1)
            }
            print("size:", fileContent.count, ", duration:", round(fileDuration.absolute * 10000.0)/10000.0, "s,",fileURL.absoluteString)

            let (webContent, webDuration) = Time.measure {
                try! String(contentsOf: webURL, encoding: .isoLatin1)
            }
            print("size:", webContent.count, ", duration:", round(webDuration.absolute * 10000.0)/10000.0, "s,", webURL.absoluteString)

            XCTAssertTrue(fileContent.count < webContent.count)
            XCTAssertTrue(fileDuration < webDuration)

            print("size:", round(Float(fileContent.count) / Float(webContent.count) * 10_000.0)/100.0, "%,",
                    "duration:", round(fileDuration.absolute/webDuration.absolute * 100_000.0)/100.0, "‰")

            /*
                size: 2355 , duration: 0.0002 s, file:///Users/alexander/TPTP/Problems/ANA/ANA007-1.p
                size: 3356 , duration: 1.0566 s, https://www.tptp.org/cgi-bin/SeeTPTP?Category=Problems&Domain=ANA&File=ANA007-1.p
                size: 70.17 %, duration: 0.23 ‰
                size: 278765153 , duration: 0.1185 s, file:///Users/alexander/TPTP/Problems/HWV/HWV134-1.p
                size: 332411676 , duration: 490.3221 s, https://www.tptp.org/cgi-bin/SeeTPTP?Category=Problems&Domain=HWV&File=HWV134-1.p
                size: 83.86 %, duration: 0.24 ‰
             */


        }
    }
}

/// HWV - Hardware verification

extension FileTests {

    func _testWebHWV134_1_v1() {
        guard URL.useTptpOrg else { return }
        
        let url = URL(webURLWithProblem: "HWV134-1")!
        XCTAssertEqual(
                "https://www.tptp.org/cgi-bin/SeeTPTP?Category=Problems&Domain=HWV&File=HWV134-1.p",
                url.absoluteString)
        print(url)

        let (content, triple) = Time.measure {
            try? String(contentsOf: url, encoding: .isoLatin1)
        }

        XCTAssertNotNil(content)
        print(content?.count() ?? -1, triple)

        // e.g.:
        // https://www.tptp.org/cgi-bin/SeeTPTP?Category=Problems&Domain=HWV&File=HWV134-1.p
        // 332411676 (user: 9.55, system: 9.81, absolute: 504.28506088256836) ≤ 10'
        // 332411676 Byte / 500s ~ 664.823 Byte/s ~ 7 Mbit/s (of 40 Mbit/s)

        // https://www.tptp.org/cgi-bin/SeeTPTP?Category=Problems&Domain=HWV&File=HWV134-1.p
        // 332411676 (user: 6.8500000000000005, system: 8.21, absolute: 399.22326397895813)
        // 332411676 Byte / 400s ~ 831.029,19 Byte/s ~ 8 Mbit/s (of 40 Mbit/s)
    }

    func _testWebHWV134_1_v2() {
        guard URL.useTptpOrg else { return }

        let (_, triple) = Time.measure {
            let start = Date()
            let file = Tptp.File(problem: "HWV134-1", options: .webUrl)
            XCTAssertNotNil(file)
            print(Date().timeIntervalSince(start), file?.url?.absoluteString ?? "n/a")

            var count = file?.cnfs.count() ?? -1
            XCTAssertEqual(2_332_428, count)
            print(Date().timeIntervalSince(start), "file.cnfs.count", count)

            count = file?.namedClauses.count ?? -1
            XCTAssertEqual(2_332_428, count)
            print(Date().timeIntervalSince(start), "file.clauses.count", count)

            count = file?.namedAxioms.count ?? -1
            XCTAssertEqual(0, count)
            print(Date().timeIntervalSince(start), "file.axioms.count", count)
        }

        print(triple)
        /** e.g.
        427.8968540430069 https://www.tptp.org/cgi-bin/SeeTPTP?Category=Problems&Domain=HWV&File=HWV134-1.p
        428.5635380744934 file.cnfs.count 2332428
        485.2957090139389 file.clauses.count 2332428
        485.6592890024185 file.axioms.count 0
        (user: 72.38999999999999, system: 14.58, absolute: 485.6719620227814)
        ************************************************************************************************/

        XCTAssertTrue(triple.user + triple.system < triple.absolute)

        XCTAssertTrue(triple.user <= 100.0)
        XCTAssertTrue(triple.system <= 20.0)
        XCTAssertTrue(triple.absolute <= 500.0)


    }

    func _testFileHWV134_1() {
        let (_, triple) = Time.measure {
            let start = Date()
            let file = Tptp.File(problem: "HWV134-1", options: .fileUrl)
            XCTAssertNotNil(file)
            print(Date().timeIntervalSince(start), file?.url?.absoluteString ?? "n/a")

            var count = file?.cnfs.count() ?? -1
            XCTAssertEqual(2_332_428, count)
            print(Date().timeIntervalSince(start), "file.cnfs.count", count)

            count = file?.namedClauses.count ?? -1
            XCTAssertEqual(2_332_428, count)
            print(Date().timeIntervalSince(start), "file.clauses.count", count)

            count = file?.namedAxioms.count ?? -1
            XCTAssertEqual(0, count)
            print(Date().timeIntervalSince(start), "file.axioms.count", count)
        }

        print(triple)
        // e.g. (user: 91.35, system: 2.06, absolute: 94.16)

        XCTAssertTrue(triple.user + triple.system < triple.absolute)

        XCTAssertTrue(triple.user <= 100.0)
        XCTAssertTrue(triple.system <= 10.0)
        XCTAssertTrue(triple.absolute <= 100.0)
    }





}
