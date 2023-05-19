/**
 A position is a finite sequence of non-negative integers.
 The *root* position is the empty sequence and denoted by `ε`
 and `p+q` denotes the concatenation of positions `p` and `q`.
 We define binary relations <= , <, and || on positions as follows.
 We say that position `p` is above position `q
 if there exists a (necessarily unique) position `r` such that `p+r = q`.
 In that case we define `q\p` as the position r.
 If `p` is above q we also say that `q` is below p or p is a *prefix* of `q`, and we write `p` <= `q`.
 We write `p < q` if `p <= q` and `p != q`. If `p < q` we say that `p` is a proper prefix of `q`.
 Positions `p`, q are parallel, denoted by `p || q`, if neither `p <= q` nor `q <= p`.
 **/

public typealias Position = [Int]

let ε = Position()

func <=(lhs: Position, rhs: Position) -> Bool {
    guard lhs.count <= rhs.count else { return false }
    return lhs.prefix(lhs.count) == rhs.prefix(lhs.count)
}

func <(lhs: Position, rhs: Position) -> Bool {
    guard lhs.count < rhs.count else { return false }
    return lhs.prefix(lhs.count) == rhs.prefix(lhs.count)
}

func ||(lhs: Position, rhs: Position) -> Bool {
    return !(lhs <= rhs || rhs <= lhs)
}

public func +(lhs: Position, rhs: Position) -> Position {
    var result = lhs
    result.append(contentsOf: rhs)
    return result
}

func -(lhs:Position, rhs: Position) -> Position? {
    guard rhs <= lhs else { return nil }

    return Array(lhs.dropFirst(rhs.count))
}

extension Array where Element == Int {
    var prettyDescription : String {
        guard self.count > 0 else {
            return "ε"
        }
        return self.map { String($0) }.joined(separator: ".")
    }
}




extension Term {

    /// Get all positions of a term, i.e. all positionPaths from root to nodes.
    /// **`P(f(x),f(g(x,y))`** yields the positions:
    ///
    ///     []      P(f(x),f(g(x,y))
    ///     [0]     f(x)
    ///     [0,1]   x
    ///     [1]     f(g(x,y))
    ///     [1,0]   g(x,y)
    ///     [1,0,0] x
    ///     [1,0,1] y
    ///
    /// see [AM2015TRS,*Definition 2.1.16*]
    var positions: [Position] {
        var positions = [ε] // the root position always exists

        guard let nodes = self.nodes else { return positions }

        let list = nodes.map { $0.positions }

        for (hop, tails) in list.enumerated() {
            positions += tails.map { [hop] + $0 }
        }
        return positions
    }
}

extension Term {
    /// Get subterm at position.
    /// With [] the term itself is returned.
    /// With [i] the the subterm with array index i is returned.
    subscript(position: Position) -> Self? {
        // a) position == []
        guard let (head, tail) = position.decomposing else { return self }
        // b) position != [], but variables has no subnodes at all
        guard let nodes = self.nodes else { return nil }
        // c) node does not have a subnode at given position
        guard 0 <= head && head < nodes.count else { return nil }
        // d) node is not a constant or variable and has a subnode at given position
        return nodes[head][Array(tail)]
    }

    /// Construct a new term by replacing the subterm at position.
    subscript(term: Self, position: Position) -> Self? {
        // a) position == []
        guard let (head, tail) = position.decomposing else { return term }

        // b) position != [], but variables has no subnodes at all
        guard var nodes = self.nodes else { return nil }

        // c) node does not have a subnode at given position
        guard 0 <= head && head < nodes.count else { return nil }

        // d) node is not a constant or variable and has a subnode at given position
        guard let subnode = nodes[head][term, Array(tail)] else { return nil }

        nodes[head] = subnode
        return Self.term(type, symbol, nodes: nodes)
    }
}

// MARK: - Array<Node> + Position

extension Array where Element: Term {

    /// Get term at position in array. (for convenience)
    /// array[[i]] := array[i]
    /// array[[i,j,...]] := array[i][j,...]
    subscript(position: Position) -> Element? {
        // a) position == [], but an array is not of type Node
        guard let (head, tail) = position.decomposing else { return nil }
        // b) node does not have a subnode at given position
        guard 0 <= head && head < count else { return nil }
        // c)
        return self[head][Position(tail)]
    }
}
