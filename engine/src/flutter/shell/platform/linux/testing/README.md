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

## Native AT-SPI activation

```sh
python3 engine/src/flutter/shell/platform/linux/testing/run_gtk4_atspi_action_test.py \
  engine/src/out/host_debug_unopt/flutter_linux_gtk4_unittests
```

This separate integration test needs a GTK runtime with native accessible-tree
support, PyGObject with Atspi introspection, `dbus-run-session`, Xvfb, `xauth`,
and the AT-SPI bus launcher and registry. It creates a private session/display,
finds its fixture by PID, and invokes the exported tap, directional scrolling,
and increase/decrease actions. The fixture asserts the resulting Flutter
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
and deletion-only changes, without whole-field or zero-length events. This flag can
be combined with `--check-focus`; neither check validates editable-text actions
or visual line wrapping.

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
