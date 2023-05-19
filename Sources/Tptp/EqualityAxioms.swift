import Base
import Utile
import Foundation

public extension [Tptp.Term.SymbolType: [(String, Int)]] {

    private var maxArity: Int {
        let arity = self[Tptp.Term.function]?.reduce(3) {
            (a,b) in return Swift.max(a, b.1)
        } ?? 3

        return self[Tptp.Term.predicate]?.reduce(arity) {
            (a,b) in return Swift.max(a, b.1)
        } ?? arity
    }

    private func variables(prefix: String, count: Int) -> [Tptp.Term] {
        (1...maxArity).map { index -> Tptp.Term in
            Tptp.Term.term(Tptp.Term.variable, "\(prefix)\(index)")
        }
    }

    /// Reflexivity of equality: x = x
    private func reflexivity(x: Tptp.Term) -> [Tptp.Term] {
        [ Tptp.Term.term(Tptp.Term.equational, "=", nodes: [x, x]) ]
    }

    private func namedReflexivity(x: Tptp.Term) -> Tptp.NamedClause {
        let literals = reflexivity(x: x)
        return Tptp.NamedClause(
            name: "=",
            role: .reflexivity,
            literals: literals
        )
    }

    /// Symmetry of equality: x = y | y != x
    private func symmetry(x: Tptp.Term, y: Tptp.Term) -> [Tptp.Term] {
        [
            Tptp.Term.term(Tptp.Term.equational, "=", nodes: [x, y]),
            Tptp.Term.term(Tptp.Term.equational, "!=", nodes: [y, x])
        ]
    }

    private func namedSymmetry(x: Tptp.Term, y: Tptp.Term) -> Tptp.NamedClause {
        let literals = symmetry(x: x, y: y)
        return Tptp.NamedClause(
            name: "=",
            role: .symmetry,
            literals: literals
        )
    }

    /// Transitivity of equality: x != y | y ! z | x = z
    private func transitivity(x: Tptp.Term, y: Tptp.Term, z: Tptp.Term) -> [Tptp.Term] {
        [
            Tptp.Term.term(Tptp.Term.equational, "!=", nodes: [x, y]),
            Tptp.Term.term(Tptp.Term.equational, "!=", nodes: [y, z]),
            Tptp.Term.term(Tptp.Term.equational, "=", nodes: [x, z])
        ]
    }

    private func namedTransitivity(x: Tptp.Term, y: Tptp.Term, z: Tptp.Term) ->  Tptp.NamedClause {
        let literals = transitivity(x: x, y: y, z: z)
        return Tptp.NamedClause(
            name: "=",
            role: .transitivity,
            literals: literals
        )
    }

    /// Congruence of equality: x_1 != y_1 | x2 != y_2 | x_1 != x_2 | y_1 = y_2
    private func congruence(xs: [Tptp.Term], ys: [Tptp.Term]) -> [Tptp.Term] {
        [
            Tptp.Term.term(Tptp.Term.equational, "!=", nodes: [xs[0], ys[0]]),
            Tptp.Term.term(Tptp.Term.equational, "!=", nodes: [xs[1], ys[1]]),
            Tptp.Term.term(Tptp.Term.equational, "!=", nodes: [xs[0], xs[1]]),
            Tptp.Term.term(Tptp.Term.equational, "=", nodes: [ys[0], ys[1]])
        ]
    }

    private func namedCongruence(_ xs: [Tptp.Term], _ ys: [Tptp.Term]) -> Tptp.NamedClause {
        let literals = congruence(xs: xs, ys: ys)
        return Tptp.NamedClause(
            name: "=",
            role: .congruence,
            literals: literals
        )
    }

    private func inequalities(arity: Int, _ xs: [Tptp.Term], _ ys: [Tptp.Term]) -> [Tptp.Term] {
        (0..<arity).map { index -> Tptp.Term in
            Tptp.Term.term(Tptp.Term.equational, "!=", nodes: [xs[index], ys[index]])
        }
    }

    // congruence of function symbol: x != y | f(x) = f(y)
    private func congruence(function symbol: String, arity: Int, _ xs: [Tptp.Term], _ ys: [Tptp.Term]) -> [Tptp.Term] {
        var literals = inequalities(arity: arity, xs, ys)
        let fxs = Tptp.Term.term(Tptp.Term.function, symbol, nodes: Array(xs[0..<arity]))
        let fys = Tptp.Term.term(Tptp.Term.function, symbol, nodes: Array(ys[0..<arity]))
        let equation = Tptp.Term.term(Tptp.Term.equational, "=", nodes: [fxs, fys])
        literals.append(equation)
        return literals
    }

    private func namedCongruence(function symbol: String, arity: Int, _ xs: [Tptp.Term], _ ys: [Tptp.Term]) -> Tptp.NamedClause {
        let literals = congruence(function: symbol, arity: arity, xs, ys)

        return Tptp.NamedClause(
            name: "\(symbol)(\(arity))",
            role: .congruence,
            literals: literals
        )
    }

    /// congruence of predicate symbol: x != y | P(x) => P(y) aka x != y | ~P(x) | P(y)
    private func congruence(predicate symbol: String, arity: Int, _ xs: [Tptp.Term], _ ys: [Tptp.Term]) -> [Tptp.Term] {
        var literals = inequalities(arity: arity, xs, ys)
        let Pxs = Tptp.Term.term(Tptp.Term.predicate, symbol, nodes: Array(xs[0..<arity]))
        let Pys = Tptp.Term.term(Tptp.Term.predicate, symbol, nodes: Array(ys[0..<arity]))
        literals.append(Pxs.negated!)
        literals.append(Pys)
        return literals
    }

    private func namedCongruence(predicate symbol: String, arity: Int, _ xs: [Tptp.Term], _ ys: [Tptp.Term]) -> Tptp.NamedClause {
        let literals = congruence(predicate: symbol, arity: arity, xs, ys)

        return Tptp.NamedClause(
            name: "\(symbol)(\(arity))",
            role: .congruence,
            literals: literals
        )
    }


    var equalityAxioms: [Tptp.NamedClause]? {

        guard let equationals = self[Tptp.Term.equational], equationals.count > 0 else {
            return nil
        }

        var clauses = [Tptp.NamedClause]()
       

        let arity = maxArity
        let xs = variables(prefix: "X", count: arity)
        let ys = variables(prefix: "Y", count: arity)

        // Reflexivity: X0=X0
        let reflexivity = namedReflexivity(x: xs[0])
        Syslog.debug { "Add \(reflexivity.name)-\(reflexivity.role): \(reflexivity.literals)" }

        // Symmetry: X0=X1 | X1!=X0
        let symmetry = namedSymmetry(x: xs[0], y: xs[1])
        Syslog.debug { "Add \(symmetry.name)-\(symmetry.role): \(symmetry.literals)" }

        let transitivity = namedTransitivity(x: xs[0], y: xs[1], z: xs[2])
        Syslog.debug { "Add \(transitivity.name)-\(transitivity.role): \(transitivity.literals)" }

        let congruence = namedCongruence(xs, ys)
        Syslog.debug { "Add \(congruence.name)-\(congruence.role): \(congruence.literals)" }

        clauses.append(contentsOf: [reflexivity, symmetry, transitivity, congruence])

        for (type, symbols) in self {
            for (symbol, arity) in symbols {
                switch (type, symbol, arity) {
                
                case (Tptp.Term.equational, _, 2):

                break

                case (Tptp.Term.equational, _, _):
                Syslog.error { "\(type) symbol '\(symbol)' with arity '\(symbol)' cannot be handled."}
                assert(false)

                case (Tptp.Term.function, _, _):
                let function = self.namedCongruence(function: symbol, arity: arity, xs, ys)
                Syslog.info { "Add \(type) \(function.name)-\(function.role): \(function.literals)"}
                clauses.append(function)

                case (Tptp.Term.predicate, _, _):
                let predicate = self.namedCongruence(predicate: symbol, arity: arity, xs, ys)
                Syslog.info { "Add \(type) \(predicate.name)-\(predicate.role): \(predicate.literals)"}
                clauses.append(predicate)


                case (Tptp.Term.variable, _, _):
                    assert(arity == -1)

                case (_, _, _):
                    Syslog.info { "\(type) symbol '\(symbol)' with arity \(arity) was ignored."}
                }
            }
        }
        return clauses
    }
}

