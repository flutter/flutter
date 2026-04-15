# Skwasm Tests

This directory contains unit tests for the `skwasm` renderer implementation in the Flutter Web Engine. These tests primarily focus on the low-level interactions between Dart and the underlying WebAssembly/Skia implementation, specifically concerning memory management and native object lifecycles.

## Files

- **`native_memory_test.dart`**: Verifies the native memory management logic for Skwasm-backed objects such as `SkwasmImage`, `SkwasmPicture`, and `SkwasmPath`. It ensures that reference counting, object cloning, and disposal behave correctly to prevent memory leaks and use-after-free errors.
- **`raw_memory_test.dart`**: Tests the `withStackScope` utility, which is used for efficient, temporary memory allocations on the native stack. It ensures that the scope is correctly managed and that the utility properly handles synchronous and asynchronous closures.
