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

#ifndef FloatRect_h
#define FloatRect_h

#include "platform/geometry/FloatPoint.h"
#include "third_party/skia/include/core/SkRect.h"
#include "wtf/Vector.h"

#if OS(MACOSX)
typedef struct CGRect CGRect;

#ifdef __OBJC__
#import <Foundation/Foundation.h>
#endif
#endif

namespace blink {

class LayoutRect;
class IntRect;

class PLATFORM_EXPORT FloatRect {
public:
    enum ContainsMode {
        InsideOrOnStroke,
        InsideButNotOnStroke
    };

    FloatRect() { }
    FloatRect(const FloatPoint& location, const FloatSize& size)
        : m_location(location), m_size(size) { }
    FloatRect(float x, float y, float width, float height)
        : m_location(FloatPoint(x, y)), m_size(FloatSize(width, height)) { }
    FloatRect(const IntRect&);
    FloatRect(const LayoutRect&);
    FloatRect(const SkRect&);

    static FloatRect narrowPrecision(double x, double y, double width, double height);

    FloatPoint location() const { return m_location; }
    FloatSize size() const { return m_size; }

    void setLocation(const FloatPoint& location) { m_location = location; }
    void setSize(const FloatSize& size) { m_size = size; }

    float x() const { return m_location.x(); }
    float y() const { return m_location.y(); }
    float maxX() const { return x() + width(); }
    float maxY() const { return y() + height(); }
    float width() const { return m_size.width(); }
    float height() const { return m_size.height(); }

    void setX(float x) { m_location.setX(x); }
    void setY(float y) { m_location.setY(y); }
    void setWidth(float width) { m_size.setWidth(width); }
    void setHeight(float height) { m_size.setHeight(height); }

    bool isEmpty() const { return m_size.isEmpty(); }
    bool isZero() const { return m_size.isZero(); }
    bool isExpressibleAsIntRect() const;

    FloatPoint center() const { return FloatPoint(x() + width() / 2, y() + height() / 2); }

    void move(const FloatSize& delta) { m_location += delta; }
    void moveBy(const FloatPoint& delta) { m_location.move(delta.x(), delta.y()); }
    void move(float dx, float dy) { m_location.move(dx, dy); }

    void expand(const FloatSize& size) { m_size += size; }
    void expand(float dw, float dh) { m_size.expand(dw, dh); }
    void contract(const FloatSize& size) { m_size -= size; }
    void contract(float dw, float dh) { m_size.expand(-dw, -dh); }

    void shiftXEdgeTo(float edge)
    {
        float delta = edge - x();
        setX(edge);
        setWidth(std::max(0.0f, width() - delta));
    }
    void shiftMaxXEdgeTo(float edge)
    {
        float delta = edge - maxX();
        setWidth(std::max(0.0f, width() + delta));
    }
    void shiftYEdgeTo(float edge)
    {
        float delta = edge - y();
        setY(edge);
        setHeight(std::max(0.0f, height() - delta));
    }
    void shiftMaxYEdgeTo(float edge)
    {
        float delta = edge - maxY();
        setHeight(std::max(0.0f, height() + delta));
    }

    FloatPoint minXMinYCorner() const { return m_location; } // typically topLeft
    FloatPoint maxXMinYCorner() const { return FloatPoint(m_location.x() + m_size.width(), m_location.y()); } // typically topRight
    FloatPoint minXMaxYCorner() const { return FloatPoint(m_location.x(), m_location.y() + m_size.height()); } // typically bottomLeft
    FloatPoint maxXMaxYCorner() const { return FloatPoint(m_location.x() + m_size.width(), m_location.y() + m_size.height()); } // typically bottomRight

    bool intersects(const FloatRect&) const;
    bool contains(const FloatRect&) const;
    bool contains(const FloatPoint&, ContainsMode = InsideOrOnStroke) const;

    void intersect(const FloatRect&);
    void unite(const FloatRect&);
    void uniteEvenIfEmpty(const FloatRect&);
    void uniteIfNonZero(const FloatRect&);
    void extend(const FloatPoint&);

    // Note, this doesn't match what IntRect::contains(IntPoint&) does; the int version
    // is really checking for containment of 1x1 rect, but that doesn't make sense with floats.
    bool contains(float px, float py) const
    {
        return px >= x() && px <= maxX() && py >= y() && py <= maxY();
    }

    void inflateX(float dx)
    {
        m_location.setX(m_location.x() - dx);
        m_size.setWidth(m_size.width() + dx + dx);
    }
    void inflateY(float dy)
    {
        m_location.setY(m_location.y() - dy);
        m_size.setHeight(m_size.height() + dy + dy);
    }
    void inflate(float d) { inflateX(d); inflateY(d); }
    void scale(float s) { scale(s, s); }
    void scale(float sx, float sy);

    FloatRect transposedRect() const { return FloatRect(m_location.transposedPoint(), m_size.transposedSize()); }

    // Re-initializes this rectangle to fit the sets of passed points.
    void fitToPoints(const FloatPoint& p0, const FloatPoint& p1);
    void fitToPoints(const FloatPoint& p0, const FloatPoint& p1, const FloatPoint& p2);
    void fitToPoints(const FloatPoint& p0, const FloatPoint& p1, const FloatPoint& p2, const FloatPoint& p3);

#if OS(MACOSX)
    FloatRect(const CGRect&);
    operator CGRect() const;
#if defined(__OBJC__) && !defined(NSGEOMETRY_TYPES_SAME_AS_CGGEOMETRY_TYPES)
    FloatRect(const NSRect&);
    operator NSRect() const;
#endif
#endif

    operator SkRect() const { return SkRect::MakeXYWH(x(), y(), width(), height()); }

private:
    FloatPoint m_location;
    FloatSize m_size;

    void setLocationAndSizeFromEdges(float left, float top, float right, float bottom)
    {
        m_location.set(left, top);
        m_size.setWidth(right - left);
        m_size.setHeight(bottom - top);
    }
};

inline FloatRect intersection(const FloatRect& a, const FloatRect& b)
{
    FloatRect c = a;
    c.intersect(b);
    return c;
}

inline FloatRect unionRect(const FloatRect& a, const FloatRect& b)
{
    FloatRect c = a;
    c.unite(b);
    return c;
}

FloatRect unionRect(const Vector<FloatRect>&);

inline FloatRect& operator+=(FloatRect& a, const FloatRect& b)
{
    a.move(b.x(), b.y());
    a.setWidth(a.width() + b.width());
    a.setHeight(a.height() + b.height());
    return a;
}

inline FloatRect operator+(const FloatRect& a, const FloatRect& b)
{
    FloatRect c = a;
    c += b;
    return c;
}

inline bool operator==(const FloatRect& a, const FloatRect& b)
{
    return a.location() == b.location() && a.size() == b.size();
}

inline bool operator!=(const FloatRect& a, const FloatRect& b)
{
    return a.location() != b.location() || a.size() != b.size();
}

PLATFORM_EXPORT IntRect enclosingIntRect(const FloatRect&);

// Returns a valid IntRect contained within the given FloatRect.
PLATFORM_EXPORT IntRect enclosedIntRect(const FloatRect&);

PLATFORM_EXPORT IntRect roundedIntRect(const FloatRect&);

// Map supplied rect from srcRect to an equivalent rect in destRect.
PLATFORM_EXPORT FloatRect mapRect(const FloatRect&, const FloatRect& srcRect, const FloatRect& destRect);

}

#endif
