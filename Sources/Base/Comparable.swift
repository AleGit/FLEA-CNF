/// - Parameters:
///   - lo: the lower bound for level
///   - hi: the upper bound for level
///   - level: the level to be bound
/// - Returns: 'nil' iff (lo > hi)
/// 'lo' iff (hi ≥ lo > level)
/// 'hi' iff (level > hi ≥ lo)
/// 'level' iff (hi ≥ level ≥ lo)
func embank<T>(lo: T, hi: T, _ level: T) -> T? where T:Comparable {
    guard lo <= hi else {
        Syslog.error { """
                       lo=\(lo) > hi=\(hi) -> undefined result
                       min(max(lo,\(level)),hi) = \(min(max(lo, level), hi)))
                       ≠
                       max(lo, min(\(level), hi)) = \(max(lo, min(level, hi)))
                       """ }
        // ∀(lo,level,hi) lo > hi -> min(max(lo, level), hi) ≠ max(lo, min(level, hi))
        // case 1: lo <= hi
        //   lo > hi -> lhs != rhs ≡ F -> lhs != rhs ≡ T

        // case 2: lo > hi
        // case 2.1: level >= lo > hi
        //   min(max(lo, level), hi) = min(level,hi) = hi
        //   max(lo,min(level,hi)) = max(lo,hi) = lo
        //   lo > hi -> lo ≠ hi ≡ T -> T ≡ T

        // case 2.2: lo >= level >= hi
        //   min(max(lo,level),hi) = min(lo,hi) = hi
        //   max(lo,min(level,hi)) = max(lo,level) = lo
        //   lo > hi -> lo ≠ hi ≡ T -> T ≡ T

        // case 2.3: lo > hi >= level
        //   min(max(lo,level),hi) = min(lo,hi) = hi
        //   max(lo,min(level,hi)) = max(lo,hi) = lo
        //   lo > hi -> lo ≠ hi ≡ T -> T ≡ T
        return nil
    }
    return min(max(lo, level), hi) 

    // ∀(lo,ln,hi) lo <= hi -> min(max(lo, ln), hi) = max(lo, min(ln, hi))
    //               | l1 | lo | l2 | hi | l3
    // an=max(lo,ln) |    | a1 | a2 |    | a3
    // bn=min(an,hi) |    | b1 | b2 | b2 |
    //               | l1 | lo | l2 | hi | l3
    // cn=min(ln,hi) | c1 |    | c2 | c3 |
    // dn=max(lo,cn) |    | d1 | d2 | d3 |
    // a1 = d1, a2 = d2, a3 = d3

    // ∀(lo,ln,hi) lo > hi -> min(max(lo, ln), hi) ≠ max(lo, min(ln, hi))
    //               | l1 | hi | l2 | lo | l3
    // an=max(lo,ln) |    |    |    |a12 | a3
    // bn=min(an,hi) |    |b123|    |    |
    //               | l1 | hi | l2 | lo | l3
    // cn=min(ln,hi) | c1 |c23 |    |    |
    // dn=max(lo,cn) |    |    |    |d123|
    // b123 ≠ d123
}

