/*
 * Copyright (C) 2011 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <gtest/gtest.h>
#include "flutter/sky/engine/wtf/CheckedArithmetic.h"

namespace {

#define CheckedArithmeticTest(type, coerceLiteral, MixedSignednessTest)        \
  TEST(WTF, Checked_##type) {                                                  \
    Checked<type, RecordOverflow> value;                                       \
    EXPECT_EQ(coerceLiteral(0), value.unsafeGet());                            \
    EXPECT_EQ(std::numeric_limits<type>::max(),                                \
              (value + std::numeric_limits<type>::max()).unsafeGet());         \
    EXPECT_EQ(std::numeric_limits<type>::max(),                                \
              (std::numeric_limits<type>::max() + value).unsafeGet());         \
    EXPECT_EQ(std::numeric_limits<type>::min(),                                \
              (value + std::numeric_limits<type>::min()).unsafeGet());         \
    EXPECT_EQ(std::numeric_limits<type>::min(),                                \
              (std::numeric_limits<type>::min() + value).unsafeGet());         \
    EXPECT_EQ(coerceLiteral(0), (value * coerceLiteral(0)).unsafeGet());       \
    EXPECT_EQ(coerceLiteral(0), (coerceLiteral(0) * value).unsafeGet());       \
    EXPECT_EQ(coerceLiteral(0), (value * value).unsafeGet());                  \
    EXPECT_EQ(coerceLiteral(0), (value - coerceLiteral(0)).unsafeGet());       \
    EXPECT_EQ(coerceLiteral(0), (coerceLiteral(0) - value).unsafeGet());       \
    EXPECT_EQ(coerceLiteral(0), (value - value).unsafeGet());                  \
    EXPECT_EQ(coerceLiteral(0), (value++).unsafeGet());                        \
    EXPECT_EQ(coerceLiteral(1), (value--).unsafeGet());                        \
    EXPECT_EQ(coerceLiteral(1), (++value).unsafeGet());                        \
    EXPECT_EQ(coerceLiteral(0), (--value).unsafeGet());                        \
    EXPECT_EQ(coerceLiteral(10), (value += coerceLiteral(10)).unsafeGet());    \
    EXPECT_EQ(coerceLiteral(10), value.unsafeGet());                           \
    EXPECT_EQ(coerceLiteral(100), (value *= coerceLiteral(10)).unsafeGet());   \
    EXPECT_EQ(coerceLiteral(100), value.unsafeGet());                          \
    EXPECT_EQ(coerceLiteral(0), (value -= coerceLiteral(100)).unsafeGet());    \
    EXPECT_EQ(coerceLiteral(0), value.unsafeGet());                            \
    value = 10;                                                                \
    EXPECT_EQ(coerceLiteral(10), value.unsafeGet());                           \
    EXPECT_EQ(coerceLiteral(0), (value - coerceLiteral(10)).unsafeGet());      \
    EXPECT_EQ(coerceLiteral(10), value.unsafeGet());                           \
    value = std::numeric_limits<type>::min();                                  \
    EXPECT_EQ(true, (Checked<type, RecordOverflow>(value - coerceLiteral(1)))  \
                        .hasOverflowed());                                     \
    EXPECT_EQ(true, !((value--).hasOverflowed()));                             \
    EXPECT_EQ(true, value.hasOverflowed());                                    \
    value = std::numeric_limits<type>::max();                                  \
    EXPECT_EQ(true, !value.hasOverflowed());                                   \
    EXPECT_EQ(true, (Checked<type, RecordOverflow>(value + coerceLiteral(1)))  \
                        .hasOverflowed());                                     \
    EXPECT_EQ(true, !(value++).hasOverflowed());                               \
    EXPECT_EQ(true, value.hasOverflowed());                                    \
    value = std::numeric_limits<type>::max();                                  \
    EXPECT_EQ(true, (value += coerceLiteral(1)).hasOverflowed());              \
    EXPECT_EQ(true, value.hasOverflowed());                                    \
    value = 10;                                                                \
    type _value = 0;                                                           \
    EXPECT_EQ(true,                                                            \
              CheckedState::DidNotOverflow ==                                  \
                  (value * Checked<type, RecordOverflow>(0)).safeGet(_value)); \
    _value = 0;                                                                \
    EXPECT_EQ(true,                                                            \
              CheckedState::DidNotOverflow ==                                  \
                  (Checked<type, RecordOverflow>(0) * value).safeGet(_value)); \
    _value = 0;                                                                \
    EXPECT_EQ(true, CheckedState::DidOverflow ==                               \
                        (value * Checked<type, RecordOverflow>(                \
                                     std::numeric_limits<type>::max()))        \
                            .safeGet(_value));                                 \
    _value = 0;                                                                \
    EXPECT_EQ(                                                                 \
        true,                                                                  \
        CheckedState::DidOverflow ==                                           \
            (Checked<type, RecordOverflow>(std::numeric_limits<type>::max()) * \
             value)                                                            \
                .safeGet(_value));                                             \
    value = 0;                                                                 \
    _value = 0;                                                                \
    EXPECT_EQ(true, CheckedState::DidNotOverflow ==                            \
                        (value * Checked<type, RecordOverflow>(                \
                                     std::numeric_limits<type>::max()))        \
                            .safeGet(_value));                                 \
    _value = 0;                                                                \
    EXPECT_EQ(                                                                 \
        true,                                                                  \
        CheckedState::DidNotOverflow ==                                        \
            (Checked<type, RecordOverflow>(std::numeric_limits<type>::max()) * \
             value)                                                            \
                .safeGet(_value));                                             \
    value = 1;                                                                 \
    _value = 0;                                                                \
    EXPECT_EQ(true, CheckedState::DidNotOverflow ==                            \
                        (value * Checked<type, RecordOverflow>(                \
                                     std::numeric_limits<type>::max()))        \
                            .safeGet(_value));                                 \
    _value = 0;                                                                \
    EXPECT_EQ(                                                                 \
        true,                                                                  \
        CheckedState::DidNotOverflow ==                                        \
            (Checked<type, RecordOverflow>(std::numeric_limits<type>::max()) * \
             value)                                                            \
                .safeGet(_value));                                             \
    _value = 0;                                                                \
    value = 0;                                                                 \
    EXPECT_EQ(true, CheckedState::DidNotOverflow ==                            \
                        (value * Checked<type, RecordOverflow>(                \
                                     std::numeric_limits<type>::max()))        \
                            .safeGet(_value));                                 \
    _value = 0;                                                                \
    EXPECT_EQ(                                                                 \
        true,                                                                  \
        CheckedState::DidNotOverflow ==                                        \
            (Checked<type, RecordOverflow>(std::numeric_limits<type>::max()) * \
             (type)0)                                                          \
                .safeGet(_value));                                             \
    _value = 0;                                                                \
    value = 1;                                                                 \
    EXPECT_EQ(true, CheckedState::DidNotOverflow ==                            \
                        (value * Checked<type, RecordOverflow>(                \
                                     std::numeric_limits<type>::max()))        \
                            .safeGet(_value));                                 \
    _value = 0;                                                                \
    EXPECT_EQ(                                                                 \
        true,                                                                  \
        CheckedState::DidNotOverflow ==                                        \
            (Checked<type, RecordOverflow>(std::numeric_limits<type>::max()) * \
             (type)1)                                                          \
                .safeGet(_value));                                             \
    _value = 0;                                                                \
    value = 2;                                                                 \
    EXPECT_EQ(true, CheckedState::DidOverflow ==                               \
                        (value * Checked<type, RecordOverflow>(                \
                                     std::numeric_limits<type>::max()))        \
                            .safeGet(_value));                                 \
    _value = 0;                                                                \
    EXPECT_EQ(                                                                 \
        true,                                                                  \
        CheckedState::DidOverflow ==                                           \
            (Checked<type, RecordOverflow>(std::numeric_limits<type>::max()) * \
             (type)2)                                                          \
                .safeGet(_value));                                             \
    value = 10;                                                                \
    EXPECT_EQ(true, (value * Checked<type, RecordOverflow>(                    \
                                 std::numeric_limits<type>::max()))            \
                        .hasOverflowed());                                     \
    MixedSignednessTest(                                                       \
        EXPECT_EQ(coerceLiteral(0), (value + -10).unsafeGet()));               \
    MixedSignednessTest(EXPECT_EQ(0U, (value - 10U).unsafeGet()));             \
    MixedSignednessTest(                                                       \
        EXPECT_EQ(coerceLiteral(0), (-10 + value).unsafeGet()));               \
    MixedSignednessTest(EXPECT_EQ(0U, (10U - value).unsafeGet()));             \
    value = std::numeric_limits<type>::min();                                  \
    MixedSignednessTest(EXPECT_EQ(                                             \
        true, (Checked<type, RecordOverflow>(value - 1)).hasOverflowed()));    \
    MixedSignednessTest(EXPECT_EQ(true, !(value--).hasOverflowed()));          \
    MixedSignednessTest(EXPECT_EQ(true, value.hasOverflowed()));               \
    value = std::numeric_limits<type>::max();                                  \
    MixedSignednessTest(EXPECT_EQ(true, !value.hasOverflowed()));              \
    MixedSignednessTest(EXPECT_EQ(                                             \
        true, (Checked<type, RecordOverflow>(value + 1)).hasOverflowed()));    \
    MixedSignednessTest(EXPECT_EQ(true, !(value++).hasOverflowed()));          \
    MixedSignednessTest(EXPECT_EQ(true, value.hasOverflowed()));               \
    value = std::numeric_limits<type>::max();                                  \
    MixedSignednessTest(EXPECT_EQ(true, (value += 1).hasOverflowed()));        \
    MixedSignednessTest(EXPECT_EQ(true, value.hasOverflowed()));               \
    value = std::numeric_limits<type>::min();                                  \
    MixedSignednessTest(EXPECT_EQ(true, (value - 1U).hasOverflowed()));        \
    MixedSignednessTest(EXPECT_EQ(true, !(value--).hasOverflowed()));          \
    MixedSignednessTest(EXPECT_EQ(true, value.hasOverflowed()));               \
    value = std::numeric_limits<type>::max();                                  \
    MixedSignednessTest(EXPECT_EQ(true, !value.hasOverflowed()));              \
    MixedSignednessTest(EXPECT_EQ(                                             \
        true, (Checked<type, RecordOverflow>(value + 1U)).hasOverflowed()));   \
    MixedSignednessTest(EXPECT_EQ(true, !(value++).hasOverflowed()));          \
    MixedSignednessTest(EXPECT_EQ(true, value.hasOverflowed()));               \
    value = std::numeric_limits<type>::max();                                  \
    MixedSignednessTest(EXPECT_EQ(true, (value += 1U).hasOverflowed()));       \
    MixedSignednessTest(EXPECT_EQ(true, value.hasOverflowed()));               \
  }

#define CoerceLiteralToUnsigned(x) x##U
#define CoerceLiteralNop(x) x
#define AllowMixedSignednessTest(x) x
#define IgnoreMixedSignednessTest(x)
CheckedArithmeticTest(int8_t, CoerceLiteralNop, IgnoreMixedSignednessTest)
    CheckedArithmeticTest(int16_t, CoerceLiteralNop, IgnoreMixedSignednessTest)
        CheckedArithmeticTest(int32_t,
                              CoerceLiteralNop,
                              AllowMixedSignednessTest)
            CheckedArithmeticTest(uint32_t,
                                  CoerceLiteralToUnsigned,
                                  AllowMixedSignednessTest)
                CheckedArithmeticTest(int64_t,
                                      CoerceLiteralNop,
                                      IgnoreMixedSignednessTest)
                    CheckedArithmeticTest(uint64_t,
                                          CoerceLiteralToUnsigned,
                                          IgnoreMixedSignednessTest)

}  // namespace
