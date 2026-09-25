# ADR-0008: Multi-Engine Spawning (`FlutterEngineSpawn`) and Add-to-App

## Status
ACCEPTED

## RFC 410 Cross-Reference
Section: *Detailed Design* -> *Multi-Engine Spawning and Add-to-App (FlutterEngineSpawn)*

## Context & Problem Statement
Android Add-to-App architectures rely heavily on `FlutterEngineGroup` to spawn lightweight engine instances that share the Dart VM, isolate group, and shared cache. In the existing architecture, `AndroidShellHolder::Spawn` reached directly into private `shell_->Spawn(...)`.

The public C Embedder API lacked a spawn API, which prevented multi-engine groups from operating on Android without including private `//flutter/shell/common/shell.h` headers.

## Non-Negotiable Invariants
1. **Resource Sharing**: Spawned shells must share the parent engine's `AndroidContext` / Impeller device context (`VkInstance`, physical device, logical device, queue handles, pipeline cache, and texture pools) in addition to sharing the Dart VM and root isolate group.
2. **Initial Route Mounting**: `FlutterEngineSpawnConfig` must accept an `initial_route` parameter to ensure spawned isolates mount distinct route hierarchies immediately upon launch without an asynchronous message hop.
3. **Low Memory Footprint**: Spawning an additional engine from an existing group must add no more than ~180 KB of native memory overhead per isolate.
4. **Independent Failure Domains**: A long-running task or crash in one spawned view's root isolate must not stall the UI isolate of another view.

## Chosen Solution
- Introduce `FlutterEngineSpawn` and `FlutterEngineSpawnConfig` to `embedder.h`:
  ```c
  typedef struct {
    size_t struct_size;
    const char* entrypoint;
    const char* library_uri;
    const char* initial_route;
    const char* const* entrypoint_argv;
    int entrypoint_argc;
    void* user_data;
    const FlutterProjectArgs* project_args;
    const FlutterRendererConfig* renderer_config;
  } FlutterEngineSpawnConfig;

  FLUTTER_EXPORT
  FlutterEngineResult FlutterEngineSpawn(
      FLUTTER_API_SYMBOL(FlutterEngine) parent_engine,
      const FlutterEngineSpawnConfig* config,
      FLUTTER_API_SYMBOL(FlutterEngine)* spawned_engine_out);
  ```
- Implement `AndroidEngineGroup` in `:flutter_embedder_native_src`, routing `FlutterEngineGroup.createAndRunEngine` across JNI directly to `FlutterEngineSpawn`.

## Rejected Alternatives & Rationale
- *Allocating independent `FlutterEngine` instances from scratch*: Rejected because creating unshared engines duplicates the Dart VM, recompiles Impeller pipelines, and consumes 15–30 MB per instance instead of ~180 KB.
- *Single-isolate multi-view for all Add-to-App*: Rejected because distinct Android Activities or Fragments often require independent navigation stacks and isolated Dart global state. `FlutterEngineSpawn` and single-isolate multi-view (`FlutterEngineAddView`) address complementary needs.

## Verification Contract
- `FlutterEngineGroupTest` verifies spawning 10 concurrent engines with <2 MB total incremental memory overhead.
- Integration tests confirm that spawned engines launch with distinct `initial_route` paths and render independently.
- ASAN/LSAN checks verify zero memory leaks upon spawned engine destruction.
