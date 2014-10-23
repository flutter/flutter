/*
 * Copyright (C) 2004, 2006, 2007 Apple Inc.  All rights reserved.
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

#include "config.h"
#include "platform/geometry/FloatPoint.h"

#include "SkPoint.h"
#include "platform/FloatConversion.h"
#include "platform/geometry/LayoutPoint.h"
#include "platform/geometry/LayoutSize.h"
#include <limits>
#include <math.h>

namespace blink {

// Skia has problems when passed infinite, etc floats, filter them to 0.
static inline SkScalar WebCoreFloatToSkScalar(float f)
{
    return SkFloatToScalar(std::isfinite(f) ? f : 0);
}

FloatPoint::FloatPoint(const IntPoint& p) : m_x(p.x()), m_y(p.y())
{
}

FloatPoint::FloatPoint(const LayoutPoint& p)
    : m_x(p.x().toFloat())
    , m_y(p.y().toFloat())
{
}

void FloatPoint::normalize()
{
    float tempLength = length();

    if (tempLength) {
        m_x /= tempLength;
        m_y /= tempLength;
    }
}

float FloatPoint::slopeAngleRadians() const
{
    return atan2f(m_y, m_x);
}

float FloatPoint::length() const
{
    return sqrtf(lengthSquared());
}

void FloatPoint::move(const LayoutSize& size)
{
    m_x += size.width();
    m_y += size.height();
}

void FloatPoint::moveBy(const LayoutPoint& point)
{
    m_x += point.x();
    m_y += point.y();
}

SkPoint FloatPoint::data() const
{
    SkPoint p = { WebCoreFloatToSkScalar(m_x), WebCoreFloatToSkScalar(m_y) };
    return p;
}

FloatPoint FloatPoint::narrowPrecision(double x, double y)
{
    return FloatPoint(narrowPrecisionToFloat(x), narrowPrecisionToFloat(y));
}

float findSlope(const FloatPoint& p1, const FloatPoint& p2, float& c)
{
    if (p2.x() == p1.x())
        return std::numeric_limits<float>::infinity();

    // y = mx + c
    float slope = (p2.y() - p1.y()) / (p2.x() - p1.x());
    c = p1.y() - slope * p1.x();
    return slope;
}

bool findIntersection(const FloatPoint& p1, const FloatPoint& p2, const FloatPoint& d1, const FloatPoint& d2, FloatPoint& intersection)
{
    float pxLength = p2.x() - p1.x();
    float pyLength = p2.y() - p1.y();

    float dxLength = d2.x() - d1.x();
    float dyLength = d2.y() - d1.y();

    float denom = pxLength * dyLength - pyLength * dxLength;
    if (!denom)
        return false;

    float param = ((d1.x() - p1.x()) * dyLength - (d1.y() - p1.y()) * dxLength) / denom;

    intersection.setX(p1.x() + param * pxLength);
    intersection.setY(p1.y() + param * pyLength);
    return true;
}

}
