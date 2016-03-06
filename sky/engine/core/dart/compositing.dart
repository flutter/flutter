// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart_ui;

/// An opaque object representing a composited scene.
abstract class Scene extends NativeFieldWrapperClass2 {
  /// Releases the resources used by this scene.
  ///
  /// After calling this function, the scene is cannot be used further.
  void dispose() native "Scene_dispose";
}

/// Builds a [Scene] containing the given visuals.
class SceneBuilder extends NativeFieldWrapperClass2 {
  // TODO(abarth): Remove this ignored "bounds" argument.
  SceneBuilder([Rect bounds]) { _constructor(); }
  void _constructor() native "SceneBuilder_constructor";

  /// Pushes a transform operation onto the operation stack.
  ///
  /// The objects are transformed by the given matrix before rasterization.
  ///
  /// See [pop] for details about the operation stack.
  void pushTransform(Float64List matrix4) native "SceneBuilder_pushTransform";

  /// Pushes a rectangular clip operation onto the operation stack.
  ///
  /// Rasterization outside the given rectangle is discarded.
  ///
  /// See [pop] for details about the operation stack.
  void pushClipRect(Rect rect) native "SceneBuilder_pushClipRect";

  /// Pushes a rounded-rectangular clip operation onto the operation stack.
  ///
  /// Rasterization outside the given rounded rectangle is discarded.
  ///
  /// See [pop] for details about the operation stack.
  void pushClipRRect(RRect rrect) native "SceneBuilder_pushClipRRect";

  /// Pushes a path clip operation onto the operation stack.
  ///
  /// Rasterization outside the given path is discarded.
  ///
  /// See [pop] for details about the operation stack.
  void pushClipPath(Path path) native "SceneBuilder_pushClipPath";

  /// Pushes an opacity operation onto the operation stack.
  ///
  /// The given alpha value is blended into the alpha value of the objects'
  /// rasterization. An alpha value of 0 makes the objects entirely invisible.
  /// An alpha value of 255 has no effect (i.e., the objects retain the current
  /// opacity).
  ///
  /// See [pop] for details about the operation stack.
  void pushOpacity(int alpha) native "SceneBuilder_pushOpacity";

  /// Pushes a color filter operation onto the operation stack.
  ///
  /// The given color is applied to the objects' rasterization using the given
  /// transfer mode.
  ///
  /// See [pop] for details about the operation stack.
  void pushColorFilter(Color color, TransferMode transferMode) native "SceneBuilder_pushColorFilter";

  /// Pushes a shader mask operation onto the operation stack.
  ///
  /// The given shader is applied to the object's rasterization in the given
  /// rectangle using the given transfer mode.
  ///
  /// See [pop] for details about the operation stack.
  void pushShaderMask(Shader shader, Rect maskRect, TransferMode transferMode) native "SceneBuilder_pushShaderMask";

  /// Ends the effect of the most recently pushed operation.
  ///
  /// Internally the scene builder maintains a stack of operations. Each of the
  /// operations in the stack applies to each of the objects added to the scene.
  /// Calling this function removes the most recently added operation from the
  /// stack.
  void pop() native "SceneBuilder_pop";

  /// Adds an object to the scene that displays performance statistics.
  ///
  /// Useful during development to assess the performance of the application.
  /// The enabledOptions controls which statistics are displayed. The bounds
  /// controls where the statistics are displayed.
  void addPerformanceOverlay(int enabledOptions, Rect bounds) native "SceneBuilder_addPerformanceOverlay";

  /// Adds a picture to the scene.
  ///
  /// The picture is rasterized at the given offset.
  void addPicture(Offset offset, Picture picture) native "SceneBuilder_addPicture";

  /// (mojo-only) Adds a scene rendered by another application to the scene for
  /// this application.
  ///
  /// Applications typically obtain scene tokens when embedding other views via
  /// the Mojo view manager, but this function is agnostic as to the source of
  /// scene token.
  void addChildScene(Offset offset,
                     int physicalWidth,
                     int physicalHeight,
                     int sceneToken) native "SceneBuilder_addChildScene";

  /// Sets a threshold after which additional debugging information should be recorded.
  ///
  /// Currently this interface is difficult to use by end-developers. If you're
  /// interested in using this feature, please contact [flutter-dev](https://groups.google.com/forum/#!forum/flutter-dev).
  /// We'll hopefully be able to figure out how to make this feature more useful
  /// to you.
  void setRasterizerTracingThreshold(int frameInterval) native "SceneBuilder_setRasterizerTracingThreshold";

  /// Finishes building the scene.
  ///
  /// Returns a [Scene] containing the objects that have been added to this
  /// scene builder.
  ///
  /// After calling this function, the scene builder object is invalid and
  /// cannot be used further.
  Scene build() native "SceneBuilder_build";
}
