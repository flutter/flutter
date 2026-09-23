# ADR-0001: Pure Embedder API Client and Dynamic Proc Table Resolution

## Status
ACCEPTED

## RFC 410 Cross-Reference
Section: *Target Architecture and Design Principles* -> *Pure Embedder API Client (FLUTTER_ENGINE_NO_PROTOTYPES)*

## Context & Problem Statement
Currently, `shell/platform/android/` directly links to internal engine symbols and includes 98 internal headers across `//flutter/shell/common`, `//flutter/runtime`, `//flutter/flow`, and `//flutter/impeller`. This tight coupling prevents the Android embedder from compiling as an independent, modular client and allows internal engine refactors to break Android embedder code silently.

We must establish a strict compile-time firewall that prevents any C-API client code from directly linking against internal engine translation units or calling C-API functions via global static symbols.

## Non-Negotiable Invariants
1. **No Static Symbol Linkage**: All source files under `:flutter_embedder_native_src` must compile with `defines = [ "FLUTTER_ENGINE_NO_PROTOTYPES" ]`.
2. **Dynamic Resolution via Proc Table**: All calls to the Flutter Embedder C-API must dispatch strictly through the `FlutterEngineProcTable` pointer table populated via `FlutterEngineGetProcAddresses`.
3. **GN Include Checking**: GN must enforce `check_includes = true` on `:flutter_embedder_native_src`. Any inclusion of an undeclared header fails the build immediately.
4. **Opaque Engine Handle**: `FlutterEmbedderNative` must store the engine reference only as an opaque `FLUTTER_API_SYMBOL(FlutterEngine)` handle (`FlutterEngine`), never casting or inspecting underlying `flutter::Shell` internals.

## Chosen Solution
- Partition `shell/platform/android/BUILD.gn` into a dedicated source set: `source_set("flutter_embedder_native_src")`.
- Pass `defines = [ "FLUTTER_ENGINE_NO_PROTOTYPES" ]` to `:flutter_embedder_native_src`.
- Declare dependencies strictly on:
  - `//flutter/shell/platform/embedder:embedder_headers`
  - `//flutter/fml`
  - `//flutter/common`
  - `//flutter/assets`
- `FlutterEmbedderNative` initializes `FlutterEngineProcTable` during engine initialization and distributes references to modular subsystem components (`AndroidSurfaceControl`, `AndroidPlatformViewsController`, etc.).

## Rejected Alternatives & Rationale
- *Direct static symbol linking against `libflutter_engine.so`*: Rejected because static linking does not prevent accidental symbol leakage, increases binary export inflation, and bypasses dynamic proc table versioning.
- *Header inclusion without GN firewall*: Rejected because developers and LLMs inadvertently introduce `#include "flutter/shell/common/shell.h"` during maintenance unless blocked by compile-time rules.
- *Splitting into separate shared libraries (`libflutter_embedder.so` and `libflutter_engine.so`)*: Rejected because multiple `.so` binaries inflate APK size, increase dynamic linker lookup overhead on Android startup, and introduce complex shared library versioning hazards across Android API levels.

## Verification Contract
- Build target compiles cleanly with `check_includes = true` and `FLUTTER_ENGINE_NO_PROTOTYPES`.
- Any attempt to call `FlutterEngineRunInitialized(...)` directly without `embedder_api_.RunInitialized(...)` produces a compile-time undefined symbol error.
- Host unit tests in `flutter_embedder_native_unittests` verify proc table initialization.
