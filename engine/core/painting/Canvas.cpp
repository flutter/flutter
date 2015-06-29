// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "math.h"

#include "sky/engine/core/painting/Canvas.h"

#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/Element.h"
#include "sky/engine/core/painting/CanvasImage.h"
#include "sky/engine/core/painting/PaintingTasks.h"
#include "sky/engine/platform/geometry/IntRect.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkBitmap.h"

namespace blink {

Canvas::Canvas(SkCanvas* skCanvas)
    : m_canvas(skCanvas)
{
}

Canvas::~Canvas()
{
}

void Canvas::save()
{
    if (!m_canvas)
        return;
    m_canvas->save();
}

void Canvas::saveLayer(const Rect& bounds, const Paint* paint)
{
    if (!m_canvas)
        return;
    m_canvas->saveLayer(!bounds.is_null ? &bounds.sk_rect : nullptr,
                        paint ? &paint->paint() : nullptr);
}

void Canvas::restore()
{
    if (!m_canvas)
        return;
    m_canvas->restore();
}

void Canvas::translate(float dx, float dy)
{
    if (!m_canvas)
        return;
    m_canvas->translate(dx, dy);
}

void Canvas::scale(float sx, float sy)
{
    if (!m_canvas)
        return;
    m_canvas->scale(sx, sy);
}

void Canvas::rotate(float radians)
{
    if (!m_canvas)
        return;
    m_canvas->rotate(radians * 180.0/M_PI);
}

void Canvas::skew(float sx, float sy)
{
    if (!m_canvas)
        return;
    m_canvas->skew(sx, sy);
}

void Canvas::concat(const Float32List& matrix4)
{
    if (!m_canvas)
        return;
    ASSERT(matrix4.data());

    // TODO(mpcomplete): how can we raise an error in this case?
    if (matrix4.num_elements() != 16)
      return;

    SkMatrix sk_matrix;
    // Mappings from SkMatrix-index to input-index.
    static const int kMappings[] = {
      0, 4, 12,
      1, 5, 13,
      3, 7, 15,
    };
    for (intptr_t i = 0; i < 9; ++i)
      sk_matrix[i] = matrix4.data()[kMappings[i]];

    m_canvas->concat(sk_matrix);
}

void Canvas::clipRect(const Rect& rect)
{
    if (!m_canvas)
        return;
    m_canvas->clipRect(rect.sk_rect);
}

void Canvas::clipRRect(const RRect* rrect)
{
    if (!m_canvas)
        return;
    m_canvas->clipRRect(rrect->rrect(), SkRegion::kIntersect_Op, true);
}

void Canvas::clipPath(const CanvasPath* path)
{
    if (!m_canvas)
        return;
    m_canvas->clipPath(path->path(), SkRegion::kIntersect_Op, true);
}

void Canvas::drawLine(const Point& p1, const Point& p2, const Paint* paint)
{
    if (!m_canvas)
        return;
    ASSERT(paint);
    m_canvas->drawLine(p1.sk_point.x(), p1.sk_point.y(), p2.sk_point.x(), p2.sk_point.y(), paint->paint());
}

void Canvas::drawPicture(Picture* picture)
{
    if (!m_canvas)
        return;
    ASSERT(picture);
    m_canvas->drawPicture(picture->toSkia());
}

void Canvas::drawPaint(const Paint* paint)
{
    if (!m_canvas)
        return;
    ASSERT(paint);
    m_canvas->drawPaint(paint->paint());
}

void Canvas::drawRect(const Rect& rect, const Paint* paint)
{
    if (!m_canvas)
        return;
    ASSERT(paint);
    m_canvas->drawRect(rect.sk_rect, paint->paint());
}

void Canvas::drawRRect(const RRect* rrect, const Paint* paint)
{
    if (!m_canvas)
        return;
    ASSERT(rrect);
    ASSERT(paint);
    m_canvas->drawRRect(rrect->rrect(), paint->paint());
}

void Canvas::drawOval(const Rect& rect, const Paint* paint)
{
    if (!m_canvas)
        return;
    ASSERT(paint);
    m_canvas->drawOval(rect.sk_rect, paint->paint());
}

void Canvas::drawCircle(const Point& c, float radius, const Paint* paint)
{
    if (!m_canvas)
        return;
    ASSERT(paint);
    m_canvas->drawCircle(c.sk_point.x(), c.sk_point.y(), radius, paint->paint());
}

void Canvas::drawPath(const CanvasPath* path, const Paint* paint)
{
    if (!m_canvas)
        return;
    ASSERT(path);
    ASSERT(paint);
    m_canvas->drawPath(path->path(), paint->paint());
}

void Canvas::drawImage(const CanvasImage* image, const Point& p, const Paint* paint) {
    if (!m_canvas)
        return;
    ASSERT(image);
    m_canvas->drawBitmap(image->bitmap(), p.sk_point.x(), p.sk_point.y(), &paint->paint());
}

void Canvas::drawImageRect(const CanvasImage* image, Rect& src, Rect& dst, Paint* paint) {
    if (!m_canvas)
        return;
    ASSERT(image);
    m_canvas->drawBitmapRectToRect(image->bitmap(), &src.sk_rect, dst.sk_rect, &paint->paint());
}

} // namespace blink
