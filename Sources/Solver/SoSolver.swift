import Foundation
import Base
import Tptp
import Utile

public struct SoSolver<Context: SolverContext>: Solver
        where Context.Symbol == String {
    var context = Context()
    public let identifier: String
    public let headers: [(Tptp.File.Header.Key, String)]
    public let roles: [Tptp.Role : Int]
    var queue: Tptp.Clauses

    public let initStartDate = Date.now
    public let initFinishDate: Date
    private (set) public var startDate: Date? = nil
    private (set) public var finishDate: Date? = nil

    private let parseFileDuration: TimeInterval
    private let readHeadersDuration: TimeInterval
    private let readRolesDuration: TimeInterval
    private let readClausesDuration: TimeInterval

    var assertedLiterals = [Tptp.Clause: Context.Literals]()

    let timeLimit: TimeInterval

    private var runtime: TimeInterval {
        return (finishDate ?? .now).timeIntervalSince(initStartDate)
    }

    private var isTimeLeft: Bool {
        runtime < timeLimit
    }

    public init?(problem name: String, options: Tptp.File.UrlOptions, timeLimit: TimeInterval) {
        let (f, t) = Time.runtime {
            Tptp.File(problem: name, options: options)
        }
        guard let file = f else {
            return nil
        }
        self.parseFileDuration = t

        self.timeLimit = timeLimit
        self.identifier = file.identifier ?? "n/a"

        (self.headers, self.readHeadersDuration) = Time.runtime { file.headers  }
        (self.roles, self.readRolesDuration) = Time.runtime { file.roles }
        (self.queue, self.readClausesDuration) = Time.runtime { file.clauses }

        self.initFinishDate = .now
    }

    mutating private func enqueue(clause: Tptp.Clause) {
        self.queue.append(clause)
    }

    var counter = 0

    mutating private func dequeue() -> (Int, Tptp.Clause)? {
        guard self.queue.count > 0 else {
            return nil
        }
        defer {
            counter += 1
        }
        return (counter, self.queue.removeFirst())
    }

    mutating private func isPrepared() -> Bool {
        guard self.assertedLiterals.isEmpty else {
            return true
        }

        for clause in self.queue {
            self.assertedLiterals[clause] = context.encode_assert(clause: clause)
        }
        return true
    }

    mutating public func run() -> SolverResult {
        guard isPrepared() else { return .indeterminate } // bad

        guard context.isSatisfiable else { return .unsatisfiable } // good

        while let (index, clause) = self.dequeue() {
            guard isTimeLeft else {
                return .timeout // bad
            }

            let smtLiterals = self.assertedLiterals[clause] ?? context.encode_assert(clause: clause)

            guard let model = context.createModel() else { return .unsatisfiable } // good

            let zipped = zip(clause, smtLiterals)
            guard let selectedLiteral = model.selectLiteral(from: zipped) else {
                assert(false, "\(index) \(clause): No literal was selected")
                return .indeterminate // bad
            }

            let distinctLiteral = selectedLiteral.distinct

            guard let negatedLiteral = distinctLiteral.negated else {
                assert(false, "\(index) \(clause): Selected literal \(selectedLiteral) could no be negated")
                return .indeterminate // bad
            }

            assert(negatedLiteral.negated!.indistinct == selectedLiteral)

            for (otherClause, otherSmtLiterals) in self.assertedLiterals {
                let zipped = zip(otherClause, otherSmtLiterals)
                guard let otherSelectedLiteral = model.selectLiteral(from: zipped) else {
                    assert(false, "  \(otherClause): No literal was selected")
                    return .indeterminate // bad
                }

                guard let unifier: [Tptp.Term: Tptp.Term] = negatedLiteral =?= otherSelectedLiteral else {
                    Syslog.debug { "\t\(selectedLiteral) and \(otherSelectedLiteral) do not clash" }
                    continue
                }

                Syslog.debug { "\t\(selectedLiteral.distinct) ⚡️ \(otherSelectedLiteral) ➡️ \(unifier)"}

                for freshClause in [
                    clause.distinct.map { ($0 * unifier).indistinct },
                    otherClause.map { ($0 * unifier).indistinct }
                ] {

                    if self.assertedLiterals[freshClause] == nil {
                        Syslog.info { "➕\t\(freshClause)"}
                        self.assertedLiterals[freshClause] = context.encode_assert(clause: freshClause)
                        self.enqueue(clause: freshClause)
                    }
                }
            }
            self.assertedLiterals[clause] = smtLiterals
        }

        return context.isSatisfiable ? .satisfiable : .unsatisfiable

    }
}
