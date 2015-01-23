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
#include "sky/engine/core/animation/css/CSSAnimations.h"

#include "gen/sky/core/StylePropertyShorthand.h"
#include "sky/engine/core/animation/ActiveAnimations.h"
#include "sky/engine/core/animation/AnimationTimeline.h"
#include "sky/engine/core/animation/KeyframeEffectModel.h"
#include "sky/engine/core/animation/LegacyStyleInterpolation.h"
#include "sky/engine/core/animation/css/CSSAnimatableValueFactory.h"
#include "sky/engine/core/animation/css/CSSPropertyEquality.h"
#include "sky/engine/core/css/CSSPropertyMetadata.h"
#include "sky/engine/core/css/CSSValueList.h"
#include "sky/engine/core/css/StyleKeyframe.h"
#include "sky/engine/core/css/StyleRuleKeyframes.h"
#include "sky/engine/core/dom/Element.h"
#include "sky/engine/core/events/AnimationEvent.h"
#include "sky/engine/core/events/TransitionEvent.h"
#include "sky/engine/core/rendering/RenderLayer.h"
#include "sky/engine/core/rendering/RenderObject.h"
#include "sky/engine/core/rendering/style/KeyframeList.h"
#include "sky/engine/platform/animation/TimingFunction.h"
#include "sky/engine/public/platform/Platform.h"
#include "sky/engine/wtf/BitArray.h"
#include "sky/engine/wtf/HashSet.h"

namespace blink {

namespace {

CSSPropertyID propertyForAnimation(CSSPropertyID property)
{
    switch (property) {
    case CSSPropertyWebkitPerspective:
        return CSSPropertyPerspective;
    case CSSPropertyWebkitTransform:
        return CSSPropertyTransform;
    case CSSPropertyWebkitPerspectiveOriginX:
    case CSSPropertyWebkitPerspectiveOriginY:
        return CSSPropertyPerspectiveOrigin;
    case CSSPropertyWebkitTransformOriginX:
    case CSSPropertyWebkitTransformOriginY:
    case CSSPropertyWebkitTransformOriginZ:
        return CSSPropertyTransformOrigin;
    default:
        break;
    }
    return property;
}

} // namespace

CSSAnimations::CSSAnimations()
{
}

PassOwnPtr<CSSAnimationUpdate> CSSAnimations::calculateUpdate(Element* element, const Element& parentElement, const RenderStyle& style, RenderStyle* parentStyle)
{
    OwnPtr<CSSAnimationUpdate> update = adoptPtr(new CSSAnimationUpdate());
    calculateAnimationActiveInterpolations(update.get(), element, parentElement.document().timeline().currentTimeInternal());
    calculateTransitionUpdate(update.get(), element, style);
    calculateTransitionActiveInterpolations(update.get(), element, parentElement.document().timeline().currentTimeInternal());
    return update->isEmpty() ? nullptr : update.release();
}

void CSSAnimations::maybeApplyPendingUpdate(Element* element)
{
    if (!m_pendingUpdate) {
        m_previousActiveInterpolationsForAnimations.clear();
        return;
    }

    OwnPtr<CSSAnimationUpdate> update = m_pendingUpdate.release();

    m_previousActiveInterpolationsForAnimations.swap(update->activeInterpolationsForAnimations());

    for (Vector<AtomicString>::const_iterator iter = update->cancelledAnimationNames().begin(); iter != update->cancelledAnimationNames().end(); ++iter) {
        RefPtr<AnimationPlayer> player = m_animations.take(*iter);
        player->cancel();
        player->update(TimingUpdateOnDemand);
    }

    for (Vector<AtomicString>::const_iterator iter = update->animationsWithPauseToggled().begin(); iter != update->animationsWithPauseToggled().end(); ++iter) {
        AnimationPlayer* player = m_animations.get(*iter);
        if (player->paused())
            player->unpause();
        else
            player->pause();
        if (player->outdated())
            player->update(TimingUpdateOnDemand);
    }

    for (Vector<CSSAnimationUpdate::NewAnimation>::const_iterator iter = update->newAnimations().begin(); iter != update->newAnimations().end(); ++iter) {
        const InertAnimation* inertAnimation = iter->animation.get();
        OwnPtr<AnimationEventDelegate> eventDelegate = adoptPtr(new AnimationEventDelegate(element, iter->name));
        RefPtr<Animation> animation = Animation::create(element, inertAnimation->effect(), inertAnimation->specifiedTiming(), Animation::DefaultPriority, eventDelegate.release());
        RefPtr<AnimationPlayer> player = element->document().timeline().createAnimationPlayer(animation.get());
        if (inertAnimation->paused())
            player->pause();
        player->update(TimingUpdateOnDemand);
        m_animations.set(iter->name, player.get());
    }

    // Transitions that are run on the compositor only update main-thread state
    // lazily. However, we need the new state to know what the from state shoud
    // be when transitions are retargeted. Instead of triggering complete style
    // recalculation, we find these cases by searching for new transitions that
    // have matching cancelled animation property IDs on the compositor.
    HashMap<CSSPropertyID, std::pair<RefPtr<Animation>, double> > retargetedCompositorTransitions;
    for (HashSet<CSSPropertyID>::iterator iter = update->cancelledTransitions().begin(); iter != update->cancelledTransitions().end(); ++iter) {
        CSSPropertyID id = *iter;
        ASSERT(m_transitions.contains(id));

        RefPtr<AnimationPlayer> player = m_transitions.take(id).player;
        player->cancel();
        player->update(TimingUpdateOnDemand);
    }

    for (CSSAnimationUpdate::NewTransitionMap::const_iterator iter = update->newTransitions().begin(); iter != update->newTransitions().end(); ++iter) {
        const CSSAnimationUpdate::NewTransition& newTransition = iter->value;

        RunningTransition runningTransition;
        runningTransition.from = newTransition.from;
        runningTransition.to = newTransition.to;

        CSSPropertyID id = newTransition.id;
        InertAnimation* inertAnimation = newTransition.animation.get();
        OwnPtr<TransitionEventDelegate> eventDelegate = adoptPtr(new TransitionEventDelegate(element, newTransition.eventId));

        RefPtr<AnimationEffect> effect = inertAnimation->effect();
        RefPtr<Animation> transition = Animation::create(element, effect, inertAnimation->specifiedTiming(), Animation::TransitionPriority, eventDelegate.release());
        RefPtr<AnimationPlayer> player = element->document().timeline().createAnimationPlayer(transition.get());
        player->update(TimingUpdateOnDemand);
        runningTransition.player = player;
        m_transitions.set(id, runningTransition);
        ASSERT(id != CSSPropertyInvalid);
    }
}

void CSSAnimations::calculateTransitionUpdateForProperty(CSSPropertyID id, CSSPropertyID eventId, const CSSTransitionData& transitionData, size_t transitionIndex, const RenderStyle& oldStyle, const RenderStyle& style, const TransitionMap* activeTransitions, CSSAnimationUpdate* update, const Element* element)
{
    RefPtr<AnimatableValue> to = nullptr;
    if (activeTransitions) {
        TransitionMap::const_iterator activeTransitionIter = activeTransitions->find(id);
        if (activeTransitionIter != activeTransitions->end()) {
            to = CSSAnimatableValueFactory::create(id, style);
            const AnimatableValue* activeTo = activeTransitionIter->value.to;
            if (to->equals(activeTo))
                return;
            update->cancelTransition(id);
            ASSERT(!element->activeAnimations() || !element->activeAnimations()->isAnimationStyleChange());
        }
    }

    if (CSSPropertyEquality::propertiesEqual(id, oldStyle, style))
        return;
    if (!to)
        to = CSSAnimatableValueFactory::create(id, style);

    RefPtr<AnimatableValue> from = CSSAnimatableValueFactory::create(id, oldStyle);
    // If we have multiple transitions on the same property, we will use the
    // last one since we iterate over them in order.
    if (AnimatableValue::usesDefaultInterpolation(to.get(), from.get()))
        return;

    Timing timing = transitionData.convertToTiming(transitionIndex);
    if (timing.startDelay + timing.iterationDuration <= 0)
        return;

    AnimatableValueKeyframeVector keyframes;

    RefPtr<AnimatableValueKeyframe> startKeyframe = AnimatableValueKeyframe::create();
    startKeyframe->setPropertyValue(id, from.get());
    startKeyframe->setOffset(0);
    startKeyframe->setEasing(timing.timingFunction.release());
    timing.timingFunction = LinearTimingFunction::shared();
    keyframes.append(startKeyframe);

    RefPtr<AnimatableValueKeyframe> endKeyframe = AnimatableValueKeyframe::create();
    endKeyframe->setPropertyValue(id, to.get());
    endKeyframe->setOffset(1);
    keyframes.append(endKeyframe);

    RefPtr<AnimatableValueKeyframeEffectModel> effect = AnimatableValueKeyframeEffectModel::create(keyframes);
    update->startTransition(id, eventId, from.get(), to.get(), InertAnimation::create(effect, timing, false));
    ASSERT(!element->activeAnimations() || !element->activeAnimations()->isAnimationStyleChange());
}

void CSSAnimations::calculateTransitionUpdate(CSSAnimationUpdate* update, const Element* element, const RenderStyle& style)
{
    if (!element)
        return;

    ActiveAnimations* activeAnimations = element->activeAnimations();
    const TransitionMap* activeTransitions = activeAnimations ? &activeAnimations->cssAnimations().m_transitions : 0;
    const CSSTransitionData* transitionData = style.transitions();

#if ENABLE(ASSERT)
    // In debug builds we verify that it would have been safe to avoid populating and testing listedProperties if the style recalc is due to animation.
    const bool animationStyleRecalc = false;
#else
    // In release builds we avoid the cost of checking for new and interrupted transitions if the style recalc is due to animation.
    const bool animationStyleRecalc = activeAnimations && activeAnimations->isAnimationStyleChange();
#endif

    BitArray<numCSSProperties> listedProperties;
    bool anyTransitionHadTransitionAll = false;
    const RenderObject* renderer = element->renderer();
    if (!animationStyleRecalc && style.display() != NONE && renderer && renderer->style() && transitionData) {
        const RenderStyle& oldStyle = *renderer->style();

        for (size_t i = 0; i < transitionData->propertyList().size(); ++i) {
            const CSSTransitionData::TransitionProperty& transitionProperty = transitionData->propertyList()[i];
            CSSTransitionData::TransitionPropertyType mode = transitionProperty.propertyType;
            CSSPropertyID property = transitionProperty.propertyId;
            if (mode == CSSTransitionData::TransitionNone || mode == CSSTransitionData::TransitionUnknown)
                continue;

            bool animateAll = mode == CSSTransitionData::TransitionAll;
            ASSERT(animateAll || mode == CSSTransitionData::TransitionSingleProperty);
            if (animateAll)
                anyTransitionHadTransitionAll = true;
            const StylePropertyShorthand& propertyList = animateAll ? CSSAnimations::animatableProperties() : shorthandForProperty(property);
            // If not a shorthand we only execute one iteration of this loop, and refer to the property directly.
            for (unsigned j = 0; !j || j < propertyList.length(); ++j) {
                CSSPropertyID id = propertyList.length() ? propertyList.properties()[j] : property;
                CSSPropertyID eventId = id;

                if (!animateAll) {
                    id = propertyForAnimation(id);
                    if (CSSPropertyMetadata::isAnimatableProperty(id))
                        listedProperties.set(id);
                    else
                        continue;
                }

                if (!update->activeInterpolationsForAnimations().contains(id)
                    && (!activeAnimations || !activeAnimations->cssAnimations().m_previousActiveInterpolationsForAnimations.contains(id))) {
                    calculateTransitionUpdateForProperty(id, eventId, *transitionData, i, oldStyle, style, activeTransitions, update, element);
                }
            }
        }
    }

    if (activeTransitions) {
        for (TransitionMap::const_iterator iter = activeTransitions->begin(); iter != activeTransitions->end(); ++iter) {
            const AnimationPlayer& player = *iter->value.player;
            CSSPropertyID id = iter->key;
            if (player.finishedInternal() || (!anyTransitionHadTransitionAll && !animationStyleRecalc && !listedProperties.get(id))) {
                // TODO: Figure out why this fails on Chrome OS login page. crbug.com/365507
                // ASSERT(player.finishedInternal() || !(activeAnimations && activeAnimations->isAnimationStyleChange()));
                update->cancelTransition(id);
            }
        }
    }
}

void CSSAnimations::cancel()
{
    for (AnimationMap::iterator iter = m_animations.begin(); iter != m_animations.end(); ++iter) {
        iter->value->cancel();
        iter->value->update(TimingUpdateOnDemand);
    }

    for (TransitionMap::iterator iter = m_transitions.begin(); iter != m_transitions.end(); ++iter) {
        iter->value.player->cancel();
        iter->value.player->update(TimingUpdateOnDemand);
    }

    m_animations.clear();
    m_transitions.clear();
    m_pendingUpdate = nullptr;
}

void CSSAnimations::calculateAnimationActiveInterpolations(CSSAnimationUpdate* update, const Element* element, double timelineCurrentTime)
{
    ActiveAnimations* activeAnimations = element ? element->activeAnimations() : 0;
    AnimationStack* animationStack = activeAnimations ? &activeAnimations->defaultStack() : 0;

    HashMap<CSSPropertyID, RefPtr<Interpolation> > activeInterpolationsForAnimations(AnimationStack::activeInterpolations(animationStack, 0, 0, Animation::DefaultPriority, timelineCurrentTime));
    update->adoptActiveInterpolationsForAnimations(activeInterpolationsForAnimations);
}

void CSSAnimations::calculateTransitionActiveInterpolations(CSSAnimationUpdate* update, const Element* element, double timelineCurrentTime)
{
    ActiveAnimations* activeAnimations = element ? element->activeAnimations() : 0;
    AnimationStack* animationStack = activeAnimations ? &activeAnimations->defaultStack() : 0;

    HashMap<CSSPropertyID, RefPtr<Interpolation> > activeInterpolationsForTransitions;
    if (update->newTransitions().isEmpty() && update->cancelledTransitions().isEmpty()) {
        activeInterpolationsForTransitions = AnimationStack::activeInterpolations(animationStack, 0, 0, Animation::TransitionPriority, timelineCurrentTime);
    } else {
        Vector<RawPtr<InertAnimation> > newTransitions;
        for (CSSAnimationUpdate::NewTransitionMap::const_iterator iter = update->newTransitions().begin(); iter != update->newTransitions().end(); ++iter)
            newTransitions.append(iter->value.animation.get());

        HashSet<RawPtr<const AnimationPlayer> > cancelledAnimationPlayers;
        if (!update->cancelledTransitions().isEmpty()) {
            ASSERT(activeAnimations);
            const TransitionMap& transitionMap = activeAnimations->cssAnimations().m_transitions;
            for (HashSet<CSSPropertyID>::iterator iter = update->cancelledTransitions().begin(); iter != update->cancelledTransitions().end(); ++iter) {
                ASSERT(transitionMap.contains(*iter));
                cancelledAnimationPlayers.add(transitionMap.get(*iter).player.get());
            }
        }

        activeInterpolationsForTransitions = AnimationStack::activeInterpolations(animationStack, &newTransitions, &cancelledAnimationPlayers, Animation::TransitionPriority, timelineCurrentTime);
    }

    // Properties being animated by animations don't get values from transitions applied.
    if (!update->activeInterpolationsForAnimations().isEmpty() && !activeInterpolationsForTransitions.isEmpty()) {
        for (HashMap<CSSPropertyID, RefPtr<Interpolation> >::const_iterator iter = update->activeInterpolationsForAnimations().begin(); iter != update->activeInterpolationsForAnimations().end(); ++iter)
            activeInterpolationsForTransitions.remove(iter->key);
    }
    update->adoptActiveInterpolationsForTransitions(activeInterpolationsForTransitions);
}

void CSSAnimations::AnimationEventDelegate::maybeDispatch(Document::ListenerType listenerType, const AtomicString& eventName, double elapsedTime)
{
    if (m_target->document().hasListenerType(listenerType)) {
        RefPtr<AnimationEvent> event = AnimationEvent::create(eventName, m_name, elapsedTime);
        event->setTarget(m_target);
        m_target->document().enqueueAnimationFrameEvent(event);
    }
}

void CSSAnimations::AnimationEventDelegate::onEventCondition(const AnimationNode* animationNode)
{
    const AnimationNode::Phase currentPhase = animationNode->phase();
    const double currentIteration = animationNode->currentIteration();

    if (m_previousPhase != currentPhase
        && (currentPhase == AnimationNode::PhaseActive || currentPhase == AnimationNode::PhaseAfter)
        && (m_previousPhase == AnimationNode::PhaseNone || m_previousPhase == AnimationNode::PhaseBefore)) {
        // The spec states that the elapsed time should be
        // 'delay < 0 ? -delay : 0', but we always use 0 to match the existing
        // implementation. See crbug.com/279611
        maybeDispatch(Document::ANIMATIONSTART_LISTENER, EventTypeNames::animationstart, 0);
    }

    if (currentPhase == AnimationNode::PhaseActive && m_previousPhase == currentPhase && m_previousIteration != currentIteration) {
        // We fire only a single event for all iterations thast terminate
        // between a single pair of samples. See http://crbug.com/275263. For
        // compatibility with the existing implementation, this event uses
        // the elapsedTime for the first iteration in question.
        ASSERT(!std::isnan(animationNode->specifiedTiming().iterationDuration));
        const double elapsedTime = animationNode->specifiedTiming().iterationDuration * (m_previousIteration + 1);
        maybeDispatch(Document::ANIMATIONITERATION_LISTENER, EventTypeNames::animationiteration, elapsedTime);
    }

    if (currentPhase == AnimationNode::PhaseAfter && m_previousPhase != AnimationNode::PhaseAfter)
        maybeDispatch(Document::ANIMATIONEND_LISTENER, EventTypeNames::animationend, animationNode->activeDurationInternal());

    m_previousPhase = currentPhase;
    m_previousIteration = currentIteration;
}

void CSSAnimations::TransitionEventDelegate::onEventCondition(const AnimationNode* animationNode)
{
    const AnimationNode::Phase currentPhase = animationNode->phase();
    if (currentPhase == AnimationNode::PhaseAfter && currentPhase != m_previousPhase && m_target->document().hasListenerType(Document::TRANSITIONEND_LISTENER)) {
        String propertyName = getPropertyNameString(m_property);
        const Timing& timing = animationNode->specifiedTiming();
        double elapsedTime = timing.iterationDuration;
        const AtomicString& eventType = EventTypeNames::transitionend;
        RefPtr<TransitionEvent> event = TransitionEvent::create(eventType, propertyName, elapsedTime);
        event->setTarget(m_target);
        m_target->document().enqueueAnimationFrameEvent(event);
    }

    m_previousPhase = currentPhase;
}

const StylePropertyShorthand& CSSAnimations::animatableProperties()
{
    DEFINE_STATIC_LOCAL(Vector<CSSPropertyID>, properties, ());
    DEFINE_STATIC_LOCAL(StylePropertyShorthand, propertyShorthand, ());
    if (properties.isEmpty()) {
        for (int i = firstCSSProperty; i < lastCSSProperty; ++i) {
            CSSPropertyID id = convertToCSSPropertyID(i);
            if (CSSPropertyMetadata::isAnimatableProperty(id))
                properties.append(id);
        }
        propertyShorthand = StylePropertyShorthand(CSSPropertyInvalid, properties.begin(), properties.size());
    }
    return propertyShorthand;
}

// Animation properties are not allowed to be affected by Web Animations.
// http://dev.w3.org/fxtf/web-animations/#not-animatable
bool CSSAnimations::isAllowedAnimation(CSSPropertyID property)
{
    switch (property) {
    case CSSPropertyAnimation:
    case CSSPropertyAnimationDelay:
    case CSSPropertyAnimationDirection:
    case CSSPropertyAnimationDuration:
    case CSSPropertyAnimationFillMode:
    case CSSPropertyAnimationIterationCount:
    case CSSPropertyAnimationName:
    case CSSPropertyAnimationPlayState:
    case CSSPropertyAnimationTimingFunction:
    case CSSPropertyDisplay:
    case CSSPropertyTransition:
    case CSSPropertyTransitionDelay:
    case CSSPropertyTransitionDuration:
    case CSSPropertyTransitionProperty:
    case CSSPropertyTransitionTimingFunction:
        return false;
    default:
        return true;
    }
}

} // namespace blink
