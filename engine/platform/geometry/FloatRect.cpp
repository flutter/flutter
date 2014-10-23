/*
 * Copyright (C) 2003, 2006, 2007 Apple Inc.  All rights reserved.
 * Copyright (C) 2005 Nokia.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "platform/geometry/FloatRect.h"

#include "platform/FloatConversion.h"
#include "platform/geometry/IntRect.h"
#include "platform/geometry/LayoutRect.h"
#include "third_party/skia/include/core/SkRect.h"
#include "wtf/MathExtras.h"

#include <algorithm>
#include <math.h>

namespace blink {

FloatRect::FloatRect(const IntRect& r) : m_location(r.location()), m_size(r.size())
{
}

FloatRect::FloatRect(const LayoutRect& r) : m_location(r.location()), m_size(r.size())
{
}

FloatRect::FloatRect(const SkRect& r) : m_location(r.fLeft, r.fTop), m_size(r.width(), r.height())
{
}

FloatRect FloatRect::narrowPrecision(double x, double y, double width, double height)
{
    return FloatRect(narrowPrecisionToFloat(x), narrowPrecisionToFloat(y), narrowPrecisionToFloat(width), narrowPrecisionToFloat(height));
}

bool FloatRect::isExpressibleAsIntRect() const
{
    return isWithinIntRange(x()) && isWithinIntRange(y())
        && isWithinIntRange(width()) && isWithinIntRange(height())
        && isWithinIntRange(maxX()) && isWithinIntRange(maxY());
}

bool FloatRect::intersects(const FloatRect& other) const
{
    // Checking emptiness handles negative widths as well as zero.
    return !isEmpty() && !other.isEmpty()
        && x() < other.maxX() && other.x() < maxX()
        && y() < other.maxY() && other.y() < maxY();
}

bool FloatRect::contains(const FloatRect& other) const
{
    return x() <= other.x() && maxX() >= other.maxX()
        && y() <= other.y() && maxY() >= other.maxY();
}

bool FloatRect::contains(const FloatPoint& point, ContainsMode containsMode) const
{
    if (containsMode == InsideOrOnStroke)
        return contains(point.x(), point.y());
    return x() < point.x() && maxX() > point.x() && y() < point.y() && maxY() > point.y();
}

void FloatRect::intersect(const FloatRect& other)
{
    float left = std::max(x(), other.x());
    float top = std::max(y(), other.y());
    float right = std::min(maxX(), other.maxX());
    float bottom = std::min(maxY(), other.maxY());

    // Return a clean empty rectangle for non-intersecting cases.
    if (left >= right || top >= bottom) {
        left = 0;
        top = 0;
        right = 0;
        bottom = 0;
    }

    setLocationAndSizeFromEdges(left, top, right, bottom);
}

void FloatRect::unite(const FloatRect& other)
{
    // Handle empty special cases first.
    if (other.isEmpty())
        return;
    if (isEmpty()) {
        *this = other;
        return;
    }

    uniteEvenIfEmpty(other);
}

void FloatRect::uniteEvenIfEmpty(const FloatRect& other)
{
    float minX = std::min(x(), other.x());
    float minY = std::min(y(), other.y());
    float maxX = std::max(this->maxX(), other.maxX());
    float maxY = std::max(this->maxY(), other.maxY());

    setLocationAndSizeFromEdges(minX, minY, maxX, maxY);
}

void FloatRect::uniteIfNonZero(const FloatRect& other)
{
    // Handle empty special cases first.
    if (other.isZero())
        return;
    if (isZero()) {
        *this = other;
        return;
    }

    uniteEvenIfEmpty(other);
}

void FloatRect::extend(const FloatPoint& p)
{
    float minX = std::min(x(), p.x());
    float minY = std::min(y(), p.y());
    float maxX = std::max(this->maxX(), p.x());
    float maxY = std::max(this->maxY(), p.y());

    setLocationAndSizeFromEdges(minX, minY, maxX, maxY);
}

void FloatRect::scale(float sx, float sy)
{
    m_location.setX(x() * sx);
    m_location.setY(y() * sy);
    m_size.setWidth(width() * sx);
    m_size.setHeight(height() * sy);
}

FloatRect unionRect(const Vector<FloatRect>& rects)
{
    FloatRect result;

    size_t count = rects.size();
    for (size_t i = 0; i < count; ++i)
        result.unite(rects[i]);

    return result;
}

void FloatRect::fitToPoints(const FloatPoint& p0, const FloatPoint& p1)
{
    float left = std::min(p0.x(), p1.x());
    float top = std::min(p0.y(), p1.y());
    float right = std::max(p0.x(), p1.x());
    float bottom = std::max(p0.y(), p1.y());

    setLocationAndSizeFromEdges(left, top, right, bottom);
}

namespace {
// Helpers for 3- and 4-way max and min.

template <typename T>
T min3(const T& v1, const T& v2, const T& v3)
{
    return std::min(std::min(v1, v2), v3);
}

template <typename T>
T max3(const T& v1, const T& v2, const T& v3)
{
    return std::max(std::max(v1, v2), v3);
}

template <typename T>
T min4(const T& v1, const T& v2, const T& v3, const T& v4)
{
    return std::min(std::min(v1, v2), std::min(v3, v4));
}

template <typename T>
T max4(const T& v1, const T& v2, const T& v3, const T& v4)
{
    return std::max(std::max(v1, v2), std::max(v3, v4));
}

} // anonymous namespace

void FloatRect::fitToPoints(const FloatPoint& p0, const FloatPoint& p1, const FloatPoint& p2)
{
    float left = min3(p0.x(), p1.x(), p2.x());
    float top = min3(p0.y(), p1.y(), p2.y());
    float right = max3(p0.x(), p1.x(), p2.x());
    float bottom = max3(p0.y(), p1.y(), p2.y());

    setLocationAndSizeFromEdges(left, top, right, bottom);
}

void FloatRect::fitToPoints(const FloatPoint& p0, const FloatPoint& p1, const FloatPoint& p2, const FloatPoint& p3)
{
    float left = min4(p0.x(), p1.x(), p2.x(), p3.x());
    float top = min4(p0.y(), p1.y(), p2.y(), p3.y());
    float right = max4(p0.x(), p1.x(), p2.x(), p3.x());
    float bottom = max4(p0.y(), p1.y(), p2.y(), p3.y());

    setLocationAndSizeFromEdges(left, top, right, bottom);
}

IntRect enclosingIntRect(const FloatRect& rect)
{
    IntPoint location = flooredIntPoint(rect.minXMinYCorner());
    IntPoint maxPoint = ceiledIntPoint(rect.maxXMaxYCorner());

    return IntRect(location, maxPoint - location);
}

IntRect enclosedIntRect(const FloatRect& rect)
{
    IntPoint location = ceiledIntPoint(rect.minXMinYCorner());
    IntPoint maxPoint = flooredIntPoint(rect.maxXMaxYCorner());
    IntSize size = maxPoint - location;
    size.clampNegativeToZero();

    return IntRect(location, size);
}

IntRect roundedIntRect(const FloatRect& rect)
{
    return IntRect(roundedIntPoint(rect.location()), roundedIntSize(rect.size()));
}

FloatRect mapRect(const FloatRect& r, const FloatRect& srcRect, const FloatRect& destRect)
{
    if (!srcRect.width() || !srcRect.height())
        return FloatRect();

    float widthScale = destRect.width() / srcRect.width();
    float heightScale = destRect.height() / srcRect.height();
    return FloatRect(destRect.x() + (r.x() - srcRect.x()) * widthScale,
        destRect.y() + (r.y() - srcRect.y()) * heightScale,
        r.width() * widthScale, r.height() * heightScale);
}

}
