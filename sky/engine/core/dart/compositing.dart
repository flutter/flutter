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
  void pushClipRRect(RRect rrect) native "SceneBuilder_pushClipRRect";
  void pushClipPath(Path path) native "SceneBuilder_pushClipPath";
  void pushOpacity(int alpha) native "SceneBuilder_pushOpacity";
  void pushColorFilter(Color color, TransferMode transferMode) native "SceneBuilder_pushColorFilter";
  void pushShaderMask(Shader shader, Rect maskRect, TransferMode transferMode) native "SceneBuilder_pushShaderMask";

  void pop() native "SceneBuilder_pop";

  void addPerformanceOverlay(int enabledOptions, Rect bounds) native "SceneBuilder_addPerformanceOverlay";
  void addPicture(Offset offset, Picture picture) native "SceneBuilder_addPicture";
  void addChildScene(Offset offset,
                     int physicalWidth,
                     int physicalHeight,
                     int sceneToken) native "SceneBuilder_addChildScene";
  void setRasterizerTracingThreshold(int frameInterval) native "SceneBuilder_setRasterizerTracingThreshold";

  Scene build() native "SceneBuilder_build";
}
