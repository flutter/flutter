# Skwasm

This directory contains the implementation of the Skwasm rendering engine for the Flutter Web engine. Skwasm is a high-performance 2D graphics renderer that leverages the Skia graphics library compiled to WebAssembly (WASM). It bridges the high-level `dart:ui` APIs with Skia's C++ implementation using Dart FFI (Foreign Function Interface).

## Purpose

The Skwasm renderer provides an alternative to the CanvasKit renderer, specifically optimized for WebAssembly-based environments (like `dart2wasm`). It enables direct, low-overhead communication between Dart and the underlying graphics engine, resulting in improved performance for complex rendering tasks, advanced text layout, and custom shaders.

## Subdirectories

- **`skwasm_impl/`**: Contains the Dart implementation of the `dart:ui` layer using Skwasm. These classes wrap the low-level FFI calls into idiomatic Dart APIs.
- **`skwasm_stub/`**: Contains the actual stub implementations that throw `UnimplementedError` when Skwasm functionality is accessed on unsupported platforms.
- **`skwasm_impl/raw/`**: Contains the low-level Dart FFI bindings and opaque handles that map directly to the Skia C++ API within the Skwasm WASM module.
- **`skwasm_impl/raw/text/`**: Contains specialized FFI bindings for Skia's text layout and styling engine.

## Files

- **`skwasm_impl.dart`**: The primary entry point for the Skwasm implementation. This file exports all the necessary components, including the higher-level Dart wrappers for the `dart:ui` layer and the underlying FFI bindings. It also specifies the `@DefaultAsset('skwasm')` for the FFI module.
- **`skwasm_stub.dart`**: The entry point for Skwasm stubs. This file exports stub implementations of Skwasm-related classes, ensuring that the Flutter Web engine can be compiled for targets that do not support Skwasm (such as when using `dart2js`) without causing compilation errors.
