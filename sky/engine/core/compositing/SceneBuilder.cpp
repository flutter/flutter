// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/compositing/SceneBuilder.h"

#include "sky/engine/core/painting/Matrix.h"
#include "third_party/skia/include/core/SkColorFilter.h"

namespace blink {

SceneBuilder::SceneBuilder(const Rect& bounds)
{
    m_canvas = m_pictureRecorder.beginRecording(bounds.sk_rect,
        &m_rtreeFactory, SkPictureRecorder::kComputeSaveLayerInfo_RecordFlag);
}

SceneBuilder::~SceneBuilder()
{
}

void SceneBuilder::pushTransform(const Float32List& matrix4, ExceptionState& es)
{
    SkMatrix sk_matrix = toSkMatrix(matrix4, es);
    if (es.had_exception())
        return;
    m_canvas->save();
    m_canvas->concat(sk_matrix);
}

void SceneBuilder::pushClipRect(const Rect& rect)
{
    if (!m_canvas)
        return;
    m_canvas->save();
    m_canvas->clipRect(rect.sk_rect);
}

void SceneBuilder::pushClipRRect(const RRect* rrect, const Rect& bounds)
{
    if (!m_canvas)
        return;
    m_canvas->saveLayer(&bounds.sk_rect, nullptr);
    m_canvas->clipRRect(rrect->rrect());
}

void SceneBuilder::pushClipPath(const CanvasPath* path, const Rect& bounds)
{
    if (!m_canvas)
        return;
    m_canvas->saveLayer(&bounds.sk_rect, nullptr);
    m_canvas->clipPath(path->path());
}

void SceneBuilder::pushOpacity(int alpha, const Rect& bounds)
{
    if (!m_canvas)
        return;
    SkColor color = SkColorSetARGB(alpha, 0, 0, 0);
    RefPtr<SkColorFilter> colorFilter = adoptRef(SkColorFilter::CreateModeFilter(color, SkXfermode::kSrcOver_Mode));
    SkPaint paint;
    paint.setColorFilter(colorFilter.get());
    m_canvas->saveLayer(&bounds.sk_rect, &paint);
}

void SceneBuilder::pushColorFilter(SkColor color, SkXfermode::Mode transferMode, const Rect& bounds)
{
    if (!m_canvas)
        return;
    RefPtr<SkColorFilter> colorFilter = adoptRef(SkColorFilter::CreateModeFilter(color, transferMode));
    SkPaint paint;
    paint.setColorFilter(colorFilter.get());
    m_canvas->saveLayer(&bounds.sk_rect, &paint);
}

void SceneBuilder::pop()
{
    if (!m_canvas)
        return;
    m_canvas->restore();
}

void SceneBuilder::addPicture(const Offset& offset, Picture* picture, const Rect& paintBounds)
{
    if (!m_canvas)
        return;
    m_canvas->save();
    m_canvas->translate(offset.sk_size.width(), offset.sk_size.height());
    m_canvas->drawPicture(picture->toSkia());
    m_canvas->restore();
}

PassRefPtr<Scene> SceneBuilder::build()
{
    RefPtr<Scene> scene = Scene::create(adoptRef(m_pictureRecorder.endRecording()));
    m_canvas = nullptr;
    return scene.release();
}

} // namespace blink
