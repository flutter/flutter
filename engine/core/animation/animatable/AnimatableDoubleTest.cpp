/*
 * Copyright (c) 2013, Google Inc. All rights reserved.
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
#include "core/animation/animatable/AnimatableDouble.h"

#include <gtest/gtest.h>

using namespace blink;

namespace {

TEST(AnimationAnimatableDoubleTest, Create)
{
    EXPECT_TRUE(static_cast<bool>(AnimatableDouble::create(5).get()));
    EXPECT_TRUE(static_cast<bool>(AnimatableDouble::create(10).get()));
}

TEST(AnimationAnimatableDoubleTest, Equal)
{
    EXPECT_TRUE(AnimatableDouble::create(10)->equals(AnimatableDouble::create(10).get()));
    EXPECT_FALSE(AnimatableDouble::create(5)->equals(AnimatableDouble::create(10).get()));
}

TEST(AnimationAnimatableDoubleTest, ToDouble)
{
    EXPECT_EQ(5.9, AnimatableDouble::create(5.9)->toDouble());
    EXPECT_EQ(-10, AnimatableDouble::create(-10)->toDouble());
}


TEST(AnimationAnimatableDoubleTest, Interpolate)
{
    RefPtrWillBeRawPtr<AnimatableDouble> from10 = AnimatableDouble::create(10);
    RefPtrWillBeRawPtr<AnimatableDouble> to20 = AnimatableDouble::create(20);
    EXPECT_EQ(5, toAnimatableDouble(AnimatableValue::interpolate(from10.get(), to20.get(), -0.5).get())->toDouble());
    EXPECT_EQ(10, toAnimatableDouble(AnimatableValue::interpolate(from10.get(), to20.get(), 0).get())->toDouble());
    EXPECT_EQ(14, toAnimatableDouble(AnimatableValue::interpolate(from10.get(), to20.get(), 0.4).get())->toDouble());
    EXPECT_EQ(15, toAnimatableDouble(AnimatableValue::interpolate(from10.get(), to20.get(), 0.5).get())->toDouble());
    EXPECT_EQ(16, toAnimatableDouble(AnimatableValue::interpolate(from10.get(), to20.get(), 0.6).get())->toDouble());
    EXPECT_EQ(20, toAnimatableDouble(AnimatableValue::interpolate(from10.get(), to20.get(), 1).get())->toDouble());
    EXPECT_EQ(25, toAnimatableDouble(AnimatableValue::interpolate(from10.get(), to20.get(), 1.5).get())->toDouble());
}

TEST(AnimationAnimatableDoubleTest, Distance)
{
    RefPtrWillBeRawPtr<AnimatableDouble> first = AnimatableDouble::create(-1.5);
    RefPtrWillBeRawPtr<AnimatableDouble> second = AnimatableDouble::create(2.25);
    RefPtrWillBeRawPtr<AnimatableDouble> third = AnimatableDouble::create(3);

    EXPECT_DOUBLE_EQ(3.75, AnimatableValue::distance(first.get(), second.get()));
    EXPECT_DOUBLE_EQ(0.75, AnimatableValue::distance(second.get(), third.get()));
    EXPECT_DOUBLE_EQ(4.5, AnimatableValue::distance(third.get(), first.get()));
}

}
