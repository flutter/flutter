/*
 * Copyright (C) 2011 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "web/painting/PaintAggregator.h"

#include "public/platform/Platform.h"

using namespace blink;

namespace blink {

// ----------------------------------------------------------------------------
// ALGORITHM NOTES
//
// We attempt to maintain a scroll rect in the presence of invalidations that
// are contained within the scroll rect. If an invalidation crosses a scroll
// rect, then we just treat the scroll rect as an invalidation rect.
//
// For invalidations performed prior to scrolling and contained within the
// scroll rect, we offset the invalidation rects to account for the fact that
// the consumer will perform scrolling before painting.
//
// We only support scrolling along one axis at a time. A diagonal scroll will
// therefore be treated as an invalidation.
// ----------------------------------------------------------------------------

// If the combined area of paint rects contained within the scroll rect grows
// too large, then we might as well just treat the scroll rect as a paint rect.
// This constant sets the max ratio of paint rect area to scroll rect area that
// we will tolerate before dograding the scroll into a repaint.
static const float maxRedundantPaintToScrollArea = 0.8f;

// The maximum number of paint rects. If we exceed this limit, then we'll
// start combining paint rects (see CombinePaintRects). This limiting is
// important since the WebKit code associated with deciding what to paint given
// a paint rect can be significant.
static const size_t maxPaintRects = 5;

// If the combined area of paint rects divided by the area of the union of all
// paint rects exceeds this threshold, then we will combine the paint rects.
static const float maxPaintRectsAreaRatio = 0.7f;

static int calculateArea(const IntRect& rect)
{
    return rect.size().width() * rect.size().height();
}

// Subtracts out the intersection of |a| and |b| from |a|, assuming |b| fully
// overlaps with |a| in either the x- or y-direction. If there is no full
// overlap, then |a| is returned.
static IntRect subtractIntersection(const IntRect& a, const IntRect& b)
{
    // boundary cases:
    if (!a.intersects(b))
        return a;
    if (b.contains(a))
        return IntRect();

    int rx = a.x();
    int ry = a.y();
    int rr = a.maxX();
    int rb = a.maxY();

    if (b.y() <= a.y() && b.maxY() >= a.maxY()) {
        // complete intersection in the y-direction
        if (b.x() <= a.x())
            rx = b.maxX();
        else
            rr = b.x();
    } else if (b.x() <= a.x() && b.maxX() >= a.maxX()) {
        // complete intersection in the x-direction
        if (b.y() <= a.y())
            ry = b.maxY();
        else
            rb = b.y();
    }
    return IntRect(rx, ry, rr - rx, rb - ry);
}

// Returns true if |a| and |b| share an entire edge (i.e., same width or same
// height), and the rectangles do not overlap.
static bool sharesEdge(const IntRect& a, const IntRect& b)
{
    return (a.y() == b.y() && a.height() == b.height() && (a.x() == b.maxX() || a.maxX() == b.x()))
        || (a.x() == b.x() && a.width() == b.width() && (a.y() == b.maxY() || a.maxY() == b.y()));
}

PaintAggregator::PendingUpdate::PendingUpdate()
{
}

PaintAggregator::PendingUpdate::~PendingUpdate()
{
}

IntRect PaintAggregator::PendingUpdate::calculateScrollDamage() const
{
    // Should only be scrolling in one direction at a time.
    ASSERT(!(scrollDelta.x() && scrollDelta.y()));

    IntRect damagedRect;

    // Compute the region we will expose by scrolling, and paint that into a
    // shared memory section.
    if (scrollDelta.x()) {
        int dx = scrollDelta.x();
        damagedRect.setY(scrollRect.y());
        damagedRect.setHeight(scrollRect.height());
        if (dx > 0) {
            damagedRect.setX(scrollRect.x());
            damagedRect.setWidth(dx);
        } else {
            damagedRect.setX(scrollRect.maxX() + dx);
            damagedRect.setWidth(-dx);
        }
    } else {
        int dy = scrollDelta.y();
        damagedRect.setX(scrollRect.x());
        damagedRect.setWidth(scrollRect.width());
        if (dy > 0) {
            damagedRect.setY(scrollRect.y());
            damagedRect.setHeight(dy);
        } else {
            damagedRect.setY(scrollRect.maxY() + dy);
            damagedRect.setHeight(-dy);
        }
    }

    // In case the scroll offset exceeds the width/height of the scroll rect
    return intersection(scrollRect, damagedRect);
}

IntRect PaintAggregator::PendingUpdate::calculatePaintBounds() const
{
    IntRect bounds;
    for (size_t i = 0; i < paintRects.size(); ++i)
        bounds.unite(paintRects[i]);
    return bounds;
}

bool PaintAggregator::hasPendingUpdate() const
{
    return !m_update.scrollRect.isEmpty() || !m_update.paintRects.isEmpty();
}

void PaintAggregator::clearPendingUpdate()
{
    m_update = PendingUpdate();
}

void PaintAggregator::popPendingUpdate(PendingUpdate* update)
{
    // Combine paint rects if their combined area is not sufficiently less than
    // the area of the union of all paint rects. We skip this if there is a
    // scroll rect since scrolling benefits from smaller paint rects.
    if (m_update.scrollRect.isEmpty() && m_update.paintRects.size() > 1) {
        int paintArea = 0;
        IntRect unionRect;
        for (size_t i = 0; i < m_update.paintRects.size(); ++i) {
            paintArea += calculateArea(m_update.paintRects[i]);
            unionRect.unite(m_update.paintRects[i]);
        }
        int unionArea = calculateArea(unionRect);
        if (float(paintArea) / float(unionArea) > maxPaintRectsAreaRatio)
            combinePaintRects();
    }
    *update = m_update;
    clearPendingUpdate();
}

void PaintAggregator::invalidateRect(const IntRect& rect)
{
    // Combine overlapping paints using smallest bounding box.
    for (size_t i = 0; i < m_update.paintRects.size(); ++i) {
        const IntRect& existingRect = m_update.paintRects[i];
        if (existingRect.contains(rect)) // Optimize out redundancy.
            return;
        if (rect.intersects(existingRect) || sharesEdge(rect, existingRect)) {
            // Re-invalidate in case the union intersects other paint rects.
            IntRect combinedRect = unionRect(existingRect, rect);
            m_update.paintRects.remove(i);
            invalidateRect(combinedRect);
            return;
        }
    }

    // Add a non-overlapping paint.
    m_update.paintRects.append(rect);

    // If the new paint overlaps with a scroll, then it forces an invalidation of
    // the scroll. If the new paint is contained by a scroll, then trim off the
    // scroll damage to avoid redundant painting.
    if (!m_update.scrollRect.isEmpty()) {
        if (shouldInvalidateScrollRect(rect))
            invalidateScrollRect();
        else if (m_update.scrollRect.contains(rect)) {
            m_update.paintRects[m_update.paintRects.size() - 1] =
                subtractIntersection(rect, m_update.calculateScrollDamage());
            if (m_update.paintRects[m_update.paintRects.size() - 1].isEmpty())
                m_update.paintRects.remove(m_update.paintRects.size() - 1);
        }
    }

    if (m_update.paintRects.size() > maxPaintRects)
        combinePaintRects();

    // Track how large the paintRects vector grows during an invalidation
    // sequence. Note: A subsequent invalidation may end up being combined
    // with all existing paints, which means that tracking the size of
    // paintRects at the time when popPendingUpdate() is called may mask
    // certain performance problems.
    blink::Platform::current()->histogramCustomCounts("MPArch.RW_IntermediatePaintRectCount",
                                          m_update.paintRects.size(), 1, 100, 50);
}

void PaintAggregator::scrollRect(int dx, int dy, const IntRect& clipRect)
{
    // We only support scrolling along one axis at a time.
    if (dx && dy) {
        invalidateRect(clipRect);
        return;
    }

    // We can only scroll one rect at a time.
    if (!m_update.scrollRect.isEmpty() && m_update.scrollRect != clipRect) {
        invalidateRect(clipRect);
        return;
    }

    // Again, we only support scrolling along one axis at a time. Make sure this
    // update doesn't scroll on a different axis than any existing one.
    if ((dx && m_update.scrollDelta.y()) || (dy && m_update.scrollDelta.x())) {
        invalidateRect(clipRect);
        return;
    }

    // The scroll rect is new or isn't changing (though the scroll amount may
    // be changing).
    m_update.scrollRect = clipRect;
    m_update.scrollDelta.move(dx, dy);

    // We might have just wiped out a pre-existing scroll.
    if (m_update.scrollDelta == IntPoint()) {
        m_update.scrollRect = IntRect();
        return;
    }

    // Adjust any contained paint rects and check for any overlapping paints.
    for (size_t i = 0; i < m_update.paintRects.size(); ++i) {
        if (m_update.scrollRect.contains(m_update.paintRects[i])) {
            m_update.paintRects[i] = scrollPaintRect(m_update.paintRects[i], dx, dy);
            // The rect may have been scrolled out of view.
            if (m_update.paintRects[i].isEmpty()) {
                m_update.paintRects.remove(i);
                i--;
            }
        } else if (m_update.scrollRect.intersects(m_update.paintRects[i])) {
            invalidateScrollRect();
            return;
        }
    }

    // If the new scroll overlaps too much with contained paint rects, then force
    // an invalidation of the scroll.
    if (shouldInvalidateScrollRect(IntRect()))
        invalidateScrollRect();
}

IntRect PaintAggregator::scrollPaintRect(const IntRect& paintRect, int dx, int dy) const
{
    IntRect result = paintRect;

    result.move(dx, dy);
    result = intersection(m_update.scrollRect, result);

    // Subtract out the scroll damage rect to avoid redundant painting.
    return subtractIntersection(result, m_update.calculateScrollDamage());
}

bool PaintAggregator::shouldInvalidateScrollRect(const IntRect& rect) const
{
    if (!rect.isEmpty()) {
        if (!m_update.scrollRect.intersects(rect))
            return false;

        if (!m_update.scrollRect.contains(rect))
            return true;
    }

    // Check if the combined area of all contained paint rects plus this new
    // rect comes too close to the area of the scrollRect. If so, then we
    // might as well invalidate the scroll rect.

    int paintArea = calculateArea(rect);
    for (size_t i = 0; i < m_update.paintRects.size(); ++i) {
        const IntRect& existingRect = m_update.paintRects[i];
        if (m_update.scrollRect.contains(existingRect))
            paintArea += calculateArea(existingRect);
    }
    int scrollArea = calculateArea(m_update.scrollRect);
    if (float(paintArea) / float(scrollArea) > maxRedundantPaintToScrollArea)
        return true;

    return false;
}

void PaintAggregator::invalidateScrollRect()
{
    IntRect scrollRect = m_update.scrollRect;
    m_update.scrollRect = IntRect();
    m_update.scrollDelta = IntPoint();
    invalidateRect(scrollRect);
}

void PaintAggregator::combinePaintRects()
{
    // Combine paint rects do to at most two rects: one inside the scrollRect
    // and one outside the scrollRect. If there is no scrollRect, then just
    // use the smallest bounding box for all paint rects.
    //
    // NOTE: This is a fairly simple algorithm. We could get fancier by only
    // combining two rects to get us under the maxPaintRects limit, but if we
    // reach this method then it means we're hitting a rare case, so there's no
    // need to over-optimize it.
    //
    if (m_update.scrollRect.isEmpty()) {
        IntRect bounds = m_update.calculatePaintBounds();
        m_update.paintRects.clear();
        m_update.paintRects.append(bounds);
    } else {
        IntRect inner, outer;
        for (size_t i = 0; i < m_update.paintRects.size(); ++i) {
            const IntRect& existingRect = m_update.paintRects[i];
            if (m_update.scrollRect.contains(existingRect))
                inner.unite(existingRect);
            else
                outer.unite(existingRect);
        }
        m_update.paintRects.clear();
        m_update.paintRects.append(inner);
        m_update.paintRects.append(outer);
    }
}

} // namespace blink
