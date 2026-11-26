# GTK4 accessibility

This describes the downstream GTK4 implementation, not an upstream support or
GTK3-parity guarantee. The capability thresholds and GN options are documented
in [GTK4 runtime API compatibility](linux-gtk4-runtime-api.md).

## Architecture and ownership

`FlAccessibilitySemanticsStore` maintains Flutter semantics and partial updates.
The GTK4 adapter maps them into roles, states, properties, relationships, and
native objects keyed by semantics ID. Property-only updates retain unaffected
objects; role/interface changes can replace a native object. Unreachable nodes
are pruned. Incremental updates do not imply every update costs only the number
of changed nodes.

Native nodes derive from `GtkWidget` to use GTK's supported action export and
realization behavior. They do not participate in ordinary application layout,
painting, pointer targeting, or GTK keyboard focus. Widget-backed native objects
still have allocation and lifecycle costs; performance parity requires measurement.

Flutter owns semantics; GTK provides the native accessibility integration.
GTK3 continues to use its ATK adapter. This implementation does not provide the
Flutter-owned direct AT-SPI-over-D-Bus backend proposed in
[issue #159460](https://github.com/flutter/flutter/issues/159460). Sharing semantics
processing does not require sharing toolkit objects or introducing that backend.

The runtime-compatible native tree is enabled by default in this branch, but
requires GTK 4.10 traversal capabilities. With GTK 4.8, the fallback exposes the
widget-backed render surface rather than the Flutter semantics hierarchy. An
application launching on that runtime is not evidence of usable semantic access.
`flutter doctor -v` reports host API prerequisites, not application parity.

## Actions, text, and privacy

The native adapter exposes named GTK widget actions for supported Flutter
semantics actions, including activation, scrolling, increase/decrease, focus,
text navigation, and clipboard commands. Requests are routed to the current
view/node and gated by semantics actions and disabled/hidden/detached state.
Named increase/decrease actions are not a complete numeric AT-SPI Value contract;
named focus actions are not proof of Component.grab_focus support.

GTK 4.14 native text support includes content, caret/selection queries,
attributes, and change notifications. GTK 4.22 adds guarded interface callbacks
for caret and selection requests. They convert GTK character offsets to Flutter
UTF-16 offsets and dispatch `SetSelection`; Flutter semantics updates remain
authoritative. Per-character extents and point-to-offset mapping are not supplied
merely because GTK 4.16 interface slots are present.

A separate `GtkEditable` adapter supports experimental mutation through
`SetText`. It requires `FLUTTER_GTK4_ENABLE_EDITABLE_TEXT=1`, native text support,
a non-obscured node, and the advertised action. Hidden, disabled, read-only, and
detached states further restrict mutation. This is disabled by default because
investigation found an asynchronous paste lifetime concern. Enabling it is not
a declaration of production-safe EditableText parity; its dependency status and
lifetime behavior need revalidation before promotion.

Obscured fields suppress value-derived labels and value text and expose masked
text rather than the underlying value. Copy/cut are suppressed even if an
inconsistent semantics update advertises them. Read-only fields also suppress
cut/paste; password fields can retain their named paste action when otherwise
allowed. This does not enable the experimental GtkEditable adapter for passwords.
Privacy tests must cover transitions and clients retaining old native objects,
not just newly created password fields. Native password-role reporting is a
separate contract from masking and must not be inferred from it.

## Lifetime and geometry

Detach removed nodes and nodes belonging to a destroyed view before releasing
the backend's ownership. Clear dispatch eligibility, view links, relationships,
text state, and native contexts as applicable. Preserve descendants correctly
during partial-update reparenting. AT-SPI clients may retain references after
removal; safe defunct responses are valid then. A blanket requirement that no
object ever becomes defunct would hide the real lifecycle contract.

Bounds compose ancestor transforms and surface scaling. Test fractional changes
that keep the integer scale factor unchanged, monitor transitions, and nested
view coordinate conversion. Passing node-bounds tests does not establish text
geometry or compositor-wide hit-testing correctness.

## Validation and remaining limits

Use the repository's native drivers in addition to unit tests. From the checkout
root, after building the GTK4 unit target in the actual configured output:

```sh
python3 engine/src/flutter/shell/platform/linux/testing/run_gtk4_atspi_action_test.py \
  engine/src/out/host_debug_unopt/flutter_linux_gtk4_unittests \
  --check-focus --check-text --check-selection
python3 engine/src/flutter/shell/platform/linux/testing/run_gtk4_atspi_geometry_test.py \
  engine/src/out/host_debug_unopt/flutter_linux_gtk4_unittests
python3 engine/src/flutter/shell/platform/linux/testing/run_gtk4_atspi_lifetime_test.py \
  engine/src/out/host_debug_unopt/flutter_linux_gtk4_unittests \
  --output=build/gtk4-atspi-lifetime.json
```

Substitute the output directory actually generated by your engine configuration.
The drivers need their documented GTK runtime capabilities, Python AT-SPI
bindings, Xvfb, and private D-Bus/accessibility services. Native fixtures skipped
by a normal unit invocation must be run separately; a skip is not a pass.

Prior investigation recorded native action/text/selection/focus, geometry, and
retained-reference lifetime passes, including engine-boundary dispatch checks.
Those results are dated evidence, not a fresh validation of every current build.
These fixtures do not establish actual Dart editing, complete Orca interaction,
all destruction/clipboard races, or performance parity. Test the rebuilt engine
and a representative application before publishing new support claims.

Continue coverage for role replacement, semantics-ID reuse, queued editing,
password transitions, old/new GTK runtime closures, Wayland/X11, and assistive
technology behavior. Use sanitizer builds where available, while recognizing
that instrumenting Flutter does not instrument the installed GTK library.
Popup keyboard/focus behavior is an additional application integration gap;
a valid accessibility tree alone cannot establish usable popup input.

## Implementation references

- [Semantics store](../../../engine/src/flutter/shell/platform/linux/fl_accessibility_semantics_store.cc)
- [GTK4 native adapter](../../../engine/src/flutter/shell/platform/linux/fl_view_gtk4_accessibility.cc)
- [Adapter tests](../../../engine/src/flutter/shell/platform/linux/fl_view_gtk4_accessibility_test.cc)
- [Runtime capability layer](../../../engine/src/flutter/shell/platform/linux/fl_gtk4_runtime_api.h)
- [GTK variant selection](linux-gtk-variant.md)
