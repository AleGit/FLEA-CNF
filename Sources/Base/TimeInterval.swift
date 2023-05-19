import Foundation

public extension TimeInterval {
    var pretty: String {
        if self < 0.001 {
            return String(format: "%.0f ns", ceil(self * 1000.0 * 1000.0))
        }
        if self < 1.0 {
            return String(format: "%.0f ms", ceil(self * 1000.0))
        }
        else if self < 10.0 {
            return String(format: "%.2f s",self)
        } else if self < 100.0 {
            return String(format: "%.1f s",self)
        } else {
            return String(format: "%.0f s", ceil(self))
        }
    }
}

public extension TimeInterval? {
    var pretty: String {
        guard let timeInterval = self else {
            return "n/a"
        }
        return timeInterval.pretty
    }
}