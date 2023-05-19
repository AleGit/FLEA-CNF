//  Created by Mauricio Santos on 3/28/15.
//  Copyright (c) 2015 Mauricio Santos. All rights reserved.

/// A Multiset (sometimes called a bag) is a special kind of set in which
/// members are allowed to appear more than once. It's possible to convert a multiset
/// to a set: `let set = Set(multiset)`
///
/// Conforms to `Sequence`, `ExpressibleByArrayLiteral` and `Hashable`.
public struct MultiSet<T: Hashable> {

    // MARK: Creating a Multiset

    /// Constructs an empty multiset.
    public init() {
    }

    /// Constructs a multiset from a sequence, such as an array.
    public init<S: Swift.Sequence>(_ elements: S) where S.Iterator.Element == T {
        for e in elements {
            insert(e)
        }
    }

    public init<S: Swift.Sequence>(_ keyValuePairs: S) where S.Iterator.Element == (T, Int) {
        for (key, value) in keyValuePairs {
            insert(key, occurrences: value)
        }
    }

    public init(_ dictionary: Dictionary<T, Int>) {
        for (key, value) in dictionary {
            insert(key, occurrences: value)
        }
    }

    // MARK: Querying a Multiset

    /// Number of elements stored in the multiset, including multiple copies.
    public fileprivate(set) var count = 0

    /// Returns `true` if and only if `count == 0`.
    public var isEmpty: Bool {
        count == 0
    }

    /// Number of distinct elements stored in the multiset.
    public var distinctCount: Int {
        members.count
    }

    /// A sequence containing the multiset's distinct elements.
    public var distinctElements: AnySequence<T> {
        AnySequence(members.keys)
    }

    /// Returns `true` if the multiset contains the given element.
    public func contains(_ element: T) -> Bool {
        members[element] != nil
    }

    /// Returns the number of occurrences  of an element in the multiset.
    public func count(_ element: T) -> Int {
        members[element] ?? 0
    }

    // MARK: Adding and Removing Elements

    /// Inserts a single occurrence of an element into the multiset.
    public mutating func insert(_ element: T) {
        insert(element, occurrences: 1)
    }

    /// Inserts a number of occurrences of an element into the multiset.
    public mutating func insert(_ element: T, occurrences: Int) {
        guard occurrences > 0 else {
            // nothing to insert
            return
        }
        let previousNumber = members[element] ?? 0
        members[element] = previousNumber + occurrences
        count += occurrences
    }

    /// Removes a single occurrence of an element from the multiset, if present.
    public mutating func remove(_ element: T) {
        return remove(element, occurrences: 1)
    }

    /// Removes a number of occurrences of an element from the multiset.
    /// If the multiset contains fewer than this number of occurrences to begin with,
    /// all occurrences will be removed.
    public mutating func remove(_ element: T, occurrences: Int) {
        guard let currentOccurrences = members[element], occurrences > 0 else {
            // nothing to remove
            return
        }

        if occurrences >= currentOccurrences {
            // remove all
            count -= currentOccurrences
            members.removeValue(forKey: element)
        } else {
            // remove some, but not all
            count -= occurrences
            members[element] = currentOccurrences - occurrences
        }
    }

    /// Removes all occurrences of an element from the multiset, if present.
    public mutating func removeAllOf(_ element: T) {
        remove(element, occurrences: count(element))
    }

    /// Removes all the elements from the multiset, and by default
    /// clears the underlying storage buffer.
    public mutating func removeAll(keepingCapacity keep: Bool = false) {
        members.removeAll(keepingCapacity: keep)
        count = 0
    }

    // MARK: Private Properties and Helper Methods

    /// Internal dictionary holding the elements.
    fileprivate var members = [T: Int]()
}

// MARK: -

extension MultiSet: Swift.Sequence {

    // MARK: Sequence Protocol Conformance

    /// Provides for-in loop functionality. Generates multiple occurrences per element.
    ///
    /// - returns: A generator over the elements.
    public func makeIterator() -> AnyIterator<T> {
        var keyValueGenerator = members.makeIterator()
        var elementCount = 0
        var element: T?
        return AnyIterator {
            if elementCount > 0 {
                elementCount -= 1
                return element
            }
            let nextTuple = keyValueGenerator.next()
            element = nextTuple?.0
            elementCount = nextTuple?.1 ?? 1
            elementCount -= 1
            return element
        }
    }
}

extension MultiSet: CustomStringConvertible {

    // MARK: CustomStringConvertible Protocol Conformance

    /// A string containing a suitable textual
    /// representation of the multiset.
    public var description: String {
        return "[" + map {
            "\($0)"
        }.joined(separator: ", ") + "]"
    }
}

extension MultiSet: ExpressibleByArrayLiteral {

    // MARK: ExpressibleByArrayLiteral Protocol Conformance

    /// Constructs a multiset using an array literal.
    /// Unlike a set, multiple copies of an element are inserted.
    public init(arrayLiteral elements: T...) {
        self.init(elements)
    }
}

extension MultiSet: ExpressibleByDictionaryLiteral {

    // MARK: ExpressibleByDictionaryLiteral Protocol Conformance

    public init(dictionaryLiteral elements: (T,Int)...) {
        self.init()
        for (element, count) in elements {
            self.insert(element, occurrences: count)
        }
    }


}

extension MultiSet: Hashable {

    // MARK: Hashable Protocol Conformance

    /// `x == y` implies `x.hashValue == y.hashValue`
    public func hash(into hasher: inout Hasher) {
        hasher.combine(distinctCount)
        hasher.combine(count)
        hasher.combine(members)
    }
}

// MARK: Multiset Equatable Conformance

/// Returns `true` if and only if the multisets contain the same number of occurrences per element.
public func ==<T>(lhs: MultiSet<T>, rhs: MultiSet<T>) -> Bool {
    guard lhs.count == rhs.count else {
        return false
    }
    return lhs.members == rhs.members
}
