import Tptp
import Utile

public protocol SolverContext {
    associatedtype Symbol
    associatedtype Sort
    associatedtype Function
    associatedtype Term
    associatedtype Predicate
    associatedtype Formula where Formula == Model.Context.Formula
    associatedtype Model: SolverModel where Model.Context == Self

    typealias Literal = Formula
    typealias Literals = [Formula]

    var name : String { get }
    var version: String { get }
    init()

    var boolTau : Sort { get }
    var freeTau : Sort { get }

    var bot: Formula { get }
    var top: Formula { get }

    func declare(constant: Symbol) -> Term
    func declare(proposition: Symbol) -> Formula
    func declare(function: Symbol, arity: Int) -> Function
    func declare(predicate: Symbol, arity: Int) -> Predicate

    func apply(function: Function, args: [Term]) -> Term
    func apply(predicate: Predicate, args: [Term]) -> Formula
    func equate(lhs: Term, rhs: Term) -> Formula
    func nequate(lhs: Term, rhs: Term) -> Formula

    func negate(formula: Formula) -> Formula
    func conjunct(formulae: [Formula]) -> Formula
    func disjunct(formulae: [Formula]) -> Formula
    func formula(_ lhs: Formula, implies rhs: Formula) -> Formula
    func formula(_ lhs: Formula, iff rhs: Formula) -> Formula

    func assert(formula: Formula)
    func assert(clause: [Formula])

    var isSatisfiable: Bool { get }
    func createModel() -> Model?

    func string(formula: Formula) -> String?
}

public extension SolverContext {
    func nequate(lhs: Term, rhs: Term) -> Formula {
        let atom = equate(lhs: lhs, rhs: rhs)
        return negate(formula: atom)
    }
}

public extension SolverContext where Self.Symbol == String {
    func encode<T: Utile.Term>(clause: T) -> Formula?
            where T.Symbol == String  {
        Swift.assert(clause.symbol.count > 0, "clause symbol name must not be empty")

        switch (clause.type, clause.symbol, clause.nodes?.count ?? 0) {
        case (T.connective, "|", 0):
            return self.bot // an empty clause is not satisfiable

        case (T.connective, "|", 1), (T.connective, "∨", 1):
            return encode(literal: clause.nodes![0])

        case (T.connective, "|", let count), (T.connective, "∨", let count):
            let literals = encode(literals: clause.nodes!)
            Swift.assert(count == literals.count)
            return disjunct(formulae: literals)

        case (let type, let symbol, let count):
            Swift.assert(false, "(\(type)_\(symbol)_\(count)) is not a valid clause definition.")
            return nil
        }
    }

    func encode<T: Utile.Term>(literals: [T]) -> [Formula]
            where T.Symbol == String {
        return literals.compactMap {
            (f:T) -> Formula? in
            return encode(literal: f)
        }
    }

    func encode<T: Utile.Term>(literal: T) -> Formula?
    where T.Symbol == String  {
        Swift.assert(literal.symbol.count > 0, "literal symbol name must not be empty")
        switch (literal.type, literal.symbol, literal.nodes?.count ?? 0) {
        case (T.predicate, let symbol, 0):
            return declare(proposition: symbol)

        case (T.predicate, let symbol, let count):
            let p = declare(predicate: symbol, arity: count)
            let terms = encode(terms: literal.nodes!)
            precondition(count == terms.count)
            return apply(predicate: p, args: terms)

        case (T.equational, "!=", 2), (T.equational, "≠", 2):
            let terms = encode(terms: literal.nodes!)
            Swift.assert(2 == terms.count)
            return nequate(lhs: terms[0], rhs: terms[1])

        case (T.equational, "=", 2):
            let terms = encode(terms: literal.nodes!)
            Swift.assert(2 == terms.count)
            return equate(lhs: terms[0], rhs: terms[1])

        case (T.connective, "~", 1), (T.connective, "!", 1):
            let atom = encode(literal: literal.nodes![0])!
            return negate(formula: atom)

        case (let type, let symbol, let count):
            Swift.assert(false, "(\(type)_\(symbol)_\(count)) is not a valid literal definition.")
            return nil
        }
    }

    func encode<T: Utile.Term>(terms: [T]) -> [Term]
            where T.Symbol == String {
        return terms.compactMap {
            (t:T) -> Term? in
            return encode(term: t)
        }
    }

    func encode<T: Utile.Term >(term: T) -> Term?
            where T.Symbol == String  {
        Swift.assert(term.symbol.count > 0, "term symbol name must not be empty")

        switch (term.type, term.symbol, term.nodes?.count ?? -1) {

        case (T.variable, _, _):
            return declare(constant: "⊥")

        case (T.function, let symbol, 0):
            return declare(constant: symbol)

        case (T.function, let symbol, let count):
            Swift.assert(count > 0 && term.nodes != nil, "can not occur")
            let terms = encode(terms: term.nodes!)
            Swift.assert(count == terms.count)
            let f = declare(function: symbol, arity: count)
            return apply(function: f, args: terms)

        case (let type, let symbol, let count):
            Swift.assert(false, "(\(type)_\(symbol)_\(count)) is not a valid term definition.")
            return nil
        }
    }
}

extension SolverContext {
    // conjunction shorthands

    func conjunct(formulae: Formula...) -> Formula {
        conjunct(formulae: formulae)
    }

    func conjunct<S: Swift.Sequence>(_ sequence: S) -> Formula where S.Element == Formula {
        conjunct(formulae: sequence.map { $0 })
    }

    func formula(_ lhs: Formula, and rhs: Formula) -> Formula {
        conjunct(formulae: lhs, rhs)
    }
}

extension SolverContext {
    // disjunction shorthands

    func disjunct(formulae: Formula...) -> Formula {
        disjunct(formulae: formulae)
    }

    func disjunct<S: Swift.Sequence>(_ sequence: S) -> Formula where S.Element == Formula {
        disjunct(formulae: sequence.map { $0 })
    }

    func formula(_ lhs: Formula, or rhs: Formula) -> Formula {
        disjunct(formulae: lhs, rhs)
    }
}

public extension SolverContext where Self.Symbol == String {
    func encode_assert(clause literals: Tptp.Literals) -> Self.Literals {
        let smtLiterals = self.encode(literals: literals)
        Swift.assert(literals.count == smtLiterals.count)

        self.assert(clause: smtLiterals)

        Swift.assert(literals.count == smtLiterals.count)
        return smtLiterals
    }

}

public protocol SolverModel {
    associatedtype Context: SolverContext
    init?(context: Context)
    func satisfies(formula: Context.Formula) -> Bool?
}

extension SolverModel {
    func selectLiteral(from literals: Zip2Sequence<Tptp.Clause, Context.Literals>) -> Tptp.Literal? {
        for (literal, smtLiteral) in literals {
            if self.satisfies(formula: smtLiteral) ?? false {
                #if DEBUG
                // print("✅\t", literal)
                #endif
                return literal
            }
            #if DEBUG
            // print("❌\t", literal)
            #endif
        }
        return nil
    }
}