// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SampledEffect_h
#define SampledEffect_h

#include "core/animation/Animation.h"
#include "core/animation/AnimationPlayer.h"
#include "core/animation/Interpolation.h"
#include "wtf/BitArray.h"
#include "wtf/Vector.h"

namespace blink {

class SampledEffect : public DummyBase<SampledEffect> {
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

    void trace(Visitor*);

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

#endif
