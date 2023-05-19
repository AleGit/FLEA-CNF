import XCTest
@testable import Base

class StringTests: ATestCase {
    let s0 =
            """
            Hello, Earth!

            I nearly was infected by humans!

            Yours
            Moon
            """
    let s1 = ["Venus", "Earth", "Mars"]
    let s2 = ["Hello", "Earth", "Yours", "Moon"]
    let s3 = ["Good", "Morning", "Sunshine"]

    let s4 =
            """


                Good Morning Sunshine       



            """
    let s5 = "\t \n \rHello, World\t\t  \n \t\t\t"
    let s6 = "(\t \n \r(Hello, World)\t\t  \n \t\t\t)"

    func testTrimmingWhitespace() {
        XCTAssertEqual(s0, s0.trimmingWhitespace)
        XCTAssertEqual("Good Morning Sunshine", s4.trimmingWhitespace)
        XCTAssertEqual("Hello, World", s5.trimmingWhitespace)
        XCTAssertEqual("Hello, World", s5.peeled().trimmingWhitespace.peeled())
    }

    func testTrimmed() {
        XCTAssertEqual("","".trimmed(by: (0,0)))
        XCTAssertNil("".trimmed(by: (1,0)))
        XCTAssertNil("".trimmed(by: (1,1)))
        XCTAssertNil("".trimmed(by: (0,1)))


        XCTAssertEqual("x","x".trimmed(by: (0,0)))
        XCTAssertEqual("","x".trimmed(by: (1,0)))
        XCTAssertNil("".trimmed(by: (1,1)))
        XCTAssertEqual("","x".trimmed(by: (0,1)))

    }

    func testIndex() {
        XCTAssertEqual("a","abc"[0])
        XCTAssertEqual("b","abc"[1])
        XCTAssertEqual("c","abc"[2])
    }


    func testRange() {

        XCTAssertEqual("", "abc"[0..<0])
        XCTAssertEqual("a", "abc"[0..<1])
        XCTAssertEqual("ab", "abc"[0..<2])
        XCTAssertEqual("abc", "abc"[0..<3])
        XCTAssertEqual("", "abc"[1..<1])
        XCTAssertEqual("b", "abc"[1..<2])
        XCTAssertEqual("bc", "abc"[1..<3])
        XCTAssertEqual("", "abc"[2..<2])
        XCTAssertEqual("c", "abc"[2..<3])


        XCTAssertEqual("abc"[0...0], "abc"[0..<1])
        XCTAssertEqual("abc"[0...1], "abc"[0..<2])
        XCTAssertEqual("abc"[0...2], "abc"[0..<3])

        XCTAssertEqual("abc"[1...1], "abc"[1..<2])
        XCTAssertEqual("abc"[1...2], "abc"[1..<3])

        XCTAssertEqual("abc"[2...2], "abc"[2..<3])

    }

    func testPealed() {
        for s in ["a", "(a)", "([a])", "([{a}])", 
                  "\"([a])\"", "|\"([a])\"|", "'|\"([a])\"|'", "<'|\"([a])\"|'>"] {
            XCTAssertEqual("a", s.peeled())
            XCTAssertEqual(s.peeled(), s.peeled().peeled())
        }

        for s in ["a", ")a)", "([a](", "([{a}]|",
                  "'([a])\"", "|\"([a])\"'", "(|\"([a])\"|'", "<'|\"([a])\"|')"] {
            XCTAssertEqual(s, s.peeled())
            XCTAssertEqual(s, s.peeled().peeled())
        }

        for s in ["a-z"] {
            XCTAssertEqual("-", s.peeled(peels: [("a","z")]) )
        }

        for s in ["a-a"] {
            XCTAssertEqual("-", s.peeled(peels: [("a","a")]) )
        }
    }

    func testContainsOne() {
        XCTAssertTrue(s0.containsOne(s1))
        XCTAssertTrue(s0.containsOne(s2))
        XCTAssertFalse(s0.containsOne(s3))

        XCTAssertFalse(s4.containsOne(s1))
        XCTAssertFalse(s4.containsOne(s2))
        XCTAssertTrue(s4.containsOne(s3))
    }

    func testContainsAll() {
        XCTAssertFalse(s0.containsAll(s1))
        XCTAssertTrue(s0.containsAll(s2))
        XCTAssertFalse(s0.containsAll(s3))

        XCTAssertFalse(s4.containsAll(s1))
        XCTAssertFalse(s4.containsAll(s2))
        XCTAssertTrue(s4.containsAll(s3))
    }

    func testLineNr() {
        let input = 
        """
        The first line.
        The second line.
        The third and last line.
        """

        XCTAssertEqual(3, input.split(separator: "\n", maxSplits: 3).count)
        XCTAssertEqual(3, input.split(separator: "\n", maxSplits: 4).count)

        print(input.replacingOccurrences(of: "\n", with: " • "))

        XCTAssertEqual("The first line.", input.line(nr: 1))
        XCTAssertEqual("The second line.", input.line(nr: 2))
        XCTAssertEqual("The third and last line.", input.line(nr: 3))

        XCTAssertEqual("The first line.", input.line(nr: -3)) // line before line before last line
        XCTAssertEqual("The second line.", input.line(nr: -2)) // line before last line
        XCTAssertEqual("The third and last line.", input.line(nr: -1)) // last line

        // edge cases

        XCTAssertEqual(Substring(input), input.line(nr: 0))

        XCTAssertEqual("The third and last line.", input.line(nr: 4)) // last line
        XCTAssertEqual("The third and last line.", input.line(nr: Int.max)) // last line

        XCTAssertEqual("The first line.", input.line(nr: -4)) // first line
        XCTAssertEqual("The first line.", input.line(nr: Int.min)) // first line


    }
}
