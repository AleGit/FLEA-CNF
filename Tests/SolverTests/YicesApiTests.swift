import CYices
import XCTest
import Base

class YicesApiTests: YicesTestCase {

    func testDeMorgan() {
        let ctx = yices_new_context(nil)
        defer { yices_free_context(ctx) }

        let bool_sort = yices_bool_type()

        let x = yices_new_uninterpreted_term(bool_sort)
        let y = yices_new_uninterpreted_term(bool_sort)
        yices_set_term_name(x, "x")
        yices_set_term_name(y, "y")

        /* De Morgan - with a negation around */
        /* !(!(x && y) <-> (!x || !y)) */
        let not_x = yices_not(x)
        let not_y = yices_not(y)

        let x_and_y = yices_and2(x,y)
        let ls = yices_not(x_and_y)
        let rs = yices_or2(not_x, not_y)
        let de_morgan = yices_iff(ls, rs)
        let negated_de_morgan = yices_not(de_morgan)

        let result = yices_check_formula(negated_de_morgan, nil, nil, nil)
        XCTAssertEqual(result, STATUS_UNSAT, "Negated De Morgan must not be satisfiable.")

        yices_assert_formula(ctx, negated_de_morgan)
        XCTAssertEqual(yices_check_context(ctx, nil), STATUS_UNSAT, "Negated De Morgan must not be satisfiable.")

        let model = yices_get_model(ctx, 1)
        XCTAssertNil(model)
    }

    func testPfa() {
        let ctx = yices_new_context(nil)
        defer {
            yices_free_context(ctx)
        }

        let bool_tau: type_t = yices_bool_type()
        let free_tau: type_t = yices_new_uninterpreted_type()
        yices_set_type_name(free_tau, "τ")

        let a: term_t = yices_new_uninterpreted_term(free_tau)
        yices_set_term_name(a, "a")

        let f_sort: type_t = yices_function_type(1, [free_tau], free_tau) // unary function symbol
        let f = yices_new_uninterpreted_term(f_sort)
        yices_set_type_name(f, "f")
        let fa: term_t = yices_application(f, 1, [a])

        let p_sort: type_t = yices_function_type(1, [free_tau], bool_tau) // unary predicate symbol
        let p: term_t = yices_new_uninterpreted_term(p_sort)
        yices_set_term_name(p, "p")
        let pfa: term_t = yices_application(p, 1, [fa])

        let not = yices_not(pfa)
        let top = yices_or2(pfa, not)

        yices_assert_formula(ctx, top)
        XCTAssertEqual(STATUS_SAT, yices_check_context(ctx, nil))

        var model = yices_get_model(ctx, 1) // 1st model
        XCTAssertNotNil(model)

        XCTAssertEqual(yices_formula_true_in_model(model, top), 1)
        XCTAssertTrue( yices_formula_true_in_model(model, pfa) != yices_formula_true_in_model(model, not))
        XCTAssertEqual( yices_formula_true_in_model(model, pfa), 0)
        XCTAssertEqual( yices_formula_true_in_model(model, not), 1)

        yices_free_model( model) // 1st model ends

        yices_assert_formula(ctx, pfa)
        XCTAssertEqual(STATUS_SAT, yices_check_context(ctx, nil))

        model = yices_get_model(ctx, 1) // 2nd model
        XCTAssertNotNil(model)

        XCTAssertEqual(yices_formula_true_in_model(model, top), 1)
        XCTAssertEqual( yices_formula_true_in_model(model, pfa), 1)
        XCTAssertEqual( yices_formula_true_in_model(model, not), 0)

        yices_free_model( model) // 2nd model ends

        yices_assert_formula(ctx, not)
        XCTAssertEqual(STATUS_UNSAT, yices_check_context(ctx, nil))

        model = yices_get_model(ctx, 1)
        XCTAssertNil(model) // no model
    }
}
