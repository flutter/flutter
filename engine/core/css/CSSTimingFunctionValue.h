/*
 * Copyright (C) 2007, 2008, 2012 Apple Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef CSSTimingFunctionValue_h
#define CSSTimingFunctionValue_h

#include "core/css/CSSValue.h"
#include "platform/animation/TimingFunction.h"
#include "wtf/PassRefPtr.h"

namespace blink {

class CSSCubicBezierTimingFunctionValue : public CSSValue {
public:
    static PassRefPtrWillBeRawPtr<CSSCubicBezierTimingFunctionValue> create(double x1, double y1, double x2, double y2)
    {
        return adoptRefWillBeNoop(new CSSCubicBezierTimingFunctionValue(x1, y1, x2, y2));
    }

    String customCSSText() const;

    double x1() const { return m_x1; }
    double y1() const { return m_y1; }
    double x2() const { return m_x2; }
    double y2() const { return m_y2; }

    bool equals(const CSSCubicBezierTimingFunctionValue&) const;

    void traceAfterDispatch(Visitor* visitor) { CSSValue::traceAfterDispatch(visitor); }

private:
    CSSCubicBezierTimingFunctionValue(double x1, double y1, double x2, double y2)
        : CSSValue(CubicBezierTimingFunctionClass)
        , m_x1(x1)
        , m_y1(y1)
        , m_x2(x2)
        , m_y2(y2)
    {
    }

    double m_x1;
    double m_y1;
    double m_x2;
    double m_y2;
};

DEFINE_CSS_VALUE_TYPE_CASTS(CSSCubicBezierTimingFunctionValue, isCubicBezierTimingFunctionValue());

class CSSStepsTimingFunctionValue : public CSSValue {
public:
    static PassRefPtrWillBeRawPtr<CSSStepsTimingFunctionValue> create(int steps, StepsTimingFunction::StepAtPosition stepAtPosition)
    {
        return adoptRefWillBeNoop(new CSSStepsTimingFunctionValue(steps, stepAtPosition));
    }

    int numberOfSteps() const { return m_steps; }
    StepsTimingFunction::StepAtPosition stepAtPosition() const { return m_stepAtPosition; }

    String customCSSText() const;

    bool equals(const CSSStepsTimingFunctionValue&) const;

    void traceAfterDispatch(Visitor* visitor) { CSSValue::traceAfterDispatch(visitor); }

private:
    CSSStepsTimingFunctionValue(int steps, StepsTimingFunction::StepAtPosition stepAtPosition)
        : CSSValue(StepsTimingFunctionClass)
        , m_steps(steps)
        , m_stepAtPosition(stepAtPosition)
    {
    }

    int m_steps;
    StepsTimingFunction::StepAtPosition m_stepAtPosition;
};

DEFINE_CSS_VALUE_TYPE_CASTS(CSSStepsTimingFunctionValue, isStepsTimingFunctionValue());

} // namespace

#endif
