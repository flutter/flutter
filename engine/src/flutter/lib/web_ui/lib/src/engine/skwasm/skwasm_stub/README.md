# Skwasm Stubs

This directory contains stub implementations for Skwasm-related functionality. These stubs are used when the Flutter Web engine is compiled for a target that does not support Skwasm (for example, when compiling with `dart2js` instead of `dart2wasm`).

The stubs ensure that the codebase can reference Skwasm-specific classes without causing compilation errors, while ensuring that any attempt to use Skwasm functionality on an unsupported platform results in a clear runtime error.

## Files

- **`renderer.dart`**: Provides a stub implementation of the `SkwasmRenderer` class. This class implements the `Renderer` interface but throws an `UnimplementedError` for all methods, as Skwasm rendering is not available when these stubs are in use.
