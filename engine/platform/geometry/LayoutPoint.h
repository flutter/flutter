/*
 * Copyright (c) 2012, Google Inc. All rights reserved.
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

#ifndef LayoutPoint_h
#define LayoutPoint_h

#include "platform/geometry/FloatPoint.h"
#include "platform/geometry/LayoutSize.h"
#include "wtf/MathExtras.h"

namespace blink {

class LayoutPoint {
public:
    LayoutPoint() { }
    LayoutPoint(LayoutUnit x, LayoutUnit y) : m_x(x), m_y(y) { }
    LayoutPoint(const IntPoint& point) : m_x(point.x()), m_y(point.y()) { }
    explicit LayoutPoint(const FloatPoint& size) : m_x(size.x()), m_y(size.y()) { }
    explicit LayoutPoint(const LayoutSize& size) : m_x(size.width()), m_y(size.height()) { }

    static LayoutPoint zero() { return LayoutPoint(); }

    LayoutUnit x() const { return m_x; }
    LayoutUnit y() const { return m_y; }

    void setX(LayoutUnit x) { m_x = x; }
    void setY(LayoutUnit y) { m_y = y; }

    void move(const LayoutSize& s) { move(s.width(), s.height()); }
    void moveBy(const LayoutPoint& offset) { move(offset.x(), offset.y()); }
    void move(LayoutUnit dx, LayoutUnit dy) { m_x += dx; m_y += dy; }
    void scale(float sx, float sy)
    {
        m_x *= sx;
        m_y *= sy;
    }

    LayoutPoint expandedTo(const LayoutPoint& other) const
    {
        return LayoutPoint(std::max(m_x, other.m_x), std::max(m_y, other.m_y));
    }

    LayoutPoint shrunkTo(const LayoutPoint& other) const
    {
        return LayoutPoint(std::min(m_x, other.m_x), std::min(m_y, other.m_y));
    }

    void clampNegativeToZero()
    {
        *this = expandedTo(zero());
    }

    LayoutPoint transposedPoint() const
    {
        return LayoutPoint(m_y, m_x);
    }

private:
    LayoutUnit m_x, m_y;
};

ALWAYS_INLINE LayoutPoint& operator+=(LayoutPoint& a, const LayoutSize& b)
{
    a.move(b.width(), b.height());
    return a;
}

ALWAYS_INLINE LayoutPoint& operator-=(LayoutPoint& a, const LayoutSize& b)
{
    a.move(-b.width(), -b.height());
    return a;
}

inline LayoutPoint operator+(const LayoutPoint& a, const LayoutSize& b)
{
    return LayoutPoint(a.x() + b.width(), a.y() + b.height());
}

ALWAYS_INLINE LayoutPoint operator+(const LayoutPoint& a, const LayoutPoint& b)
{
    return LayoutPoint(a.x() + b.x(), a.y() + b.y());
}

ALWAYS_INLINE LayoutSize operator-(const LayoutPoint& a, const LayoutPoint& b)
{
    return LayoutSize(a.x() - b.x(), a.y() - b.y());
}

inline LayoutPoint operator-(const LayoutPoint& a, const LayoutSize& b)
{
    return LayoutPoint(a.x() - b.width(), a.y() - b.height());
}

inline LayoutPoint operator-(const LayoutPoint& point)
{
    return LayoutPoint(-point.x(), -point.y());
}

ALWAYS_INLINE bool operator==(const LayoutPoint& a, const LayoutPoint& b)
{
    return a.x() == b.x() && a.y() == b.y();
}

inline bool operator!=(const LayoutPoint& a, const LayoutPoint& b)
{
    return a.x() != b.x() || a.y() != b.y();
}

inline LayoutPoint toPoint(const LayoutSize& size)
{
    return LayoutPoint(size.width(), size.height());
}

inline LayoutPoint toLayoutPoint(const LayoutSize& p)
{
    return LayoutPoint(p.width(), p.height());
}

inline LayoutSize toSize(const LayoutPoint& a)
{
    return LayoutSize(a.x(), a.y());
}

inline IntPoint flooredIntPoint(const LayoutPoint& point)
{
    return IntPoint(point.x().floor(), point.y().floor());
}

inline IntPoint roundedIntPoint(const LayoutPoint& point)
{
    return IntPoint(point.x().round(), point.y().round());
}

inline IntPoint roundedIntPoint(const LayoutSize& size)
{
    return IntPoint(size.width().round(), size.height().round());
}

inline IntPoint ceiledIntPoint(const LayoutPoint& point)
{
    return IntPoint(point.x().ceil(), point.y().ceil());
}

inline LayoutPoint flooredLayoutPoint(const FloatPoint& p)
{
    return LayoutPoint(LayoutUnit::fromFloatFloor(p.x()), LayoutUnit::fromFloatFloor(p.y()));
}

inline LayoutPoint ceiledLayoutPoint(const FloatPoint& p)
{
    return LayoutPoint(LayoutUnit::fromFloatCeil(p.x()), LayoutUnit::fromFloatCeil(p.y()));
}

inline IntSize pixelSnappedIntSize(const LayoutSize& s, const LayoutPoint& p)
{
    return IntSize(snapSizeToPixel(s.width(), p.x()), snapSizeToPixel(s.height(), p.y()));
}

inline LayoutPoint roundedLayoutPoint(const FloatPoint& p)
{
    return LayoutPoint(p);
}

inline LayoutSize toLayoutSize(const LayoutPoint& p)
{
    return LayoutSize(p.x(), p.y());
}

inline LayoutPoint flooredLayoutPoint(const FloatSize& s)
{
    return flooredLayoutPoint(FloatPoint(s));
}


} // namespace blink

#endif // LayoutPoint_h
