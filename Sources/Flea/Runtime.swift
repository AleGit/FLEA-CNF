import Tptp
import Solver
import Foundation

/// Reads command line options and provides runtime options
struct Runtime {
    /// (problems) as leading arguments, or
    /// --problem -p (problems)
    /// all arguments are considered
    static var problems: [String] {
        return CommandLine[.problems] ?? [String]()
    }

    // --base -b • see URL.tptpDirectoryURL

    // --config -c • see URL.loggingConfigurationURL


    // --smt_solver -s (Yices | Z3)
    // first argument is used, default: Z3

    static func createSolver(problem: String) -> (any Solver)? {
        Tptp.Term.reset()

        let solver: (any Solver)?

        if CommandLine[.smtSolver]?.first?.hasPrefix("Z") ?? false {
            solver = SoSolver<Z3.Context>(problem: problem,
                    options: Runtime.urlOptions,
                    timeLimit: Runtime.timeLimit)
        } else {
            solver = SoSolver<Yices.Context>(problem: problem,
            options: Runtime.urlOptions, 
            timeLimit: Runtime.timeLimit)
        }
        return solver
    }

    /// --uri_scheme -u (schemes)
    /// default: file has priority
    static var urlOptions: Tptp.File.UrlOptions = {
        guard let values = CommandLine[.uriSchemes], !values.isEmpty else {
            return .fileUrl
        }

        var options = Tptp.File.UrlOptions()

        for value in values {
            switch value.lowercased() {
                case "http", "https", "remote", "web", "weburl": 
                    options.insert(Tptp.File.UrlOptions.webUrl)
                case "file", "local", "fileurl":  
                    options.insert(Tptp.File.UrlOptions.fileUrl)
                default:  
                    break
            }
        }

        guard options.rawValue > 0 else {
             return .fileUrl
        }

        return options
    }()

    /// --time_limit -t (seconds)
    /// first argument is used, default: 300 
    static var timeLimit: TimeInterval = {
        guard let string = CommandLine[.timeLimit]?.first, let value = TimeInterval(string) else {
            return TimeInterval(300)
        }
        return value
    }()

    // --verbose -v
    // arguments are ignored
    static var isVerbose: Bool = CommandLine[.verbose] != nil

    // --info -i (topics)
    // default (missing list): header
    // default (empty list): header + topics
    static var infoTopics: CommandLine.InfoTopicSet = {
        guard let strings = CommandLine[.infoTopics] else {
            // if neither --info nor -i were present, then show header
            return .header
        }

        var topics = CommandLine.InfoTopicSet(rawValue: 0)

        for string in strings {
            switch string.lowercased() {
            case "all", "a": 
                topics = .all
                return topics
            case "header", "h":
                topics.insert(.header)
            case "options", "o":
                topics.insert(.options)
            case "shorts", "shortOptions", "s":
                topics.insert(.shorts)
            case "variables", "v":
                topics.insert(.variables)
            default: 
                break
            }
        }

        guard topics.rawValue > 0 else {
            // if list did not conatin a valid topic string then show available header and topics
            return [.header,.topics]
        }

        return topics
    }()

    // --help -h 
    // arguments are ignored
    static var showHelp: Bool = CommandLine[.help] != nil
}

extension Runtime {
    static var isActive: Bool {
        guard problems.count > 0, !showHelp else {
            printHelp()
            return false
        }

        printSeparator(infoTopics.rawValue > 0)
        defer { printSeparator(infoTopics.rawValue > 0) }

        if infoTopics.contains(.header) { printHeader(withSeparator: infoTopics.rawValue > 1) }
        if infoTopics.contains(.shorts) { printShortsInfo() }
        if infoTopics.contains(.options) { printOptionsInfo() }
        if infoTopics.contains(.variables) { printVariablesInfo() }
        if infoTopics.contains(.topics) { printInfoTopics() }

        return true
    }
}

extension Runtime {
    static func printHelp() {
        printSeparator()
        printHeader(withSeparator: true)
        defer { printSeparator() }

        print(
            """
            https://github.com/AleGit/FLEA-CNF/blob/main/README.md

            COMMAND

            USAGE
                swift run -c release Flea <problems> [<options>]

            OPTIONS
                --base, -b
                    path to directory with problems and axioms (default: ~/TPTP)
                --config, -c
                    file path to a logging configuration file
                --smt_solver, -s
                    Yices | Z3 (default: Z3)
                --uri_schemes, -u
                    file | html | file html (default: file, priority: file)
                --time_limit -t
                    maximum runtime in seconds per problem
                --verbose -v
                    sets logging to maximum, i.e. ignores logging configuration file
                --info_topics -i
                    header | options | shorts | variables | topics | all
                --help
                    show help text, to not run solver

            EXAMPLES

                Try to solve a simple problem (searches locally in ~/TPTP for the problem file):
                    swift run -c release Flea "HWV001-1.p"

                Try to load and solve problem from tptp website:
                    swift run -c release Flea "HWV001-1.p" --uri_schemes html

                Try to solve two problems: 
                    swift run -c release Flea "HWV001-1.p" "PUZ001-1.p"

                Try to solve a simple problem within 60 seconds:
                    swift run -c release Flea "HWV001-1.p" -time_limit 60

            """
        )


    }

    private static var title = "FLEA - First order Logic with Equality Attester"
    private static var separatingLine = String(repeating: "=", count: title.count + 8)

    private static func printSeparator(_ value: Bool = true) {
        guard value else { return }
        print(separatingLine)
    }
    
    private static func printHeader(withSeparator value: Bool) { 
        let name = CommandLine.name.padding(toLength: title.count, withPad: " ", startingAt:0)
        for info in [title, name] {
            print("+++", info, "+++")
        }
        printSeparator(value)
    }

    private static func printShortsInfo() {
        print("- mapping of supported command line short options:")
        for shortOption in CommandLine.ShortOption.allCases {
            print(shortOption.info)
        }
    }

    private static func printOptionsInfo() {
        print("- values of supported command line options:")
        print("  (includes values of mapped einvironment variables)")
        for option in CommandLine.Option.allCases {
            print(option.info)
        }
    }
    
    private static func printVariablesInfo() {
        print("- values of mapped environment variables:")
        for variable in CommandLine.Environment.Variable.allCases {
            print(variable.info)
        }
    }

    private static func printInfoTopics() {
        print("- available info topics (--info -i): all")
        print(" ", CommandLine.InfoTopicSet.all.info)

    }

}