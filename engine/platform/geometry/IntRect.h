/*
 * Copyright (C) 2003, 2006, 2009 Apple Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef IntRect_h
#define IntRect_h

#include "platform/geometry/IntPoint.h"
#include "wtf/FastAllocBase.h"
#include "wtf/Vector.h"
#include "wtf/VectorTraits.h"

#if OS(MACOSX)
typedef struct CGRect CGRect;

#ifdef __OBJC__
#import <Foundation/Foundation.h>
#endif
#endif

struct SkRect;
struct SkIRect;

namespace blink {

class FloatRect;
class LayoutRect;

class PLATFORM_EXPORT IntRect {
    WTF_MAKE_FAST_ALLOCATED;
public:
    IntRect() { }
    IntRect(const IntPoint& location, const IntSize& size)
        : m_location(location), m_size(size) { }
    IntRect(int x, int y, int width, int height)
        : m_location(IntPoint(x, y)), m_size(IntSize(width, height)) { }

    explicit IntRect(const FloatRect&); // don't do this implicitly since it's lossy
    explicit IntRect(const LayoutRect&); // don't do this implicitly since it's lossy

    IntPoint location() const { return m_location; }
    IntSize size() const { return m_size; }

    void setLocation(const IntPoint& location) { m_location = location; }
    void setSize(const IntSize& size) { m_size = size; }

    int x() const { return m_location.x(); }
    int y() const { return m_location.y(); }
    int maxX() const { return x() + width(); }
    int maxY() const { return y() + height(); }
    int width() const { return m_size.width(); }
    int height() const { return m_size.height(); }

    void setX(int x) { m_location.setX(x); }
    void setY(int y) { m_location.setY(y); }
    void setWidth(int width) { m_size.setWidth(width); }
    void setHeight(int height) { m_size.setHeight(height); }

    bool isEmpty() const { return m_size.isEmpty(); }

    // NOTE: The result is rounded to integer values, and thus may be not the exact
    // center point.
    IntPoint center() const { return IntPoint(x() + width() / 2, y() + height() / 2); }

    void move(const IntSize& size) { m_location += size; }
    void moveBy(const IntPoint& offset) { m_location.move(offset.x(), offset.y()); }
    void move(int dx, int dy) { m_location.move(dx, dy); }

    void expand(const IntSize& size) { m_size += size; }
    void expand(int dw, int dh) { m_size.expand(dw, dh); }
    void contract(const IntSize& size) { m_size -= size; }
    void contract(int dw, int dh) { m_size.expand(-dw, -dh); }

    void shiftXEdgeTo(int edge)
    {
        int delta = edge - x();
        setX(edge);
        setWidth(std::max(0, width() - delta));
    }
    void shiftMaxXEdgeTo(int edge)
    {
        int delta = edge - maxX();
        setWidth(std::max(0, width() + delta));
    }
    void shiftYEdgeTo(int edge)
    {
        int delta = edge - y();
        setY(edge);
        setHeight(std::max(0, height() - delta));
    }
    void shiftMaxYEdgeTo(int edge)
    {
        int delta = edge - maxY();
        setHeight(std::max(0, height() + delta));
    }

    IntPoint minXMinYCorner() const { return m_location; } // typically topLeft
    IntPoint maxXMinYCorner() const { return IntPoint(m_location.x() + m_size.width(), m_location.y()); } // typically topRight
    IntPoint minXMaxYCorner() const { return IntPoint(m_location.x(), m_location.y() + m_size.height()); } // typically bottomLeft
    IntPoint maxXMaxYCorner() const { return IntPoint(m_location.x() + m_size.width(), m_location.y() + m_size.height()); } // typically bottomRight

    bool intersects(const IntRect&) const;
    bool contains(const IntRect&) const;

    // This checks to see if the rect contains x,y in the traditional sense.
    // Equivalent to checking if the rect contains a 1x1 rect below and to the right of (px,py).
    bool contains(int px, int py) const
        { return px >= x() && px < maxX() && py >= y() && py < maxY(); }
    bool contains(const IntPoint& point) const { return contains(point.x(), point.y()); }

    void intersect(const IntRect&);
    void unite(const IntRect&);
    void uniteIfNonZero(const IntRect&);

    void inflateX(int dx)
    {
        m_location.setX(m_location.x() - dx);
        m_size.setWidth(m_size.width() + dx + dx);
    }
    void inflateY(int dy)
    {
        m_location.setY(m_location.y() - dy);
        m_size.setHeight(m_size.height() + dy + dy);
    }
    void inflate(int d) { inflateX(d); inflateY(d); }
    void scale(float s);

    IntSize differenceToPoint(const IntPoint&) const;
    int distanceSquaredToPoint(const IntPoint& p) const { return differenceToPoint(p).diagonalLengthSquared(); }

    IntRect transposedRect() const { return IntRect(m_location.transposedPoint(), m_size.transposedSize()); }

#if OS(MACOSX)
    operator CGRect() const;
#if defined(__OBJC__) && !defined(NSGEOMETRY_TYPES_SAME_AS_CGGEOMETRY_TYPES)
    operator NSRect() const;
#endif
#endif

    operator SkRect() const;
    operator SkIRect() const;

#ifndef NDEBUG
    // Prints the rect to the screen.
    void show() const;
#endif

private:
    IntPoint m_location;
    IntSize m_size;
};

inline IntRect intersection(const IntRect& a, const IntRect& b)
{
    IntRect c = a;
    c.intersect(b);
    return c;
}

inline IntRect unionRect(const IntRect& a, const IntRect& b)
{
    IntRect c = a;
    c.unite(b);
    return c;
}

PLATFORM_EXPORT IntRect unionRect(const Vector<IntRect>&);

inline bool operator==(const IntRect& a, const IntRect& b)
{
    return a.location() == b.location() && a.size() == b.size();
}

inline bool operator!=(const IntRect& a, const IntRect& b)
{
    return a.location() != b.location() || a.size() != b.size();
}

#if OS(MACOSX)
PLATFORM_EXPORT IntRect enclosingIntRect(const CGRect&);
#if defined(__OBJC__) && !defined(NSGEOMETRY_TYPES_SAME_AS_CGGEOMETRY_TYPES)
PLATFORM_EXPORT IntRect enclosingIntRect(const NSRect&);
#endif
#endif

} // namespace blink

WTF_ALLOW_MOVE_INIT_AND_COMPARE_WITH_MEM_FUNCTIONS(blink::IntRect);

#endif // IntRect_h
