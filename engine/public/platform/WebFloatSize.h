/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
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

#ifndef WebFloatSize_h
#define WebFloatSize_h

#include "WebCommon.h"

#include <algorithm>

#if INSIDE_BLINK
#include "platform/geometry/FloatSize.h"
#else
#include <cmath>
#include <ui/gfx/geometry/size_f.h>
#include <ui/gfx/vector2d_f.h>
#endif

namespace blink {

struct WebFloatSize {
    float width;
    float height;

    bool isEmpty() const { return width <= 0 || height <= 0; }

    WebFloatSize()
        : width(0)
        , height(0)
    {
    }

    WebFloatSize(float width, float height)
        : width(width)
        , height(height)
    {
    }

#if INSIDE_BLINK
    WebFloatSize(const FloatSize& s)
        : width(s.width())
        , height(s.height())
    {
    }

    WebFloatSize& operator=(const FloatSize& s)
    {
        width = s.width();
        height = s.height();
        return *this;
    }

    operator FloatSize() const
    {
        return FloatSize(width, height);
    }
#else
    WebFloatSize(const gfx::SizeF& s)
        : width(s.width())
        , height(s.height())
    {
    }

    WebFloatSize(const gfx::Vector2dF& v)
        : width(v.x())
        , height(v.y())
    {
    }

    WebFloatSize& operator=(const gfx::SizeF& s)
    {
        width = s.width();
        height = s.height();
        return *this;
    }

    WebFloatSize& operator=(const gfx::Vector2dF& v)
    {
        width = v.x();
        height = v.y();
        return *this;
    }

    operator gfx::SizeF() const
    {
        return gfx::SizeF(std::max(0.f, width), std::max(0.f, height));
    }

    operator gfx::Vector2dF() const
    {
        return gfx::Vector2dF(width, height);
    }
#endif
};

inline bool operator==(const WebFloatSize& a, const WebFloatSize& b)
{
    return a.width == b.width && a.height == b.height;
}

inline bool operator!=(const WebFloatSize& a, const WebFloatSize& b)
{
    return !(a == b);
}

} // namespace blink

#endif
