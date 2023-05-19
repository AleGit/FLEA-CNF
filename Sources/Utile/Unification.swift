import Base

/// Construct unifier of left-hand side and right-hand side.
infix operator =?= : AdditionPrecedence

/// 'lhs =?= rhs' constructs most common unifier mgu(lhs,rhs)
/// iff terms lhs and rhs are unifiable.
/// Otherwise it returns *nil*.
public func =?= <N: Term, S: Substitution>(lhs: N, rhs: N) -> S?
    where S.K == N, S.V == N, S.Iterator == DictionaryIterator<N, N> {
    // delete
    if lhs == rhs {
        return lhs.isVariable ? S(dictionary: [lhs :rhs]) : S()
    }

    // variable elimination

    if lhs.isVariable {
        if rhs.variables.contains(lhs) { return nil } // occur check
        return S(dictionary: [lhs: rhs])
    }
    if rhs.isVariable {
        if lhs.variables.contains(rhs) { return nil } // occur check
        return S(dictionary: [rhs: lhs])
    }

    // both lhs and rhs are not variables

    guard lhs.key == rhs.key else {
        // f(...) =?= g(...) -> nil
        return nil
    }

    // decompositon

    guard var lnodes = lhs.nodes, var rnodes = rhs.nodes, lnodes.count == rnodes.count
    else {
        // f(.) =?= f(.,.) -> nil
        return nil
    }

    // signatures match, e.g. f(.,.,.) =?= f(.,.,.)

    var mgu = S()

    while lnodes.count > 0 {
        guard let unifier: S = (lnodes[0] =?= rnodes[0]) else { return nil }

        lnodes.removeFirst()
        rnodes.removeFirst()

        lnodes = lnodes.map { $0 * unifier }
        rnodes = rnodes.map { $0 * unifier }

        guard let concat = mgu * unifier else { return nil }

        mgu = concat
    }
    return mgu
}
