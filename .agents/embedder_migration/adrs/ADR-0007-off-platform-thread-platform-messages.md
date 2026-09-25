# ADR-0007: Off-Platform-Thread Platform Message Routing (`FlutterPlatformMessageCallback2`)

## Status
ACCEPTED

## RFC 410 Cross-Reference
Section: *Detailed Design* -> *Platform Channel Messaging, Background Handlers, and Task Queues*

## Context & Problem Statement
In the existing Android architecture, `PlatformMessageHandlerAndroid::DoesHandlePlatformMessageOnPlatformThread()` returns `false` to permit message dispatch from arbitrary threads. In contrast, desktop embedders using `embedder.h` return `true`, enforcing that all platform messages hop to the platform thread before dispatch.

Forcing mobile platforms to conform to desktop's `true` model would cause severe performance regressions:
1. Plugins handling high-bandwidth or compute-heavy workloads (camera frame streams, SQLite queries, cryptography) register background task queues via `BinaryMessenger.makeBackgroundTaskQueue()`. Forcing an intermediate hop through the Android main `Looper` causes main-thread contention and UI jank.
2. If the Android main thread is busy measuring views or handling input, background message execution stalls behind that work (head-of-line blocking).

## Non-Negotiable Invariants
1. **Zero Main-Thread Contention for Background Channels**: Background channel traffic must never be forced to hop through Android's main `Looper` before reaching background executor pools.
2. **Desktop Zero-Init Compatibility**: `FlutterProjectArgs.does_handle_platform_messages_on_platform_thread` must default to `true` when zero-initialized to preserve existing desktop embedder behavior.
3. **Empty Message Safety**: Inbound messages where `message_size == 0` and `message == nullptr` must be delivered safely as empty buffers without null pointer assertions.
4. **Thread-Safe Responses**: Responses submitted via `FlutterEngineSendPlatformMessageResponse` must be callable from any background executor thread without main-thread hops.

## Chosen Solution
- Extend `embedder.h` with:
  ```c
  typedef void (*FlutterPlatformMessageCallback2)(
      const FlutterPlatformMessage* message,
      void* user_data);
  ```
- Add `bool does_handle_platform_messages_on_platform_thread` in `FlutterProjectArgs`.
- Android explicitly sets `does_handle_platform_messages_on_platform_thread = false`.
- The engine invokes `FlutterPlatformMessageCallback2` directly on the originating thread (typically the UI task runner).
- The embedder forwards the message to Java `DartMessenger`:
  - If the target channel is registered with a `BinaryMessenger.TaskQueue`, it dispatches directly to that queue's background executor pool.
  - If registered on the default queue, it posts to the Android platform `Looper`.

## Rejected Alternatives & Rationale
- *Enforcing `does_handle_platform_messages_on_platform_thread = true` on Android*: Rejected because forcing every camera frame or database message to hop through the main `Looper` destroys frame pacing and degrades high-bandwidth plugin performance.
- *Separate background channel C-API*: Rejected because adding separate APIs fragments the channel abstraction; a configuration flag provides complete parity with zero desktop impact.

## Verification Contract
- Benchmark running 1,000 background database queries per second confirms 0 ms main Looper contention.
- Integration tests verify that `BinaryMessenger.makeBackgroundTaskQueue()` executes completely on background threads.
- Test delivering empty platform messages (`size=0, ptr=null`) verifies zero crashes or assertions.
