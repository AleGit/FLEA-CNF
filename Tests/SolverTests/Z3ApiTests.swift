import CZ3Api
import XCTest
import Base

/// https://github.com/Z3Prover/z3/blob/master/examples/c/test_capi.c
class Z3ApiTests: ATestCase {

    func testDeMorgan() {
        let cfg = Z3_mk_config()
        defer {
            Z3_del_config(cfg)
        }

        let ctx = Z3_mk_context(cfg)
        defer {
            Z3_del_context(ctx)
        }

        let bool_sort = Z3_mk_bool_sort(ctx)
        let symbol_x = Z3_mk_int_symbol(ctx, 0)
        let symbol_y = Z3_mk_int_symbol(ctx, 1)
        let x = Z3_mk_const(ctx, symbol_x, bool_sort)
        let y = Z3_mk_const(ctx, symbol_y, bool_sort)

        /* De Morgan - with a negation around */
        /* !(!(x && y) <-> (!x || !y)) */
        let not_x = Z3_mk_not(ctx, x)
        let not_y = Z3_mk_not(ctx, y)

        let x_and_y = Z3_mk_and(ctx, 2, [x, y]);
        let ls = Z3_mk_not(ctx, x_and_y);
        let rs = Z3_mk_or(ctx, 2, [not_x, not_y]);
        let de_morgan = Z3_mk_iff(ctx, ls, rs);
        let negated_de_morgan = Z3_mk_not(ctx, de_morgan);

        let s = Z3_mk_solver(ctx)
        Z3_solver_inc_ref(ctx, s)
        defer {
            Z3_solver_dec_ref(ctx, s)
        }

        Z3_solver_assert(ctx, s, negated_de_morgan)
        let result = Z3_solver_check(ctx, s)

        XCTAssertEqual(result, Z3_L_FALSE, "De Morgan is not valid.")
    }

    func testPfa() {
        let cfg = Z3_mk_config()
        defer {
            Z3_del_config(cfg)
        }
        let ctx = Z3_mk_context(cfg)
        defer {
            Z3_del_context(ctx)
        }

        let true_val = Z3_mk_true(ctx)
        let false_val = Z3_mk_false(ctx)

        let tau_symbol = Z3_mk_string_symbol(ctx, "𝛕")
        let a_symbol = Z3_mk_string_symbol(ctx, "a")
        let f_symbol = Z3_mk_string_symbol(ctx, "f")
        let p_symbol = Z3_mk_string_symbol(ctx, "p")

        let bool_tau = Z3_mk_bool_sort(ctx)
        let free_tau = Z3_mk_uninterpreted_sort(ctx, tau_symbol)

        // let a = Z3_mk_func_decl(ctx, a_symbol, 0, nil, free_tau)
        let f = Z3_mk_func_decl(ctx, f_symbol, 1, [free_tau], free_tau)
        let p = Z3_mk_func_decl(ctx, p_symbol, 1, [free_tau], bool_tau)

        let a = Z3_mk_const(ctx, a_symbol, free_tau)
        let fa = Z3_mk_app(ctx, f, 1, [a])
        let pfa = Z3_mk_app(ctx, p, 1, [fa])

        let not = Z3_mk_not(ctx, pfa)
        let top = Z3_mk_or(ctx, 2, [pfa, not])
        let bot = Z3_mk_and(ctx, 2, [pfa, not])

        let solver = Z3_mk_solver(ctx)
        XCTAssertNotNil(solver)
        Z3_solver_inc_ref(ctx, solver)
        defer { Z3_solver_dec_ref(ctx, solver) }

        Z3_solver_assert(ctx, solver, top)
        XCTAssertEqual(Z3_solver_check(ctx, solver), Z3_L_TRUE)

        Z3_solver_assert(ctx, solver, pfa)
        XCTAssertEqual(Z3_solver_check(ctx, solver), Z3_L_TRUE)

        let model = Z3_solver_get_model(ctx, solver)
        XCTAssertNotNil(model)
        Z3_model_inc_ref(ctx, model)
        defer { Z3_model_dec_ref(ctx, model) }

        XCTAssertEqual(Z3_model_get_num_consts(ctx, model), 1)
        XCTAssertEqual(Z3_model_get_num_funcs(ctx, model), 2)
        XCTAssertEqual(Z3_model_get_num_sorts(ctx, model), 1)

        if let s = Z3_model_to_string(ctx, model) {
            let string = String(cString: s)
            print(string)
        }
        else {
            print("model to string failed")
        }

        for (f, expected) in [
            pfa: true_val, not : false_val,
            top: true_val, bot: false_val,
            true_val: true_val, false_val: false_val
        ] {
            var val: Z3_ast? = nil
            XCTAssertTrue(Z3_model_eval(ctx, model, f, false, &val))
            XCTAssertEqual(expected, val)

        }

        var pfa_val: Z3_ast? = nil
        var not_val: Z3_ast? = nil
        var top_val: Z3_ast? = nil

        XCTAssertTrue(Z3_model_eval(ctx, model, pfa, false, &pfa_val))
        XCTAssertTrue(Z3_model_eval(ctx, model, not, false, &not_val))
        XCTAssertTrue(Z3_model_eval(ctx, model, top, false, &top_val))

        Z3_solver_assert(ctx, solver, not)
        XCTAssertEqual(Z3_solver_check(ctx, solver), Z3_L_FALSE)


    }

    func testMore() {
        let cfg = Z3_mk_config()
        defer { Z3_del_config(cfg) }
        let ctx = Z3_mk_context(cfg)
        defer { Z3_del_context(ctx) }

        let 𝛕_symbol = Z3_mk_string_symbol(ctx, "𝛕")
        let a_symbol = Z3_mk_string_symbol(ctx, "a")
        let b_symbol = Z3_mk_string_symbol(ctx, "b")
        let f_symbol = Z3_mk_string_symbol(ctx, "f")
        let p_symbol = Z3_mk_string_symbol(ctx, "p")
        let q_symbol = Z3_mk_string_symbol(ctx, "q")

        let bool_𝛕 = Z3_mk_bool_sort(ctx)
        let free_𝛕 = Z3_mk_uninterpreted_sort(ctx, 𝛕_symbol)

        let f = Z3_mk_func_decl(ctx, f_symbol, 2, [free_𝛕, free_𝛕], free_𝛕)
        let p = Z3_mk_func_decl(ctx, p_symbol, 1, [free_𝛕], bool_𝛕)
        let q = Z3_mk_func_decl(ctx, q_symbol, 1, [free_𝛕], bool_𝛕)

        let a = Z3_mk_const(ctx, a_symbol, free_𝛕)
        let b = Z3_mk_const(ctx, b_symbol, free_𝛕)
        let fa = Z3_mk_app(ctx, f, 2, [a, a])
        let fb = Z3_mk_app(ctx, f, 2, [b, b])
        let pfa = Z3_mk_app(ctx, p, 1, [fa])
        let pfb = Z3_mk_app(ctx, p, 1, [fb])
        let qa = Z3_mk_app(ctx, q, 1, [a])
        let qfa = Z3_mk_app(ctx, q, 1, [fa])

        let npfa = Z3_mk_not(ctx, pfa)
        let npfb = Z3_mk_not(ctx, pfb)

        let top = Z3_mk_or(ctx, 2, [pfa, npfa])
        let bot = Z3_mk_and(ctx, 2, [pfa, npfa])

        let solver = Z3_mk_solver(ctx)
        XCTAssertNotNil(solver)
        Z3_solver_inc_ref(ctx, solver)
        defer { Z3_solver_dec_ref(ctx, solver) }

        Z3_solver_assert(ctx, solver, pfa)
        XCTAssertEqual(Z3_solver_check(ctx, solver), Z3_L_TRUE)

        Z3_solver_assert(ctx, solver, npfb)
        XCTAssertEqual(Z3_solver_check(ctx, solver), Z3_L_TRUE)

        let model = Z3_solver_get_model(ctx, solver)
        XCTAssertNotNil(model)
        Z3_model_inc_ref(ctx, model)
        defer { Z3_model_dec_ref(ctx, model) }

        print(Z3_model_get_num_consts(ctx, model))
        print(Z3_model_get_num_funcs(ctx, model))
        print(Z3_model_get_num_sorts(ctx, model))

        if let s = Z3_model_to_string(ctx, model) {
            let string = String(cString: s)
            print(string)
        }

        let true_val = Z3_mk_true(ctx)
        let false_val = Z3_mk_false(ctx)

        var val: Z3_ast?
        for (f,expected) in [
            pfa : ("true", true_val),
            npfa : ("false", false_val),
            top : ("true", true_val),
            bot : ("false", false_val),
            npfb : ("true", true_val),
            pfb : ("false", false_val)
        ] {
            val = nil
            XCTAssertTrue(Z3_model_eval(ctx, model, f, false, &val))
            XCTAssertEqual(expected.1, val)
            if let s = Z3_ast_to_string(ctx, val) {
                XCTAssertEqual(expected.0, String(cString: s))
            }
            else {
                XCTFail(expected.0)
            }
        }

        for f in [ qa, qfa ] {
            val = nil
            XCTAssertTrue(Z3_model_eval(ctx, model, f, false, &val))
            XCTAssertNotEqual(true_val, val, "true")
            XCTAssertNotEqual(false_val, val, "false")
        }

        Z3_solver_assert(ctx, solver, npfa)
        XCTAssertEqual(Z3_solver_check(ctx, solver), Z3_L_FALSE)


    }
}
