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

#ifndef PolygonShape_h
#define PolygonShape_h

#include "core/rendering/shapes/Shape.h"
#include "core/rendering/shapes/ShapeInterval.h"
#include "platform/geometry/FloatPolygon.h"

namespace blink {

class OffsetPolygonEdge final : public VertexPair {
public:
    OffsetPolygonEdge(const FloatPolygonEdge& edge, const FloatSize& offset)
        : m_vertex1(edge.vertex1() + offset)
        , m_vertex2(edge.vertex2() + offset)
    {
    }

    virtual const FloatPoint& vertex1() const override { return m_vertex1; }
    virtual const FloatPoint& vertex2() const override { return m_vertex2; }

    bool isWithinYRange(float y1, float y2) const { return y1 <= minY() && y2 >= maxY(); }
    bool overlapsYRange(float y1, float y2) const { return y2 >= minY() && y1 <= maxY(); }
    float xIntercept(float y) const;
    FloatShapeInterval clippedEdgeXRange(float y1, float y2) const;

private:
    FloatPoint m_vertex1;
    FloatPoint m_vertex2;
};

class PolygonShape final : public Shape {
    WTF_MAKE_NONCOPYABLE(PolygonShape);
public:
    PolygonShape(PassOwnPtr<Vector<FloatPoint> > vertices, WindRule fillRule)
        : Shape()
        , m_polygon(vertices, fillRule)
    {
    }

    virtual LayoutRect shapeMarginLogicalBoundingBox() const override;
    virtual bool isEmpty() const override { return m_polygon.isEmpty(); }
    virtual LineSegment getExcludedInterval(LayoutUnit logicalTop, LayoutUnit logicalHeight) const override;
    virtual void buildDisplayPaths(DisplayPaths&) const override;

private:
    FloatPolygon m_polygon;
};

} // namespace blink

#endif // PolygonShape_h
