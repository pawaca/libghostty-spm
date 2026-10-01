# Upstream upgrade, 2026-10-01

The PonyMux fork is rebased onto Lakr233/libghostty-spm
`37557cd6db4f8af3157f90cd3ad549d1107a9ab1` (1.6.20260929).
Ghostty moves from `82938b633ba646db38591d969c3c526332bd7e65` to
`0081d4530929317364d3bfec5309e55238e4cd90`. Zig remains 0.16.0.

## Wrapper changes

- Preserve synchronized output during resize and hold the prior frame while
  the shell redraws its prompt, with bounded holds across resize races.
- Reject stale iOS IOSurfaces during resize and adapt the Metal patches to
  the upstream shared render-device implementation.
- Expose effective and program-requested background colors to hosts.
- Fix iPad hardware input-language switching, key repeat, held Backspace,
  and the input-document anchor; match the menu bar and safe area to the theme.
- Update Apple target and source-build patch handling and same-day releases.

## Ghostty changes relevant to this fork

- Fix custom-shader selection-color uniform layout.
- Fix wide-character word selection, selection at hard line breaks,
  reverse-wrap cursor movement, pending wrap after resize, and saved cursor
  positions during repeated widening.
- Support application-requested window resizing (CSI 8 t), reset the palette
  on RIS, and cancel incomplete OSC sequences on CAN/SUB.
- Share render-device state across surfaces. PonyMux creates one Ghostty app
  per terminal, so this does not by itself share devices across its terminals.
- Extend libghostty-vt render-state/OSC APIs and harden paste/parser handling.
- Carry GTK/OpenGL, Windows memory/image-path, tmux lifetime, and build fixes;
  those do not all affect PonyMux's macOS embedded runtime.

## Fork behavior retained

Custom shaders remain enabled. Host-provided resources, public surface access,
search callbacks, binding dispatch, and the handled `open_url` return contract
are retained. Color-change and search delegate conformances are both preserved
when resolving the state-file conflicts.

The upstream wrapper still skips app ticks for detached/backgrounded surfaces;
the engine still blocks forever on a full surface mailbox and joins producer
threads at teardown. Patch 0018 and the background-wakeup fix remain necessary.

## Release integration

The new pin drops `Ghostty.build`; its storage tag is `upstream.0081d4530929`.
The production manifest retains the available fork asset until the new patched
XCFramework is published and its actual checksum is rendered by the release
scripts. Local validation uses `Package.local.swift`. Updating only the Swift
revision does not install the new engine or its closing-mailbox fix.
