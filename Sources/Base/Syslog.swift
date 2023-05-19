import Foundation

/// Static wrapper for [wiki/syslog](https://en.wikipedia.org/wiki/Syslog)
///
/// - [The Syslog Protocol. RFC 5424](https://tools.ietf.org/html/rfc5424)
/// - [Textual Conventions for Syslog Management. RFC 5427](https://tools.ietf.org/html/rfc5427)
public struct Syslog {
    static var carping = false
    static var failOnError = false // make this configurable

    public enum Priority: Comparable {
        case emergency // LOG_EMERG      system is unusable
        case alert // LOG_ALERT      action must be taken immediately
        case critical // LOG_CRIT       critical conditions
        case error // LOG_ERR        error conditions
        case warning // LOG_WARNING    warning conditions
        case notice // LOG_NOTICE     normal, but significant, condition
        case info // LOG_INFO       informational message
        case debug // LOG_DEBUG      debug-level message

        fileprivate var priority: Int32 {
            switch self {
            case .emergency: return LOG_EMERG
            case .alert: return LOG_ALERT
            case .critical: return LOG_CRIT
            case .error: return LOG_ERR
            case .warning: return LOG_WARNING
            case .notice: return LOG_NOTICE
            case .info: return LOG_INFO
            case .debug: return LOG_DEBUG
            }
        }

        /// Since `Syslog.Priority` is allready `Equatable`
        /// it is sufficient to implement < to adopt `Comparable`
        public static func < (_ lhs: Priority, rhs: Priority) -> Bool {
            lhs.priority < rhs.priority
        }

        fileprivate init?(string: String) {
            switch string {
            case "emergency": self = .emergency
            case "alert": self = .alert
            case "critical": self = .critical
            case "error": self = .error
            case "warning": self = .warning
            case "notice": self = .notice
            case "info": self = .info
            case "debug": self = .debug
            default: return nil
            }
        }

        fileprivate static var all = [
            Priority.emergency, Priority.alert, Priority.critical, Priority.error,
            Priority.warning, Priority.notice, Priority.info, Priority.debug,
        ]
    }

    public enum Option {
        case console
        case immediately
        case nowait
        case delayed
        case perror
        case pid
        // LOG_CONS       Write directly to system console if there is an error
        //                while sending to system logger.
        //
        // LOG_NDELAY     Open the connection immediately (normally, the
        //                connection is opened when the first message is
        //                logged).
        //
        // LOG_NOWAIT     Don't wait for child processes that may have been
        //                created while logging the message.  (The GNU C library
        //                does not create a child process, so this option has no
        //                effect on Linux.)
        //
        // LOG_ODELAY     The converse of LOG_NDELAY; opening of the connection
        //                is delayed until syslog() is called.  (This is the
        //                default, and need not be specified.)
        //
        // LOG_PERROR     (Not in POSIX.1-2001 or POSIX.1-2008.)  Print to
        //                stderr as well.
        //
        // LOG_PID        Include PID with each message.
        fileprivate var option: Int32 {
            switch self {
            case .console: return LOG_CONS
            case .immediately: return LOG_NDELAY
            case .nowait: return LOG_NOWAIT
            case .delayed: return LOG_ODELAY
            case .perror: return LOG_PERROR
            case .pid: return LOG_PID
            }
        }
    }

    ///
    private static var activePriorities = Syslog.maskedPriorities

    /// Syslog is active _after_ reading the configuration.
    private static var active = false

    public static var openVerbosely = true

    /// read in the logging configuration (from file)
    // TODO: provide a cleaner/better implementation
    static let configuration: [String: Priority]? = {
        /// after the configuration is read the logging is active
        defer { Syslog.active = true }

        // reminder: the logging is not active
        Syslog.prinfo(condition: Syslog.openVerbosely) {  "Reading Configuration started." }
        defer { Syslog.prinfo(condition: Syslog.openVerbosely) { "Reading configuration finished." } }

#if DEBUG
        print("🏁", "config file path:", URL.loggingConfigurationURL?.path ?? "N/A")
#endif

        // read configuration file line by line, but
        // ignore comments (#...) and empty lines (whitespace only)
        guard let entries = URL.loggingConfigurationURL?.path.lines(predicate: {
            !($0.hasPrefix("#") || $0.isEmpty)
        }), entries.count > 0 else {
            Syslog.prinfo(condition: Syslog.openVerbosely) { "Configuration file is missing or has no entries." }
            return nil
        }

        // create configuration
        var configuration = [String: Priority]()

        for entry in entries {
            let components = entry.components(separatedBy: "::")

            guard components.count == 2,
                let key = components.first?.trimmingWhitespace.peeled(),
                let last = components.last else {
                Syslog.prinfo { "invalid CONFIGURATION entry ! \(entry) \(components)" }
                continue
            }

            let lastIndex = last.firstIndex(of: "#") ?? last.endIndex
            let value = String(last.prefix(upTo: lastIndex)).trimmingWhitespace.peeled()
            guard let p = Priority(string: value) else {
                continue
            }
            configuration[key] = p

            Syslog.prinfo(condition: Syslog.openVerbosely) { "\(entry) => (\(key),\(p))" }
        }
        return configuration
    }()

    /// Everything less or equal MUST be logged.
    /// .error <= minimal log level
    public static var minimalLogLevel: Priority = {
        embank(
            lo: .error, // .emergency, .alert, .critical, .error must be logged.
            hi: .debug, // highest possible log level
            Syslog.configuration?["---"] ?? .error
        )! // fatal if .error > .debug
    }()

    /// Everything greater MUST NOT be logged.
    /// minimal log level <= maximal log level
    public static var maximalLogLevel: Priority = {
        embank(
            lo: Syslog.minimalLogLevel, // at least .error
            hi: .debug, // highest possible log level
            Syslog.configuration?["+++"] ?? .warning
        )! // fatal if minimalLogLevel > .debug
    }()

    /// Everything less or equal will be logged.
    /// minimal <= default <= maxiaml log level
    public static var defaultLogLevel: Priority = {
        embank(
            lo: Syslog.minimalLogLevel, // at least .error
            hi: Syslog.maximalLogLevel, // at most .debug
            Syslog.configuration?["***"] ?? .warning
        )! // fatal if minimalLogLevel > maximalLogLevel
    }()

    public static func logLevel(_ filePath: String = #file, _ function: String = #function) -> Priority {
        let fileName = URL(fileURLWithPath: filePath).lastPathComponent
        return embank(
            lo: Syslog.minimalLogLevel,
            hi: Syslog.maximalLogLevel,
            Syslog.configuration?[fileName + "/" + function]    // "Node.swift/foo()"
            ?? Syslog.configuration?[function]                   // "foo()"
            ?? Syslog.configuration?[fileName]                  // "Node.swift"   
            ?? Syslog.defaultLogLevel                           // "***"
        )!
    }

    private static func loggable(_ priority: Priority, _ file: String, _ function: String, _: Int) -> Bool {
        guard Syslog.active, priority <= Syslog.maximalLogLevel else { return false }

        return priority <= Syslog.logLevel(file, function)
    }
}

extension Syslog {
    private static var maskedPriorities: Set<Priority> {
        let mask = setlogmask(255)

        _ = setlogmask(mask)
        let array = Priority.all.filter {
            ((1 << $0.priority) | mask) > 0
        }
        return Set(array)
    }

    private static var configured: [Priority] {
        Syslog.activePriorities.sorted { $0.priority < $1.priority }
    }
}

extension Syslog {

    /* void closelog(void); */
    public static func closeLog() {
        closelog()
    }

    /* void openlog(const char *ident, int logopt, int facility); */
    public static func openLog(ident: String? = nil, options: Syslog.Option..., facility: Int32 = LOG_USER, verbosely: Bool = false) {
        Syslog.openVerbosely = verbosely
        let option = options.reduce(0) { $0 | $1.option }
        openlog(ident, option, facility)
        // ident == nil => use process name
        // ident != nil => does not work on Linux

        if verbosely {
            _ = setLogMask(upTo: .debug)
            Syslog.minimalLogLevel = .debug
        } else {
            _ = setLogMask(upTo: Syslog.maximalLogLevel)
        }
    }

    /* int setlogmask(int maskpri); */

    private static func setLogMask() -> Int32 {
        let mask = Syslog.activePriorities.reduce(Int32(0)) { $0 + (1 << $1.priority) }
        return setlogmask(mask)
    }

    static func setLogMask(upTo: Syslog.Priority) -> Int32 {
        Syslog.activePriorities = Set(
            Syslog.Priority.all.filter { $0.priority <= upTo.priority }
        )
        return setLogMask()
    }

    private static func setLogMask(priorities: Syslog.Priority...) -> Int32 {
        Syslog.activePriorities = Set(priorities)
        return setLogMask()
    }

    private static func clearLogMask() -> Int32 {
        Syslog.activePriorities = Set<Priority>()
        return setLogMask()
    }

    /*  void syslog(int priority, const char *format, ...); */
    /*  void vsyslog(int priority, const char *format, va_list ap); */
    private static func vSysLog(
        priority: Priority, args: CVarArg...,
        message: () -> String
    ) {
        #if arch(x86_64)
        withVaList(args) {
            vsyslog(priority.priority, message(), $0)
        }
        #elseif arch(arm64)
        
        let msg = String(format: message(), args)
        vsyslog(priority.priority, msg, nil)

        /*
        ```
        vsyslog(priority.priority, message(), args)
        ```

        cannot convert value of type '[CVarArg]' to expected argument type '__darwin_va_list?' (aka 'Optional<UnsafeMutablePointer<Int8>>')

        ```
        withVaList(args) {
            vsyslog(priority.priority, message(), $0)
        }
        ```

        cannot convert value of type 'CVaListPointer' to expected argument type '__darwin_va_list?' (aka 'Optional<UnsafeMutablePointer<Int8>>')
        */

        #endif
    }

    private static func log(
        _ priority: Priority, errcode: Int32 = 0,
        file: String = #file, function: String = #function, line: Int = #line, column: Int = #column,
        message: () -> String
    ) {
        switch errcode {
        case 0:
            // format string contains "%d %d" for line, column
            Syslog.vSysLog(priority: priority,
                           args: line, column) {
                #if os(macOS)
                    return "🔖  \(URL(fileURLWithPath: file).lastPathComponent)[%d:%d].\(function) 📌  \(message())"
                #elseif os(Linux)
                    return "\(Syslog.loggingTime()) <\(priority)>: \(URL(fileURLWithPath: file).lastPathComponent)[%d:%d].\(function) \(message())"
                #else
                    assert(false, "unknown os")
                    return "unknown os"
                #endif
            }
        default:
            // format string contains "%d %d %m" for line, column, and error code message
            Syslog.vSysLog(priority: priority,
                           args: line, column) {
                #if os(macOS)
                    return "🔖  \(URL(fileURLWithPath: file).lastPathComponent)[%d:%d].\(function) 🖍  '%m' 📌  \(message())"
                #elseif os(Linux)
                    return "\(Syslog.loggingTime()) <\(priority)>: \(URL(fileURLWithPath: file).lastPathComponent)[%d:%d].\(function) '%m'  \(message())"
                #else
                    assert(false, "unknown os")
                    return "unknown os"
                #endif
            }
        }
    }

    public static func multiple(errcode: Int32 = 0, condition: () -> Bool = { true },
                                file: String = #file, function: String = #function, line: Int = #line, column: Int = #column,
                                message: () -> String) {
        for p in Syslog.Priority.all {
            guard Syslog.loggable(p, file, function, line), condition() else { continue }
            Syslog.log(p, errcode: errcode, file: file, function: function, line: line, column: column) {
                "\(message())"
            }
        }
    }

    private static func fail(condition: @autoclosure () -> Bool = true,
                             file: String = #file, function: String = #function, line: Int = #line, column: Int = #column,
                             message: () -> String) {
        guard condition() else { return }

        log(.error,
            file: file, function: function, line: line, column: column, message: message)

        assert(false, "\(file)/\(function).\(line):\(column) \(message())")
    }

    public static func error(errcode: Int32 = 0, condition: @autoclosure () -> Bool = true,
                             file: String = #file, function: String = #function, line: Int = #line, column: Int = #column,
                             message: () -> String) {
        guard Syslog.loggable(.error, file, function, line), condition() else { return }
        log(.error, errcode: errcode,
            file: file, function: function, line: line, column: column, message: message)

        assert(!failOnError, "\(file)/\(function).\(line):\(column) \(message())")
    }

    public static func warning(errcode: Int32 = 0, condition: @autoclosure () -> Bool = true,
                               file: String = #file, function: String = #function, line: Int = #line, column: Int = #column,
                               message: () -> String) {
        guard Syslog.loggable(.warning, file, function, line), condition() else { return }
        log(.warning, errcode: errcode,
            file: file, function: function, line: line, column: column, message: message)
    }

    public static func notice(errcode: Int32 = 0, condition: @autoclosure () -> Bool = true,
                              file: String = #file, function: String = #function, line: Int = #line, column: Int = #column,
                              message: () -> String) {
        guard Syslog.loggable(.notice, file, function, line), condition() else { return }
        log(.notice, errcode: errcode,
            file: file, function: function, line: line, column: column, message: message)
    }

    public static func info(errcode: Int32 = 0, condition: @autoclosure () -> Bool = true,
                            file: String = #file, function: String = #function, line: Int = #line, column: Int = #column,
                            message: () -> String) {
        guard Syslog.loggable(.info, file, function, line), condition() else { return }
        log(.info, errcode: errcode,
            file: file, function: function, line: line, column: column, message: message)
    }

    static func prinfo(errcode: Int32 = 0, condition: @autoclosure () -> Bool = true,
                       file: String = #file, function: String = #function, line: Int = #line, column: Int = #column,
                       message: () -> String) {
        if Syslog.loggable(.info, file, function, line), condition() {
            log(.info, errcode: errcode,
                    file: file, function: function, line: line, column: column, message: message)
        } else if CommandLine[.verbose]?.first == "true" || CommandLine.name.hasSuffix("test"), condition() 
        {
            print("\(Syslog.loggingTime()) 🖨  🔖  \(URL(fileURLWithPath: file).lastPathComponent)[\(line):\(column)].\(function) 📌 \(message())")
        }
    }

    public static func debug(errcode: Int32 = 0, condition: @autoclosure () -> Bool = true,
                             file: String = #file, function: String = #function, line: Int = #line, column: Int = #column,
                             message: () -> String) {
        guard Syslog.loggable(.debug, file, function, line), condition() else { return }
        log(.debug, errcode: errcode,
            file: file, function: function, line: line, column: column, message: message)
    }
}

extension Syslog {
    private static func loggingTime() -> String {
        var t = time(nil) // : time_t
        let tm = localtime(&t) // : struct tm *
        var s = [CChar](repeating: 0, count: 64) // : char s[64];
        strftime(&s, s.count, "%F %T %z", tm)
        return String(cString: s)
    }
}
