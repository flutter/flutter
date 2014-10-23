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

#include "core/rendering/shapes/BoxShape.h"

#include "platform/geometry/RoundedRect.h"

#include <gtest/gtest.h>

namespace blink {

class BoxShapeTest : public ::testing::Test {
protected:
    BoxShapeTest() { }

    PassOwnPtr<Shape> createBoxShape(const RoundedRect& bounds, float shapeMargin)
    {
        return Shape::createLayoutBoxShape(bounds, TopToBottomWritingMode, shapeMargin);
    }
};

} // namespace blink

namespace {

using namespace blink;

#define TEST_EXCLUDED_INTERVAL(shapePtr, lineTop, lineHeight, expectedLeft, expectedRight) \
{                                                                                          \
    LineSegment segment = shapePtr->getExcludedInterval(lineTop, lineHeight);                           \
    EXPECT_TRUE(segment.isValid); \
    if (segment.isValid) {                                                             \
        EXPECT_FLOAT_EQ(expectedLeft, segment.logicalLeft);                              \
        EXPECT_FLOAT_EQ(expectedRight, segment.logicalRight);                            \
    }                                                                                      \
}

#define TEST_NO_EXCLUDED_INTERVAL(shapePtr, lineTop, lineHeight) \
{                                                                \
    LineSegment segment = shapePtr->getExcludedInterval(lineTop, lineHeight); \
    EXPECT_FALSE(segment.isValid); \
}

/* The BoxShape is based on a 100x50 rectangle at 0,0. The shape-margin value is 10,
 * so the shapeMarginBoundingBox rectangle is 120x70 at -10,-10:
 *
 *   -10,-10   110,-10
 *       +--------+
 *       |        |
 *       +--------+
 *   -10,60     60,60
 */
TEST_F(BoxShapeTest, zeroRadii)
{
    OwnPtr<Shape> shape = createBoxShape(RoundedRect(0, 0, 100, 50), 10);
    EXPECT_FALSE(shape->isEmpty());

    EXPECT_EQ(LayoutRect(-10, -10, 120, 70), shape->shapeMarginLogicalBoundingBox());

    // A BoxShape's bounds include the top edge but not the bottom edge.
    // Similarly a "line", specified as top,height to the overlap methods,
    // is defined as top <= y < top + height.

    EXPECT_TRUE(shape->lineOverlapsShapeMarginBounds(-9, 1));
    EXPECT_TRUE(shape->lineOverlapsShapeMarginBounds(-10, 0));
    EXPECT_TRUE(shape->lineOverlapsShapeMarginBounds(-10, 200));
    EXPECT_TRUE(shape->lineOverlapsShapeMarginBounds(5, 10));
    EXPECT_TRUE(shape->lineOverlapsShapeMarginBounds(59, 1));

    EXPECT_FALSE(shape->lineOverlapsShapeMarginBounds(-12, 2));
    EXPECT_FALSE(shape->lineOverlapsShapeMarginBounds(60, 1));
    EXPECT_FALSE(shape->lineOverlapsShapeMarginBounds(100, 200));

    TEST_EXCLUDED_INTERVAL(shape, -9, 1, -10, 110);
    TEST_EXCLUDED_INTERVAL(shape, -10, 0, -10, 110);
    TEST_EXCLUDED_INTERVAL(shape, -10, 200, -10, 110);
    TEST_EXCLUDED_INTERVAL(shape, 5, 10, -10, 110);
    TEST_EXCLUDED_INTERVAL(shape, 59, 1, -10, 110);

    TEST_NO_EXCLUDED_INTERVAL(shape, -12, 2);
    TEST_NO_EXCLUDED_INTERVAL(shape, 60, 1);
    TEST_NO_EXCLUDED_INTERVAL(shape, 100, 200);
}

/* BoxShape geometry for this test. Corner radii are in parens, x and y intercepts
 * for the elliptical corners are noted. The rectangle itself is at 0,0 with width and height 100.
 *
 *         (10, 15)  x=10      x=90 (10, 20)
 *                (--+---------+--)
 *           y=15 +--|         |-+ y=20
 *                |               |
 *                |               |
 *           y=85 + -|         |- + y=70
 *                (--+---------+--)
 *       (25, 15)  x=25      x=80  (20, 30)
 */
TEST_F(BoxShapeTest, getIntervals)
{
    const RoundedRect::Radii cornerRadii(IntSize(10, 15), IntSize(10, 20), IntSize(25, 15), IntSize(20, 30));
    OwnPtr<Shape> shape = createBoxShape(RoundedRect(IntRect(0, 0, 100, 100), cornerRadii), 0);
    EXPECT_FALSE(shape->isEmpty());

    EXPECT_EQ(LayoutRect(0, 0, 100, 100), shape->shapeMarginLogicalBoundingBox());

    TEST_EXCLUDED_INTERVAL(shape, 10, 95, 0, 100);
    TEST_EXCLUDED_INTERVAL(shape, 5, 25, 0, 100);
    TEST_EXCLUDED_INTERVAL(shape, 15, 6, 0, 100);
    TEST_EXCLUDED_INTERVAL(shape, 20, 50, 0, 100);
    TEST_EXCLUDED_INTERVAL(shape, 69, 5, 0, 100);
    TEST_EXCLUDED_INTERVAL(shape, 85, 10, 0, 97.320511f);
}

} // namespace
