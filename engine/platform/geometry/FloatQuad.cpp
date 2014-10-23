/*
 * Copyright (C) 2008 Apple Inc. All rights reserved.
 * Copyright (C) 2012 Nokia Corporation and/or its subsidiary(-ies)
 * Copyright (C) 2013 Xidorn Quan (quanxunzhen@gmail.com)
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 * 3.  Neither the name of Apple Computer, Inc. ("Apple") nor the names of
 *     its contributors may be used to endorse or promote products derived
 *     from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "platform/geometry/FloatQuad.h"

#include <algorithm>
#include <limits>

namespace blink {

static inline float min4(float a, float b, float c, float d)
{
    return std::min(std::min(a, b), std::min(c, d));
}

static inline float max4(float a, float b, float c, float d)
{
    return std::max(std::max(a, b), std::max(c, d));
}

inline float dot(const FloatSize& a, const FloatSize& b)
{
    return a.width() * b.width() + a.height() * b.height();
}

inline float determinant(const FloatSize& a, const FloatSize& b)
{
    return a.width() * b.height() - a.height() * b.width();
}

inline bool isPointInTriangle(const FloatPoint& p, const FloatPoint& t1, const FloatPoint& t2, const FloatPoint& t3)
{
    // Compute vectors
    FloatSize v0 = t3 - t1;
    FloatSize v1 = t2 - t1;
    FloatSize v2 = p - t1;

    // Compute dot products
    float dot00 = dot(v0, v0);
    float dot01 = dot(v0, v1);
    float dot02 = dot(v0, v2);
    float dot11 = dot(v1, v1);
    float dot12 = dot(v1, v2);

    // Compute barycentric coordinates
    float invDenom = 1.0f / (dot00 * dot11 - dot01 * dot01);
    float u = (dot11 * dot02 - dot01 * dot12) * invDenom;
    float v = (dot00 * dot12 - dot01 * dot02) * invDenom;

    // Check if point is in triangle
    return (u >= 0) && (v >= 0) && (u + v <= 1);
}

FloatRect FloatQuad::boundingBox() const
{
    float left   = min4(m_p1.x(), m_p2.x(), m_p3.x(), m_p4.x());
    float top    = min4(m_p1.y(), m_p2.y(), m_p3.y(), m_p4.y());

    float right  = max4(m_p1.x(), m_p2.x(), m_p3.x(), m_p4.x());
    float bottom = max4(m_p1.y(), m_p2.y(), m_p3.y(), m_p4.y());

    return FloatRect(left, top, right - left, bottom - top);
}

static inline bool withinEpsilon(float a, float b)
{
    return fabs(a - b) < std::numeric_limits<float>::epsilon();
}

bool FloatQuad::isRectilinear() const
{
    return (withinEpsilon(m_p1.x(), m_p2.x()) && withinEpsilon(m_p2.y(), m_p3.y()) && withinEpsilon(m_p3.x(), m_p4.x()) && withinEpsilon(m_p4.y(), m_p1.y()))
        || (withinEpsilon(m_p1.y(), m_p2.y()) && withinEpsilon(m_p2.x(), m_p3.x()) && withinEpsilon(m_p3.y(), m_p4.y()) && withinEpsilon(m_p4.x(), m_p1.x()));
}

bool FloatQuad::containsPoint(const FloatPoint& p) const
{
    return isPointInTriangle(p, m_p1, m_p2, m_p3) || isPointInTriangle(p, m_p1, m_p3, m_p4);
}

// Note that we only handle convex quads here.
bool FloatQuad::containsQuad(const FloatQuad& other) const
{
    return containsPoint(other.p1()) && containsPoint(other.p2()) && containsPoint(other.p3()) && containsPoint(other.p4());
}

static inline FloatPoint rightMostCornerToVector(const FloatRect& rect, const FloatSize& vector)
{
    // Return the corner of the rectangle that if it is to the left of the vector
    // would mean all of the rectangle is to the left of the vector.
    // The vector here represents the side between two points in a clockwise convex polygon.
    //
    //  Q  XXX
    // QQQ XXX   If the lower left corner of X is left of the vector that goes from the top corner of Q to
    //  QQQ      the right corner of Q, then all of X is left of the vector, and intersection impossible.
    //   Q
    //
    FloatPoint point;
    if (vector.width() >= 0)
        point.setY(rect.maxY());
    else
        point.setY(rect.y());
    if (vector.height() >= 0)
        point.setX(rect.x());
    else
        point.setX(rect.maxX());
    return point;
}

bool FloatQuad::intersectsRect(const FloatRect& rect) const
{
    // For each side of the quad clockwise we check if the rectangle is to the left of it
    // since only content on the right can onlap with the quad.
    // This only works if the quad is convex.
    FloatSize v1, v2, v3, v4;

    // Ensure we use clockwise vectors.
    if (!isCounterclockwise()) {
        v1 = m_p2 - m_p1;
        v2 = m_p3 - m_p2;
        v3 = m_p4 - m_p3;
        v4 = m_p1 - m_p4;
    } else {
        v1 = m_p4 - m_p1;
        v2 = m_p1 - m_p2;
        v3 = m_p2 - m_p3;
        v4 = m_p3 - m_p4;
    }

    FloatPoint p = rightMostCornerToVector(rect, v1);
    if (determinant(v1, p - m_p1) < 0)
        return false;

    p = rightMostCornerToVector(rect, v2);
    if (determinant(v2, p - m_p2) < 0)
        return false;

    p = rightMostCornerToVector(rect, v3);
    if (determinant(v3, p - m_p3) < 0)
        return false;

    p = rightMostCornerToVector(rect, v4);
    if (determinant(v4, p - m_p4) < 0)
        return false;

    // If not all of the rectangle is outside one of the quad's four sides, then that means at least
    // a part of the rectangle is overlapping the quad.
    return true;
}

// Tests whether the line is contained by or intersected with the circle.
static inline bool lineIntersectsCircle(const FloatPoint& center, float radius, const FloatPoint& p0, const FloatPoint& p1)
{
    float x0 = p0.x() - center.x(), y0 = p0.y() - center.y();
    float x1 = p1.x() - center.x(), y1 = p1.y() - center.y();
    float radius2 = radius * radius;
    if ((x0 * x0 + y0 * y0) <= radius2 || (x1 * x1 + y1 * y1) <= radius2)
        return true;
    if (p0 == p1)
        return false;

    float a = y0 - y1;
    float b = x1 - x0;
    float c = x0 * y1 - x1 * y0;
    float distance2 = c * c / (a * a + b * b);
    // If distance between the center point and the line > the radius,
    // the line doesn't cross (or is contained by) the ellipse.
    if (distance2 > radius2)
        return false;

    // The nearest point on the line is between p0 and p1?
    float x = - a * c / (a * a + b * b);
    float y = - b * c / (a * a + b * b);
    return (((x0 <= x && x <= x1) || (x0 >= x && x >= x1))
        && ((y0 <= y && y <= y1) || (y1 <= y && y <= y0)));
}

bool FloatQuad::intersectsCircle(const FloatPoint& center, float radius) const
{
    return containsPoint(center) // The circle may be totally contained by the quad.
        || lineIntersectsCircle(center, radius, m_p1, m_p2)
        || lineIntersectsCircle(center, radius, m_p2, m_p3)
        || lineIntersectsCircle(center, radius, m_p3, m_p4)
        || lineIntersectsCircle(center, radius, m_p4, m_p1);
}

bool FloatQuad::intersectsEllipse(const FloatPoint& center, const FloatSize& radii) const
{
    // Transform the ellipse to an origin-centered circle whose radius is the product of major radius and minor radius.
    // Here we apply the same transformation to the quad.
    FloatQuad transformedQuad(*this);
    transformedQuad.move(-center.x(), -center.y());
    transformedQuad.scale(radii.height(), radii.width());

    FloatPoint originPoint;
    return transformedQuad.intersectsCircle(originPoint, radii.height() * radii.width());

}

bool FloatQuad::isCounterclockwise() const
{
    // Return if the two first vectors are turning clockwise. If the quad is convex then all following vectors will turn the same way.
    return determinant(m_p2 - m_p1, m_p3 - m_p2) < 0;
}

} // namespace blink
