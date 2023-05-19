import XCTest
import Tptp
@testable import Solver

class SoSolverTest: ATestCase {
    func _testRunPUZ001_1() {
        Tptp.Term.reset()
        guard var solver = SoSolver<Yices.Context>(problem: "PUZ001-1", options: .fileUrl, timeLimit: 300.0) else {
            XCTFail()
            return
        }
        print(solver)

        XCTAssertEqual(12, solver.queue.count)
        let result = solver.run()

        switch (result, solver.headerStatus) {
        case (.satisfiable, .satisfiable), (.unsatisfiable, .unsatisfiable):
            print("\(result) - success")
        case (.timeout, _):
            XCTFail("\(result) - time out")
        case (.indeterminate, _):
            XCTFail("\(result) - error")
        default:
            XCTFail("\(result) - wrong answer \(solver.headerStatus)")
        }
        Tptp.Term.reset()
    }

    func _testInitHWV() {
        Tptp.Term.reset()
        guard let solver = SoSolver<Yices.Context>(problem: "HWV001-1", options: .fileUrl, timeLimit: 300.0) else {
            XCTFail()
            return
        }
        print(solver)

        XCTAssertEqual(76, solver.queue.count)
        print(solver.queue[0...5])
        print(solver.queue[35...40])

        print(solver.queue[41...46])

        let reflexivity = Set(["X1 = X1"])
        let symmetry = Set(["X1 = X2", "X2 != X1"])
        let transitivity = Set(["X1 != X2", "X2 != X3", "X1 = X3"])
        let congruence = Set(["X1 != Y1", "X2 != Y2", "X1 != X2", "Y1 = Y2"])


        XCTAssertEqual(reflexivity, Set(solver.queue[47].map { $0.description }), "Reflexivity")
        XCTAssertEqual(symmetry, Set(solver.queue[48].map { $0.description }), "Symmetry")
        XCTAssertEqual(transitivity, Set(solver.queue[49].map { $0.description }), "Transitivity")
        XCTAssertEqual(congruence, Set(solver.queue[50].map { $0.description }), "Confluence")

        print(solver.queue[41...56])
        print(solver.queue[70...75])


        Tptp.Term.reset()
    }


}