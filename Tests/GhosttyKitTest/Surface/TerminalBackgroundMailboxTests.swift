import Foundation
import GhosttyKit
@testable import GhosttyTerminal
import Testing

@MainActor
@Suite(.serialized)
struct TerminalBackgroundMailboxTests {
    @Test(arguments: [(false, true), (true, false), (false, false)])
    func `titles reach the host when rendering is suspended`(
        attached: Bool, active: Bool
    ) async throws {
        let host = await GhosttySurfaceHarness.make()
        defer { host.tearDown() }
        let receiver = TitleReceiver()
        host.coordinator.delegate = receiver
        host.coordinator.isAttached = { attached }
        host.coordinator.setApplicationActive(active)
        let surface = try #require(host.surface)

        // Write through the actual engine, bypassing InMemoryTerminalSession's
        // independent app tick. Stay below the mailbox capacity so the old
        // behavior fails an assertion rather than hanging the test runner.
        let titles = (0..<8).map { "background-title-\($0)" }
        let output = titles.map { "\u{1B}]2;\($0)\u{07}" }.joined()
        let bytes = Array(output.utf8)
        bytes.withUnsafeBufferPointer {
            ghostty_surface_write_buffer(surface.rawValue, $0.baseAddress, UInt($0.count))
        }
        host.coordinator.controller?.handleWakeup()

        #expect(receiver.titles == titles)
    }
}

@MainActor
private final class TitleReceiver: TerminalSurfaceTitleDelegate {
    var titles: [String] = []
    func terminalDidChangeTitle(_ title: String) { titles.append(title) }
}
