/*
 * Copyright (C) 2010 Google Inc. All rights reserved.
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

#ifndef WebFloatRect_h
#define WebFloatRect_h

#include "WebCommon.h"

#if INSIDE_BLINK
#include "platform/geometry/FloatRect.h"
#else
#include <algorithm>
#include <cmath>
#include <ui/gfx/rect_f.h>
#endif

namespace blink {

struct WebFloatRect {
    float x;
    float y;
    float width;
    float height;

    bool isEmpty() const { return width <= 0 || height <= 0; }

    WebFloatRect()
        : x(0)
        , y(0)
        , width(0)
        , height(0)
    {
    }

    WebFloatRect(float x, float y, float width, float height)
        : x(x)
        , y(y)
        , width(width)
        , height(height)
    {
    }

#if INSIDE_BLINK
    WebFloatRect(const FloatRect& r)
        : x(r.x())
        , y(r.y())
        , width(r.width())
        , height(r.height())
    {
    }

    WebFloatRect& operator=(const FloatRect& r)
    {
        x = r.x();
        y = r.y();
        width = r.width();
        height = r.height();
        return *this;
    }

    operator FloatRect() const
    {
        return FloatRect(x, y, width, height);
    }
#else
    WebFloatRect(const gfx::RectF& r)
        : x(r.x())
        , y(r.y())
        , width(r.width())
        , height(r.height())
    {
    }

    WebFloatRect& operator=(const gfx::RectF& r)
    {
        x = r.x();
        y = r.y();
        width = r.width();
        height = r.height();
        return *this;
    }

    operator gfx::RectF() const
    {
        return gfx::RectF(x, y, std::max(0.0f, width), std::max(0.0f, height));
    }
#endif
};

inline bool operator==(const WebFloatRect& a, const WebFloatRect& b)
{
    return a.x == b.x && a.y == b.y && a.width == b.width && a.height == b.height;
}

inline bool operator!=(const WebFloatRect& a, const WebFloatRect& b)
{
    return !(a == b);
}

} // namespace blink

#endif
