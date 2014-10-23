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

#include "config.h"
#include "core/animation/AnimationStack.h"

#include "core/animation/CompositorAnimations.h"
#include "core/animation/StyleInterpolation.h"
#include "core/animation/css/CSSAnimations.h"
#include "wtf/BitArray.h"
#include "wtf/NonCopyingSort.h"
#include <algorithm>

namespace blink {

namespace {

void copyToActiveInterpolationMap(const WillBeHeapVector<RefPtrWillBeMember<blink::Interpolation> >& source, WillBeHeapHashMap<CSSPropertyID, RefPtrWillBeMember<blink::Interpolation> >& target)
{
    for (size_t i = 0; i < source.size(); ++i) {
        Interpolation* interpolation = source[i].get();
        target.set(toStyleInterpolation(interpolation)->id(), interpolation);
    }
}

bool compareEffects(const OwnPtrWillBeMember<SampledEffect>& effect1, const OwnPtrWillBeMember<SampledEffect>& effect2)
{
    ASSERT(effect1 && effect2);
    return effect1->sequenceNumber() < effect2->sequenceNumber();
}

void copyNewAnimationsToActiveInterpolationMap(const WillBeHeapVector<RawPtrWillBeMember<InertAnimation> >& newAnimations, WillBeHeapHashMap<CSSPropertyID, RefPtrWillBeMember<Interpolation> >& result)
{
    for (size_t i = 0; i < newAnimations.size(); ++i) {
        OwnPtrWillBeRawPtr<WillBeHeapVector<RefPtrWillBeMember<Interpolation> > > sample = newAnimations[i]->sample(0);
        if (sample) {
            copyToActiveInterpolationMap(*sample, result);
        }
    }
}

} // namespace

AnimationStack::AnimationStack()
{
}

bool AnimationStack::affects(CSSPropertyID property) const
{
    for (size_t i = 0; i < m_effects.size(); ++i) {
        if (m_effects[i]->animation() && m_effects[i]->animation()->affects(property))
            return true;
    }
    return false;
}

bool AnimationStack::hasActiveAnimationsOnCompositor(CSSPropertyID property) const
{
    for (size_t i = 0; i < m_effects.size(); ++i) {
        if (m_effects[i]->animation() && m_effects[i]->animation()->hasActiveAnimationsOnCompositor(property))
            return true;
    }
    return false;
}

WillBeHeapHashMap<CSSPropertyID, RefPtrWillBeMember<Interpolation> > AnimationStack::activeInterpolations(AnimationStack* animationStack, const WillBeHeapVector<RawPtrWillBeMember<InertAnimation> >* newAnimations, const WillBeHeapHashSet<RawPtrWillBeMember<const AnimationPlayer> >* cancelledAnimationPlayers, Animation::Priority priority, double timelineCurrentTime)
{
    // We don't exactly know when new animations will start, but timelineCurrentTime is a good estimate.

    WillBeHeapHashMap<CSSPropertyID, RefPtrWillBeMember<Interpolation> > result;

    if (animationStack) {
        WillBeHeapVector<OwnPtrWillBeMember<SampledEffect> >& effects = animationStack->m_effects;
        // std::sort doesn't work with OwnPtrs
        nonCopyingSort(effects.begin(), effects.end(), compareEffects);
        animationStack->simplifyEffects();
        for (size_t i = 0; i < effects.size(); ++i) {
            const SampledEffect& effect = *effects[i];
            if (effect.priority() != priority || (cancelledAnimationPlayers && effect.animation() && cancelledAnimationPlayers->contains(effect.animation()->player())))
                continue;
            copyToActiveInterpolationMap(effect.interpolations(), result);
        }
    }

    if (newAnimations)
        copyNewAnimationsToActiveInterpolationMap(*newAnimations, result);

    return result;
}

void AnimationStack::simplifyEffects()
{
    // FIXME: This will need to be updated when we have 'add' keyframes.

    BitArray<numCSSProperties> replacedProperties;
    for (size_t i = m_effects.size(); i--; ) {
        SampledEffect& effect = *m_effects[i];
        effect.removeReplacedInterpolationsIfNeeded(replacedProperties);
        if (!effect.canChange()) {
            for (size_t i = 0; i < effect.interpolations().size(); ++i)
                replacedProperties.set(toStyleInterpolation(effect.interpolations()[i].get())->id());
        }
    }

    size_t dest = 0;
    for (size_t i = 0; i < m_effects.size(); ++i) {
        if (!m_effects[i]->interpolations().isEmpty()) {
            m_effects[dest++].swap(m_effects[i]);
            continue;
        }
        if (m_effects[i]->animation())
            m_effects[i]->animation()->notifySampledEffectRemovedFromAnimationStack();
    }
    m_effects.shrink(dest);
}

void AnimationStack::trace(Visitor* visitor)
{
    visitor->trace(m_effects);
}

bool AnimationStack::getAnimatedBoundingBox(FloatBox& box, CSSPropertyID property) const
{
    FloatBox originalBox(box);
    for (size_t i = 0; i < m_effects.size(); ++i) {
        if (m_effects[i]->animation() && m_effects[i]->animation()->affects(property)) {
            Animation* anim = m_effects[i]->animation();
            if (!anim)
                continue;
            const Timing& timing = anim->specifiedTiming();
            double startRange = 0;
            double endRange = 1;
            timing.timingFunction->range(&startRange, &endRange);
            FloatBox expandingBox(originalBox);
            if (!CompositorAnimations::instance()->getAnimatedBoundingBox(expandingBox, *anim->effect(), startRange, endRange))
                return false;
            box.expandTo(expandingBox);
        }
    }
    return true;
}

} // namespace blink
