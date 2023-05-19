import Foundation
import CTptpParsing
import Base
import Utile

public struct Tptp {
    /// A parsed TPTP file where the abstract syntax tree is stored in
    /// an optimized dynamically allocated heap memory which is only accessible by pointers.
    /// It uses the C-API of the small tptp parsing lib
    /// - /usr/local/include/Prlc*.h
    /// - /usr/local/lib/libTptpParsing.dylib (macOS)
    /// - /usr/local/lib/libTptpParsing.so (Linux)
    public final class File {

        private var store: StoreRef?
        /// The root of the parsed <TPTP_file>
        /// <TPTP_file> ::= <TPTP_input>*
        /// <TPTP_file> ::= <TPTP_input>*
        private(set) var root: TreeNodeRef?

        public let headers: [(Header.Key, String)]

        /// initialize with the content of an url
        convenience init?(url: URL) {
            Syslog.info {
                "Tptp.File(url:\(url))"
            }

            if url.isFileURL, let content = try? String(contentsOf: url, encoding: .isoLatin1) {
                // no cleanup necessary
                self.init(string: content, variety: .file, name: url.absoluteString)
            } else if let content = try? String(contentsOf: url, encoding: .isoLatin1), // charset=iso-8859-1
                      let startRange = content.range(of: "<pre>", options: .caseInsensitive),
                      let endRange = content.range(of: "</pre>", options: [.caseInsensitive, .backwards]) {
                let problem = content[startRange.upperBound..<endRange.lowerBound]

                // remove hyperlinks in front of formulae, e.g.
                // <A NAME="ork_says_bog_is_from_venus"></A>cnf(ork_says_bog_is_from_venus,hypothesis,
                //    says(ork,bog_is_from_venus) ).
                let cleaned = problem.replacingOccurrences(of: "<A.*></A>", with: "", options: [.regularExpression, .caseInsensitive])

                // but keep 'Axioms/<a href=SeeTPTP?Category=Axioms&File=PUZ001-0.ax>PUZ001-0.ax</a>'
                assert(content.contains("charset=iso-8859-1"), "wrong charset")

                self.init(string: cleaned, variety: .file, name: url.absoluteString)
            } else {
                Syslog.error {
                    "\(url) could not be read."
                }
                return nil
            }
        }

        public struct UrlOptions: OptionSet {
            public let rawValue: Int

            public static let fileUrl = UrlOptions(rawValue: 1 << 0)
            public static let webUrl = UrlOptions(rawValue: 1 << 1)

            public static let all: UrlOptions = [.fileUrl, .webUrl]

            public init(rawValue: Int) {
                self.rawValue = rawValue
            }
        }

        /// Searches for a problem by name locally and remotely e.g. "PUZ001-1" ->
        ///
        /// 1. file:///absolute/path/to/TPTP/Problems/PUZ001-1.p
        ///
        /// 2. https://www.tptp.org/cgi-bin/SeeTPTP?Category=Problems&Domain=PUZ&File=PUZ001-1.p
        ///
        /// It will return nil if problem file could not be located, read or parsed.
        public convenience init?(problem name: String, options: UrlOptions = .fileUrl) {
            Syslog.info {
                "Tptp.File(problem:\(name))"
            }
            guard let url =
            options.contains(.fileUrl) ? URL(fileURLWithProblem: name) : nil ??
                    options.contains(.webUrl) ? URL(webURLWithProblem: name) : nil
            else {
                Syslog.error {
                    "Problem \(name) could not be found. url options:\(options)"
                }
                return nil
            }
            self.init(url: url)
        }

        /// initialize with the content of string (internal)
        ///
        /// [SyntaxBNF](https://tptp.org/cgi-bin/SeeTPTP?Category=Documents&File=SyntaxBNF)
        /// - Parameters:
        ///   - string: a problem literal
        ///   - variety:
        ///   - name:
        init?(string: String, variety: Tptp.File.Variety, name: String) {
            self.headers = Header.parseHeader(content: string)

            let code: Int32

            switch variety {
                /// variables and (constant) are terms.
                /// Σ -> fof(temp, axiom, predicate(Σ)).
                /// <fof_plain_term>
            case .function(_), .variable:
                code = prlcParseString(string, &store, &root, PRLC_FUNCTION, name)

                /// conjunctive normal form
                /// Σ -> string -> cnf(temp, axiom, Σ).
                /// <cnf_annotated>
            case .cnf:
                code = prlcParseString(string, &store, &root, PRLC_CNF, name)

                /// arbitrary first order formulas
                /// Σ -> fof(temp, axiom, Σ).
                /// <fof_annotated>
            case .fof, .universal, .existential, .negation, .disjunction, .conjunction, .implication, .reverseimpl, .bicondition, .xor, .nand, .nor, .equation, .inequation, .predicate:

                code = prlcParseString(string, &store, &root, PRLC_FOF, name)

                /// the content of include statements, e.g.
                /// - "'Axioms/PUZ001-0.ax'"
                /// - "'Axioms/SYN000-0.ax',[ia1,ia3]"
                /// Σ -> include(Σ).
                /// <include>
            case .include:
                code = prlcParseString(string, &store, &root, PRLC_INCLUDE, name)

                /// the content of a file
                /// Σ -> Σ
                /// <TPTP_file>
            case .file:
                code = prlcParseString(string, &store, &root, PRLC_FILE, name)

            default: // .name, .role, .annotation
                code = -1
            }

            guard code == 0 && store != nil && root != nil else {
                return nil
            }
        }

        /// free dynamically allocated memory
        deinit {
            Syslog.debug {
                "'\(self.identifier ?? "n/a")' memory freed."
            }

            if let store = store {
                prlcDestroyStore(store)
            }
        }

        /// The identifier, i.e. the file path or an url string to the parsed file is stored in the root.
        public var identifier: String? {
            guard let cstring = root?.pointee.symbol else {
                return nil
            }
            return String(validatingUTF8: cstring) ?? nil
        }

        /// Try to construct an URL from identifier
        var url: URL? {
            guard let string = self.identifier else {
                return nil
            }

            if string.hasPrefix("http") || string.hasPrefix("file") {
                return URL(string: string)
            } else {
                return URL(fileURLWithPath: string)
            }
        }

        /// The sequence of stored symbols (paths, names, etc.) from first to last.
        /// Symbols (C-strings / UTF8) are uniquely stored in a single memory block,
        /// i.e. the symbols are separated by exactly one `\0`
        var symbols: Utile.Sequence<CStringRef, String?> {
            let first = prlcFirstSymbol(store!)
            let step = { (cstring: CStringRef) in
                prlcNextSymbol(self.store!, cstring)
            }
            let data = { (cstring: CStringRef) in
                String(validatingUTF8: cstring)
            }

            return Utile.Sequence(first: first, step: step, data: data)
        }

        /// The sequence of stored tree nodes from first to last.
        private var nodes: Utile.Sequence<TreeNodeRef, TreeNodeRef> {
            let first = prlcFirstTreeNode(store!)
            let step = { (treeNode: TreeNodeRef) in
                prlcNextTreeNode(self.store!, treeNode)
            }
            let data = { (treeNode: TreeNodeRef) in
                treeNode
            }
            return Utile.Sequence(first: first, step: step, data: data)
        }

        /// The sequence of parsed <TPTP_input> nodes.
        /// - <TPTP_input> ::= <annotated_formula> | <include>
        var inputs: Utile.Sequence<TreeNodeRef, TreeNodeRef> {
            root!.children {
                $0
            }
        }

        /// The sequence of parsed <include> nodes.
        /// includes.count <= inputs.count
        var includes: Utile.Sequence<TreeNodeRef, TreeNodeRef> {
            root!.children(where: { $0.type == PRLC_INCLUDE }) {
                $0
            }
        }

        /// The sequence of parsed <cnf_annotated> nodes.
        /// cnfs.count <= inputs.count
        var cnfs: Utile.Sequence<TreeNodeRef, TreeNodeRef> {
            root!.children(where: { $0.type == PRLC_CNF }) {
                $0
            }
        }

        /// The sequence of parsed <fof_annotated> nodes.
        /// fofs.count <= inputs.count
        private var fofs: Utile.Sequence<TreeNodeRef, TreeNodeRef> {
            root!.children(where: { $0.type == PRLC_FOF }) {
                $0
            }
        }

        /// return a list of triples with the 'short' name, the formula selection, and the URL (file://, http(s)://)
        /// from <include> entries like
        /// include('Axioms/SYN000+0.ax',[ia1,ia3])
        ///     -> ("'Axioms/SYN000+0.ax'", ["ia1","ia3"], "file:///absolute/path/to/TPTP/Axioms/SYN000+0.ax")
        /// include('Axioms/<a href=SeeTPTP?Category=Axioms&File=PUZ001-0.ax>PUZ001-0.ax</a>')
        ///     -> ("'Axioms/SYN000+0.ax'", ["ia1","ia3"], "https://www.tptp.org/cgi-bin/SeeTPTP?Category=Axioms&File=PUZ001-0.ax")
        private func axiomSelectionURLs(problemURL: URL) -> [(String, [String], URL)] {
            // <include> ::= include(<file_name><formula_selection>).
            return includes.compactMap {
                // <file_name> ::= <single_quoted>
                guard let name = $0.symbol else {
                    Syslog.error {
                        "<include> entry has no <file_name>."
                    }
                    return nil
                }

                let shortName: String
                let axiomURL: URL

                if problemURL.isFileURL, let fileURL = URL(fileURLWithAxiom: name, problemURL: problemURL) {
                    shortName = name
                    axiomURL = fileURL
                    Syslog.debug {
                        "\(shortName) • '\(axiomURL)'"
                    }
                } else if let range = name.range(of: "SeeTPTP[^>]*ax", options: [.regularExpression, .caseInsensitive]) {
                    let seeTPTP = name[range]

                    let format = "https://www.tptp.org/cgi-bin/%@"
                    let string = String(format: format, String(seeTPTP))
                    guard let newURL = URL(string: string) else {
                        return nil
                    }
                    shortName = name.replacingOccurrences(of: "(<A.*ax>)|(</A>)", with: "", options: [.regularExpression, .caseInsensitive])
                    axiomURL = newURL
                    Syslog.debug {
                        "\(shortName) ⦿ '\(axiomURL)'"
                    }
                } else {
                    return nil
                }
                // <formula_selection> ::= ,[<name_list>] | <null>
                let selection = $0.children.compactMap {
                    $0.symbol
                }
                return (shortName, selection, axiomURL)
            }
        }

        var axiomSources: [(String, [String], URL)] {
            return axiomSelectionURLs(problemURL: self.url!)
        }

        var containsIncludes: Bool {
            includes.reduce(false) { _, _ in
                true
            }
        }
    }
}

extension Tptp.File {
    /// term = Tptp.Term.create(tree: tree)
    /// roleSymbol = term.nodes?.first?.symbol, role = Tptp.Role(rawValue: roleValue),
    /// literals = term.nodes?.last?.nodes (last of the two term.nodes)
    private func clause(tree: TreeNodeRef) -> [Tptp.Term]? {
        guard let term = Tptp.Term.create(tree: tree),
              let literals = term.nodes?.last?.nodes else {
            assert(false)
            Syslog.error { "Unable to create literals" }
            return nil
        }
        assert(term.nodes?.count == 2)
        return literals
    }

    private func readCnfs()  -> [[Tptp.Term]] {
        cnfs.compactMap { cnf in
            clause(tree: cnf)
        }
    }

    private func readCnfs(select: (String) -> Bool) -> [[Tptp.Term]] {
        cnfs.compactMap { cnf in
            guard let symbol = cnf.symbol, select(symbol) else {
                assert(cnf.symbol != nil)
                return nil
            }
            return clause(tree: cnf)
        }
    }

    private func axioms() -> [[Tptp.Term]] {
        axiomSources.flatMap { (s: String, strings: [String], url: URL) -> [[Tptp.Term]] in
            guard let file = Tptp.File(url: url) else {
                assert(false)
                return [[Tptp.Term]]()
            }
            return file.readCnfs {
                strings.isEmpty || strings.contains($0)
            }
        }
    }

    public var clauses: [[Tptp.Term]] {
        var clauses = self.readCnfs()
        clauses.append(contentsOf: self.axioms())
        // TODO: equality axioms
        let axioms = Tptp.Term.typedSymbols.equalityAxioms?.map {
            $0.literals
        }
        if let axioms = axioms {
            clauses.append(contentsOf: axioms)
        }

        return clauses
    }
}


extension Tptp.File {
    public var roles: [Tptp.Role: Int] {
        nodes.filter {
                    $0.type == PRLC_ROLE
                }
                .reduce(into: [Tptp.Role: Int]()) {
                    (result: inout [Tptp.Role: Int], treeNodeRef: TreeNodeRef) in
                    let role = Tptp.Role(rawValue: treeNodeRef.symbol ?? "unknown") ?? Tptp.Role.unknown
                    let value = result[role] ?? 0
                    result[role] = value + 1
                }
    }

    public func nodeSymbols(type: PRLC_TREE_NODE_TYPE) -> Set<String> {
        nodes.filter {
                    $0.type == type
                }
                .reduce(into: Set<String>()) {
                    (symbols: inout Set<String>, treeNodeRef: TreeNodeRef) in
                    symbols.insert(treeNodeRef.symbol ?? "n/a")
                }

    }
}

extension Tptp.File {

    private func namedClause(tree: TreeNodeRef) -> Tptp.NamedClause? {
        guard let term = Tptp.Term.create(tree: tree),
              let roleValue = term.nodes?.first?.symbol, let role = Tptp.Role(rawValue: roleValue),
              let clause = term.nodes?.last, let literals = clause.nodes
        else {
            return nil
        }
        return Tptp.NamedClause(name: term.symbol, role: role, literals: literals)
    }

    private func namedClause(select: (String) -> Bool = { _ in
        true
    }) -> [Tptp.NamedClause] {
        return cnfs.compactMap { cnf in
            guard let symbol = cnf.symbol, select(symbol) else {
                assert(cnf.symbol != nil)
                return nil
            }
            return namedClause(tree: cnf)
        }
    }

    /// A list of closes with name, role, and list of literals.
    /// These clauses are present in the file.
    public var namedClauses: [Tptp.NamedClause] {
        return namedClause()
    }

    /// A list of clauses with name, role (axiom), and list of literals.
    /// These clauses are loaded from other (axiom) files.
    public var namedAxioms: [Tptp.NamedClause] {
        axiomSources.flatMap { (s: String, strings: [String], url: URL) -> [Tptp.NamedClause] in
            guard let file = Tptp.File(url: url) else {
                assert(false)
                return [Tptp.NamedClause]()
            }
            return file.namedClause {
                strings.isEmpty || strings.contains($0)
            }
        }
    }
}

extension Tptp.File {
    public struct Header {
        fileprivate enum State {
            case Start(Int) // start state and number of read non-comment lines
            case Separator(Int) // number of read separator lines
            case Key(Header.Key)
        }

        fileprivate enum Line {
            case NoComment
            case Separator
            case KeyValue(Header.Key, String)
            case Value(String)

            init(string: String) {
                let cs = CharacterSet.whitespacesAndNewlines.union(["%"])
                if !string.hasPrefix("%") {
                    self = .NoComment
                } else if string.hasPrefix("%--------------------") {
                    self = .Separator
                } else if string.hasPrefix("%          ") {
                    let value = string.trimmingCharacters(in: cs)
                    self = .Value(value)
                } else {
                    let parts = string.split(separator: ":", maxSplits: 1)
                    let key = Header.Key(string: parts.first?.trimmingCharacters(in: cs) ?? "n/a")
                    let value = parts.count > 1 ? parts[1].trimmingCharacters(in: cs) : ""
                    self = .KeyValue(key, value)
                }
            }
        }

        public enum Key: Hashable {
            case Undefined
            case File, Domain, Problem, Version, English, Refs, Source, Names, Status, Rating, Syntax, SPC, Comments
            case Unknown (String)

            init(string: String) {
                switch string {
                case "File":
                    self = .File
                case "Domain":
                    self = .Domain
                case "Problem":
                    self = .Problem
                case "Version":
                    self = .Version
                case "English":
                    self = .English
                case "Refs":
                    self = .Refs
                case "Source":
                    self = .Source
                case "Names":
                    self = .Names
                case "Status":
                    self = .Status
                case "Rating":
                    self = .Rating
                case "Syntax":
                    self = .Syntax
                case "SPC":
                    self = .SPC
                case "Comments":
                    self = .Comments
                default:
                    self = .Unknown(string)
                }
            }
        }

        fileprivate static func parseHeader(content: String) -> [(Header.Key, String)] {
            var list = [(Header.Key, String)]()
            var state = Header.State.Start(0)

            content.enumerateLines { (string, stop) in
                let line = Header.Line(string: string)

                switch (state, line) {

                        // %------------------------------------------------------------------------------
                case (.Start(let count), .NoComment):
                    stop = count > 10 // give up after 10 initial non-comment lines
                    state = .Start(count + 1)
                case (.Start(_), .Separator):
                    state = .Separator(0)
                case (.Separator(let count), .Separator), (.Separator(let count), .NoComment):
                    stop = count > 10 // give up after 10 sequent separator and non-comment lines
                    state = .Separator(count + 1)

                        // % File     : ANA007-1 : TPTP v8.1.2. Released v3.2.0.
                        // % Syntax   : Number of clauses     : 2784 ( 646 unt; 248 nHn;1975 RR)
                case (.Separator, .KeyValue(let key, let value)),
                     (.Key, .KeyValue(let key, let value)):
                    list.append((key, value))
                    state = .Key(key)

                        // %            Number of literals    : 6116 (1279 equ;3143 neg)
                case (.Key(let key), .Value(let value)):
                    list.append((key, value))

                case (.Key, .NoComment):
                    break // i.e. ignore line

                        // %------------------------------------------------------------------------------
                case (.Key, .Separator):
                    stop = true

                default:
                    Syslog.warning {
                        "Unhandled (state, line): \((state, line))"
                    }
                    break // i.e. ignore line
                }
            }
            return list
        }

        public enum Status: String, Hashable {
            case unsatisfiable = "Unsatisfiable"
            case satisfiable = "Satisfiable"
            case undefined = "Undefined"
        }
    }
}
