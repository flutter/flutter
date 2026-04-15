# Layer-Based Rendering System

This directory implements the layer-based rendering system for the Flutter Web engine. It provides a structured way to build, optimize, and render a scene using a tree of `Layer` objects.

## Purpose

The layer system acts as an intermediate representation between the `SceneBuilder` API and the final rendering on one or more HTML canvases. This architecture allows the engine to:
- **Minimize rendering work via culling:** By calculating the paint bounds of every layer during a `preroll` phase, the engine can skip the measurement and painting of any layer (or entire subtree) that is outside the current viewport.
- **Optimize platform view composition:** Before drawing any pixels, the engine determines the exact placement and occlusion of all embedded HTML elements. This allows it to intelligently manage the multiple canvases required to correctly layer Flutter-rendered content with platform views.
- **Coordinate complex painting operations:** It uses an `NWayCanvas` to simultaneously apply clips, transforms, and filters across all active canvases, ensuring consistent visual results.
- **Support retained layers:** The system allows the Flutter framework to reuse existing `EngineLayer` objects, avoiding the overhead of re-creating the layer tree structure for parts of the UI that haven't changed.

## Files

- **`layer.dart`**: Contains the core `Layer` and `ContainerLayer` base classes, along with specialized implementations for various rendering primitives such as `ClipPathEngineLayer`, `OpacityEngineLayer`, `TransformEngineLayer`, `PictureLayer`, and `PlatformViewLayer`.
- **`layer_painting.dart`**: Defines internal interfaces (`LayerCanvas`, `LayerPicture`, `LayerImageFilter`, etc.) that extend standard `dart:ui` classes with additional methods needed for internal engine operations like measurement and SVG generation.
- **`layer_scene_builder.dart`**: Implements the `ui.SceneBuilder` and `ui.Scene` interfaces. It translates high-level scene building commands into a tree structure of `Layer` objects.
- **`layer_tree.dart`**: Defines the `LayerTree` class, which manages the root of the layer tree and orchestrates the frame lifecycle, including the `preroll`, `measure`, and `paint` phases.
- **`layer_visitor.dart`**: Implements various visitors for traversing the layer tree. This includes the `PrerollVisitor` for calculating bounds, the `MeasureVisitor` for optimizing rendering and platform view placement, and the `PaintVisitor` for the final rendering pass.
- **`n_way_canvas.dart`**: Provides the `NWayCanvas` utility, which allows the engine to apply a single sequence of canvas operations (like clips or transforms) to multiple underlying canvases simultaneously.
