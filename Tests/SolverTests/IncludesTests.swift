
import XCTest
@testable import Tptp
import Utile

class IncludesTests: ATestCase {
    func testPUZ006m1() {
        let problem = "PUZ006-1"
        guard let file = Tptp.File(problem: problem) else {
            XCTFail("\(problem) was not found")
            return
        }

        let includes = file.includes.map { node in Tptp.Term.create(tree: node) }
        XCTAssertEqual(1, includes.count)
        XCTAssertEqual("include('Axioms/PUZ001-0.ax').", includes[0]?.description, file.identifier ?? "n/a")
    }




    func testSYN000m2() {
        let problem = "SYN000-2.p"
        // CREATE_FOT niyAssertion failed: (false), function prlc_parse, file PrlcParser.y, line 451.
        guard let file = Tptp.File(problem: problem) else {
            XCTFail("\(problem) was not found")
            return
        }

        print(file.identifier ?? "n/a")

        let includes = file.includes.compactMap { node in Tptp.Term.create(tree: node) }

        let expectedURL : URL?
        let expected : String
        if file.url?.isFileURL ?? false {
            expectedURL = URL(fileURLWithProblem: problem)
            expected = "include('Axioms/SYN000-0.ax',[ia1,ia3])."
        } else {
            expected = "include('Axioms/<a href=SeeTPTP?Category=Axioms&File=SYN000-0.ax>SYN000-0.ax</a>',[ia1,ia3])."
            expectedURL = URL(string: "https://www.tptp.org/cgi-bin/SeeTPTP?Category=Problems&Domain=SYN&File=SYN000-2.p")
        }
        XCTAssertEqual(expectedURL, file.url)
        XCTAssertTrue(file.identifier?.hasSuffix(problem) ?? false, file.identifier ?? "n/a")
        XCTAssertEqual(expected, includes[0].description, file.identifier ?? "n/a")

        let cnfs = file.cnfs.map { $0 }
        XCTAssertEqual(14, cnfs.count)

    }

    /// cd /path/to/TPTP; egrep -r "include[(]'Axioms/.*',"
    /// ./Problems/SYN/SYN000+2.p:include('Axioms/SYN000+0.ax',[ia1,ia3]).
    /// ./Problems/SYN/SYN000^2.p:include('Axioms/SYN000^0.ax',[ia1_type,ia1,ia3_type,ia3]).
    /// ./Problems/SYN/SYN000-2.p:include('Axioms/SYN000-0.ax',[ia1,ia3]).
    /// ./Problems/SYN/SYN000_2.p:include('Axioms/SYN000_0.ax',[ia1,ia3]).
    func testIncludesWithAxiomSelection() {
        for (problem, expected) in [
            ("SYN000+2.p","include('Axioms/SYN000+0.ax',[ia1,ia3])."),
            // ("SYN000^2.p","include('Axioms/SYN000^0.ax',[ia1_type,ia1,ia3_type,ia3])."), // thf is not supported at all
            ("SYN000-2.p","include('Axioms/SYN000-0.ax',[ia1,ia3])."),
            // ("SYN000_2.p","include('Axioms/SYN000_0.ax',[ia1,ia3]).") // tff is not supported at all
            ] {
            guard let file = Tptp.File(problem: problem) else {
                XCTFail("\(problem) was not found or could not be parsed.")
                return
            }
            print(file.identifier ?? "n/a")
            let includes = file.includes.compactMap { node in Tptp.Term.create(tree: node) }
            XCTAssertEqual(1, includes.count)
            let include = includes[0]

            let actual = includes[0].description.replacingOccurrences(of: "<a.*ax>|</a>", with: "", options: .regularExpression)
            XCTAssertEqual(expected, actual)

            print(include.symbol, include.type, include.key ,include.nodes!, include.nodes!.count, include.nodes![0], include.nodes![1])
        }

    }
    
}