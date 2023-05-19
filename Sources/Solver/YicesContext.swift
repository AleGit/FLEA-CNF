import CYices
import Base
import Foundation

public struct Yices {
    public final class Context: SolverContext {

        private static var lock: Lock = Base.Mutex()
        private static var contextCount = 0
        let context: OpaquePointer // context_t *

        public typealias Sort = type_t
        public typealias Function = type_t
        public typealias Term = term_t
        public typealias Predicate = type_t
        public typealias Formula = term_t

        public init() {
            Context.lock.lock()
            defer { Context.lock.unlock() }
            if Context.contextCount == 0 {
                yices_init()
            }
            Context.contextCount += 1

            let config = yices_new_config()
            defer { yices_free_config(config) }
            // quantifier free uninterpreted functions
            yices_default_config_for_logic(config, "QF_UF")
            context = yices_new_context(config)
        }

        deinit {
            Context.lock.lock()
            defer {
                Context.lock.unlock()
            }

            yices_free_context(context)
            Context.contextCount -= 1

            if Context.contextCount == 0 {
                yices_exit()
            }
        }

        public lazy var boolTau: type_t = yices_bool_type()
        public lazy var freeTau: type_t = {
            let name = "𝛕"
            var tau = yices_get_type_by_name(name)
            if tau == NULL_TYPE {
                tau = yices_new_uninterpreted_type()
                yices_set_type_name(tau, name)
            }
            return tau
        }()

        public lazy var top: term_t = yices_true()
        public lazy var bot: term_t = yices_false()
    }
}

public extension Yices.Context {

    private func declare(symbol: String, tau: Sort) -> term_t {
        var term = yices_get_term_by_name(symbol)
        if term == NULL_TERM {
            term = yices_new_uninterpreted_term(tau)
            yices_set_term_name(term, symbol)
        }
        else {
            Swift.assert(tau == yices_type_of_term(term))
        }
        return term
    }

    private func declare(type name: String, domain: [type_t], range: type_t) -> type_t {
        var tau = yices_get_type_by_name(name)
        if tau == NULL_TYPE {
            tau = yices_function_type(UInt32(domain.count), domain, range)
            yices_set_type_name(tau, name)
        }
        return tau
    }


    func declare(constant: String) -> term_t {
        declare(symbol: constant, tau: freeTau)
    }

    func declare(proposition: String) -> term_t {
        declare(symbol: "\(proposition)_p", tau: boolTau)
    }

    func declare(function: String, arity: Int) -> type_t {
        let domain = [Term](repeatElement(freeTau, count: arity))
        let tau = declare(type: "f_\(arity)", domain: domain, range: freeTau)
        return declare(symbol: "\(function)_f\(arity)", tau: tau)
    }

    func declare(predicate: String, arity: Int) -> type_t {
        let domain = [type_t](repeatElement(freeTau, count: arity))
        let tau = declare(type: "p_\(arity)", domain: domain, range: boolTau)
        return declare(symbol: "\(predicate)_p\(arity)", tau: tau)
    }

    func apply(function: term_t, args: [term_t]) -> term_t {
        yices_application(function, UInt32(args.count), args)
    }

    func apply(predicate: term_t, args: [term_t]) -> term_t {
        yices_application(predicate, UInt32(args.count), args)
    }

    func equate(lhs: term_t, rhs: term_t) -> term_t {
        yices_eq(lhs, rhs)
    }

}

public extension Yices.Context {

    func negate(formula: term_t) -> term_t {
        yices_not(formula)
    }

    func inequate(lhs: term_t, rhs: term_t) -> term_t {
        yices_neq(lhs, rhs)
    }

    func conjunct(formulae: [term_t]) -> term_t {
        var args = formulae
        return yices_and(UInt32(args.count), &args)
    }

    func disjunct(formulae: [term_t]) -> term_t {
        var args = formulae
        return yices_or(UInt32(args.count), &args)
    }

    func formula(_ lhs: term_t, implies rhs: term_t) -> term_t {
        yices_implies(lhs, rhs)
    }

    func formula(_ lhs: term_t, iff rhs: term_t) -> term_t {
        yices_iff(lhs, rhs)
    }
}

public extension Yices.Context {

    func assert(formula: term_t) {
        yices_assert_formula(context, formula)
    }

    func assert(clause literals: [term_t]) {
        let formula = disjunct(formulae: literals)
        assert(formula: formula)
    }

    var isSatisfiable: Bool {
        yices_check_context(context, nil) == STATUS_SAT
    }

    func createModel() -> Model? {
        Model(context: self)
    }
}

public extension Yices.Context {
    func string(formula: Formula) -> String? {
        guard let c = yices_term_to_string(formula, 120, 18, 0) else { return nil }
        defer { free(c) }
        return String(validatingUTF8: c)
    }
}
