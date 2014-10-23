/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 *           (C) 2000 Antti Koivisto (koivisto@kde.org)
 *           (C) 2000 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2003, 2005, 2006, 2007, 2008 Apple Inc. All rights reserved.
 * Copyright (C) 2006 Graham Dennis (graham.dennis@gmail.com)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 *
 */

#ifndef TimingFunction_h
#define TimingFunction_h

#include "platform/animation/AnimationUtilities.h" // For blend()
#include "platform/animation/UnitBezier.h"
#include "wtf/OwnPtr.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefCounted.h"
#include "wtf/StdLibExtras.h"
#include "wtf/text/StringBuilder.h"
#include "wtf/text/WTFString.h"
#include <algorithm>

namespace blink {

class PLATFORM_EXPORT TimingFunction : public RefCounted<TimingFunction> {
public:

    enum Type {
        LinearFunction, CubicBezierFunction, StepsFunction
    };

    virtual ~TimingFunction() { }

    Type type() const { return m_type; }

    virtual String toString() const = 0;

    // Evaluates the timing function at the given fraction. The accuracy parameter provides a hint as to the required
    // accuracy and is not guaranteed.
    virtual double evaluate(double fraction, double accuracy) const = 0;

    // This function returns the minimum and maximum values obtainable when
    // calling evaluate();
    virtual void range(double* minValue, double* maxValue) const = 0;

protected:
    TimingFunction(Type type)
        : m_type(type)
    {
    }

private:
    Type m_type;
};

class PLATFORM_EXPORT LinearTimingFunction FINAL : public TimingFunction {
public:
    static LinearTimingFunction* shared()
    {
        DEFINE_STATIC_REF(LinearTimingFunction, linear, (adoptRef(new LinearTimingFunction())));
        return linear;
    }

    virtual ~LinearTimingFunction() { }

    virtual String toString() const OVERRIDE;

    virtual double evaluate(double fraction, double) const OVERRIDE;

    virtual void range(double* minValue, double* maxValue) const OVERRIDE;
private:
    LinearTimingFunction()
        : TimingFunction(LinearFunction)
    {
    }
};

class PLATFORM_EXPORT CubicBezierTimingFunction FINAL : public TimingFunction {
public:
    enum SubType {
        Ease,
        EaseIn,
        EaseOut,
        EaseInOut,
        Custom
    };

    static PassRefPtr<CubicBezierTimingFunction> create(double x1, double y1, double x2, double y2)
    {
        return adoptRef(new CubicBezierTimingFunction(Custom, x1, y1, x2, y2));
    }

    static CubicBezierTimingFunction* preset(SubType subType)
    {
        switch (subType) {
        case Ease:
            {
                DEFINE_STATIC_REF(CubicBezierTimingFunction, ease, (adoptRef(new CubicBezierTimingFunction(Ease, 0.25, 0.1, 0.25, 1.0))));
                return ease;
            }
        case EaseIn:
            {
                DEFINE_STATIC_REF(CubicBezierTimingFunction, easeIn, (adoptRef(new CubicBezierTimingFunction(EaseIn, 0.42, 0.0, 1.0, 1.0))));
                return easeIn;
            }
        case EaseOut:
            {
                DEFINE_STATIC_REF(CubicBezierTimingFunction, easeOut, (adoptRef(new CubicBezierTimingFunction(EaseOut, 0.0, 0.0, 0.58, 1.0))));
                return easeOut;
            }
        case EaseInOut:
            {
                DEFINE_STATIC_REF(CubicBezierTimingFunction, easeInOut, (adoptRef(new CubicBezierTimingFunction(EaseInOut, 0.42, 0.0, 0.58, 1.0))));
                return easeInOut;
            }
        default:
            ASSERT_NOT_REACHED();
            return 0;
        }
    }

    virtual ~CubicBezierTimingFunction() { }

    virtual String toString() const OVERRIDE;

    virtual double evaluate(double fraction, double accuracy) const OVERRIDE;
    virtual void range(double* minValue, double* maxValue) const OVERRIDE;

    double x1() const { return m_x1; }
    double y1() const { return m_y1; }
    double x2() const { return m_x2; }
    double y2() const { return m_y2; }

    SubType subType() const { return m_subType; }

private:
    explicit CubicBezierTimingFunction(SubType subType, double x1, double y1, double x2, double y2)
        : TimingFunction(CubicBezierFunction)
        , m_x1(x1)
        , m_y1(y1)
        , m_x2(x2)
        , m_y2(y2)
        , m_subType(subType)
    {
    }

    double m_x1;
    double m_y1;
    double m_x2;
    double m_y2;
    SubType m_subType;
    mutable OwnPtr<UnitBezier> m_bezier;
};

class PLATFORM_EXPORT StepsTimingFunction FINAL : public TimingFunction {
public:
    enum SubType {
        Start,
        End,
        Middle,
        Custom
    };

    enum StepAtPosition {
        StepAtStart,
        StepAtMiddle,
        StepAtEnd
    };

    static PassRefPtr<StepsTimingFunction> create(int steps, StepAtPosition stepAtPosition)
    {
        return adoptRef(new StepsTimingFunction(Custom, steps, stepAtPosition));
    }

    static StepsTimingFunction* preset(SubType subType)
    {
        switch (subType) {
        case Start:
            {
                DEFINE_STATIC_REF(StepsTimingFunction, start, (adoptRef(new StepsTimingFunction(Start, 1, StepAtStart))));
                return start;
            }
        case Middle:
            {
                DEFINE_STATIC_REF(StepsTimingFunction, middle, (adoptRef(new StepsTimingFunction(Middle, 1, StepAtMiddle))));
                return middle;
            }
        case End:
            {
                DEFINE_STATIC_REF(StepsTimingFunction, end, (adoptRef(new StepsTimingFunction(End, 1, StepAtEnd))));
                return end;
            }
        default:
            ASSERT_NOT_REACHED();
            return 0;
        }
    }


    virtual ~StepsTimingFunction() { }

    virtual String toString() const OVERRIDE;

    virtual double evaluate(double fraction, double) const OVERRIDE;

    virtual void range(double* minValue, double* maxValue) const OVERRIDE;
    int numberOfSteps() const { return m_steps; }
    StepAtPosition stepAtPosition() const { return m_stepAtPosition; }

    SubType subType() const { return m_subType; }

private:
    StepsTimingFunction(SubType subType, int steps, StepAtPosition stepAtPosition)
        : TimingFunction(StepsFunction)
        , m_steps(steps)
        , m_stepAtPosition(stepAtPosition)
        , m_subType(subType)
    {
    }

    int m_steps;
    StepAtPosition m_stepAtPosition;
    SubType m_subType;
};

PLATFORM_EXPORT bool operator==(const LinearTimingFunction&, const TimingFunction&);
PLATFORM_EXPORT bool operator==(const CubicBezierTimingFunction&, const TimingFunction&);
PLATFORM_EXPORT bool operator==(const StepsTimingFunction&, const TimingFunction&);

PLATFORM_EXPORT bool operator==(const TimingFunction&, const TimingFunction&);
PLATFORM_EXPORT bool operator!=(const TimingFunction&, const TimingFunction&);

#define DEFINE_TIMING_FUNCTION_TYPE_CASTS(typeName) \
    DEFINE_TYPE_CASTS( \
        typeName##TimingFunction, TimingFunction, value, \
        value->type() == TimingFunction::typeName##Function, \
        value.type() == TimingFunction::typeName##Function)

DEFINE_TIMING_FUNCTION_TYPE_CASTS(Linear);
DEFINE_TIMING_FUNCTION_TYPE_CASTS(CubicBezier);
DEFINE_TIMING_FUNCTION_TYPE_CASTS(Steps);

} // namespace blink

#endif // TimingFunction_h
