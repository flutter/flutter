// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/css/parser/BisonCSSParser.h"

#include "core/css/CSSTimingFunctionValue.h"
#include "core/css/MediaList.h"
#include "core/css/StyleRule.h"
#include "platform/animation/TimingFunction.h"
#include "wtf/dtoa/utils.h"

#include <gtest/gtest.h>

namespace blink {

TEST(BisonCSSParserTest, ParseAnimationTimingFunctionValue)
{
    RefPtrWillBeRawPtr<CSSValue> timingFunctionValue;
    timingFunctionValue = BisonCSSParser::parseAnimationTimingFunctionValue("ease");
    EXPECT_EQ(CSSValueEase, toCSSPrimitiveValue(timingFunctionValue.get())->getValueID());

    timingFunctionValue = BisonCSSParser::parseAnimationTimingFunctionValue("linear");
    EXPECT_EQ(CSSValueLinear, toCSSPrimitiveValue(timingFunctionValue.get())->getValueID());

    timingFunctionValue = BisonCSSParser::parseAnimationTimingFunctionValue("ease-in");
    EXPECT_EQ(CSSValueEaseIn, toCSSPrimitiveValue(timingFunctionValue.get())->getValueID());

    timingFunctionValue = BisonCSSParser::parseAnimationTimingFunctionValue("ease-out");
    EXPECT_EQ(CSSValueEaseOut, toCSSPrimitiveValue(timingFunctionValue.get())->getValueID());

    timingFunctionValue = BisonCSSParser::parseAnimationTimingFunctionValue("ease-in-out");
    EXPECT_EQ(CSSValueEaseInOut, toCSSPrimitiveValue(timingFunctionValue.get())->getValueID());

    timingFunctionValue = BisonCSSParser::parseAnimationTimingFunctionValue("step-start");
    EXPECT_EQ(CSSValueStepStart, toCSSPrimitiveValue(timingFunctionValue.get())->getValueID());

    timingFunctionValue = BisonCSSParser::parseAnimationTimingFunctionValue("step-middle");
    EXPECT_EQ(CSSValueStepMiddle, toCSSPrimitiveValue(timingFunctionValue.get())->getValueID());

    timingFunctionValue = BisonCSSParser::parseAnimationTimingFunctionValue("step-end");
    EXPECT_EQ(CSSValueStepEnd, toCSSPrimitiveValue(timingFunctionValue.get())->getValueID());

    timingFunctionValue = BisonCSSParser::parseAnimationTimingFunctionValue("steps(3, start)");
    EXPECT_TRUE(CSSStepsTimingFunctionValue::create(3, StepsTimingFunction::StepAtStart)->equals(toCSSStepsTimingFunctionValue(*timingFunctionValue.get())));

    timingFunctionValue = BisonCSSParser::parseAnimationTimingFunctionValue("steps(3, middle)");
    EXPECT_TRUE(CSSStepsTimingFunctionValue::create(3, StepsTimingFunction::StepAtMiddle)->equals(toCSSStepsTimingFunctionValue(*timingFunctionValue.get())));

    timingFunctionValue = BisonCSSParser::parseAnimationTimingFunctionValue("steps(3, end)");
    EXPECT_TRUE(CSSStepsTimingFunctionValue::create(3, StepsTimingFunction::StepAtEnd)->equals(toCSSStepsTimingFunctionValue(*timingFunctionValue.get())));

    timingFunctionValue = BisonCSSParser::parseAnimationTimingFunctionValue("steps(3, nowhere)");
    EXPECT_EQ(0, timingFunctionValue.get());

    timingFunctionValue = BisonCSSParser::parseAnimationTimingFunctionValue("steps(-3, end)");
    EXPECT_EQ(0, timingFunctionValue.get());

    timingFunctionValue = BisonCSSParser::parseAnimationTimingFunctionValue("steps(3)");
    EXPECT_TRUE(CSSStepsTimingFunctionValue::create(3, StepsTimingFunction::StepAtEnd)->equals(toCSSStepsTimingFunctionValue(*timingFunctionValue.get())));

    timingFunctionValue = BisonCSSParser::parseAnimationTimingFunctionValue("cubic-bezier(0.1, 5, 0.23, 0)");
    EXPECT_TRUE(CSSCubicBezierTimingFunctionValue::create(0.1, 5, 0.23, 0)->equals(toCSSCubicBezierTimingFunctionValue(*timingFunctionValue.get())));

    timingFunctionValue = BisonCSSParser::parseAnimationTimingFunctionValue("cubic-bezier(0.1, 0, 4, 0.4)");
    EXPECT_EQ(0, timingFunctionValue.get());
}

static void testMediaQuery(const char* expected, MediaQuerySet& querySet)
{
    const WillBeHeapVector<OwnPtrWillBeMember<MediaQuery> >& queryVector = querySet.queryVector();
    size_t queryVectorSize = queryVector.size();
    StringBuilder output;

    for (size_t i = 0; i < queryVectorSize; ) {
        String queryText = queryVector[i]->cssText();
        output.append(queryText);
        ++i;
        if (i >= queryVectorSize)
            break;
        output.appendLiteral(", ");
    }
    ASSERT_STREQ(expected, output.toString().ascii().data());
}

TEST(BisonCSSParserTest, MediaQuery)
{
    struct {
        const char* input;
        const char* output;
    } testCases[] = {
        {"@media s} {}", "not all"},
        {"@media } {}", "not all"},
        {"@media tv {}", "tv"},
        {"@media tv, screen {}", "tv, screen"},
        {"@media s}, tv {}", "not all, tv"},
        {"@media tv, screen and (}) {}", "tv, not all"},
    };

    BisonCSSParser parser(strictCSSParserContext());

    for (unsigned i = 0; i < ARRAY_SIZE(testCases); ++i) {
        RefPtrWillBeRawPtr<StyleRuleBase> rule = parser.parseRule(nullptr, String(testCases[i].input));

        EXPECT_TRUE(rule->isMediaRule());
        testMediaQuery(testCases[i].output, *static_cast<StyleRuleMedia*>(rule.get())->mediaQueries());
    }
}

} // namespace blink
