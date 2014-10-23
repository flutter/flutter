/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"

#include "platform/animation/UnitBezier.h"

#include <gtest/gtest.h>

using namespace blink;

namespace {

TEST(UnitBezierTest, BasicUse)
{
    UnitBezier bezier(0.5, 1.0, 0.5, 1.0);
    EXPECT_EQ(0.875, bezier.solve(0.5, 0.005));
}

TEST(UnitBezierTest, Overshoot)
{
    UnitBezier bezier(0.5, 2.0, 0.5, 2.0);
    EXPECT_EQ(1.625, bezier.solve(0.5, 0.005));
}

TEST(UnitBezierTest, Undershoot)
{
    UnitBezier bezier(0.5, -1.0, 0.5, -1.0);
    EXPECT_EQ(-0.625, bezier.solve(0.5, 0.005));
}

TEST(UnitBezierTest, InputAtEdgeOfRange)
{
    UnitBezier bezier(0.5, 1.0, 0.5, 1.0);
    EXPECT_EQ(0.0, bezier.solve(0.0, 0.005));
    EXPECT_EQ(1.0, bezier.solve(1.0, 0.005));
}

TEST(UnitBezierTest, InputOutOfRange)
{
    UnitBezier bezier(0.5, 1.0, 0.5, 1.0);
    EXPECT_EQ(-2.0, bezier.solve(-1.0, 0.005));
    EXPECT_EQ(1.0, bezier.solve(2.0, 0.005));
}

TEST(UnitBezierTest, InputOutOfRangeLargeEpsilon)
{
    UnitBezier bezier(0.5, 1.0, 0.5, 1.0);
    EXPECT_EQ(-2.0, bezier.solve(-1.0, 1.0));
    EXPECT_EQ(1.0, bezier.solve(2.0, 1.0));
}

TEST(UnitBezierTest, InputOutOfRangeCoincidentEndpoints)
{
    UnitBezier bezier(0.0, 0.0, 1.0, 1.0);
    EXPECT_EQ(-1.0, bezier.solve(-1.0, 0.005));
    EXPECT_EQ(2.0, bezier.solve(2.0, 0.005));
}

TEST(UnitBezierTest, InputOutOfRangeVerticalGradient)
{
    UnitBezier bezier(0.0, 1.0, 1.0, 0.0);
    EXPECT_EQ(0.0, bezier.solve(-1.0, 0.005));
    EXPECT_EQ(1.0, bezier.solve(2.0, 0.005));
}

TEST(UnitBezierTest, InputOutOfRangeDistinctEndpoints)
{
    UnitBezier bezier(0.1, 0.2, 0.8, 0.8);
    EXPECT_EQ(-2.0, bezier.solve(-1.0, 0.005));
    EXPECT_EQ(2.0, bezier.solve(2.0, 0.005));
}

} // namespace
