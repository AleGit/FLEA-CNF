import Foundation

// Base.FilePath must not be confused with System.FilePath
// which was introduced with iOS 14 / macOS 11.
public typealias FilePath = String

extension FilePath {
    public var fileSize: Int? {
        var status = stat()

        let code = stat(self, &status)
        switch (code, S_IFREG & status.st_mode) {
        case (0, S_IFREG):
            return Int(status.st_size)
        default:
            return nil
        }
    }

    var isAccessible: Bool {
        guard let f = fopen(self, "r") else {
            Syslog.info {
                "Path \(self) is not accessible."
            }
            return false
        }
        fclose(f)
        return true
    }

    var isAccessibleDirectory: Bool {
        guard let d = opendir(self) else {
            Syslog.info {
                "Directory \(self) does not exist."
            }
            return false
        }
        closedir(d)
        return self.isAccessible
    }
}

public extension FilePath {
    var fileName: String {
        guard let index = self.lastIndex(of: "/") else {
            return self
        }
        let start = self.index(after: index)
        let end = self.endIndex
        return String(self[start..<end])
    }

    var relativeFilePath: String {
        guard let range = self.range(of: "Problems") else {
            return self.fileName
        }
        let start = range.lowerBound
        let end = self.endIndex
        return String(self[start..<end])
    }

}

extension FilePath {
    func lines(predicate: (String) -> Bool = { _ in
        true
    }, encoding: Encoding = .utf8) -> [String]? {
        guard let f = fopen(self, "r") else {
            Syslog.error {
                "File at '\(self)' could not be opened."
            }
            return nil
        }
        guard let bufsize = self.fileSize else {
            return nil
        }

        var strings = [String]()
        var buf = [CChar](repeating: CChar(0), count: bufsize)

        while let s = fgets(&buf, Int32(bufsize), f) {
            guard let string = String(cString: s, encoding: encoding)?.trimmingWhitespace, predicate(string) else {
                continue
            }
            strings.append(string)
        }
        return strings
    }
}


