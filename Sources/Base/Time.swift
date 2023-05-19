import Foundation

/// A static wrapper for system time utilities to measure runtime of program routines.
public struct Time {
    static var tps = ticksPerSecond()

    private static func absoluteTime() -> Double {
        var atime = timeval() // initialize C struct
        _ = gettimeofday(&atime, nil) // will return 0
        return Double(atime.tv_sec) // s (seconds)
                + Double(atime.tv_usec) / Double(1_000_000.0) // µs (microseconds)
        // 1 µs (microsecond) = 1E-6 s
        // 1 ms (millisecond) = 1E-3 s
    }

    public typealias Triple = (user: Double, system: Double, absolute: Double)

    private static func ticksPerSecond() -> Double {
        Double(sysconf(Int32(_SC_CLK_TCK)))
    }

    private static func currentTriple() -> Triple {
        var ptime = tms()
        _ = times(&ptime)

        return (
                user: Double(ptime.tms_utime + ptime.tms_cutime) / tps,
                system: Double(ptime.tms_stime + ptime.tms_cstime) / tps,
                absolute: absoluteTime()
        )
    }

    /// Measure the absolute runtime of a code block.
    /// Usage: `let (result,runtime) = measure { *code to measure* }`
    public static func measure<R>(f: () -> R) -> (R, Time.Triple) {
        let start = currentTriple()
        let result = f()
        let end = currentTriple()
        return (result, end - start)
    }

    public static func runtime<R>(f: () -> R) -> (R, TimeInterval) {
        let start = absoluteTime()
        return (f(), absoluteTime() - start)

    }


}


private func -(lhs: Time.Triple, rhs: Time.Triple) -> Time.Triple {
    (
            user: lhs.user - rhs.user,
            system: lhs.system - rhs.system,
            absolute: lhs.absolute - rhs.absolute
    )
}
