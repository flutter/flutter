/*
 * Copyright (C) 2012 Adobe Systems Incorporated. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer.
 * 2. Redistributions in binary form must reproduce the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer in the documentation and/or other materials
 *    provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "core/rendering/shapes/PolygonShape.h"

#include "platform/geometry/LayoutPoint.h"
#include "wtf/MathExtras.h"

namespace blink {

static inline FloatSize inwardEdgeNormal(const FloatPolygonEdge& edge)
{
    FloatSize edgeDelta = edge.vertex2() - edge.vertex1();
    if (!edgeDelta.width())
        return FloatSize((edgeDelta.height() > 0 ? -1 : 1), 0);
    if (!edgeDelta.height())
        return FloatSize(0, (edgeDelta.width() > 0 ? 1 : -1));
    float edgeLength = edgeDelta.diagonalLength();
    return FloatSize(-edgeDelta.height() / edgeLength, edgeDelta.width() / edgeLength);
}

static inline FloatSize outwardEdgeNormal(const FloatPolygonEdge& edge)
{
    return -inwardEdgeNormal(edge);
}

static inline bool overlapsYRange(const FloatRect& rect, float y1, float y2) { return !rect.isEmpty() && y2 >= y1 && y2 >= rect.y() && y1 <= rect.maxY(); }

float OffsetPolygonEdge::xIntercept(float y) const
{
    ASSERT(y >= minY() && y <= maxY());

    if (vertex1().y() == vertex2().y() || vertex1().x() == vertex2().x())
        return minX();
    if (y == minY())
        return vertex1().y() < vertex2().y() ? vertex1().x() : vertex2().x();
    if (y == maxY())
        return vertex1().y() > vertex2().y() ? vertex1().x() : vertex2().x();

    return vertex1().x() + ((y - vertex1().y()) * (vertex2().x() - vertex1().x()) / (vertex2().y() - vertex1().y()));
}

FloatShapeInterval OffsetPolygonEdge::clippedEdgeXRange(float y1, float y2) const
{
    if (!overlapsYRange(y1, y2) || (y1 == maxY() && minY() <= y1) || (y2 == minY() && maxY() >= y2))
        return FloatShapeInterval();

    if (isWithinYRange(y1, y2))
        return FloatShapeInterval(minX(), maxX());

    // Clip the edge line segment to the vertical range y1,y2 and then return
    // the clipped line segment's horizontal range.

    FloatPoint minYVertex;
    FloatPoint maxYVertex;
    if (vertex1().y() < vertex2().y()) {
        minYVertex = vertex1();
        maxYVertex = vertex2();
    } else {
        minYVertex = vertex2();
        maxYVertex = vertex1();
    }
    float xForY1 = (minYVertex.y() < y1) ? xIntercept(y1) : minYVertex.x();
    float xForY2 = (maxYVertex.y() > y2) ? xIntercept(y2) : maxYVertex.x();
    return FloatShapeInterval(std::min(xForY1, xForY2), std::max(xForY1, xForY2));
}

static float circleXIntercept(float y, float radius)
{
    ASSERT(radius > 0);
    return radius * sqrt(1 - (y * y) / (radius * radius));
}

static FloatShapeInterval clippedCircleXRange(const FloatPoint& center, float radius, float y1, float y2)
{
    if (y1 > center.y() + radius || y2 < center.y() - radius)
        return FloatShapeInterval();

    if (center.y() >= y1 && center.y() <= y2)
        return FloatShapeInterval(center.x() - radius, center.x() + radius);

    // Clip the circle to the vertical range y1,y2 and return the extent of the clipped circle's
    // projection on the X axis

    float xi =  circleXIntercept((y2 < center.y() ? y2 : y1) - center.y(), radius);
    return FloatShapeInterval(center.x() - xi, center.x() + xi);
}

LayoutRect PolygonShape::shapeMarginLogicalBoundingBox() const
{
    FloatRect box = m_polygon.boundingBox();
    box.inflate(shapeMargin());
    return LayoutRect(box);
}

LineSegment PolygonShape::getExcludedInterval(LayoutUnit logicalTop, LayoutUnit logicalHeight) const
{
    float y1 = logicalTop.toFloat();
    float y2 = logicalTop.toFloat() + logicalHeight.toFloat();

    if (m_polygon.isEmpty() || !overlapsYRange(m_polygon.boundingBox(), y1 - shapeMargin(), y2 + shapeMargin()))
        return LineSegment();

    Vector<const FloatPolygonEdge*> overlappingEdges;
    if (!m_polygon.overlappingEdges(y1 - shapeMargin(), y2 + shapeMargin(), overlappingEdges))
        return LineSegment();

    FloatShapeInterval excludedInterval;
    for (unsigned i = 0; i < overlappingEdges.size(); i++) {
        const FloatPolygonEdge& edge = *(overlappingEdges[i]);
        if (edge.maxY() == edge.minY())
            continue;
        if (!shapeMargin()) {
            excludedInterval.unite(OffsetPolygonEdge(edge, FloatSize()).clippedEdgeXRange(y1, y2));
        } else {
            excludedInterval.unite(OffsetPolygonEdge(edge, outwardEdgeNormal(edge) * shapeMargin()).clippedEdgeXRange(y1, y2));
            excludedInterval.unite(OffsetPolygonEdge(edge, inwardEdgeNormal(edge) * shapeMargin()).clippedEdgeXRange(y1, y2));
            excludedInterval.unite(clippedCircleXRange(edge.vertex1(), shapeMargin(), y1, y2));
        }
    }

    if (excludedInterval.isEmpty())
        return LineSegment();

    return LineSegment(excludedInterval.x1(), excludedInterval.x2());
}

void PolygonShape::buildDisplayPaths(DisplayPaths& paths) const
{
    if (!m_polygon.numberOfVertices())
        return;
    paths.shape.moveTo(m_polygon.vertexAt(0));
    for (size_t i = 1; i < m_polygon.numberOfVertices(); ++i)
        paths.shape.addLineTo(m_polygon.vertexAt(i));
    paths.shape.closeSubpath();
}

} // namespace blink
