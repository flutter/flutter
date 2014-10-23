/*
 * Copyright (C) 2004, 2006, 2007 Apple Inc.  All rights reserved.
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

#ifndef FloatPoint_h
#define FloatPoint_h

#include "platform/geometry/FloatSize.h"
#include "platform/geometry/IntPoint.h"
#include "wtf/MathExtras.h"
#include <algorithm>

#if OS(MACOSX)
typedef struct CGPoint CGPoint;

#ifdef __OBJC__
#import <Foundation/Foundation.h>
#endif
#endif

struct SkPoint;

namespace blink {

class IntPoint;
class IntSize;
class LayoutPoint;
class LayoutSize;

class PLATFORM_EXPORT FloatPoint {
public:
    FloatPoint() : m_x(0), m_y(0) { }
    FloatPoint(float x, float y) : m_x(x), m_y(y) { }
    FloatPoint(const IntPoint&);
    FloatPoint(const LayoutPoint&);
    explicit FloatPoint(const FloatSize& size) : m_x(size.width()), m_y(size.height()) { }

    static FloatPoint zero() { return FloatPoint(); }

    static FloatPoint narrowPrecision(double x, double y);

    float x() const { return m_x; }
    float y() const { return m_y; }

    void setX(float x) { m_x = x; }
    void setY(float y) { m_y = y; }
    void set(float x, float y)
    {
        m_x = x;
        m_y = y;
    }
    void move(float dx, float dy)
    {
        m_x += dx;
        m_y += dy;
    }
    void move(const IntSize& a)
    {
        m_x += a.width();
        m_y += a.height();
    }
    void move(const LayoutSize&);
    void move(const FloatSize& a)
    {
        m_x += a.width();
        m_y += a.height();
    }
    void moveBy(const IntPoint& a)
    {
        m_x += a.x();
        m_y += a.y();
    }
    void moveBy(const LayoutPoint&);
    void moveBy(const FloatPoint& a)
    {
        m_x += a.x();
        m_y += a.y();
    }
    void scale(float sx, float sy)
    {
        m_x *= sx;
        m_y *= sy;
    }

    void normalize();

    float dot(const FloatPoint& a) const
    {
        return m_x * a.x() + m_y * a.y();
    }

    float slopeAngleRadians() const;
    float length() const;
    float lengthSquared() const
    {
        return m_x * m_x + m_y * m_y;
    }

    FloatPoint expandedTo(const FloatPoint& other) const
    {
        return FloatPoint(std::max(m_x, other.m_x), std::max(m_y, other.m_y));
    }

    FloatPoint shrunkTo(const FloatPoint& other) const
    {
        return FloatPoint(std::min(m_x, other.m_x), std::min(m_y, other.m_y));
    }

    FloatPoint transposedPoint() const
    {
        return FloatPoint(m_y, m_x);
    }

    FloatPoint scaledBy(float scale) const
    {
        return FloatPoint(m_x * scale, m_y * scale);
    }

#if OS(MACOSX)
    FloatPoint(const CGPoint&);
    operator CGPoint() const;
#if defined(__OBJC__) && !defined(NSGEOMETRY_TYPES_SAME_AS_CGGEOMETRY_TYPES)
    FloatPoint(const NSPoint&);
    operator NSPoint() const;
#endif
#endif

    SkPoint data() const;

private:
    float m_x, m_y;
};


inline FloatPoint& operator+=(FloatPoint& a, const FloatSize& b)
{
    a.move(b.width(), b.height());
    return a;
}

inline FloatPoint& operator+=(FloatPoint& a, const FloatPoint& b)
{
    a.move(b.x(), b.y());
    return a;
}

inline FloatPoint& operator-=(FloatPoint& a, const FloatSize& b)
{
    a.move(-b.width(), -b.height());
    return a;
}

inline FloatPoint operator+(const FloatPoint& a, const FloatSize& b)
{
    return FloatPoint(a.x() + b.width(), a.y() + b.height());
}

inline FloatPoint operator+(const FloatPoint& a, const FloatPoint& b)
{
    return FloatPoint(a.x() + b.x(), a.y() + b.y());
}

inline FloatSize operator-(const FloatPoint& a, const FloatPoint& b)
{
    return FloatSize(a.x() - b.x(), a.y() - b.y());
}

inline FloatPoint operator-(const FloatPoint& a, const FloatSize& b)
{
    return FloatPoint(a.x() - b.width(), a.y() - b.height());
}

inline FloatPoint operator-(const FloatPoint& a)
{
    return FloatPoint(-a.x(), -a.y());
}

inline bool operator==(const FloatPoint& a, const FloatPoint& b)
{
    return a.x() == b.x() && a.y() == b.y();
}

inline bool operator!=(const FloatPoint& a, const FloatPoint& b)
{
    return a.x() != b.x() || a.y() != b.y();
}

inline float operator*(const FloatPoint& a, const FloatPoint& b)
{
    // dot product
    return a.dot(b);
}

inline IntPoint roundedIntPoint(const FloatPoint& p)
{
    return IntPoint(clampToInteger(roundf(p.x())), clampToInteger(roundf(p.y())));
}

inline IntPoint flooredIntPoint(const FloatPoint& p)
{
    return IntPoint(clampToInteger(floorf(p.x())), clampToInteger(floorf(p.y())));
}

inline IntPoint ceiledIntPoint(const FloatPoint& p)
{
    return IntPoint(clampToInteger(ceilf(p.x())), clampToInteger(ceilf(p.y())));
}

inline IntSize flooredIntSize(const FloatPoint& p)
{
    return IntSize(clampToInteger(floorf(p.x())), clampToInteger(floorf(p.y())));
}

inline FloatSize toFloatSize(const FloatPoint& a)
{
    return FloatSize(a.x(), a.y());
}

PLATFORM_EXPORT float findSlope(const FloatPoint& p1, const FloatPoint& p2, float& c);

// Find point where lines through the two pairs of points intersect. Returns false if the lines don't intersect.
PLATFORM_EXPORT bool findIntersection(const FloatPoint& p1, const FloatPoint& p2, const FloatPoint& d1, const FloatPoint& d2, FloatPoint& intersection);

}

#endif
