// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/compositing/SceneBuilder.h"

#include "sky/engine/core/painting/Matrix.h"
#include "third_party/skia/include/core/SkColorFilter.h"

namespace blink {

SceneBuilder::SceneBuilder(const Rect& bounds)
    : m_rootPaintBounds(bounds.sk_rect)
    , m_currentLayer(nullptr)
{
}

SceneBuilder::~SceneBuilder()
{
}

void SceneBuilder::pushTransform(const Float32List& matrix4, ExceptionState& es)
{
    SkMatrix sk_matrix = toSkMatrix(matrix4, es);
    if (es.had_exception())
        return;
    std::unique_ptr<sky::TransformLayer> layer(new sky::TransformLayer());
    layer->set_transform(sk_matrix);
    addLayer(std::move(layer));
}

void SceneBuilder::pushClipRect(const Rect& rect)
{
    std::unique_ptr<sky::ClipRectLayer> layer(new sky::ClipRectLayer());
    layer->set_clip_rect(rect.sk_rect);
    addLayer(std::move(layer));
}

void SceneBuilder::pushClipRRect(const RRect* rrect, const Rect& bounds)
{
    std::unique_ptr<sky::ClipRRectLayer> layer(new sky::ClipRRectLayer());
    layer->set_clip_rrect(rrect->rrect());
    addLayer(std::move(layer));
}

void SceneBuilder::pushClipPath(const CanvasPath* path, const Rect& bounds)
{
    std::unique_ptr<sky::ClipPathLayer> layer(new sky::ClipPathLayer());
    layer->set_clip_path(path->path());
    addLayer(std::move(layer));
}

void SceneBuilder::pushOpacity(int alpha, const Rect& bounds)
{
    std::unique_ptr<sky::OpacityLayer> layer(new sky::OpacityLayer());
    layer->set_paint_bounds(bounds.sk_rect);
    layer->set_alpha(alpha);
    addLayer(std::move(layer));
}

void SceneBuilder::pushColorFilter(SkColor color, SkXfermode::Mode transferMode, const Rect& bounds)
{
    std::unique_ptr<sky::ColorFilterLayer> layer(new sky::ColorFilterLayer());
    layer->set_paint_bounds(bounds.sk_rect);
    layer->set_color(color);
    layer->set_transfer_mode(transferMode);
    addLayer(std::move(layer));
}

void SceneBuilder::addLayer(std::unique_ptr<sky::ContainerLayer> layer)
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
    sky::ContainerLayer* newLayer = layer.get();
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
    std::unique_ptr<sky::PictureLayer> layer(new sky::PictureLayer());
    layer->set_offset(SkPoint::Make(offset.sk_size.width(), offset.sk_size.height()));
    layer->set_picture(picture->toSkia());
    layer->set_paint_bounds(paintBounds.sk_rect);
    m_currentLayer->Add(std::move(layer));
}

PassRefPtr<Scene> SceneBuilder::build()
{
    m_currentLayer = nullptr;
    return Scene::create(std::move(m_rootLayer));
}

} // namespace blink
