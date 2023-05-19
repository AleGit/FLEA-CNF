import XCTest
@testable import Base

class URLTests: ATestCase {

    func testHomeUrl() {
        guard let url = URL.homeDirectoryURL else {
            XCTFail()
            return
        }
        XCTAssertTrue(url.isAccessibleDirectory)
        print(ok, url.path, "is accessible home directory")
    }

    func testTptpURL() {
        guard let url = URL.tptpDirectoryURL else {
            XCTFail()
            return
        }
        XCTAssertTrue(url.isAccessibleDirectory)
        print(ok, url.path, "is accessible tptp directory")
    }

    func testLoggingConfigurationURL() {
        guard let url = URL.loggingConfigurationURL else {
            XCTFail()
            return
        }
        XCTAssertTrue(url.isFileURL)
        XCTAssertTrue(url.isAccessible)
        print(ok, url.path, "is accessible file url")
    }

    func testWebURLWithProblem() {
        guard URL.useTptpOrg else { return }

        let problem = "PUZ001-1"
        let expected = "https://www.tptp.org/cgi-bin/SeeTPTP?Category=Problems&Domain=PUZ&File=PUZ001-1.p"
        let url = URL(webURLWithProblem: problem)! // does not crash with valid url string
        XCTAssertEqual(url.absoluteString, expected)
        
        do {
            let content = try String(contentsOf: url, encoding: .isoLatin1)
            guard let startRange = content.range(of: "<pre>", options: .caseInsensitive),
            let endRange = content.range(of: "</pre>", options: [.caseInsensitive, .backwards]) else {
                XCTFail("<pre>...</pre> not found.")
                return
            }
            let range = content[startRange.upperBound..<endRange.lowerBound]
            let cleaned = range.replacingOccurrences(of: "<A.*</A>", with: "", options: .regularExpression)
            XCTAssertTrue(cleaned.contains("cnf(agatha,hypothesis,"))
            XCTAssertTrue(cleaned.contains("cnf(prove_neither_charles_nor_butler_did_it,negated_conjecture,"))
        } catch {
            switch (error._code, error._domain) {
            case (256, NSCocoaErrorDomain):
                Syslog.error { "260 NSCocoaErrorDomain" }
                return
            case (260, NSCocoaErrorDomain):
                Syslog.error { "260 NSCocoaErrorDomain" }
                return
            case (let code, let domain):
                #if os(macOS)
                let info = error._userInfo?.description ?? "n/a"
                XCTFail("\(code), \(domain), \(info)")
                #else 
                XCTFail("\(code), \(domain)")
                #endif

            }
        }
    }

    func testWebURLWithAxiom() {
        guard URL.useTptpOrg else { return }
        
        let axiom = "PUZ001-0.ax"
        let expected = "https://www.tptp.org/cgi-bin/SeeTPTP?Category=Axioms&File=PUZ001-0.ax"
        let url = URL(webURLWithAxiom: axiom)! // does not crash with valid url string
        XCTAssertEqual(url.absoluteString, expected)

        do {
            let content = try String(contentsOf: url, encoding: .isoLatin1)
            guard let startRange = content.range(of: "<pre>", options: .caseInsensitive),
            let endRange = content.range(of: "</pre>", options: [.caseInsensitive, .backwards]) else {
                XCTFail("<pre>...</pre> not found.")
                return
            }
            let range = content[startRange.upperBound..<endRange.lowerBound]
            let cleaned = range.replacingOccurrences(of: "<A.*</A>", with: "", options: .regularExpression)
            XCTAssertTrue(cleaned.contains("cnf(from_mars_or_venus,axiom,"))
            XCTAssertTrue(cleaned.contains("cnf(liars_make_false_statements,axiom,"))
        } catch {
            switch (error._code, error._domain) {
            case (256, NSCocoaErrorDomain):
                Syslog.error { "260 NSCocoaErrorDomain" }
                return
            case (260, NSCocoaErrorDomain):
                Syslog.error { "260 NSCocoaErrorDomain" }
                return
            case (let code, let domain):
                #if os(macOS)
                let info = error._userInfo?.description ?? "n/a"
                XCTFail("\(code), \(domain), \(info)")
                #else 
                XCTFail("\(code), \(domain)")
                #endif
            }
        }
    }
}
