extension Collection {
    /// Split a collection in a pair of its first element and the remaining elements.
    ///
    /// - [] -> nil,
    ///   [a,...] -> (a,[...]) : (T, ArraySlice<<T>>)
    ///
    /// - "" -> nil,
    ///   "Hello" -> ('H', "ello") : (Character, Substring)
    ///
    /// _Complexity_: O(1) -- `first` and `dropFirst()` are O(1) for collections
    public var decomposing: (head: Self.Element, tail: Self.SubSequence)? {
        guard let head = first else { return nil }
        return (head, dropFirst()) //
    }
}
