import CTptpParsing
import Base
import Utile

extension Tptp {
    public typealias Literal = Tptp.Term
    public typealias Literals = [Literal]
    public typealias Clause = Literals
    public typealias Clauses = [Clause]

    public final class Term: Utile.Term {

        public typealias Symbol = String
        public typealias SymbolType = PRLC_TREE_NODE_TYPE
        public typealias SymbolKey = Int

        public static var variable = PRLC_VARIABLE
        public static var function = PRLC_FUNCTION
        public static var predicate = PRLC_PREDICATE
        public static var equational = PRLC_EQUATIONAL
        public static var connective = PRLC_CONNECTIVE

        // MARK: - public protocol properties

        public static let wildcard = -1

        /// The symbol of the node, e.g. "f".
        public var symbol: String {
            Tptp.Term.keysToTypedSymbolsMapping[key].symbol
        }

        /// The TPTP type of the node, e.g. PRLC_FUNCTION.
        public var type: PRLC_TREE_NODE_TYPE {
            Tptp.Term.keysToTypedSymbolsMapping[key].type
        }

        /// The key of the node, e.g. 1 with [ 1: "f" ]
        /// The key, not the symbol, is used for unification
        public let key: Int

        /// The children of the node, e.g. [X, z].
        public let nodes: [Term]?

        // MARK: - private static tables and functions

        /// A symbol might be used multiple times with different types,
        /// e.g. as a name of an annotated formula and as a constant in this formula.
        /// see agatha, butler, charles in [PUZ001-1.p](http://www.tptp.org/cgi-bin/SeeTPTP?Category=Problems&Domain=PUZ&File=PUZ001-1.p)
        /// - Note: Not the same as Tptp.SymbolType
        public struct TypedSymbol : Hashable {
            let type : PRLC_TREE_NODE_TYPE
            let symbol : String
            let arity : Int
        }

        // Lookup for symbols by key, e.g. symbols[3] -> ("f", function)
        private static var keysToTypedSymbolsMapping = [TypedSymbol]()

        public static var typedSymbols: [Tptp.Term.SymbolType: [(String, Int)]] {
            var dictionary = [SymbolType: [(String, Int)]]()
            for symbolType in [ equational, predicate, function ] {
                dictionary[symbolType] = [(String, Int)]()
            }

            for typedSymbol in keysToTypedSymbolsMapping {
                dictionary[typedSymbol.type]?.append((typedSymbol.symbol, typedSymbol.arity))
            }

            return dictionary
        }


        // Lookup for key by symbols, e.g. table["f"] -> 3
        private static var typedSymbolsToKeyMapping = [TypedSymbol: Int]()

        // All (shared) nodes
        private static var pool = Set<Term>()

        // - Reset mappings for symbols, types, and keys.
        // - Reset pool of terms.
        public static func reset() {
            pool = Set<Term>()
            typedSymbolsToKeyMapping = [TypedSymbol: Int]()
            keysToTypedSymbolsMapping = [TypedSymbol]()
        }

        public static var sizes: (keys: Int, symbols: Int, pool: Int) {
            return (keysToTypedSymbolsMapping.count, typedSymbolsToKeyMapping.count, pool.count)
        }

        /// - Parameters:
        ///   - type:
        ///   - symbol:
        /// - Returns:
        private static func combine(_ type: PRLC_TREE_NODE_TYPE, _ symbol: String) -> String {
            return "\(symbol)_\(type)"
        }

        private static func symbolize(_ type: PRLC_TREE_NODE_TYPE, _ symbol: String, _ arity: Int) -> Int {
            let typedSymbol = TypedSymbol(type: type, symbol: symbol, arity: arity)

            guard let key = Term.typedSymbolsToKeyMapping[typedSymbol] else {
                // typed symbol is not known yet
                let count = Term.keysToTypedSymbolsMapping.count
                Term.typedSymbolsToKeyMapping[typedSymbol] = count
                Term.keysToTypedSymbolsMapping.append(typedSymbol)
                return count
            }

            return key
        }

        private init(key: Int, nodes: [Term]?) {
            self.key = key
            self.nodes = nodes
        }

        public static func variable(_ symbol: String) -> Term {
            term(Term.variable, symbol)
        }

        public static func term(_ type: PRLC_TREE_NODE_TYPE, _ symbol: String, nodes: [Term]? = nil) -> Term {

            let key = Term.symbolize(type, symbol, nodes?.count ?? -1)
            let node : Term
            switch type {
            case PRLC_VARIABLE:
                assert(nodes == nil, "\(type) \(symbol))")
                node = Term(key: key, nodes: nil)
            default:
                assert(nodes != nil, "\(type) \(symbol))")
                node = Term(key: key, nodes: nodes)
            }

            return pool.insert(node).memberAfterInsert
        }

        static func create(tree parent: TreeNodeRef) -> Term? {
            guard parent.type != PRLC_VARIABLE else {
                return Term.term(parent.type, parent.symbol ?? "n/a", nodes: nil)
            }

            let children = parent.children.compactMap {
                child in
                Term.create(tree: child)
            }

            return Term.term(parent.type, parent.symbol ?? "n/a", nodes: children)
        }

        public lazy var description: String = {
            guard let children = nodes?.map({ $0.description }) else {
                assert(self.type == PRLC_VARIABLE)
                return symbol
            }

            let count = children.count // ≥ 0

            switch (self.type, self.symbol, count) {
            case (PRLC_FILE, _,_):
                let list = children.joined(separator: "\n")
                return "\(symbol)\n\(list)"

            case (PRLC_FOF, _,_):
                assert(count == 2)
                return "fof(\(symbol),\(children.first!),\n\t( \(children.last!) ))."

            case (PRLC_CNF, _,_):
                assert(count == 2)
                return "cnf(\(symbol),\(children.first!),\n\t( \(children.last!) ))."

            case (PRLC_QUANTIFIER, _,_):
                let variables = children[..<(count - 1)].map { $0 }.joined(separator: ",")
                return "\(symbol) [\(variables)] :\n\t( \(children.last!) )"

            case (PRLC_CONNECTIVE, "~", 1):
                return "\(symbol)\(children.first!)"

            case (PRLC_CONNECTIVE, _, 1):
                return "\(children.first!)"

            case (PRLC_CONNECTIVE, _, _):
                return children.joined(separator: " \(symbol) ")

            case (PRLC_EQUATIONAL, _, _):
                assert(count == 2)
                return "\(children.first!) \(symbol) \(children.last!)"

            case (PRLC_INCLUDE, _, 0):
                return "include(\(symbol))."
            case (PRLC_INCLUDE, _, _):
                let terms = children.joined(separator: ",")
                return "include(\(symbol),[\(terms)])."

            // (variable), constant function, role
            case (_, _, 0):
                return symbol

            case (_, _, _):
                let terms = children.joined(separator: ",")
                return "\(symbol)(\(terms))"
            }
        }()

        /// P(f(X,Y), g(Z))
        ///     P.1.f.1.*
        ///     P.1.f.2.*
        ///     P.2.g.1.*
        public lazy var paths:[[Int]] = {
            guard let nodes = self.nodes else {
                return [[Tptp.Term.wildcard]] // -1 '*', i.e. a variable
            }

            if nodes.count == 0 {
                return [[ self.key ]] // e.g. [[ 'f' ]]
            }

            let result = nodes.enumerated().flatMap { index, term -> [[Int]] in
                term.paths.map { path in [self.key, index ] + path }
            }

            return result
        }()
    }
}

public extension Tptp.Term {
    static func create(file: Tptp.File) -> Tptp.Term? {
        guard let root = file.root else {
            return nil
        }
        return Tptp.Term.create(tree: root)
    }
}

public extension Tptp.Term {
    var negated: Tptp.Term? {
        switch (self.type, self.symbol) {
        case (Tptp.Term.connective, "~"):
            assert(self.nodes?.count == 1)
            return self.nodes?.first

        case (Tptp.Term.predicate, _):
            return Tptp.Term.term(Tptp.Term.connective, "~", nodes: [self])

        case (Tptp.Term.equational, "="):
            assert(self.nodes?.count == 2)
            return Tptp.Term.term(Tptp.Term.equational, "!=", nodes: self.nodes)

        case (Tptp.Term.equational, "!="):
            assert(self.nodes?.count == 2)
            return Tptp.Term.term(Tptp.Term.equational, "=", nodes: self.nodes)

        default:
            return nil // undefined for variables, constants, functions, etc.
        }
    }

    // rename all Variable to variable
    var lowercased: Tptp.Term {
        switch self.type {
        case Tptp.Term.variable:
            // assert(self.symbol.first?.isUppercase ?? false)
            let prefix = self.symbol.prefix(1).lowercased()
            let suffix = self.symbol.suffix(self.symbol.count - 1)
            let symbol = prefix + suffix
            return Tptp.Term.term(Tptp.Term.variable, symbol)

        default:
            let nodes = self.nodes?.map { $0.lowercased }
            return Tptp.Term.term(self.type, self.symbol, nodes: nodes)
        }

    }

    var uppercased: Tptp.Term {
        switch self.type {
        case Tptp.Term.variable:
            // assert(self.symbol.first?.isLowercase ?? false)
            let prefix = self.symbol.prefix(1).uppercased()
            let suffix = self.symbol.suffix(self.symbol.count - 1)
            let symbol = prefix + suffix
            return Tptp.Term.term(Tptp.Term.variable, symbol)

        default:
            let nodes = self.nodes?.map { $0.uppercased }
            return Tptp.Term.term(self.type, self.symbol, nodes: nodes)
        }

    }

    var distinct: Tptp.Term {
        switch self.type {
        case Tptp.Term.variable:
            return Tptp.Term.term(Tptp.Term.variable, "•\(symbol)•")

        default:
            let nodes = self.nodes?.map { $0.distinct }
            return Tptp.Term.term(self.type, self.symbol, nodes: nodes)
        }

    }

    var indistinct: Tptp.Term {
        switch self.type {
        case Tptp.Term.variable:
            return Tptp.Term.term(Tptp.Term.variable, symbol.replacingOccurrences(of: "•", with: ""))

        default:
            let nodes = self.nodes?.map { $0.indistinct }
            return Tptp.Term.term(self.type, self.symbol, nodes: nodes)
        }

    }
}

public extension Tptp.Clause {
    var distinct: Tptp.Clause {
        self.map { $0.distinct }
    }

    var indistinct: Tptp.Clause {
        self.map { $0.indistinct }
    }

}
