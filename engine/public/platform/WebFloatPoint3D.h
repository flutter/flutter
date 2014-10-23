// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


#ifndef WebFloatPoint3D_h
#define WebFloatPoint3D_h

#include "WebCommon.h"

#if INSIDE_BLINK
#include "platform/geometry/FloatPoint3D.h"
#else
#include <ui/gfx/geometry/point3_f.h>
#endif

namespace blink {

struct WebFloatPoint3D {
    float x;
    float y;
    float z;

    WebFloatPoint3D()
        : x(0.0f)
        , y(0.0f)
        , z(0.0f)
    {
    }

    WebFloatPoint3D(float x, float y, float z)
        : x(x)
        , y(y)
        , z(z)
    {
    }

#if INSIDE_BLINK
    WebFloatPoint3D(const FloatPoint3D& p)
        : x(p.x())
        , y(p.y())
        , z(p.z())
    {
    }

    WebFloatPoint3D& operator=(const FloatPoint3D& p)
    {
        x = p.x();
        y = p.y();
        z = p.z();
        return *this;
    }

    operator FloatPoint3D() const
    {
        return FloatPoint3D(x, y, z);
    }
#else
    WebFloatPoint3D(const gfx::Point3F& p)
        : x(p.x())
        , y(p.y())
        , z(p.z())
    {
    }

    WebFloatPoint3D& operator=(const gfx::Point3F& p)
    {
        x = p.x();
        y = p.y();
        return *this;
    }

    operator gfx::Point3F() const
    {
        return gfx::Point3F(x, y, z);
    }

#endif
};

inline bool operator==(const WebFloatPoint3D& a, const WebFloatPoint3D& b)
{
    return a.x == b.x && a.y == b.y && a.z == b.z;
}

inline bool operator!=(const WebFloatPoint3D& a, const WebFloatPoint3D& b)
{
    return !(a == b);
}

} // namespace blink

#endif
