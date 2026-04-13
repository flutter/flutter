# Linux Accessibility Migration Plan

This document defines the Linux accessibility migration strategy for the
Flutter engine.

The current Linux accessibility implementation is GTK3/ATK-based. GTK4 build
validation has shown that this stack cannot simply be compiled forward under
GTK4: it depends on `atk/atk.h`, `AtkPlug`/`GtkSocket`, and GTK3-era GDK APIs
that are not present in the GTK4 sysroot or runtime model.

The long-term target is the work described in
`flutter/flutter#159460`: replace ATK usage with direct AT-SPI access on
Linux. The engine already has prior art in `flutter/engine#52355`, which added
an AT-SPI socket/plug export path. That change is relevant, but it should be
treated as an implementation reference or intermediate step, not necessarily as
the final architecture.

The migration goals are:
- GTK3 should be the first validation target for the new architecture.
- GTK4 should stop depending on the GTK3 accessibility stack.
- GTK4 should follow after the new Linux accessibility model is proven under
  GTK3.
- The branch should stay technically honest about what is implemented versus
  what is still a placeholder.

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

We need to answer three separate questions:

1. What is the long-term Linux accessibility architecture?
2. How do we prove that architecture without losing current behavior?
3. What should GTK4 do in the meantime?

These cannot be solved with one build-flag change. The first is an
architecture task. The second is a migration and testing task. The third is a
GTK4 stabilization task.

## Migration order

Recommended order:

1. Use GTK3 as the first implementation and validation target for the new Linux
   accessibility architecture.
2. Preserve existing GTK3 semantics behavior and as much of the current test
   coverage as possible while moving away from ATK-shaped internals.
3. Only after the model is proven under GTK3, add the GTK4 adapter.

This order is preferable because GTK3 already has working behavior and an
existing test corpus. GTK4 currently has no complete accessibility
implementation in this branch, so designing the architecture there first gives
less feedback and more ambiguity.

## Immediate policy

Until the new Linux accessibility implementation exists:
- Keep GTK3 accessibility behavior as the baseline to compare against.
- Do not compile GTK3 accessibility sources into the GTK4 engine build unless
  they are explicitly part of a transitional adapter.
- Do not instantiate GTK3 accessibility handlers from GTK4 engine startup.
- Do not require existing ATK-based Linux unit tests to compile under GTK4.
- Be explicit that GTK4 accessibility is currently partial or transitional.

This keeps the branch buildable and prevents hidden GTK3 dependencies from
leaking back into GTK4 while the larger migration is being designed.

## Target architecture

The Linux accessibility implementation should be semantics-driven, not
ATK-object-port-driven.

Recommended shape:
- Keep `flutter/accessibility` channel handling as the engine-facing entry
  point.
- Introduce a platform-neutral internal semantics model owned by the Linux
  embedder.
- Add platform adapters on top of that model rather than embedding ATK object
  design into the semantics core.
- Map Flutter semantics updates onto Linux accessibility roles, states,
  properties, relations, actions, and announcements through those adapters.
- Keep the Linux embedder’s public API stable where possible; avoid exporting
  Linux accessibility internals as part of the public `flutter_linux` surface.

That implies a new Linux accessibility path rather than a direct port of:
- `FlViewAccessible`
- `FlAccessibleNode`
- `FlAccessibleTextField`

For GTK3, the new adapter may temporarily reuse concepts from the existing
socket/plug integration or from `engine#52355`, but the semantics core should
not be shaped around ATK-only concepts.

## Proposed phases

### Phase 0: Stabilize GTK4 and isolate the old stack

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

### Phase 1: Define the Linux accessibility abstraction

Goal: establish the replacement ownership model before doing the platform port.

Deliverables:
- A semantics-owned Linux accessibility layer under
  `engine/src/flutter/shell/platform/linux/`.
- A clear split between:
  - accessibility channel handling
  - semantics state retention
  - platform adapter responsibilities
  - announcements / live-region behavior
- A documented relationship between:
  - current ATK-based GTK3 implementation
  - `engine#52355` AT-SPI socket/plug work
  - `flutter#159460` direct AT-SPI target

Open design question:
- Is the first non-ATK validation target:
  - a socket/plug-based AT-SPI export path, or
  - direct AT-SPI/D-Bus exposure?

Recommendation:
- Decide this explicitly before expanding GTK4 work. Do not let the branch
  drift into a hybrid model accidentally.

### Phase 2: Implement and validate GTK3 first

Goal: prove the new Linux accessibility model against the platform that already
has working behavior and tests.

Required capabilities:
- Preserve current semantics update flow.
- Preserve current announcement behavior.
- Preserve current text and selection behavior where feasible.
- Keep existing GTK3 accessibility tests passing, updating them only where they
  are coupled to ATK internals rather than observable behavior.

Files likely affected:
- `engine/src/flutter/shell/platform/linux/fl_accessibility_handler.*`
- `engine/src/flutter/shell/platform/linux/fl_view.cc`
- `engine/src/flutter/shell/platform/linux/fl_engine.cc`
- current GTK3 accessibility implementation files

### Phase 3: Add the GTK4 adapter

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

### Phase 4: Semantics mapping

Goal: implement a minimum viable semantics-to-platform translation, then finish
the GTK4 adapter.

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
- Linux accessibility abstraction files
- GTK4 accessibility bridge files
- `engine/src/flutter/shell/platform/linux/fl_view.cc`
- `engine/src/flutter/shell/platform/linux/fl_engine.cc`
- `engine/src/flutter/shell/platform/linux/fl_accessibility_handler.*`

### Phase 5: Text and announcements

Goal: cover the semantics that were previously handled by
`FlAccessibleTextField` and `FlAccessibilityHandler`.

Required capabilities:
- text value updates
- selection updates
- editable-text operations
- announcements with politeness / assertiveness mapping where GTK4 supports it

This phase should explicitly document any behavior that cannot be represented
1:1 from the ATK implementation.

### Phase 6: Tests and CI

Goal: validate the migration in the right order instead of treating GTK4 as the
first proof point.

Required changes:
- Preserve and adapt GTK3 accessibility tests first.
- Add GTK4-safe mocks to `engine/src/flutter/shell/platform/linux/testing/mock_gtk.*`.
- Split tests into:
  - GTK3 baseline accessibility tests
  - GTK4-safe engine tests
  - GTK4 accessibility bridge tests
- Add CI validation that at minimum:
  - exercises the GTK3 migration path
  - regenerates GN with `use_gtk4=true`
  - builds `libflutter_linux_gtk.so`
  - runs GTK4-safe Linux tests

Do not block GTK4 on porting every ATK test verbatim. Some current tests are
proving GTK3 implementation details, not the cross-platform Linux
accessibility contract we actually need.

## Interim implementation rules

Until the new Linux accessibility model exists:
- No new migration code should deepen ATK coupling unless it is explicitly part
  of the GTK3 transitional adapter.
- No new GTK4 code should include `atk/atk.h`.
- No new GTK4 code should depend on `FlViewAccessible`, `FlAccessibleNode`, or
  `FlAccessibleTextField`.
- `flutter_linux_unittests` should remain GTK3-only if the alternative is
  dragging GTK3/ATK dependencies into the GTK4 build.
- Build fixes should prefer explicit GTK3/GTK4 source separation over fragile
  macro tricks in shared headers.

## Concrete next steps

1. Decide whether the first migration target is the `engine#52355`
   socket/plug model or direct AT-SPI/D-Bus.
2. Convert this plan into a Linux-wide accessibility plan of record, with GTK3
   first and GTK4 second.
3. Use GTK3 to validate the new accessibility abstraction while preserving
   current semantics behavior and tests.
4. Keep GTK4 isolated from GTK3 accessibility code during that work.
5. Once GTK3 behavior is proven, port GTK4 onto the same abstraction.

## Non-goals for the first migration pass

- Perfect parity with every ATK role and state.
- Designing the final Linux accessibility architecture around GTK4-only needs.
- Porting all GTK3 accessibility tests unchanged if they are ATK-internal
  rather than behavior-based.
- Assuming `engine#52355` and `flutter#159460` are identical tasks.

The first pass should optimize for correctness of architecture, preservation of
GTK3 behavior, and a clean path to GTK4, not for superficial parity with the
existing ATK object model.
