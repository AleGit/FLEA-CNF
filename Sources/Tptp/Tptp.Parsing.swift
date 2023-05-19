import CTptpParsing

public extension Tptp {
    /// <formula_role>         :== axiom | hypothesis | definition | assumption |
    //                           lemma | theorem | corollary | conjecture |
    //                           negated_conjecture | plain | type |
    //                           fi_domain | fi_functors | fi_predicates | unknown
    enum Role: String, CaseIterable {
        /// [SyntaxBNF](https://tptp.org/cgi-bin/SeeTPTP?Category=Documents&File=SyntaxBNF) `<formula_role>`
        case axiom, hypothesis, definition, assumption,
             lemma, theorem, corollary, conjecture,
             negated_conjecture, plain, type,
             fi_domain, fi_functors, fi_predicates, unknown
        /// Generated clauses
        case reflexivity, symmetry, transitivity, congruence, conflict

    }
}

public extension Tptp {
    struct NamedClause {
        public let name: String
        public let role: Tptp.Role
        public let literals: [Tptp.Term]

        public init(name: String, role: Tptp.Role, literals: [Tptp.Term]) {
            self.name = name
            self.role = role
            self.literals = literals
        }
    }
}

extension PRLC_TREE_NODE_TYPE : CustomStringConvertible {
    public var description: String {
        switch self {
        case PRLC_UNDEFINED: return "undefined"
        case PRLC_FILE: return "file"
        case PRLC_FOF: return "fof"
        case PRLC_CNF: return "cnf"
        case PRLC_INCLUDE: return "include"
        case PRLC_NAME: return "name"
        case PRLC_ROLE: return "role"
        case PRLC_ANNOTATION: return "annotation"
        case PRLC_QUANTIFIER: return "quantifier"
        case PRLC_CONNECTIVE: return "connective"
        case PRLC_EQUATIONAL: return "equational"
        case PRLC_PREDICATE: return "predicate"
        case PRLC_FUNCTION: return "function"
        case PRLC_VARIABLE: return "variable"
        default: return "unavailable"

        }
    }
}