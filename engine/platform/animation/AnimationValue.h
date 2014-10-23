/*
 * Copyright (C) 2009 Apple Inc. All rights reserved.
 * Copyright (C) 2013 Intel Corporation. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
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

#ifndef AnimationValue_h
#define AnimationValue_h

#include "platform/animation/TimingFunction.h"
#include "platform/graphics/filters/FilterOperations.h"
#include "platform/transforms/TransformOperations.h"

#include "wtf/PassRefPtr.h"
#include "wtf/RefPtr.h"

namespace blink {

// Base class for animation values (also used for transitions). Here to
// represent values for properties being animated via the GraphicsLayer,
// without pulling in style-related data from outside of the platform directory.
class AnimationValue {
    WTF_MAKE_FAST_ALLOCATED;
public:
    explicit AnimationValue(double keyTime, PassRefPtr<TimingFunction> timingFunction = nullptr)
        : m_keyTime(keyTime)
        , m_timingFunction(timingFunction)
    {
    }

    virtual ~AnimationValue() { }

    double keyTime() const { return m_keyTime; }
    const TimingFunction* timingFunction() const { return m_timingFunction.get(); }
    virtual PassOwnPtr<AnimationValue> clone() const = 0;

private:
    double m_keyTime;
    RefPtr<TimingFunction> m_timingFunction;
};

// Used to store one float value of an animation.
class FloatAnimationValue FINAL : public AnimationValue {
public:
    FloatAnimationValue(double keyTime, float value, PassRefPtr<TimingFunction> timingFunction = nullptr)
        : AnimationValue(keyTime, timingFunction)
        , m_value(value)
    {
    }
    virtual PassOwnPtr<AnimationValue> clone() const OVERRIDE { return adoptPtr(new FloatAnimationValue(*this)); }

    float value() const { return m_value; }

private:
    float m_value;
};

// Used to store one transform value in a keyframe list.
class TransformAnimationValue FINAL : public AnimationValue {
public:
    explicit TransformAnimationValue(double keyTime, const TransformOperations* value = 0, PassRefPtr<TimingFunction> timingFunction = nullptr)
        : AnimationValue(keyTime, timingFunction)
    {
        if (value)
            m_value = *value;
    }
    virtual PassOwnPtr<AnimationValue> clone() const OVERRIDE { return adoptPtr(new TransformAnimationValue(*this)); }

    const TransformOperations* value() const { return &m_value; }

private:
    TransformOperations m_value;
};

// Used to store one filter value in a keyframe list.
class FilterAnimationValue FINAL : public AnimationValue {
public:
    explicit FilterAnimationValue(double keyTime, const FilterOperations* value = 0, PassRefPtr<TimingFunction> timingFunction = nullptr)
        : AnimationValue(keyTime, timingFunction)
    {
        if (value)
            m_value = *value;
    }
    virtual PassOwnPtr<AnimationValue> clone() const OVERRIDE { return adoptPtr(new FilterAnimationValue(*this)); }

    const FilterOperations* value() const { return &m_value; }

private:
    FilterOperations m_value;
};

} // namespace blink

#endif // AnimationValue_h
