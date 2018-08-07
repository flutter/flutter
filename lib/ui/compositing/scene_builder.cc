// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/compositing/scene_builder.h"

#include "flutter/fml/build_config.h"
#include "flutter/lib/ui/painting/matrix.h"
#include "flutter/lib/ui/painting/shader.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "flutter/lib/ui/window/window.h"
#include "third_party/skia/include/core/SkColorFilter.h"
#include "third_party/tonic/converter/dart_converter.h"
#include "third_party/tonic/dart_args.h"
#include "third_party/tonic/dart_binding_macros.h"
#include "third_party/tonic/dart_library_natives.h"

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
  V(SceneBuilder, pushPhysicalShape)                \
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
                                double bottom,
                                int clipBehavior) {
  layer_builder_->PushClipRect(SkRect::MakeLTRB(left, top, right, bottom),
                               static_cast<flow::Clip>(clipBehavior));
}

void SceneBuilder::pushClipRRect(const RRect& rrect, int clipBehavior) {
  layer_builder_->PushClipRoundedRect(rrect.sk_rrect,
                                      static_cast<flow::Clip>(clipBehavior));
}

void SceneBuilder::pushClipPath(const CanvasPath* path, int clipBehavior) {
  layer_builder_->PushClipPath(path->path(),
                               static_cast<flow::Clip>(clipBehavior));
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

void SceneBuilder::pushPhysicalShape(const CanvasPath* path,
                                     double elevation,
                                     int color,
                                     int shadow_color,
                                     int clip_behavior) {
  layer_builder_->PushPhysicalShape(
      path->path(),                 //
      elevation,                    //
      static_cast<SkColor>(color),  //
      static_cast<SkColor>(shadow_color),
      UIDartState::Current()->window()->viewport_metrics().device_pixel_ratio,
      static_cast<flow::Clip>(clip_behavior));
}

void SceneBuilder::pop() {
  layer_builder_->Pop();
}

void SceneBuilder::addPicture(double dx,
                              double dy,
                              Picture* picture,
                              int hints) {
  layer_builder_->PushPicture(
      SkPoint::Make(dx, dy),                             //
      UIDartState::CreateGPUObject(picture->picture()),  //
      !!(hints & 1),                                     // picture is complex
      !!(hints & 2)                                      // picture will change
  );
}

void SceneBuilder::addTexture(double dx,
                              double dy,
                              double width,
                              double height,
                              int64_t textureId,
                              bool freeze) {
  layer_builder_->PushTexture(SkPoint::Make(dx, dy),
                              SkSize::Make(width, height), textureId, freeze);
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

fml::RefPtr<Scene> SceneBuilder::build() {
  fml::RefPtr<Scene> scene =
      Scene::create(layer_builder_->TakeLayer(),
                    layer_builder_->GetRasterizerTracingThreshold(),
                    layer_builder_->GetCheckerboardRasterCacheImages(),
                    layer_builder_->GetCheckerboardOffscreenLayers());
  ClearDartWrapper();
  return scene;
}

}  // namespace blink
