/*
 * Copyright (c) 2012, Google Inc. All rights reserved.
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

#include "config.h"
#include "platform/LayoutUnit.h"

#include <gtest/gtest.h>
#include <limits.h>

using namespace blink;

namespace {

TEST(WebCoreLayoutUnit, LayoutUnitInt)
{
    ASSERT_EQ(LayoutUnit(INT_MIN).toInt(), intMinForLayoutUnit);
    ASSERT_EQ(LayoutUnit(INT_MIN / 2).toInt(), intMinForLayoutUnit);
    ASSERT_EQ(LayoutUnit(intMinForLayoutUnit - 1).toInt(), intMinForLayoutUnit);
    ASSERT_EQ(LayoutUnit(intMinForLayoutUnit).toInt(), intMinForLayoutUnit);
    ASSERT_EQ(LayoutUnit(intMinForLayoutUnit + 1).toInt(), intMinForLayoutUnit + 1);
    ASSERT_EQ(LayoutUnit(intMinForLayoutUnit / 2).toInt(), intMinForLayoutUnit / 2);
    ASSERT_EQ(LayoutUnit(-10000).toInt(), -10000);
    ASSERT_EQ(LayoutUnit(-1000).toInt(), -1000);
    ASSERT_EQ(LayoutUnit(-100).toInt(), -100);
    ASSERT_EQ(LayoutUnit(-10).toInt(), -10);
    ASSERT_EQ(LayoutUnit(-1).toInt(), -1);
    ASSERT_EQ(LayoutUnit(0).toInt(), 0);
    ASSERT_EQ(LayoutUnit(1).toInt(), 1);
    ASSERT_EQ(LayoutUnit(100).toInt(), 100);
    ASSERT_EQ(LayoutUnit(1000).toInt(), 1000);
    ASSERT_EQ(LayoutUnit(10000).toInt(), 10000);
    ASSERT_EQ(LayoutUnit(intMaxForLayoutUnit / 2).toInt(), intMaxForLayoutUnit / 2);
    ASSERT_EQ(LayoutUnit(intMaxForLayoutUnit - 1).toInt(), intMaxForLayoutUnit - 1);
    ASSERT_EQ(LayoutUnit(intMaxForLayoutUnit).toInt(), intMaxForLayoutUnit);
    ASSERT_EQ(LayoutUnit(intMaxForLayoutUnit + 1).toInt(), intMaxForLayoutUnit);
    ASSERT_EQ(LayoutUnit(INT_MAX / 2).toInt(), intMaxForLayoutUnit);
    ASSERT_EQ(LayoutUnit(INT_MAX).toInt(), intMaxForLayoutUnit);
}

TEST(WebCoreLayoutUnit, LayoutUnitFloat)
{
    const float tolerance = 1.0f / kFixedPointDenominator;
    ASSERT_FLOAT_EQ(LayoutUnit(1.0f).toFloat(), 1.0f);
    ASSERT_FLOAT_EQ(LayoutUnit(1.25f).toFloat(), 1.25f);
    ASSERT_NEAR(LayoutUnit(1.1f).toFloat(), 1.1f, tolerance);
    ASSERT_NEAR(LayoutUnit(1.33f).toFloat(), 1.33f, tolerance);
    ASSERT_NEAR(LayoutUnit(1.3333f).toFloat(), 1.3333f, tolerance);
    ASSERT_NEAR(LayoutUnit(1.53434f).toFloat(), 1.53434f, tolerance);
    ASSERT_NEAR(LayoutUnit(345634).toFloat(), 345634.0f, tolerance);
    ASSERT_NEAR(LayoutUnit(345634.12335f).toFloat(), 345634.12335f, tolerance);
    ASSERT_NEAR(LayoutUnit(-345634.12335f).toFloat(), -345634.12335f, tolerance);
    ASSERT_NEAR(LayoutUnit(-345634).toFloat(), -345634.0f, tolerance);
}

TEST(WebCoreLayoutUnit, LayoutUnitRounding)
{
    ASSERT_EQ(LayoutUnit(-1.9f).round(), -2);
    ASSERT_EQ(LayoutUnit(-1.6f).round(), -2);
    ASSERT_EQ(LayoutUnit::fromFloatRound(-1.51f).round(), -2);
    ASSERT_EQ(LayoutUnit::fromFloatRound(-1.5f).round(), -1);
    ASSERT_EQ(LayoutUnit::fromFloatRound(-1.49f).round(), -1);
    ASSERT_EQ(LayoutUnit(-1.0f).round(), -1);
    ASSERT_EQ(LayoutUnit::fromFloatRound(-0.99f).round(), -1);
    ASSERT_EQ(LayoutUnit::fromFloatRound(-0.51f).round(), -1);
    ASSERT_EQ(LayoutUnit::fromFloatRound(-0.50f).round(), 0);
    ASSERT_EQ(LayoutUnit::fromFloatRound(-0.49f).round(), 0);
    ASSERT_EQ(LayoutUnit(-0.1f).round(), 0);
    ASSERT_EQ(LayoutUnit(0.0f).round(), 0);
    ASSERT_EQ(LayoutUnit(0.1f).round(), 0);
    ASSERT_EQ(LayoutUnit::fromFloatRound(0.49f).round(), 0);
    ASSERT_EQ(LayoutUnit::fromFloatRound(0.50f).round(), 1);
    ASSERT_EQ(LayoutUnit::fromFloatRound(0.51f).round(), 1);
    ASSERT_EQ(LayoutUnit(0.99f).round(), 1);
    ASSERT_EQ(LayoutUnit(1.0f).round(), 1);
    ASSERT_EQ(LayoutUnit::fromFloatRound(1.49f).round(), 1);
    ASSERT_EQ(LayoutUnit::fromFloatRound(1.5f).round(), 2);
    ASSERT_EQ(LayoutUnit::fromFloatRound(1.51f).round(), 2);
}

TEST(WebCoreLayoutUnit, LayoutUnitSnapSizeToPixel)
{
    ASSERT_EQ(snapSizeToPixel(LayoutUnit(1), LayoutUnit(0)), 1);
    ASSERT_EQ(snapSizeToPixel(LayoutUnit(1), LayoutUnit(0.5)), 1);
    ASSERT_EQ(snapSizeToPixel(LayoutUnit(1.5), LayoutUnit(0)), 2);
    ASSERT_EQ(snapSizeToPixel(LayoutUnit(1.5), LayoutUnit(0.49)), 2);
    ASSERT_EQ(snapSizeToPixel(LayoutUnit(1.5), LayoutUnit(0.5)), 1);
    ASSERT_EQ(snapSizeToPixel(LayoutUnit(1.5), LayoutUnit(0.75)), 1);
    ASSERT_EQ(snapSizeToPixel(LayoutUnit(1.5), LayoutUnit(0.99)), 1);
    ASSERT_EQ(snapSizeToPixel(LayoutUnit(1.5), LayoutUnit(1)), 2);

    ASSERT_EQ(snapSizeToPixel(LayoutUnit(0.5), LayoutUnit(1.5)), 0);
    ASSERT_EQ(snapSizeToPixel(LayoutUnit(0.99), LayoutUnit(1.5)), 0);
    ASSERT_EQ(snapSizeToPixel(LayoutUnit(1.0), LayoutUnit(1.5)), 1);
    ASSERT_EQ(snapSizeToPixel(LayoutUnit(1.49), LayoutUnit(1.5)), 1);
    ASSERT_EQ(snapSizeToPixel(LayoutUnit(1.5), LayoutUnit(1.5)), 1);

    ASSERT_EQ(snapSizeToPixel(LayoutUnit(100.5), LayoutUnit(100)), 101);
    ASSERT_EQ(snapSizeToPixel(LayoutUnit(intMaxForLayoutUnit), LayoutUnit(0.3)), intMaxForLayoutUnit);
    ASSERT_EQ(snapSizeToPixel(LayoutUnit(intMinForLayoutUnit), LayoutUnit(-0.3)), intMinForLayoutUnit);
}

TEST(WebCoreLayoutUnit, LayoutUnitMultiplication)
{
    ASSERT_EQ((LayoutUnit(1) * LayoutUnit(1)).toInt(), 1);
    ASSERT_EQ((LayoutUnit(1) * LayoutUnit(2)).toInt(), 2);
    ASSERT_EQ((LayoutUnit(2) * LayoutUnit(1)).toInt(), 2);
    ASSERT_EQ((LayoutUnit(2) * LayoutUnit(0.5)).toInt(), 1);
    ASSERT_EQ((LayoutUnit(0.5) * LayoutUnit(2)).toInt(), 1);
    ASSERT_EQ((LayoutUnit(100) * LayoutUnit(1)).toInt(), 100);

    ASSERT_EQ((LayoutUnit(-1) * LayoutUnit(1)).toInt(), -1);
    ASSERT_EQ((LayoutUnit(-1) * LayoutUnit(2)).toInt(), -2);
    ASSERT_EQ((LayoutUnit(-2) * LayoutUnit(1)).toInt(), -2);
    ASSERT_EQ((LayoutUnit(-2) * LayoutUnit(0.5)).toInt(), -1);
    ASSERT_EQ((LayoutUnit(-0.5) * LayoutUnit(2)).toInt(), -1);
    ASSERT_EQ((LayoutUnit(-100) * LayoutUnit(1)).toInt(), -100);

    ASSERT_EQ((LayoutUnit(-1) * LayoutUnit(-1)).toInt(), 1);
    ASSERT_EQ((LayoutUnit(-1) * LayoutUnit(-2)).toInt(), 2);
    ASSERT_EQ((LayoutUnit(-2) * LayoutUnit(-1)).toInt(), 2);
    ASSERT_EQ((LayoutUnit(-2) * LayoutUnit(-0.5)).toInt(), 1);
    ASSERT_EQ((LayoutUnit(-0.5) * LayoutUnit(-2)).toInt(), 1);
    ASSERT_EQ((LayoutUnit(-100) * LayoutUnit(-1)).toInt(), 100);

    ASSERT_EQ((LayoutUnit(100) * LayoutUnit(3.33)).round(), 333);
    ASSERT_EQ((LayoutUnit(-100) * LayoutUnit(3.33)).round(), -333);
    ASSERT_EQ((LayoutUnit(-100) * LayoutUnit(-3.33)).round(), 333);

    size_t aHundredSizeT = 100;
    ASSERT_EQ((LayoutUnit(aHundredSizeT) * LayoutUnit(1)).toInt(), 100);
    ASSERT_EQ((aHundredSizeT * LayoutUnit(4)).toInt(), 400);
    ASSERT_EQ((LayoutUnit(4) * aHundredSizeT).toInt(), 400);

    int quarterMax = intMaxForLayoutUnit / 4;
    ASSERT_EQ((LayoutUnit(quarterMax) * LayoutUnit(2)).toInt(), quarterMax * 2);
    ASSERT_EQ((LayoutUnit(quarterMax) * LayoutUnit(3)).toInt(), quarterMax * 3);
    ASSERT_EQ((LayoutUnit(quarterMax) * LayoutUnit(4)).toInt(), quarterMax * 4);
    ASSERT_EQ((LayoutUnit(quarterMax) * LayoutUnit(5)).toInt(), intMaxForLayoutUnit);

    size_t overflowIntSizeT = intMaxForLayoutUnit * 4;
    ASSERT_EQ((LayoutUnit(overflowIntSizeT) * LayoutUnit(2)).toInt(), intMaxForLayoutUnit);
    ASSERT_EQ((overflowIntSizeT * LayoutUnit(4)).toInt(), intMaxForLayoutUnit);
    ASSERT_EQ((LayoutUnit(4) * overflowIntSizeT).toInt(), intMaxForLayoutUnit);
}

TEST(WebCoreLayoutUnit, LayoutUnitDivision)
{
    ASSERT_EQ((LayoutUnit(1) / LayoutUnit(1)).toInt(), 1);
    ASSERT_EQ((LayoutUnit(1) / LayoutUnit(2)).toInt(), 0);
    ASSERT_EQ((LayoutUnit(2) / LayoutUnit(1)).toInt(), 2);
    ASSERT_EQ((LayoutUnit(2) / LayoutUnit(0.5)).toInt(), 4);
    ASSERT_EQ((LayoutUnit(0.5) / LayoutUnit(2)).toInt(), 0);
    ASSERT_EQ((LayoutUnit(100) / LayoutUnit(10)).toInt(), 10);
    ASSERT_FLOAT_EQ((LayoutUnit(1) / LayoutUnit(2)).toFloat(), 0.5f);
    ASSERT_FLOAT_EQ((LayoutUnit(0.5) / LayoutUnit(2)).toFloat(), 0.25f);

    ASSERT_EQ((LayoutUnit(-1) / LayoutUnit(1)).toInt(), -1);
    ASSERT_EQ((LayoutUnit(-1) / LayoutUnit(2)).toInt(), 0);
    ASSERT_EQ((LayoutUnit(-2) / LayoutUnit(1)).toInt(), -2);
    ASSERT_EQ((LayoutUnit(-2) / LayoutUnit(0.5)).toInt(), -4);
    ASSERT_EQ((LayoutUnit(-0.5) / LayoutUnit(2)).toInt(), 0);
    ASSERT_EQ((LayoutUnit(-100) / LayoutUnit(10)).toInt(), -10);
    ASSERT_FLOAT_EQ((LayoutUnit(-1) / LayoutUnit(2)).toFloat(), -0.5f);
    ASSERT_FLOAT_EQ((LayoutUnit(-0.5) / LayoutUnit(2)).toFloat(), -0.25f);

    ASSERT_EQ((LayoutUnit(-1) / LayoutUnit(-1)).toInt(), 1);
    ASSERT_EQ((LayoutUnit(-1) / LayoutUnit(-2)).toInt(), 0);
    ASSERT_EQ((LayoutUnit(-2) / LayoutUnit(-1)).toInt(), 2);
    ASSERT_EQ((LayoutUnit(-2) / LayoutUnit(-0.5)).toInt(), 4);
    ASSERT_EQ((LayoutUnit(-0.5) / LayoutUnit(-2)).toInt(), 0);
    ASSERT_EQ((LayoutUnit(-100) / LayoutUnit(-10)).toInt(), 10);
    ASSERT_FLOAT_EQ((LayoutUnit(-1) / LayoutUnit(-2)).toFloat(), 0.5f);
    ASSERT_FLOAT_EQ((LayoutUnit(-0.5) / LayoutUnit(-2)).toFloat(), 0.25f);

    size_t aHundredSizeT = 100;
    ASSERT_EQ((LayoutUnit(aHundredSizeT) / LayoutUnit(2)).toInt(), 50);
    ASSERT_EQ((aHundredSizeT / LayoutUnit(4)).toInt(), 25);
    ASSERT_EQ((LayoutUnit(400) / aHundredSizeT).toInt(), 4);

    ASSERT_EQ((LayoutUnit(intMaxForLayoutUnit) / LayoutUnit(2)).toInt(), intMaxForLayoutUnit / 2);
    ASSERT_EQ((LayoutUnit(intMaxForLayoutUnit) / LayoutUnit(0.5)).toInt(), intMaxForLayoutUnit);
}

TEST(WebCoreLayoutUnit, LayoutUnitCeil)
{
    ASSERT_EQ(LayoutUnit(0).ceil(), 0);
    ASSERT_EQ(LayoutUnit(0.1).ceil(), 1);
    ASSERT_EQ(LayoutUnit(0.5).ceil(), 1);
    ASSERT_EQ(LayoutUnit(0.9).ceil(), 1);
    ASSERT_EQ(LayoutUnit(1.0).ceil(), 1);
    ASSERT_EQ(LayoutUnit(1.1).ceil(), 2);

    ASSERT_EQ(LayoutUnit(-0.1).ceil(), 0);
    ASSERT_EQ(LayoutUnit(-0.5).ceil(), 0);
    ASSERT_EQ(LayoutUnit(-0.9).ceil(), 0);
    ASSERT_EQ(LayoutUnit(-1.0).ceil(), -1);

    ASSERT_EQ(LayoutUnit(intMaxForLayoutUnit).ceil(), intMaxForLayoutUnit);
    ASSERT_EQ((LayoutUnit(intMaxForLayoutUnit) - LayoutUnit(0.5)).ceil(), intMaxForLayoutUnit);
    ASSERT_EQ((LayoutUnit(intMaxForLayoutUnit) - LayoutUnit(1)).ceil(), intMaxForLayoutUnit - 1);

    ASSERT_EQ(LayoutUnit(intMinForLayoutUnit).ceil(), intMinForLayoutUnit);
}

TEST(WebCoreLayoutUnit, LayoutUnitFloor)
{
    ASSERT_EQ(LayoutUnit(0).floor(), 0);
    ASSERT_EQ(LayoutUnit(0.1).floor(), 0);
    ASSERT_EQ(LayoutUnit(0.5).floor(), 0);
    ASSERT_EQ(LayoutUnit(0.9).floor(), 0);
    ASSERT_EQ(LayoutUnit(1.0).floor(), 1);
    ASSERT_EQ(LayoutUnit(1.1).floor(), 1);

    ASSERT_EQ(LayoutUnit(-0.1).floor(), -1);
    ASSERT_EQ(LayoutUnit(-0.5).floor(), -1);
    ASSERT_EQ(LayoutUnit(-0.9).floor(), -1);
    ASSERT_EQ(LayoutUnit(-1.0).floor(), -1);

    ASSERT_EQ(LayoutUnit(intMaxForLayoutUnit).floor(), intMaxForLayoutUnit);

    ASSERT_EQ(LayoutUnit(intMinForLayoutUnit).floor(), intMinForLayoutUnit);
    ASSERT_EQ((LayoutUnit(intMinForLayoutUnit) + LayoutUnit(0.5)).floor(), intMinForLayoutUnit);
    ASSERT_EQ((LayoutUnit(intMinForLayoutUnit) + LayoutUnit(1)).floor(), intMinForLayoutUnit + 1);
}

TEST(WebCoreLayoutUnit, LayoutUnitFloatOverflow)
{
    // These should overflow to the max/min according to their sign.
    ASSERT_EQ(intMaxForLayoutUnit, LayoutUnit(176972000.0f).toInt());
    ASSERT_EQ(intMinForLayoutUnit, LayoutUnit(-176972000.0f).toInt());
    ASSERT_EQ(intMaxForLayoutUnit, LayoutUnit(176972000.0).toInt());
    ASSERT_EQ(intMinForLayoutUnit, LayoutUnit(-176972000.0).toInt());
}

} // namespace
