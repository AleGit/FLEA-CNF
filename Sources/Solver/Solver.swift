import Tptp
import Base
import Foundation

public protocol Solver : CustomStringConvertible {
    associatedtype Context : SolverContext

    var identifier: String { get }
    var headers: [(Tptp.File.Header.Key, String)] { get }
    var initStartDate: Date { get }
    var initFinishDate: Date { get }
    var startDate: Date? { get }
    var finishDate: Date? { get }
    var roles: [Tptp.Role : Int] { get }

    init?(problem: String, options: Tptp.File.UrlOptions, timeLimit: TimeInterval)
    mutating func run() -> SolverResult
}

public extension Solver {
    var headerStatus: Tptp.File.Header.Status {
        Tptp.File.Header.Status(rawValue: headers[.Status].first ?? "") ?? .undefined
    }

    var headerRating: Double {
        if let substring = headers[Tptp.File.Header.Key.Rating].first?
                .split(separator: ",").first?   // e.g. "0.1 v8.0.0, ..., 0.2 v7.0.0" -> "0.1 v8.0.0"
                .split(separator: " ").first,   // e.g. "0.1 v8.0.0" -> 0.1
           let number = Double(substring) {
            return number
        }

        return Double.nan
    }
}

public enum SolverResult {
    case satisfiable
    case unsatisfiable
    case timeout
    case indeterminate

}

extension [(Tptp.File.Header.Key, String)] { //  : Dictionary<Header.Key, [String]>

    subscript(_ k: Tptp.File.Header.Key) -> [String] {
        self.compactMap {
            (key, value) -> String? in
            return key == k ? value : nil
        }
    }
}

public extension Solver {
    var description: String {
        let initial = self.initFinishDate.timeIntervalSince(self.initStartDate).pretty
        let totalClauses = roles.reduce(0) { (result,role) -> Int in result + role.1 }
        let rolesInfo = roles.map { (key,value) -> String in "\(value) x \(key.rawValue)" }.joined(separator: ", ")
        return """
               Flea 1.0ß read \(totalClauses) clauses (\(rolesInfo)) 
               from '\(identifier)' 
               in \(initial).

               """
    }
}