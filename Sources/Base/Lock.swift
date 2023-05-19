import Foundation

/// [Atomic Properties in Swift](https://www.vadimbulavin.com/atomic-properties/)
public protocol Lock {
    func lock()
    func unlock()
}

public final class Mutex: Lock {
    private var mutex: pthread_mutex_t = {
        var mutex = pthread_mutex_t()
        pthread_mutex_init(&mutex, nil)
        return mutex
    }()

    public init() {

    }
    public func lock() {
        pthread_mutex_lock(&mutex)
    }

    public func unlock() {
        pthread_mutex_unlock(&mutex)
    }
}
