// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_ANIMATION_DEFAULTSTYLEINTERPOLATION_H_
#define SKY_ENGINE_CORE_ANIMATION_DEFAULTSTYLEINTERPOLATION_H_

#include "sky/engine/core/animation/StyleInterpolation.h"
#include "sky/engine/core/css/resolver/StyleBuilder.h"

namespace blink {

class DefaultStyleInterpolation : public StyleInterpolation {
public:
    static PassRefPtr<DefaultStyleInterpolation> create(CSSValue* start, CSSValue* end, CSSPropertyID id)
    {
        return adoptRef(new DefaultStyleInterpolation(start, end, id));
    }

    virtual void apply(StyleResolverState& state) const
    {
        StyleBuilder::applyProperty(m_id, state, toInterpolableBool(m_cachedValue.get())->value() ? m_endCSSValue.get() : m_startCSSValue.get());
    }

private:
    DefaultStyleInterpolation(CSSValue* start, CSSValue* end, CSSPropertyID id)
        : StyleInterpolation(InterpolableBool::create(false), InterpolableBool::create(true), id)
        , m_startCSSValue(start)
        , m_endCSSValue(end)
    {
    }

    RefPtr<CSSValue> m_startCSSValue;
    RefPtr<CSSValue> m_endCSSValue;
};

}

#endif  // SKY_ENGINE_CORE_ANIMATION_DEFAULTSTYLEINTERPOLATION_H_
