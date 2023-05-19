import CZ3Api

extension Z3.Context {
     public var name: String {
        "Z3"
    }

     public var version: String {
        var major = UInt32.zero
        var minor = UInt32.zero
        var build = UInt32.zero
        var revision = UInt32.zero
        Z3_get_version(&major, &minor, &build, &revision)
        return [major, minor, build, revision].map {
            "\($0)"
        }.joined(separator: ".")
    }

}
