import CTptpParsing



extension Tptp.File {

    enum Variety: Hashable {
        case undefined

        /// <TPTP_file>
        case file

        /// <fof_annotated>
        case fof
        /// <cnf_annotated>
        case cnf
        /// <include>
        case include // file name

        case name

        case role
        case annotation

        case universal // ! X Y ... s with implicit arity == 1..<∞
        case existential // ? X Y ... s with implicit arity == 1..<∞

        case negation // ~ s with implicit arity == 1
        case disjunction // s, t ... with implicit arity == 0..<∞
        case conjunction // s & t ... with implicit arity == 0..<∞

        case implication // s => t with implicit arity == 2
        case reverseimpl // s <= t with implicit arity == 2
        case bicondition // s <=> t with implicit arity == 2
        case xor // <~> with implicit arity == 2
        case nand // ~& with implicit arity == 2
        case nor // ~| with implicit arity == 2

        // case gentzen // -->
        // case star // *
        // case plus // +

        // $true
        // $false

        case equation // s = t with implicit arity == 2
        case inequation // s != t with implicit arity == 2

        case predicate(Int) // predicates and propositions with fixed arity per symbol

        case function(Int) // functions and constants with fixed arity per symbol
        case variable // variables
    }
}


extension Tptp.File.Variety {

    // swiftlint:disable cyclomatic_complexity
    // swiftlint:disable function_body_length
    init(of node: TreeNodeRef) {

        guard let name = node.symbol else {
            self = .undefined
            return
        }
        let type = node.type

        switch (name, type) {

            /* logical symbols */

        case ("!", _):
            assert(type == PRLC_QUANTIFIER, "'\(name)' is not a quantifier \(type).")
            self = .universal
            // assert (string.symbolType == Tptp.SymbolType.universal)

        case ("?", _):
            assert(type == PRLC_QUANTIFIER, "'\(name)' is not a quantifier \(type).")
            self = .existential
            // assert (string.symbolType == Tptp.SymbolType.existential)

        case ("~", _):
            assert(type == PRLC_CONNECTIVE, "'\(name)' is not a connective \(type).")
            self = .negation
            // assert (string.symbolType == Tptp.SymbolType.negation)

        case ("|", _):
            assert(type == PRLC_CONNECTIVE, "'\(name)' is not a connective \(type).")
            self = .disjunction
            // assert (string.symbolType == Tptp.SymbolType.disjunction)

        case ("&", _):
            assert(type == PRLC_CONNECTIVE, "'\(name)' is not a connective \(type).")
            self = .conjunction
            // assert (string.symbolType == Tptp.SymbolType.conjunction)

        case ("=>", _):
            assert(type == PRLC_CONNECTIVE, "'\(name)' is not a connective \(type).")
            self = .implication
            // assert (string.symbolType == Tptp.SymbolType.implication)

        case ("<=", _):
            assert(type == PRLC_CONNECTIVE, "'\(name)' is not a connective \(type).")
            self = .reverseimpl
            // assert (string.symbolType == Tptp.SymbolType.reverseimpl)

        case ("<=>", _):
            assert(type == PRLC_CONNECTIVE, "'\(name)' is not a connective \(type).")
            self = .bicondition
            // assert (string.symbolType == Tptp.SymbolType.bicondition)

        case ("<~>", _):
            assert(type == PRLC_CONNECTIVE, "'\(name)' is not a connective \(type).")
            self = .xor
            // assert (string.symbolType == Tptp.SymbolType.xor)

        case ("~&", _):
            assert(type == PRLC_CONNECTIVE, "'\(name)' is not a connective \(type).")
            self = .nand
            // assert (string.symbolType == Tptp.SymbolType.nand)

        case ("~|", _):
            assert(type == PRLC_CONNECTIVE, "'\(name)' is not a connective \(type).")
            self = .nor
            // assert (string.symbolType == Tptp.SymbolType.nor)

            /* error */
        case (_, PRLC_CONNECTIVE):
            assert(false, "Unknown connective '\(name)'")
            self = .undefined

        case ("=", _):
            assert(type == PRLC_EQUATIONAL, "'\(name)' is not equational \(type).")
            self = .equation
            // assert (string.symbolType == Tptp.SymbolType.equation)

        case ("!=", _):
            assert(type == PRLC_EQUATIONAL, "'\(name)' is not equational \(type).")
            self = .inequation
            // assert (string.symbolType == Tptp.SymbolType.inequation)

            /* error */
        case (_, PRLC_EQUATIONAL):
            assert(false, "Unknown equational '\(name)'")
            self = .undefined

        case (_, PRLC_PREDICATE):
            self = .predicate(node.childCount)
            // assert (string.symbolType == Tptp.SymbolType.undefined)

        case (_, PRLC_FUNCTION):
            self = .function(node.childCount)
            // assert (string.symbolType == Tptp.SymbolType.undefined)

        case (_, PRLC_VARIABLE):
            // assert (string.symbolType == Tptp.SymbolType.variable)
            self = .variable

            /* non-logical symbols */

        case (_, PRLC_FILE):
            self = .file
        case (_, PRLC_FOF):
            self = .fof
        case (_, PRLC_CNF):
            self = .cnf
        case (_, PRLC_INCLUDE):
            self = .include
        case (_, PRLC_ROLE):
            self = .role
        case (_, PRLC_ANNOTATION):
            self = .annotation

        default:
            self = .undefined
        }
    }

    // swiftlint:enable cyclomatic_complexity
    // swiftlint:enable function_body_length
    
}

