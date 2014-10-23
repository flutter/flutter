/*
 * Copyright (C) 2013 Adobe Systems Incorporated. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer.
 * 2. Redistributions in binary form must reproduce the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer in the documentation and/or other materials
 *    provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER “AS IS” AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
 * OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
 * THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#ifndef FloatBoxExtent_h
#define FloatBoxExtent_h

#include "platform/geometry/FloatRect.h"

namespace blink {

class FloatBoxExtent {
public:
    FloatBoxExtent()
        : m_top(0)
        , m_right(0)
        , m_bottom(0)
        , m_left(0)
    {
    }

    FloatBoxExtent(float top, float right, float bottom, float left)
        : m_top(top)
        , m_right(right)
        , m_bottom(bottom)
        , m_left(left)
    {
    }

    float top() const { return m_top; }
    void setTop(float top) { m_top = top; }

    float right() const { return m_right; }
    void setRight(float right) { m_right = right; }

    float bottom() const { return m_bottom; }
    void setBottom(float bottom) { m_bottom = bottom; }

    float left() const { return m_left; }
    void setLeft(float left) { m_left = left; }

    bool isZero() const { return !left() && !right() && !top() && !bottom(); }

    void expandRect(FloatRect& rect) const
    {
        if (isZero())
            return;

        rect.move(-left(), -top());
        rect.expand(left() + right(), top() + bottom());
    }

    void unite(const FloatBoxExtent& other)
    {
        m_top = std::min(m_top, other.top());
        m_right = std::max(m_right, other.right());
        m_bottom = std::max(m_bottom, other.bottom());
        m_left = std::min(m_left, other.left());
    }

    void unite(const FloatRect& rect)
    {
        m_top = std::min(m_top, rect.y());
        m_right = std::max(m_right, rect.maxX());
        m_bottom = std::max(m_bottom, rect.maxY());
        m_left = std::min(m_left, rect.x());
    }

private:
    float m_top;
    float m_right;
    float m_bottom;
    float m_left;
};

inline bool operator==(const FloatBoxExtent& a, const FloatBoxExtent& b)
{
    return a.top() == b.top()
        && a.right() == b.right()
        && a.bottom() == b.bottom()
        && a.left() == b.left();
}

inline bool operator!=(const FloatBoxExtent& a, const FloatBoxExtent& b)
{
    return !(a == b);
}

inline void operator+=(FloatBoxExtent& a, const FloatBoxExtent& b)
{
    a.setTop(a.top() + b.top());
    a.setRight(a.right() + b.right());
    a.setBottom(a.bottom() + b.bottom());
    a.setLeft(a.left() + b.left());
}

} // namespace blink


#endif // FloatBoxExtent_h
