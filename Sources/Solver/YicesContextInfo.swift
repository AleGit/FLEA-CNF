import CYices

extension Yices.Context {

    public var name: String {
        "Yices2"
    }

    public var version: String {
        String(validatingUTF8: yices_version) ?? "n/a"
    }

    public var arch: String {
        String(validatingUTF8: yices_build_arch) ?? "n/a"
    }

    public var mode: String {
        String(validatingUTF8: yices_build_mode) ?? "n/a"
    }

    public var date: String {
        String(validatingUTF8: yices_build_date) ?? "n/a"
    }
}