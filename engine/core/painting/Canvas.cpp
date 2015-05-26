// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/painting/Canvas.h"

#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/Element.h"
#include "sky/engine/core/painting/PaintingTasks.h"
#include "sky/engine/platform/geometry/IntRect.h"
#include "third_party/skia/include/core/SkCanvas.h"

namespace blink {

Canvas::Canvas(const FloatSize& size)
    : m_size(size)
{
    m_displayList = adoptRef(new DisplayList);
    m_canvas = m_displayList->beginRecording(expandedIntSize(m_size));
}

Canvas::~Canvas()
{
}

void Canvas::save()
{
    if (!m_canvas)
        return;
    ASSERT(m_displayList->isRecording());
    m_canvas->save();
}

void Canvas::saveLayer(const Rect& bounds, const Paint* paint)
{
    if (!m_canvas)
        return;
    ASSERT(m_displayList->isRecording());
    m_canvas->saveLayer(!bounds.is_null ? &bounds.sk_rect : nullptr,
                        paint ? &paint->paint() : nullptr);
}

void Canvas::restore()
{
    if (!m_canvas)
        return;
    ASSERT(m_displayList->isRecording());
    m_canvas->restore();
}

void Canvas::translate(float dx, float dy)
{
    if (!m_canvas)
        return;
    ASSERT(m_displayList->isRecording());
    m_canvas->translate(dx, dy);
}

void Canvas::scale(float sx, float sy)
{
    if (!m_canvas)
        return;
    ASSERT(m_displayList->isRecording());
    m_canvas->scale(sx, sy);
}

void Canvas::rotateDegrees(float degrees)
{
    if (!m_canvas)
        return;
    ASSERT(m_displayList->isRecording());
    m_canvas->rotate(degrees);
}

void Canvas::skew(float sx, float sy)
{
    if (!m_canvas)
        return;
    ASSERT(m_displayList->isRecording());
    m_canvas->skew(sx, sy);
}

void Canvas::concat(const Vector<float>& matrix)
{
    if (!m_canvas)
        return;
    ASSERT(m_displayList->isRecording());
    ASSERT(matrix.size() == 9);
    SkMatrix sk_matrix;
    sk_matrix.set9(matrix.data());
    m_canvas->concat(sk_matrix);
}

void Canvas::clipRect(const Rect& rect)
{
    if (!m_canvas)
        return;
    ASSERT(m_displayList->isRecording());
    m_canvas->clipRect(rect.sk_rect);
}

void Canvas::drawPicture(Picture* picture)
{
    if (!m_canvas)
        return;
    ASSERT(picture);
    ASSERT(m_displayList->isRecording());
    m_canvas->drawPicture(picture->toSkia());
}

void Canvas::drawPaint(const Paint* paint)
{
    if (!m_canvas)
        return;
    ASSERT(paint);
    ASSERT(m_displayList->isRecording());
    m_canvas->drawPaint(paint->paint());
}

void Canvas::drawRect(const Rect& rect, const Paint* paint)
{
    if (!m_canvas)
        return;
    ASSERT(paint);
    ASSERT(m_displayList->isRecording());
    m_canvas->drawRect(rect.sk_rect, paint->paint());
}

void Canvas::drawOval(const Rect& rect, const Paint* paint)
{
    if (!m_canvas)
        return;
    ASSERT(paint);
    ASSERT(m_displayList->isRecording());
    m_canvas->drawOval(rect.sk_rect, paint->paint());
}

void Canvas::drawCircle(float x, float y, float radius, const Paint* paint)
{
    if (!m_canvas)
        return;
    ASSERT(paint);
    ASSERT(m_displayList->isRecording());
    m_canvas->drawCircle(x, y, radius, paint->paint());
}

void Canvas::drawPath(const CanvasPath* path, const Paint* paint)
{
    if (!m_canvas)
        return;
    ASSERT(path);
    ASSERT(paint);
    ASSERT(m_displayList->isRecording());
    m_canvas->drawPath(path->path(), paint->paint());
}

PassRefPtr<DisplayList> Canvas::finishRecording()
{
    if (!isRecording())
        return nullptr;
    m_canvas = nullptr;
    m_displayList->endRecording();
    return m_displayList.release();
}

} // namespace blink
