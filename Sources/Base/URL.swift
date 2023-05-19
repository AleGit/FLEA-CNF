import Foundation

extension URL {
    /// Get the home path from environment.
    static var homeDirectoryURL: URL? {
        guard let path = CommandLine.Environment.getValue(for: .HOME_DIR) else {
            Syslog.warning {
                "\(CommandLine.Environment.Variable.HOME_DIR) path variable was not available."
            }
            return nil
        }
        return URL(fileURLWithPath: path)
    }

    /// Get the process specific configuration file path for logging
    static var loggingConfigurationURL: URL? {
        if let path = CommandLine[.configFile]?.first {
            if path.isAccessible {
                return URL(fileURLWithPath: path)
            }
            #if DEBUG
            print("🏁", CommandLine.Option.configFile, path, "is not accessible")
            #endif
        }

        if let path = CommandLine.Environment.getValue(for: .FLEA_CONFIG_FILE) {
            if path.isAccessible {
                return URL(fileURLWithPath: path)
            }
            #if DEBUG
            print("🏁", CommandLine.Environment.Variable.FLEA_CONFIG_FILE, path, "is not accessible.")
            #endif
        }

        // Choose logging file name by process name
        let directory = "Configs/"
        let name = URL(fileURLWithPath: CommandLine.name).lastPathComponent
        let suffix = ".logging"

        var paths = [
            "\(directory)\(name)\(suffix)",
            "\(directory)default\(suffix)",
        ]

        if CommandLine.name.contains("/debug/") {
            paths.insert("\(directory)\(name).debug\(suffix)", at: 0)
        } else if CommandLine.name.contains("/release/") {
            paths.insert("\(directory)\(name).release\(suffix)", at: 0)
        }
        for path in paths {
            let url = URL(fileURLWithPath: path)
            if url.isAccessible {
                Syslog.prinfo(condition: Syslog.openVerbosely) {
                    "'\(url.path)' is an accessible logging configuration file."
                }
                return url
            }
            Syslog.prinfo(condition: Syslog.openVerbosely) {
                "'\(url.path)' is not accessible."
            }
        }
        Syslog.prinfo(condition: Syslog.openVerbosely) {
            "No accessible logging configuration file was found."
        }
        return nil
    }
}

extension URL {
    private mutating func deleteLastComponents(downTo cmp: String) {
        var deleted = false
        while !deleted && lastPathComponent != "/" {
            if lastPathComponent == cmp {
                deleted = true
            }
            deleteLastPathComponent()
        }
    }

    private func deletingLastComponents(downTo cmp: String) -> URL {
        var url = self
        url.deleteLastComponents(downTo: cmp)
        return url
    }

    private mutating func append(extension pex: String, delete: Bool = true) {
        let pe = pathExtension
        guard pe != pex else {
            return
        } // nothing to do

        if delete {
            deletePathExtension()
        }

        appendPathExtension(pex)
    }

    private func appending(extension pex: String, delete: Bool = true) -> URL {
        var url = self
        url.append(extension: pex, delete: delete)
        return url
    }

    private mutating func append(component cmp: String) {
        appendPathComponent(cmp)
    }

    fileprivate func appending(component cmp: String) -> URL {
        var url = self
        url.append(component: cmp)
        return url
    }
}

extension URL {
    var isAccessible: Bool {
        self.path.isAccessible
    }

    var isAccessibleDirectory: Bool {
        self.path.isAccessibleDirectory
    }

    var isTptpLibraryDictionary: Bool {
        let problems = self.appendingPathComponent("Problems")
        let axioms = self.appendingPathComponent("Axioms")

        guard problems.appendingPathComponent("PUZ/PUZ001-1.p").isAccessible,
              axioms.appendingPathComponent("PUZ001-0.ax").isAccessible
        else {
            return false
        }
        for category in [
            "AGT", "ALG", "ANA", "ARI", "BIO", "BOO", "CAT",
            "COL", "COM", "CSR", "DAT", "FLD", "GEG", "GEO",
            "GRA", "GRP", "HAL", "HEN", "HWC", "HWV", "ITP",
            "KLE", "KRS", "LAT", "LCL", "LDA", "LIN", "MED",
            "MGT", "MSC", "NLP", "NUM", "NUN", "PHI", "PLA",
            "PRD", "PRO", "PUZ", "QUA", "RAL", "REL", "RNG",
            "ROB", "SCT", "SET", "SEU", "SEV", "SWB", "SWC",
            "SWV", "SWW", "SYN", "SYO", "TOP"
        ] {
            guard problems.appendingPathComponent(category).isAccessibleDirectory else {
                return false
            }
        }
        return true
    }
}


extension URL {

    /// Search for an accessible [TPTP library](https://www.tptp.org) for
    /// Automated Reasoning with problems and axioms on the local file system.
    static var tptpDirectoryURL: URL? {
        // --tptp_base has the highest priority

        var invalid = Set<URL>()

        if let paths = CommandLine[.baseDir] {
            // values from environment variable TPTP_BASE are already included
            for path in paths {
                let url = URL(fileURLWithPath: path)
                
                if !invalid.contains(url), url.isTptpLibraryDictionary {
                    Syslog.notice {
                        "»\(CommandLine.Option.baseDir) \(url.path)« is a valid TPTP library path."
                    }
                    return url
                }
                invalid.insert(url)

                Syslog.notice {
                    "»\(CommandLine.Option.baseDir) \(path)« is not a valid TPTP library path."
                }
            }
            Syslog.warning {
                "»\(CommandLine.Option.baseDir) \(paths.joined(separator: " "))« did not contain a valid TPTP library path."
            }
        }

        // default places

        if let homeURL = URL.homeDirectoryURL {
            for component in ["TPTP", "Downloads/TPTP", "Documents/TPTP", "UIBK/TPTP"] {
                let url = homeURL.appending(component: component)
                if !invalid.contains(url), url.isTptpLibraryDictionary {
                    Syslog.notice {
                        "(fallback) »\(url.path)« is a valid TPTP library path."
                    }
                    return url
                }
                invalid.insert(url)
            }
        }

        Syslog.error {
            "No valid TPTP library was found."
        }
        return nil
    }

    fileprivate init?(fileURLWithTptp name: String, pex: String,
                      roots: URL?...,
                      foo: ((String) -> String)? = nil) {


        // try "$name.$pex" as path

        self = URL(fileURLWithPath: name)
        append(extension: pex)

        if self.isAccessible { 
            // i.e. absolute or relative path to a problem or an axiom file
            return 
        }

        // construct path by tptp conventions, e.g.
        // foo: HWV001-1 -> Problem/HWV/HWV001-1.p
        // foo: HWC002-0 -> Axioms/HWC002-0.ax

        guard let component = foo?(lastPathComponent) else {
            return nil
        }

        for base in roots.compactMap({ $0 }) {
            self = base.appending(component: component) 
            if self.isAccessible { return }
        }

        return nil // no accessible file found
    }


    /// a problem file path string is either
    /// - the name of a problem file, e.g. 'PUZ001-1[.p]'
    /// - the relative path to a file, e.g. 'relative/path/PUZ001-1[.p]'
    /// - the absolute path to a file, e.g. '/path/to/dir/PUZ001-1[.p]'
    /// with or without extension 'p'.
    /// If no resolved problem file url is accessible, nil is returned.
    public init?(fileURLWithProblem problem: String) {
        let file = problem.peeled() // e.g. remove outer '...'
        guard let url = URL(fileURLWithTptp: String(file),
                pex: "p",
                roots: URL.tptpDirectoryURL,
                foo: {
                    let abc = String($0[0..<3])
                    return "Problems/\(abc)/\($0)"
                }
        )
        else {
            return nil
        }

        self = url
    }


    /// an axiom path string is either
    /// - the name of a axiom file, e.g. 'PUZ001-1[.ax]'
    /// - the relative path to a file, e.g. 'relative/path/PUZ001-1[.ax]'
    /// - the absolute path to a file, e.g. '/path/to/dir/PUZ001-1[.ax]'
    /// with or without extension 'ax'.
    /// If a problem URL is given, the axiom file is searches on a position in the
    /// file tree parallel to the problem file.
    /// If no resolved axiom file path is accessible, nil is returned.
    public init?(fileURLWithAxiom axiom: String, problemURL: URL? = nil) {
        let file = axiom.peeled(peels: [("'", "'")]) // e.g. remove outer '...'
        guard let url = URL(fileURLWithTptp: file, pex: "ax",
                roots: // start search in ...
                problemURL?.deletingLastComponents(downTo: "Problems"), // path/to/Problems/problem.p -> path/to/
                problemURL?.deletingLastPathComponent(), // path/to/problem.p -> path/to/
                URL.tptpDirectoryURL, // i.e. --tptp_base, $TPTP_BASE, or ~/TPTP
                foo: { "Axioms/\($0)" }
        )
        else {
            return nil
        }

        self = url
    }
}

extension URL {
    public init?(webURLWithProblem problem: String) {
        let parts = problem.split(separator: ".")
        assert(parts.count == 1 || (parts.count == 2 && parts[1] == "p"), problem)
        let format = "https://www.tptp.org/cgi-bin/SeeTPTP?Category=%@&Domain=%@&File=%@.%@"
        let category = "Problems"
        let domain = String(problem[0..<3])
        let name = String(parts[0])
        let pex = "p"
        let string = String(format: format, category, domain, name, pex)
        guard let url = URL(string: string) else {
            return nil
        }
        self = url
    }

    /// an axiom url string is something
    /// - between the name of an axiom file, e.g. 'PUZ001-1[.ax]'
    /// - and 'Axioms/<a href=SeeTPTP?Category=Axioms&File=PUZ001-0.ax>PUZ001-0.ax</a>'
    init?(webURLWithAxiom axiom: String) {
        let parts = axiom.split(separator: ".")
        assert(parts.count == 1 || (parts.count == 2 && parts[1] == "ax"))
        let format = "https://www.tptp.org/cgi-bin/SeeTPTP?Category=%@&File=%@.%@"
        let category = "Axioms"
        let name = String(parts[0])
        let pex = "ax"
        let string = String(format: format, category, name, pex)
        guard let url = URL(string: string) else {
            return nil
        }
        self = url
    }
}

public extension URL {
    static var useTptpOrg: Bool {
        guard let value = getenv("TPTP_ORG_USAGE"), let string = String(validatingUTF8: value) else {
            return false
        }
        return string == "active"
    }
}


