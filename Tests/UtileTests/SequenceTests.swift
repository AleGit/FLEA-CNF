import XCTest
import Base
import Utile

class SequenceTests : ATestCase {

    private static var primes10 = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29]

    class Simples: Swift.Sequence {
        private var sorted = primes10
        private lazy var primes = Set(sorted)

        private func prime(s: Int) -> Bool {
            if primes.contains(s) { return true }

            for p in sorted {
                if s % p == 0 {
                    return false
                }
            }
            sorted.append(s)
            primes.insert(s)
            return true
        }
        func makeIterator() -> Utile.Iterator<Int,Int> {
            return Utile.Iterator(
                    first: 2,
                    step: { s in s + 1  },
                    where: { s in self.prime(s: s)  },
                    data: { s in s })
        }

        func first(_ k: Int) -> [Int] {
            for _ in self {
                guard sorted.count < k else { break }
            }
            return Array(sorted[0..<k])
        }

        subscript(idx: Int) -> Int {
            for _ in self {
                guard sorted.count <= idx else { break }
            }
            return sorted[idx]
        }
    }

    class Primes: Swift.Sequence {
        private var sorted = primes10

        private func sieved(s: Int) -> Bool {
            assert(sorted.last! < s)
            for p in sorted[1...] {
                if s % p == 0 {
                    return true // sieved, i.e. not a prime
                }
            }
            sorted.append(s)
            return false // not sieved, i.e. a prime
        }

        subscript(idx: Int) -> Int {
            while idx >= sorted.count {
                var s = sorted.last! + 2
                while sieved(s: s) { s += 2}
            }
            return sorted[idx]
        }

        func prime(p: Int) -> Bool {
            while p >= sorted.last! {
                var s = sorted.last! + 2
                while sieved(s: s) { s += 2 }
            }

            // binary search
            var lhs = 0
            var rhs = sorted.count - 1

            while lhs <= rhs {
                let mid = (lhs+rhs)/2
                let val = sorted[mid]

                if val == p { return true }

                if val < p { lhs = mid+1 }
                else { rhs = mid-1 }
            }
            return false

        }

        func makeIterator() -> Utile.Iterator<Int, Int> {
            return Utile.Iterator(
                    first: 0,
                    step: { idx in idx + 1  },
                    data: { idx in self[idx] })
        }

        func first(_ k: Int) -> [Int] {
            for _ in self {
                guard sorted.count < k else { break }
            }
            return Array(sorted[0..<k])
        }
    }

    func testPrime() {
        let primes = Primes()

        for n in 0...SequenceTests.primes10.last! {
            XCTAssertEqual(SequenceTests.primes10.contains(n), primes.prime(p: n) )
        }

        for p in SequenceTests.primes10.reversed() {
            XCTAssertTrue(primes.prime(p: p))
        }

    }

    func testPrimes() {
        let simples = Simples()
        let primes = Primes()

        let (_, t) = Time.measure {

            XCTAssertEqual([2], simples.first(1))
            XCTAssertEqual([2, 3, 5, 7, 11, 13, 17, 19, 23, 29], simples.first(10))

            XCTAssertEqual([2], primes.first(1))
            XCTAssertEqual([2, 3, 5, 7, 11, 13, 17, 19, 23, 29], primes.first(10))
        }

        XCTAssertTrue(t.absolute < 0.001, t.absolute.description)

        for count in [1000, 1110, 2000] {

            let (result_p, time_p) = Time.measure {
                primes.first(count)
            }

            let (result_s, time_s) = Time.measure {
                simples.first(count)
            }

            XCTAssertEqual(result_s, result_p)
            print(time_p, time_s)
            // TODO: XCTAssertTrue(time_p.absolute < time_s.absolute, "\(count) time_p=\(time_p.absolute) • time_s=\(time_s.absolute)")
        }

        let (s, time_s) = Time.measure {
            simples[2100]
        }

        let (p, time_p) = Time.measure {
            simples[2100]
        }

        XCTAssertTrue(primes.prime(p: s))
        XCTAssertTrue(primes.prime(p: p))
        XCTAssertEqual(s, p)
        XCTAssertTrue(time_p < time_s, "time_p=\(time_p.absolute) • time_s=\(time_s.absolute)")
    }
}

extension SequenceTests {

    private static var fibonacci13 = [0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144]

    class FibonacciSequence: Swift.Sequence {
        private var sorted = [0, 1]

        subscript(idx: Int) -> Int {
            while idx >= sorted.count {
                let n = sorted[sorted.count-2] + sorted[sorted.count-1]
                sorted.append(n)
            }
            return sorted[idx]
        }

        func makeIterator() -> Utile.Iterator<Int, Int> {
            return Utile.Iterator(
                    first: 0,
                    step: { idx in idx + 1  },
                    data: { idx in self[idx] })
        }

        func first(_ k: Int) -> [Int] {
            for _ in self {
                guard sorted.count < k else { break }
            }
            return Array(sorted[0..<k])
        }
    }

    func testFibonacci() {
        let fibs = FibonacciSequence()
        XCTAssertEqual(SequenceTests.fibonacci13, fibs.first(13))
    }
}
