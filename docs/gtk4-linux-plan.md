# GTK4 Linux Default Plan

## Goal
Make the Linux desktop embedder use GTK4 by default while keeping a short transition path for existing GTK3-based apps and plugins.

## Scope
- Engine/Embedder: GTK4-backed Linux shell and `flutter_linux` surface.
- Tooling/Templates: update generated Linux runner (`my_application.*`, CMake, manifest).
- Tests/CI: validate GTK4 in bots and add regression coverage.

## Workstreams

### 1) Embedder + Engine
- Add a GTK4 backend in `engine/src/flutter/shell/platform/linux` (or port the existing GTK3 implementation).
- Replace GTK3-only APIs with GTK4 equivalents (e.g., container/child APIs, event controllers, header bar wiring).
- Ensure IME, clipboard, accessibility, windowing, and input paths still function under GTK4.
- Update build configuration to link against `gtk4`/`gdk-4` via pkg-config and document system deps.

### 2) Tooling + Templates
- Update Linux runner templates in `packages/flutter_tools/templates/app/linux-gtk4.tmpl/runner/`:
  - `my_application.cc.tmpl` and `my_application.h` to GTK4 APIs.
  - `CMakeLists.txt` to find and link GTK4 packages.
- Verify `template_manifest.json` stays consistent and new projects generate GTK4 code by default.
- Provide a migration note for existing apps: re-run `flutter create --platforms=linux .` or manually port the runner code.

### 3) Plugins + Platform Interfaces
- Audit `packages/` Linux plugins for GTK3-specific types or assumptions.
- Update plugin examples and registrant usage if API surface changes in `flutter_linux`.

### 4) Testing + CI
- Add/extend Linux integration tests in `dev/integration_tests/` to cover windowing, input, IME, and accessibility on GTK4.
- Wire a GTK4 Linux shard into `dev/bots/test.dart` (and `analyze.dart` if needed) so GTK4 is exercised in CI.
- Keep a temporary GTK3 shard for comparison until GTK4 stabilizes, then remove or demote.

## Test Plan (Proposed)
- **Engine unit tests (GTK4)**: build with `use_gtk4=true` and run `flutter_linux_unittests`.
- **Engine unit tests (GTK3)**: keep a parity run with `use_gtk4=false` during transition.
- **Tooling sanity**: `flutter create --linux-gtk=gtk4` and `--linux-gtk=gtk3` generate and build runner code.
- **Integration coverage**: run targeted tests in `dev/integration_tests/` (windowing, text input, a11y) against GTK4 builds.
- **CI shard**: add a Linux GTK4 shard to run the above in LUCI, keeping GTK3 for comparison until stable.

## Milestones
1. **Prototype**: GTK4 embedder builds and runs a minimal app (no regressions in windowing/input).
2. **Template switch**: new Linux apps generate GTK4 runner code by default.
3. **CI coverage**: GTK4 shard green for key test suites.
4. **Default rollout**: document GTK4 as default; keep GTK3 escape hatch for one cycle.

## Risks & Open Questions
- GTK4 API differences (container hierarchy, event handling, header bars) may require non-trivial refactors.
- Plugin ecosystem breakage: need a compatibility story and clear migration guidance.
- Distribution requirements: confirm minimum distro versions that ship GTK4.
