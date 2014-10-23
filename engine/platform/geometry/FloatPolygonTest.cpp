/*
 * Copyright (C) 2013 Adobe Systems Incorporated. All rights reserved.
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

#include "platform/geometry/FloatPolygon.h"

#include <gtest/gtest.h>

namespace blink {

class FloatPolygonTestValue {
public:
    FloatPolygonTestValue(const float* coordinates, unsigned coordinatesLength, WindRule fillRule)
    {
        ASSERT(!(coordinatesLength % 2));
        OwnPtr<Vector<FloatPoint> > vertices = adoptPtr(new Vector<FloatPoint>(coordinatesLength / 2));
        for (unsigned i = 0; i < coordinatesLength; i += 2)
            (*vertices)[i / 2] = FloatPoint(coordinates[i], coordinates[i + 1]);
        m_polygon = adoptPtr(new FloatPolygon(vertices.release(), fillRule));
    }

    const FloatPolygon& polygon() const { return *m_polygon; }

private:
    OwnPtr<FloatPolygon> m_polygon;
};

} // namespace blink

namespace {

using namespace blink;

static bool compareEdgeIndex(const FloatPolygonEdge* edge1, const FloatPolygonEdge* edge2)
{
    return edge1->edgeIndex() < edge2->edgeIndex();
}

static Vector<const FloatPolygonEdge*> sortedOverlappingEdges(const FloatPolygon& polygon, float minY, float maxY)
{
    Vector<const FloatPolygonEdge*> result;
    polygon.overlappingEdges(minY, maxY, result);
    std::sort(result.begin(), result.end(), compareEdgeIndex);
    return result;
}

#define SIZEOF_ARRAY(p) (sizeof(p) / sizeof(p[0]))

/**
 * Checks a right triangle. This test covers all of the trivial FloatPolygon accessors.
 *
 *                        200,100
 *                          /|
 *                         / |
 *                        /  |
 *                       -----
 *                 100,200   200,200
 */
TEST(FloatPolygonTest, basics)
{
    const float triangleCoordinates[] = {200, 100, 200, 200, 100, 200};
    FloatPolygonTestValue triangleTestValue(triangleCoordinates, SIZEOF_ARRAY(triangleCoordinates), RULE_NONZERO);
    const FloatPolygon& triangle = triangleTestValue.polygon();

    EXPECT_EQ(RULE_NONZERO, triangle.fillRule());
    EXPECT_FALSE(triangle.isEmpty());

    EXPECT_EQ(3u, triangle.numberOfVertices());
    EXPECT_EQ(FloatPoint(200, 100), triangle.vertexAt(0));
    EXPECT_EQ(FloatPoint(200, 200), triangle.vertexAt(1));
    EXPECT_EQ(FloatPoint(100, 200), triangle.vertexAt(2));

    EXPECT_EQ(3u, triangle.numberOfEdges());
    EXPECT_EQ(FloatPoint(200, 100), triangle.edgeAt(0).vertex1());
    EXPECT_EQ(FloatPoint(200, 200), triangle.edgeAt(0).vertex2());
    EXPECT_EQ(FloatPoint(200, 200), triangle.edgeAt(1).vertex1());
    EXPECT_EQ(FloatPoint(100, 200), triangle.edgeAt(1).vertex2());
    EXPECT_EQ(FloatPoint(100, 200), triangle.edgeAt(2).vertex1());
    EXPECT_EQ(FloatPoint(200, 100), triangle.edgeAt(2).vertex2());

    EXPECT_EQ(0u, triangle.edgeAt(0).vertexIndex1());
    EXPECT_EQ(1u, triangle.edgeAt(0).vertexIndex2());
    EXPECT_EQ(1u, triangle.edgeAt(1).vertexIndex1());
    EXPECT_EQ(2u, triangle.edgeAt(1).vertexIndex2());
    EXPECT_EQ(2u, triangle.edgeAt(2).vertexIndex1());
    EXPECT_EQ(0u, triangle.edgeAt(2).vertexIndex2());

    EXPECT_EQ(200, triangle.edgeAt(0).minX());
    EXPECT_EQ(200, triangle.edgeAt(0).maxX());
    EXPECT_EQ(100, triangle.edgeAt(1).minX());
    EXPECT_EQ(200, triangle.edgeAt(1).maxX());
    EXPECT_EQ(100, triangle.edgeAt(2).minX());
    EXPECT_EQ(200, triangle.edgeAt(2).maxX());

    EXPECT_EQ(100, triangle.edgeAt(0).minY());
    EXPECT_EQ(200, triangle.edgeAt(0).maxY());
    EXPECT_EQ(200, triangle.edgeAt(1).minY());
    EXPECT_EQ(200, triangle.edgeAt(1).maxY());
    EXPECT_EQ(100, triangle.edgeAt(2).minY());
    EXPECT_EQ(200, triangle.edgeAt(2).maxY());

    EXPECT_EQ(0u, triangle.edgeAt(0).edgeIndex());
    EXPECT_EQ(1u, triangle.edgeAt(1).edgeIndex());
    EXPECT_EQ(2u, triangle.edgeAt(2).edgeIndex());

    EXPECT_EQ(2u, triangle.edgeAt(0).previousEdge().edgeIndex());
    EXPECT_EQ(1u, triangle.edgeAt(0).nextEdge().edgeIndex());
    EXPECT_EQ(0u, triangle.edgeAt(1).previousEdge().edgeIndex());
    EXPECT_EQ(2u, triangle.edgeAt(1).nextEdge().edgeIndex());
    EXPECT_EQ(1u, triangle.edgeAt(2).previousEdge().edgeIndex());
    EXPECT_EQ(0u, triangle.edgeAt(2).nextEdge().edgeIndex());

    EXPECT_EQ(FloatRect(100, 100, 100, 100), triangle.boundingBox());

    Vector<const FloatPolygonEdge*> resultA = sortedOverlappingEdges(triangle, 100, 200);
    EXPECT_EQ(3u, resultA.size());
    if (resultA.size() == 3) {
        EXPECT_EQ(0u, resultA[0]->edgeIndex());
        EXPECT_EQ(1u, resultA[1]->edgeIndex());
        EXPECT_EQ(2u, resultA[2]->edgeIndex());
    }

    Vector<const FloatPolygonEdge*> resultB = sortedOverlappingEdges(triangle, 200, 200);
    EXPECT_EQ(3u, resultB.size());
    if (resultB.size() == 3) {
        EXPECT_EQ(0u, resultB[0]->edgeIndex());
        EXPECT_EQ(1u, resultB[1]->edgeIndex());
        EXPECT_EQ(2u, resultB[2]->edgeIndex());
    }

    Vector<const FloatPolygonEdge*> resultC = sortedOverlappingEdges(triangle, 100, 150);
    EXPECT_EQ(2u, resultC.size());
    if (resultC.size() == 2) {
        EXPECT_EQ(0u, resultC[0]->edgeIndex());
        EXPECT_EQ(2u, resultC[1]->edgeIndex());
    }

    Vector<const FloatPolygonEdge*> resultD = sortedOverlappingEdges(triangle, 201, 300);
    EXPECT_EQ(0u, resultD.size());

    Vector<const FloatPolygonEdge*> resultE = sortedOverlappingEdges(triangle, 98, 99);
    EXPECT_EQ(0u, resultE.size());
}

/**
 * Tests FloatPolygon::contains() with a right triangle, and fillRule = nonzero.
 *
 *                        200,100
 *                          /|
 *                         / |
 *                        /  |
 *                       -----
 *                 100,200   200,200
 */
TEST(FloatPolygonTest, triangle_nonzero)
{
    const float triangleCoordinates[] = {200, 100, 200, 200, 100, 200};
    FloatPolygonTestValue triangleTestValue(triangleCoordinates, SIZEOF_ARRAY(triangleCoordinates), RULE_NONZERO);
    const FloatPolygon& triangle = triangleTestValue.polygon();

    EXPECT_EQ(RULE_NONZERO, triangle.fillRule());
    EXPECT_TRUE(triangle.contains(FloatPoint(200, 100)));
    EXPECT_TRUE(triangle.contains(FloatPoint(200, 200)));
    EXPECT_TRUE(triangle.contains(FloatPoint(100, 200)));
    EXPECT_TRUE(triangle.contains(FloatPoint(150, 150)));
    EXPECT_FALSE(triangle.contains(FloatPoint(100, 100)));
    EXPECT_FALSE(triangle.contains(FloatPoint(149, 149)));
    EXPECT_FALSE(triangle.contains(FloatPoint(150, 200.5)));
    EXPECT_FALSE(triangle.contains(FloatPoint(201, 200.5)));
}

/**
 * Tests FloatPolygon::contains() with a right triangle, and fillRule = evenodd;
 *
 *                        200,100
 *                          /|
 *                         / |
 *                        /  |
 *                       -----
 *                 100,200   200,200
 */
TEST(FloatPolygonTest, triangle_evenodd)
{
    const float triangleCoordinates[] = {200, 100, 200, 200, 100, 200};
    FloatPolygonTestValue triangleTestValue(triangleCoordinates, SIZEOF_ARRAY(triangleCoordinates), RULE_EVENODD);
    const FloatPolygon& triangle = triangleTestValue.polygon();

    EXPECT_EQ(RULE_EVENODD, triangle.fillRule());
    EXPECT_TRUE(triangle.contains(FloatPoint(200, 100)));
    EXPECT_TRUE(triangle.contains(FloatPoint(200, 200)));
    EXPECT_TRUE(triangle.contains(FloatPoint(100, 200)));
    EXPECT_TRUE(triangle.contains(FloatPoint(150, 150)));
    EXPECT_FALSE(triangle.contains(FloatPoint(100, 100)));
    EXPECT_FALSE(triangle.contains(FloatPoint(149, 149)));
    EXPECT_FALSE(triangle.contains(FloatPoint(150, 200.5)));
    EXPECT_FALSE(triangle.contains(FloatPoint(201, 200.5)));
}

#define TEST_EMPTY(coordinates)                                                                        \
{                                                                                                      \
    FloatPolygonTestValue emptyPolygonTestValue(coordinates, SIZEOF_ARRAY(coordinates), RULE_NONZERO); \
    const FloatPolygon& emptyPolygon = emptyPolygonTestValue.polygon();                                \
    EXPECT_TRUE(emptyPolygon.isEmpty());                                                               \
}

TEST(FloatPolygonTest, emptyPolygons)
{
    const float emptyCoordinates1[] = {0, 0};
    TEST_EMPTY(emptyCoordinates1);

    const float emptyCoordinates2[] = {0, 0, 1, 1};
    TEST_EMPTY(emptyCoordinates2);

    const float emptyCoordinates3[] = {0, 0, 1, 1, 2, 2, 3, 3};
    TEST_EMPTY(emptyCoordinates3);

    const float emptyCoordinates4[] = {0, 0, 1, 1, 2, 2, 3, 3, 1, 1};
    TEST_EMPTY(emptyCoordinates4);

    const float emptyCoordinates5[] = {0, 0, 0, 1, 0, 2, 0, 3, 0, 1};
    TEST_EMPTY(emptyCoordinates5);

    const float emptyCoordinates6[] = {0, 0, 1, 0, 2, 0, 3, 0, 1, 0};
    TEST_EMPTY(emptyCoordinates6);
}

/*
 * Test FloatPolygon::contains() with a trapezoid. The vertices are listed in counter-clockwise order.
 *
 *        150,100   250,100
 *          +----------+
 *         /            \
 *        /              \
 *       +----------------+
 *     100,150          300,150
 */
TEST(FloatPolygonTest, trapezoid)
{
    const float trapezoidCoordinates[] = {100, 150, 300, 150, 250, 100, 150, 100};
    FloatPolygonTestValue trapezoidTestValue(trapezoidCoordinates, SIZEOF_ARRAY(trapezoidCoordinates), RULE_EVENODD);
    const FloatPolygon& trapezoid = trapezoidTestValue.polygon();

    EXPECT_FALSE(trapezoid.isEmpty());
    EXPECT_EQ(4u, trapezoid.numberOfVertices());
    EXPECT_EQ(FloatRect(100, 100, 200, 50), trapezoid.boundingBox());

    EXPECT_TRUE(trapezoid.contains(FloatPoint(150, 100)));
    EXPECT_TRUE(trapezoid.contains(FloatPoint(150, 101)));
    EXPECT_TRUE(trapezoid.contains(FloatPoint(200, 125)));
    EXPECT_FALSE(trapezoid.contains(FloatPoint(149, 100)));
    EXPECT_FALSE(trapezoid.contains(FloatPoint(301, 150)));
}


/*
 * Test FloatPolygon::contains() with a non-convex rectilinear polygon. The polygon has the same shape
 * as the letter "H":
 *
 *    100,100  150,100   200,100   250,100
 *       +--------+        +--------+
 *       |        |        |        |
 *       |        |        |        |
 *       |        +--------+        |
 *       |     150,150   200,150    |
 *       |                          |
 *       |     150,200   200,200    |
 *       |        +--------+        |
 *       |        |        |        |
 *       |        |        |        |
 *       +--------+        +--------+
 *    100,250  150,250   200,250   250,250
 */
TEST(FloatPolygonTest, rectilinear)
{
    const float hCoordinates[] = {100, 100, 150, 100, 150, 150, 200, 150, 200, 100, 250, 100, 250, 250, 200, 250, 200, 200, 150, 200, 150, 250, 100, 250};
    FloatPolygonTestValue hTestValue(hCoordinates, SIZEOF_ARRAY(hCoordinates), RULE_NONZERO);
    const FloatPolygon& h = hTestValue.polygon();

    EXPECT_FALSE(h.isEmpty());
    EXPECT_EQ(12u, h.numberOfVertices());
    EXPECT_EQ(FloatRect(100, 100, 150, 150), h.boundingBox());

    EXPECT_TRUE(h.contains(FloatPoint(100, 100)));
    EXPECT_TRUE(h.contains(FloatPoint(125, 100)));
    EXPECT_TRUE(h.contains(FloatPoint(125, 125)));
    EXPECT_TRUE(h.contains(FloatPoint(150, 100)));
    EXPECT_TRUE(h.contains(FloatPoint(200, 200)));
    EXPECT_TRUE(h.contains(FloatPoint(225, 225)));
    EXPECT_TRUE(h.contains(FloatPoint(250, 250)));
    EXPECT_TRUE(h.contains(FloatPoint(100, 250)));
    EXPECT_TRUE(h.contains(FloatPoint(125, 250)));

    EXPECT_FALSE(h.contains(FloatPoint(99, 100)));
    EXPECT_FALSE(h.contains(FloatPoint(251, 100)));
    EXPECT_FALSE(h.contains(FloatPoint(151, 100)));
    EXPECT_FALSE(h.contains(FloatPoint(199, 100)));
    EXPECT_FALSE(h.contains(FloatPoint(175, 125)));
    EXPECT_FALSE(h.contains(FloatPoint(151, 250)));
    EXPECT_FALSE(h.contains(FloatPoint(199, 250)));
    EXPECT_FALSE(h.contains(FloatPoint(199, 250)));
    EXPECT_FALSE(h.contains(FloatPoint(175, 225)));
}

} // namespace
