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

#include "platform/geometry/FloatRoundedRect.h"

#include <gtest/gtest.h>

using namespace blink;

namespace blink {

void PrintTo(const FloatSize& size, std::ostream* os)
{
    *os << "FloatSize("
        << size.width() << ", "
        << size.height() << ")";
}

void PrintTo(const FloatRect& rect, std::ostream* os)
{
    *os << "FloatRect("
        << rect.x() << ", "
        << rect.y() << ", "
        << rect.width() << ", "
        << rect.height() << ")";
}

void PrintTo(const FloatRoundedRect::Radii& radii, std::ostream* os)
{
    *os << "FloatRoundedRect::Radii("
        << ::testing::PrintToString(radii.topLeft()) << ", "
        << ::testing::PrintToString(radii.topRight()) << ", "
        << ::testing::PrintToString(radii.bottomRight()) << ", "
        << ::testing::PrintToString(radii.bottomLeft()) << ")";
}

void PrintTo(const FloatRoundedRect& roundedRect, std::ostream* os)
{
    *os << "FloatRoundedRect("
        << ::testing::PrintToString(roundedRect.rect()) << ", "
        << ::testing::PrintToString(roundedRect.radii()) << ")";
}

} // namespace blink

namespace {

#define TEST_INTERCEPTS(roundedRect, yCoordinate, expectedMinXIntercept, expectedMaxXIntercept) \
{                                                                                               \
    float minXIntercept;                                                                        \
    float maxXIntercept;                                                                        \
    EXPECT_TRUE(roundedRect.xInterceptsAtY(yCoordinate, minXIntercept, maxXIntercept));         \
    EXPECT_FLOAT_EQ(expectedMinXIntercept, minXIntercept);                                      \
    EXPECT_FLOAT_EQ(expectedMaxXIntercept, maxXIntercept);                                      \
}

TEST(FloatRoundedRectTest, zeroRadii)
{
    FloatRoundedRect r = FloatRoundedRect(1, 2, 3, 4);

    EXPECT_EQ(FloatRect(1, 2, 3, 4), r.rect());
    EXPECT_EQ(FloatSize(), r.radii().topLeft());
    EXPECT_EQ(FloatSize(), r.radii().topRight());
    EXPECT_EQ(FloatSize(), r.radii().bottomLeft());
    EXPECT_EQ(FloatSize(), r.radii().bottomRight());
    EXPECT_TRUE(r.radii().isZero());
    EXPECT_FALSE(r.isRounded());
    EXPECT_FALSE(r.isEmpty());

    EXPECT_EQ(FloatRect(1, 2, 0, 0), r.topLeftCorner());
    EXPECT_EQ(FloatRect(4, 2, 0, 0), r.topRightCorner());
    EXPECT_EQ(FloatRect(4, 6, 0, 0), r.bottomRightCorner());
    EXPECT_EQ(FloatRect(1, 6, 0, 0), r.bottomLeftCorner());

    TEST_INTERCEPTS(r, 2, r.rect().x(), r.rect().maxX());
    TEST_INTERCEPTS(r, 4, r.rect().x(), r.rect().maxX());
    TEST_INTERCEPTS(r, 6, r.rect().x(), r.rect().maxX());

    float minXIntercept;
    float maxXIntercept;

    EXPECT_FALSE(r.xInterceptsAtY(1, minXIntercept, maxXIntercept));
    EXPECT_FALSE(r.xInterceptsAtY(7, minXIntercept, maxXIntercept));

    // The FloatRoundedRect::expandRadii() function doesn't change radii FloatSizes that
    // are <= zero. Same as RoundedRect::expandRadii().
    r.expandRadii(20);
    r.shrinkRadii(10);
    EXPECT_TRUE(r.radii().isZero());
}

TEST(FloatRoundedRectTest, circle)
{
    FloatSize cornerRadii(50, 50);
    FloatRoundedRect r(FloatRect(0, 0, 100, 100), cornerRadii, cornerRadii, cornerRadii, cornerRadii);

    EXPECT_EQ(FloatRect(0, 0, 100, 100), r.rect());
    EXPECT_EQ(cornerRadii, r.radii().topLeft());
    EXPECT_EQ(cornerRadii, r.radii().topRight());
    EXPECT_EQ(cornerRadii, r.radii().bottomLeft());
    EXPECT_EQ(cornerRadii, r.radii().bottomRight());
    EXPECT_FALSE(r.radii().isZero());
    EXPECT_TRUE(r.isRounded());
    EXPECT_FALSE(r.isEmpty());

    EXPECT_EQ(FloatRect(0, 0, 50, 50), r.topLeftCorner());
    EXPECT_EQ(FloatRect(50, 0, 50, 50), r.topRightCorner());
    EXPECT_EQ(FloatRect(0, 50, 50, 50), r.bottomLeftCorner());
    EXPECT_EQ(FloatRect(50, 50, 50, 50), r.bottomRightCorner());

    TEST_INTERCEPTS(r, 0, 50, 50);
    TEST_INTERCEPTS(r, 25, 6.69873, 93.3013);
    TEST_INTERCEPTS(r, 50, 0, 100);
    TEST_INTERCEPTS(r, 75, 6.69873, 93.3013);
    TEST_INTERCEPTS(r, 100, 50, 50);

    float minXIntercept;
    float maxXIntercept;

    EXPECT_FALSE(r.xInterceptsAtY(-1, minXIntercept, maxXIntercept));
    EXPECT_FALSE(r.xInterceptsAtY(101, minXIntercept, maxXIntercept));
}

/*
 * FloatRoundedRect geometry for this test. Corner radii are in parens, x and y intercepts
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
TEST(FloatRoundedRectTest, ellipticalCorners)
{
    FloatSize cornerSize(10, 20);
    FloatRoundedRect::Radii cornerRadii;
    cornerRadii.setTopLeft(FloatSize(10, 15));
    cornerRadii.setTopRight(FloatSize(10, 20));
    cornerRadii.setBottomLeft(FloatSize(25, 15));
    cornerRadii.setBottomRight(FloatSize(20, 30));

    FloatRoundedRect r(FloatRect(0, 0, 100, 100), cornerRadii);

    EXPECT_EQ(r.radii(), FloatRoundedRect::Radii(FloatSize(10, 15), FloatSize(10, 20), FloatSize(25, 15), FloatSize(20, 30)));
    EXPECT_EQ(r, FloatRoundedRect(FloatRect(0, 0, 100, 100), cornerRadii));

    EXPECT_EQ(FloatRect(0, 0, 10, 15), r.topLeftCorner());
    EXPECT_EQ(FloatRect(90, 0, 10, 20), r.topRightCorner());
    EXPECT_EQ(FloatRect(0, 85, 25, 15), r.bottomLeftCorner());
    EXPECT_EQ(FloatRect(80, 70, 20, 30), r.bottomRightCorner());

    TEST_INTERCEPTS(r, 5, 2.5464401, 96.61438);
    TEST_INTERCEPTS(r, 15, 0, 99.682457);
    TEST_INTERCEPTS(r, 20, 0, 100);
    TEST_INTERCEPTS(r, 50, 0, 100);
    TEST_INTERCEPTS(r, 70, 0, 100);
    TEST_INTERCEPTS(r, 85, 0, 97.320511);
    TEST_INTERCEPTS(r, 95, 6.3661003, 91.05542);

    float minXIntercept;
    float maxXIntercept;

    EXPECT_FALSE(r.xInterceptsAtY(-1, minXIntercept, maxXIntercept));
    EXPECT_FALSE(r.xInterceptsAtY(101, minXIntercept, maxXIntercept));
}

} // namespace

