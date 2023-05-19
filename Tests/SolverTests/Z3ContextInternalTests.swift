import XCTest
import Base
@testable import Solver

final class Z3ContextInternalTests: Z3TestCase {

    func testDeMorgan() {
        let context = Context()
        let x = context.declare(proposition: "p")
        let y = context.declare(proposition: "q")
        let not_x = context.negate(formula: x)
        let not_y = context.negate(formula: y)

        let x_and_y = context.formula(x, and: y)
        let ls = context.negate(formula: x_and_y)
        let rs = context.formula(not_x, or: not_y)
        let de_morgan = context.formula(ls, iff: rs)
        let negated = context.negate(formula: de_morgan)

        context.assert(formula: negated)

        XCTAssertFalse(context.isSatisfiable)
        XCTAssertNil(context.createModel())
    }

    func testPfa() {
        let context = Context()

        let a = context.declare(constant: "a")
        let f = context.declare(function: "f", arity: 1)
        let fa = context.apply(function: f, args: [a])
        let p = context.declare(predicate: "p", arity: 1)
        let pfa = context.apply(predicate: p, args: [fa])

        let not = context.negate(formula: pfa)
        let top = context.formula(pfa, or: not)

        context.assert(formula: top)
        XCTAssertTrue(context.isSatisfiable)
        var model = context.createModel()!

        XCTAssertTrue(model.satisfies(formula: top) == true)
        XCTAssertTrue(model.satisfies(formula: pfa) == nil)
        XCTAssertTrue(model.satisfies(formula: not) == nil)

        context.assert(formula: pfa)
        XCTAssertTrue(context.isSatisfiable)
        model = context.createModel()!
        XCTAssertNotNil(model)

        XCTAssertTrue(model.satisfies(formula: top) == true)
        XCTAssertTrue(model.satisfies(formula: pfa) == true)
        XCTAssertTrue(model.satisfies(formula: not) == false)

        context.assert(formula: not)
        XCTAssertFalse(context.isSatisfiable)
        XCTAssertNil(context.createModel())


    }

    func testConjunction() {
        let context = Context()
        let a = context.declare(proposition: "a")
        let b = context.declare(proposition: "b")
        let c = context.declare(proposition: "c")

        let na = context.negate(formula: a)
        let nb = context.negate(formula: b)
        let nc = context.negate(formula: c)

        context.assert(formula: context.conjunct(formulae: a,b,c))
        XCTAssertTrue(context.isSatisfiable)

        context.assert(formula: context.conjunct(formulae: na,nb,nc))
        XCTAssertFalse(context.isSatisfiable)
    }

    func testDisjunction() {
        let context = Context()
        let a = context.declare(proposition: "a")
        let b = context.declare(proposition: "b")
        let c = context.declare(proposition: "c")

        let na = context.negate(formula: a)
        let nb = context.negate(formula: b)
        let nc = context.negate(formula: c)

        context.assert(formula: context.disjunct(formulae: a,b,c))
        XCTAssertTrue(context.isSatisfiable)

        context.assert(formula:context.disjunct(formulae: na,nb,nc))
        XCTAssertTrue(context.isSatisfiable)

        context.assert(formula: context.disjunct(formulae: nb, c))
        XCTAssertTrue(context.isSatisfiable)

        context.assert(formula: context.disjunct(formulae: na, c))
        XCTAssertTrue(context.isSatisfiable)

        context.assert(formula: context.disjunct(formulae: b, nc))
        XCTAssertTrue(context.isSatisfiable)

        context.assert(formula: context.disjunct(formulae: a, nc))
        XCTAssertFalse(context.isSatisfiable)
    }

    func testMultipleDeclarations() {
        let context = Context()
        let f = context.declare(constant: "x")
        let f0 = context.declare(function: "x", arity: 0)
        let f1 = context.declare(function: "x", arity: 1)
        let f2 = context.declare(function: "x", arity: 2)

        let p = context.declare(proposition: "x")
        let p0 = context.declare(predicate: "x", arity: 0)
        let p1 = context.declare(predicate: "x", arity: 1)
        let p2 = context.declare(predicate: "x", arity: 2)


        let a = f
        let b = context.apply(function: f0, args: [Context.Term]())
        let c = context.apply(function: f1, args: [a])
        let d = context.apply(function: f2, args: [b, c])

        let pa = p
        let pb = context.apply(predicate: p0, args: [Context.Term]())
        let pc = context.apply(predicate: p1, args: [a])
        let pd = context.apply(predicate: p2, args: [b, c])
        let pe = context.apply(predicate: p2, args: [a, d])
        context.assert(formula: context.conjunct(formulae: pa, pb, pc, pd, pe))
        XCTAssertTrue(context.isSatisfiable)

    }

    func testContradiction() {
        let context = Context()
        let x = context.declare(proposition: "p")
        let y = context.declare(proposition: "p")
        XCTAssertEqual(x,y)

        let not_y = context.negate(formula: y)
        context.assert(formula: context.formula(x, and: not_y))

        XCTAssertFalse(context.isSatisfiable)
        XCTAssertNil(context.createModel())
    }

    func testIdentities() {
        let context = Context()
        let c = context.declare(function: "c", arity: 1)
        let d = context.declare(function: "c", arity: 1)
        XCTAssertEqual(c, d)
        let f = context.declare(function: "f", arity: 1)
        let g = context.declare(function: "f", arity: 1)
        XCTAssertEqual(f, g)
        let p = context.declare(function: "p", arity: 1)
        let q = context.declare(function: "p", arity: 1)
        XCTAssertEqual(p, q)
        let r = context.declare(proposition: "r")
        let s = context.declare(proposition: "r")
        XCTAssertEqual(r, s)
    }

    func testTransitivity() {
        let context = Context()
        let a = context.declare(constant: "a")
        let b = context.declare(constant: "b")
        let c = context.declare(constant: "c")

        let ab = context.equate(lhs: a, rhs: b)
        let bc = context.equate(lhs: b, rhs: c)

        context.assert(formula: ab)
        context.assert(formula: bc)
        XCTAssertTrue(context.isSatisfiable, "consistency failure")

        let conjecture = context.equate(lhs: c, rhs: a)
        let negated = context.negate(formula: conjecture)

        context.assert(formula: negated)
        XCTAssertFalse(context.isSatisfiable, "transitivity failure")
    }

    func testSymmetry() {
        let context = Context()
        let a = context.declare(constant: "a")
        let b = context.declare(constant: "b")

        let ab = context.equate(lhs: a, rhs: b)
        context.assert(formula: ab)
        XCTAssertTrue(context.isSatisfiable, "consistency failure")

        let conjecture = context.equate(lhs: b, rhs: a)
        let negated = context.negate(formula: conjecture)

        context.assert(formula: negated)
        XCTAssertFalse(context.isSatisfiable, "symmetry failure")

    }

    func testReflexivity() {
        let context = Context()
        let a = context.declare(constant: "a")

        let conjecture = context.equate(lhs: a, rhs: a)
        let negated = context.negate(formula: conjecture)

        context.assert(formula: negated)
        XCTAssertFalse(context.isSatisfiable, "reflexivity failure")

    }

    func testFunctionCongruence() {
        let context = Context()
        let a = context.declare(constant: "a")
        let b = context.declare(constant: "b")

        let f = context.declare(function: "f", arity: 1)
        let fa = context.apply(function: f, args: [a])
        let fb = context.apply(function: f, args: [b])
        let ab = context.equate(lhs: a, rhs: b)

        context.assert(formula: ab)
        XCTAssertTrue(context.isSatisfiable, "consistency failure")

        let conjecture = context.equate(lhs: fa, rhs: fb)
        let negated = context.negate(formula: conjecture)

        context.assert(formula: negated)
        XCTAssertFalse(context.isSatisfiable, "function congruence failure")
    }

    func testPredicateCongruence() {
        let context = Context()
        let a = context.declare(constant: "a")
        let b = context.declare(constant: "b")

        let f = context.declare(function: "f", arity: 1)
        let p = context.declare(predicate: "p", arity: 2)
        let fa = context.apply(function: f, args: [a])
        let fb = context.apply(function: f, args: [b])
        let ab = context.equate(lhs: a, rhs: b)

        let pa = context.apply(predicate: p, args: [fa, b])
        let pb = context.apply(predicate: p, args: [fb, a])

        context.assert(formula: ab)
        XCTAssertTrue(context.isSatisfiable, "consistency failure")

        let conjecture = context.formula(pa, iff: pb)
        let negated = context.negate(formula: conjecture)

        context.assert(formula: negated)
        XCTAssertFalse(context.isSatisfiable, "predicate congruence failure")
    }
}
