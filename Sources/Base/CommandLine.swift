import Foundation

/**
// Swift/Misc.swift
@frozen public enum CommandLine {
    public static var argc: Int32 { get }
    public static var unsafeArgv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?> { get }
    public static var arguments: [String]
}
*/

extension CommandLine {
    public enum Option: String, Hashable, CaseIterable {
        case problems   = "--problem"       // e.g. PUZ001-1 oder PUZ001-1.p
        case baseDir    = "--base"          // e.g. ~/TPTP
        case configFile = "--config"        // path to config file
        case smtSolver  = "--smt_solver"    // "Yices" "Z3"
        case uriSchemes = "--uri_schemes"   // "http" "file"
        case timeLimit  = "--time_limit"    // seconds
        case infoTopics = "--info_topics"   // header options shorts variables topics
        case verbose    = "--verbose"       // set all log leves to debug
        case help       = "--help"          // show help, to not run solvers

        public var info: String {
            if let joined = CommandLine[self]?.joined(separator: "\" \"") {
                return "  • \(self.rawValue) \"\(joined)\""
            }
            else {
                return "  • \(self.rawValue) n/a"
            }
        }
    }

    public enum ShortOption: String, Hashable, CaseIterable { 
        case problems   = "-p"
        case baseDir    = "-b"
        case configFile = "-c"
        case smtSolver  = "-s"
        case uriSchemes = "-u"
        case timeLimit  = "-t"
        case infoTopics = "-i"
        case verbose    = "-v"
        case help       = "-h"

        public var info: String {
            "  • \(self.rawValue) is \(CommandLine.optionMapping[self]?.rawValue ?? "n/a")"
        }
    }

    public struct InfoTopicSet: OptionSet {
        public var rawValue: Int

        public static let header = InfoTopicSet(rawValue: 1 << 0)
        public static let options = InfoTopicSet(rawValue: 1 << 1)
        public static let shorts = InfoTopicSet(rawValue: 1 << 2)
        public static let variables = InfoTopicSet(rawValue: 1 << 3)
        public static let topics = InfoTopicSet(rawValue: 1 << 4)
        
        public static let all: InfoTopicSet = [.header, .options, .shorts, .variables, .topics]

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public var info: String {
            switch self {
                case .header: return "header"
                case .options: return "options"
                case .shorts: return "shorts"
                case .variables: return "variables"
                case .topics: return "topics"

                default:
                    return [.header, .options, .shorts, .variables, .topics].filter {
                        self.contains($0)
                    }
                    .map {
                        $0.info
                    }
                    .joined(separator: " ")
            }
        }
    }

    /// map short options to options
    static let optionMapping: [ShortOption : Option] = [
        .problems   : .problems,
        .baseDir    : .baseDir,
        .configFile : .configFile,
        .smtSolver  : .smtSolver,
        .uriSchemes : .uriSchemes,
        .timeLimit  : .timeLimit,
        .infoTopics : .infoTopics,
        .verbose    : .verbose,
        .help       : .help
    ]
}

extension CommandLine {
    /// CommandLine.arguments.first ?? "n/a"
    public static var name: String = {
        guard CommandLine.argc > 0 else {
            Syslog.error { "CommandLine has no arguments." }

            return "n/a (CommandLine has no arguments.)"
        }
        return CommandLine.arguments[0]
    }()

    /// CommandLine.arguments.dropFirst()
    static var parameters: [String] {
        guard CommandLine.argc > 0 else {
            return [String]()
        }
        return Array(CommandLine.arguments.dropFirst())
    }

    /// access values of all options
    static var options: [CommandLine.Option: [String]] = {
        var key = Option.problems // key for entries previous to the first --key or -key
        var dictionary = [key: [String]()] // i.e. empty list of problems

        for parameter in CommandLine.parameters {
            if let option = CommandLine.Option(rawValue: parameter) {
                key = option
                if dictionary[key] == nil {
                    dictionary[key] = [String]()    // empty list of 'key'
                }
            }  else if let shortOption = ShortOption(rawValue: parameter), 
                let option = CommandLine.optionMapping[shortOption] {
                key = option
                if dictionary[key] == nil {
                    dictionary[key] = [String]()    // empty list of 'key'
                }
            } else if let shortOption = ShortOption(rawValue: parameter) {
                Syslog.error { "unmapped command line short option \(parameter)" }
                fatalError("unmapped command line short option \(parameter)")
            } else if parameter.hasPrefix("-") {
                Syslog.warning { "unsupported command line option \(parameter)" }
            } else {
                let parameters = parameter
                        .split(separator: ";", omittingEmptySubsequences: true)
                        .map { String($0) }
                // add entries to list 'key'
                dictionary[key]?.append(contentsOf: parameters)
            }
        }

        /// read values from mapped environment variables
        for variable in Environment.Variable.allCases {
            if let key = variableMapping[variable], let value = Environment.getValue(for: variable) {
                let parameters = value
                        .split(separator: ";", omittingEmptySubsequences: true)
                        .map { String($0) }

                if dictionary[key] == nil {
                    dictionary[key] = parameters
                } else {
                    dictionary[key]?.append(contentsOf: parameters)
                }
            }
        }
        return dictionary
    }()
}

public extension CommandLine {
    /// access values by option
    static subscript(_ key: CommandLine.Option) -> [String]? {
        options[key]
    }
}


extension CommandLine {
    /// Access environment variables
    public struct Environment {
        /// Supported environment variables
        public enum Variable: String, CaseIterable {
            case HOME_DIR          = "HOME"
            case TPTP_BASE_DIR     = "TPTP_BASE"
            case FLEA_CONFIG_FILE  = "FLEA_CONFIG"
            case FLEA_SMT_SOLVER   = "FLEA_SMT_SOLVER"
            case FLEA_URI_SCHEMES  = "FLEA_URI_SCHEMES"
            case FLEA_INFO_TOPICS  = "FLEA_INFO_TOPICS"
            case FLEA_TIME_LIMIT   = "FLEA_TIME_LIMIT"

            public var info: String {
                "  • \(self.rawValue)=\(CommandLine.Environment.getValue(for: self) ?? "")"
            }
        }

        static func getValue(for name: Variable) -> String? {
            guard let value = getenv(name.rawValue) else { return nil }
            return String(validatingUTF8: value)
        }

        private static func deleteValue(for name: String) {
            unsetenv(name)
        }

        private static func set(value: String, for name: String, overwrite: Bool = true) {
            setenv(name, value, overwrite ? 1 : 0)
        }
    }

    // map environment variables to options
    static let variableMapping: [Environment.Variable : Option] = [
        .TPTP_BASE_DIR      : .baseDir,
        .FLEA_CONFIG_FILE   : .configFile,
        .FLEA_SMT_SOLVER    : .smtSolver,
        .FLEA_URI_SCHEMES   : .uriSchemes,
        .FLEA_INFO_TOPICS   : .infoTopics,
        .FLEA_TIME_LIMIT    : .timeLimit
    ]
}
