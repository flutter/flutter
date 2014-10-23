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

#ifndef LayoutSize_h
#define LayoutSize_h

#include "platform/LayoutUnit.h"
#include "platform/geometry/FloatSize.h"
#include "platform/geometry/IntSize.h"

namespace blink {

enum AspectRatioFit {
    AspectRatioFitShrink,
    AspectRatioFitGrow
};

class LayoutSize {
public:
    LayoutSize() { }
    LayoutSize(const IntSize& size) : m_width(size.width()), m_height(size.height()) { }
    LayoutSize(LayoutUnit width, LayoutUnit height) : m_width(width), m_height(height) { }

    explicit LayoutSize(const FloatSize& size) : m_width(size.width()), m_height(size.height()) { }

    LayoutUnit width() const { return m_width; }
    LayoutUnit height() const { return m_height; }

    void setWidth(LayoutUnit width) { m_width = width; }
    void setHeight(LayoutUnit height) { m_height = height; }

    bool isEmpty() const { return m_width.rawValue() <= 0 || m_height.rawValue() <= 0; }
    bool isZero() const { return !m_width && !m_height; }

    float aspectRatio() const { return m_width.toFloat() / m_height.toFloat(); }

    void expand(LayoutUnit width, LayoutUnit height)
    {
        m_width += width;
        m_height += height;
    }

    void shrink(LayoutUnit width, LayoutUnit height)
    {
        m_width -= width;
        m_height -= height;
    }

    void scale(float scale)
    {
        m_width *= scale;
        m_height *= scale;
    }

    void scale(float widthScale, float heightScale)
    {
        m_width *= widthScale;
        m_height *= heightScale;
    }

    LayoutSize expandedTo(const LayoutSize& other) const
    {
        return LayoutSize(m_width > other.m_width ? m_width : other.m_width,
            m_height > other.m_height ? m_height : other.m_height);
    }

    LayoutSize shrunkTo(const LayoutSize& other) const
    {
        return LayoutSize(m_width < other.m_width ? m_width : other.m_width,
            m_height < other.m_height ? m_height : other.m_height);
    }

    void clampNegativeToZero()
    {
        *this = expandedTo(LayoutSize());
    }

    void clampToMinimumSize(const LayoutSize& minimumSize)
    {
        if (m_width < minimumSize.width())
            m_width = minimumSize.width();
        if (m_height < minimumSize.height())
            m_height = minimumSize.height();
    }

    LayoutSize transposedSize() const
    {
        return LayoutSize(m_height, m_width);
    }

    LayoutSize fitToAspectRatio(const LayoutSize& aspectRatio, AspectRatioFit fit) const
    {
        float heightScale = height().toFloat() / aspectRatio.height().toFloat();
        float widthScale = width().toFloat() / aspectRatio.width().toFloat();
        if ((widthScale > heightScale) != (fit == AspectRatioFitGrow))
            return LayoutSize(height() * aspectRatio.width() / aspectRatio.height(), height());
        return LayoutSize(width(), width() * aspectRatio.height() / aspectRatio.width());
    }

    LayoutSize fraction() const
    {
        return LayoutSize(m_width.fraction(), m_height.fraction());
    }

private:
    LayoutUnit m_width, m_height;
};

inline LayoutSize& operator+=(LayoutSize& a, const LayoutSize& b)
{
    a.setWidth(a.width() + b.width());
    a.setHeight(a.height() + b.height());
    return a;
}

inline LayoutSize& operator-=(LayoutSize& a, const LayoutSize& b)
{
    a.setWidth(a.width() - b.width());
    a.setHeight(a.height() - b.height());
    return a;
}

inline LayoutSize operator+(const LayoutSize& a, const LayoutSize& b)
{
    return LayoutSize(a.width() + b.width(), a.height() + b.height());
}

inline LayoutSize operator-(const LayoutSize& a, const LayoutSize& b)
{
    return LayoutSize(a.width() - b.width(), a.height() - b.height());
}

inline LayoutSize operator-(const LayoutSize& size)
{
    return LayoutSize(-size.width(), -size.height());
}

inline bool operator==(const LayoutSize& a, const LayoutSize& b)
{
    return a.width() == b.width() && a.height() == b.height();
}

inline bool operator!=(const LayoutSize& a, const LayoutSize& b)
{
    return a.width() != b.width() || a.height() != b.height();
}

inline IntSize flooredIntSize(const LayoutSize& s)
{
    return IntSize(s.width().floor(), s.height().floor());
}

inline IntSize roundedIntSize(const LayoutSize& s)
{
    return IntSize(s.width().round(), s.height().round());
}

inline LayoutSize roundedLayoutSize(const FloatSize& s)
{
    return LayoutSize(s);
}

} // namespace blink

#endif // LayoutSize_h
