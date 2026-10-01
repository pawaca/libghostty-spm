import Foundation

/// Engine producers can request a wakeup for every message. Keep at most one
/// main-queue wakeup pending while preserving a wakeup raised during a drain.
final class TerminalWakeupScheduler: @unchecked Sendable {
    private let lock = NSLock()
    private var pending = false

    func schedule(_ operation: @escaping @Sendable () -> Void) {
        lock.lock()
        guard !pending else {
            lock.unlock()
            return
        }
        pending = true
        lock.unlock()

        DispatchQueue.main.async { [self] in
            lock.lock()
            pending = false
            lock.unlock()
            operation()
        }
    }
}
