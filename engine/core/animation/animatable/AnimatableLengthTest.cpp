// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"

#include "core/animation/animatable/AnimatableLength.h"

#include "platform/CalculationValue.h"

#include <gtest/gtest.h>

namespace blink {

namespace {

    PassRefPtrWillBeRawPtr<AnimatableLength> create(const Length& length, double zoom = 1)
    {
        return AnimatableLength::create(length, zoom);
    }

} // namespace

TEST(AnimationAnimatableLengthTest, RoundTripConversion)
{
    EXPECT_EQ(Length(0, Fixed), create(Length(0, Fixed))->length(1, ValueRangeAll));
    EXPECT_EQ(Length(0, Percent), create(Length(0, Percent))->length(1, ValueRangeAll));
    EXPECT_EQ(Length(10, Fixed), create(Length(10, Fixed))->length(1, ValueRangeAll));
    EXPECT_EQ(Length(10, Percent), create(Length(10, Percent))->length(1, ValueRangeAll));
    EXPECT_EQ(Length(-10, Fixed), create(Length(-10, Fixed))->length(1, ValueRangeAll));
    EXPECT_EQ(Length(-10, Percent), create(Length(-10, Percent))->length(1, ValueRangeAll));
    Length calc = Length(CalculationValue::create(PixelsAndPercent(5, 10), ValueRangeAll));
    EXPECT_EQ(calc, create(calc)->length(1, ValueRangeAll));
}

TEST(AnimationAnimatableLengthTest, ValueRangeNonNegative)
{
    EXPECT_EQ(Length(10, Fixed), create(Length(10, Fixed))->length(1, ValueRangeNonNegative));
    EXPECT_EQ(Length(10, Percent), create(Length(10, Percent))->length(1, ValueRangeNonNegative));
    EXPECT_EQ(Length(0, Fixed), create(Length(-10, Fixed))->length(1, ValueRangeNonNegative));
    EXPECT_EQ(Length(0, Percent), create(Length(-10, Percent))->length(1, ValueRangeNonNegative));
    Length calc = Length(CalculationValue::create(PixelsAndPercent(-5, -10), ValueRangeNonNegative));
    EXPECT_TRUE(calc == create(calc)->length(1, ValueRangeNonNegative));
}

TEST(AnimationAnimatableLengthTest, Zoom)
{
    EXPECT_EQ(Length(4, Fixed), create(Length(10, Fixed), 5)->length(2, ValueRangeAll));
    EXPECT_EQ(Length(10, Percent), create(Length(10, Percent), 5)->length(2, ValueRangeAll));
    Length calc = Length(CalculationValue::create(PixelsAndPercent(5, 10), ValueRangeAll));
    Length result = Length(CalculationValue::create(PixelsAndPercent(2, 10), ValueRangeAll));
    EXPECT_TRUE(result == create(calc, 5)->length(2, ValueRangeAll));
}

TEST(AnimationAnimatableLengthTest, Equals)
{
    EXPECT_TRUE(create(Length(10, Fixed))->equals(create(Length(10, Fixed)).get()));
    EXPECT_TRUE(create(Length(20, Percent))->equals(create(Length(20, Percent)).get()));
    EXPECT_FALSE(create(Length(10, Fixed))->equals(create(Length(10, Percent)).get()));
    EXPECT_FALSE(create(Length(0, Percent))->equals(create(Length(0, Fixed)).get()));
    Length calc = Length(CalculationValue::create(PixelsAndPercent(5, 10), ValueRangeAll));
    EXPECT_TRUE(create(calc)->equals(create(calc).get()));
    EXPECT_FALSE(create(calc)->equals(create(Length(10, Percent)).get()));
}

TEST(AnimationAnimatableLengthTest, Interpolate)
{
    EXPECT_TRUE(AnimatableValue::interpolate(create(Length(10, Fixed)).get(), create(Length(0, Fixed)).get(), 0.2)->equals(create(Length(8, Fixed)).get()));
    EXPECT_TRUE(AnimatableValue::interpolate(create(Length(4, Percent)).get(), create(Length(12, Percent)).get(), 0.25)->equals(create(Length(6, Percent)).get()));
    Length calc = Length(CalculationValue::create(PixelsAndPercent(12, 4), ValueRangeAll));
    EXPECT_TRUE(AnimatableValue::interpolate(create(Length(20, Fixed)).get(), create(Length(10, Percent)).get(), 0.4)->equals(create(calc).get()));
}

} // namespace blink
