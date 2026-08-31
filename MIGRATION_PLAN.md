# Flutter Android Embedder Migration: Ultimate Master Plan

This document represents the synthesized blueprint for migrating the Flutter Android Embedder to the public C Embedder API (`embedder.h`). It guarantees 100% feature parity without regressions by ensuring all capabilities (including advanced graphics and Add-to-App spawning) are fully integrated before legacy deletion.

## 1. Architectural Guardrails (The Invariants)

1. **Zero-Regression Feature Parity**: All existing features—including Vulkan External Textures and Add-to-App multi-engine spawning—MUST be fully ported to the new Embedder API *before* the legacy code is deleted.
2. **Strict C-ABI Protection (Opaque Handles)**: `embedder.h` must remain strictly OS-agnostic. Android-specific OS constructs (`AHardwareBuffer`) must be modeled as opaque handles (e.g., `void* os_handle`) within universal structs, or strictly confined to separate OS-specific extension headers. Do NOT shatter the standard C-ABI.
3. **JNI Routing Boundary & JvmInvoker**: The structural rollout flip (`if (IsEmbedderEnabled())`) MUST occur natively inside the raw JNI boundary function. If true, the `JniDelegate` handles the call, but it MUST be injected with an abstracted `JvmInvoker` interface. This prevents the raw JNI boundary from becoming a monolithic god-class and allows host tests to inject a mocked `JvmInvoker` to test JVM callback logic.
4. **Dynamic Decoupling & Host Test Safety**: Use `dlsym`/`dlopen` wrapped in an `OSLibraryLoader` interface for Android native bindings (like `AChoreographer`, `AHardwareBuffer`). This MUST be present before any Android-specific graphics are implemented to protect desktop CI.
5. **Perfetto Tracing Mandate**: All multi-threaded implementations, JNI asynchronous routing bounds, and C++ callbacks (e.g., `AChoreographer`, Engine Spawn threading) MUST be instrumented with Perfetto trace events (`fml/trace_event.h`). Perfetto traces must be used to validate execution correctness and identify lifecycle or pacing bugs.
6. **Pre-Emptive GN Shield**: Create a strict `flutter_embedder_native` GN target in Phase 1 that explicitly forbids internal UI/Skia headers, ensuring all new development is structurally validated from Day 1.
7. **Multi-Platform GN Dependency & Include Discipline**: Any embedder or platform layer referencing Impeller display list or other subsystem headers (e.g., `aiks_context.h`, `dl_image_impeller.h`) MUST explicitly declare the corresponding GN target dependencies (e.g., `//flutter/impeller/display_list`) in `deps`/`public_deps` in `BUILD.gn`. All changes must pass strict `gn check` across all platform configurations (including Fuchsia, Android, Linux, iOS, macOS, Windows) to prevent build failures on strict CI targets.

## 2. Sequencing Rules (Correcting Oversights)

- **Rule 1: Virtualization & Routing First**: The JNI routing logic (`if/else`), `JniDelegate` adapter (with `JvmInvoker`), and `OSLibraryLoader` must be implemented in Phase 1 BEFORE subsystem logic.
- **Rule 2: Complete Flag Eradication**: Phase 5.2 must completely eradicate the rollout flag from the Java/C++ API surface and obliterate the `if/else` conditional entirely. Hardcode unconditional routing to the new Embedder API to prevent downstream failures.
- **Rule 3: Multi-Backend Matrix Testing**: All tests must utilize Parameterized Tests (`TEST_P`) across backends.

---

## 3. The Phased Blueprint

### Phase 1: Foundations, Safety Nets, and C-API Prep
* **1.1 Test Matrix**: Wire up `TEST_P` logic.
* **1.2 Pre-Emptive GN Quarantine**: Create `flutter_embedder_native` target dependent strictly on `embedder.h`.
* **1.3 JNI DI Interface & Inline Routing**: Implement `if (Flags.isEmbedderApiInputEnabled())` inside the raw JNI boundary. Inject `JvmInvoker` into `JniDelegate` for abstracted JVM callbacks.
* **1.4 Dynamic Virtualization**: Implement `OSLibraryLoader` wrapper to shield desktop host tests.
* **1.5 C-API Extension (Vulkan)**: Expand `embedder.h` with opaque cross-platform abstractions for Vulkan External Textures.
* **1.6 C-API Extension (AHardwareBuffer)**: Expand `embedder.h` with opaque abstractions for Android `AHardwareBuffer` zero-copy textures.
* **1.7 C-API Extension (Engine Spawn)**: Expand `embedder.h` with `FlutterEngineSpawn` support for Add-to-App capabilities.
* **1.8 C-API Extension (Dart Deferred Components)**: Expand `embedder.h` with `FlutterEngineLoadDartDeferredLibrary` and corresponding struct configurations to map Play Feature Delivery components safely.
* **1.9 C-API Extension (Screenshot API)**: Expand `embedder.h` with `FlutterEngineScreenshot` and `FlutterEngineFreeScreenshot` to synchronously capture raster bitmaps across the boundary.
* **1.10 C-API Extension (Raster Context Hooks)**: Expand `FlutterProjectArgs` with `raster_thread_context_make_current` and `clear_current` to explicitly route Thread/EGL context lifetimes.
* **1.11 C-API Extension (Thread Priorities)**: Expand `FlutterProjectArgs` with `custom_task_runners` mapping Android's `ALooper` and strict thread priorities (e.g. `PRIORITY_DISPLAY`) onto the backend.

### Phase 2: Decoupled Subsystems
* **2.1 Asset Resolver**: Adapt `APKAssetProvider`.
* **2.2 Dart Callbacks**: Implement `FlutterEngineGetCallbackInformation` hook.
* **2.3 Image Generators**: Hook `AndroidImageGenerator` to `FlutterEngineRegisterImageDecoder`.
* **2.4 Mutator Translation**: Implement `AndroidMutatorsMapper`.
* **2.5 Accessibility & Semantics**: Wire the Android accessibility bridge tree native updates.
* **2.6 Platform Views**: Wire `AndroidPlatformView` and `PlatformViewsController` integrations.
* **2.7 Window Metrics Translation**: The C-API uses `FlutterEngineSendWindowMetricsEvent` to handle display DPI, padding, and cutouts. Route Java metrics here to safely drop `android_display.cc`.
* **2.8 AChoreographer VSync Routing**: Utilize the Phase 1.4 Virtualization `OSLibraryLoader` to capture `AChoreographer` callbacks and route them into `FlutterProjectArgs::vsync_callback` to fix 120Hz frame pacing before legacy files drop.
* **2.9 Global VM Initialization (`flutter_main.cc`)**: Migrate global startup (AOT snapshot mapping, ICU data mounting) out of legacy Android singletons into the public `FlutterEngineInitialize` API.

### Phase 3: Advanced Graphics & Multi-Engine Integration
* **3.1 AHardwareBuffer**: Wire the Android implementation to the Phase 1 opaque hooks via `OSLibraryLoader`.
* **3.2 Vulkan External Textures**: Wire the Android Vulkan instances relying on the `OSLibraryLoader` virtualization.
* **3.3 SurfaceControl HCPP**: Add dual-mode UI presentation natively into the new pipeline.
* **3.4 Add-to-App Multi-Engine**: Wire `FlutterEngineGroup` natively to `FlutterEngineSpawn`. Java wrappers must be explicitly wired with a JNI `PhantomReference` or `Cleaner` registry catching GC events to route `FlutterEngineShutdown` and prevent pointer leaks.

### Phase 4: E2E Parity
* **4.1 CI E2E Harness**: Verify 100% test passing on `dev/integration_tests/channels`.

### Phase 5: Emancipation (The Purge)
* **5.1 Default Flip**: Change the default settings fallback to `true`.
* **5.2 Legacy Deletion (Subsystems)**: Delete legacy classes for Asset, Callback, Image, and Mutators.
* **5.3 Legacy Deletion (Platform Views & Semantics)**: Purge legacy accessibility and platform view hierarchies.
* **5.4 Legacy Deletion (Graphics Pipeline)**: Delete `android_context`, `external_view_embedder`, and `android_surface`.
* **5.5 Flag Obliteration**: Obliterate the `IsEmbedderEnabled` flag entirely and hardcode unconditionally to the new Embedder API.
* **5.6 Final GN Integration**: Migrate `flutter_embedder_native` into `flutter_shell_native` AND explicitly purge all legacy UI/Skia dependencies from `flutter_shell_native`'s `BUILD.gn` to prevent Post-Migration Relapse.

---

## 4. Key Architectural Decisions & Rationale

### 4.1 Decision 1: Native C-ABI Quarantine vs Direct Engine C++ Internal Linkage
- **Context & Decision**: Route all Android platform shell native operations strictly through the public C-ABI (`embedder.h`) with opaque types and an isolated GN target (`flutter_embedder_native`), strictly forbidding any direct C++ `#include` of internal Engine headers (`//flutter/flow`, `//flutter/skia`, `//flutter/lib/ui`, `//flutter/impeller`).
- **Reasoning**:
  - Enforces strict modular separation between the platform shell (Android Java/JNI layer) and the core Flutter engine.
  - Enables comprehensive desktop host unit testing (`flutter_embedder_native_unittests`) on macOS, Linux, and Windows without initializing the full engine stack or GPU pipelines.
  - Prevents internal engine refactorings (e.g., changes in Skia, Impeller, or Flow layer classes) from breaking the Android embedding.
  - Establishes a clean, stable boundary that aligns Android with other embedders (Windows, Linux, macOS, Custom Embedders).
- **Alternatives Considered**:
  - **Alternative A: Direct Engine C++ Internal Linkage** (`flutter::Shell`, `flutter::Rasterizer`, `flutter::Engine` direct usage).
    - *Pros*: Faster initial implementation; avoids C-ABI struct conversions, opaque handle mapping, and proc table indirections; allows passing C++ smart pointers (`fml::RefPtr`, `sk_sp`) directly across boundaries.
    - *Cons*: Tightly couples the Android shell to internal engine headers; causes build breaks whenever internal Engine classes change; leaks graphics backend internals into Java JNI glue; prevents running host unit tests without mocking massive chunks of the engine runtime.
  - **Alternative B: Semi-Private C++ Internal Header Interface**.
    - *Pros*: Allows richer C++ abstractions (templates, classes) than a pure C-ABI while maintaining an abstract interface.
    - *Cons*: High risk of header leakage; creates a "second-class" private API that diverts maintenance effort from the public `embedder.h`; lacks the ABI stability guarantees of a C API.

### 4.2 Decision 2: Dynamic Library Virtualization (`OSLibraryLoader::LoadDynamicLibrary`) vs Static NDK Linkage
- **Context & Decision**: Abstract all Android NDK symbol resolution (`libandroid.so`, `libvulkan.so`, `AChoreographer`, `AHardwareBuffer`, `ASurfaceControl`) behind a unified `OSLibraryLoader` interface using the `LoadDynamicLibrary` method.
- **Reasoning**:
  - Android NDK features are gated across API levels (e.g., `AChoreographer_postFrameCallbackDelayed` in API 24, `AHardwareBuffer` in API 26, `ASurfaceControl` in API 29). Dynamic resolution prevents startup crashes on older API levels.
  - Crucially, it allows 100% desktop host unit testing on macOS (arm64/x86_64), Linux (x86_64), and Windows (MSVC x64) by injecting mock dynamic libraries and function tables into `OSLibraryLoader`.
  - The method is explicitly named `LoadDynamicLibrary` to prevent fatal Windows SDK macro collisions where `<libloaderapi.h>` defines `#define LoadLibrary LoadLibraryW`.
- **Alternatives Considered**:
  - **Alternative A: Static NDK Linkage in GN** (`-landroid`, `-lvulkan`).
    - *Pros*: Direct, simple function calls without function pointer typedefs, struct lookups, or wrapper layers.
    - *Cons*: Hard crashes at runtime when running on Android API levels below the introduced API of any linked symbol; completely prevents compiling or running host unit tests on non-Android host operating systems.
  - **Alternative B: Direct Unabstracted `dlopen()` / `dlsym()` Calls**.
    - *Pros*: Minimal code footprint without defining `OSLibraryLoader` interfaces or classes.
    - *Cons*: Cannot be intercepted or mocked in unit tests without dangerous global symbol hooking/interposition; duplicates dynamic loading boilerplate across every subsystem; leaks POSIX dynamic loading headers into cross-platform files.

### 4.3 Decision 3: Test Fixture Matrix Decoupling (`EmbedderAllBackendsTest` vs `EmbedderTestMultiBackend`)
- **Context & Decision**: Decouple general lifecycle and engine testing (`EmbedderAllBackendsTest` parameterized across Software, OpenGL, Vulkan, Metal) from GPU-specific image fixture tests (`EmbedderTestMultiBackend` / `EmbedderTestGlVk`).
- **Reasoning**:
  - Parameterized tests in GoogleTest (`TEST_P`) instantiate every test in a suite across all configured backend parameters.
  - Tests performing GPU pixel comparisons or Impeller texture operations require real or mock GPU contexts.
  - If general lifecycle tests and GPU image tests share a single fixture that includes `kSoftwareContext`, GPU image tests get instantiated with software rasterization, triggering assertion failures and crashing headless/software CI bots. Decoupling creates dedicated, isolated test suites with precise backend configuration matrices.
- **Alternatives Considered**:
  - **Alternative A: Unified Single Fixture `EmbedderTestMultiBackend` for All Embedder Tests**.
    - *Pros*: Single fixture class in `embedder_test.h`.
    - *Cons*: Forces GoogleTest to run software contexts against GPU-only pixel tests, breaking headless Linux bots, or forces excluding `kSoftwareContext` globally, which degrades test coverage for software fallback rendering.
  - **Alternative B: Runtime Backend Skipping with `GTEST_SKIP()`**.
    - *Pros*: Keeps single fixture class while skipping unsupported combinations dynamically.
    - *Cons*: Clutters test bodies with defensive branching; obscures real test regressions behind skipped tests; pollutes CI logs with noisy skip notifications.

### 4.4 Decision 4: Dual-Dispatch JNI Routing with Phase 5.5 Complete Flag Obliteration
- **Context & Decision**: Implement a dual-dispatch `JniRouter` with `isEmbedderApiInputEnabled()` during Phases 1–4, and completely eradicate the flag and delete all legacy code branches in Phase 5.5.
- **Reasoning**:
  - Dual-dispatch enables safe, incremental migration with side-by-side verification and zero downtime or trunk breakage during the multi-phase rollout.
  - However, retaining feature flags permanently results in architectural decay, double maintenance burden, cognitive friction, binary bloat, and subtle divergence bugs. Phase 5.5 hardcodes unconditional C-API routing and purges legacy paths completely.
- **Alternatives Considered**:
  - **Alternative A: Permanent Runtime Feature Flag Retention**.
    - *Pros*: Provides an indefinite emergency fallback mechanism in production apps.
    - *Cons*: Doubles native code footprint; requires every future Android engine change to be written and tested twice; prevents deleting thousands of lines of deprecated code; incurs runtime branching overhead on critical paths.
  - **Alternative B: Single "Big-Bang" Cutover Without Dual-Dispatch Routing**.
    - *Pros*: No need to write routing logic, `JniRouter`, or temporary adapter classes.
    - *Cons*: High-risk monolithic PR that is impossible to review effectively; breaks trunk stability during development; cannot incrementally validate subsystems.

### 4.5 Decision 5: Garbage Collection Lifetime Safety for Engine Spawning (Cleaner / PhantomReference)
- **Context & Decision**: Implement a JNI `PhantomReference` / `Cleaner` registry to catch JVM garbage collection of `FlutterEngine` instances and deterministically route native `FlutterEngineShutdown`.
- **Reasoning**:
  - In Add-to-App multi-engine architectures (`FlutterEngineGroup`), developers frequently create and discard `FlutterEngine` Java objects without explicitly calling `destroy()`.
  - Native engine instances allocate significant native heap memory, rasterizer threads, and EGL/Vulkan contexts. Relying on explicit `destroy()` alone causes catastrophic memory leaks in dynamic UI workflows.
  - Java `finalize()` is deprecated in Java 9+ and removed in modern JDKs, making `PhantomReference` / `Cleaner` the only robust, future-proof mechanism.
- **Alternatives Considered**:
  - **Alternative A: Rely Strictly on Explicit User Invocation of `FlutterEngine.destroy()`**.
    - *Pros*: Simplest implementation with zero JVM reference tracking overhead.
    - *Cons*: Highly error-prone; real-world Add-to-App apps inevitably leak native engines, threads, and GPU contexts when Java references are dropped.
  - **Alternative B: Override `Object.finalize()` in Java Engine Wrappers**.
    - *Pros*: Traditional Java object cleanup approach.
    - *Cons*: Deprecated since Java 9, causes GC pauses, suffers from object resurrection issues, and offers no ordering guarantees.

---

## 5. Traps, Pitfalls & Invariants to Look Out For

### 5.1 Multi-Platform Host Compilation & MSVC Header Traps
- **Forbidden POSIX Headers**: Never include POSIX-only headers (such as `<unistd.h>`) in shared or Android C++ files. Use `fml` utilities or standard C++ `<chrono>` and `<thread>` to ensure MSVC (Windows host builds) compiles cleanly.
- **Windows SDK Macro Collisions**:
  - `<windows.h>` and `<libloaderapi.h>` define aggressive preprocessor macros (e.g., `#define LoadLibrary LoadLibraryW`, `#define Yield ...`).
  - **Rule**: Never name C++ methods or symbols `LoadLibrary` or `Yield`. Always use disambiguated names such as `LoadDynamicLibrary` or `YieldProcessor`.
- **GoogleTest Function Pointer Streaming on MSVC**:
  - On MSVC, comparing function pointers with `EXPECT_EQ(fn_ptr1, fn_ptr2)` fails to compile with `-Wmicrosoft-cast` because GTest tries to stream the function pointer to `std::ostream`.
  - **Rule**: Always compare function pointers using `EXPECT_TRUE(fn_ptr1 == fn_ptr2)` or `EXPECT_FALSE(...)`.

### 5.2 Clang-Tidy Static Analysis Invariants
Strict Clang-Tidy analysis is enforced across all Android embedder source files. Ensure code adheres to the following rules:
- **`google-explicit-constructor`**: All single-argument and defaulted constructors must be marked `explicit` (e.g., `explicit EmbedderTestParam(...)`).
- **`performance-move-const-arg`**: Never call `std::move()` on `const` references or trivially copyable types (e.g., `const std::shared_ptr<T>&` or `std::optional<FlutterRendererConfig>`).
- **`performance-unnecessary-value-param`**: Non-trivial types (such as `std::shared_ptr<AndroidHardwareBuffer>`) must be passed by `const &` across JNI router and native delegates unless the receiver takes sink ownership.
- **`modernize-use-default-member-init`**: Do not redundantly initialize struct/class members in constructor initializer lists if an in-class default member initializer already exists.
- **`bugprone-unchecked-optional-access`**: Never dereference `std::optional` (`*opt` or `opt->val` or `opt.value()`) without guarding it via `if (opt.has_value())` or `ASSERT_TRUE(opt.has_value())`.
- **`clang-analyzer-optin.core.EnumCastOutOfRange`**: Never cast arbitrary out-of-range integer values to enum types in unit tests. Always use valid enum constants (e.g., `kFlutterSemanticsFlagIsButton`).
- **`clang-analyzer-optin.cplusplus.VirtualCall`**: Never call virtual methods (e.g., `GetHandle()`) inside class destructors, as the vtable is partially destroyed during teardown.
- **`readability-identifier-naming`**: Enum constants must follow standard PascalCase with a `k` prefix (e.g., `kR8G8B8A8Unorm`, `kD32Float`).
- **`performance-inefficient-vector-operation`**: Always call `vector.reserve(...)` before filling vectors in loops or spawning multithreaded workers.

### 5.3 Perfetto Tracing & Thread Safety Rules
- **Mandatory Perfetto Tracing**: Every entry point across the JNI routing boundary, asynchronous task runner posting, and external NDK callbacks (`AChoreographer`, Engine Spawn) MUST be instrumented with `TRACE_EVENT0("flutter", ...)` or `TRACE_EVENT1("flutter", ...)`.
- **Thread Verification**: Multi-threaded tests must verify synchronization and thread-safety invariants using std::atomic, promises, futures, and thread barriers. Never block the Flutter UI or raster threads.

### 5.4 Repository Static Analysis & Formatting Discipline
- **End-of-File Formatting (`[no-trailing-spaces]`)**: `dev/bots/analyze.dart` strictly forbids trailing blank lines (`\n\n`) at the end of files. All markdown, C++, and Dart files must terminate with exactly one single newline character (`\n`).
- **Linter & Analyzer Mandates**:
  - Run `bin/flutter analyze --flutter-repo` to verify zero Dart analysis issues.
  - Run `engine/src/flutter/ci/clang_tidy.sh` across modified C++ files to guarantee 100% clean static analysis.
  - Run `dart format` on all modified Dart code.
