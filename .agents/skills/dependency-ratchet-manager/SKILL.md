---
name: dependency-ratchet-manager
description: >
  Audits and enforces the monotonic reduction of internal engine headers in the Android embedder
  (shell/platform/android/) per RFC 410.0000. Validates incoming changes against allowed_internal_headers.yaml
  (tracking 98 baseline headers down to 0) and prevents dependency regressions.

  When to use:
  - When modifying any files under engine/src/flutter/shell/platform/android/.
  - When refactoring components to eliminate private engine header inclusions.
  - Before committing or submitting PRs in the android-embedder-migration-v10 chain.
---

# Dependency Ratchet Manager Skill (RFC 410 Aligned)

This skill enforces the 3-layer dependency firewall established in **RFC 410.0000** for the Flutter Android embedder:
1. **Layer 1: GN Target Partitioning**: Isolates pure C-API code in `flutter_embedder_native_src` with `defines = [ "FLUTTER_ENGINE_NO_PROTOTYPES" ]` and strict dependencies.
2. **Layer 2: Monotonic Header Inclusion Ratchet**: Enforces continuous decrement of the 98 allowed internal engine headers tracked in `allowed_internal_headers.yaml`.
3. **Layer 3: Terminal Build Decoupling**: Permanent lock at `total_allowed_internal_headers: 0` once legacy classes are purged in Phase 4.

## Baseline Subsystems & Header Allocation (98 Headers Total)

| Subsystem | Baseline Count | Direct GN Dependencies | Key Internal Headers Blocked |
| :--- | :--- | :--- | :--- |
| **Impeller & Graphics** | 29 | `//flutter/impeller` | `renderer/backend/vulkan/context_vk.h`, `surface_context_vk.h` |
| **Platform Views (Flow)** | 2 | `//flutter/flow` | `flow/embedded_views.h`, `flow/surface.h` |
| **External Textures** | 5 | `//flutter/common/graphics` | `common/graphics/texture.h`, `gl_context_switch.h` |
| **Engine Core & Shell** | 11 | `//flutter/shell/common` | `shell/common/shell.h`, `thread_host.h`, `platform_view.h` |
| **UI & Messages** | 5 | `//flutter/lib/ui` | `lib/ui/window/platform_message.h`, `callback_cache.h` |
| **Dart Runtime & VM** | 2 | `//flutter/runtime` | `runtime/dart_vm.h`, `runtime/dart_service_isolate.h` |
| **Asset Management** | 1 | `//flutter/assets` | `assets/asset_resolver.h` |
| **GPU Backends** | 5 | `//flutter/shell/gpu` | `gpu_surface_gl_impeller.h`, `gpu_surface_vulkan_impeller.h` |
| **FML & Threading** | 24 | `//flutter/fml` | `fml/raster_thread_merger.h`, `fml/task_runner.h` |

## Presubmit Enforcement Rules

Any PR modifying `shell/platform/android/` must pass the four deterministic rules:

1. **Zero New Files**: Only transitional legacy files listed in `allowed_internal_headers.yaml` may contain internal engine includes. Any inclusion in a new file fails immediately.
2. **Zero New Headers**: New `#include "flutter/..."` directives not in the baseline allowlist fail presubmit, requiring the functionality to be routed through `embedder.h`.
3. **Monotonic Decrement**: When a refactor eliminates an internal header, the PR must remove it from `allowed_internal_headers.yaml` and decrement `total_allowed_internal_headers`. The ratchet locks the lower count permanently.
4. **No Escape Hatches**: The linter parses `shell/platform/android/BUILD.gn` and rejects any modifications introducing `// nogncheck` or widening GN target visibility.

## Verification Workflow

Run the audit check against current changes:
```bash
python3 shell/platform/android/check_android_embedder_deps.py
```
If an internal header was removed, decrement the counter in `allowed_internal_headers.yaml` before staging your commit.
