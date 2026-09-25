---
name: proc-table-and-firewall-auditor
description: >
  Audits native C++ code in shell/platform/android/ for compliance with the GN compile-time firewall
  (defines = [ "FLUTTER_ENGINE_NO_PROTOTYPES" ]). Verifies that all Embedder C-API calls route strictly
  through FlutterEngineProcTable function pointers rather than direct static symbol linkage.

  When to use:
  - When writing or reviewing C++ source files in flutter_embedder_native_src.
  - When inspecting call sites into embedder.h functions (e.g. FlutterEngineInitialize, FlutterEngineRunInitialized).
  - To verify that no global C symbol linkage leaks into modular embedder components.
---

# Proc Table & GN Firewall Auditor Skill

Per **RFC 410.0000**, the modular Android embedder source set (`:flutter_embedder_native_src`) compiles with:
```gn
source_set("flutter_embedder_native_src") {
  defines = [ "FLUTTER_ENGINE_NO_PROTOTYPES" ]
  check_includes = true
  ...
}
```

This macro removes public C function prototypes from `embedder.h`, ensuring that:
1. No translation unit in `:flutter_embedder_native_src` can directly link against global C symbols (`FlutterEngineRun`, `FlutterEngineSendPointerEvent`, etc.).
2. All invocations must route through an initialized `FlutterEngineProcTable` pointer table populated via `FlutterEngineGetProcAddresses`.
3. An explicit compile-time error occurs if any file attempts to invoke global functions or include forbidden engine internal headers.

## Canonical Pattern for C-API Invocations

All modular components in `:flutter_embedder_native_src` (`AndroidSurfaceControl`, `AndroidPlatformViewsController`, `AndroidVsyncWaiter`, etc.) must receive a reference or pointer to the initialized `FlutterEngineProcTable`:

```cpp
// Correct: Invocation through proc table pointer
FlutterEngineResult result =
    embedder_api_.RunInitialized(engine_handle_);

if (result != kSuccess) {
  FML_LOG(ERROR) << "Failed to run initialized FlutterEngine: " << result;
}
```

```cpp
// INCORRECT: Direct static symbol call (Fails compile time with FLUTTER_ENGINE_NO_PROTOTYPES)
FlutterEngineResult result = FlutterEngineRunInitialized(engine_handle_);
```

## Audit Checklist

When reviewing newly written code in `flutter_embedder_native_src`:
- [ ] Ensure the file includes only public headers:
  ```cpp
  #include "flutter/shell/platform/embedder/embedder.h"
  #include "flutter/fml/logging.h"
  ```
- [ ] Verify that no internal engine headers (`flutter/shell/common/...`, `flutter/flow/...`, `flutter/runtime/...`) are included.
- [ ] Confirm that all C-API invocations use the `FlutterEngineProcTable` instance owned by `FlutterEmbedderNative`.
- [ ] Confirm that structs passed across the boundary initialize `struct_size = sizeof(TargetStruct)`.
