// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_ANIMATION_SAMPLEDEFFECT_H_
#define SKY_ENGINE_CORE_ANIMATION_SAMPLEDEFFECT_H_

#include "sky/engine/core/animation/Animation.h"
#include "sky/engine/core/animation/AnimationPlayer.h"
#include "sky/engine/core/animation/Interpolation.h"
#include "sky/engine/wtf/BitArray.h"
#include "sky/engine/wtf/Vector.h"

namespace blink {

class SampledEffect {
public:
    static PassOwnPtr<SampledEffect> create(Animation* animation, PassOwnPtr<Vector<RefPtr<Interpolation> > > interpolations)
    {
        return adoptPtr(new SampledEffect(animation, interpolations));
    }

    bool canChange() const;
    void clear();

    const Vector<RefPtr<Interpolation> >& interpolations() const { return *m_interpolations; }
    void setInterpolations(PassOwnPtr<Vector<RefPtr<Interpolation> > > interpolations) { m_interpolations = interpolations; }

    Animation* animation() const { return m_animation; }
    unsigned sequenceNumber() const { return m_sequenceNumber; }
    Animation::Priority priority() const { return m_priority; }

    void removeReplacedInterpolationsIfNeeded(const BitArray<numCSSProperties>&);

private:
    SampledEffect(Animation*, PassOwnPtr<Vector<RefPtr<Interpolation> > >);

    RawPtr<Animation> m_animation;
#if !ENABLE(OILPAN)
    RefPtr<AnimationPlayer> m_player;
#endif
    OwnPtr<Vector<RefPtr<Interpolation> > > m_interpolations;
    const unsigned m_sequenceNumber;
    Animation::Priority m_priority;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_ANIMATION_SAMPLEDEFFECT_H_
