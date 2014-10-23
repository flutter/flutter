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

#ifndef FloatPolygon_h
#define FloatPolygon_h

#include "platform/PODIntervalTree.h"
#include "platform/geometry/FloatPoint.h"
#include "platform/geometry/FloatRect.h"
#include "platform/graphics/GraphicsTypes.h"
#include "wtf/OwnPtr.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/Vector.h"

namespace blink {

class FloatPolygonEdge;

// This class is used by PODIntervalTree for debugging.
#ifndef NDEBUG
template <class> struct ValueToString;
#endif

class PLATFORM_EXPORT FloatPolygon {
public:
    FloatPolygon(PassOwnPtr<Vector<FloatPoint> > vertices, WindRule fillRule);

    const FloatPoint& vertexAt(unsigned index) const { return (*m_vertices)[index]; }
    unsigned numberOfVertices() const { return m_vertices->size(); }

    WindRule fillRule() const { return m_fillRule; }

    const FloatPolygonEdge& edgeAt(unsigned index) const { return m_edges[index]; }
    unsigned numberOfEdges() const { return m_edges.size(); }

    FloatRect boundingBox() const { return m_boundingBox; }
    bool overlappingEdges(float minY, float maxY, Vector<const FloatPolygonEdge*>& result) const;
    bool contains(const FloatPoint&) const;
    bool isEmpty() const { return m_empty; }

private:
    typedef PODInterval<float, FloatPolygonEdge*> EdgeInterval;
    typedef PODIntervalTree<float, FloatPolygonEdge*> EdgeIntervalTree;

    bool containsNonZero(const FloatPoint&) const;
    bool containsEvenOdd(const FloatPoint&) const;

    OwnPtr<Vector<FloatPoint> > m_vertices;
    WindRule m_fillRule;
    FloatRect m_boundingBox;
    bool m_empty;
    Vector<FloatPolygonEdge> m_edges;
    EdgeIntervalTree m_edgeTree; // Each EdgeIntervalTree node stores minY, maxY, and a ("UserData") pointer to a FloatPolygonEdge.

};

class PLATFORM_EXPORT VertexPair {
public:
    virtual ~VertexPair() { }

    virtual const FloatPoint& vertex1() const = 0;
    virtual const FloatPoint& vertex2() const = 0;

    float minX() const { return std::min(vertex1().x(), vertex2().x()); }
    float minY() const { return std::min(vertex1().y(), vertex2().y()); }
    float maxX() const { return std::max(vertex1().x(), vertex2().x()); }
    float maxY() const { return std::max(vertex1().y(), vertex2().y()); }

    bool intersection(const VertexPair&, FloatPoint&) const;
};

class PLATFORM_EXPORT FloatPolygonEdge : public VertexPair {
    friend class FloatPolygon;
public:
    virtual const FloatPoint& vertex1() const OVERRIDE
    {
        ASSERT(m_polygon);
        return m_polygon->vertexAt(m_vertexIndex1);
    }

    virtual const FloatPoint& vertex2() const OVERRIDE
    {
        ASSERT(m_polygon);
        return m_polygon->vertexAt(m_vertexIndex2);
    }

    const FloatPolygonEdge& previousEdge() const
    {
        ASSERT(m_polygon && m_polygon->numberOfEdges() > 1);
        return m_polygon->edgeAt((m_edgeIndex + m_polygon->numberOfEdges() - 1) % m_polygon->numberOfEdges());
    }

    const FloatPolygonEdge& nextEdge() const
    {
        ASSERT(m_polygon && m_polygon->numberOfEdges() > 1);
        return m_polygon->edgeAt((m_edgeIndex + 1) % m_polygon->numberOfEdges());
    }

    const FloatPolygon* polygon() const { return m_polygon; }
    unsigned vertexIndex1() const { return m_vertexIndex1; }
    unsigned vertexIndex2() const { return m_vertexIndex2; }
    unsigned edgeIndex() const { return m_edgeIndex; }

private:
    // Edge vertex index1 is less than index2, except the last edge, where index2 is 0. When a polygon edge
    // is defined by 3 or more colinear vertices, index2 can be the the index of the last colinear vertex.
    unsigned m_vertexIndex1;
    unsigned m_vertexIndex2;
    unsigned m_edgeIndex;
    const FloatPolygon* m_polygon;
};

// These structures are used by PODIntervalTree for debugging.
#ifndef NDEBUG
template <> struct ValueToString<float> {
    static String string(const float value) { return String::number(value); }
};

template<> struct ValueToString<FloatPolygonEdge*> {
    static String string(const FloatPolygonEdge* edge) { return String::format("%p (%f,%f %f,%f)", edge, edge->vertex1().x(), edge->vertex1().y(), edge->vertex2().x(), edge->vertex2().y()); }
};
#endif

} // namespace blink

#endif // FloatPolygon_h
