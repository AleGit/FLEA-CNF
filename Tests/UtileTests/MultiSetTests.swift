import XCTest
@testable import Utile


class MultiSetTests: ATestCase {

    func testBasics() {

        let counts = [(0,4), (1,7), (2,2), (3,200), (4,54), (5,2), (6,0), (7,13), (8,300), (9,1)]

        var multiSet = MultiSet(counts)
        XCTAssertEqual(9, multiSet.distinctCount)   // 0,1,2,  3, 4,5, , 7,  8,9
        XCTAssertEqual(583, multiSet.count)         // 4+7+2+200+54+2+0+13+300+1

        for (element, occurs) in counts {
            XCTAssertEqual(occurs, multiSet.count(element), "\((element,occurs))")
            multiSet.remove(element)
            XCTAssertEqual(max(0, occurs - 1), multiSet.count(element))
        }
        XCTAssertEqual(8, multiSet.distinctCount)   // 0,1,2,  3, 4,5, , 7,  8,
        XCTAssertEqual(574, multiSet.count)         // 3+6+1+199+53+1+0+12+299+0

        for (element, occurs) in counts {
            multiSet.insert(element)
            XCTAssertEqual(max(occurs, 1), multiSet.count(element), "\((element,occurs))")
        }
        XCTAssertEqual(10, multiSet.distinctCount)  // 0,1,2,  3, 4,5,6, 7,  8,9
        XCTAssertEqual(584, multiSet.count)         // 4+7+2+200+54+2+1+13+300+1

        for (index, _) in counts.enumerated() {
            multiSet.removeAllOf(index)
            XCTAssertEqual(0, multiSet.count(index))
        }
    }

}

extension MultiSetTests {
    func testInitWithSequence() {
        // insert numbers 1 to 10 modulo 3 + 2 into multiset
        let sequence = Utile.Sequence(
                first: 1,
                step: { s in
                    s < 10 ? s+1 : nil
                }) { s in s % 3 + 2}
        let multiSet = MultiSet(sequence)

        XCTAssertEqual(0, multiSet.count(1))
        XCTAssertEqual(3, multiSet.count(2)) //    3, 6, 9  -> 2
        XCTAssertEqual(4, multiSet.count(3)) // 1, 4, 7, 10 -> 4
        XCTAssertEqual(3, multiSet.count(4)) // 2, 5, 8     -> 5
        XCTAssertEqual(0, multiSet.count(5))
    }

    func fac(n: Int) -> Int {
        guard n > 1 else { return 1 }
        let range = 2...n
        return range.reduce(1) { $0 * $1 }
    }

    func testInitWithRandomSequence() {
        // insert 50 random numbers from 1 to 10 into multiset
        let range = 1...10
        let last = 50
        let sequence = Utile.Sequence(
                first: 1,
                step: { s in
                    s < last ? s + 1 : nil
                }) { _ in Int.random(in: range) }
        let multiSet = MultiSet(sequence)

        XCTAssertEqual(0, multiSet.count(0))
        XCTAssertEqual(0, multiSet.count(11))
        XCTAssertEqual(last, multiSet.count)
        XCTAssertEqual(10, multiSet.distinctCount, "bad luck!")
    }

    func testInitWithKeyValuePairs() {
        let d = [("a", 20), ("b", 13), ("c",254), ("d", 1), ("a", 1)]
        let multiSet = MultiSet(d)
        XCTAssertEqual(21, multiSet.count("a")) // 20 + 1
        XCTAssertEqual(13, multiSet.count("b"))
        XCTAssertEqual(254 , multiSet.count("c"))
        XCTAssertEqual(1 , multiSet.count("d"))
        XCTAssertEqual(0 , multiSet.count("e"))
    }

    func testInitWithDictionary() {
        let d = ["a" : 20, "b" : 13, "c" : 254, "d" : 1]
        let multiSet = MultiSet(d)
        XCTAssertEqual(d["a"], multiSet.count("a"))
        XCTAssertEqual(d["b"], multiSet.count("b"))
        XCTAssertEqual(d["c"] , multiSet.count("c"))
        XCTAssertEqual(d["d"] , multiSet.count("d"))
        XCTAssertEqual(0 , multiSet.count("e"))
    }
}

extension MultiSetTests {
    func testCustomStringConvertible() {
        let multiSet = ["a", "b", "c", "a", "c", "a"] as MultiSet<String>
        XCTAssertEqual("[a, a, a, b, c, c]".count, multiSet.description.count)
    }

    func testExpressibleByArrayLiteral() {
        let multiSet = ["a", "b", "c", "a", "c", "a"] as MultiSet<String>
        XCTAssertEqual(3, multiSet.count("a"))
        XCTAssertEqual(1, multiSet.count("b"))
        XCTAssertEqual(2, multiSet.count("c"))
    }

    func testExpressibleByDictionaryLiteral() {
        let multiSet = ["a" : 2, "b" : 3, "c" : 4, "a" : 5, "c" : 6, "a" : 1] as MultiSet<String>
        XCTAssertEqual(8, multiSet.count("a"))
        XCTAssertEqual(3, multiSet.count("b"))
        XCTAssertEqual(10, multiSet.count("c"))
    }

    func testEquatable() {
        let counts = [1 : 4, 2:72, 3:2, 4:9, 5:3, 6:5, 7:1, 8:22, 9:33]
        let expected = MultiSet(counts)

        var elements = [Int]()
        for (element, occurs) in counts {
            for _ in 0..<occurs {
                elements.append(element)
            }
        }
        elements.shuffle()

        XCTAssertEqual(expected, MultiSet(elements))

        var actual = MultiSet<Int>()
        for element in elements {
            XCTAssertNotEqual(expected, actual)
            actual.insert(element)
        }
        XCTAssertEqual(expected, actual)

        actual.remove(3)
        XCTAssertNotEqual(expected, actual)
        actual.insert(3, occurrences: 3)
        XCTAssertNotEqual(expected, actual)
        actual.remove(3, occurrences: 2)
        XCTAssertEqual(expected, actual)
    }
}
