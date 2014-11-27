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

#include "sky/engine/config.h"
#include "sky/engine/core/animation/Animation.h"

#include "sky/engine/bindings/core/v8/Dictionary.h"
#include "sky/engine/bindings/core/v8/ExceptionState.h"
#include "sky/engine/core/animation/ActiveAnimations.h"
#include "sky/engine/core/animation/AnimationHelpers.h"
#include "sky/engine/core/animation/AnimationPlayer.h"
#include "sky/engine/core/animation/AnimationTimeline.h"
#include "sky/engine/core/animation/CompositorAnimations.h"
#include "sky/engine/core/animation/Interpolation.h"
#include "sky/engine/core/animation/KeyframeEffectModel.h"
#include "sky/engine/core/dom/Element.h"
#include "sky/engine/core/frame/UseCounter.h"
#include "sky/engine/core/rendering/RenderLayer.h"

namespace blink {

PassRefPtr<Animation> Animation::create(Element* target, PassRefPtr<AnimationEffect> effect, const Timing& timing, Priority priority, PassOwnPtr<EventDelegate> eventDelegate)
{
    return adoptRef(new Animation(target, effect, timing, priority, eventDelegate));
}

PassRefPtr<Animation> Animation::create(Element* element, PassRefPtr<AnimationEffect> effect, const Dictionary& timingInputDictionary)
{
    ASSERT(RuntimeEnabledFeatures::webAnimationsAPIEnabled());
    return create(element, effect, TimingInput::convert(timingInputDictionary));
}
PassRefPtr<Animation> Animation::create(Element* element, PassRefPtr<AnimationEffect> effect, double duration)
{
    ASSERT(RuntimeEnabledFeatures::webAnimationsAPIEnabled());
    return create(element, effect, TimingInput::convert(duration));
}
PassRefPtr<Animation> Animation::create(Element* element, PassRefPtr<AnimationEffect> effect)
{
    ASSERT(RuntimeEnabledFeatures::webAnimationsAPIEnabled());
    return create(element, effect, Timing());
}
PassRefPtr<Animation> Animation::create(Element* element, const Vector<Dictionary>& keyframeDictionaryVector, const Dictionary& timingInputDictionary, ExceptionState& exceptionState)
{
    ASSERT(RuntimeEnabledFeatures::webAnimationsAPIEnabled());
    if (element)
        UseCounter::count(element->document(), UseCounter::AnimationConstructorKeyframeListEffectObjectTiming);
    return create(element, EffectInput::convert(element, keyframeDictionaryVector, exceptionState), TimingInput::convert(timingInputDictionary));
}
PassRefPtr<Animation> Animation::create(Element* element, const Vector<Dictionary>& keyframeDictionaryVector, double duration, ExceptionState& exceptionState)
{
    ASSERT(RuntimeEnabledFeatures::webAnimationsAPIEnabled());
    if (element)
        UseCounter::count(element->document(), UseCounter::AnimationConstructorKeyframeListEffectDoubleTiming);
    return create(element, EffectInput::convert(element, keyframeDictionaryVector, exceptionState), TimingInput::convert(duration));
}
PassRefPtr<Animation> Animation::create(Element* element, const Vector<Dictionary>& keyframeDictionaryVector, ExceptionState& exceptionState)
{
    ASSERT(RuntimeEnabledFeatures::webAnimationsAPIEnabled());
    if (element)
        UseCounter::count(element->document(), UseCounter::AnimationConstructorKeyframeListEffectNoTiming);
    return create(element, EffectInput::convert(element, keyframeDictionaryVector, exceptionState), Timing());
}

Animation::Animation(Element* target, PassRefPtr<AnimationEffect> effect, const Timing& timing, Priority priority, PassOwnPtr<EventDelegate> eventDelegate)
    : AnimationNode(timing, eventDelegate)
    , m_target(target)
    , m_effect(effect)
    , m_sampledEffect(nullptr)
    , m_priority(priority)
{
    if (m_target)
        m_target->ensureActiveAnimations().addAnimation(this);
}

Animation::~Animation()
{
    if (m_target)
        m_target->activeAnimations()->notifyAnimationDestroyed(this);
}

void Animation::attach(AnimationPlayer* player)
{
    if (m_target) {
        m_target->ensureActiveAnimations().players().add(player);
        m_target->setNeedsAnimationStyleRecalc();
    }
    AnimationNode::attach(player);
}

void Animation::detach()
{
    if (m_target)
        m_target->activeAnimations()->players().remove(player());
    if (m_sampledEffect)
        clearEffects();
    AnimationNode::detach();
}

void Animation::specifiedTimingChanged()
{
    if (player()) {
        // FIXME: Needs to consider groups when added.
        ASSERT(player()->source() == this);
        player()->setCompositorPending(true);
    }
}

static AnimationStack& ensureAnimationStack(Element* element)
{
    return element->ensureActiveAnimations().defaultStack();
}

void Animation::applyEffects()
{
    ASSERT(isInEffect());
    ASSERT(player());
    if (!m_target || !m_effect)
        return;

    double iteration = currentIteration();
    ASSERT(iteration >= 0);
    // FIXME: Handle iteration values which overflow int.
    OwnPtr<Vector<RefPtr<Interpolation> > > interpolations = m_effect->sample(static_cast<int>(iteration), timeFraction(), iterationDuration());
    if (m_sampledEffect) {
        m_sampledEffect->setInterpolations(interpolations.release());
    } else if (!interpolations->isEmpty()) {
        OwnPtr<SampledEffect> sampledEffect = SampledEffect::create(this, interpolations.release());
        m_sampledEffect = sampledEffect.get();
        ensureAnimationStack(m_target).add(sampledEffect.release());
    } else {
        return;
    }

    m_target->setNeedsAnimationStyleRecalc();
}

void Animation::clearEffects()
{
    ASSERT(player());
    ASSERT(m_sampledEffect);

    m_sampledEffect->clear();
    m_sampledEffect = nullptr;
    cancelAnimationOnCompositor();
    m_target->setNeedsAnimationStyleRecalc();
    invalidate();
}

void Animation::updateChildrenAndEffects() const
{
    if (!m_effect)
        return;
    if (isInEffect())
        const_cast<Animation*>(this)->applyEffects();
    else if (m_sampledEffect)
        const_cast<Animation*>(this)->clearEffects();
}

double Animation::calculateTimeToEffectChange(bool forwards, double localTime, double timeToNextIteration) const
{
    const double start = startTimeInternal() + specifiedTiming().startDelay;
    const double end = start + activeDurationInternal();

    switch (phase()) {
    case PhaseBefore:
        ASSERT(start >= localTime);
        return forwards
            ? start - localTime
            : std::numeric_limits<double>::infinity();
    case PhaseActive:
        if (forwards && hasActiveAnimationsOnCompositor()) {
            ASSERT(specifiedTiming().playbackRate == 1);
            // Need service to apply fill / fire events.
            const double timeToEnd = end - localTime;
            if (hasEvents()) {
                return std::min(timeToEnd, timeToNextIteration);
            } else {
                return timeToEnd;
            }
        }
        return 0;
    case PhaseAfter:
        ASSERT(localTime >= end);
        // If this Animation is still in effect then it will need to update
        // when its parent goes out of effect. We have no way of knowing when
        // that will be, however, so the parent will need to supply it.
        return forwards
            ? std::numeric_limits<double>::infinity()
            : localTime - end;
    default:
        ASSERT_NOT_REACHED();
        return std::numeric_limits<double>::infinity();
    }
}

void Animation::notifySampledEffectRemovedFromAnimationStack()
{
    ASSERT(m_sampledEffect);
    m_sampledEffect = nullptr;
}

void Animation::notifyElementDestroyed()
{
    // If our player is kept alive just by the sampledEffect, we might get our
    // destructor called when we call SampledEffect::clear(), so we need to
    // clear m_sampledEffect first.
    m_target = nullptr;
    clearEventDelegate();
    SampledEffect* sampledEffect = m_sampledEffect;
    m_sampledEffect = nullptr;
    if (sampledEffect)
        sampledEffect->clear();
}

bool Animation::isCandidateForAnimationOnCompositor() const
{
    if (!effect() || !m_target)
        return false;
    return CompositorAnimations::instance()->isCandidateForAnimationOnCompositor(specifiedTiming(), *effect());
}

bool Animation::maybeStartAnimationOnCompositor(double startTime, double currentTime)
{
    ASSERT(!hasActiveAnimationsOnCompositor());
    if (!isCandidateForAnimationOnCompositor())
        return false;
    if (!CompositorAnimations::instance()->canStartAnimationOnCompositor(*m_target))
        return false;
    if (!CompositorAnimations::instance()->startAnimationOnCompositor(*m_target, startTime, currentTime, specifiedTiming(), *effect(), m_compositorAnimationIds))
        return false;
    ASSERT(!m_compositorAnimationIds.isEmpty());
    return true;
}

bool Animation::hasActiveAnimationsOnCompositor() const
{
    return !m_compositorAnimationIds.isEmpty();
}

bool Animation::hasActiveAnimationsOnCompositor(CSSPropertyID property) const
{
    return hasActiveAnimationsOnCompositor() && affects(property);
}

bool Animation::affects(CSSPropertyID property) const
{
    return m_effect && m_effect->affects(property);
}

void Animation::cancelAnimationOnCompositor()
{
    if (!hasActiveAnimationsOnCompositor())
        return;
    if (!m_target || !m_target->renderer())
        return;
    for (size_t i = 0; i < m_compositorAnimationIds.size(); ++i)
        CompositorAnimations::instance()->cancelAnimationOnCompositor(*m_target, m_compositorAnimationIds[i]);
    m_compositorAnimationIds.clear();
    player()->setCompositorPending(true);
}

void Animation::pauseAnimationForTestingOnCompositor(double pauseTime)
{
    ASSERT(hasActiveAnimationsOnCompositor());
    if (!m_target || !m_target->renderer())
        return;
    for (size_t i = 0; i < m_compositorAnimationIds.size(); ++i)
        CompositorAnimations::instance()->pauseAnimationForTestingOnCompositor(*m_target, m_compositorAnimationIds[i], pauseTime);
}

} // namespace blink
