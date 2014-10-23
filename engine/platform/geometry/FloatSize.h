/*
 * Copyright (C) 2003, 2006 Apple Computer, Inc.  All rights reserved.
 * Copyright (C) 2005 Nokia.  All rights reserved.
 *               2008 Eric Seidel <eric@webkit.org>
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

#ifndef FloatSize_h
#define FloatSize_h

#include "platform/geometry/IntPoint.h"
#include "wtf/MathExtras.h"

#if OS(MACOSX)
typedef struct CGSize CGSize;

#ifdef __OBJC__
#import <Foundation/Foundation.h>
#endif
#endif

namespace blink {

class IntSize;
class LayoutSize;

class PLATFORM_EXPORT FloatSize {
public:
    FloatSize() : m_width(0), m_height(0) { }
    FloatSize(float width, float height) : m_width(width), m_height(height) { }
    FloatSize(const IntSize& size) : m_width(size.width()), m_height(size.height()) { }
    FloatSize(const LayoutSize&);

    static FloatSize narrowPrecision(double width, double height);

    float width() const { return m_width; }
    float height() const { return m_height; }

    void setWidth(float width) { m_width = width; }
    void setHeight(float height) { m_height = height; }

    bool isEmpty() const { return m_width <= 0 || m_height <= 0; }
    bool isZero() const;
    bool isExpressibleAsIntSize() const;

    float aspectRatio() const { return m_width / m_height; }

    void expand(float width, float height)
    {
        m_width += width;
        m_height += height;
    }

    void scale(float s) { scale(s, s); }

    void scale(float scaleX, float scaleY)
    {
        m_width *= scaleX;
        m_height *= scaleY;
    }

    FloatSize expandedTo(const FloatSize& other) const
    {
        return FloatSize(m_width > other.m_width ? m_width : other.m_width,
            m_height > other.m_height ? m_height : other.m_height);
    }

    FloatSize shrunkTo(const FloatSize& other) const
    {
        return FloatSize(m_width < other.m_width ? m_width : other.m_width,
            m_height < other.m_height ? m_height : other.m_height);
    }

    float diagonalLength() const;
    float diagonalLengthSquared() const
    {
        return m_width * m_width + m_height * m_height;
    }

    FloatSize transposedSize() const
    {
        return FloatSize(m_height, m_width);
    }

    FloatSize scaledBy(float scale) const
    {
        return scaledBy(scale, scale);
    }

    FloatSize scaledBy(float scaleX, float scaleY) const
    {
        return FloatSize(m_width * scaleX, m_height * scaleY);
    }

#if OS(MACOSX)
    explicit FloatSize(const CGSize&); // don't do this implicitly since it's lossy
    operator CGSize() const;
#if defined(__OBJC__) && !defined(NSGEOMETRY_TYPES_SAME_AS_CGGEOMETRY_TYPES)
    explicit FloatSize(const NSSize &); // don't do this implicitly since it's lossy
    operator NSSize() const;
#endif
#endif

private:
    float m_width, m_height;
};

inline FloatSize& operator+=(FloatSize& a, const FloatSize& b)
{
    a.setWidth(a.width() + b.width());
    a.setHeight(a.height() + b.height());
    return a;
}

inline FloatSize& operator-=(FloatSize& a, const FloatSize& b)
{
    a.setWidth(a.width() - b.width());
    a.setHeight(a.height() - b.height());
    return a;
}

inline FloatSize operator+(const FloatSize& a, const FloatSize& b)
{
    return FloatSize(a.width() + b.width(), a.height() + b.height());
}

inline FloatSize operator-(const FloatSize& a, const FloatSize& b)
{
    return FloatSize(a.width() - b.width(), a.height() - b.height());
}

inline FloatSize operator-(const FloatSize& size)
{
    return FloatSize(-size.width(), -size.height());
}

inline FloatSize operator*(const FloatSize& a, const float b)
{
    return FloatSize(a.width() * b, a.height() * b);
}

inline FloatSize operator*(const float a, const FloatSize& b)
{
    return FloatSize(a * b.width(), a * b.height());
}

inline bool operator==(const FloatSize& a, const FloatSize& b)
{
    return a.width() == b.width() && a.height() == b.height();
}

inline bool operator!=(const FloatSize& a, const FloatSize& b)
{
    return a.width() != b.width() || a.height() != b.height();
}

inline IntSize roundedIntSize(const FloatSize& p)
{
    return IntSize(clampToInteger(roundf(p.width())), clampToInteger(roundf(p.height())));
}

inline IntSize flooredIntSize(const FloatSize& p)
{
    return IntSize(clampToInteger(floorf(p.width())), clampToInteger(floorf(p.height())));
}

inline IntSize expandedIntSize(const FloatSize& p)
{
    return IntSize(clampToInteger(ceilf(p.width())), clampToInteger(ceilf(p.height())));
}

inline IntPoint flooredIntPoint(const FloatSize& p)
{
    return IntPoint(clampToInteger(floorf(p.width())), clampToInteger(floorf(p.height())));
}

} // namespace blink

#endif // FloatSize_h
