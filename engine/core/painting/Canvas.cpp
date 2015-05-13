// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/painting/PictureRecorder.h"

#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/Element.h"
#include "sky/engine/core/painting/PaintingTasks.h"
#include "sky/engine/platform/geometry/IntRect.h"
#include "third_party/skia/include/core/SkCanvas.h"

namespace blink {

SkRect toSkRect(const Vector<float>& rect)
{
    ASSERT(rect.size() == 4);
    SkRect sk_rect;
    sk_rect.set(rect[0], rect[1], rect[2], rect[3]);
    return sk_rect;
}

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

void Canvas::saveLayer(const Vector<float>& bounds, const Paint* paint)
{
    if (!m_canvas)
        return;
    ASSERT(m_displayList->isRecording());
    SkRect sk_bounds;
    if (!bounds.isEmpty())
      sk_bounds = toSkRect(bounds);
    m_canvas->saveLayer(!bounds.isEmpty() ? &sk_bounds : nullptr,
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

void Canvas::clipRect(const Vector<float>& rect)
{
    if (!m_canvas)
        return;
    ASSERT(m_displayList->isRecording());
    m_canvas->clipRect(toSkRect(rect));
}

void Canvas::drawPaint(Paint* paint)
{
    if (!m_canvas)
        return;
    ASSERT(paint);
    ASSERT(m_displayList->isRecording());
    m_canvas->drawPaint(paint->paint());
}

void Canvas::drawRect(const Vector<float>& rect, const Paint* paint)
{
    if (!m_canvas)
        return;
    ASSERT(paint);
    ASSERT(m_displayList->isRecording());
    m_canvas->drawRect(toSkRect(rect), paint->paint());
}

void Canvas::drawOval(const Vector<float>& rect, const Paint* paint)
{
    if (!m_canvas)
        return;
    ASSERT(paint);
    ASSERT(m_displayList->isRecording());
    m_canvas->drawOval(toSkRect(rect), paint->paint());
}

void Canvas::drawCircle(float x, float y, float radius, Paint* paint)
{
    if (!m_canvas)
        return;
    ASSERT(paint);
    ASSERT(m_displayList->isRecording());
    m_canvas->drawCircle(x, y, radius, paint->paint());
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
