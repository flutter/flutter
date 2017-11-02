// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/compositing/scene_builder.h"

#include "flutter/lib/ui/painting/matrix.h"
#include "flutter/lib/ui/painting/shader.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "flutter/lib/ui/window/window.h"
#include "lib/fxl/build_config.h"
#include "lib/tonic/converter/dart_converter.h"
#include "lib/tonic/dart_args.h"
#include "lib/tonic/dart_binding_macros.h"
#include "lib/tonic/dart_library_natives.h"
#include "third_party/skia/include/core/SkColorFilter.h"

namespace blink {

static void SceneBuilder_constructor(Dart_NativeArguments args) {
  DartCallConstructor(&SceneBuilder::create, args);
}

IMPLEMENT_WRAPPERTYPEINFO(ui, SceneBuilder);

#define FOR_EACH_BINDING(V)                         \
  V(SceneBuilder, pushTransform)                    \
  V(SceneBuilder, pushClipRect)                     \
  V(SceneBuilder, pushClipRRect)                    \
  V(SceneBuilder, pushClipPath)                     \
  V(SceneBuilder, pushOpacity)                      \
  V(SceneBuilder, pushColorFilter)                  \
  V(SceneBuilder, pushBackdropFilter)               \
  V(SceneBuilder, pushShaderMask)                   \
  V(SceneBuilder, pushPhysicalModel)                \
  V(SceneBuilder, pop)                              \
  V(SceneBuilder, addPicture)                       \
  V(SceneBuilder, addTexture)                       \
  V(SceneBuilder, addChildScene)                    \
  V(SceneBuilder, addPerformanceOverlay)            \
  V(SceneBuilder, setRasterizerTracingThreshold)    \
  V(SceneBuilder, setCheckerboardOffscreenLayers)   \
  V(SceneBuilder, setCheckerboardRasterCacheImages) \
  V(SceneBuilder, build)

FOR_EACH_BINDING(DART_NATIVE_CALLBACK)

void SceneBuilder::RegisterNatives(tonic::DartLibraryNatives* natives) {
  natives->Register(
      {{"SceneBuilder_constructor", SceneBuilder_constructor, 1, true},
       FOR_EACH_BINDING(DART_REGISTER_NATIVE)});
}

SceneBuilder::SceneBuilder() : layer_builder_(flow::LayerBuilder::Create()) {}

SceneBuilder::~SceneBuilder() = default;

void SceneBuilder::pushTransform(const tonic::Float64List& matrix4) {
  layer_builder_->PushTransform(ToSkMatrix(matrix4));
}

void SceneBuilder::pushClipRect(double left,
                                double right,
                                double top,
                                double bottom) {
  layer_builder_->PushClipRect(SkRect::MakeLTRB(left, top, right, bottom));
}

void SceneBuilder::pushClipRRect(const RRect& rrect) {
  layer_builder_->PushClipRoundedRect(rrect.sk_rrect);
}

void SceneBuilder::pushClipPath(const CanvasPath* path) {
  layer_builder_->PushClipPath(path->path());
}

void SceneBuilder::pushOpacity(int alpha) {
  layer_builder_->PushOpacity(alpha);
}

void SceneBuilder::pushColorFilter(int color, int blendMode) {
  layer_builder_->PushColorFilter(static_cast<SkColor>(color),
                                  static_cast<SkBlendMode>(blendMode));
}

void SceneBuilder::pushBackdropFilter(ImageFilter* filter) {
  layer_builder_->PushBackdropFilter(filter->filter());
}

void SceneBuilder::pushShaderMask(Shader* shader,
                                  double maskRectLeft,
                                  double maskRectRight,
                                  double maskRectTop,
                                  double maskRectBottom,
                                  int blendMode) {
  layer_builder_->PushShaderMask(
      shader->shader(),
      SkRect::MakeLTRB(maskRectLeft, maskRectTop, maskRectRight,
                       maskRectBottom),
      static_cast<SkBlendMode>(blendMode));
}

void SceneBuilder::pushPhysicalModel(const RRect& rrect,
                                     double elevation,
                                     int color) {
  layer_builder_->PushPhysicalModel(
      rrect.sk_rrect,               //
      elevation,                    //
      static_cast<SkColor>(color),  //
      UIDartState::Current()->window()->viewport_metrics().device_pixel_ratio);
}

void SceneBuilder::pop() {
  layer_builder_->Pop();
}

void SceneBuilder::addPicture(double dx,
                              double dy,
                              Picture* picture,
                              int hints) {
  layer_builder_->PushPicture(SkPoint::Make(dx, dy),  //
                              picture->picture(),     //
                              !!(hints & 1),          // picture is complex
                              !!(hints & 2)           // picture will change
  );
}

void SceneBuilder::addTexture(double dx,
                              double dy,
                              double width,
                              double height,
                              int64_t textureId) {
  layer_builder_->PushTexture(SkPoint::Make(dx, dy),
                              SkSize::Make(width, height), textureId);
}

void SceneBuilder::addChildScene(double dx,
                                 double dy,
                                 double width,
                                 double height,
                                 SceneHost* sceneHost,
                                 bool hitTestable) {
#if defined(OS_FUCHSIA)
  layer_builder_->PushChildScene(SkPoint::Make(dx, dy),            //
                                 SkSize::Make(width, height),      //
                                 sceneHost->export_node_holder(),  //
                                 hitTestable);
#endif  // defined(OS_FUCHSIA)
}

void SceneBuilder::addPerformanceOverlay(uint64_t enabledOptions,
                                         double left,
                                         double right,
                                         double top,
                                         double bottom) {
  layer_builder_->PushPerformanceOverlay(
      enabledOptions, SkRect::MakeLTRB(left, top, right, bottom));
}

void SceneBuilder::setRasterizerTracingThreshold(uint32_t frameInterval) {
  layer_builder_->SetRasterizerTracingThreshold(frameInterval);
}

void SceneBuilder::setCheckerboardRasterCacheImages(bool checkerboard) {
  layer_builder_->SetCheckerboardRasterCacheImages(checkerboard);
}

void SceneBuilder::setCheckerboardOffscreenLayers(bool checkerboard) {
  layer_builder_->SetCheckerboardOffscreenLayers(checkerboard);
}

fxl::RefPtr<Scene> SceneBuilder::build() {
  fxl::RefPtr<Scene> scene =
      Scene::create(layer_builder_->TakeLayer(),
                    layer_builder_->GetRasterizerTracingThreshold(),
                    layer_builder_->GetCheckerboardRasterCacheImages(),
                    layer_builder_->GetCheckerboardOffscreenLayers());
  ClearDartWrapper();
  return scene;
}

}  // namespace blink
