/*
 * Copyright (C) 2006, 2008, 2011 Apple Inc. All rights reserved.
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

#include "config.h"
#include "core/rendering/HitTestLocation.h"

namespace blink {

HitTestLocation::HitTestLocation()
    : m_isRectBased(false)
    , m_isRectilinear(true)
{
}

HitTestLocation::HitTestLocation(const LayoutPoint& point)
    : m_point(point)
    , m_boundingBox(rectForPoint(point, 0, 0, 0, 0))
    , m_transformedPoint(point)
    , m_transformedRect(m_boundingBox)
    , m_isRectBased(false)
    , m_isRectilinear(true)
{
}

HitTestLocation::HitTestLocation(const FloatPoint& point)
    : m_point(flooredLayoutPoint(point))
    , m_boundingBox(rectForPoint(m_point, 0, 0, 0, 0))
    , m_transformedPoint(point)
    , m_transformedRect(m_boundingBox)
    , m_isRectBased(false)
    , m_isRectilinear(true)
{
}

HitTestLocation::HitTestLocation(const FloatPoint& point, const FloatQuad& quad)
    : m_transformedPoint(point)
    , m_transformedRect(quad)
    , m_isRectBased(true)
{
    m_point = flooredLayoutPoint(point);
    m_boundingBox = enclosingIntRect(quad.boundingBox());
    m_isRectilinear = quad.isRectilinear();
}

HitTestLocation::HitTestLocation(const LayoutPoint& centerPoint, unsigned topPadding, unsigned rightPadding, unsigned bottomPadding, unsigned leftPadding)
    : m_point(centerPoint)
    , m_boundingBox(rectForPoint(centerPoint, topPadding, rightPadding, bottomPadding, leftPadding))
    , m_transformedPoint(centerPoint)
    , m_isRectBased(topPadding || rightPadding || bottomPadding || leftPadding)
    , m_isRectilinear(true)
{
    m_transformedRect = FloatQuad(m_boundingBox);
}

HitTestLocation::HitTestLocation(const HitTestLocation& other, const LayoutSize& offset)
    : m_point(other.m_point)
    , m_boundingBox(other.m_boundingBox)
    , m_transformedPoint(other.m_transformedPoint)
    , m_transformedRect(other.m_transformedRect)
    , m_isRectBased(other.m_isRectBased)
    , m_isRectilinear(other.m_isRectilinear)
{
    move(offset);
}

HitTestLocation::HitTestLocation(const HitTestLocation& other)
    : m_point(other.m_point)
    , m_boundingBox(other.m_boundingBox)
    , m_transformedPoint(other.m_transformedPoint)
    , m_transformedRect(other.m_transformedRect)
    , m_isRectBased(other.m_isRectBased)
    , m_isRectilinear(other.m_isRectilinear)
{
}

HitTestLocation::~HitTestLocation()
{
}

HitTestLocation& HitTestLocation::operator=(const HitTestLocation& other)
{
    m_point = other.m_point;
    m_boundingBox = other.m_boundingBox;
    m_transformedPoint = other.m_transformedPoint;
    m_transformedRect = other.m_transformedRect;
    m_isRectBased = other.m_isRectBased;
    m_isRectilinear = other.m_isRectilinear;

    return *this;
}

void HitTestLocation::move(const LayoutSize& offset)
{
    m_point.move(offset);
    m_transformedPoint.move(offset);
    m_transformedRect.move(offset);
    m_boundingBox = enclosingIntRect(m_transformedRect.boundingBox());
}

template<typename RectType>
bool HitTestLocation::intersectsRect(const RectType& rect) const
{
    // FIXME: When the hit test is not rect based we should use rect.contains(m_point).
    // That does change some corner case tests though.

    // First check if rect even intersects our bounding box.
    if (!rect.intersects(m_boundingBox))
        return false;

    // If the transformed rect is rectilinear the bounding box intersection was accurate.
    if (m_isRectilinear)
        return true;

    // If rect fully contains our bounding box, we are also sure of an intersection.
    if (rect.contains(m_boundingBox))
        return true;

    // Otherwise we need to do a slower quad based intersection test.
    return m_transformedRect.intersectsRect(rect);
}

bool HitTestLocation::intersects(const LayoutRect& rect) const
{
    return intersectsRect(rect);
}

bool HitTestLocation::intersects(const FloatRect& rect) const
{
    return intersectsRect(rect);
}

bool HitTestLocation::intersects(const RoundedRect& rect) const
{
    return rect.intersectsQuad(m_transformedRect);
}

bool HitTestLocation::containsPoint(const FloatPoint& point) const
{
    return m_transformedRect.containsPoint(point);
}

IntRect HitTestLocation::rectForPoint(const LayoutPoint& point, unsigned topPadding, unsigned rightPadding, unsigned bottomPadding, unsigned leftPadding)
{
    IntPoint actualPoint(flooredIntPoint(point));
    actualPoint -= IntSize(leftPadding, topPadding);

    IntSize actualPadding(leftPadding + rightPadding, topPadding + bottomPadding);
    // As IntRect is left inclusive and right exclusive (seeing IntRect::contains(x, y)), adding "1".
    // FIXME: Remove this once non-rect based hit-detection stops using IntRect:intersects.
    actualPadding += IntSize(1, 1);

    return IntRect(actualPoint, actualPadding);
}

} // namespace blink
