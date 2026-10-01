import Combine
import Foundation
@testable import GhosttyTerminal
import Testing

@MainActor
struct TerminalWakeupCoalescingTests {
    @Test
    func `a burst of titles publishes only the final state next turn`() async {
        let state = TerminalViewState()
        var published: [String] = []
        let observation = state.$title.sink { published.append($0) }
        for i in 0..<10_000 { state.terminalDidChangeTitle("title-\(i)") }
        #expect(state.title == "")
        await nextMainTurn()
        #expect(published == ["", "title-9999"])

        state.terminalDidChangeTitle("")
        await nextMainTurn()
        #expect(published == ["", "title-9999", ""])
        withExtendedLifetime(observation) {}
    }

    @Test
    func `title changes back to the current value do not publish a stale value`() async {
        let state = TerminalViewState()
        state.terminalDidChangeTitle("temporary")
        state.terminalDidChangeTitle("")
        await nextMainTurn()
        #expect(state.title == "")
    }

    @Test
    func `wakeups coalesce and a wakeup during delivery is preserved`() async {
        let scheduler = TerminalWakeupScheduler()
        let count = Counter()
        for _ in 0..<10_000 {
            scheduler.schedule { count.increment() }
        }
        await nextMainTurn()
        #expect(count.value == 1)
        scheduler.schedule {
            count.increment()
            scheduler.schedule { count.increment() }
        }
        await nextMainTurn()
        await nextMainTurn()
        #expect(count.value == 3)
    }

    private func nextMainTurn() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
    }
}

private final class Counter: @unchecked Sendable {
    private let lock = NSLock()
    private var storage = 0
    var value: Int {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }
    func increment() {
        lock.lock()
        storage += 1
        lock.unlock()
    }
}
