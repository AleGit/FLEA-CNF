public struct Iterator<S, T>: Swift.IteratorProtocol {
    private var this: S?
    private let step: (S) -> S?
    private let data: (S) -> T
    private let predicate: (S) -> Bool

    /// a iterator may outlive its creator,
    /// hence the functions `step`, `predicate`, and `data` may escape their context.
    public init(first: S?, step: @escaping (S) -> S?,
                where predicate: @escaping (S) -> Bool = { _ in
                    true
                },
                data: @escaping (S) -> T) {
        this = first
        self.step = step
        self.data = data
        self.predicate = predicate
    }

    public mutating func next() -> T? {
        while let current = self.this {
            this = step(current)

            if predicate(current) {
                return data(current)
            }
        }

        return nil
    }
}

public struct Sequence<S, T>: Swift.Sequence {
    private let this: S?
    private let step: (S) -> S?
    private let predicate: (S) -> Bool
    private let data: (S) -> T

    /// a sequence may outlive its creator,
    /// hence the functions `step`, `predicate`, and `data` may escape their context.
    public init(first: S?, step: @escaping (S) -> S?, where
    predicate: @escaping (S) -> Bool = { _ in
        true
    }, data: @escaping (S) -> T) {
        this = first
        self.step = step
        self.predicate = predicate
        self.data = data
    }

    public func makeIterator() -> Iterator<S, T> {
        Iterator(first: this, step: step, where: predicate, data: data)
    }
}

