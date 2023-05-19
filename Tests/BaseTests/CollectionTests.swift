import XCTest
import Base

class CollectionTests: ATestCase {
    func testDecomposingArray() {
        let list1 = [1, 2, 3]
        guard let (head1, tail1) = list1.decomposing else {
            XCTFail()
            return
        }
        XCTAssertEqual(1, head1)
        XCTAssertEqual([2, 3], tail1)

        guard let (head2, tail2) = tail1.decomposing else {
            XCTFail()
            return
        }
        XCTAssertEqual(2, head2)
        XCTAssertEqual([3], tail2)

        guard let (head3, tail3) = tail2.decomposing else {
            XCTFail()
            return
        }
        XCTAssertEqual(3, head3)
        XCTAssertEqual([], tail3)

        for (head, tail) in [(head1, tail1), (head2, tail2), (head3, tail3)] {
            XCTAssertEqual("Int", "\(type(of: head))", "\(head)•\(tail)")
            XCTAssertEqual("ArraySlice<Int>", "\(type(of: tail))", "\(head)•\(tail)")
        }

        XCTAssertNil(tail3.decomposing)
        XCTAssertNil(tail3.decomposing)
    }

    func testDecomposingString() {
        let string = "1👩‍👧‍👧3"
        guard let (head1, tail1) = string.decomposing else {
            XCTFail()
            return
        }
        XCTAssertEqual("1", head1)
        XCTAssertEqual("👩‍👧‍👧3", tail1)

        guard let (head2, tail2) = tail1.decomposing else {
            XCTFail()
            return
        }
        XCTAssertEqual("👩‍👧‍👧", head2)
        XCTAssertEqual("3", tail2)

        guard let (head3, tail3) = tail2.decomposing else {
            XCTFail()
            return
        }
        XCTAssertEqual("3", head3)
        XCTAssertEqual("", tail3)

        for (head, tail) in [(head1, tail1), (head2, tail2), (head3, tail3)] {
            XCTAssertTrue(string.contains(head), "\(head)")
            XCTAssertEqual("Character", "\(type(of: head))", "\(head)•\(tail)")
            XCTAssertEqual("Substring", "\(type(of: tail))", "\(head)•\(tail)")
        }

        XCTAssertNil(tail3.decomposing)
        XCTAssertNil("".decomposing)
    }

    func testDecomposingDictionary() {
        let dictionary = [ 1: "eins", 3:"drei", 312 : "dreihundertzwölf"]
        guard let (head1, tail1) = dictionary.decomposing else {
            XCTFail()
            return
        }


        guard let (head2, tail2) = tail1.decomposing else {
            XCTFail()
            return
        }
        XCTAssertNotEqual(head1.key, head2.key)
        XCTAssertNotEqual(head1.value, head2.value)


        guard let (head3, tail3) = tail2.decomposing else {
            XCTFail()
            return
        }
        XCTAssertNotEqual(head1.key, head3.key)
        XCTAssertNotEqual(head1.value, head3.value)
        XCTAssertNotEqual(head2.key, head3.key)
        XCTAssertNotEqual(head2.value, head3.value)

        for (head, tail) in [(head1, tail1), (head2, tail2), (head3, tail3)] {
            XCTAssertTrue(dictionary.contains { key, value in head == (key, value)  }, "\(head)•\(tail)")
            XCTAssertEqual("(key: Int, value: String)", "\(type(of: head))", "\(head)•\(tail)")
            XCTAssertEqual("Slice<Dictionary<Int, String>>", "\(type(of: tail))", "\(head)•\(tail)")
        }

        XCTAssertNil(tail3.decomposing)
    }

    func testDecomposingSet() {
        let set = Set(["eins", "drei", "dreihundertzwölf"])
        guard let (head1, tail1) = set.decomposing else {
            XCTFail()
            return
        }

        guard let (head2, tail2) = tail1.decomposing else {
            XCTFail()
            return
        }
        XCTAssertTrue(set.contains(head2), head2)
        XCTAssertNotEqual(head1, head2)


        guard let (head3, tail3) = tail2.decomposing else {
            XCTFail()
            return
        }
        XCTAssertTrue(set.contains(head3), head3)
        XCTAssertNotEqual(head1, head3, head3)
        XCTAssertNotEqual(head2, head3, head3)

        for (head, tail) in [(head1, tail1), (head2, tail2), (head3, tail3)] {
            XCTAssertTrue(set.contains(head), head)
            XCTAssertEqual("String", "\(type(of: head))", "\(head)•\(tail)")
            XCTAssertEqual("Slice<Set<String>>", "\(type(of: tail))", "\(head)•\(tail)")
        }

        XCTAssertNil(tail3.decomposing)
    }
}