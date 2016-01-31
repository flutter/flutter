// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/compositing/SceneBuilder.h"

#include "flow/layers/child_scene_layer.h"
#include "flow/layers/clip_path_layer.h"
#include "flow/layers/clip_rect_layer.h"
#include "flow/layers/clip_rrect_layer.h"
#include "flow/layers/color_filter_layer.h"
#include "flow/layers/container_layer.h"
#include "flow/layers/opacity_layer.h"
#include "flow/layers/performance_overlay_layer.h"
#include "flow/layers/picture_layer.h"
#include "flow/layers/shader_mask_layer.h"
#include "flow/layers/transform_layer.h"
#include "sky/engine/core/painting/Matrix.h"
#include "sky/engine/core/painting/Shader.h"
#include "sky/engine/tonic/dart_args.h"
#include "sky/engine/tonic/dart_binding_macros.h"
#include "sky/engine/tonic/dart_converter.h"
#include "sky/engine/tonic/dart_library_natives.h"
#include "third_party/skia/include/core/SkColorFilter.h"

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

IMPLEMENT_WRAPPERTYPEINFO(ui, SceneBuilder);

#define FOR_EACH_BINDING(V) \
  V(SceneBuilder, pushClipRect) \
  V(SceneBuilder, pushClipRRect) \
  V(SceneBuilder, pushClipPath) \
  V(SceneBuilder, pushOpacity) \
  V(SceneBuilder, pushColorFilter) \
  V(SceneBuilder, pushShaderMask) \
  V(SceneBuilder, pop) \
  V(SceneBuilder, addPicture) \
  V(SceneBuilder, addChildScene) \
  V(SceneBuilder, addPerformanceOverlay) \
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
    : m_currentLayer(nullptr)
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
    std::unique_ptr<flow::TransformLayer> layer(new flow::TransformLayer());
    layer->set_transform(sk_matrix);
    addLayer(std::move(layer));
}

void SceneBuilder::pushClipRect(const Rect& rect)
{
    std::unique_ptr<flow::ClipRectLayer> layer(new flow::ClipRectLayer());
    layer->set_clip_rect(rect.sk_rect);
    addLayer(std::move(layer));
}

void SceneBuilder::pushClipRRect(const RRect& rrect)
{
    std::unique_ptr<flow::ClipRRectLayer> layer(new flow::ClipRRectLayer());
    layer->set_clip_rrect(rrect.sk_rrect);
    addLayer(std::move(layer));
}

void SceneBuilder::pushClipPath(const CanvasPath* path)
{
    std::unique_ptr<flow::ClipPathLayer> layer(new flow::ClipPathLayer());
    layer->set_clip_path(path->path());
    addLayer(std::move(layer));
}

void SceneBuilder::pushOpacity(int alpha)
{
    std::unique_ptr<flow::OpacityLayer> layer(new flow::OpacityLayer());
    layer->set_alpha(alpha);
    addLayer(std::move(layer));
}

void SceneBuilder::pushColorFilter(CanvasColor color, TransferMode transferMode)
{
    std::unique_ptr<flow::ColorFilterLayer> layer(new flow::ColorFilterLayer());
    layer->set_color(color);
    layer->set_transfer_mode(transferMode);
    addLayer(std::move(layer));
}

void SceneBuilder::pushShaderMask(Shader* shader, const Rect& maskRect, TransferMode transferMode)
{
    std::unique_ptr<flow::ShaderMaskLayer> layer(new flow::ShaderMaskLayer());
    layer->set_shader(shader->shader());
    layer->set_mask_rect(maskRect.sk_rect);
    layer->set_transfer_mode(transferMode);
    addLayer(std::move(layer));
}

void SceneBuilder::addLayer(std::unique_ptr<flow::ContainerLayer> layer)
{
    DCHECK(layer);
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

void SceneBuilder::pop()
{
    if (!m_currentLayer)
        return;
    m_currentLayer = m_currentLayer->parent();
}

void SceneBuilder::addPicture(const Offset& offset, Picture* picture)
{
    if (!m_currentLayer)
        return;
    std::unique_ptr<flow::PictureLayer> layer(new flow::PictureLayer());
    layer->set_offset(SkPoint::Make(offset.sk_size.width(), offset.sk_size.height()));
    layer->set_picture(picture->toSkia());
    m_currentLayer->Add(std::move(layer));
}

void SceneBuilder::addChildScene(const Offset& offset,
                                 int physical_width,
                                 int physical_height,
                                 uint32_t scene_token) {
    if (!m_currentLayer)
        return;
    std::unique_ptr<flow::ChildSceneLayer> layer(new flow::ChildSceneLayer());
    layer->set_offset(SkPoint::Make(offset.sk_size.width(), offset.sk_size.height()));
    layer->set_physical_size(SkISize::Make(physical_width, physical_height));
    mojo::gfx::composition::SceneTokenPtr token = mojo::gfx::composition::SceneToken::New();
    token->value = scene_token;
    layer->set_scene_token(token.Pass());
    m_currentLayer->Add(std::move(layer));
}

void SceneBuilder::addPerformanceOverlay(uint64_t enabledOptions, const Rect& bounds)
{
    if (!m_currentLayer)
        return;
    std::unique_ptr<flow::PerformanceOverlayLayer> layer(new flow::PerformanceOverlayLayer(enabledOptions));
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
