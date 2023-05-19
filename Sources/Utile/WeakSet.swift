/// Unordered set like collection of entries with weak references to hashable objects.
/// Created 2015 by Adam Preble [WeakSet](https://gist.github.com/preble/13ab713ac044876c89b5)
/// Modified 2016 by Alexander Maringele.
/// **Caution:** The collection may contain less entries than elements inserted:
/// - An entry is valid if it's element reference is valid (inserted element still exists)
/// - An entry is invalid if it's element reference is nil (inserted element does not exist anymore)
/// - Some invalid entries will be removed when mutating functions are performed.
/// - The number of valid entries can decrease even for an immutable weak set.
struct WeakSet<T>
    where T: AnyObject, T: Hashable, T: CustomStringConvertible {
    fileprivate var contents = [Int: [WeakEntry<T>]](minimumCapacity: 1)
    init() {}
}

/// A weak entry holds a weak reference to an hashable object.
/// [ARC](https://en.wikipedia.org/wiki/Automatic_Reference_Counting)
/// deallocates an object, when there is no strong reference left.
/// Additionally weak references to this object will be set to nil.
private struct WeakEntry<T>
    where T: AnyObject, T: Hashable, T: CustomStringConvertible {
    weak var element: T?
}

/// A protocol for collections with a subset of set algebra methods.
/// A type adopting this protocol MAY NOT hold strong references to its elements.
/// See [SetAlgebra](https://developer.apple.com/documentation/swift/setalgebra)
protocol PartialSetAlgebra {
    associatedtype Element
    mutating func insert(_ newMember: Element) -> (inserted: Bool, memberAfterInsert: Element)
    func contains(_ member: Element) -> Bool
}

/// Trivially a set can adopt the protocol.
extension Set: PartialSetAlgebra {} // Set : SetAlgebra : PartialSetAlgebra

/// A marker protocol for collections with weak references to objects.
/// A type adopting this protocol MUST NOT hold strong references to its elements.
/// A set MUST NOT adopt this protocol.
protocol WeakPartialSetAlgebra: PartialSetAlgebra {}

/// A weak set is a collection of weak references
/// and supports a subset of set algebra methods.
extension WeakSet: WeakPartialSetAlgebra {

    /// Insert an element (and get its substitution).
    /// - Parameter newElement:
    /// - Returns:
    @discardableResult
    mutating func insert(_ newElement: T) -> (inserted: Bool, memberAfterInsert: T) {
        let value = newElement.hashValue

        guard let validEntries = entries(at: value) else {
            // no valid entry at all, create a new list with one element
            contents[value] = [WeakEntry(element: newElement)]
            return (true, newElement)
        }

        assert(validEntries.count < 12, "\(#function) \(validEntries.count) (too many collisions)")

        for entry in validEntries {
            if let element = entry.element, element == newElement {
                // an element equal to newElement is already in the collection,
                // hence the equivalent element from the collection is returned
                return (false, element)
            }
        }

        // the new element is not in the collection
        contents[value]?.append(WeakEntry(element: newElement))
        return (true, newElement)
    }

    /// Check if an object is in the collection.
    /// **Complexity:** O(1). *Worst case:* O(n) when all hash values collide.
    func contains(_ member: T) -> Bool {
        let value = member.hashValue
        guard let entries = contents[value] else {
            return false
        }
        for entry in entries {
            if let element = entry.element, element == member {
                return true
            }
        }
        return false
    }
}

///
extension WeakSet {
    /// Number of entries *with* a referenced object.
    /// This number may decrease even when the weak set is immutable.
    /// An atomic insert increases this number by one.
    /// *Complexity*: O(n)
    var count: Int {
        return contents.flatMap({ $0.1 }).filter { $0.element != nil }.count
    }

    /// Number of entries *without* a referenced object.
    /// This number may increase even when the weak set is immutable.
    /// An atomic insert may decrease this number by k ∊ [0, nilCount].
    /// *Complexity*: O(n)
    var nilCount: Int {
        return contents.flatMap({ $0.1 }).filter { $0.element == nil }.count
    }

    /// Number of entries *with or without* a referenced object.
    /// When the weak set is immutable this number will not change.
    /// 'count + nilCount = totalCount' will always hold.
    /// An atomic insert can change this number by n ∊ [-nilCount,1].
    /// *Complexity*: O(n)
    var totalCount: Int {
        return contents.reduce(0) { $0 + $1.1.count }
    }

    /// Number of list of entries.
    /// When the weak set is immutable then this number will not change.
    /// 'keyCount <= totalCount' will always hold.
    /// An atomic insert can change this number by n ∊ [-nilCount,1]
    /// *Complexity*: O(1)
    var keyCount: Int {
        return contents.count
    }
}

// MARK: Iterator protocol and Sequence

/// The weak set type is it's own consuming iterator type.
extension WeakSet: IteratorProtocol {
    mutating func next() -> T? {
        guard let first = contents.first else { return nil }

        guard var entries = contents[first.0]?.filter({ $0.element != nil }),
            entries.count > 0 else {
            // no valid entries at all
            contents[first.0] = nil
            return next()
        }

        defer {
            entries.removeLast()
            contents[first.0] = entries
        }

        guard let member = entries.last?.element else {
            // the last entry should hold a valid reference, but the
            /// weakly referenced object was deallocated after filtering
            return next()
        }

        // now the object is strongly referenced

        return member
    }
}

// MARK: - Sequence

extension WeakSet: Swift.Sequence {
    func makeIterator() -> WeakSet<T> {
        return self // a consumable copy
    }
}

extension WeakSet: ExpressibleByArrayLiteral {
    init(arrayLiteral: T...) {
        self.init()
        for element in arrayLiteral {
            _ = insert(element)
        }
    }
}

extension WeakSet {
    init(set: Set<T>) {
        self.init()
        for s in set {
            _ = insert(s)
        }
    }
}

// MARK: - Misc

extension WeakEntry: CustomStringConvertible {
    var description: String {
        guard let e = self.element else {
            return "nillified"
        }
        return e.description
    }
}

extension WeakSet {
    /// Update and return list of valid (not nullified) entries for a value
    fileprivate func entries(at value: Int) -> [WeakEntry<T>]? {
        guard let entries = contents[value]?.filter({ $0.element != nil }), entries.count > 0 else {
            return nil
        }
        return entries
    }

    mutating func clean() {
        for key in contents.keys {
            contents[key] = entries(at: key)
        }
    }

    /// The number of extra members (values) per hash value (key)
    /// collision count <= count - contents.count when no member is nilified.
    /// collision count = count - contents.count when no member is nilified.
    var collisionCount: Int {
        return contents.map({ $0.1 }).reduce(0) {
            $0 + $1.count - 1
        }
    }
}
