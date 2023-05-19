public struct Pair<L, R> {
        public let lhs: L
        public let rhs: R

        public init(_ lhs: L, _ rhs: R) {
            self.lhs = lhs
            self.rhs = rhs
        }
    }

extension Pair: Equatable where L:Equatable, R: Equatable { }

extension Pair: Hashable where L:Hashable, R: Hashable { }

extension Pair: Comparable where L:Comparable, R:Comparable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.lhs < rhs.lhs {
            return true
        } else if lhs.lhs == rhs.lhs {
            return lhs.rhs < rhs.rhs
        } else {
            return false
        }
    }
}

public struct OrderedPair<V> where V:Comparable  {
    public let lhs: V
    public let rhs: V

    init(_ lhs: V, _ rhs: V) {
            if lhs <= rhs {
                self.lhs = lhs
                self.rhs = rhs
            } else {
                self.lhs = rhs
                self.rhs = lhs
            }
        }
}

extension OrderedPair: Equatable where V: Equatable { }

extension OrderedPair: Hashable where V: Hashable { }

extension OrderedPair: Comparable where V:Comparable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.lhs < rhs.lhs {
            return true
        } else if lhs.lhs == rhs.lhs {
            return lhs.rhs < rhs.rhs
        } else {
            return false
        }
    }
}

public struct Triple<A,B,C> {
        public let a: A
        public let b: B
        public let c: C

        public init(_ a: A, b: B, c: C) {
            self.a = a
            self.b = b
            self.c = c
        }
    }

extension Triple: Equatable where A:Equatable, B: Equatable, C: Equatable { }

extension Triple: Hashable where A:Hashable, B: Hashable, C: Hashable { }

extension Triple: Comparable where A:Comparable, B: Comparable, C: Comparable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.a < rhs.a {
            return true
        } else if lhs.a == rhs.a {
            return lhs.b < rhs.b
        } else if lhs.a == rhs.a, lhs.b == lhs.b {
            return lhs.c < rhs.c
        } else {
            return false
        }
    }
}

