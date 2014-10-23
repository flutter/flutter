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

#include "wtf/SaturatedArithmetic.h"
#include <gtest/gtest.h>
#include <limits.h>

namespace {

TEST(SaturatedArithmeticTest, Addition)
{
    EXPECT_EQ(0, saturatedAddition(0, 0));
    EXPECT_EQ(1, saturatedAddition(0, 1));
    EXPECT_EQ(100, saturatedAddition(0, 100));
    EXPECT_EQ(150, saturatedAddition(100, 50));

    EXPECT_EQ(-1, saturatedAddition(0, -1));
    EXPECT_EQ(0, saturatedAddition(1, -1));
    EXPECT_EQ(50, saturatedAddition(100, -50));
    EXPECT_EQ(-50, saturatedAddition(50, -100));

    EXPECT_EQ(INT_MAX - 1, saturatedAddition(INT_MAX - 1, 0));
    EXPECT_EQ(INT_MAX, saturatedAddition(INT_MAX - 1, 1));
    EXPECT_EQ(INT_MAX, saturatedAddition(INT_MAX - 1, 2));
    EXPECT_EQ(INT_MAX - 1, saturatedAddition(0, INT_MAX - 1));
    EXPECT_EQ(INT_MAX, saturatedAddition(1, INT_MAX - 1));
    EXPECT_EQ(INT_MAX, saturatedAddition(2, INT_MAX - 1));
    EXPECT_EQ(INT_MAX, saturatedAddition(INT_MAX - 1, INT_MAX - 1));
    EXPECT_EQ(INT_MAX, saturatedAddition(INT_MAX, INT_MAX));

    EXPECT_EQ(INT_MIN, saturatedAddition(INT_MIN, 0));
    EXPECT_EQ(INT_MIN + 1, saturatedAddition(INT_MIN + 1, 0));
    EXPECT_EQ(INT_MIN + 2, saturatedAddition(INT_MIN + 1, 1));
    EXPECT_EQ(INT_MIN + 3, saturatedAddition(INT_MIN + 1, 2));
    EXPECT_EQ(INT_MIN, saturatedAddition(INT_MIN + 1, -1));
    EXPECT_EQ(INT_MIN, saturatedAddition(INT_MIN + 1, -2));
    EXPECT_EQ(INT_MIN + 1, saturatedAddition(0, INT_MIN + 1));
    EXPECT_EQ(INT_MIN, saturatedAddition(-1, INT_MIN + 1));
    EXPECT_EQ(INT_MIN, saturatedAddition(-2, INT_MIN + 1));

    EXPECT_EQ(INT_MAX / 2 + 10000, saturatedAddition(INT_MAX / 2, 10000));
    EXPECT_EQ(INT_MAX, saturatedAddition(INT_MAX / 2 + 1, INT_MAX / 2 + 1));
    EXPECT_EQ(-1, saturatedAddition(INT_MIN, INT_MAX));
}

TEST(SaturatedArithmeticTest, Subtraction)
{
    EXPECT_EQ(0, saturatedSubtraction(0, 0));
    EXPECT_EQ(-1, saturatedSubtraction(0, 1));
    EXPECT_EQ(-100, saturatedSubtraction(0, 100));
    EXPECT_EQ(50, saturatedSubtraction(100, 50));

    EXPECT_EQ(1, saturatedSubtraction(0, -1));
    EXPECT_EQ(2, saturatedSubtraction(1, -1));
    EXPECT_EQ(150, saturatedSubtraction(100, -50));
    EXPECT_EQ(150, saturatedSubtraction(50, -100));

    EXPECT_EQ(INT_MAX, saturatedSubtraction(INT_MAX, 0));
    EXPECT_EQ(INT_MAX - 1, saturatedSubtraction(INT_MAX, 1));
    EXPECT_EQ(INT_MAX - 1, saturatedSubtraction(INT_MAX - 1, 0));
    EXPECT_EQ(INT_MAX, saturatedSubtraction(INT_MAX - 1, -1));
    EXPECT_EQ(INT_MAX, saturatedSubtraction(INT_MAX - 1, -2));
    EXPECT_EQ(-INT_MAX + 1, saturatedSubtraction(0, INT_MAX - 1));
    EXPECT_EQ(-INT_MAX, saturatedSubtraction(-1, INT_MAX - 1));
    EXPECT_EQ(-INT_MAX - 1, saturatedSubtraction(-2, INT_MAX - 1));
    EXPECT_EQ(-INT_MAX - 1, saturatedSubtraction(-3, INT_MAX - 1));

    EXPECT_EQ(INT_MIN, saturatedSubtraction(INT_MIN, 0));
    EXPECT_EQ(INT_MIN + 1, saturatedSubtraction(INT_MIN + 1, 0));
    EXPECT_EQ(INT_MIN, saturatedSubtraction(INT_MIN + 1, 1));
    EXPECT_EQ(INT_MIN, saturatedSubtraction(INT_MIN + 1, 2));

    EXPECT_EQ(0, saturatedSubtraction(INT_MIN, INT_MIN));
    EXPECT_EQ(0, saturatedSubtraction(INT_MAX, INT_MAX));
    EXPECT_EQ(INT_MAX, saturatedSubtraction(INT_MAX, INT_MIN));
}

TEST(SaturatedArithmeticTest, SetSigned)
{
    const int kFractionBits = 6;
    const int intMaxForLayoutUnit = INT_MAX >> kFractionBits;
    const int intMinForLayoutUnit = INT_MIN >> kFractionBits;

    EXPECT_EQ(0, saturatedSet(0, kFractionBits));

    // Internally the max number we can represent (without saturating)
    // is all the (non-sign) bits set except for the bottom n fraction bits
    const int maxInternalRepresentation = INT_MAX ^ ((1 << kFractionBits)-1);
    EXPECT_EQ(maxInternalRepresentation,
        saturatedSet(intMaxForLayoutUnit, kFractionBits));

    EXPECT_EQ(getMaxSaturatedSetResultForTesting(kFractionBits),
        saturatedSet(intMaxForLayoutUnit + 100, kFractionBits));

    EXPECT_EQ((intMaxForLayoutUnit - 100) << kFractionBits,
        saturatedSet(intMaxForLayoutUnit - 100, kFractionBits));

    EXPECT_EQ(getMinSaturatedSetResultForTesting(kFractionBits),
        saturatedSet(intMinForLayoutUnit, kFractionBits));

    EXPECT_EQ(getMinSaturatedSetResultForTesting(kFractionBits),
        saturatedSet(intMinForLayoutUnit - 100, kFractionBits));

    EXPECT_EQ((intMinForLayoutUnit + 100) << kFractionBits,
        saturatedSet(intMinForLayoutUnit + 100, kFractionBits));
}

TEST(SaturatedArithmeticTest, SetUnsigned)
{
    const int kFractionBits = 6;
    const int intMaxForLayoutUnit = INT_MAX >> kFractionBits;

    EXPECT_EQ(0, saturatedSet((unsigned)0, kFractionBits));

    EXPECT_EQ(getMaxSaturatedSetResultForTesting(kFractionBits),
        saturatedSet((unsigned)intMaxForLayoutUnit, kFractionBits));

    const unsigned kOverflowed = intMaxForLayoutUnit + 100;
    EXPECT_EQ(getMaxSaturatedSetResultForTesting(kFractionBits),
        saturatedSet(kOverflowed, kFractionBits));

    const unsigned kNotOverflowed = intMaxForLayoutUnit - 100;
    EXPECT_EQ((intMaxForLayoutUnit - 100) << kFractionBits,
        saturatedSet(kNotOverflowed, kFractionBits));
}


} // namespace
