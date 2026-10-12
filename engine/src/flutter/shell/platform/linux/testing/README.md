# Linux GTK compatibility tests

GTK3 and GTK4 unit tests are built as separate targets. They must not load both
GTK major versions into one process. Build the GTK4 tests from the repository root:

```sh
autoninja -C engine/src/out/host_debug_unopt flutter_linux_gtk4 flutter_linux_gtk4_unittests
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
The JSON records GTK/GLib versions, scale, queried rectangles and the binary hash.

This tests Component geometry with a mocked engine. It does not establish
screen-coordinate support, clipping/hit testing, text character extents,
Wayland behavior, arbitrary fractional desktop scaling, or real Dart layout.

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
