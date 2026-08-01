@testable import GhosttyTerminal
import GhosttyKit
import Testing

@MainActor
private final class OpenURLRecorder: TerminalSurfaceOpenURLDelegate {
    var received: [(url: String, kind: TerminalOpenURLKind)] = []
    var answer = false

    func terminalDidRequestOpenURL(_ url: String, kind: TerminalOpenURLKind) -> Bool {
        received.append((url, kind))
        return answer
    }
}

@MainActor
private final class PlainDelegate: TerminalSurfaceViewDelegate {}

private func openURLAction(
    _ url: UnsafePointer<CChar>?, len: Int
) -> ghostty_action_s {
    var action = ghostty_action_s()
    action.tag = GHOSTTY_ACTION_OPEN_URL
    action.action.open_url = ghostty_action_open_url_s(
        kind: GHOSTTY_ACTION_OPEN_URL_KIND_TEXT,
        url: url,
        len: UInt(len)
    )
    return action
}

/// Ghostty runs its own fallback opener for an OPEN_URL the app reports as
/// unhandled, so the bridge's return value is a contract, not a convenience:
/// `true` is the only thing standing between a host-claimed
/// `write_screen_file:open` and a stray `/usr/bin/open` spawn.
@MainActor
@Suite
struct TerminalCallbackBridgeOpenURLTests {
    @Test
    func `open_url forwards the delegate's answer`() {
        let delegate = OpenURLRecorder()
        let bridge = TerminalCallbackBridge(delegate: delegate)
        let url = "file:///tmp/capture.vt"

        delegate.answer = true
        let claimed = url.withCString { ptr in
            bridge.handleAction(openURLAction(ptr, len: url.utf8.count))
        }
        #expect(claimed)
        #expect(delegate.received.map(\.url) == [url])
        #expect(delegate.received.map(\.kind) == [.text])

        delegate.answer = false
        let declined = url.withCString { ptr in
            bridge.handleAction(openURLAction(ptr, len: url.utf8.count))
        }
        #expect(!declined)
    }

    @Test
    func `open_url without a conforming delegate reports unhandled`() {
        let delegate = PlainDelegate()
        let bridge = TerminalCallbackBridge(delegate: delegate)
        let url = "https://example.com"

        let handled = url.withCString { ptr in
            bridge.handleAction(openURLAction(ptr, len: url.utf8.count))
        }
        #expect(!handled)
    }
}
