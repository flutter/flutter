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
#include "core/animation/animatable/AnimatableUnknown.h"

#include "core/animation/animatable/AnimatableNeutral.h"
#include "core/css/CSSValuePool.h"

#include <gtest/gtest.h>

using namespace blink;

namespace {

class AnimationAnimatableUnknownTest : public ::testing::Test {
protected:
    virtual void SetUp()
    {
        cssValue = cssValuePool().createIdentifierValue(CSSValueYellow);
        animatableUnknown = AnimatableUnknown::create(cssValue);

        otherCSSValue = cssValuePool().createIdentifierValue(CSSValueOrange);
        otherAnimatableUnknown = AnimatableUnknown::create(otherCSSValue);
    }

    RefPtrWillBePersistent<CSSValue> cssValue;
    RefPtrWillBePersistent<AnimatableValue> animatableUnknown;
    RefPtrWillBePersistent<CSSValue> otherCSSValue;
    RefPtrWillBePersistent<AnimatableValue> otherAnimatableUnknown;
};

TEST_F(AnimationAnimatableUnknownTest, Create)
{
    EXPECT_TRUE(animatableUnknown);
}

TEST_F(AnimationAnimatableUnknownTest, ToCSSValue)
{
    EXPECT_EQ(cssValue, toAnimatableUnknown(animatableUnknown.get())->toCSSValue());
}

TEST_F(AnimationAnimatableUnknownTest, Interpolate)
{
    EXPECT_EQ(cssValue, toAnimatableUnknown(AnimatableValue::interpolate(animatableUnknown.get(), otherAnimatableUnknown.get(), 0).get())->toCSSValue());
    EXPECT_EQ(cssValue, toAnimatableUnknown(AnimatableValue::interpolate(animatableUnknown.get(), otherAnimatableUnknown.get(), 0.4).get())->toCSSValue());
    EXPECT_EQ(otherCSSValue, toAnimatableUnknown(AnimatableValue::interpolate(animatableUnknown.get(), otherAnimatableUnknown.get(), 0.5).get())->toCSSValue());
    EXPECT_EQ(otherCSSValue, toAnimatableUnknown(AnimatableValue::interpolate(animatableUnknown.get(), otherAnimatableUnknown.get(), 0.6).get())->toCSSValue());
    EXPECT_EQ(otherCSSValue, toAnimatableUnknown(AnimatableValue::interpolate(animatableUnknown.get(), otherAnimatableUnknown.get(), 1).get())->toCSSValue());

    EXPECT_EQ(otherCSSValue, toAnimatableUnknown(AnimatableValue::interpolate(otherAnimatableUnknown.get(), animatableUnknown.get(), 0).get())->toCSSValue());
    EXPECT_EQ(otherCSSValue, toAnimatableUnknown(AnimatableValue::interpolate(otherAnimatableUnknown.get(), animatableUnknown.get(), 0.4).get())->toCSSValue());
    EXPECT_EQ(cssValue, toAnimatableUnknown(AnimatableValue::interpolate(otherAnimatableUnknown.get(), animatableUnknown.get(), 0.5).get())->toCSSValue());
    EXPECT_EQ(cssValue, toAnimatableUnknown(AnimatableValue::interpolate(otherAnimatableUnknown.get(), animatableUnknown.get(), 0.6).get())->toCSSValue());
    EXPECT_EQ(cssValue, toAnimatableUnknown(AnimatableValue::interpolate(otherAnimatableUnknown.get(), animatableUnknown.get(), 1).get())->toCSSValue());
}

}
