# Flutter Web Engine `dart:ui` Implementation (`lib/`)

This directory contains the web-specific implementation of the `dart:ui` library. It provides the foundational primitives that the Flutter framework uses to interact with the web browser environment.

## Purpose

The code in this directory acts as a bridge between the Flutter framework and the browser's low-level APIs (DOM, Canvas, WebGL, WebAssembly). It implements the core rendering, event handling, text layout, and accessibility systems required to run Flutter on the web.

While the Flutter framework expects the `dart:ui` library to be provided by the engine, on the web, this implementation is written in Dart and leverages the internal engine logic found in the `src/` and `ui_web/` subdirectories.

## Subdirectories

- **`src/`**: Contains the internal, private implementation of the web engine, including rendering backends (CanvasKit, Skwasm), platform integration, and DOM management.
- **`ui_web/`**: Contains the implementation of the `dart:ui_web` library, which provides web-specific extensions to the core `dart:ui` API.

## Files

- **`annotations.dart`**: Defines the `@keepToString` annotation, used to prevent the Dart compiler from removing `toString` overrides during size optimization in release builds.
- **`canvas.dart`**: Contains the definitions for the `Canvas`, `Picture`, `PictureRecorder`, and `Vertices` classes, which provide the core drawing API for Flutter.
- **`channel_buffers.dart`**: Implements `ChannelBuffers` to manage and buffer messages sent over platform channels between the framework and the engine.
- **`compositing.dart`**: Defines the `Scene` and `SceneBuilder` classes used to build, optimize, and render the layer-based scene graph.
- **`geometry.dart`**: Provides core geometric primitives used throughout the engine, including `Offset`, `Size`, `Rect`, `Radius`, `RRect`, `RSuperellipse`, and `RSTransform`.
- **`key.dart`**: Defines the `KeyData` class and related enums for representing low-level keyboard events.
- **`lerp.dart`**: Contains foundational linear interpolation functions, such as `lerpDouble`, used for animations and transitions.
- **`math.dart`**: Provides basic mathematical utility functions like `clampDouble`.
- **`natives.dart`**: Defines helper classes for platform-specific integration, such as `DartPluginRegistrant` (largely implemented as stubs for the web).
- **`painting.dart`**: The core of the painting system, defining `Color`, `Paint`, `Image`, `Shader`, `Gradient`, `ImageFilter`, and `ColorFilter`.
- **`path.dart`**: Defines the `Path` class for representing complex 2D vector shapes and paths.
- **`path_metrics.dart`**: Provides the `PathMetrics`, `PathMetric`, and `Tangent` classes for measuring and iterating over paths.
- **`platform_dispatcher.dart`**: Implements the `PlatformDispatcher`, which centralizes platform-level events (metrics, locale, brightness, semantics) and lifecycle management.
- **`platform_isolate.dart`**: Provides web-specific implementations for running computations on the platform thread.
- **`pointer.dart`**: Defines `PointerData` and `PointerDataPacket` for representing pointer, mouse, touch, and trackpad events.
- **`rsuperellipse_param.dart`**: Contains internal helper classes and extensions for building and managing the complex geometry of `RSuperellipse` shapes.
- **`semantics.dart`**: Defines the extensive accessibility system, including `SemanticsAction`, `SemanticsFlag`, `SemanticsUpdate`, and `SemanticsRole`.
- **`text.dart`**: Contains the text layout and styling system, defining `TextStyle`, `ParagraphStyle`, `StrutStyle`, and the `Paragraph` and `ParagraphBuilder` classes.
- **`tile_mode.dart`**: Defines the `TileMode` enum, used to specify how shaders should tile when they extend beyond their original bounds.
- **`ui.dart`**: The main library entry point and barrel file that exports all the components of the web implementation of `dart:ui`.
- **`window.dart`**: Defines the `FlutterView`, `Display`, and `AccessibilityFeatures` classes for managing windowing, display metrics, and accessibility configurations.
