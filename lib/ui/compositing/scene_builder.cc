// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/compositing/scene_builder.h"

#include "flutter/flow/layers/backdrop_filter_layer.h"
#include "flutter/flow/layers/child_scene_layer.h"
#include "flutter/flow/layers/clip_path_layer.h"
#include "flutter/flow/layers/clip_rect_layer.h"
#include "flutter/flow/layers/clip_rrect_layer.h"
#include "flutter/flow/layers/color_filter_layer.h"
#include "flutter/flow/layers/container_layer.h"
#include "flutter/flow/layers/opacity_layer.h"
#include "flutter/flow/layers/performance_overlay_layer.h"
#include "flutter/flow/layers/picture_layer.h"
#include "flutter/flow/layers/shader_mask_layer.h"
#include "flutter/flow/layers/transform_layer.h"
#include "flutter/lib/ui/painting/matrix.h"
#include "flutter/lib/ui/painting/shader.h"
#include "lib/tonic/dart_args.h"
#include "lib/tonic/dart_binding_macros.h"
#include "lib/tonic/converter/dart_converter.h"
#include "lib/tonic/dart_library_natives.h"
#include "third_party/skia/include/core/SkColorFilter.h"

namespace blink {

static void SceneBuilder_constructor(Dart_NativeArguments args) {
  DartCallConstructor(&SceneBuilder::create, args);
}

IMPLEMENT_WRAPPERTYPEINFO(ui, SceneBuilder);

#define FOR_EACH_BINDING(V)                      \
  V(SceneBuilder, pushTransform)                 \
  V(SceneBuilder, pushClipRect)                  \
  V(SceneBuilder, pushClipRRect)                 \
  V(SceneBuilder, pushClipPath)                  \
  V(SceneBuilder, pushOpacity)                   \
  V(SceneBuilder, pushColorFilter)               \
  V(SceneBuilder, pushBackdropFilter)            \
  V(SceneBuilder, pushShaderMask)                \
  V(SceneBuilder, pop)                           \
  V(SceneBuilder, addPicture)                    \
  V(SceneBuilder, addChildScene)                 \
  V(SceneBuilder, addPerformanceOverlay)         \
  V(SceneBuilder, setRasterizerTracingThreshold) \
  V(SceneBuilder, build)

FOR_EACH_BINDING(DART_NATIVE_CALLBACK)

void SceneBuilder::RegisterNatives(tonic::DartLibraryNatives* natives) {
  natives->Register(
      {{"SceneBuilder_constructor", SceneBuilder_constructor, 1, true},
       FOR_EACH_BINDING(DART_REGISTER_NATIVE)});
}

SceneBuilder::SceneBuilder()
    : m_currentLayer(nullptr), m_currentRasterizerTracingThreshold(0) {
  m_cullRects.push(SkRect::MakeLargest());
}

SceneBuilder::~SceneBuilder() {}

void SceneBuilder::pushTransform(const tonic::Float64List& matrix4) {
  SkMatrix sk_matrix = ToSkMatrix(matrix4);
  SkMatrix inverse_sk_matrix;
  SkRect cullRect;
  if (sk_matrix.invert(&inverse_sk_matrix))
    inverse_sk_matrix.mapRect(&cullRect, m_cullRects.top());
  else
    cullRect = SkRect::MakeLargest();

  std::unique_ptr<flow::TransformLayer> layer(new flow::TransformLayer());
  layer->set_transform(sk_matrix);
  addLayer(std::move(layer), cullRect);
}

void SceneBuilder::pushClipRect(double left,
                                double right,
                                double top,
                                double bottom) {
  const SkRect clipRect = SkRect::MakeLTRB(left, top, right, bottom);
  SkRect cullRect;
  if (!cullRect.intersect(clipRect, m_cullRects.top()))
    cullRect = SkRect::MakeEmpty();

  std::unique_ptr<flow::ClipRectLayer> layer(new flow::ClipRectLayer());
  layer->set_clip_rect(clipRect);
  addLayer(std::move(layer), cullRect);
}

void SceneBuilder::pushClipRRect(const RRect& rrect) {
  SkRect cullRect;
  if (!cullRect.intersect(rrect.sk_rrect.rect(), m_cullRects.top()))
    cullRect = SkRect::MakeEmpty();

  std::unique_ptr<flow::ClipRRectLayer> layer(new flow::ClipRRectLayer());
  layer->set_clip_rrect(rrect.sk_rrect);
  addLayer(std::move(layer), cullRect);
}

void SceneBuilder::pushClipPath(const CanvasPath* path) {
  SkRect cullRect;
  if (!cullRect.intersect(path->path().getBounds(), m_cullRects.top()))
    cullRect = SkRect::MakeEmpty();

  std::unique_ptr<flow::ClipPathLayer> layer(new flow::ClipPathLayer());
  layer->set_clip_path(path->path());
  addLayer(std::move(layer), cullRect);
}

void SceneBuilder::pushOpacity(int alpha) {
  std::unique_ptr<flow::OpacityLayer> layer(new flow::OpacityLayer());
  layer->set_alpha(alpha);
  addLayer(std::move(layer), m_cullRects.top());
}

void SceneBuilder::pushColorFilter(int color, int transferMode) {
  std::unique_ptr<flow::ColorFilterLayer> layer(new flow::ColorFilterLayer());
  layer->set_color(static_cast<SkColor>(color));
  layer->set_transfer_mode(static_cast<SkXfermode::Mode>(transferMode));
  addLayer(std::move(layer), m_cullRects.top());
}

void SceneBuilder::pushBackdropFilter(ImageFilter* filter) {
  std::unique_ptr<flow::BackdropFilterLayer> layer(
      new flow::BackdropFilterLayer());
  layer->set_filter(filter->filter());
  addLayer(std::move(layer), m_cullRects.top());
}

void SceneBuilder::pushShaderMask(Shader* shader,
                                  double maskRectLeft,
                                  double maskRectRight,
                                  double maskRectTop,
                                  double maskRectBottom,
                                  int transferMode) {
  std::unique_ptr<flow::ShaderMaskLayer> layer(new flow::ShaderMaskLayer());
  layer->set_shader(shader->shader());
  layer->set_mask_rect(SkRect::MakeLTRB(maskRectLeft, maskRectTop,
                                        maskRectRight, maskRectBottom));
  layer->set_transfer_mode(static_cast<SkXfermode::Mode>(transferMode));
  addLayer(std::move(layer), m_cullRects.top());
}

void SceneBuilder::addLayer(std::unique_ptr<flow::ContainerLayer> layer, const SkRect& cullRect) {
  DCHECK(layer);

  m_cullRects.push(cullRect);

  if (!m_rootLayer) {
    DCHECK(!m_currentLayer);
    m_rootLayer = std::move(layer);
    m_currentLayer = m_rootLayer.get();
    return;
  }
  if (!m_currentLayer)
    return;
  flow::ContainerLayer* newLayer = layer.get();
  m_currentLayer->Add(std::move(layer));
  m_currentLayer = newLayer;
}

void SceneBuilder::pop() {
  if (!m_currentLayer)
    return;
  m_cullRects.pop();
  m_currentLayer = m_currentLayer->parent();
}

void SceneBuilder::addPicture(double dx,
                              double dy,
                              Picture* picture,
                              int hints) {
  if (!m_currentLayer)
    return;

  SkRect pictureRect = picture->picture()->cullRect();
  pictureRect.offset(dx, dy);
  if (!SkRect::Intersects(pictureRect, m_cullRects.top()))
    return;

  std::unique_ptr<flow::PictureLayer> layer(new flow::PictureLayer());
  layer->set_offset(SkPoint::Make(dx, dy));
  layer->set_picture(picture->picture());
  layer->set_is_complex(!!(hints & 1));
  layer->set_will_change(!!(hints & 2));
  m_currentLayer->Add(std::move(layer));
}

void SceneBuilder::addChildScene(double dx,
                                 double dy,
                                 double devicePixelRatio,
                                 int physicalWidth,
                                 int physicalHeight,
                                 uint32_t sceneToken) {
  if (!m_currentLayer)
    return;
  std::unique_ptr<flow::ChildSceneLayer> layer(new flow::ChildSceneLayer());
  layer->set_offset(SkPoint::Make(dx, dy));
  layer->set_device_pixel_ratio(devicePixelRatio);
  layer->set_physical_size(SkISize::Make(physicalWidth, physicalHeight));
  mojo::gfx::composition::SceneTokenPtr token =
      mojo::gfx::composition::SceneToken::New();
  token->value = sceneToken;
  layer->set_scene_token(token.Pass());
  m_currentLayer->Add(std::move(layer));
}

void SceneBuilder::addPerformanceOverlay(uint64_t enabledOptions,
                                         double left,
                                         double right,
                                         double top,
                                         double bottom) {
  if (!m_currentLayer)
    return;
  std::unique_ptr<flow::PerformanceOverlayLayer> layer(
      new flow::PerformanceOverlayLayer(enabledOptions));
  layer->set_paint_bounds(SkRect::MakeLTRB(left, top, right, bottom));
  m_currentLayer->Add(std::move(layer));
}

void SceneBuilder::setRasterizerTracingThreshold(uint32_t frameInterval) {
  m_currentRasterizerTracingThreshold = frameInterval;
}

ftl::RefPtr<Scene> SceneBuilder::build() {
  m_currentLayer = nullptr;
  int32_t threshold = m_currentRasterizerTracingThreshold;
  m_currentRasterizerTracingThreshold = 0;
  ftl::RefPtr<Scene> scene = Scene::create(std::move(m_rootLayer), threshold);
  ClearDartWrapper();
  return scene;
}

}  // namespace blink
