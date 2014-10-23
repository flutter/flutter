/*
 * Copyright (C) 2009 Google Inc. All rights reserved.
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

#ifndef WebPoint_h
#define WebPoint_h

#include "WebCommon.h"

#if INSIDE_BLINK
#include "platform/geometry/IntPoint.h"
#else
#include <ui/gfx/geometry/point.h>
#endif

namespace blink {

struct WebPoint {
    int x;
    int y;

    WebPoint()
        : x(0)
        , y(0)
    {
    }

    WebPoint(int x, int y)
        : x(x)
        , y(y)
    {
    }

#if INSIDE_BLINK
    WebPoint(const IntPoint& p)
        : x(p.x())
        , y(p.y())
    {
    }

    WebPoint& operator=(const IntPoint& p)
    {
        x = p.x();
        y = p.y();
        return *this;
    }

    operator IntPoint() const
    {
        return IntPoint(x, y);
    }
#else
    WebPoint(const gfx::Point& p)
        : x(p.x())
        , y(p.y())
    {
    }

    WebPoint& operator=(const gfx::Point& p)
    {
        x = p.x();
        y = p.y();
        return *this;
    }

    operator gfx::Point() const
    {
        return gfx::Point(x, y);
    }
#endif
};

inline bool operator==(const WebPoint& a, const WebPoint& b)
{
    return a.x == b.x && a.y == b.y;
}

inline bool operator!=(const WebPoint& a, const WebPoint& b)
{
    return !(a == b);
}

} // namespace blink

#endif
