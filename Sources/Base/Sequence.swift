extension Sequence {
    /// check if a predicate holds for all members of a sequence
    func all(_ predicate: (Element) -> Bool) -> Bool {
        return reduce(true) { $0 && predicate($1) }
    }

    /// check if a predicate holds for at least one member of a sequence
    func one(_ predicate: (Element) -> Bool) -> Bool {
        return reduce(false) { $0 || predicate($1) }
    }

    /// count the members of a sequence where a predicate holds
    func count(_ predicate: (Element) -> Bool = { _ in true }) -> Int {
        return reduce(0) { $0 + (predicate($1) ? 1 : 0) }
    }
}