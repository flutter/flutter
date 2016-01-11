// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart_ui;

abstract class Scene extends NativeFieldWrapperClass2 {
  void dispose() native "Scene_dispose";
}

class SceneBuilder extends NativeFieldWrapperClass2 {
  void _constructor(Rect bounds) native "SceneBuilder_constructor";
  SceneBuilder(Rect bounds) { _constructor(bounds); }

  void pushTransform(Float64List matrix4) native "SceneBuilder_pushTransform";
  void pushClipRect(Rect rect) native "SceneBuilder_pushClipRect";
  void _pushClipRRect(RRect rrect) native "SceneBuilder_pushClipRRect";
  void _pushClipPath(Path path) native "SceneBuilder_pushClipPath";
  void _pushOpacity(int alpha) native "SceneBuilder_pushOpacity";
  void _pushColorFilter(Color color, TransferMode transferMode) native "SceneBuilder_pushColorFilter";
  void pushShader(Shader shader, TransferMode transferMode) native "SceneBuilder_pushShader";

  void pop() native "SceneBuilder_pop";

  void addPerformanceOverlay(int enabledOptions, Rect bounds) native "SceneBuilder_addPerformanceOverlay";
  void _addPicture(Offset offset, Picture picture) native "SceneBuilder_addPicture";
  void setRasterizerTracingThreshold(int frameInterval) native "SceneBuilder_setRasterizerTracingThreshold";

  Scene build() native "SceneBuilder_build";

  // TODO(abarth): Remove these once clients stop passing bounds.
  void pushClipRRect(RRect rrect, [ Rect bounds ]) {
    _pushClipRRect(rrect);
  }
  void pushClipPath(Path path, [ Rect bounds ]) {
    _pushClipPath(path);
  }
  void pushOpacity(int alpha, [ Rect bounds ]) {
    _pushOpacity(alpha);
  }
  void pushColorFilter(Color color, TransferMode transferMode, [ Rect bounds ]) {
    _pushColorFilter(color, transferMode);
  }
  void addPicture(Offset offset, Picture picture, [ Rect bounds ]) {
    _addPicture(offset, picture);
  }
}
