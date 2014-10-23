/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef AnimationStack_h
#define AnimationStack_h

#include "core/animation/Animation.h"
#include "core/animation/AnimationEffect.h"
#include "core/animation/AnimationPlayer.h"
#include "core/animation/SampledEffect.h"
#include "platform/geometry/FloatBox.h"
#include "wtf/HashSet.h"
#include "wtf/Vector.h"

namespace blink {

class InertAnimation;

class AnimationStack {
    DISALLOW_ALLOCATION();
    WTF_MAKE_NONCOPYABLE(AnimationStack);
public:
    AnimationStack();

    void add(PassOwnPtrWillBeRawPtr<SampledEffect> effect) { m_effects.append(effect); }
    bool isEmpty() const { return m_effects.isEmpty(); }
    bool affects(CSSPropertyID) const;
    bool hasActiveAnimationsOnCompositor(CSSPropertyID) const;
    static WillBeHeapHashMap<CSSPropertyID, RefPtrWillBeMember<Interpolation> > activeInterpolations(AnimationStack*, const WillBeHeapVector<RawPtrWillBeMember<InertAnimation> >* newAnimations, const WillBeHeapHashSet<RawPtrWillBeMember<const AnimationPlayer> >* cancelledAnimationPlayers, Animation::Priority, double timelineCurrentTime);

    bool getAnimatedBoundingBox(FloatBox&, CSSPropertyID) const;
    void trace(Visitor*);

private:
    void simplifyEffects();
    // Effects sorted by priority. Lower priority at the start of the list.
    WillBeHeapVector<OwnPtrWillBeMember<SampledEffect> > m_effects;

    friend class AnimationAnimationStackTest;
};

} // namespace blink

#endif
