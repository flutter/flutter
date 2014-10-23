/*
 * Copyright (c) 2014, Google Inc. All rights reserved.
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
#ifndef FloatBox_h
#define FloatBox_h

#include "platform/geometry/FloatPoint3D.h"
#include <cmath>

namespace blink {

class FloatBox {
public:
    FloatBox()
        : m_x(0)
        , m_y(0)
        , m_z(0)
        , m_width(0)
        , m_height(0)
        , m_depth(0)
    {
    }

    FloatBox(float x, float y, float z, float width, float height, float depth)
        : m_x(x)
        , m_y(y)
        , m_z(z)
        , m_width(width)
        , m_height(height)
        , m_depth(depth)
    {
    }

    FloatBox(const FloatBox& box)
        : m_x(box.x())
        , m_y(box.y())
        , m_z(box.z())
        , m_width(box.width())
        , m_height(box.height())
        , m_depth(box.depth())
    {
    }

    void setOrigin(const FloatPoint3D& origin)
    {
        m_x = origin.x();
        m_y = origin.y();
        m_z = origin.z();
    }

    void setSize(const FloatPoint3D& origin)
    {
        ASSERT(origin.x() >= 0);
        ASSERT(origin.y() >= 0);
        ASSERT(origin.z() >= 0);

        m_width = origin.x();
        m_height = origin.y();
        m_depth = origin.z();
    }

    void move(const FloatPoint3D& location)
    {
        m_x += location.x();
        m_y += location.y();
        m_z += location.z();
    }

    void flatten()
    {
        m_z = 0;
        m_depth = 0;
    }

    void expandTo(const FloatPoint3D& low, const FloatPoint3D& high)
    {
        ASSERT(low.x() <= high.x());
        ASSERT(low.y() <= high.y());
        ASSERT(low.z() <= high.z());

        float minX = std::min(m_x, low.x());
        float minY = std::min(m_y, low.y());
        float minZ = std::min(m_z, low.z());

        float maxX = std::max(right(), high.x());
        float maxY = std::max(bottom(), high.y());
        float maxZ = std::max(front(), high.z());

        m_x = minX;
        m_y = minY;
        m_z = minZ;

        m_width = maxX - minX;
        m_height = maxY - minY;
        m_depth = maxZ - minZ;
    }

    void expandTo(const FloatPoint3D& point)
    {
        expandTo(point, point);
    }

    void expandTo(const FloatBox& box)
    {
        expandTo(FloatPoint3D(box.x(), box.y(), box.z()), FloatPoint3D(box.right(), box.bottom(), box.front()));
    }

    void unionBounds(const FloatBox& box)
    {
        if (box.isEmpty())
            return;

        if (isEmpty()) {
            *this = box;
            return;
        }

        expandTo(box);
    }

    bool isEmpty() const { return (m_width <= 0 && m_height <= 0) || (m_width <= 0 && m_depth <= 0) || (m_height <= 0 && m_depth <= 0); }

    float right() const { return m_x + m_width; }
    float bottom() const { return m_y + m_height; }
    float front() const { return m_z + m_depth; }
    float x() const { return m_x; }
    float y() const { return m_y; }
    float z() const { return m_z; }
    float width() const { return m_width; }
    float height() const { return m_height; }
    float depth() const { return m_depth; }
private:
    float m_x;
    float m_y;
    float m_z;
    float m_width;
    float m_height;
    float m_depth;
};

inline bool operator==(const FloatBox& a, const FloatBox& b)
{
    return a.x() == b.x() && a.y() == b.y() && a.z() == b.z() && a.width() == b.width()
        && a.height() == b.height() && a.depth() == b.depth();
}

inline bool operator!=(const FloatBox& a, const FloatBox& b)
{
    return !(a == b);
}

} // namespace WebKit

#endif
