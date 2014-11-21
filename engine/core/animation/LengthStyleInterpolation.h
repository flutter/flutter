// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_ANIMATION_LENGTHSTYLEINTERPOLATION_H_
#define SKY_ENGINE_CORE_ANIMATION_LENGTHSTYLEINTERPOLATION_H_

#include "sky/engine/core/animation/StyleInterpolation.h"
#include "sky/engine/platform/Length.h"

namespace blink {

class LengthStyleInterpolation : public StyleInterpolation {
public:
    static PassRefPtr<LengthStyleInterpolation> create(CSSValue* start, CSSValue* end, CSSPropertyID id,  ValueRange range)
    {
        return adoptRef(new LengthStyleInterpolation(lengthToInterpolableValue(start), lengthToInterpolableValue(end), id, range));
    }

    static bool canCreateFrom(const CSSValue&);

    virtual void apply(StyleResolverState&) const override;
private:
    LengthStyleInterpolation(PassOwnPtr<InterpolableValue> start, PassOwnPtr<InterpolableValue> end, CSSPropertyID id,  ValueRange range)
        : StyleInterpolation(start, end, id)
        , m_range(range)
    { }

    static PassOwnPtr<InterpolableValue> lengthToInterpolableValue(CSSValue*);
    static PassRefPtr<CSSValue> interpolableValueToLength(InterpolableValue*, ValueRange);

    ValueRange m_range;

    friend class AnimationLengthStyleInterpolationTest;
};

}

#endif  // SKY_ENGINE_CORE_ANIMATION_LENGTHSTYLEINTERPOLATION_H_
