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

class SampledEffect : public NoBaseWillBeGarbageCollected<SampledEffect> {
public:
    static PassOwnPtrWillBeRawPtr<SampledEffect> create(Animation* animation, PassOwnPtrWillBeRawPtr<WillBeHeapVector<RefPtrWillBeMember<Interpolation> > > interpolations)
    {
        return adoptPtrWillBeNoop(new SampledEffect(animation, interpolations));
    }

    bool canChange() const;
    void clear();

    const WillBeHeapVector<RefPtrWillBeMember<Interpolation> >& interpolations() const { return *m_interpolations; }
    void setInterpolations(PassOwnPtrWillBeRawPtr<WillBeHeapVector<RefPtrWillBeMember<Interpolation> > > interpolations) { m_interpolations = interpolations; }

    Animation* animation() const { return m_animation; }
    unsigned sequenceNumber() const { return m_sequenceNumber; }
    Animation::Priority priority() const { return m_priority; }

    void removeReplacedInterpolationsIfNeeded(const BitArray<numCSSProperties>&);

    void trace(Visitor*);

private:
    SampledEffect(Animation*, PassOwnPtrWillBeRawPtr<WillBeHeapVector<RefPtrWillBeMember<Interpolation> > >);

    RawPtrWillBeWeakMember<Animation> m_animation;
#if !ENABLE(OILPAN)
    RefPtr<AnimationPlayer> m_player;
#endif
    OwnPtrWillBeMember<WillBeHeapVector<RefPtrWillBeMember<Interpolation> > > m_interpolations;
    const unsigned m_sequenceNumber;
    Animation::Priority m_priority;
};

} // namespace blink

#endif
