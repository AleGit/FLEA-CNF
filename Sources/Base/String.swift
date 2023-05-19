import Foundation

//struct Peel : Hashable {
//    let lhs: Character
//    let rhs: Character
//
//    init(_ lhs: Character, _ rhs: Character) {
//        self.lhs = lhs
//        self.rhs = rhs
//    }
//
//    static let defaultPeels : [Peel] = ["\"", "'", "|", "()", "{}", "[]", "<>"]
//}

typealias Peel = (Character, Character)

fileprivate let defaultPeels : [Peel] = [("\"", "\""), ("'","'"), ("|","|"), ("(",")"), ("{","}"), ("[","]"), ("<",">")]

extension String {
    var trimmingWhitespace: String {
        self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }

    func trimmed(by: (UInt, UInt)) -> String? {
        guard by.0 + by.1 > 0 else { return self }

        guard self.count >= by.0 + by.1 else { return nil }

        let start = self.index(self.startIndex, offsetBy: Int(by.0))
        let end = self.index(self.endIndex, offsetBy: -Int(by.1))
        guard start <= end else { return nil }

        let slice = self[start..<end]
        return String(slice)
    }

    func trimmed(by: UInt) -> String? {
        trimmed(by: (by, by))
    }

    subscript(_ i: Int) -> Character {
        let index = self.index(self.startIndex, offsetBy: i)
        return self[index]
    }
    subscript(_ r: Range<Int>) -> Substring {
        let start = self.index(self.startIndex, offsetBy: r.lowerBound)
        let end = self.index(self.startIndex, offsetBy: r.upperBound)
        return self[start..<end]
    }

    subscript(_ r: ClosedRange<Int>) -> Substring {
        self[r.lowerBound..<(r.upperBound+1)]
    }

    /// Returns a string where matching first and last character are removed,
    /// e.g. "debug" -> debug, <x> -> x
    func peeled(peels: [Peel] = defaultPeels) -> String {
        guard let lhs = self.first,
              let rhs = self.last,
              peels.contains(where: { $0.0 == lhs && $0.1 == rhs }) else {
            return self
        }

        let start = self.index(after: self.startIndex)
        let end = self.index(before: self.endIndex)
        let slice = self[start..<end]
        return String(slice).peeled(peels: peels)
    }

    /// Is at least one element of a sequence of strings
    /// a substring of this string?
    func containsOne<S: Sequence>(_ strings: S) -> Bool
            where S.Element == String {
        strings.reduce(false) {
            $0 || self.contains($1)
        }
    }

    /// Are all elements of a sequence of strings
    /// substrings of this string?
    func containsAll<S: Sequence>(_ strings: S) -> Bool
            where S.Element == String {
        strings.reduce(true) {
            $0 && self.contains($1)
        }
    }
}

public extension String {
    ///
    ///
    /// - Parameters:
    ///   - nr: integer (negative, zero, positive)
    ///   - separator: line separator character, default = '\n'
    ///   - omittingEmptySubsequences: ignore empty lines, default = false
    /// - Returns:
    ///     - case nr = 0 return complete self as substring
    ///     - case nr > 0 return nth line from top
    ///     - case nr < 0 return -nth line form bottom
    func line(nr: Int, separator: Character = "\n", omittingEmptySubsequences: Bool = false) -> Substring {
        switch nr {
        case 1 ... Int.max:
            let lines = self.split(separator: separator, maxSplits: nr, omittingEmptySubsequences: omittingEmptySubsequences) // at most n+1 lines
            let index = min(nr, lines.count) - 1 // nr in { 1, 2, 3, ...}
            return lines[index]  // 0 <= index < lines.count

        case Int.min ... (-1):
            let lines = self.split(separator: separator, omittingEmptySubsequences: omittingEmptySubsequences) // all lines
            let index = max(0, lines.count + nr) // nr in { -1, -2, -3, ...}
            return lines[index] // 0 <= index < lines.count

        default: // nr == 0
            return Substring(self)
        }
    }
}

public extension Int {
    var numerus: String {
        switch self {
        case 0:
            return "no"
        case 1:
            return "one"
        case 2:
            return "two"
        default:
            return "\(self)"
        }
    }

    func numerus(_ singular: String) -> String {
        switch (self, singular) {
        case (-1,_), (1,_):
            return singular
        case(_, let string):
            return string + "s" // simple english
        }
    }
}
