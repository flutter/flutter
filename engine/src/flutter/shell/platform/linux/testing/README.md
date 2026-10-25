# Linux GTK compatibility tests

GTK3 and GTK4 unit tests are built as separate targets. They must not load both
GTK major versions into one process. Build the GTK4 tests from the repository root:

```sh
autoninja -C engine/src/out/host_debug_unopt flutter_linux_gtk4 flutter_linux_gtk4_unittests
```

## Implementation boundaries

GTK4 accessibility tree reconciliation and view integration live in
`fl_view_gtk4_accessibility.cc`. Native node roles, properties, actions, and
lifecycle live in `fl_gtk4_accessible_node.cc`; text queries, selection, protected
values, and editing live in `fl_gtk4_text_accessible_node.cc`. Tree reconciliation
uses the opaque node API. Only node and text implementations share the node's
private layout. The native-tree build flag and runtime capability checks remain
in effect for all three implementations.

Display bookkeeping lives in `fl_display_monitor.cc`, with discovery and signal
subscriptions behind `fl_display_monitor_backend.h`. The GTK3 and GTK4 source
sets select their respective adapters. Adapters return owned monitor snapshots
and disconnect all subscriptions on disposal. The GTK4 adapter retains the
existing behavior of resetting display IDs when the monitor list changes.

## GTK conditional-compilation audit

Inventory GTK4 switches and GTK version checks per C/C++/Objective-C source file:

```sh
python3 engine/src/flutter/shell/platform/linux/testing/audit_gtk4_ifdefs.py
python3 engine/src/flutter/shell/platform/linux/testing/audit_gtk4_ifdefs.py \
  engine/src/flutter/shell/platform/linux/fl_view.cc --details
python3 engine/src/flutter/shell/platform/linux/testing/audit_gtk4_ifdefs.py \
  --json > /tmp/gtk4-ifdefs.json
```

The default scan covers the Linux embedder, sorted by block count. Pass files or
directories to change the scope; overlapping paths are deduplicated. `--sort path`
orders the report by filename. Detailed and JSON output include branch line
ranges, `#else` alternatives, and enclosing conditions. Comments, string literals,
and header guards are excluded; continued directives retain physical line numbers.
`BODY_LINES` counts the union of physical branch-body lines (including comments
and blank lines), excluding conditional directive lines. Nested blocks do not
double-count these lines.

This is a source inventory, not a preprocessor or proof of runtime compatibility:
conditions are not evaluated, includes are not expanded, and every alternative
of a GTK-related conditional is reported. Files without matches are omitted.
Presence tests of `FLUTTER_LINUX_GTK4` are annotated because they also match a
macro defined as `0`; this is informational, since the current GN targets define
the macro for GTK4 and leave it undefined for GTK3. Malformed conditionals or
unreadable files cause a nonzero exit and are included in JSON's `errors` array.

Run the audit utility's tests with:

```sh
python3 -m unittest discover -s engine/src/flutter/shell/platform/linux/testing \
  -p audit_gtk4_ifdefs_test.py
```

## Runtime compatibility

The optional runtime validator configures an isolated output directory, checks
the selected sysroot's GTK symbols, checks that the engine does not directly
import the listed optional APIs, and runs GoogleTest against a selected runtime.
It is a local integration check, not a replacement for the engine unit tests or
an automatically scheduled CI job.

```sh
bash dev/tools/test_gtk4_runtime_compat.sh \
  --sysroot=bullseye --native-tree-compat --runtime-loader=container \
  --container-image=localhost/flutter-gtk4-tests:bookworm
```

Requirements: an x86-64 Linux host, the engine build dependencies, the selected installed sysroot,
`readelf`, Python 3.10 or later, and Xvfb. The shell entry point forwards all
arguments to `validate_gtk4_runtime_compat.py` in this directory. It can be run
from any working directory.

Runtime modes have different guarantees:

- `host` stages the selected sysroot's GTK dependencies but uses the host's
  libc and loader. It checks the resolved GTK/GLib libraries for accidental
  host fallback. This is not a full distribution compatibility test. Patched
  build-sysroot binaries can fail in the loader before any tests execute;
  use container runtimes for compatibility evidence in that case.
- `sysroot` uses the sysroot's loader and libraries and rejects dependencies
  outside that root or the build output. Some build sysroots omit runtime files.
- `container` requires an explicit, already available `--container-image` with
  GTK4, EGL, epoxy, their dependencies, Xvfb and `xauth`. Prepare and preferably
  pin that image separately. The test does not pull images, install packages,
  or use the network. `--sysroot` selects build headers; the image independently
  selects runtime libraries. Use Bookworm for GTK 4.8 and a suitable newer image
  for native-tree coverage. Stock Bullseye does not contain the GTK backport.

For local image preparation, a minimal Containerfile is:

```dockerfile
ARG BASE_IMAGE=debian:bookworm
FROM ${BASE_IMAGE}
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      libgtk-4-1 libegl1 libepoxy0 libgl1-mesa-dri dbus-x11 xvfb xauth && \
    rm -rf /var/lib/apt/lists/*
```

Build it with `podman build -t localhost/flutter-gtk4-tests:bookworm .`.
Use `--build-arg BASE_IMAGE=debian:trixie` and a different tag for Trixie.
Image preparation needs network access. Record the resulting image ID/digest
and installed GTK version with results; tags alone do not fix package versions.

To test an existing binary against Trixie libraries without reconfiguring it:

```sh
bash dev/tools/test_gtk4_runtime_compat.sh \
  --skip-build --output-dir=engine/src/out/host_debug_unopt \
  --sysroot=trixie --native-tree-compat --runtime-loader=container \
  --container-image=localhost/flutter-gtk4-tests:trixie
```

Native-tree tests require a capable runtime and may skip on GTK 4.8. The runtime
API tests still exercise capability detection and fallback. A skip does not
establish native-tree parity. `--skip-runtime` performs artifact checks only.

Test the validator's configuration and failure checks without building Flutter:

```sh
python3 -m unittest discover \
  -s engine/src/flutter/shell/platform/linux/testing \
  -p validate_gtk4_runtime_compat_test.py
```

## GTK3/GTK4 AT-SPI comparison

```sh
autoninja -C engine/src/out/host_debug_unopt \
  flutter_linux_accessibility_parity_tests flutter_linux_gtk4_unittests
python3 engine/src/flutter/shell/platform/linux/testing/run_atspi_parity_test.py \
  --gtk3 engine/src/out/host_debug_unopt/flutter_linux_accessibility_parity_tests \
  --gtk4 engine/src/out/host_debug_unopt/flutter_linux_gtk4_unittests \
  --output /tmp/flutter-atspi-parity.json
```

Both binaries compile the same semantics fixture: a button, checkbox, editable
and obscured text, Unicode selection, slider, scroll actions, and nested groups.
The client verifies complete export, absence of defunct nodes, undefined
selection/expansion capabilities, action dispatch, and a partial checkbox-state
update. It records roles, interfaces, states,
normalized action names, children and text queries before and after the actions.
Loaded GTK/GLib versions are included in the JSON report. Protected text is
represented only by whether the fixture value was exposed, never its contents.

The comparison also checks protected Text: masking, character count, caret and
selection, suppression of copy/cut, and preservation of advertised paste. It
protects existing ASCII and Unicode fields, checks that deletion/insertion event
payloads contain only masks, and restores readable contents. On GTK 4.22+ it
sends a native protected selection request and verifies the Flutter UTF-16
payload. Older text-capable runtimes still exercise the query checks and report
selection-command support separately. The report includes binary/source-file
checksums and successful action-routing assertions.

GTK3 is a regression baseline for usable behavior. Its synthetic obscured-value
disclosure and UTF-16 offsets in AT-SPI character queries are not target behavior.
Masked Text support does not solve password-role identification: GTK 4.22's
native exporter recognizes password roles through concrete GtkText/editable
delegates, rather than a public property for custom accessible objects.

The GTK3 target uses real GTK; the regular unit-test binary replaces native GTK
functions and cannot perform this export test. GTK4 needs native text support
(GTK 4.14+); GTK 4.8 fallback is tested by the runtime compatibility validator.
The command needs the same AT-SPI/Xvfb prerequisites as the activation test below.

The default command fails on broken common behavior and reports remaining
backend differences. Add `--strict` to fail on any difference, including native
interface/role differences; there is no allowlist hiding discrepancies. Passing
the common checks does not establish full parity or real Dart/Orca behavior.
No rendering or performance comparison is performed by this fixture.

Test the report comparison without a display:

```sh
python3 -m unittest discover \
  -s engine/src/flutter/shell/platform/linux/testing \
  -p run_atspi_parity_test_test.py
```

## Native AT-SPI geometry

```sh
python3 engine/src/flutter/shell/platform/linux/testing/run_gtk4_atspi_geometry_test.py \
  engine/src/out/host_debug_unopt/flutter_linux_gtk4_unittests \
  --output /tmp/flutter-gtk4-atspi-geometry.json
```

Requires the same native-tree, AT-SPI and Xvfb prerequisites as activation below.
The runner creates private sessions with desktop-service autoactivation disabled,
then starts the required accessibility services. It verifies parent and window
coordinates through three semantic levels, composed scale/translation, nonzero
semantic rectangle origins, and a render surface offset within a GTK host.
It runs at GTK scale factors 1 and 2, checking logical-coordinate conversion and
outward rounding. A native tap triggers a root-only transform update; retained
objects must report the updated geometry and dispatch exactly two Flutter taps.
The second tap removes the realized subtree, exercising native notifications
and proxy teardown after clients have queried the nodes.
The JSON records GTK/GLib versions, scale, queried rectangles and the binary hash.

This tests Component geometry with a mocked engine. It does not establish
screen-coordinate support, clipping/hit testing, text character extents,
Wayland behavior, arbitrary fractional desktop scaling, or real Dart layout.

Add `--check-hit-testing` to require native Contains and GetAccessibleAtPoint
results to match the queried parent/window rectangles before and after the
ancestor update. It checks rectangle boundaries and deepest-descendant lookup,
including an overlapping hidden sibling that must not intercept the visible
button. Both modes verify that native child traversal excludes this sibling.
The report records the loaded GTK library path and hash as well as its version.

This strict gate fails on the tested stock GTK 4.22.5: containment compares local
points to the object's position instead of size, and point lookup subtracts the
queried object's origin twice. Point lookup also visits hidden nodes and their
subtrees, unlike ordinary native child traversal. Independent GTK corrections
and standalone reproductions are tracked in the accessibility investigation.
Use a GTK runtime with those corrections to pass this gate; the Flutter bridge
does not carry a workaround. The default geometry command continues to test bounds on stock GTK.
Passing hit checks does not establish clipping or Flutter paint/hit-test order.

## Native lifetime and multiple views

```sh
python3 engine/src/flutter/shell/platform/linux/testing/run_gtk4_atspi_lifetime_test.py \
  engine/src/out/host_debug_unopt/flutter_linux_gtk4_unittests \
  --output /tmp/flutter-gtk4-atspi-lifetime.json
```

The fixture realizes two views sharing an engine. The client retains a root,
parent and focused child, and registers child/state/text event listeners. A
native controller action reparents the omitted child using a root-only update
and removes its old parent. The same native child must remain usable and route
one tap to the original view/node. Another controller action destroys the target
window and disposes its view while the control view stays alive.

Retained remote objects must become defunct or reject queries as unregistered;
timeouts and other transport errors fail the test. A stale child action must
not reach Flutter. The final control action verifies routing counts, and the
listener must observe a retained-object defunct notification. This uses real
GTK/AT-SPI with a mock engine, private X11, and scale 1; it does not cover queued
clipboard edits, ID reuse, arbitrary event ordering, or full screen-reader use.

The local workspace helpers can run this gate with ordinary tests:
`./run_gtk_tests.sh --gtk4 --native`. An explicit sanitizer build/test invocation
is `./build.sh debug --asan --test`, which uses a separate
`host_debug_unopt_asan` directory. `./build.sh all --test` runs the debug tests
then normal profile/release builds. `all --asan` is rejected to keep sanitizer
artifacts separate. `--dry-run` prints build commands without executing them.
These root helper scripts are local workspace files, not tracked engine tooling.
Native action/selection checks require a GTK 4.22+ runtime; using old headers
for compilation does not meet that runtime requirement.

## Independent reading and hit-test order

```sh
python3 engine/src/flutter/shell/platform/linux/testing/run_gtk4_atspi_overlap_test.py \
  engine/src/out/host_debug_unopt/flutter_linux_gtk4_unittests \
  --output /tmp/flutter-gtk4-atspi-overlap.json
```

This explicit gate currently fails even with the GTK coordinate and hidden-node
corrections. Two visible buttons overlap and retain reading order `[2, 3]`.
Flutter supplies hit order `[2, 3]`, then a native tap changes it to `[3, 2]`
with a parent-only partial update. Native point lookup should change its target
from node 2 to node 3. GTK's generic lookup instead picks node 3 in both phases.
The runner records both phases, stable object identity and exactly two native
taps, writes the report, and exits 1 when hit order is wrong. Use the corrected
GTK runtime to isolate this limitation from the earlier coordinate bugs.

The semantics store preserves the independent order, including order-only
updates, but the released GtkAccessible interface has no custom hit-test hook.
Reordering the exported children would change screen-reader reading order.
The unresolved API requirement is tracked in the accessibility investigation;
passing the ordinary geometry gate does not establish overlap-order parity.

## Native AT-SPI activation

```sh
python3 engine/src/flutter/shell/platform/linux/testing/run_gtk4_atspi_action_test.py \
  engine/src/out/host_debug_unopt/flutter_linux_gtk4_unittests
```

This separate integration test needs a GTK runtime with native accessible-tree
support, PyGObject with Atspi introspection, `dbus-run-session`, Xvfb, `xauth`,
and the AT-SPI bus launcher and registry. It creates a private session/display,
finds its fixture by PID, and invokes the exported tap, directional scrolling,
increase/decrease, show-on-screen, dismiss, focus, expand/collapse, and clipboard
actions. Clipboard actions operate on Flutter's current selection; they do not
implement the range-based AT-SPI EditableText interface or manipulate the host
clipboard in this fixture. Unit tests additionally verify that copy/cut are
blocked for obscured content and cut/paste for read-only fields, while advertised
paste remains available for editable obscured fields.
The fixture asserts the resulting Flutter
embedder actions and their order. It does not validate a Dart callback,
Orca behavior, or full text-editing support.

The external-client fixture skips in ordinary GoogleTest runs. The runtime
validator tests do not require access to the user's accessibility bus.

On GTK 4.18 or later, add `--check-focus` to the AT-SPI command to verify focus
gain/loss notifications and their corresponding exported states. It also checks
that repeated identical semantics batches do not duplicate those notifications.
GTK 4.10 through 4.16 can expose the cached platform states on query, but lack
the public `gtk_accessible_update_platform_state()` notification API. Runtime
compatibility builds resolve this API optionally; direct-call builds require
GTK 4.18 headers to enable these notifications.

On GTK 4.14 or later, add `--check-text` to verify the exported AT-SPI Text
interface: contents, Unicode character count, UTF-16 selection conversion,
caret offset, and character/word/sentence/paragraph ranges. The multiline fixture
checks that paragraph queries stop at the next paragraph start, including the
separator, rather than returning the entire field. It includes an end-of-text
character query to ensure it does not repeat the whole field. The client also
triggers a semantics text replacement and checks deletion/insertion payloads,
caret and selection notifications, and the resulting queryable state. A repeated
identical semantics batch must not produce additional notifications. Incremental
edits cover Unicode replacement with unchanged prefixes/suffixes, insertion-only
and deletion-only changes, without whole-field or zero-length events. The client
also invokes forward/backward character and word cursor actions and verifies
their Flutter boolean payload (do not extend the selection). This works without
GTK 4.22 selection setters. It does not validate actual Dart caret movement,
text insertion/deletion, or visual line wrapping. This flag can be combined with
`--check-focus`.

On GTK 4.22 or later, `--check-selection` verifies that AT-SPI caret and
selection commands reach Flutter as `SetSelection` actions with UTF-16 offsets.
It implies `--check-text` and can be combined with `--check-focus`. The mock
embedder verifies the action payload; this does not exercise Dart editing or
text insertion/deletion commands. Cached caret/selection state remains governed
by subsequent Flutter semantics updates, not optimistic native mutations.

### GTK 4.22 interface safety

`FlGtk4RuntimeApiTest.EditingCallbacksOnlyWriteTheSupportedTail` checks that
installation changes only the two new callbacks on a supported runtime and
changes no bytes on an older runtime. The incomplete-argument test checks that
rejected installations do not partially overwrite an interface.
`OlderRuntimeDoesNotAccessBeyondTextInterface` places an old-size interface
against a protected memory page: any access to the newer tail faults. This test
must run on an older GTK runtime; its skip on GTK 4.22+ is not a safety pass.
Run the compatibility validator with prepared older and newer runtime images.

The checked-in header also asserts every text-interface member offset available
in the build headers, plus the range layout and GTK 4.22 callback signatures.
Check it independently of the engine build against installed GTK 4.22+ headers:

```sh
c++ -std=c++20 -fsyntax-only -x c++ -DFLUTTER_LINUX_GTK4=1 \
  $(pkg-config --cflags gtk4) \
  engine/src/flutter/shell/platform/linux/fl_gtk4_runtime_api.h
```

Repeat with each supported header environment. Old headers cannot validate
members they do not declare. Header checks, protected-tail runtime tests, and
`--check-selection` AT-SPI dispatch tests cover different risks; none alone
establishes compatibility with an untested GTK release or architecture.

## Real-engine gradient pixels

This is an opt-in GPU rendering regression, not a software widget golden. Create
an ordinary small GTK4 app with this checkout, replace its main.dart with the
fixture, and build it against the local engine:

```sh
bin/flutter create --platforms=linux --linux-gtk=gtk4 --project-name=gtk4_gradient_probe /tmp/gtk4_gradient_probe
cp engine/src/flutter/shell/platform/linux/testing/fixtures/gradient_scene.dart /tmp/gtk4_gradient_probe/lib/main.dart
# Run from /tmp/gtk4_gradient_probe, using this checkout's absolute bin/flutter:
flutter --local-engine-src-path=/path/to/flutter/engine/src \
  --local-engine=host_debug_unopt --local-engine-host=host_debug_unopt \
  build linux --linux-gtk=gtk4 --debug
```

The fixture renders a short vertical control, a wider horizontal gradient, a
translucent rounded diagonal gradient, and a large-radius radial gradient. It
exports RepaintBoundary GPU image readback when GRADIENT_PROBE_OUTPUT is set by
the driver, then scrolls by 40 logical pixels. The driver asserts RGBA samples
against interpolation and alpha-compositing expectations, resizes the actual
window, and verifies samples again. It also checks startup logs agree with the
requested Impeller mode and records the loaded engine library hash.

```sh
python3 engine/src/flutter/shell/platform/linux/testing/run_gtk4_gradient_test.py \
  /tmp/gtk4_gradient_probe/build/linux-gtk4/x64/debug/bundle/gtk4_gradient_probe \
  --engine-dir=engine/src/out/host_debug_unopt --output=/tmp/gradient-pixels.json
```

Requires Pillow already installed locally, Xvfb, X11, and a runnable fixture
bundle. The driver creates a private D-Bus/display session. Options:
`--impeller=false`, `--gsk-renderer=gl`, `--gsk-renderer=vulkan`, and `--scale=2`.
The requested GTK backend may fall back; `gsk_observed` is only populated if the
runner logs `GRADIENT_GSK <G_OBJECT_TYPE_NAME(gtk_native_get_renderer(...))>`.
Do not infer actual GTK backend solely from the requested setting.

The principal assertion is engine-side image readback before GTK presentation.
It proves gradient rasterization, scrolling and resize behavior on the tested
engine; it does not assert exact final-screen pixels, GPU performance, arbitrary
scales, external-texture behavior, or an unavailable Vulkan GTK backend.

## GTK4 fractional-scale conversion and metrics

`FlGtk4ScalingTest.*` is part of `flutter_linux_gtk4_unittests`. It verifies
100%, 125%, 150%, 175%, and 200% backing dimensions, nearest-pixel rounding for
odd logical sizes, and fractional DPR/constraints sent through the engine's
window-metrics API. The scale-change sequence keeps logical size fixed and
includes changes whose rounded-up integer scale remains 2.

Run with the normal GTK4 unit-test environment and
`--gtest_filter=FlGtk4ScalingTest.*`. The local `run_gtk_tests.sh --gtk4` helper
includes this suite in its default filter.

These are conversion and engine-boundary tests using the mock engine. They do
not exercise GDK's scale discovery/notifications, physical render-target
allocation, input conversion, native accessibility geometry, or moving a
window between Wayland monitors. The X11 geometry and gradient probes still
only support integer scales 1 and 2; passing these unit tests does not establish
end-to-end fractional-scale support.

## GTK4 fractional scaling on Wayland

The opt-in Wayland driver runs a private headless Sway compositor with two
outputs. It exercises 100%, 125%, 150%, 175%, upward/downward changes that retain
integer scale 2, moves between differently scaled outputs, and odd-sized resize
at 150% (including resize without a scale change), and monitor moves with the
same DPR. The real GTK4 view verifies
window metrics, display metadata/IDs, texture natural size, native accessible bounds, mouse-event
coordinates, wheel-event coordinates/deltas, and scale-notification teardown.

```sh
python3 engine/src/flutter/shell/platform/linux/testing/run_gtk4_wayland_scale_test.py \
  engine/src/out/host_debug_unopt/flutter_linux_gtk4_unittests \
  --output=/tmp/gtk4-wayland-scale.json
```

Requires Sway/wlroots with headless and pixman support, `swaymsg`, `cc`,
`wayland-scanner`, and Wayland client development libraries already installed.
The test vendors the MIT-licensed virtual-pointer protocol from
[swaywm/wlr-protocols](https://github.com/swaywm/wlr-protocols/blob/master/unstable/wlr-virtual-pointer-unstable-v1.xml).
No protocol files or dependencies are downloaded by the driver. Add `--sized-to-content` to exercise secondary views with unbounded sizing
constraints. Add `--atspi` to query the semantics label bounds through a private
AT-SPI bus; this requires Python GI/Atspi and the local accessibility services.
The local test helper exposes this gate as `./run_gtk_tests.sh --gtk4 --wayland-scale`.

For real raster coverage, build the gradient fixture described above, with an
undecorated runner window titled `Flutter fractional scale probe` and logical
default size 1001 × 603. The Wayland rendering driver enables physical-pixel
readback through `GRADIENT_PROBE_PHYSICAL=1` and checks Flutter DPR/physical size,
readback dimensions, and gradient pixels throughout the same twelve phases:

```sh
python3 engine/src/flutter/shell/platform/linux/testing/run_gtk4_wayland_render_scale_test.py \
  /tmp/gtk4_fractional_render_probe/build/linux-gtk4/x64/debug/bundle/gtk4_password_probe \
  --engine-dir=engine/src/out/host_debug_unopt \
  --output=/tmp/gtk4-wayland-render-scale.json
```

Use the actual fixture binary path; its filename depends on its project name.
`--impeller=false` runs the same scene with Skia. `--gsk-renderer=gl` or
`--gsk-renderer=vulkan` selects GTK presentation; reports record the observed
renderer when the diagnostic runner emits `GRADIENT_GSK`. This driver additionally
requires locally installed Pillow. It verifies the mapped engine hash rather
than assuming `LD_LIBRARY_PATH` took effect.

This is headless compositor coverage. It does not establish hardware-GPU text
sharpness, physical touchscreen/touchpad behavior, AT-SPI event ordering,
external-texture behavior, or every older GTK runtime. The optional direct
subsurface path falls back to GTK texture presentation at fractional scales;
its native Wayland buffer scale remains integer-only.
