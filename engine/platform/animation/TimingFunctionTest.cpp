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
#include "platform/animation/TimingFunction.h"

#include "wtf/text/WTFString.h"
#include <gmock/gmock.h>
#include <gtest/gtest.h>
#include <sstream>
#include <string>

// Macro is only used to allow the use of streams.
// Can be removed if a pretty failure message isn't needed.
#define EXPECT_NE_WITH_MESSAGE(a, b) \
    EXPECT_NE(*a.second, *b.second) \
        << a.first \
        << " (" << a.second->toString().latin1().data() << ")" \
        << " ==  " \
        << b.first \
        << " (" << b.second->toString().latin1().data() << ")" \
        << "\n";

namespace blink {

namespace {

class TimingFunctionTest : public ::testing::Test {
public:
    void notEqualHelperLoop(Vector<std::pair<std::string, RefPtr<TimingFunction> > >& v)
    {
        for (size_t i = 0; i < v.size(); ++i) {
            for (size_t j = 0; j < v.size(); ++j) {
                if (i == j)
                    continue;
                EXPECT_NE_WITH_MESSAGE(v[i], v[j]);
            }
        }
    }
};

TEST_F(TimingFunctionTest, LinearToString)
{
    RefPtr<TimingFunction> linearTiming = LinearTimingFunction::shared();
    EXPECT_EQ(linearTiming->toString(), "linear");
}

TEST_F(TimingFunctionTest, CubicToString)
{
    RefPtr<TimingFunction> cubicEaseTiming = CubicBezierTimingFunction::preset(CubicBezierTimingFunction::Ease);
    EXPECT_EQ("ease", cubicEaseTiming->toString());
    RefPtr<TimingFunction> cubicEaseInTiming = CubicBezierTimingFunction::preset(CubicBezierTimingFunction::EaseIn);
    EXPECT_EQ("ease-in", cubicEaseInTiming->toString());
    RefPtr<TimingFunction> cubicEaseOutTiming = CubicBezierTimingFunction::preset(CubicBezierTimingFunction::EaseOut);
    EXPECT_EQ("ease-out", cubicEaseOutTiming->toString());
    RefPtr<TimingFunction> cubicEaseInOutTiming = CubicBezierTimingFunction::preset(CubicBezierTimingFunction::EaseInOut);
    EXPECT_EQ("ease-in-out", cubicEaseInOutTiming->toString());

    RefPtr<TimingFunction> cubicCustomTiming = CubicBezierTimingFunction::create(0.17, 0.67, 1, -1.73);
    EXPECT_EQ("cubic-bezier(0.17, 0.67, 1, -1.73)", cubicCustomTiming->toString());
}

TEST_F(TimingFunctionTest, StepToString)
{
    RefPtr<TimingFunction> stepTimingStart = StepsTimingFunction::preset(StepsTimingFunction::Start);
    EXPECT_EQ("step-start", stepTimingStart->toString());

    RefPtr<TimingFunction> stepTimingMiddle = StepsTimingFunction::preset(StepsTimingFunction::Middle);
    EXPECT_EQ("step-middle", stepTimingMiddle->toString());

    RefPtr<TimingFunction> stepTimingEnd = StepsTimingFunction::preset(StepsTimingFunction::End);
    EXPECT_EQ("step-end", stepTimingEnd->toString());

    RefPtr<TimingFunction> stepTimingCustomStart = StepsTimingFunction::create(3, StepsTimingFunction::StepAtStart);
    EXPECT_EQ("steps(3, start)", stepTimingCustomStart->toString());

    RefPtr<TimingFunction> stepTimingCustomMiddle = StepsTimingFunction::create(4, StepsTimingFunction::StepAtMiddle);
    EXPECT_EQ("steps(4, middle)", stepTimingCustomMiddle->toString());

    RefPtr<TimingFunction> stepTimingCustomEnd = StepsTimingFunction::create(5, StepsTimingFunction::StepAtEnd);
    EXPECT_EQ("steps(5, end)", stepTimingCustomEnd->toString());
}

TEST_F(TimingFunctionTest, BaseOperatorEq)
{
    RefPtr<TimingFunction> linearTiming = LinearTimingFunction::shared();
    RefPtr<TimingFunction> cubicTiming1 = CubicBezierTimingFunction::preset(CubicBezierTimingFunction::EaseIn);
    RefPtr<TimingFunction> cubicTiming2 = CubicBezierTimingFunction::create(0.17, 0.67, 1, -1.73);
    RefPtr<TimingFunction> stepsTiming1 = StepsTimingFunction::preset(StepsTimingFunction::End);
    RefPtr<TimingFunction> stepsTiming2 = StepsTimingFunction::create(5, StepsTimingFunction::StepAtStart);

    Vector<std::pair<std::string, RefPtr<TimingFunction> > > v;
    v.append(std::make_pair("linearTiming", linearTiming));
    v.append(std::make_pair("cubicTiming1", cubicTiming1));
    v.append(std::make_pair("cubicTiming2", cubicTiming2));
    v.append(std::make_pair("stepsTiming1", stepsTiming1));
    v.append(std::make_pair("stepsTiming2", stepsTiming2));
    notEqualHelperLoop(v);
}

TEST_F(TimingFunctionTest, LinearOperatorEq)
{
    RefPtr<TimingFunction> linearTiming1 = LinearTimingFunction::shared();
    RefPtr<TimingFunction> linearTiming2 = LinearTimingFunction::shared();
    EXPECT_EQ(*linearTiming1, *linearTiming1);
    EXPECT_EQ(*linearTiming1, *linearTiming2);
}

TEST_F(TimingFunctionTest, CubicOperatorEq)
{
    RefPtr<TimingFunction> cubicEaseInTiming1 = CubicBezierTimingFunction::preset(CubicBezierTimingFunction::EaseIn);
    RefPtr<TimingFunction> cubicEaseInTiming2 = CubicBezierTimingFunction::preset(CubicBezierTimingFunction::EaseIn);
    EXPECT_EQ(*cubicEaseInTiming1, *cubicEaseInTiming1);
    EXPECT_EQ(*cubicEaseInTiming1, *cubicEaseInTiming2);

    RefPtr<TimingFunction> cubicEaseOutTiming1 = CubicBezierTimingFunction::preset(CubicBezierTimingFunction::EaseOut);
    RefPtr<TimingFunction> cubicEaseOutTiming2 = CubicBezierTimingFunction::preset(CubicBezierTimingFunction::EaseOut);
    EXPECT_EQ(*cubicEaseOutTiming1, *cubicEaseOutTiming1);
    EXPECT_EQ(*cubicEaseOutTiming1, *cubicEaseOutTiming2);

    RefPtr<TimingFunction> cubicEaseInOutTiming1 = CubicBezierTimingFunction::preset(CubicBezierTimingFunction::EaseInOut);
    RefPtr<TimingFunction> cubicEaseInOutTiming2 = CubicBezierTimingFunction::preset(CubicBezierTimingFunction::EaseInOut);
    EXPECT_EQ(*cubicEaseInOutTiming1, *cubicEaseInOutTiming1);
    EXPECT_EQ(*cubicEaseInOutTiming1, *cubicEaseInOutTiming2);

    RefPtr<TimingFunction> cubicCustomTiming1 = CubicBezierTimingFunction::create(0.17, 0.67, 1, -1.73);
    RefPtr<TimingFunction> cubicCustomTiming2 = CubicBezierTimingFunction::create(0.17, 0.67, 1, -1.73);
    EXPECT_EQ(*cubicCustomTiming1, *cubicCustomTiming1);
    EXPECT_EQ(*cubicCustomTiming1, *cubicCustomTiming2);

    Vector<std::pair<std::string, RefPtr<TimingFunction> > > v;
    v.append(std::make_pair("cubicEaseInTiming1", cubicEaseInTiming1));
    v.append(std::make_pair("cubicEaseOutTiming1", cubicEaseOutTiming1));
    v.append(std::make_pair("cubicEaseInOutTiming1", cubicEaseInOutTiming1));
    v.append(std::make_pair("cubicCustomTiming1", cubicCustomTiming1));
    notEqualHelperLoop(v);
}

TEST_F(TimingFunctionTest, CubicOperatorEqReflectivity)
{
    RefPtr<TimingFunction> cubicA = CubicBezierTimingFunction::preset(CubicBezierTimingFunction::EaseIn);
    RefPtr<TimingFunction> cubicB = CubicBezierTimingFunction::create(0.42, 0.0, 1.0, 1.0);
    EXPECT_NE(*cubicA, *cubicB);
    EXPECT_NE(*cubicB, *cubicA);
}

TEST_F(TimingFunctionTest, StepsOperatorEq)
{
    RefPtr<TimingFunction> stepsTimingStart1 = StepsTimingFunction::preset(StepsTimingFunction::Start);
    RefPtr<TimingFunction> stepsTimingStart2 = StepsTimingFunction::preset(StepsTimingFunction::Start);
    EXPECT_EQ(*stepsTimingStart1, *stepsTimingStart1);
    EXPECT_EQ(*stepsTimingStart1, *stepsTimingStart2);

    RefPtr<TimingFunction> stepsTimingEnd1 = StepsTimingFunction::preset(StepsTimingFunction::End);
    RefPtr<TimingFunction> stepsTimingEnd2 = StepsTimingFunction::preset(StepsTimingFunction::End);
    EXPECT_EQ(*stepsTimingEnd1, *stepsTimingEnd1);
    EXPECT_EQ(*stepsTimingEnd1, *stepsTimingEnd2);

    RefPtr<TimingFunction> stepsTimingCustom1 = StepsTimingFunction::create(5, StepsTimingFunction::StepAtStart);
    RefPtr<TimingFunction> stepsTimingCustom2 = StepsTimingFunction::create(5, StepsTimingFunction::StepAtEnd);
    RefPtr<TimingFunction> stepsTimingCustom3 = StepsTimingFunction::create(7, StepsTimingFunction::StepAtStart);
    RefPtr<TimingFunction> stepsTimingCustom4 = StepsTimingFunction::create(7, StepsTimingFunction::StepAtEnd);

    EXPECT_EQ(*StepsTimingFunction::create(5, StepsTimingFunction::StepAtStart), *stepsTimingCustom1);
    EXPECT_EQ(*StepsTimingFunction::create(5, StepsTimingFunction::StepAtEnd), *stepsTimingCustom2);
    EXPECT_EQ(*StepsTimingFunction::create(7, StepsTimingFunction::StepAtStart), *stepsTimingCustom3);
    EXPECT_EQ(*StepsTimingFunction::create(7, StepsTimingFunction::StepAtEnd), *stepsTimingCustom4);

    Vector<std::pair<std::string, RefPtr<TimingFunction> > > v;
    v.append(std::make_pair("stepsTimingStart1", stepsTimingStart1));
    v.append(std::make_pair("stepsTimingEnd1", stepsTimingEnd1));
    v.append(std::make_pair("stepsTimingCustom1", stepsTimingCustom1));
    v.append(std::make_pair("stepsTimingCustom2", stepsTimingCustom2));
    v.append(std::make_pair("stepsTimingCustom3", stepsTimingCustom3));
    v.append(std::make_pair("stepsTimingCustom4", stepsTimingCustom4));
    notEqualHelperLoop(v);
}

TEST_F(TimingFunctionTest, StepsOperatorEqReflectivity)
{
    RefPtr<TimingFunction> stepsA = StepsTimingFunction::preset(StepsTimingFunction::Start);
    RefPtr<TimingFunction> stepsB = StepsTimingFunction::create(1, StepsTimingFunction::StepAtStart);
    EXPECT_NE(*stepsA, *stepsB);
    EXPECT_NE(*stepsB, *stepsA);
}

TEST_F(TimingFunctionTest, LinearEvaluate)
{
    RefPtr<TimingFunction> linearTiming = LinearTimingFunction::shared();
    EXPECT_EQ(0.2, linearTiming->evaluate(0.2, 0));
    EXPECT_EQ(0.6, linearTiming->evaluate(0.6, 0));
    EXPECT_EQ(-0.2, linearTiming->evaluate(-0.2, 0));
    EXPECT_EQ(1.6, linearTiming->evaluate(1.6, 0));
}

TEST_F(TimingFunctionTest, LinearRange)
{
    double start = 0;
    double end = 1;
    RefPtr<TimingFunction> linearTiming = LinearTimingFunction::shared();
    linearTiming->range(&start, &end);
    EXPECT_NEAR(0, start, 0.01);
    EXPECT_NEAR(1, end, 0.01);
    start = -1;
    end = 10;
    linearTiming->range(&start, &end);
    EXPECT_NEAR(-1, start, 0.01);
    EXPECT_NEAR(10, end, 0.01);
}

TEST_F(TimingFunctionTest, StepRange)
{
    double start = 0;
    double end = 1;
    RefPtr<TimingFunction> steps = StepsTimingFunction::preset(StepsTimingFunction::Start);
    steps->range(&start, &end);
    EXPECT_NEAR(0, start, 0.01);
    EXPECT_NEAR(1, end, 0.01);

    start = -1;
    end = 10;
    steps->range(&start, &end);
    EXPECT_NEAR(0, start, 0.01);
    EXPECT_NEAR(1, end, 0.01);
}

TEST_F(TimingFunctionTest, CubicRange)
{
    double start = 0;
    double end = 1;

    RefPtr<TimingFunction> cubicEaseTiming = CubicBezierTimingFunction::preset(CubicBezierTimingFunction::Ease);
    start = 0;
    end = 1;
    cubicEaseTiming->range(&start, &end);
    EXPECT_NEAR(0, start, 0.01);
    EXPECT_NEAR(1, end, 0.01);
    start = -1;
    end = 10;
    cubicEaseTiming->range(&start, &end);
    EXPECT_NEAR(-0.4, start, 0.01);
    EXPECT_NEAR(1, end, 0.01);

    RefPtr<TimingFunction> cubicEaseInTiming = CubicBezierTimingFunction::preset(CubicBezierTimingFunction::EaseIn);
    start = 0;
    end = 1;
    cubicEaseInTiming->range(&start, &end);
    EXPECT_NEAR(0, start, 0.01);
    EXPECT_NEAR(1, end, 0.01);
    start = -1;
    end = 10;
    cubicEaseInTiming->range(&start, &end);
    EXPECT_NEAR(0.0, start, 0.01);
    EXPECT_NEAR(16.51, end, 0.01);

    RefPtr<TimingFunction> cubicEaseOutTiming = CubicBezierTimingFunction::preset(CubicBezierTimingFunction::EaseOut);
    start = 0;
    end = 1;
    cubicEaseOutTiming->range(&start, &end);
    EXPECT_NEAR(0, start, 0.01);
    EXPECT_NEAR(1, end, 0.01);
    start = -1;
    end = 10;
    cubicEaseOutTiming->range(&start, &end);
    EXPECT_NEAR(-1.72, start, 0.01);
    EXPECT_NEAR(1.0, end, 0.01);

    RefPtr<TimingFunction> cubicEaseInOutTiming = CubicBezierTimingFunction::preset(CubicBezierTimingFunction::EaseInOut);
    start = 0;
    end = 1;
    cubicEaseInOutTiming->range(&start, &end);
    EXPECT_NEAR(0, start, 0.01);
    EXPECT_NEAR(1, end, 0.01);
    start = -1;
    end = 10;
    cubicEaseInOutTiming->range(&start, &end);
    EXPECT_NEAR(0.0, start, 0.01);
    EXPECT_NEAR(1.0, end, 0.01);

    RefPtr<TimingFunction> cubicCustomTiming = CubicBezierTimingFunction::create(0.17, 0.67, 1.0, -1.73);
    start = 0;
    end = 1;
    cubicCustomTiming->range(&start, &end);
    EXPECT_NEAR(-0.33, start, 0.01);
    EXPECT_NEAR(1.0, end, 0.01);

    start = -1;
    end = 10;
    cubicCustomTiming->range(&start, &end);
    EXPECT_NEAR(-3.94, start, 0.01);
    EXPECT_NEAR(4.578, end, 0.01);
}

TEST_F(TimingFunctionTest, CubicEvaluate)
{
    double tolerance = 0.01;
    RefPtr<TimingFunction> cubicEaseTiming = CubicBezierTimingFunction::preset(CubicBezierTimingFunction::Ease);
    EXPECT_NEAR(0.418, cubicEaseTiming->evaluate(0.25, tolerance), tolerance);
    EXPECT_NEAR(0.805, cubicEaseTiming->evaluate(0.50, tolerance), tolerance);
    EXPECT_NEAR(0.960, cubicEaseTiming->evaluate(0.75, tolerance), tolerance);

    RefPtr<TimingFunction> cubicEaseInTiming = CubicBezierTimingFunction::preset(CubicBezierTimingFunction::EaseIn);
    EXPECT_NEAR(0.093, cubicEaseInTiming->evaluate(0.25, tolerance), tolerance);
    EXPECT_NEAR(0.305, cubicEaseInTiming->evaluate(0.50, tolerance), tolerance);
    EXPECT_NEAR(0.620, cubicEaseInTiming->evaluate(0.75, tolerance), tolerance);

    RefPtr<TimingFunction> cubicEaseOutTiming = CubicBezierTimingFunction::preset(CubicBezierTimingFunction::EaseOut);
    EXPECT_NEAR(0.379, cubicEaseOutTiming->evaluate(0.25, tolerance), tolerance);
    EXPECT_NEAR(0.694, cubicEaseOutTiming->evaluate(0.50, tolerance), tolerance);
    EXPECT_NEAR(0.906, cubicEaseOutTiming->evaluate(0.75, tolerance), tolerance);

    RefPtr<TimingFunction> cubicEaseInOutTiming = CubicBezierTimingFunction::preset(CubicBezierTimingFunction::EaseInOut);
    EXPECT_NEAR(0.128, cubicEaseInOutTiming->evaluate(0.25, tolerance), tolerance);
    EXPECT_NEAR(0.500, cubicEaseInOutTiming->evaluate(0.50, tolerance), tolerance);
    EXPECT_NEAR(0.871, cubicEaseInOutTiming->evaluate(0.75, tolerance), tolerance);

    RefPtr<TimingFunction> cubicCustomTiming = CubicBezierTimingFunction::create(0.17, 0.67, 1, -1.73);
    EXPECT_NEAR(0.034, cubicCustomTiming->evaluate(0.25, tolerance), tolerance);
    EXPECT_NEAR(-0.217, cubicCustomTiming->evaluate(0.50, tolerance), tolerance);
    EXPECT_NEAR(-0.335, cubicCustomTiming->evaluate(0.75, tolerance), tolerance);
}

TEST_F(TimingFunctionTest, StepsEvaluate)
{
    RefPtr<TimingFunction> stepsTimingStart = StepsTimingFunction::preset(StepsTimingFunction::Start);
    EXPECT_EQ(0.00, stepsTimingStart->evaluate(-1.10, 0));
    EXPECT_EQ(0.00, stepsTimingStart->evaluate(-0.10, 0));
    EXPECT_EQ(1.00, stepsTimingStart->evaluate(0.00, 0));
    EXPECT_EQ(1.00, stepsTimingStart->evaluate(0.20, 0));
    EXPECT_EQ(1.00, stepsTimingStart->evaluate(0.60, 0));
    EXPECT_EQ(1.00, stepsTimingStart->evaluate(1.00, 0));
    EXPECT_EQ(1.00, stepsTimingStart->evaluate(2.00, 0));

    RefPtr<TimingFunction> stepsTimingMiddle = StepsTimingFunction::preset(StepsTimingFunction::Middle);
    EXPECT_EQ(0.00, stepsTimingMiddle->evaluate(-2.50, 0));
    EXPECT_EQ(0.00, stepsTimingMiddle->evaluate(0.00, 0));
    EXPECT_EQ(0.00, stepsTimingMiddle->evaluate(0.49, 0));
    EXPECT_EQ(1.00, stepsTimingMiddle->evaluate(0.50, 0));
    EXPECT_EQ(1.00, stepsTimingMiddle->evaluate(1.00, 0));
    EXPECT_EQ(1.00, stepsTimingMiddle->evaluate(2.50, 0));

    RefPtr<TimingFunction> stepsTimingEnd = StepsTimingFunction::preset(StepsTimingFunction::End);
    EXPECT_EQ(0.00, stepsTimingEnd->evaluate(-2.00, 0));
    EXPECT_EQ(0.00, stepsTimingEnd->evaluate(0.00, 0));
    EXPECT_EQ(0.00, stepsTimingEnd->evaluate(0.20, 0));
    EXPECT_EQ(0.00, stepsTimingEnd->evaluate(0.60, 0));
    EXPECT_EQ(1.00, stepsTimingEnd->evaluate(1.00, 0));
    EXPECT_EQ(1.00, stepsTimingEnd->evaluate(2.00, 0));

    RefPtr<TimingFunction> stepsTimingCustomStart = StepsTimingFunction::create(4, StepsTimingFunction::StepAtStart);
    EXPECT_EQ(0.00, stepsTimingCustomStart->evaluate(-0.50, 0));
    EXPECT_EQ(0.25, stepsTimingCustomStart->evaluate(0.00, 0));
    EXPECT_EQ(0.25, stepsTimingCustomStart->evaluate(0.24, 0));
    EXPECT_EQ(0.50, stepsTimingCustomStart->evaluate(0.25, 0));
    EXPECT_EQ(0.50, stepsTimingCustomStart->evaluate(0.49, 0));
    EXPECT_EQ(0.75, stepsTimingCustomStart->evaluate(0.50, 0));
    EXPECT_EQ(0.75, stepsTimingCustomStart->evaluate(0.74, 0));
    EXPECT_EQ(1.00, stepsTimingCustomStart->evaluate(0.75, 0));
    EXPECT_EQ(1.00, stepsTimingCustomStart->evaluate(1.00, 0));
    EXPECT_EQ(1.00, stepsTimingCustomStart->evaluate(1.50, 0));

    RefPtr<TimingFunction> stepsTimingCustomMiddle = StepsTimingFunction::create(4, StepsTimingFunction::StepAtMiddle);
    EXPECT_EQ(0.00, stepsTimingCustomMiddle->evaluate(-2.00, 0));
    EXPECT_EQ(0.00, stepsTimingCustomMiddle->evaluate(0.00, 0));
    EXPECT_EQ(0.00, stepsTimingCustomMiddle->evaluate(0.12, 0));
    EXPECT_EQ(0.25, stepsTimingCustomMiddle->evaluate(0.13, 0));
    EXPECT_EQ(0.25, stepsTimingCustomMiddle->evaluate(0.37, 0));
    EXPECT_EQ(0.50, stepsTimingCustomMiddle->evaluate(0.38, 0));
    EXPECT_EQ(0.50, stepsTimingCustomMiddle->evaluate(0.62, 0));
    EXPECT_EQ(0.75, stepsTimingCustomMiddle->evaluate(0.63, 0));
    EXPECT_EQ(0.75, stepsTimingCustomMiddle->evaluate(0.87, 0));
    EXPECT_EQ(1.00, stepsTimingCustomMiddle->evaluate(0.88, 0));
    EXPECT_EQ(1.00, stepsTimingCustomMiddle->evaluate(1.00, 0));
    EXPECT_EQ(1.00, stepsTimingCustomMiddle->evaluate(3.00, 0));

    RefPtr<TimingFunction> stepsTimingCustomEnd = StepsTimingFunction::create(4, StepsTimingFunction::StepAtEnd);
    EXPECT_EQ(0.00, stepsTimingCustomEnd->evaluate(-2.00, 0));
    EXPECT_EQ(0.00, stepsTimingCustomEnd->evaluate(0.00, 0));
    EXPECT_EQ(0.00, stepsTimingCustomEnd->evaluate(0.24, 0));
    EXPECT_EQ(0.25, stepsTimingCustomEnd->evaluate(0.25, 0));
    EXPECT_EQ(0.25, stepsTimingCustomEnd->evaluate(0.49, 0));
    EXPECT_EQ(0.50, stepsTimingCustomEnd->evaluate(0.50, 0));
    EXPECT_EQ(0.50, stepsTimingCustomEnd->evaluate(0.74, 0));
    EXPECT_EQ(0.75, stepsTimingCustomEnd->evaluate(0.75, 0));
    EXPECT_EQ(0.75, stepsTimingCustomEnd->evaluate(0.99, 0));
    EXPECT_EQ(1.00, stepsTimingCustomEnd->evaluate(1.00, 0));
    EXPECT_EQ(1.00, stepsTimingCustomEnd->evaluate(2.00, 0));
}

} // namespace

} // namespace blink
