// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/compositing/SceneBuilder.h"

#include "third_party/skia/include/core/SkColorFilter.h"
#include "sky/engine/core/painting/Matrix.h"
#include "sky/compositor/clip_path_layer.h"
#include "sky/compositor/clip_rect_layer.h"
#include "sky/compositor/clip_rrect_layer.h"
#include "sky/compositor/color_filter_layer.h"
#include "sky/compositor/container_layer.h"
#include "sky/compositor/opacity_layer.h"
#include "sky/compositor/picture_layer.h"
#include "sky/compositor/statistics_layer.h"
#include "sky/compositor/transform_layer.h"
#include "sky/engine/tonic/dart_args.h"
#include "sky/engine/tonic/dart_binding_macros.h"
#include "sky/engine/tonic/dart_converter.h"
#include "sky/engine/tonic/dart_library_natives.h"

namespace blink {

static void SceneBuilder_constructor(Dart_NativeArguments args) {
  DartCallConstructor(&SceneBuilder::create, args);
}

static void SceneBuilder_pushTransform(Dart_NativeArguments args) {
  DartArgIterator it(args);
  Float64List matrix4 = it.GetNext<Float64List>();
  if (it.had_exception())
    return;
  ExceptionState es;
  GetReceiver<SceneBuilder>(args)->pushTransform(matrix4, es);
  if (es.had_exception())
    Dart_ThrowException(es.GetDartException(args, true));
}

IMPLEMENT_WRAPPERTYPEINFO(SceneBuilder);

#define FOR_EACH_BINDING(V) \
  V(SceneBuilder, pushClipRect) \
  V(SceneBuilder, pushClipRRect) \
  V(SceneBuilder, pushClipPath) \
  V(SceneBuilder, pushOpacity) \
  V(SceneBuilder, pushColorFilter) \
  V(SceneBuilder, pop) \
  V(SceneBuilder, addPicture) \
  V(SceneBuilder, addStatistics) \
  V(SceneBuilder, setRasterizerTracingThreshold) \
  V(SceneBuilder, build)

FOR_EACH_BINDING(DART_NATIVE_CALLBACK)

void SceneBuilder::RegisterNatives(DartLibraryNatives* natives) {
  natives->Register({
    { "SceneBuilder_constructor", SceneBuilder_constructor, 2, true },
    { "SceneBuilder_pushTransform", SceneBuilder_pushTransform, 2, true },
FOR_EACH_BINDING(DART_REGISTER_NATIVE)
  });
}

SceneBuilder::SceneBuilder(const Rect& bounds)
    : m_rootPaintBounds(bounds.sk_rect)
    , m_currentLayer(nullptr)
    , m_currentRasterizerTracingThreshold(0)
{
}

SceneBuilder::~SceneBuilder()
{
}

void SceneBuilder::pushTransform(const Float64List& matrix4, ExceptionState& es)
{
    SkMatrix sk_matrix = toSkMatrix(matrix4, es);
    if (es.had_exception())
        return;
    std::unique_ptr<sky::compositor::TransformLayer> layer(new sky::compositor::TransformLayer());
    layer->set_transform(sk_matrix);
    addLayer(std::move(layer));
}

void SceneBuilder::pushClipRect(const Rect& rect)
{
    std::unique_ptr<sky::compositor::ClipRectLayer> layer(new sky::compositor::ClipRectLayer());
    layer->set_clip_rect(rect.sk_rect);
    addLayer(std::move(layer));
}

void SceneBuilder::pushClipRRect(const RRect& rrect, const Rect& bounds)
{
    std::unique_ptr<sky::compositor::ClipRRectLayer> layer(new sky::compositor::ClipRRectLayer());
    layer->set_clip_rrect(rrect.sk_rrect);
    addLayer(std::move(layer));
}

void SceneBuilder::pushClipPath(const CanvasPath* path, const Rect& bounds)
{
    std::unique_ptr<sky::compositor::ClipPathLayer> layer(new sky::compositor::ClipPathLayer());
    layer->set_clip_path(path->path());
    addLayer(std::move(layer));
}

void SceneBuilder::pushOpacity(int alpha, const Rect& bounds)
{
    std::unique_ptr<sky::compositor::OpacityLayer> layer(new sky::compositor::OpacityLayer());
    if (!bounds.is_null)
      layer->set_paint_bounds(bounds.sk_rect);
    layer->set_alpha(alpha);
    addLayer(std::move(layer));
}

void SceneBuilder::pushColorFilter(CanvasColor color, TransferMode transferMode, const Rect& bounds)
{
    std::unique_ptr<sky::compositor::ColorFilterLayer> layer(new sky::compositor::ColorFilterLayer());
    if (!bounds.is_null)
      layer->set_paint_bounds(bounds.sk_rect);
    layer->set_color(color);
    layer->set_transfer_mode(transferMode);
    addLayer(std::move(layer));
}

void SceneBuilder::addLayer(std::unique_ptr<sky::compositor::ContainerLayer> layer)
{
    DCHECK(layer);
    if (!m_rootLayer) {
        DCHECK(!m_currentLayer);
        m_rootLayer = std::move(layer);
        m_rootLayer->set_paint_bounds(m_rootPaintBounds);
        m_currentLayer = m_rootLayer.get();
        return;
    }
    if (!m_currentLayer)
        return;
    sky::compositor::ContainerLayer* newLayer = layer.get();
    m_currentLayer->Add(std::move(layer));
    m_currentLayer = newLayer;
}

void SceneBuilder::pop()
{
    if (!m_currentLayer)
        return;
    m_currentLayer = m_currentLayer->parent();
}

void SceneBuilder::addPicture(const Offset& offset, Picture* picture, const Rect& paintBounds)
{
    if (!m_currentLayer)
        return;
    std::unique_ptr<sky::compositor::PictureLayer> layer(new sky::compositor::PictureLayer());
    layer->set_offset(SkPoint::Make(offset.sk_size.width(), offset.sk_size.height()));
    layer->set_picture(picture->toSkia());
    if (!paintBounds.is_null)
      layer->set_paint_bounds(paintBounds.sk_rect);
    m_currentLayer->Add(std::move(layer));
}

void SceneBuilder::addStatistics(uint64_t enabledOptions, const Rect& bounds)
{
    if (!m_currentLayer)
        return;
    std::unique_ptr<sky::compositor::StatisticsLayer> layer(new sky::compositor::StatisticsLayer(enabledOptions));
    if (!bounds.is_null)
      layer->set_paint_bounds(bounds.sk_rect);
    m_currentLayer->Add(std::move(layer));
}

void SceneBuilder::setRasterizerTracingThreshold(uint32_t frameInterval)
{
    m_currentRasterizerTracingThreshold = frameInterval;
}

PassRefPtr<Scene> SceneBuilder::build()
{
    m_currentLayer = nullptr;
    int32_t threshold = m_currentRasterizerTracingThreshold;
    m_currentRasterizerTracingThreshold = 0;
    RefPtr<Scene> scene = Scene::create(std::move(m_rootLayer), threshold);
    ClearDartWrapper();
    return scene.release();
}

} // namespace blink
