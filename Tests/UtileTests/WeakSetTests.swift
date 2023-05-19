import XCTest
@testable import Utile

final class WeakSetTests : ATestCase {
    private class Foo: Hashable, CustomStringConvertible {
        let name: String

        init(name: String) {
            self.name = name
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(self.name)

        }

        static func ==(lhs: Foo, rhs: Foo) -> Bool {
            lhs.name == rhs.name
        }

        var description: String {
            return self.name
        }
    }

    private class Bar: Hashable, CustomStringConvertible {
        let name: String

        init(name: String) {
            self.name = name
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(name.first)
            hasher.combine(17)
        }

        static func ==(lhs: Bar, rhs: Bar) -> Bool {
            lhs.name == rhs.name
        }

        var description: String {
            return self.name
        }


    }
}

// MARK: Tests

extension WeakSetTests {

    func testFoo() {

        var a : Foo? = Foo(name: "a")
        var b : Foo? = Foo(name: "b")
        var c : Foo? = Foo(name: "c")

        var w = WeakSet<Foo>()

        w.insert(a!)
        w.insert(b!)
        w.insert(c!)

        var names : [String]

        names = w.map { $0.name }.sorted()
        XCTAssertEqual(["a", "b", "c"], names)

        XCTAssertEqual(3, w.count)
        XCTAssertEqual(0, w.nilCount)
        XCTAssertEqual(w.count + w.nilCount, w.totalCount)
        XCTAssertTrue(w.totalCount >= w.keyCount)
        XCTAssertEqual(0, w.collisionCount)


        w.insert(Foo(name:"d"))
        XCTAssertEqual(3, w.count)
        XCTAssertEqual(1, w.nilCount) // leftover from 'd'
        XCTAssertEqual(w.count + w.nilCount, w.totalCount)
        XCTAssertTrue(w.totalCount >= w.keyCount)
        XCTAssertEqual(0, w.collisionCount)

        a = nil
        names = w.map { $0.name }.sorted()
        XCTAssertEqual(["b", "c"], names)

        XCTAssertEqual(2, w.count)
        XCTAssertEqual(2, w.nilCount) // leftovers from 'd' and 'a'
        XCTAssertEqual(w.count + w.nilCount, w.totalCount)
        XCTAssertTrue(w.totalCount >= w.keyCount)
        XCTAssertEqual(0, w.collisionCount)

        b = nil
        names = w.map { $0.name }.sorted()
        XCTAssertEqual(["c"], names)

        XCTAssertEqual(1, w.count)
        XCTAssertEqual(3, w.nilCount) // leftovers from 'd', 'a', and 'b'
        XCTAssertEqual(w.count + w.nilCount, w.totalCount)
        XCTAssertTrue(w.totalCount >= w.keyCount)
        XCTAssertEqual(0, w.collisionCount)

        w.clean()
        XCTAssertEqual(1, w.count)
        XCTAssertEqual(0, w.nilCount) // leftovers cleaned
        XCTAssertEqual(w.count + w.nilCount, w.totalCount)
        XCTAssertTrue(w.totalCount >= w.keyCount)
        XCTAssertEqual(0, w.collisionCount)

        c = nil
        XCTAssertEqual(0, w.count)
        XCTAssertEqual(1, w.nilCount)
        XCTAssertEqual(w.count + w.nilCount, w.totalCount)
        XCTAssertTrue(w.totalCount >= w.keyCount)
        XCTAssertEqual(0, w.collisionCount)
    }

    func testBar() {
        var w = WeakSet<Bar>()

        var aa: Bar? = Bar(name: "aa")
        let ba = Bar(name: "ba")
        w.insert(aa!)
        w.insert(ba)
        XCTAssertEqual(0, w.collisionCount)

        let ab  = Bar(name: "ab")
        w.insert(ab)  // 1. collision: aa-ab
        XCTAssertEqual(1, w.collisionCount)

        let ac = Bar(name: "ac")
        w.insert(ac) // 2. collision: aa-ac
        XCTAssertEqual(2, w.collisionCount)

        let bb = Bar(name: "bb")
        w.insert(bb) // 3. collision: ba-bb
        XCTAssertEqual(3, w.collisionCount)

        XCTAssertEqual(5, w.count)
        XCTAssertEqual(0, w.nilCount)
        XCTAssertEqual(w.count + w.nilCount, w.totalCount)
        XCTAssertTrue(w.totalCount >= w.keyCount)

        aa = nil
        XCTAssertEqual(3, w.collisionCount) // not cleaned up

        XCTAssertEqual(4, w.count)
        XCTAssertEqual(1, w.nilCount)
        XCTAssertEqual(w.count + w.nilCount, w.totalCount)
        XCTAssertTrue(w.totalCount >= w.keyCount)

        w.clean()
        XCTAssertEqual(2, w.collisionCount)

        XCTAssertEqual(4, w.count)
        XCTAssertEqual(0, w.nilCount)
        XCTAssertEqual(w.count + w.nilCount, w.totalCount)
        XCTAssertTrue(w.totalCount >= w.keyCount)





    }

}
