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

#ifndef WebFloatPoint_h
#define WebFloatPoint_h

#include "WebCommon.h"

#if INSIDE_BLINK
#include "platform/geometry/FloatPoint.h"
#else
#include <ui/gfx/geometry/point_f.h>
#endif

namespace blink {

struct WebFloatPoint {
    float x;
    float y;

    WebFloatPoint()
        : x(0.0f)
        , y(0.0f)
    {
    }

    WebFloatPoint(float x, float y)
        : x(x)
        , y(y)
    {
    }

#if INSIDE_BLINK
    WebFloatPoint(const FloatPoint& p)
        : x(p.x())
        , y(p.y())
    {
    }

    WebFloatPoint& operator=(const FloatPoint& p)
    {
        x = p.x();
        y = p.y();
        return *this;
    }

    operator FloatPoint() const
    {
        return FloatPoint(x, y);
    }
#else
    WebFloatPoint(const gfx::PointF& p)
        : x(p.x())
        , y(p.y())
    {
    }

    WebFloatPoint& operator=(const gfx::PointF& p)
    {
        x = p.x();
        y = p.y();
        return *this;
    }

    operator gfx::PointF() const
    {
        return gfx::PointF(x, y);
    }

#endif
};

inline bool operator==(const WebFloatPoint& a, const WebFloatPoint& b)
{
    return a.x == b.x && a.y == b.y;
}

inline bool operator!=(const WebFloatPoint& a, const WebFloatPoint& b)
{
    return !(a == b);
}

} // namespace blink

#endif
