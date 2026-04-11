# GTK4 Accessibility Plan

This document defines the GTK4 accessibility strategy for the Linux engine.
The current Linux accessibility implementation is GTK3/ATK-based. GTK4 build
validation has shown that this stack cannot simply be compiled forward under
GTK4: it depends on `atk/atk.h`, `AtkPlug`/`GtkSocket`, and GTK3-era GDK APIs
that are not present in the GTK4 sysroot or runtime model.

The goal here is to make the GTK4 port technically honest:
- GTK4 builds should not depend on GTK3 accessibility code.
- GTK4 should eventually expose Flutter semantics through a GTK4-native
  accessibility path.
- Until that exists, the branch should fail gracefully rather than pretend that
  ATK-based accessibility still works.

## Current state

GTK3 accessibility is implemented by:
- `engine/src/flutter/shell/platform/linux/fl_accessibility_handler.*`
- `engine/src/flutter/shell/platform/linux/fl_view_accessible.*`
- `engine/src/flutter/shell/platform/linux/fl_accessible_node.*`
- `engine/src/flutter/shell/platform/linux/fl_accessible_text_field.*`
- `engine/src/flutter/shell/platform/linux/fl_socket_accessible.*`

This stack assumes:
- ATK object types are available.
- The view accessibility root can be exported through `AtkPlug`.
- The widget-side embedding path uses GTK3 accessibility plumbing.

GTK4 currently has no equivalent implementation in this branch.

## Problem statement

We need to answer two separate questions:

1. What should GTK4 do right now?
2. What is the long-term GTK4 accessibility architecture?

These cannot be solved with one build-flag change. The first is a stabilization
task. The second is a product and engine design task.

## Immediate policy

Until a GTK4-native implementation exists:
- Do not compile GTK3 accessibility sources into the GTK4 engine build.
- Do not instantiate GTK3 accessibility handlers from GTK4 engine startup.
- Do not require existing ATK-based Linux unit tests to compile under GTK4.
- Be explicit that GTK4 accessibility is currently unimplemented or partial.

This keeps the branch buildable and prevents hidden GTK3 dependencies from
leaking back into GTK4.

## Target architecture

The GTK4 implementation should be semantics-driven, not ATK-object-port-driven.

Recommended shape:
- Keep `flutter/accessibility` channel handling as the engine-facing entry
  point.
- Replace the ATK view/object tree with a GTK4 accessibility bridge owned by
  the view.
- Map Flutter semantics updates onto GTK4 accessibility roles, states,
  properties, relations, and announcements.
- Keep the Linux embedder’s public API stable where possible; avoid exporting
  GTK4 accessibility internals as part of the public `flutter_linux` surface.

That implies a new GTK4 path rather than a direct port of:
- `FlViewAccessible`
- `FlAccessibleNode`
- `FlAccessibleTextField`

## Proposed phases

### Phase 0: Stabilize the build

Goal: GTK4 compiles without pulling GTK3 accessibility code into the graph.

Required changes:
- Guard GTK3 accessibility sources out of GTK4 in
  `engine/src/flutter/shell/platform/linux/BUILD.gn`.
- Guard engine startup wiring in
  `engine/src/flutter/shell/platform/linux/fl_engine.cc`.
- Keep GTK3-only accessibility setup in
  `engine/src/flutter/shell/platform/linux/fl_view.cc`.
- Convert GTK4-incompatible Linux unit-test targets to GTK3-only coverage until
  GTK4-safe mocks exist.

Exit criteria:
- `ninja -C engine/src/out/host_debug_unopt build.ninja.stamp` succeeds.
- Focused GTK4 Linux engine build gets past accessibility source/link errors.

### Phase 1: Define a GTK4 accessibility bridge

Goal: establish the replacement ownership model.

Deliverables:
- New GTK4-specific accessibility bridge files under
  `engine/src/flutter/shell/platform/linux/`.
- A clear owner for:
  - semantics root
  - node lookup / caching
  - text-field specialization
  - announcements / live regions
- A decision on whether the bridge is attached directly to `FlView`,
  `render_area`, or another GTK4-native widget boundary.

Open design question:
- Should the GTK4 path maintain an explicit internal semantics tree mirroring
  the current ATK implementation, or should it translate updates directly onto
  GTK4 accessible objects with less retained state?

Recommendation:
- Keep an internal semantics tree. The existing Flutter semantics protocol is
  incremental and view-scoped; retaining state will make announcements, child
  updates, and text selection behavior more tractable.

### Phase 2: Semantics mapping

Goal: implement a minimum viable semantics-to-GTK4 translation.

Required capabilities:
- Root object creation for each `FlView`.
- Child hierarchy updates from `FlutterSemanticsUpdate2`.
- Node labels / names.
- Roles for common controls.
- Basic state mapping:
  - focused
  - enabled / disabled
  - selected
  - checked / checkable
  - editable / read-only
- Geometry updates sufficient for screen-reader hit testing.

Files likely affected:
- new GTK4 accessibility bridge files
- `engine/src/flutter/shell/platform/linux/fl_view.cc`
- `engine/src/flutter/shell/platform/linux/fl_engine.cc`
- `engine/src/flutter/shell/platform/linux/fl_accessibility_handler.*`

### Phase 3: Text and announcements

Goal: cover the semantics that were previously handled by
`FlAccessibleTextField` and `FlAccessibilityHandler`.

Required capabilities:
- text value updates
- selection updates
- editable-text operations
- announcements with politeness / assertiveness mapping where GTK4 supports it

This phase should explicitly document any behavior that cannot be represented
1:1 from the ATK implementation.

### Phase 4: Tests and CI

Goal: add GTK4-specific validation instead of trying to reuse all GTK3 tests.

Required changes:
- Add GTK4-safe mocks to
  `engine/src/flutter/shell/platform/linux/testing/mock_gtk.*`.
- Split tests into:
  - GTK3-only accessibility tests
  - GTK4-safe engine tests
  - GTK4 accessibility bridge tests
- Add CI validation that at minimum:
  - regenerates GN with `use_gtk4=true`
  - builds `libflutter_linux_gtk.so`
  - runs GTK4-safe Linux tests

Do not block GTK4 on porting every ATK test verbatim. Some current tests are
proving GTK3 implementation details, not the GTK4 contract we actually need.

## Interim implementation rules

Until the GTK4 bridge exists:
- No new GTK4 code should include `atk/atk.h`.
- No new GTK4 code should depend on `FlViewAccessible`, `FlAccessibleNode`, or
  `FlAccessibleTextField`.
- `flutter_linux_unittests` should remain GTK3-only if the alternative is
  dragging GTK3/ATK dependencies into the GTK4 build.
- Build fixes should prefer explicit GTK3/GTK4 source separation over fragile
  macro tricks in shared headers.

## Concrete next steps

1. Finish removing unconditional GTK3 accessibility wiring from GTK4 engine
   startup and view setup.
2. Decide the temporary GTK4 behavior:
   document accessibility as unimplemented, or add a no-op bridge with clear
   TODOs.
3. Introduce a GTK4 accessibility bridge skeleton with owned files and type
   names, even before feature-complete behavior lands.
4. Add one focused GTK4 build validation command to CI for the Linux engine.
5. Add one focused GTK4 accessibility design test once the skeleton exists.

## Non-goals for the first GTK4 accessibility pass

- Perfect parity with every ATK role and state.
- Porting all GTK3 accessibility tests unchanged.
- Preserving the exact `AtkPlug`/`GtkSocket` model under GTK4.

The first pass should optimize for correctness of architecture and clear
forward progress, not for superficial parity with the GTK3 implementation.
