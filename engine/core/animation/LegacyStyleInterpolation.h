// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef LegacyStyleInterpolation_h
#define LegacyStyleInterpolation_h

#include "sky/engine/core/animation/StyleInterpolation.h"
#include "sky/engine/core/css/resolver/AnimatedStyleBuilder.h"

namespace blink {

class LegacyStyleInterpolation : public StyleInterpolation {
public:
    static PassRefPtr<LegacyStyleInterpolation> create(PassRefPtr<AnimatableValue> start, PassRefPtr<AnimatableValue> end, CSSPropertyID id)
    {
        return adoptRef(new LegacyStyleInterpolation(InterpolableAnimatableValue::create(start), InterpolableAnimatableValue::create(end), id));
    }

    virtual void apply(StyleResolverState& state) const override
    {
        AnimatedStyleBuilder::applyProperty(m_id, state, currentValue().get());
    }

    virtual bool isLegacyStyleInterpolation() const override final { return true; }
    PassRefPtr<AnimatableValue> currentValue() const
    {
        return toInterpolableAnimatableValue(m_cachedValue.get())->value();
    }

private:
    LegacyStyleInterpolation(PassOwnPtr<InterpolableValue> start, PassOwnPtr<InterpolableValue> end, CSSPropertyID id)
        : StyleInterpolation(start, end, id)
    {
    }
};

DEFINE_TYPE_CASTS(LegacyStyleInterpolation, Interpolation, value, value->isLegacyStyleInterpolation(), value.isLegacyStyleInterpolation());

}

#endif
