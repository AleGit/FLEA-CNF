import Base
import Solver
import Tptp

if Runtime.isActive {
    Syslog.openLog(options: .console, .pid, .perror, verbosely: Runtime.isVerbose)
    defer { Syslog.closeLog() }

    for problem in Runtime.problems {
        guard var solver = Runtime.createSolver(problem: problem) else {
            Syslog.error { "Problem '\(problem)' could not be found, read or parsed."}
            continue
        }
        print(solver.description)
        let result = solver.run()
        print(result)
    }
}












