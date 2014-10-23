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
#include "core/css/CSSCalculationValue.h"

#include "core/css/CSSPrimitiveValue.h"
#include "core/css/CSSToLengthConversionData.h"
#include "core/css/StylePropertySet.h"
#include "core/rendering/style/RenderStyle.h"
#include "core/rendering/style/StyleInheritedData.h"

#include <gtest/gtest.h>


namespace blink {

void PrintTo(const CSSLengthArray& lengthArray, ::std::ostream* os)
{
    for (size_t i = 0; i < CSSPrimitiveValue::LengthUnitTypeCount; ++i)
        *os << lengthArray.at(i) << ' ';
}

}

using namespace blink;

namespace {

void testAccumulatePixelsAndPercent(const CSSToLengthConversionData& conversionData, PassRefPtrWillBeRawPtr<CSSCalcExpressionNode> expression, float expectedPixels, float expectedPercent)
{
    PixelsAndPercent value(0, 0);
    expression->accumulatePixelsAndPercent(conversionData, value);
    EXPECT_EQ(expectedPixels, value.pixels);
    EXPECT_EQ(expectedPercent, value.percent);
}

void initLengthArray(CSSLengthArray& lengthArray)
{
    lengthArray.resize(CSSPrimitiveValue::LengthUnitTypeCount);
    for (size_t i = 0; i < CSSPrimitiveValue::LengthUnitTypeCount; ++i)
        lengthArray.at(i) = 0;
}

CSSLengthArray& setLengthArray(CSSLengthArray& lengthArray, String text)
{
    initLengthArray(lengthArray);
    RefPtrWillBeRawPtr<MutableStylePropertySet> propertySet = MutableStylePropertySet::create();
    propertySet->setProperty(CSSPropertyLeft, text);
    toCSSPrimitiveValue(propertySet->getPropertyCSSValue(CSSPropertyLeft).get())->accumulateLengthArray(lengthArray);
    return lengthArray;
}

bool lengthArraysEqual(CSSLengthArray& a, CSSLengthArray& b)
{
    for (size_t i = 0; i < CSSPrimitiveValue::LengthUnitTypeCount; ++i) {
        if (a.at(i) != b.at(i))
            return false;
    }
    return true;
}

TEST(CSSCalculationValue, AccumulatePixelsAndPercent)
{
    RefPtr<RenderStyle> style = RenderStyle::createDefaultStyle();
    style->setEffectiveZoom(5);
    CSSToLengthConversionData conversionData(style.get(), style.get(), 0);

    testAccumulatePixelsAndPercent(conversionData,
        CSSCalcValue::createExpressionNode(CSSPrimitiveValue::create(10, CSSPrimitiveValue::CSS_PX), true),
        50, 0);

    testAccumulatePixelsAndPercent(conversionData,
        CSSCalcValue::createExpressionNode(
            CSSCalcValue::createExpressionNode(CSSPrimitiveValue::create(10, CSSPrimitiveValue::CSS_PX), true),
            CSSCalcValue::createExpressionNode(CSSPrimitiveValue::create(20, CSSPrimitiveValue::CSS_PX), true),
            CalcAdd),
        150, 0);

    testAccumulatePixelsAndPercent(conversionData,
        CSSCalcValue::createExpressionNode(
            CSSCalcValue::createExpressionNode(CSSPrimitiveValue::create(1, CSSPrimitiveValue::CSS_IN), true),
            CSSCalcValue::createExpressionNode(CSSPrimitiveValue::create(2, CSSPrimitiveValue::CSS_NUMBER), true),
            CalcMultiply),
        960, 0);

    testAccumulatePixelsAndPercent(conversionData,
        CSSCalcValue::createExpressionNode(
            CSSCalcValue::createExpressionNode(
                CSSCalcValue::createExpressionNode(CSSPrimitiveValue::create(50, CSSPrimitiveValue::CSS_PX), true),
                CSSCalcValue::createExpressionNode(CSSPrimitiveValue::create(0.25, CSSPrimitiveValue::CSS_NUMBER), false),
                CalcMultiply),
            CSSCalcValue::createExpressionNode(
                CSSCalcValue::createExpressionNode(CSSPrimitiveValue::create(20, CSSPrimitiveValue::CSS_PX), true),
                CSSCalcValue::createExpressionNode(CSSPrimitiveValue::create(40, CSSPrimitiveValue::CSS_PERCENTAGE), false),
                CalcSubtract),
            CalcSubtract),
        -37.5, 40);
}

TEST(CSSCalculationValue, RefCount)
{
    RefPtr<CalculationValue> calc = CalculationValue::create(PixelsAndPercent(1, 2), ValueRangeAll);
    Length lengthA(calc);
    EXPECT_EQ(calc->refCount(), 2);

    Length lengthB;
    lengthB = lengthA;
    EXPECT_EQ(calc->refCount(), 3);

    Length lengthC(calc);
    lengthC = lengthA;
    EXPECT_EQ(calc->refCount(), 4);

    Length lengthD(CalculationValue::create(PixelsAndPercent(1, 2), ValueRangeAll));
    lengthD = lengthA;
    EXPECT_EQ(calc->refCount(), 5);
}

TEST(CSSCalculationValue, RefCountLeak)
{
    RefPtr<CalculationValue> calc = CalculationValue::create(PixelsAndPercent(1, 2), ValueRangeAll);
    Length lengthA(calc);

    Length lengthB = lengthA;
    for (int i = 0; i < 100; ++i)
        lengthB = lengthA;
    EXPECT_EQ(calc->refCount(), 3);

    Length lengthC(lengthA);
    for (int i = 0; i < 100; ++i)
        lengthC = lengthA;
    EXPECT_EQ(calc->refCount(), 4);

    Length lengthD(calc);
    for (int i = 0; i < 100; ++i)
        lengthD = lengthA;
    EXPECT_EQ(calc->refCount(), 5);

    lengthD = Length();
    EXPECT_EQ(calc->refCount(), 4);
}

TEST(CSSCalculationValue, AddToLengthUnitValues)
{
    CSSLengthArray expectation, actual;
    initLengthArray(expectation);
    EXPECT_TRUE(lengthArraysEqual(expectation, setLengthArray(actual, "0")));

    expectation.at(CSSPrimitiveValue::UnitTypePixels) = 10;
    EXPECT_TRUE(lengthArraysEqual(expectation, setLengthArray(actual, "10px")));

    expectation.at(CSSPrimitiveValue::UnitTypePixels) = 0;
    expectation.at(CSSPrimitiveValue::UnitTypePercentage) = 20;
    EXPECT_TRUE(lengthArraysEqual(expectation, setLengthArray(actual, "20%%")));

    expectation.at(CSSPrimitiveValue::UnitTypePixels) = 30;
    expectation.at(CSSPrimitiveValue::UnitTypePercentage) = -40;
    EXPECT_TRUE(lengthArraysEqual(expectation, setLengthArray(actual, "calc(30px - 40%%)")));

    expectation.at(CSSPrimitiveValue::UnitTypePixels) = 90;
    expectation.at(CSSPrimitiveValue::UnitTypePercentage) = 10;
    EXPECT_TRUE(lengthArraysEqual(expectation, setLengthArray(actual, "calc(1in + 10%% - 6px)")));

    expectation.at(CSSPrimitiveValue::UnitTypePixels) = 15;
    expectation.at(CSSPrimitiveValue::UnitTypeFontSize) = 20;
    expectation.at(CSSPrimitiveValue::UnitTypePercentage) = -40;
    EXPECT_TRUE(lengthArraysEqual(expectation, setLengthArray(actual, "calc((1 * 2) * (5px + 20em / 2) - 80%% / (3 - 1) + 5px)")));
}

}
