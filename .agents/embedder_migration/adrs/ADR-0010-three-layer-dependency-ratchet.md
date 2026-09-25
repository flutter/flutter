# ADR-0010: Three-Layer Dependency Ratchet and CI Enforcement

## Status
ACCEPTED

## RFC 410 Cross-Reference
Section: *Phase 4: Build Decoupling and Legacy Class Purge* -> *The Dependency Ratchet Mechanism*

## Context & Problem Statement
In a monorepo with high commit velocity, multi-quarter refactoring projects face persistent regression risks: developers resolving defects or adding features may inadvertently introduce new `#include` directives pointing to private engine headers, or add `// nogncheck` annotations to bypass visibility boundaries.

We need a multi-layered, automated defense mechanism to guarantee that dependency reduction is strictly monotonic throughout the migration, locking down all 98 baseline headers until reaching zero.

## Non-Negotiable Invariants
1. **Zero New Files with Internal Includes**: Only transitional legacy source files registered in `allowed_internal_headers.yaml` may include private engine headers.
2. **Zero New Internal Headers**: Any pull request introducing an unlisted `#include "flutter/..."` directive must be rejected by presubmit checks.
3. **Monotonic Decrement**: Whenever a refactor eliminates an internal include, the pull request must update `allowed_internal_headers.yaml` and decrement `total_allowed_internal_headers`. The ratchet locks the lower count permanently.
4. **No Escape Hatches**: Modifications introducing `// nogncheck` or widening GN target visibility are strictly rejected.
5. **Terminal Lock**: In Phase 4, the allowlist configuration is locked at `total_allowed_internal_headers: 0` permanently.

## Chosen Solution
Enforce an automated ratchet across three distinct architectural layers:
- **Layer 1: GN Target Partitioning (Compile-Time Firewall)**:
  `flutter_embedder_native_src` compiles with `defines = [ "FLUTTER_ENGINE_NO_PROTOTYPES" ]` and `check_includes = true`, restricting dependencies strictly to `embedder_headers`, `fml`, `common`, and `assets`.
- **Layer 2: Monotonic Header Inclusion Ratchet (`check_android_embedder_deps.py`)**:
  Automated presubmit script references `allowed_internal_headers.yaml` (tracking 98 baseline headers across 9 subsystems). Validates that all PRs touching `shell/platform/android/` obey the 4 presubmit rules.
- **Layer 3: Terminal Build Decoupling (Permanent Lock)**:
  Once `AndroidShellHolder` and `PlatformViewAndroid` are deleted in Phase 4:
  - `allowed_internal_headers.yaml` locks at 0 headers.
  - All internal GN dependencies (`//flutter/flow`, `//flutter/runtime`, `//flutter/shell/common`, `//flutter/impeller`, etc.) are purged from `shell/platform/android/BUILD.gn`.

## Rejected Alternatives & Rationale
- *Manual Code Review Enforcement*: Rejected because human reviewers and LLMs miss subtle internal includes during complex refactors, allowing regressions to slip through unnoticed.
- *Advisory/Warning CI checks*: Rejected because non-blocking warnings are routinely ignored under schedule pressure; only hard blocking presubmit errors guarantee monotonic reduction.

## Verification Contract
- Presubmit script `python3 shell/platform/android/check_android_embedder_deps.py` runs on all engine pull requests touching `shell/platform/android/`.
- CI test intentionally introducing an unlisted `#include` or `// nogncheck` asserts that presubmit fails and rejects the change.
