/// A substitution is a mapping from keys to values, e.g. a dictionary.
public protocol Substitution: ExpressibleByDictionaryLiteral, Swift.Sequence, CustomStringConvertible {
    associatedtype K: Hashable
    associatedtype V
    associatedtype Ks : Collection where Ks.Element == K
    associatedtype Vs : Collection where Vs.Element == V

    subscript(_: K) -> V? { get set }

    init(dictionary: [K: V])

    var keys: Ks { get }
    var values: Vs { get }
}

extension Substitution {
    /// Do the runtime types of keys and values match?
    var isHomogeneous: Bool {
        type(of: keys.first) == type(of: values.first)
    }
}

extension Substitution where K == V {
    var isHomogeneous: Bool {
        true
    }
}



/// A dictionary is a substitution.
extension Dictionary: Substitution {
    public init(dictionary: [Key: Value]) {
        self = dictionary
    }
}

/// A substitution has a pretty description.
extension Substitution // K == V not necessary
        where Iterator == DictionaryIterator<K, V> {
    public var prettyDescription: String {
        let pairs = map { "\($0)↦\($1)" }.joined(separator: ",")
        return "{\(pairs)}"
    }

    public var description: String { return self.prettyDescription }
}

/// 't * σ' returns the application of substitution σ on term t.
/// - *caution*: this implementation is more general as
///   the usual definition of substitution, where only variables
///   are substituted with terms. Here any arbitrary term can be
///   substituted with any other term, which can lead to ambiguity.
/// - where keys are only variables it matches the definition of substitution
/// - implicit sharing happens
public func *<N: Term, S: Substitution>(t: N, σ: S) -> N
        where N == S.K, N == S.V, S.Iterator == DictionaryIterator<N, N> {

    if let tσ = σ[t] {
        return tσ // implicit sharing
    }

    guard let nodes = t.nodes, nodes.count > 0 else {
        // a leaf of the term, e.g. constant or variable
        return t // implicit sharing for reference types
    }

    return N.term(t.type, t.symbol, nodes: nodes.map { $0 * σ })
}

public func *<N, S: Substitution>(t: N, σ: S) -> N
        where N == S.K, N == S.V, S.Iterator == DictionaryIterator<N, N> {

    if let tσ = σ[t] {
        return tσ // implicit sharing for reference types
    }

    return t
}

/// The composition of two term substitutions.
public func *<N, S: Substitution>(lhs: S?, rhs: S?) -> S?
        where N == S.K, N == S.V, S.Iterator == DictionaryIterator<N, N> {

    guard let lhs = lhs, let rhs = rhs else {
        return nil
    }

    var subs = S()
    for (key, value) in lhs {
        subs[key] = value * rhs
    }
    for (key, value) in rhs {
        // i.e. key -> value
        if let term = subs[key] {
            // already set, i.e. key -> term
            guard term == value else {
                // already set and different,
                // i.e. key -> value != term <- key
                return nil
            }
            // already set and equal,
            // i.e. key -> value == term <- key
        } else {
            // not set yet
            subs[key] = value
        }
    }
    return subs
}


/// 't * s' returns the substitution of all variables in t with term s.
/// - Term `s` will be shared when N is a reference type
/// - All nodes above multiple occurences of term `s` are fresh,
///     e.g. unshared when N: Sharing does not apply.
func *<N: Term>(t: N, s: N) -> N {
    guard let nodes = t.nodes else {
        return s // implicit sharing for reference types
    } // any variable is replaced by term s

    return N.term(t.type, t.symbol, nodes: nodes.map { $0 * s })
}

/// `t⊥` substitutes all variables in term `t` with constant `⊥`.
postfix operator ⊥

/// 't⊥' returns the substitution of all variables in t with constant term '⊥'.
/// - Constant term '⊥' will be shared when N is a reference type.
/// - All nodes above multiple occurences of constant term '⊥' are fresh,
///     eg. unshared when N: Sharing does not apply.
postfix func ⊥<N: Term>(t: N) -> N where N.Symbol == String {
    return t * N.constant("⊥")
}

/// properties of term substitutions
extension Substitution where K: Term, V: Term {

    /// Are *variables* mapped to terms?
    private var allKeysAreVariables: Bool {
        keys.reduce(true) {
            $0 && $1.nodes == nil
        }
    }

    /// Are terms mapped to *variables*?
    private var allValuesAreVariables: Bool {
        values.reduce(true) {
            $0 && $1.nodes == nil
        }
    }

    /// Are distinct terms mapped to *distinguishable* terms?
    private var isInjective: Bool {
        keys.count == Set(values).count
    }

    /// A substitution maps variables to terms.
    var isSubstitution: Bool {
        allKeysAreVariables
    }

    /// A variable substitution maps variables to variables.
    var isVariableSubstitution: Bool {
        allKeysAreVariables && allValuesAreVariables
    }

    /// A (variable) renaming maps distinct variables to distinguishable variables.
    private var isRenaming: Bool {
        allKeysAreVariables && allValuesAreVariables && isInjective
    }

    func isRenamingOf(size: Int) -> Bool {
        keys.count == size && isRenaming
    }
}

extension Substitution where Self.Iterator == DictionaryIterator<K,V> {

    /// For substitutions where Self.K == Self.V
    /// - Returns: a new substitution without identities, e.g. x->x
    func simplified() -> Self {
        guard self.isHomogeneous else { return self }
        var dictionary = [K:V]()
        for (key, value) in self {
            if let v = value as? Self.K, key == v {
                // identity, e.g. x->x
            }
            else {
                // e.g. x->y, x->a, x->f(a)
                dictionary[key] = value
            }
        }
        return Self(dictionary: dictionary)
    }
}
