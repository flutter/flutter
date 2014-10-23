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
#include "core/animation/animatable/AnimatableColor.h"

#include <gtest/gtest.h>

using namespace blink;

namespace {

TEST(AnimationAnimatableColorTest, ToColor)
{
    Color transparent = AnimatableColorImpl(Color::transparent).toColor();
    EXPECT_EQ(transparent.rgb(), Color::transparent);
    Color red = AnimatableColorImpl(Color(0xFFFF0000)).toColor();
    EXPECT_EQ(red.rgb(), 0xFFFF0000);
}

TEST(AnimationAnimatableColorTest, Interpolate)
{
    EXPECT_EQ(AnimatableColorImpl(Color(0xFF00FF00)).interpolateTo(Color(0xFF00FF00), -10).toColor().rgb(), 0xFF00FF00);
    EXPECT_EQ(AnimatableColorImpl(Color(0xFF00FF00)).interpolateTo(Color(0xFFFF00FF), -10).toColor().rgb(), 0xFF00FF00);
    EXPECT_EQ(AnimatableColorImpl(Color(0xFF00FF00)).interpolateTo(Color(0xFFFF00FF), 0).toColor().rgb(), 0xFF00FF00);
    EXPECT_EQ(AnimatableColorImpl(Color(0xFF00FF00)).interpolateTo(Color(0xFFFF00FF), 1. / 255).toColor().rgb(), 0xFF01FE01);
    EXPECT_EQ(AnimatableColorImpl(Color(0xFF00FF00)).interpolateTo(Color(0xFFFF00FF), 0.5).toColor().rgb(), 0xFF808080);
    EXPECT_EQ(AnimatableColorImpl(Color(0xFF00FF00)).interpolateTo(Color(0xFFFF00FF), 254. / 255).toColor().rgb(), 0xFFFE01FE);
    EXPECT_EQ(AnimatableColorImpl(Color(0xFF00FF00)).interpolateTo(Color(0xFFFF00FF), 1).toColor().rgb(), 0xFFFF00FF);
    EXPECT_EQ(AnimatableColorImpl(Color(0xFF00FF00)).interpolateTo(Color(0xFFFF00FF), 10).toColor().rgb(), 0xFFFF00FF);

    EXPECT_EQ(AnimatableColorImpl(Color(0xFF001020)).interpolateTo(Color(0xFF4080C0), 3. / 16).toColor().rgb(), 0xFF0C253E);

    EXPECT_EQ(AnimatableColorImpl(Color(0x0000FF00)).interpolateTo(Color(0xFFFF00FF), 0.5).toColor().rgb(), 0x80FF00FF);
    EXPECT_EQ(AnimatableColorImpl(Color(0x4000FF00)).interpolateTo(Color(0x80FF00FF), 0.5).toColor().rgb(), 0x60AA55AAu);
    EXPECT_EQ(AnimatableColorImpl(Color(0x40FF00FF)).interpolateTo(Color(0x80FFFFFF), 0.5).toColor().rgb(), 0x60FFAAFFu);

    EXPECT_EQ(AnimatableColorImpl(Color(0x10204080)).interpolateTo(Color(0x104080C0), 0.5).toColor().rgb(), 0x103060A0u);
}

TEST(AnimationAnimatableColorTest, Distance)
{
    EXPECT_NEAR(1.0, AnimatableColorImpl(Color(0xFF000000)).distanceTo(Color(0xFFFF0000)), 0.00000001);
    EXPECT_NEAR(13.0 / 255, AnimatableColorImpl(Color(0xFF53647C)).distanceTo(Color(0xFF506070)), 0.00000001);
    EXPECT_NEAR(60.0 / 255, AnimatableColorImpl(Color(0x3C000000)).distanceTo(Color(0x00FFFFFF)), 0.00000001);
    EXPECT_NEAR(60.0 / 255, AnimatableColorImpl(Color(0x3C000000)).distanceTo(Color(0x3C00FF00)), 0.00000001);

    RefPtrWillBeRawPtr<AnimatableColor> first = AnimatableColor::create(AnimatableColorImpl(Color(0xFF53647C)), AnimatableColorImpl(Color(0xFF000000)));
    RefPtrWillBeRawPtr<AnimatableColor> second = AnimatableColor::create(AnimatableColorImpl(Color(0xFF506070)), AnimatableColorImpl(Color(0xFF000000)));
    EXPECT_NEAR(13.0 / 255, AnimatableValue::distance(first.get(), second.get()), 0.00000001);
}

}
