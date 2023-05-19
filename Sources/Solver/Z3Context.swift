import CZ3Api

public struct Z3 {
    public final class Context: SolverContext {

        let context: Z3_context
        let solver: Z3_solver

        public typealias Sort = Z3_sort
        public typealias Function = Z3_func_decl
        public typealias Term = Z3_ast
        public typealias Predicate = Z3_func_decl
        public typealias Formula = Z3_ast

        public init() {
            let cfg = Z3_mk_config()
            defer {
                Z3_del_config(cfg)
            }
            context = Z3_mk_context(cfg)
            solver = Z3_mk_solver(context)
            Z3_solver_inc_ref(context, solver)
        }

        deinit {
            Z3_solver_dec_ref(context, solver)
            Z3_del_context(context)
        }

        public lazy var boolTau: Z3_sort = Z3_mk_bool_sort(context)
        public lazy var freeTau: Z3_sort = {
            let symbol = Z3_mk_string_symbol(context, "𝛕")
            return Z3_mk_uninterpreted_sort(context, symbol)
        }()

        public lazy var top: Z3_ast = Z3_mk_true(context)
        public lazy var bot: Z3_ast = Z3_mk_false(context)
    }
}

public extension Z3.Context {
    func declare(constant: String) -> Z3_ast {
        let symbol = Z3_mk_string_symbol(context, constant)
        return Z3_mk_const(context, symbol, freeTau)
    }

    func declare(proposition: String) -> Z3_ast {
        let symbol = Z3_mk_string_symbol(context, proposition)
        return Z3_mk_const(context, symbol, boolTau)
    }

    func declare(function: String, arity: Int) -> Z3_func_decl {
        let symbol = Z3_mk_string_symbol(context, function)
        let domain = [Z3_sort?](repeatElement(freeTau, count: arity))
        return Z3_mk_func_decl(context, symbol, UInt32(arity), domain, freeTau)
    }

    func declare(predicate: String, arity: Int) -> Z3_func_decl {
        let symbol = Z3_mk_string_symbol(self.context, predicate)
        let domain = [Z3_sort?](repeatElement(freeTau, count: arity))
        return Z3_mk_func_decl(context, symbol, UInt32(arity), domain, boolTau)

    }

    private func apply(_ fp: Z3_func_decl, args: [Z3_ast]) -> Z3_ast {
        let args :[Z3_ast?] = args
        return Z3_mk_app(context, fp, UInt32(args.count), args)
    }

    func apply(function: Z3_func_decl, args: [Z3_ast]) -> Z3_ast {
        apply(function, args: args)
    }

    func apply(predicate: Z3_func_decl, args: [Z3_ast]) -> Z3_ast {
        apply(predicate, args: args)
    }

    func equate(lhs: Z3_ast, rhs: Z3_ast) -> Z3_ast {
        Z3_mk_eq(context, lhs, rhs)
    }
}

public extension Z3.Context {

    func negate(formula: Z3_ast) -> Z3_ast {
        Z3_mk_not(context, formula)
    }

    func conjunct(formulae: [Z3_ast]) -> Z3_ast {
        let args: [Z3_ast?] = formulae
        return Z3_mk_and(context, UInt32(args.count), args)
    }

    func disjunct(formulae: [Z3_ast]) -> Z3_ast {
        let args: [Z3_ast?] = formulae
        return Z3_mk_or(context, UInt32(args.count), args)
    }

    func formula(_ lhs: Z3_ast, implies rhs: Z3_ast) -> Z3_ast {
        Z3_mk_implies(context, lhs, rhs)
    }

    func formula(_ lhs: Z3_ast, iff rhs: Z3_ast) -> Z3_ast {
        Z3_mk_iff(context, lhs, rhs)
    }

}

public extension Z3.Context {

    func assert(formula: Z3_ast) {
        Z3_solver_assert(context, solver, formula)
    }

    func assert(clause literals: [Z3_ast]) {
        let formula = disjunct(formulae: literals)
        assert(formula: formula)
    }

    var isSatisfiable: Bool {
        Z3_solver_check(context, solver) == Z3_L_TRUE
    }

    func createModel() -> Model? {
        Model(context: self)
    }
}

public extension Z3.Context {
    func string(formula: Formula) -> String? {
        guard let c = Z3_ast_to_string(self.context, formula) else { return nil }
        /* The result buffer is statically allocated by Z3.
         It will be automatically deallocated when Z3_del_context is invoked.
         So, the buffer is invalidated in the next call to Z3_ast_to_string.
         https://z3prover.github.io/api/html/group__capi.html#ga3975f8427c68d0a938834afd78ccef4d
         */
        return String(validatingUTF8: c)
    }
}
