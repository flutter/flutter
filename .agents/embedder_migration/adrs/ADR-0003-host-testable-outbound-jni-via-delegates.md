# ADR-0003: Host-Testable Outbound JNI via `JniRouter`, `JniDelegate`, and Provider Interfaces

## Status
ACCEPTED

## RFC 410 Cross-Reference
Section: *Target Architecture and Design Principles* -> *Decomposition and Elimination of AndroidShellHolder* (`JniRouter`, `JniDelegate`, and `JvmInvoker`)

## Context & Problem Statement
Historically, native Android embedder C++ code made outbound JNI calls by directly manipulating `JNIEnv*` and calling JNI reflection methods (`env->CallVoidMethod(...)`) inlined within business logic. This pattern caused three major issues:
1. Tight coupling to a live Android OS JVM runtime, preventing unit tests from running on the host machine (Linux/macOS) without booting an Android device or emulator.
2. Fragile thread attachment: storing or passing raw `JNIEnv*` across task runners resulted in crashes because `JNIEnv*` is strictly thread-local.
3. Lack of mockability for hardware surfaces, Choreographer callbacks, and window transactions.

## Non-Negotiable Invariants
1. **Thread Attachment Invariant**: A `JNIEnv*` must **never** be cached across task runner hops or stored as a member variable. It must be acquired locally on the calling thread via `fml::jni::AttachCurrentThread()`.
2. **Exception Checking Invariant**: Every outbound JNI call must immediately invoke `fml::jni::CheckException(env)` before proceeding.
3. **Handle Scoping**: Global Java handles must be wrapped in `fml::jni::ScopedJavaGlobalRef`. Local references inside tight loops must be scoped with `fml::jni::ScopedJavaLocalFrame`.
4. **Host Testability**: All modular C++ embedder components must be completely constructible and testable on host Linux by injecting mock provider delegates.

## Chosen Solution
- Introduce an abstraction layer comprising `JniRouter`, `JniDelegate`, and `JvmInvoker`.
- Decouple outbound JNI interactions into narrow provider interfaces:
  - `FlutterJniProvider`: Outbound platform message delivery and lifecycle hooks.
  - `HardwareBufferProvider`: Zero-copy `AHardwareBuffer` queries.
  - `SurfaceControlProvider`: NDK/Java `SurfaceControl` mutations.
  - `SurfaceTransactionProvider`: Atomic `SurfaceControl.Transaction` commits.
  - `ChoreographerProvider`: Vsync frame pacing callbacks.
- In production, `JniDelegateImpl` implements these interfaces by invoking real JNI calls via `JvmInvoker`.
- In tests, `MockJniDelegate` provides deterministic in-memory stubs, allowing `flutter_embedder_native_unittests` to run on host Linux in ~1.5 seconds via:
  ```bash
  et test -c host_debug_unopt //flutter/shell/platform/android:flutter_embedder_native_unittests
  ```

## Rejected Alternatives & Rationale
- *Direct inlined JNI calls*: Rejected because it forces all testing onto physical Android devices or emulators, making TDD slow, flakier, and infeasible for rapid LLM iteration loops.
- *Robolectric-only testing*: Rejected because Robolectric tests Java code, but cannot validate native C++ embedder logic, memory allocations, or `embedder.h` proc table invocations.

## Verification Contract
- `flutter_embedder_native_unittests` compiles and executes on host Linux (`host_debug_unopt`) with 100% pass rate.
- AddressSanitizer (ASAN) and LeakSanitizer (LSAN) verify zero memory leaks or dangling JNI handle references during test execution.
