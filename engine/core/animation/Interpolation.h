// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_ANIMATION_INTERPOLATION_H_
#define SKY_ENGINE_CORE_ANIMATION_INTERPOLATION_H_

#include "sky/engine/core/animation/InterpolableValue.h"
#include "sky/engine/platform/heap/Handle.h"

namespace blink {

class Interpolation : public RefCounted<Interpolation> {
    DECLARE_EMPTY_VIRTUAL_DESTRUCTOR_WILL_BE_REMOVED(Interpolation);
public:
    static PassRefPtr<Interpolation> create(PassOwnPtr<InterpolableValue> start, PassOwnPtr<InterpolableValue> end)
    {
        return adoptRef(new Interpolation(start, end));
    }

    void interpolate(int iteration, double fraction) const;

    virtual bool isStyleInterpolation() const { return false; }
    virtual bool isLegacyStyleInterpolation() const { return false; }

protected:
    const OwnPtr<InterpolableValue> m_start;
    const OwnPtr<InterpolableValue> m_end;

    mutable double m_cachedFraction;
    mutable int m_cachedIteration;
    mutable OwnPtr<InterpolableValue> m_cachedValue;

    Interpolation(PassOwnPtr<InterpolableValue> start, PassOwnPtr<InterpolableValue> end);

private:
    InterpolableValue* getCachedValueForTesting() const { return m_cachedValue.get(); }

    friend class AnimationInterpolableValueTest;
    friend class AnimationInterpolationEffectTest;
};

}

#endif  // SKY_ENGINE_CORE_ANIMATION_INTERPOLATION_H_
