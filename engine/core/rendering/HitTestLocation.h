/*
 * Copyright (C) 2006 Apple Computer, Inc.
 * Copyright (C) 2012 Nokia Corporation and/or its subsidiary(-ies)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 *
*/

#ifndef HitTestLocation_h
#define HitTestLocation_h

#include "platform/geometry/FloatQuad.h"
#include "platform/geometry/FloatRect.h"
#include "platform/geometry/LayoutRect.h"
#include "platform/geometry/RoundedRect.h"
#include "wtf/Forward.h"
#include "wtf/ListHashSet.h"
#include "wtf/OwnPtr.h"
#include "wtf/RefPtr.h"

namespace blink {

class HitTestLocation {
public:

    HitTestLocation();
    HitTestLocation(const LayoutPoint&);
    HitTestLocation(const FloatPoint&);
    HitTestLocation(const FloatPoint&, const FloatQuad&);
    // Pass non-zero padding values to perform a rect-based hit test.
    HitTestLocation(const LayoutPoint& centerPoint, unsigned topPadding, unsigned rightPadding, unsigned bottomPadding, unsigned leftPadding);
    HitTestLocation(const HitTestLocation&, const LayoutSize& offset);
    HitTestLocation(const HitTestLocation&);
    ~HitTestLocation();
    HitTestLocation& operator=(const HitTestLocation&);

    const LayoutPoint& point() const { return m_point; }
    IntPoint roundedPoint() const { return roundedIntPoint(m_point); }

    // Rect-based hit test related methods.
    bool isRectBasedTest() const { return m_isRectBased; }
    bool isRectilinear() const { return m_isRectilinear; }
    IntRect boundingBox() const { return m_boundingBox; }

    static IntRect rectForPoint(const LayoutPoint&, unsigned topPadding, unsigned rightPadding, unsigned bottomPadding, unsigned leftPadding);
    int topPadding() const { return roundedPoint().y() - m_boundingBox.y(); }
    int rightPadding() const { return m_boundingBox.maxX() - roundedPoint().x() - 1; }
    int bottomPadding() const { return m_boundingBox.maxY() - roundedPoint().y() - 1; }
    int leftPadding() const { return roundedPoint().x() - m_boundingBox.x(); }

    bool intersects(const LayoutRect&) const;
    bool intersects(const FloatRect&) const;
    bool intersects(const RoundedRect&) const;
    bool containsPoint(const FloatPoint&) const;

    const FloatPoint& transformedPoint() const { return m_transformedPoint; }
    const FloatQuad& transformedRect() const { return m_transformedRect; }

private:
    template<typename RectType>
    bool intersectsRect(const RectType&) const;
    void move(const LayoutSize& offset);

    // This is cached forms of the more accurate point and area below.
    LayoutPoint m_point;
    IntRect m_boundingBox;

    FloatPoint m_transformedPoint;
    FloatQuad m_transformedRect;

    bool m_isRectBased;
    bool m_isRectilinear;
};

} // namespace blink

#endif // HitTestLocation_h
