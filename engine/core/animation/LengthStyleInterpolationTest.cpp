// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/animation/LengthStyleInterpolation.h"

#include "core/css/CSSPrimitiveValue.h"
#include "core/css/StylePropertySet.h"

#include <gtest/gtest.h>

namespace blink {

class AnimationLengthStyleInterpolationTest : public ::testing::Test {
protected:
    static PassOwnPtrWillBeRawPtr<InterpolableValue> lengthToInterpolableValue(CSSValue* value)
    {
        return LengthStyleInterpolation::lengthToInterpolableValue(value);
    }

    static PassRefPtrWillBeRawPtr<CSSValue> interpolableValueToLength(InterpolableValue* value, ValueRange range)
    {
        return LengthStyleInterpolation::interpolableValueToLength(value, range);
    }

    static PassRefPtrWillBeRawPtr<CSSValue> roundTrip(PassRefPtrWillBeRawPtr<CSSValue> value)
    {
        return interpolableValueToLength(lengthToInterpolableValue(value.get()).get(), ValueRangeAll);
    }

    static void testPrimitiveValue(RefPtrWillBeRawPtr<CSSValue> value, double doubleValue, CSSPrimitiveValue::UnitType unitType)
    {
        EXPECT_TRUE(value->isPrimitiveValue());
        EXPECT_EQ(doubleValue, toCSSPrimitiveValue(value.get())->getDoubleValue());
        EXPECT_EQ(unitType, toCSSPrimitiveValue(value.get())->primitiveType());
    }

    static PassOwnPtrWillBeRawPtr<InterpolableList> createInterpolableLength(double a, double b, double c, double d, double e, double f, double g, double h, double i, double j)
    {
        OwnPtrWillBeRawPtr<InterpolableList> list = InterpolableList::create(10);
        list->set(0, InterpolableNumber::create(a));
        list->set(1, InterpolableNumber::create(b));
        list->set(2, InterpolableNumber::create(c));
        list->set(3, InterpolableNumber::create(d));
        list->set(4, InterpolableNumber::create(e));
        list->set(5, InterpolableNumber::create(f));
        list->set(6, InterpolableNumber::create(g));
        list->set(7, InterpolableNumber::create(h));
        list->set(8, InterpolableNumber::create(i));
        list->set(9, InterpolableNumber::create(j));

        return list.release();
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
};

TEST_F(AnimationLengthStyleInterpolationTest, ZeroLength)
{
    RefPtrWillBeRawPtr<CSSValue> value = roundTrip(CSSPrimitiveValue::create(0, CSSPrimitiveValue::CSS_PX));
    testPrimitiveValue(value, 0, CSSPrimitiveValue::CSS_PX);

    value = roundTrip(CSSPrimitiveValue::create(0, CSSPrimitiveValue::CSS_EMS));
    testPrimitiveValue(value, 0, CSSPrimitiveValue::CSS_PX);
}

TEST_F(AnimationLengthStyleInterpolationTest, SingleUnit)
{
    RefPtrWillBeRawPtr<CSSValue> value = roundTrip(CSSPrimitiveValue::create(10, CSSPrimitiveValue::CSS_PX));
    testPrimitiveValue(value, 10, CSSPrimitiveValue::CSS_PX);

    value = roundTrip(CSSPrimitiveValue::create(30, CSSPrimitiveValue::CSS_PERCENTAGE));
    testPrimitiveValue(value, 30, CSSPrimitiveValue::CSS_PERCENTAGE);

    value = roundTrip(CSSPrimitiveValue::create(-10, CSSPrimitiveValue::CSS_EMS));
    testPrimitiveValue(value, -10, CSSPrimitiveValue::CSS_EMS);
}

TEST_F(AnimationLengthStyleInterpolationTest, SingleClampedUnit)
{
    RefPtrWillBeRawPtr<CSSValue> value = CSSPrimitiveValue::create(-10, CSSPrimitiveValue::CSS_EMS);
    value = interpolableValueToLength(lengthToInterpolableValue(value.get()).get(), ValueRangeNonNegative);
    testPrimitiveValue(value, 0, CSSPrimitiveValue::CSS_EMS);
}

TEST_F(AnimationLengthStyleInterpolationTest, MultipleUnits)
{
    CSSLengthArray actual, expectation;
    initLengthArray(expectation);
    OwnPtrWillBeRawPtr<InterpolableList> list = createInterpolableLength(0, 10, 0, 10, 0, 10, 0, 10, 0, 10);
    toCSSPrimitiveValue(interpolableValueToLength(list.get(), ValueRangeAll).get())->accumulateLengthArray(expectation);
    EXPECT_TRUE(lengthArraysEqual(expectation, setLengthArray(actual, "calc(10%% + 10ex + 10ch + 10vh + 10vmax)")));
}

}
