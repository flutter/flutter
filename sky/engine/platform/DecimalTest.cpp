/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
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

#include "flutter/sky/engine/platform/Decimal.h"

#include <float.h>
#include <gtest/gtest.h>
#include "flutter/sky/engine/wtf/MathExtras.h"
#include "flutter/sky/engine/wtf/text/CString.h"

namespace blink {

std::ostream& operator<<(std::ostream& os, const Decimal& decimal) {
  Decimal::EncodedData data = decimal.value();
  return os << "encode(" << String::number(data.coefficient()).ascii().data()
            << ", " << String::number(data.exponent()).ascii().data() << ", "
            << (data.sign() == Decimal::Negative ? "Negative" : "Positive")
            << ")=" << decimal.toString().ascii().data();
}

}  // namespace blink

using namespace blink;

// Simulate WebCore/html/StepRange
class DecimalStepRange {
 public:
  Decimal maximum;
  Decimal minimum;
  Decimal step;

  DecimalStepRange(const Decimal& minimum,
                   const Decimal& maximum,
                   const Decimal& step)
      : maximum(maximum), minimum(minimum), step(step) {}

  Decimal clampValue(Decimal value) const {
    const Decimal result = minimum + ((value - minimum) / step).round() * step;
    ASSERT(result.isFinite());
    return result > maximum ? result - step : result;
  }
};

class DecimalTest : public ::testing::Test {
 protected:
  typedef Decimal::Sign Sign;

 protected:
  static const Sign Positive = Decimal::Positive;

 protected:
  static const Sign Negative = Decimal::Negative;

  Decimal encode(uint64_t coefficient, int exponent, Sign sign) {
    return Decimal(sign, exponent, coefficient);
  }

 protected:
  Decimal fromString(const String& string) {
    return Decimal::fromString(string);
  }

 protected:
  Decimal stepDown(const String& minimum,
                   const String& maximum,
                   const String& step,
                   const String& valueString,
                   int numberOfStepTimes) {
    DecimalStepRange stepRange(fromString(minimum), fromString(maximum),
                               fromString(step));
    Decimal value = fromString(valueString);
    for (int i = 0; i < numberOfStepTimes; ++i) {
      value -= stepRange.step;
      value = stepRange.clampValue(value);
    }
    return value;
  }

 protected:
  Decimal stepUp(const String& minimum,
                 const String& maximum,
                 const String& step,
                 const String& valueString,
                 int numberOfStepTimes) {
    DecimalStepRange stepRange(fromString(minimum), fromString(maximum),
                               fromString(step));
    Decimal value = fromString(valueString);
    for (int i = 0; i < numberOfStepTimes; ++i) {
      value += stepRange.step;
      value = stepRange.clampValue(value);
    }
    return value;
  }
};

// FIXME: We should use expectedSign without "Decimal::", however, g++ causes
// undefined references for DecimalTest::Positive and Negative.
#define EXPECT_DECIMAL_ENCODED_DATA_EQ(expectedCoefficient, expectedExponent, \
                                       expectedSign, decimal)                 \
  EXPECT_EQ((expectedCoefficient), (decimal).value().coefficient());          \
  EXPECT_EQ((expectedExponent), (decimal).value().exponent());                \
  EXPECT_EQ(Decimal::expectedSign, (decimal).value().sign());

#define EXPECT_DECIMAL_STREQ(expected, decimal) \
  EXPECT_STREQ((expected), (decimal).toString().ascii().data())

TEST_F(DecimalTest, Abs) {
  EXPECT_EQ(encode(0, 0, Positive), encode(0, 0, Positive).abs());
  EXPECT_EQ(encode(0, 0, Positive), encode(0, 0, Negative).abs());

  EXPECT_EQ(encode(0, 10, Positive), encode(0, 10, Positive).abs());
  EXPECT_EQ(encode(0, 10, Positive), encode(0, 10, Negative).abs());

  EXPECT_EQ(encode(0, -10, Positive), encode(0, -10, Positive).abs());
  EXPECT_EQ(encode(0, -10, Positive), encode(0, -10, Negative).abs());

  EXPECT_EQ(encode(1, 0, Positive), encode(1, 0, Positive).abs());
  EXPECT_EQ(encode(1, 0, Positive), encode(1, 0, Negative).abs());

  EXPECT_EQ(encode(1, 10, Positive), encode(1, 10, Positive).abs());
  EXPECT_EQ(encode(1, 10, Positive), encode(1, 10, Negative).abs());

  EXPECT_EQ(encode(1, -10, Positive), encode(1, -10, Positive).abs());
  EXPECT_EQ(encode(1, -10, Positive), encode(1, -10, Negative).abs());
}

TEST_F(DecimalTest, AbsBigExponent) {
  EXPECT_EQ(encode(1, 1000, Positive), encode(1, 1000, Positive).abs());
  EXPECT_EQ(encode(1, 1000, Positive), encode(1, 1000, Negative).abs());
}

TEST_F(DecimalTest, AbsSmallExponent) {
  EXPECT_EQ(encode(1, -1000, Positive), encode(1, -1000, Positive).abs());
  EXPECT_EQ(encode(1, -1000, Positive), encode(1, -1000, Negative).abs());
}

TEST_F(DecimalTest, AbsSpecialValues) {
  EXPECT_EQ(Decimal::infinity(Positive), Decimal::infinity(Positive).abs());
  EXPECT_EQ(Decimal::infinity(Positive), Decimal::infinity(Negative).abs());
  EXPECT_EQ(Decimal::nan(), Decimal::nan().abs());
}

TEST_F(DecimalTest, Add) {
  EXPECT_EQ(encode(0, 0, Positive), Decimal(0) + Decimal(0));
  EXPECT_EQ(Decimal(1), Decimal(2) + Decimal(-1));
  EXPECT_EQ(Decimal(1), Decimal(-1) + Decimal(2));
  EXPECT_EQ(encode(100, 0, Positive), Decimal(99) + Decimal(1));
  EXPECT_EQ(encode(100, 0, Negative), Decimal(-50) + Decimal(-50));
  EXPECT_EQ(encode(UINT64_C(1000000000000000), 35, Positive),
            encode(1, 50, Positive) + Decimal(1));
  EXPECT_EQ(encode(UINT64_C(1000000000000000), 35, Positive),
            Decimal(1) + encode(1, 50, Positive));
  EXPECT_EQ(encode(UINT64_C(10000000001), 0, Positive),
            encode(1, 10, Positive) + Decimal(1));
  EXPECT_EQ(encode(UINT64_C(10000000001), 0, Positive),
            Decimal(1) + encode(1, 10, Positive));
  EXPECT_EQ(encode(1, 0, Positive),
            encode(1, -1022, Positive) + encode(1, 0, Positive));
  EXPECT_EQ(encode(2, -1022, Positive),
            encode(1, -1022, Positive) + encode(1, -1022, Positive));
}

TEST_F(DecimalTest, AddBigExponent) {
  EXPECT_EQ(encode(1, 1022, Positive),
            encode(1, 1022, Positive) + encode(1, 0, Positive));
  EXPECT_EQ(encode(2, 1022, Positive),
            encode(1, 1022, Positive) + encode(1, 1022, Positive));
  EXPECT_EQ(Decimal::infinity(Positive),
            encode(std::numeric_limits<uint64_t>::max(), 1022, Positive) +
                encode(1, 0, Positive));
  EXPECT_EQ(encode(1, 1022, Positive),
            encode(1, 1022, Positive) + encode(1, -1000, Positive));
}

TEST_F(DecimalTest, AddSmallExponent) {
  EXPECT_EQ(encode(1, 0, Positive),
            encode(1, -1022, Positive) + encode(1, 0, Positive));
  EXPECT_EQ(encode(2, -1022, Positive),
            encode(1, -1022, Positive) + encode(1, -1022, Positive));
}

TEST_F(DecimalTest, AddSpecialValues) {
  const Decimal Infinity(Decimal::infinity(Positive));
  const Decimal MinusInfinity(Decimal::infinity(Negative));
  const Decimal NaN(Decimal::nan());
  const Decimal Ten(10);

  EXPECT_EQ(Infinity, Infinity + Infinity);
  EXPECT_EQ(NaN, Infinity + MinusInfinity);
  EXPECT_EQ(NaN, MinusInfinity + Infinity);
  EXPECT_EQ(MinusInfinity, MinusInfinity + MinusInfinity);

  EXPECT_EQ(Infinity, Infinity + Ten);
  EXPECT_EQ(Infinity, Ten + Infinity);
  EXPECT_EQ(MinusInfinity, MinusInfinity + Ten);
  EXPECT_EQ(MinusInfinity, Ten + MinusInfinity);

  EXPECT_EQ(NaN, NaN + NaN);
  EXPECT_EQ(NaN, NaN + Ten);
  EXPECT_EQ(NaN, Ten + NaN);

  EXPECT_EQ(NaN, NaN - Infinity);
  EXPECT_EQ(NaN, NaN - MinusInfinity);
  EXPECT_EQ(NaN, Infinity - NaN);
  EXPECT_EQ(NaN, MinusInfinity - NaN);
}

TEST_F(DecimalTest, Ceiling) {
  EXPECT_EQ(Decimal(1), Decimal(1).ceiling());
  EXPECT_EQ(Decimal(1), encode(1, -10, Positive).ceiling());
  EXPECT_EQ(Decimal(2), encode(11, -1, Positive).ceiling());
  EXPECT_EQ(Decimal(2), encode(13, -1, Positive).ceiling());
  EXPECT_EQ(Decimal(2), encode(15, -1, Positive).ceiling());
  EXPECT_EQ(Decimal(2), encode(19, -1, Positive).ceiling());
  EXPECT_EQ(Decimal(2), encode(151, -2, Positive).ceiling());
  EXPECT_EQ(Decimal(2), encode(101, -2, Positive).ceiling());
  EXPECT_EQ(Decimal(1), encode(199, -3, Positive).ceiling());
  EXPECT_EQ(Decimal(2), encode(199, -2, Positive).ceiling());
  EXPECT_EQ(Decimal(3), encode(209, -2, Positive).ceiling());

  EXPECT_EQ(Decimal(-1), Decimal(-1).ceiling());
  EXPECT_EQ(Decimal(0), encode(1, -10, Negative).ceiling());
  EXPECT_EQ(Decimal(-1), encode(11, -1, Negative).ceiling());
  EXPECT_EQ(Decimal(-1), encode(13, -1, Negative).ceiling());
  EXPECT_EQ(Decimal(-1), encode(15, -1, Negative).ceiling());
  EXPECT_EQ(Decimal(-1), encode(19, -1, Negative).ceiling());
  EXPECT_EQ(Decimal(-1), encode(151, -2, Negative).ceiling());
  EXPECT_EQ(Decimal(-1), encode(101, -2, Negative).ceiling());
  EXPECT_EQ(Decimal(0), encode(199, -3, Negative).ceiling());
  EXPECT_EQ(Decimal(-1), encode(199, -2, Negative).ceiling());
  EXPECT_EQ(Decimal(-2), encode(209, -2, Negative).ceiling());
}

TEST_F(DecimalTest, CeilingBigExponent) {
  EXPECT_EQ(encode(1, 1000, Positive), encode(1, 1000, Positive).ceiling());
  EXPECT_EQ(encode(1, 1000, Negative), encode(1, 1000, Negative).ceiling());
}

TEST_F(DecimalTest, CeilingSmallExponent) {
  EXPECT_EQ(encode(1, 0, Positive), encode(1, -1000, Positive).ceiling());
  EXPECT_EQ(encode(0, 0, Negative), encode(1, -1000, Negative).ceiling());
}

TEST_F(DecimalTest, CeilingSpecialValues) {
  EXPECT_EQ(Decimal::infinity(Positive), Decimal::infinity(Positive).ceiling());
  EXPECT_EQ(Decimal::infinity(Negative), Decimal::infinity(Negative).ceiling());
  EXPECT_EQ(Decimal::nan(), Decimal::nan().ceiling());
}

TEST_F(DecimalTest, Compare) {
  EXPECT_TRUE(Decimal(0) == Decimal(0));
  EXPECT_TRUE(Decimal(0) != Decimal(1));
  EXPECT_TRUE(Decimal(0) < Decimal(1));
  EXPECT_TRUE(Decimal(0) <= Decimal(0));
  EXPECT_TRUE(Decimal(0) > Decimal(-1));
  EXPECT_TRUE(Decimal(0) >= Decimal(0));

  EXPECT_FALSE(Decimal(1) == Decimal(2));
  EXPECT_FALSE(Decimal(1) != Decimal(1));
  EXPECT_FALSE(Decimal(1) < Decimal(0));
  EXPECT_FALSE(Decimal(1) <= Decimal(0));
  EXPECT_FALSE(Decimal(1) > Decimal(2));
  EXPECT_FALSE(Decimal(1) >= Decimal(2));
}

TEST_F(DecimalTest, CompareBigExponent) {
  EXPECT_TRUE(encode(1, 1000, Positive) == encode(1, 1000, Positive));
  EXPECT_FALSE(encode(1, 1000, Positive) != encode(1, 1000, Positive));
  EXPECT_FALSE(encode(1, 1000, Positive) < encode(1, 1000, Positive));
  EXPECT_TRUE(encode(1, 1000, Positive) <= encode(1, 1000, Positive));
  EXPECT_FALSE(encode(1, 1000, Positive) > encode(1, 1000, Positive));
  EXPECT_TRUE(encode(1, 1000, Positive) >= encode(1, 1000, Positive));

  EXPECT_TRUE(encode(1, 1000, Negative) == encode(1, 1000, Negative));
  EXPECT_FALSE(encode(1, 1000, Negative) != encode(1, 1000, Negative));
  EXPECT_FALSE(encode(1, 1000, Negative) < encode(1, 1000, Negative));
  EXPECT_TRUE(encode(1, 1000, Negative) <= encode(1, 1000, Negative));
  EXPECT_FALSE(encode(1, 1000, Negative) > encode(1, 1000, Negative));
  EXPECT_TRUE(encode(1, 1000, Negative) >= encode(1, 1000, Negative));

  EXPECT_FALSE(encode(2, 1000, Positive) == encode(1, 1000, Positive));
  EXPECT_TRUE(encode(2, 1000, Positive) != encode(1, 1000, Positive));
  EXPECT_FALSE(encode(2, 1000, Positive) < encode(1, 1000, Positive));
  EXPECT_FALSE(encode(2, 1000, Positive) <= encode(1, 1000, Positive));
  EXPECT_TRUE(encode(2, 1000, Positive) > encode(1, 1000, Positive));
  EXPECT_TRUE(encode(2, 1000, Positive) >= encode(1, 1000, Positive));

  EXPECT_FALSE(encode(2, 1000, Negative) == encode(1, 1000, Negative));
  EXPECT_TRUE(encode(2, 1000, Negative) != encode(1, 1000, Negative));
  EXPECT_TRUE(encode(2, 1000, Negative) < encode(1, 1000, Negative));
  EXPECT_TRUE(encode(2, 1000, Negative) <= encode(1, 1000, Negative));
  EXPECT_FALSE(encode(2, 1000, Negative) > encode(1, 1000, Negative));
  EXPECT_FALSE(encode(2, 1000, Negative) >= encode(1, 1000, Negative));
}

TEST_F(DecimalTest, CompareSmallExponent) {
  EXPECT_TRUE(encode(1, -1000, Positive) == encode(1, -1000, Positive));
  EXPECT_FALSE(encode(1, -1000, Positive) != encode(1, -1000, Positive));
  EXPECT_FALSE(encode(1, -1000, Positive) < encode(1, -1000, Positive));
  EXPECT_TRUE(encode(1, -1000, Positive) <= encode(1, -1000, Positive));
  EXPECT_FALSE(encode(1, -1000, Positive) > encode(1, -1000, Positive));
  EXPECT_TRUE(encode(1, -1000, Positive) >= encode(1, -1000, Positive));

  EXPECT_TRUE(encode(1, -1000, Negative) == encode(1, -1000, Negative));
  EXPECT_FALSE(encode(1, -1000, Negative) != encode(1, -1000, Negative));
  EXPECT_FALSE(encode(1, -1000, Negative) < encode(1, -1000, Negative));
  EXPECT_TRUE(encode(1, -1000, Negative) <= encode(1, -1000, Negative));
  EXPECT_FALSE(encode(1, -1000, Negative) > encode(1, -1000, Negative));
  EXPECT_TRUE(encode(1, -1000, Negative) >= encode(1, -1000, Negative));

  EXPECT_FALSE(encode(2, -1000, Positive) == encode(1, -1000, Positive));
  EXPECT_TRUE(encode(2, -1000, Positive) != encode(1, -1000, Positive));
  EXPECT_FALSE(encode(2, -1000, Positive) < encode(1, -1000, Positive));
  EXPECT_FALSE(encode(2, -1000, Positive) <= encode(1, -1000, Positive));
  EXPECT_TRUE(encode(2, -1000, Positive) > encode(1, -1000, Positive));
  EXPECT_TRUE(encode(2, -1000, Positive) >= encode(1, -1000, Positive));

  EXPECT_FALSE(encode(2, -1000, Negative) == encode(1, -1000, Negative));
  EXPECT_TRUE(encode(2, -1000, Negative) != encode(1, -1000, Negative));
  EXPECT_TRUE(encode(2, -1000, Negative) < encode(1, -1000, Negative));
  EXPECT_TRUE(encode(2, -1000, Negative) <= encode(1, -1000, Negative));
  EXPECT_FALSE(encode(2, -1000, Negative) > encode(1, -1000, Negative));
  EXPECT_FALSE(encode(2, -1000, Negative) >= encode(1, -1000, Negative));
}

TEST_F(DecimalTest, CompareSpecialValues) {
  const Decimal Infinity(Decimal::infinity(Positive));
  const Decimal MinusInfinity(Decimal::infinity(Negative));
  const Decimal NaN(Decimal::nan());
  const Decimal Zero(Decimal::zero(Positive));
  const Decimal MinusZero(Decimal::zero(Negative));
  const Decimal Ten(10);

  EXPECT_TRUE(Zero == Zero);
  EXPECT_FALSE(Zero != Zero);
  EXPECT_FALSE(Zero < Zero);
  EXPECT_TRUE(Zero <= Zero);
  EXPECT_FALSE(Zero > Zero);
  EXPECT_TRUE(Zero >= Zero);

  EXPECT_TRUE(Zero == MinusZero);
  EXPECT_FALSE(Zero != MinusZero);
  EXPECT_FALSE(Zero < MinusZero);
  EXPECT_TRUE(Zero <= MinusZero);
  EXPECT_FALSE(Zero > MinusZero);
  EXPECT_TRUE(Zero >= MinusZero);

  EXPECT_TRUE(MinusZero == Zero);
  EXPECT_FALSE(MinusZero != Zero);
  EXPECT_FALSE(MinusZero < Zero);
  EXPECT_TRUE(MinusZero <= Zero);
  EXPECT_FALSE(MinusZero > Zero);
  EXPECT_TRUE(MinusZero >= Zero);

  EXPECT_TRUE(MinusZero == MinusZero);
  EXPECT_FALSE(MinusZero != MinusZero);
  EXPECT_FALSE(MinusZero < MinusZero);
  EXPECT_TRUE(MinusZero <= MinusZero);
  EXPECT_FALSE(MinusZero > MinusZero);
  EXPECT_TRUE(MinusZero >= MinusZero);

  EXPECT_TRUE(Infinity == Infinity);
  EXPECT_FALSE(Infinity != Infinity);
  EXPECT_FALSE(Infinity < Infinity);
  EXPECT_TRUE(Infinity <= Infinity);
  EXPECT_FALSE(Infinity > Infinity);
  EXPECT_TRUE(Infinity >= Infinity);

  EXPECT_FALSE(Infinity == Ten);
  EXPECT_TRUE(Infinity != Ten);
  EXPECT_FALSE(Infinity < Ten);
  EXPECT_FALSE(Infinity <= Ten);
  EXPECT_TRUE(Infinity > Ten);
  EXPECT_TRUE(Infinity >= Ten);

  EXPECT_FALSE(Infinity == MinusInfinity);
  EXPECT_TRUE(Infinity != MinusInfinity);
  EXPECT_FALSE(Infinity < MinusInfinity);
  EXPECT_FALSE(Infinity <= MinusInfinity);
  EXPECT_TRUE(Infinity > MinusInfinity);
  EXPECT_TRUE(Infinity >= MinusInfinity);

  EXPECT_FALSE(Infinity == NaN);
  EXPECT_FALSE(Infinity != NaN);
  EXPECT_FALSE(Infinity < NaN);
  EXPECT_FALSE(Infinity <= NaN);
  EXPECT_FALSE(Infinity > NaN);
  EXPECT_FALSE(Infinity >= NaN);

  EXPECT_FALSE(MinusInfinity == Infinity);
  EXPECT_TRUE(MinusInfinity != Infinity);
  EXPECT_TRUE(MinusInfinity < Infinity);
  EXPECT_TRUE(MinusInfinity <= Infinity);
  EXPECT_FALSE(MinusInfinity > Infinity);
  EXPECT_FALSE(MinusInfinity >= Infinity);

  EXPECT_FALSE(MinusInfinity == Ten);
  EXPECT_TRUE(MinusInfinity != Ten);
  EXPECT_TRUE(MinusInfinity < Ten);
  EXPECT_TRUE(MinusInfinity <= Ten);
  EXPECT_FALSE(MinusInfinity > Ten);
  EXPECT_FALSE(MinusInfinity >= Ten);

  EXPECT_TRUE(MinusInfinity == MinusInfinity);
  EXPECT_FALSE(MinusInfinity != MinusInfinity);
  EXPECT_FALSE(MinusInfinity < MinusInfinity);
  EXPECT_TRUE(MinusInfinity <= MinusInfinity);
  EXPECT_FALSE(MinusInfinity > MinusInfinity);
  EXPECT_TRUE(MinusInfinity >= MinusInfinity);

  EXPECT_FALSE(MinusInfinity == NaN);
  EXPECT_FALSE(MinusInfinity != NaN);
  EXPECT_FALSE(MinusInfinity < NaN);
  EXPECT_FALSE(MinusInfinity <= NaN);
  EXPECT_FALSE(MinusInfinity > NaN);
  EXPECT_FALSE(MinusInfinity >= NaN);

  EXPECT_FALSE(NaN == Infinity);
  EXPECT_FALSE(NaN != Infinity);
  EXPECT_FALSE(NaN < Infinity);
  EXPECT_FALSE(NaN <= Infinity);
  EXPECT_FALSE(NaN > Infinity);
  EXPECT_FALSE(NaN >= Infinity);

  EXPECT_FALSE(NaN == Ten);
  EXPECT_FALSE(NaN != Ten);
  EXPECT_FALSE(NaN < Ten);
  EXPECT_FALSE(NaN <= Ten);
  EXPECT_FALSE(NaN > Ten);
  EXPECT_FALSE(NaN >= Ten);

  EXPECT_FALSE(NaN == MinusInfinity);
  EXPECT_FALSE(NaN != MinusInfinity);
  EXPECT_FALSE(NaN < MinusInfinity);
  EXPECT_FALSE(NaN <= MinusInfinity);
  EXPECT_FALSE(NaN > MinusInfinity);
  EXPECT_FALSE(NaN >= MinusInfinity);

  EXPECT_TRUE(NaN == NaN);
  EXPECT_FALSE(NaN != NaN);
  EXPECT_FALSE(NaN < NaN);
  EXPECT_TRUE(NaN <= NaN);
  EXPECT_FALSE(NaN > NaN);
  EXPECT_TRUE(NaN >= NaN);
}

TEST_F(DecimalTest, Constructor) {
  EXPECT_DECIMAL_ENCODED_DATA_EQ(0u, 0, Positive, encode(0, 0, Positive));
  EXPECT_DECIMAL_ENCODED_DATA_EQ(0u, 0, Negative, encode(0, 0, Negative));
  EXPECT_DECIMAL_ENCODED_DATA_EQ(1u, 0, Positive, encode(1, 0, Positive));
  EXPECT_DECIMAL_ENCODED_DATA_EQ(1u, 0, Negative, encode(1, 0, Negative));
  EXPECT_DECIMAL_ENCODED_DATA_EQ(1u, 1022, Positive, encode(1, 1022, Positive));
  EXPECT_DECIMAL_ENCODED_DATA_EQ(1u, 1022, Negative, encode(1, 1022, Negative));
  EXPECT_DECIMAL_ENCODED_DATA_EQ(1u, 1023, Positive, encode(1, 1023, Positive));
  EXPECT_DECIMAL_ENCODED_DATA_EQ(1u, 1023, Negative, encode(1, 1023, Negative));
  EXPECT_TRUE(encode(1, 2000, Positive).isInfinity());
  EXPECT_TRUE(encode(1, 2000, Negative).isInfinity());
  EXPECT_DECIMAL_ENCODED_DATA_EQ(0u, 0, Positive, encode(1, -2000, Positive));
  EXPECT_DECIMAL_ENCODED_DATA_EQ(0u, 0, Negative, encode(1, -2000, Negative));
  EXPECT_DECIMAL_ENCODED_DATA_EQ(
      UINT64_C(99999999999999998), 0, Positive,
      encode(UINT64_C(99999999999999998), 0, Positive));
  EXPECT_DECIMAL_ENCODED_DATA_EQ(
      UINT64_C(99999999999999998), 0, Negative,
      encode(UINT64_C(99999999999999998), 0, Negative));
  EXPECT_DECIMAL_ENCODED_DATA_EQ(
      UINT64_C(99999999999999999), 0, Positive,
      encode(UINT64_C(99999999999999999), 0, Positive));
  EXPECT_DECIMAL_ENCODED_DATA_EQ(
      UINT64_C(99999999999999999), 0, Negative,
      encode(UINT64_C(99999999999999999), 0, Negative));
  EXPECT_DECIMAL_ENCODED_DATA_EQ(
      UINT64_C(100000000000000000), 0, Positive,
      encode(UINT64_C(100000000000000000), 0, Positive));
  EXPECT_DECIMAL_ENCODED_DATA_EQ(
      UINT64_C(100000000000000000), 0, Negative,
      encode(UINT64_C(100000000000000000), 0, Negative));
}

TEST_F(DecimalTest, Division) {
  EXPECT_EQ(encode(0, 0, Positive), Decimal(0) / Decimal(1));
  EXPECT_EQ(encode(2, 0, Negative), Decimal(2) / Decimal(-1));
  EXPECT_EQ(encode(5, -1, Negative), Decimal(-1) / Decimal(2));
  EXPECT_EQ(encode(99, 0, Positive), Decimal(99) / Decimal(1));
  EXPECT_EQ(Decimal(1), Decimal(-50) / Decimal(-50));
  EXPECT_EQ(encode(UINT64_C(33333333333333333), -17, Positive),
            Decimal(1) / Decimal(3));
  EXPECT_EQ(encode(UINT64_C(12345678901234), -1, Positive),
            encode(UINT64_C(12345678901234), 0, Positive) / Decimal(10));
}

TEST_F(DecimalTest, DivisionBigExponent) {
  EXPECT_EQ(encode(1, 1022, Positive),
            encode(1, 1022, Positive) / encode(1, 0, Positive));
  EXPECT_EQ(encode(1, 0, Positive),
            encode(1, 1022, Positive) / encode(1, 1022, Positive));
  EXPECT_EQ(Decimal::infinity(Positive),
            encode(1, 1022, Positive) / encode(1, -1000, Positive));
}

TEST_F(DecimalTest, DivisionSmallExponent) {
  EXPECT_EQ(encode(1, -1022, Positive),
            encode(1, -1022, Positive) / encode(1, 0, Positive));
  EXPECT_EQ(encode(1, 0, Positive),
            encode(1, -1022, Positive) / encode(1, -1022, Positive));
}

TEST_F(DecimalTest, DivisionSpecialValues) {
  const Decimal Infinity(Decimal::infinity(Positive));
  const Decimal MinusInfinity(Decimal::infinity(Negative));
  const Decimal NaN(Decimal::nan());
  const Decimal Zero(Decimal::zero(Positive));
  const Decimal MinusZero(Decimal::zero(Negative));
  const Decimal Ten(10);
  const Decimal MinusTen(-10);

  EXPECT_EQ(NaN, Zero / Zero);
  EXPECT_EQ(NaN, Zero / MinusZero);
  EXPECT_EQ(NaN, MinusZero / Zero);
  EXPECT_EQ(NaN, MinusZero / MinusZero);

  EXPECT_EQ(Infinity, Ten / Zero);
  EXPECT_EQ(MinusInfinity, Ten / MinusZero);
  EXPECT_EQ(MinusInfinity, MinusTen / Zero);
  EXPECT_EQ(Infinity, MinusTen / MinusZero);

  EXPECT_EQ(Infinity, Infinity / Zero);
  EXPECT_EQ(MinusInfinity, Infinity / MinusZero);
  EXPECT_EQ(MinusInfinity, MinusInfinity / Zero);
  EXPECT_EQ(Infinity, MinusInfinity / MinusZero);

  EXPECT_EQ(NaN, Infinity / Infinity);
  EXPECT_EQ(NaN, Infinity / MinusInfinity);
  EXPECT_EQ(NaN, MinusInfinity / Infinity);
  EXPECT_EQ(NaN, MinusInfinity / MinusInfinity);

  EXPECT_EQ(Zero, Ten / Infinity);
  EXPECT_EQ(MinusZero, Ten / MinusInfinity);
  EXPECT_EQ(MinusZero, MinusTen / Infinity);
  EXPECT_EQ(Zero, MinusTen / MinusInfinity);

  EXPECT_EQ(NaN, NaN / NaN);
  EXPECT_EQ(NaN, NaN / Ten);
  EXPECT_EQ(NaN, Ten / NaN);

  EXPECT_EQ(NaN, NaN / Infinity);
  EXPECT_EQ(NaN, NaN / MinusInfinity);
  EXPECT_EQ(NaN, Infinity / NaN);
  EXPECT_EQ(NaN, MinusInfinity / NaN);
}

TEST_F(DecimalTest, EncodedData) {
  EXPECT_EQ(encode(0, 0, Positive), encode(0, 0, Positive));
  EXPECT_EQ(encode(0, 0, Negative), encode(0, 0, Negative));
  EXPECT_EQ(Decimal(1), Decimal(1));
  EXPECT_EQ(encode(1, 0, Negative), encode(1, 0, Negative));
  EXPECT_EQ(Decimal::infinity(Positive), encode(1, 2000, Positive));
  EXPECT_EQ(Decimal::zero(Positive), encode(1, -2000, Positive));
}

TEST_F(DecimalTest, Floor) {
  EXPECT_EQ(Decimal(1), Decimal(1).floor());
  EXPECT_EQ(Decimal(0), encode(1, -10, Positive).floor());
  EXPECT_EQ(Decimal(1), encode(11, -1, Positive).floor());
  EXPECT_EQ(Decimal(1), encode(13, -1, Positive).floor());
  EXPECT_EQ(Decimal(1), encode(15, -1, Positive).floor());
  EXPECT_EQ(Decimal(1), encode(19, -1, Positive).floor());
  EXPECT_EQ(Decimal(1), encode(193332, -5, Positive).floor());
  EXPECT_EQ(Decimal(12), encode(12002, -3, Positive).floor());

  EXPECT_EQ(Decimal(-1), Decimal(-1).floor());
  EXPECT_EQ(Decimal(-1), encode(1, -10, Negative).floor());
  EXPECT_EQ(Decimal(-2), encode(11, -1, Negative).floor());
  EXPECT_EQ(Decimal(-2), encode(13, -1, Negative).floor());
  EXPECT_EQ(Decimal(-2), encode(15, -1, Negative).floor());
  EXPECT_EQ(Decimal(-2), encode(19, -1, Negative).floor());
  EXPECT_EQ(Decimal(-2), encode(193332, -5, Negative).floor());
  EXPECT_EQ(Decimal(-13), encode(12002, -3, Negative).floor());
}

TEST_F(DecimalTest, FloorBigExponent) {
  EXPECT_EQ(encode(1, 1000, Positive), encode(1, 1000, Positive).floor());
  EXPECT_EQ(encode(1, 1000, Negative), encode(1, 1000, Negative).floor());
}

TEST_F(DecimalTest, FloorSmallExponent) {
  EXPECT_EQ(encode(0, 0, Positive), encode(1, -1000, Positive).floor());
  EXPECT_EQ(encode(1, 0, Negative), encode(1, -1000, Negative).floor());
}

TEST_F(DecimalTest, FloorSpecialValues) {
  EXPECT_EQ(Decimal::infinity(Positive), Decimal::infinity(Positive).floor());
  EXPECT_EQ(Decimal::infinity(Negative), Decimal::infinity(Negative).floor());
  EXPECT_EQ(Decimal::nan(), Decimal::nan().floor());
}

TEST_F(DecimalTest, FromDouble) {
  EXPECT_EQ(encode(0, 0, Positive), Decimal::fromDouble(0.0));
  EXPECT_EQ(encode(0, 0, Negative), Decimal::fromDouble(-0.0));
  EXPECT_EQ(encode(1, 0, Positive), Decimal::fromDouble(1));
  EXPECT_EQ(encode(1, 0, Negative), Decimal::fromDouble(-1));
  EXPECT_EQ(encode(123, 0, Positive), Decimal::fromDouble(123));
  EXPECT_EQ(encode(123, 0, Negative), Decimal::fromDouble(-123));
  EXPECT_EQ(encode(1, -1, Positive), Decimal::fromDouble(0.1));
  EXPECT_EQ(encode(1, -1, Negative), Decimal::fromDouble(-0.1));
}

TEST_F(DecimalTest, FromDoubleLimits) {
  EXPECT_EQ(encode(UINT64_C(2220446049250313), -31, Positive),
            Decimal::fromDouble(std::numeric_limits<double>::epsilon()));
  EXPECT_EQ(encode(UINT64_C(2220446049250313), -31, Negative),
            Decimal::fromDouble(-std::numeric_limits<double>::epsilon()));
  EXPECT_EQ(encode(UINT64_C(17976931348623157), 292, Positive),
            Decimal::fromDouble(std::numeric_limits<double>::max()));
  EXPECT_EQ(encode(UINT64_C(17976931348623157), 292, Negative),
            Decimal::fromDouble(-std::numeric_limits<double>::max()));
  EXPECT_EQ(encode(UINT64_C(22250738585072014), -324, Positive),
            Decimal::fromDouble(std::numeric_limits<double>::min()));
  EXPECT_EQ(encode(UINT64_C(22250738585072014), -324, Negative),
            Decimal::fromDouble(-std::numeric_limits<double>::min()));
  EXPECT_TRUE(Decimal::fromDouble(std::numeric_limits<double>::infinity())
                  .isInfinity());
  EXPECT_TRUE(Decimal::fromDouble(-std::numeric_limits<double>::infinity())
                  .isInfinity());
  EXPECT_TRUE(
      Decimal::fromDouble(std::numeric_limits<double>::quiet_NaN()).isNaN());
  EXPECT_TRUE(
      Decimal::fromDouble(-std::numeric_limits<double>::quiet_NaN()).isNaN());
}

TEST_F(DecimalTest, FromInt32) {
  EXPECT_EQ(encode(0, 0, Positive), Decimal(0));
  EXPECT_EQ(encode(1, 0, Positive), Decimal(1));
  EXPECT_EQ(encode(1, 0, Negative), Decimal(-1));
  EXPECT_EQ(encode(100, 0, Positive), Decimal(100));
  EXPECT_EQ(encode(100, 0, Negative), Decimal(-100));
  EXPECT_EQ(encode(0x7FFFFFFF, 0, Positive),
            Decimal(std::numeric_limits<int32_t>::max()));
  EXPECT_EQ(encode(0x80000000u, 0, Negative),
            Decimal(std::numeric_limits<int32_t>::min()));
}

TEST_F(DecimalTest, FromString) {
  EXPECT_EQ(encode(0, 0, Positive), fromString("0"));
  EXPECT_EQ(encode(0, 0, Negative), fromString("-0"));
  EXPECT_EQ(Decimal(1), fromString("1"));
  EXPECT_EQ(encode(1, 0, Negative), fromString("-1"));
  EXPECT_EQ(Decimal(1), fromString("01"));
  EXPECT_EQ(encode(3, 0, Positive), fromString("+3"));
  EXPECT_EQ(encode(0, 3, Positive), fromString("0E3"));
  EXPECT_EQ(encode(5, -1, Positive), fromString(".5"));
  EXPECT_EQ(encode(100, 0, Positive), fromString("100"));
  EXPECT_EQ(encode(100, 0, Negative), fromString("-100"));
  EXPECT_EQ(encode(123, -2, Positive), fromString("1.23"));
  EXPECT_EQ(encode(123, -2, Negative), fromString("-1.23"));
  EXPECT_EQ(encode(123, 8, Positive), fromString("1.23E10"));
  EXPECT_EQ(encode(123, 8, Negative), fromString("-1.23E10"));
  EXPECT_EQ(encode(123, 8, Positive), fromString("1.23E+10"));
  EXPECT_EQ(encode(123, 8, Negative), fromString("-1.23E+10"));
  EXPECT_EQ(encode(123, -12, Positive), fromString("1.23E-10"));
  EXPECT_EQ(encode(123, -12, Negative), fromString("-1.23E-10"));
  EXPECT_EQ(encode(5, -7, Positive), fromString("0.0000005"));
  EXPECT_EQ(encode(0, 0, Positive), fromString("0e9999"));
  EXPECT_EQ(encode(123, -3, Positive), fromString("0.123"));
  EXPECT_EQ(encode(0, -2, Positive), fromString("00.00"));
  EXPECT_EQ(encode(1, 2, Positive), fromString("1E2"));
  EXPECT_EQ(Decimal::infinity(Positive), fromString("1E20000"));
  EXPECT_EQ(Decimal::zero(Positive), fromString("1E-20000"));
  EXPECT_EQ(encode(1000, 1023, Positive), fromString("1E1026"));
  EXPECT_EQ(Decimal::zero(Positive), fromString("1E-1026"));
  EXPECT_EQ(Decimal::infinity(Positive), fromString("1234567890E1036"));

  // 2^1024
  const uint64_t leadingDigitsOf2PowerOf1024 = UINT64_C(17976931348623159);
  EXPECT_EQ(encode(leadingDigitsOf2PowerOf1024, 292, Positive),
            fromString("1797693134862315907729305190789024733617976978942306572"
                       "7343008115773267580550096313270847732240753602112011387"
                       "9871393357658789768814416622492847430639474124377767893"
                       "4248654852763022196012460941194530829520850057688381506"
                       "8234246288147391311054082723716335051068458629823994724"
                       "5938479716304835356329624224137216"));
}

// These strings are look like proper number, but we don't accept them.
TEST_F(DecimalTest, FromStringLikeNumber) {
  EXPECT_EQ(Decimal::nan(), fromString(" 123 "));
  EXPECT_EQ(Decimal::nan(), fromString("1,234"));
}

// fromString doesn't support infinity and NaN.
TEST_F(DecimalTest, FromStringSpecialValues) {
  EXPECT_EQ(Decimal::nan(), fromString("INF"));
  EXPECT_EQ(Decimal::nan(), fromString("Infinity"));
  EXPECT_EQ(Decimal::nan(), fromString("infinity"));
  EXPECT_EQ(Decimal::nan(), fromString("+Infinity"));
  EXPECT_EQ(Decimal::nan(), fromString("+infinity"));
  EXPECT_EQ(Decimal::nan(), fromString("-Infinity"));
  EXPECT_EQ(Decimal::nan(), fromString("-infinity"));
  EXPECT_EQ(Decimal::nan(), fromString("NaN"));
  EXPECT_EQ(Decimal::nan(), fromString("nan"));
  EXPECT_EQ(Decimal::nan(), fromString("+NaN"));
  EXPECT_EQ(Decimal::nan(), fromString("+nan"));
  EXPECT_EQ(Decimal::nan(), fromString("-NaN"));
  EXPECT_EQ(Decimal::nan(), fromString("-nan"));
}

TEST_F(DecimalTest, fromStringTruncated) {
  EXPECT_EQ(Decimal::nan(), fromString("x"));
  EXPECT_EQ(Decimal::nan(), fromString("0."));
  EXPECT_EQ(Decimal::nan(), fromString("1x"));

  EXPECT_EQ(Decimal::nan(), fromString("1Ex"));
  EXPECT_EQ(Decimal::nan(), fromString("1E2x"));
  EXPECT_EQ(Decimal::nan(), fromString("1E+x"));
}

TEST_F(DecimalTest, Multiplication) {
  EXPECT_EQ(encode(0, 0, Positive), Decimal(0) * Decimal(0));
  EXPECT_EQ(encode(2, 0, Negative), Decimal(2) * Decimal(-1));
  EXPECT_EQ(encode(2, 0, Negative), Decimal(-1) * Decimal(2));
  EXPECT_EQ(encode(99, 0, Positive), Decimal(99) * Decimal(1));
  EXPECT_EQ(encode(2500, 0, Positive), Decimal(-50) * Decimal(-50));
  EXPECT_EQ(encode(1, 21, Positive),
            encode(UINT64_C(10000000000), 0, Positive) *
                encode(UINT64_C(100000000000), 0, Positive));
}

TEST_F(DecimalTest, MultiplicationBigExponent) {
  EXPECT_EQ(encode(1, 1022, Positive),
            encode(1, 1022, Positive) * encode(1, 0, Positive));
  EXPECT_EQ(Decimal::infinity(Positive),
            encode(1, 1022, Positive) * encode(1, 1022, Positive));
  EXPECT_EQ(encode(1, 22, Positive),
            encode(1, 1022, Positive) * encode(1, -1000, Positive));
}

TEST_F(DecimalTest, MultiplicationSmallExponent) {
  EXPECT_EQ(encode(1, -1022, Positive),
            encode(1, -1022, Positive) * encode(1, 0, Positive));
  EXPECT_EQ(encode(0, 0, Positive),
            encode(1, -1022, Positive) * encode(1, -1022, Positive));
}

TEST_F(DecimalTest, MultiplicationSpecialValues) {
  const Decimal Infinity(Decimal::infinity(Positive));
  const Decimal MinusInfinity(Decimal::infinity(Negative));
  const Decimal NaN(Decimal::nan());
  const Decimal Ten(10);
  const Decimal MinusTen(-10);
  const Decimal Zero(Decimal::zero(Positive));
  const Decimal MinusZero(Decimal::zero(Negative));

  EXPECT_EQ(Infinity, Infinity * Infinity);
  EXPECT_EQ(MinusInfinity, Infinity * MinusInfinity);
  EXPECT_EQ(MinusInfinity, MinusInfinity * Infinity);
  EXPECT_EQ(Infinity, MinusInfinity * MinusInfinity);

  EXPECT_EQ(NaN, Infinity * Zero);
  EXPECT_EQ(NaN, Zero * MinusInfinity);
  EXPECT_EQ(NaN, MinusInfinity * Zero);
  EXPECT_EQ(NaN, MinusInfinity * Zero);

  EXPECT_EQ(NaN, Infinity * MinusZero);
  EXPECT_EQ(NaN, MinusZero * MinusInfinity);
  EXPECT_EQ(NaN, MinusInfinity * MinusZero);
  EXPECT_EQ(NaN, MinusInfinity * MinusZero);

  EXPECT_EQ(Infinity, Infinity * Ten);
  EXPECT_EQ(Infinity, Ten * Infinity);
  EXPECT_EQ(MinusInfinity, MinusInfinity * Ten);
  EXPECT_EQ(MinusInfinity, Ten * MinusInfinity);

  EXPECT_EQ(MinusInfinity, Infinity * MinusTen);
  EXPECT_EQ(MinusInfinity, MinusTen * Infinity);
  EXPECT_EQ(Infinity, MinusInfinity * MinusTen);
  EXPECT_EQ(Infinity, MinusTen * MinusInfinity);

  EXPECT_EQ(NaN, NaN * NaN);
  EXPECT_EQ(NaN, NaN * Ten);
  EXPECT_EQ(NaN, Ten * NaN);

  EXPECT_EQ(NaN, NaN * Infinity);
  EXPECT_EQ(NaN, NaN * MinusInfinity);
  EXPECT_EQ(NaN, Infinity * NaN);
  EXPECT_EQ(NaN, MinusInfinity * NaN);
}

TEST_F(DecimalTest, Negate) {
  EXPECT_EQ(encode(0, 0, Negative), -encode(0, 0, Positive));
  EXPECT_EQ(encode(0, 0, Positive), -encode(0, 0, Negative));

  EXPECT_EQ(encode(0, 10, Negative), -encode(0, 10, Positive));
  EXPECT_EQ(encode(0, 10, Positive), -encode(0, 10, Negative));

  EXPECT_EQ(encode(0, -10, Negative), -encode(0, -10, Positive));
  EXPECT_EQ(encode(0, -10, Positive), -encode(0, -10, Negative));

  EXPECT_EQ(encode(1, 0, Negative), -encode(1, 0, Positive));
  EXPECT_EQ(encode(1, 0, Positive), -encode(1, 0, Negative));

  EXPECT_EQ(encode(1, 10, Negative), -encode(1, 10, Positive));
  EXPECT_EQ(encode(1, 10, Positive), -encode(1, 10, Negative));

  EXPECT_EQ(encode(1, -10, Negative), -encode(1, -10, Positive));
  EXPECT_EQ(encode(1, -10, Positive), -encode(1, -10, Negative));
}

TEST_F(DecimalTest, NegateBigExponent) {
  EXPECT_EQ(encode(1, 1000, Negative), -encode(1, 1000, Positive));
  EXPECT_EQ(encode(1, 1000, Positive), -encode(1, 1000, Negative));
}

TEST_F(DecimalTest, NegateSmallExponent) {
  EXPECT_EQ(encode(1, -1000, Negative), -encode(1, -1000, Positive));
  EXPECT_EQ(encode(1, -1000, Positive), -encode(1, -1000, Negative));
}

TEST_F(DecimalTest, NegateSpecialValues) {
  EXPECT_EQ(Decimal::infinity(Negative), -Decimal::infinity(Positive));
  EXPECT_EQ(Decimal::infinity(Positive), -Decimal::infinity(Negative));
  EXPECT_EQ(Decimal::nan(), -Decimal::nan());
}

TEST_F(DecimalTest, Predicates) {
  EXPECT_TRUE(Decimal::zero(Positive).isFinite());
  EXPECT_FALSE(Decimal::zero(Positive).isInfinity());
  EXPECT_FALSE(Decimal::zero(Positive).isNaN());
  EXPECT_TRUE(Decimal::zero(Positive).isPositive());
  EXPECT_FALSE(Decimal::zero(Positive).isNegative());
  EXPECT_FALSE(Decimal::zero(Positive).isSpecial());
  EXPECT_TRUE(Decimal::zero(Positive).isZero());

  EXPECT_TRUE(Decimal::zero(Negative).isFinite());
  EXPECT_FALSE(Decimal::zero(Negative).isInfinity());
  EXPECT_FALSE(Decimal::zero(Negative).isNaN());
  EXPECT_FALSE(Decimal::zero(Negative).isPositive());
  EXPECT_TRUE(Decimal::zero(Negative).isNegative());
  EXPECT_FALSE(Decimal::zero(Negative).isSpecial());
  EXPECT_TRUE(Decimal::zero(Negative).isZero());

  EXPECT_TRUE(Decimal(123).isFinite());
  EXPECT_FALSE(Decimal(123).isInfinity());
  EXPECT_FALSE(Decimal(123).isNaN());
  EXPECT_TRUE(Decimal(123).isPositive());
  EXPECT_FALSE(Decimal(123).isNegative());
  EXPECT_FALSE(Decimal(123).isSpecial());
  EXPECT_FALSE(Decimal(123).isZero());

  EXPECT_TRUE(Decimal(-123).isFinite());
  EXPECT_FALSE(Decimal(-123).isInfinity());
  EXPECT_FALSE(Decimal(-123).isNaN());
  EXPECT_FALSE(Decimal(-123).isPositive());
  EXPECT_TRUE(Decimal(-123).isNegative());
  EXPECT_FALSE(Decimal(-123).isSpecial());
  EXPECT_FALSE(Decimal(-123).isZero());
}

TEST_F(DecimalTest, PredicatesSpecialValues) {
  EXPECT_FALSE(Decimal::infinity(Positive).isFinite());
  EXPECT_TRUE(Decimal::infinity(Positive).isInfinity());
  EXPECT_FALSE(Decimal::infinity(Positive).isNaN());
  EXPECT_TRUE(Decimal::infinity(Positive).isPositive());
  EXPECT_FALSE(Decimal::infinity(Positive).isNegative());
  EXPECT_TRUE(Decimal::infinity(Positive).isSpecial());
  EXPECT_FALSE(Decimal::infinity(Positive).isZero());

  EXPECT_FALSE(Decimal::infinity(Negative).isFinite());
  EXPECT_TRUE(Decimal::infinity(Negative).isInfinity());
  EXPECT_FALSE(Decimal::infinity(Negative).isNaN());
  EXPECT_FALSE(Decimal::infinity(Negative).isPositive());
  EXPECT_TRUE(Decimal::infinity(Negative).isNegative());
  EXPECT_TRUE(Decimal::infinity(Negative).isSpecial());
  EXPECT_FALSE(Decimal::infinity(Negative).isZero());

  EXPECT_FALSE(Decimal::nan().isFinite());
  EXPECT_FALSE(Decimal::nan().isInfinity());
  EXPECT_TRUE(Decimal::nan().isNaN());
  EXPECT_TRUE(Decimal::nan().isSpecial());
  EXPECT_FALSE(Decimal::nan().isZero());
}

// tests/fast/forms/number/number-stepup-stepdown-from-renderer
TEST_F(DecimalTest, RealWorldExampleNumberStepUpStepDownFromRenderer) {
  EXPECT_DECIMAL_STREQ("10", stepDown("0", "100", "10", "19", 1));
  EXPECT_DECIMAL_STREQ("90", stepUp("0", "99", "10", "89", 1));
  EXPECT_DECIMAL_STREQ(
      "1", stepUp("0", "1", "0.33333333333333333", "0", 3));  // step=1/3
  EXPECT_DECIMAL_STREQ("0.01", stepUp("0", "0.01", "0.0033333333333333333", "0",
                                      3));  // step=1/300
  EXPECT_DECIMAL_STREQ(
      "1", stepUp("0", "1", "0.003921568627450980", "0", 255));  // step=1/255
  EXPECT_DECIMAL_STREQ("1", stepUp("0", "1", "0.1", "0", 10));
}

TEST_F(DecimalTest, RealWorldExampleNumberStepUpStepDownFromRendererRounding) {
  EXPECT_DECIMAL_STREQ("5.015", stepUp("0", "100", "0.005", "5.005", 2));
  EXPECT_DECIMAL_STREQ("5.06", stepUp("0", "100", "0.005", "5.005", 11));
  EXPECT_DECIMAL_STREQ("5.065", stepUp("0", "100", "0.005", "5.005", 12));

  EXPECT_DECIMAL_STREQ("5.015", stepUp("4", "9", "0.005", "5.005", 2));
  EXPECT_DECIMAL_STREQ("5.06", stepUp("4", "9", "0.005", "5.005", 11));
  EXPECT_DECIMAL_STREQ("5.065", stepUp("4", "9", "0.005", "5.005", 12));
}

TEST_F(DecimalTest, RealWorldExampleRangeStepUpStepDown) {
  EXPECT_DECIMAL_STREQ("1e+38", stepUp("0", "1E38", "1", "1E38", 9));
  EXPECT_DECIMAL_STREQ("1e+38", stepDown("0", "1E38", "1", "1E38", 9));
}

TEST_F(DecimalTest, Remainder) {
  EXPECT_EQ(encode(21, -1, Positive), encode(21, -1, Positive).remainder(3));
  EXPECT_EQ(Decimal(1), Decimal(10).remainder(3));
  EXPECT_EQ(Decimal(1), Decimal(10).remainder(-3));
  EXPECT_EQ(encode(1, 0, Negative), Decimal(-10).remainder(3));
  EXPECT_EQ(Decimal(-1), Decimal(-10).remainder(-3));
  EXPECT_EQ(encode(2, -1, Positive), encode(102, -1, Positive).remainder(1));
  EXPECT_EQ(encode(1, -1, Positive),
            Decimal(10).remainder(encode(3, -1, Positive)));
  EXPECT_EQ(Decimal(1),
            encode(36, -1, Positive).remainder(encode(13, -1, Positive)));
  EXPECT_EQ(encode(1, 86, Positive),
            (encode(1234, 100, Positive).remainder(Decimal(3))));
  EXPECT_EQ(Decimal(500), (Decimal(500).remainder(1000)));
  EXPECT_EQ(Decimal(-500), (Decimal(-500).remainder(1000)));
}

TEST_F(DecimalTest, RemainderBigExponent) {
  EXPECT_EQ(encode(0, 1022, Positive),
            encode(1, 1022, Positive).remainder(encode(1, 0, Positive)));
  EXPECT_EQ(encode(0, 1022, Positive),
            encode(1, 1022, Positive).remainder(encode(1, 1022, Positive)));
  EXPECT_EQ(Decimal::infinity(Positive),
            encode(1, 1022, Positive).remainder(encode(1, -1000, Positive)));
}

TEST_F(DecimalTest, RemainderSmallExponent) {
  EXPECT_EQ(encode(1, -1022, Positive),
            encode(1, -1022, Positive).remainder(encode(1, 0, Positive)));
  EXPECT_EQ(encode(0, -1022, Positive),
            encode(1, -1022, Positive).remainder(encode(1, -1022, Positive)));
}

TEST_F(DecimalTest, RemainderSpecialValues) {
  EXPECT_EQ(Decimal::infinity(Positive),
            Decimal::infinity(Positive).remainder(1));
  EXPECT_EQ(Decimal::infinity(Negative),
            Decimal::infinity(Negative).remainder(1));
  EXPECT_EQ(Decimal::nan(), Decimal::nan().remainder(1));

  EXPECT_EQ(Decimal::infinity(Negative),
            Decimal::infinity(Positive).remainder(-1));
  EXPECT_EQ(Decimal::infinity(Positive),
            Decimal::infinity(Negative).remainder(-1));
  EXPECT_EQ(Decimal::nan(), Decimal::nan().remainder(-1));

  EXPECT_EQ(Decimal::infinity(Positive),
            Decimal::infinity(Positive).remainder(3));
  EXPECT_EQ(Decimal::infinity(Negative),
            Decimal::infinity(Negative).remainder(3));
  EXPECT_EQ(Decimal::nan(), Decimal::nan().remainder(3));

  EXPECT_EQ(Decimal::infinity(Negative),
            Decimal::infinity(Positive).remainder(-1));
  EXPECT_EQ(Decimal::infinity(Positive),
            Decimal::infinity(Negative).remainder(-1));
  EXPECT_EQ(Decimal::nan(), Decimal::nan().remainder(-1));

  EXPECT_EQ(Decimal::nan(), Decimal(1).remainder(Decimal::infinity(Positive)));
  EXPECT_EQ(Decimal::nan(), Decimal(1).remainder(Decimal::infinity(Negative)));
  EXPECT_EQ(Decimal::nan(), Decimal(1).remainder(Decimal::nan()));
}

TEST_F(DecimalTest, Round) {
  EXPECT_EQ(Decimal(1), (Decimal(9) / Decimal(10)).round());
  EXPECT_EQ(Decimal(25), (Decimal(5) / fromString("0.200")).round());
  EXPECT_EQ(Decimal(3), (Decimal(5) / Decimal(2)).round());
  EXPECT_EQ(Decimal(1), (Decimal(2) / Decimal(3)).round());
  EXPECT_EQ(Decimal(3), (Decimal(10) / Decimal(3)).round());
  EXPECT_EQ(Decimal(3), (Decimal(1) / fromString("0.3")).round());
  EXPECT_EQ(Decimal(10), (Decimal(1) / fromString("0.1")).round());
  EXPECT_EQ(Decimal(5), (Decimal(1) / fromString("0.2")).round());
  EXPECT_EQ(Decimal(10), (fromString("10.2") / 1).round());
  EXPECT_EQ(encode(1234, 100, Positive), encode(1234, 100, Positive).round());

  EXPECT_EQ(Decimal(2), encode(190002, -5, Positive).round());
  EXPECT_EQ(Decimal(2), encode(150002, -5, Positive).round());
  EXPECT_EQ(Decimal(2), encode(150000, -5, Positive).round());
  EXPECT_EQ(Decimal(12), encode(12492, -3, Positive).round());
  EXPECT_EQ(Decimal(13), encode(12502, -3, Positive).round());

  EXPECT_EQ(Decimal(-2), encode(190002, -5, Negative).round());
  EXPECT_EQ(Decimal(-2), encode(150002, -5, Negative).round());
  EXPECT_EQ(Decimal(-2), encode(150000, -5, Negative).round());
  EXPECT_EQ(Decimal(-12), encode(12492, -3, Negative).round());
  EXPECT_EQ(Decimal(-13), encode(12502, -3, Negative).round());
}

TEST_F(DecimalTest, RoundSpecialValues) {
  EXPECT_EQ(Decimal::infinity(Positive), Decimal::infinity(Positive).round());
  EXPECT_EQ(Decimal::infinity(Negative), Decimal::infinity(Negative).round());
  EXPECT_EQ(Decimal::nan(), Decimal::nan().round());
}

TEST_F(DecimalTest, Subtract) {
  EXPECT_EQ(encode(0, 0, Positive), Decimal(0) - Decimal(0));
  EXPECT_EQ(encode(3, 0, Positive), Decimal(2) - Decimal(-1));
  EXPECT_EQ(encode(3, 0, Negative), Decimal(-1) - Decimal(2));
  EXPECT_EQ(encode(98, 0, Positive), Decimal(99) - Decimal(1));
  EXPECT_EQ(encode(0, 0, Positive), Decimal(-50) - Decimal(-50));
  EXPECT_EQ(encode(UINT64_C(1000000000000000), 35, Positive),
            encode(1, 50, Positive) - Decimal(1));
  EXPECT_EQ(encode(UINT64_C(1000000000000000), 35, Negative),
            Decimal(1) - encode(1, 50, Positive));
}

TEST_F(DecimalTest, SubtractBigExponent) {
  EXPECT_EQ(encode(1, 1022, Positive),
            encode(1, 1022, Positive) - encode(1, 0, Positive));
  EXPECT_EQ(encode(0, 0, Positive),
            encode(1, 1022, Positive) - encode(1, 1022, Positive));
  EXPECT_EQ(encode(1, 1022, Positive),
            encode(1, 1022, Positive) + encode(1, -1000, Positive));
}

TEST_F(DecimalTest, SubtractSmallExponent) {
  EXPECT_EQ(encode(UINT64_C(10000000000000000), -16, Negative),
            encode(1, -1022, Positive) - encode(1, 0, Positive));
  EXPECT_EQ(encode(0, 0, Positive),
            encode(1, -1022, Positive) - encode(1, -1022, Positive));
}

TEST_F(DecimalTest, SubtractSpecialValues) {
  const Decimal Infinity(Decimal::infinity(Positive));
  const Decimal MinusInfinity(Decimal::infinity(Negative));
  const Decimal NaN(Decimal::nan());
  const Decimal Ten(10);

  EXPECT_EQ(NaN, Infinity - Infinity);
  EXPECT_EQ(Infinity, Infinity - MinusInfinity);
  EXPECT_EQ(MinusInfinity, MinusInfinity - Infinity);
  EXPECT_EQ(NaN, MinusInfinity - MinusInfinity);

  EXPECT_EQ(Infinity, Infinity - Ten);
  EXPECT_EQ(MinusInfinity, Ten - Infinity);
  EXPECT_EQ(MinusInfinity, MinusInfinity - Ten);
  EXPECT_EQ(Infinity, Ten - MinusInfinity);

  EXPECT_EQ(NaN, NaN - NaN);
  EXPECT_EQ(NaN, NaN - Ten);
  EXPECT_EQ(NaN, Ten - NaN);

  EXPECT_EQ(NaN, NaN - Infinity);
  EXPECT_EQ(NaN, NaN - MinusInfinity);
  EXPECT_EQ(NaN, Infinity - NaN);
  EXPECT_EQ(NaN, MinusInfinity - NaN);
}

TEST_F(DecimalTest, ToDouble) {
  EXPECT_EQ(0.0, encode(0, 0, Positive).toDouble());
  EXPECT_EQ(-0.0, encode(0, 0, Negative).toDouble());

  EXPECT_EQ(1.0, encode(1, 0, Positive).toDouble());
  EXPECT_EQ(-1.0, encode(1, 0, Negative).toDouble());

  EXPECT_EQ(0.1, encode(1, -1, Positive).toDouble());
  EXPECT_EQ(-0.1, encode(1, -1, Negative).toDouble());
  EXPECT_EQ(0.3, encode(3, -1, Positive).toDouble());
  EXPECT_EQ(-0.3, encode(3, -1, Negative).toDouble());
  EXPECT_EQ(0.6, encode(6, -1, Positive).toDouble());
  EXPECT_EQ(-0.6, encode(6, -1, Negative).toDouble());
  EXPECT_EQ(0.7, encode(7, -1, Positive).toDouble());
  EXPECT_EQ(-0.7, encode(7, -1, Negative).toDouble());

  EXPECT_EQ(0.01, encode(1, -2, Positive).toDouble());
  EXPECT_EQ(0.001, encode(1, -3, Positive).toDouble());
  EXPECT_EQ(0.0001, encode(1, -4, Positive).toDouble());
  EXPECT_EQ(0.00001, encode(1, -5, Positive).toDouble());

  EXPECT_EQ(1e+308, encode(1, 308, Positive).toDouble());
  EXPECT_EQ(1e-307, encode(1, -307, Positive).toDouble());

  EXPECT_TRUE(std::isinf(encode(1, 1000, Positive).toDouble()));
  EXPECT_EQ(0.0, encode(1, -1000, Positive).toDouble());
}

TEST_F(DecimalTest, ToDoubleSpecialValues) {
  EXPECT_TRUE(std::isinf(Decimal::infinity(Decimal::Positive).toDouble()));
  EXPECT_TRUE(std::isinf(Decimal::infinity(Decimal::Negative).toDouble()));
  EXPECT_TRUE(std::isnan(Decimal::nan().toDouble()));
}

TEST_F(DecimalTest, ToString) {
  EXPECT_DECIMAL_STREQ("0", Decimal::zero(Positive));
  EXPECT_DECIMAL_STREQ("-0", Decimal::zero(Negative));
  EXPECT_DECIMAL_STREQ("1", Decimal(1));
  EXPECT_DECIMAL_STREQ("-1", Decimal(-1));
  EXPECT_DECIMAL_STREQ("1234567", Decimal(1234567));
  EXPECT_DECIMAL_STREQ("-1234567", Decimal(-1234567));
  EXPECT_DECIMAL_STREQ("0.5", encode(5, -1, Positive));
  EXPECT_DECIMAL_STREQ("-0.5", encode(5, -1, Negative));
  EXPECT_DECIMAL_STREQ("12.345", encode(12345, -3, Positive));
  EXPECT_DECIMAL_STREQ("-12.345", encode(12345, -3, Negative));
  EXPECT_DECIMAL_STREQ("0.12345", encode(12345, -5, Positive));
  EXPECT_DECIMAL_STREQ("-0.12345", encode(12345, -5, Negative));
  EXPECT_DECIMAL_STREQ("50", encode(50, 0, Positive));
  EXPECT_DECIMAL_STREQ("-50", encode(50, 0, Negative));
  EXPECT_DECIMAL_STREQ("5e+1", encode(5, 1, Positive));
  EXPECT_DECIMAL_STREQ("-5e+1", encode(5, 1, Negative));
  EXPECT_DECIMAL_STREQ("5.678e+103", encode(5678, 100, Positive));
  EXPECT_DECIMAL_STREQ("-5.678e+103", encode(5678, 100, Negative));
  EXPECT_DECIMAL_STREQ("5.678e-97", encode(5678, -100, Positive));
  EXPECT_DECIMAL_STREQ("-5.678e-97", encode(5678, -100, Negative));
  EXPECT_DECIMAL_STREQ("8639999913600001",
                       encode(UINT64_C(8639999913600001), 0, Positive));
  EXPECT_DECIMAL_STREQ(
      "9007199254740991",
      encode((static_cast<uint64_t>(1) << DBL_MANT_DIG) - 1, 0, Positive));
  EXPECT_DECIMAL_STREQ("99999999999999999",
                       encode(UINT64_C(99999999999999999), 0, Positive));
  EXPECT_DECIMAL_STREQ("9.9999999999999999e+17",
                       encode(UINT64_C(99999999999999999), 1, Positive));
  EXPECT_DECIMAL_STREQ("9.9999999999999999e+18",
                       encode(UINT64_C(99999999999999999), 2, Positive));
  EXPECT_DECIMAL_STREQ("1e+16",
                       encode(UINT64_C(99999999999999999), -1, Positive));
  EXPECT_DECIMAL_STREQ("1000000000000000",
                       encode(UINT64_C(99999999999999999), -2, Positive));
  EXPECT_DECIMAL_STREQ("1", encode(UINT64_C(99999999999999999), -17, Positive));
  EXPECT_DECIMAL_STREQ("0.001",
                       encode(UINT64_C(99999999999999999), -20, Positive));
  EXPECT_DECIMAL_STREQ("1e-83",
                       encode(UINT64_C(99999999999999999), -100, Positive));
}

TEST_F(DecimalTest, ToStringSpecialValues) {
  EXPECT_DECIMAL_STREQ("Infinity", Decimal::infinity(Positive));
  EXPECT_DECIMAL_STREQ("-Infinity", Decimal::infinity(Negative));
  EXPECT_DECIMAL_STREQ("NaN", Decimal::nan());
}
