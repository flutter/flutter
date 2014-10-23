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
#include "core/animation/css/CSSAnimations.h"

#include "core/StylePropertyShorthand.h"
#include "core/animation/ActiveAnimations.h"
#include "core/animation/AnimationTimeline.h"
#include "core/animation/CompositorAnimations.h"
#include "core/animation/KeyframeEffectModel.h"
#include "core/animation/LegacyStyleInterpolation.h"
#include "core/animation/css/CSSAnimatableValueFactory.h"
#include "core/animation/css/CSSPropertyEquality.h"
#include "core/css/CSSKeyframeRule.h"
#include "core/css/CSSPropertyMetadata.h"
#include "core/css/CSSValueList.h"
#include "core/css/resolver/CSSToStyleMap.h"
#include "core/css/resolver/StyleResolver.h"
#include "core/dom/Element.h"
#include "core/dom/StyleEngine.h"
#include "core/events/AnimationEvent.h"
#include "core/events/TransitionEvent.h"
#include "core/frame/UseCounter.h"
#include "core/rendering/RenderLayer.h"
#include "core/rendering/RenderObject.h"
#include "core/rendering/style/KeyframeList.h"
#include "platform/animation/TimingFunction.h"
#include "public/platform/Platform.h"
#include "wtf/BitArray.h"
#include "wtf/HashSet.h"

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

static void resolveKeyframes(StyleResolver* resolver, Element* element, const Element& parentElement, const RenderStyle& style, RenderStyle* parentStyle, const AtomicString& name, TimingFunction* defaultTimingFunction,
    AnimatableValueKeyframeVector& keyframes)
{
    // When the element is null, use its parent for scoping purposes.
    const Element* elementForScoping = element ? element : &parentElement;
    const StyleRuleKeyframes* keyframesRule = CSSAnimations::matchScopedKeyframesRule(resolver, elementForScoping, name.impl());
    if (!keyframesRule)
        return;

    const WillBeHeapVector<RefPtrWillBeMember<StyleKeyframe> >& styleKeyframes = keyframesRule->keyframes();
    if (styleKeyframes.isEmpty())
        return;

    // Construct and populate the style for each keyframe
    PropertySet specifiedPropertiesForUseCounter;
    for (size_t i = 0; i < styleKeyframes.size(); ++i) {
        const StyleKeyframe* styleKeyframe = styleKeyframes[i].get();
        // It's OK to pass a null element here.
        RefPtr<RenderStyle> keyframeStyle = resolver->styleForKeyframe(element, style, parentStyle, styleKeyframe, name);
        RefPtrWillBeRawPtr<AnimatableValueKeyframe> keyframe = AnimatableValueKeyframe::create();
        const Vector<double>& offsets = styleKeyframe->keys();
        ASSERT(!offsets.isEmpty());
        keyframe->setOffset(offsets[0]);
        keyframe->setEasing(defaultTimingFunction);
        const StylePropertySet& properties = styleKeyframe->properties();
        for (unsigned j = 0; j < properties.propertyCount(); j++) {
            specifiedPropertiesForUseCounter.add(properties.propertyAt(j).id());
            CSSPropertyID property = propertyForAnimation(properties.propertyAt(j).id());
            if (property == CSSPropertyWebkitAnimationTimingFunction || property == CSSPropertyAnimationTimingFunction) {
                CSSValue* value = properties.propertyAt(j).value();
                RefPtr<TimingFunction> timingFunction;
                if (value->isInheritedValue() && parentStyle->animations())
                    timingFunction = parentStyle->animations()->timingFunctionList()[0];
                else if (value->isInheritedValue() || value->isInitialValue())
                    timingFunction = CSSTimingData::initialTimingFunction();
                else
                    timingFunction = CSSToStyleMap::mapAnimationTimingFunction(toCSSValueList(value)->item(0));
                keyframe->setEasing(timingFunction.release());
            } else if (CSSPropertyMetadata::isAnimatableProperty(property)) {
                keyframe->setPropertyValue(property, CSSAnimatableValueFactory::create(property, *keyframeStyle).get());
            }
        }
        keyframes.append(keyframe);
        // The last keyframe specified at a given offset is used.
        for (size_t j = 1; j < offsets.size(); ++j) {
            keyframes.append(toAnimatableValueKeyframe(keyframe->cloneWithOffset(offsets[j]).get()));
        }
    }
    ASSERT(!keyframes.isEmpty());

    // Remove duplicate keyframes. In CSS the last keyframe at a given offset takes priority.
    std::stable_sort(keyframes.begin(), keyframes.end(), Keyframe::compareOffsets);
    size_t targetIndex = 0;
    for (size_t i = 1; i < keyframes.size(); i++) {
        if (keyframes[i]->offset() != keyframes[targetIndex]->offset())
            targetIndex++;
        if (targetIndex != i)
            keyframes[targetIndex] = keyframes[i];
    }
    keyframes.shrink(targetIndex + 1);

    // Add 0% and 100% keyframes if absent.
    RefPtrWillBeRawPtr<AnimatableValueKeyframe> startKeyframe = keyframes[0];
    if (startKeyframe->offset()) {
        startKeyframe = AnimatableValueKeyframe::create();
        startKeyframe->setOffset(0);
        startKeyframe->setEasing(defaultTimingFunction);
        keyframes.prepend(startKeyframe);
    }
    RefPtrWillBeRawPtr<AnimatableValueKeyframe> endKeyframe = keyframes[keyframes.size() - 1];
    if (endKeyframe->offset() != 1) {
        endKeyframe = AnimatableValueKeyframe::create();
        endKeyframe->setOffset(1);
        endKeyframe->setEasing(defaultTimingFunction);
        keyframes.append(endKeyframe);
    }
    ASSERT(keyframes.size() >= 2);
    ASSERT(!keyframes.first()->offset());
    ASSERT(keyframes.last()->offset() == 1);

    // Snapshot current property values for 0% and 100% if missing.
    PropertySet allProperties;
    size_t numKeyframes = keyframes.size();
    for (size_t i = 0; i < numKeyframes; i++) {
        const PropertySet& keyframeProperties = keyframes[i]->properties();
        for (PropertySet::const_iterator iter = keyframeProperties.begin(); iter != keyframeProperties.end(); ++iter)
            allProperties.add(*iter);
    }
    const PropertySet& startKeyframeProperties = startKeyframe->properties();
    const PropertySet& endKeyframeProperties = endKeyframe->properties();
    bool missingStartValues = startKeyframeProperties.size() < allProperties.size();
    bool missingEndValues = endKeyframeProperties.size() < allProperties.size();
    if (missingStartValues || missingEndValues) {
        for (PropertySet::const_iterator iter = allProperties.begin(); iter != allProperties.end(); ++iter) {
            const CSSPropertyID property = *iter;
            bool startNeedsValue = missingStartValues && !startKeyframeProperties.contains(property);
            bool endNeedsValue = missingEndValues && !endKeyframeProperties.contains(property);
            if (!startNeedsValue && !endNeedsValue)
                continue;
            RefPtrWillBeRawPtr<AnimatableValue> snapshotValue = CSSAnimatableValueFactory::create(property, style);
            if (startNeedsValue)
                startKeyframe->setPropertyValue(property, snapshotValue.get());
            if (endNeedsValue)
                endKeyframe->setPropertyValue(property, snapshotValue.get());
        }
    }
    ASSERT(startKeyframe->properties().size() == allProperties.size());
    ASSERT(endKeyframe->properties().size() == allProperties.size());
}

} // namespace

const StyleRuleKeyframes* CSSAnimations::matchScopedKeyframesRule(StyleResolver* resolver, const Element* element, const StringImpl* animationName)
{
    // FIXME: This is all implementation detail of style resolver, CSSAnimations shouldn't be reaching into any of it.
    if (resolver->document().styleEngine()->hasOnlyScopedResolverForDocument())
        return element->document().scopedStyleResolver()->keyframeStylesForAnimation(animationName);

    WillBeHeapVector<RawPtrWillBeMember<ScopedStyleResolver>, 8> stack;
    resolver->styleTreeResolveScopedKeyframesRules(element, stack);
    if (stack.isEmpty())
        return 0;

    for (size_t i = 0; i < stack.size(); ++i) {
        if (const StyleRuleKeyframes* keyframesRule = stack.at(i)->keyframeStylesForAnimation(animationName))
            return keyframesRule;
    }
    return 0;
}

CSSAnimations::CSSAnimations()
{
}

PassOwnPtrWillBeRawPtr<CSSAnimationUpdate> CSSAnimations::calculateUpdate(Element* element, const Element& parentElement, const RenderStyle& style, RenderStyle* parentStyle, StyleResolver* resolver)
{
    OwnPtrWillBeRawPtr<CSSAnimationUpdate> update = adoptPtrWillBeNoop(new CSSAnimationUpdate());
    calculateAnimationUpdate(update.get(), element, parentElement, style, parentStyle, resolver);
    calculateAnimationActiveInterpolations(update.get(), element, parentElement.document().timeline().currentTimeInternal());
    calculateTransitionUpdate(update.get(), element, style);
    calculateTransitionActiveInterpolations(update.get(), element, parentElement.document().timeline().currentTimeInternal());
    return update->isEmpty() ? nullptr : update.release();
}

void CSSAnimations::calculateAnimationUpdate(CSSAnimationUpdate* update, Element* element, const Element& parentElement, const RenderStyle& style, RenderStyle* parentStyle, StyleResolver* resolver)
{
    const ActiveAnimations* activeAnimations = element ? element->activeAnimations() : 0;

#if !ENABLE(ASSERT)
    // If we're in an animation style change, no animations can have started, been cancelled or changed play state.
    // When ASSERT is enabled, we verify this optimization.
    if (activeAnimations && activeAnimations->isAnimationStyleChange())
        return;
#endif

    const CSSAnimationData* animationData = style.animations();
    const CSSAnimations* cssAnimations = activeAnimations ? &activeAnimations->cssAnimations() : 0;

    HashSet<AtomicString> inactive;
    if (cssAnimations)
        for (AnimationMap::const_iterator iter = cssAnimations->m_animations.begin(); iter != cssAnimations->m_animations.end(); ++iter)
            inactive.add(iter->key);

    if (style.display() != NONE) {
        for (size_t i = 0; animationData && i < animationData->nameList().size(); ++i) {
            AtomicString animationName(animationData->nameList()[i]);
            if (animationName == CSSAnimationData::initialName())
                continue;

            bool isPaused = CSSTimingData::getRepeated(animationData->playStateList(), i) == AnimPlayStatePaused;

            // Keyframes and animation properties are snapshotted when the
            // animation starts, so we don't need to track changes to these,
            // with the exception of play-state.
            if (cssAnimations) {
                AnimationMap::const_iterator existing(cssAnimations->m_animations.find(animationName));
                if (existing != cssAnimations->m_animations.end()) {
                    inactive.remove(animationName);
                    AnimationPlayer* player = existing->value.get();
                    if (isPaused != player->paused()) {
                        ASSERT(!activeAnimations || !activeAnimations->isAnimationStyleChange());
                        update->toggleAnimationPaused(animationName);
                    }
                    continue;
                }
            }

            Timing timing = animationData->convertToTiming(i);
            RefPtr<TimingFunction> keyframeTimingFunction = timing.timingFunction;
            timing.timingFunction = Timing::defaults().timingFunction;
            AnimatableValueKeyframeVector resolvedKeyframes;
            resolveKeyframes(resolver, element, parentElement, style, parentStyle, animationName, keyframeTimingFunction.get(), resolvedKeyframes);
            if (!resolvedKeyframes.isEmpty()) {
                ASSERT(!activeAnimations || !activeAnimations->isAnimationStyleChange());
                update->startAnimation(animationName, InertAnimation::create(AnimatableValueKeyframeEffectModel::create(resolvedKeyframes), timing, isPaused));
            }
        }
    }

    ASSERT(inactive.isEmpty() || cssAnimations);
    for (HashSet<AtomicString>::const_iterator iter = inactive.begin(); iter != inactive.end(); ++iter) {
        ASSERT(!activeAnimations || !activeAnimations->isAnimationStyleChange());
        update->cancelAnimation(*iter, *cssAnimations->m_animations.get(*iter));
    }
}

void CSSAnimations::maybeApplyPendingUpdate(Element* element)
{
    if (!m_pendingUpdate) {
        m_previousActiveInterpolationsForAnimations.clear();
        return;
    }

    OwnPtrWillBeRawPtr<CSSAnimationUpdate> update = m_pendingUpdate.release();

    m_previousActiveInterpolationsForAnimations.swap(update->activeInterpolationsForAnimations());

    // FIXME: cancelling, pausing, unpausing animations all query compositingState, which is not necessarily up to date here
    // since we call this from recalc style.
    // https://code.google.com/p/chromium/issues/detail?id=339847
    DisableCompositingQueryAsserts disabler;

    for (Vector<AtomicString>::const_iterator iter = update->cancelledAnimationNames().begin(); iter != update->cancelledAnimationNames().end(); ++iter) {
        RefPtrWillBeRawPtr<AnimationPlayer> player = m_animations.take(*iter);
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

    for (WillBeHeapVector<CSSAnimationUpdate::NewAnimation>::const_iterator iter = update->newAnimations().begin(); iter != update->newAnimations().end(); ++iter) {
        const InertAnimation* inertAnimation = iter->animation.get();
        OwnPtrWillBeRawPtr<AnimationEventDelegate> eventDelegate = adoptPtrWillBeNoop(new AnimationEventDelegate(element, iter->name));
        RefPtrWillBeRawPtr<Animation> animation = Animation::create(element, inertAnimation->effect(), inertAnimation->specifiedTiming(), Animation::DefaultPriority, eventDelegate.release());
        RefPtrWillBeRawPtr<AnimationPlayer> player = element->document().timeline().createAnimationPlayer(animation.get());
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
    WillBeHeapHashMap<CSSPropertyID, std::pair<RefPtrWillBeMember<Animation>, double> > retargetedCompositorTransitions;
    for (HashSet<CSSPropertyID>::iterator iter = update->cancelledTransitions().begin(); iter != update->cancelledTransitions().end(); ++iter) {
        CSSPropertyID id = *iter;
        ASSERT(m_transitions.contains(id));

        RefPtrWillBeRawPtr<AnimationPlayer> player = m_transitions.take(id).player;
        Animation* animation = toAnimation(player->source());
        if (animation->hasActiveAnimationsOnCompositor(id) && update->newTransitions().find(id) != update->newTransitions().end())
            retargetedCompositorTransitions.add(id, std::pair<RefPtrWillBeMember<Animation>, double>(animation, player->startTimeInternal()));
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
        OwnPtrWillBeRawPtr<TransitionEventDelegate> eventDelegate = adoptPtrWillBeNoop(new TransitionEventDelegate(element, newTransition.eventId));

        RefPtrWillBeRawPtr<AnimationEffect> effect = inertAnimation->effect();

        if (retargetedCompositorTransitions.contains(id)) {
            const std::pair<RefPtrWillBeMember<Animation>, double>& oldTransition = retargetedCompositorTransitions.get(id);
            RefPtrWillBeRawPtr<Animation> oldAnimation = oldTransition.first;
            double oldStartTime = oldTransition.second;
            double inheritedTime = isNull(oldStartTime) ? 0 : element->document().timeline().currentTimeInternal() - oldStartTime;

            AnimatableValueKeyframeEffectModel* oldEffect = toAnimatableValueKeyframeEffectModel(inertAnimation->effect());
            const KeyframeVector& frames = oldEffect->getFrames();

            AnimatableValueKeyframeVector newFrames;
            newFrames.append(toAnimatableValueKeyframe(frames[0]->clone().get()));
            newFrames.append(toAnimatableValueKeyframe(frames[1]->clone().get()));

            newFrames[0]->clearPropertyValue(id);
            RefPtrWillBeRawPtr<InertAnimation> inertAnimationForSampling = InertAnimation::create(oldAnimation->effect(), oldAnimation->specifiedTiming(), false);
            OwnPtrWillBeRawPtr<WillBeHeapVector<RefPtrWillBeMember<Interpolation> > > sample = inertAnimationForSampling->sample(inheritedTime);
            ASSERT(sample->size() == 1);
            newFrames[0]->setPropertyValue(id, toLegacyStyleInterpolation(sample->at(0).get())->currentValue());

            effect = AnimatableValueKeyframeEffectModel::create(newFrames);
        }

        RefPtrWillBeRawPtr<Animation> transition = Animation::create(element, effect, inertAnimation->specifiedTiming(), Animation::TransitionPriority, eventDelegate.release());
        RefPtrWillBeRawPtr<AnimationPlayer> player = element->document().timeline().createAnimationPlayer(transition.get());
        player->update(TimingUpdateOnDemand);
        runningTransition.player = player;
        m_transitions.set(id, runningTransition);
        ASSERT(id != CSSPropertyInvalid);
    }
}

void CSSAnimations::calculateTransitionUpdateForProperty(CSSPropertyID id, CSSPropertyID eventId, const CSSTransitionData& transitionData, size_t transitionIndex, const RenderStyle& oldStyle, const RenderStyle& style, const TransitionMap* activeTransitions, CSSAnimationUpdate* update, const Element* element)
{
    RefPtrWillBeRawPtr<AnimatableValue> to = nullptr;
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

    RefPtrWillBeRawPtr<AnimatableValue> from = CSSAnimatableValueFactory::create(id, oldStyle);
    // If we have multiple transitions on the same property, we will use the
    // last one since we iterate over them in order.
    if (AnimatableValue::usesDefaultInterpolation(to.get(), from.get()))
        return;

    Timing timing = transitionData.convertToTiming(transitionIndex);
    if (timing.startDelay + timing.iterationDuration <= 0)
        return;

    AnimatableValueKeyframeVector keyframes;

    RefPtrWillBeRawPtr<AnimatableValueKeyframe> startKeyframe = AnimatableValueKeyframe::create();
    startKeyframe->setPropertyValue(id, from.get());
    startKeyframe->setOffset(0);
    startKeyframe->setEasing(timing.timingFunction.release());
    timing.timingFunction = LinearTimingFunction::shared();
    keyframes.append(startKeyframe);

    RefPtrWillBeRawPtr<AnimatableValueKeyframe> endKeyframe = AnimatableValueKeyframe::create();
    endKeyframe->setPropertyValue(id, to.get());
    endKeyframe->setOffset(1);
    keyframes.append(endKeyframe);

    RefPtrWillBeRawPtr<AnimatableValueKeyframeEffectModel> effect = AnimatableValueKeyframeEffectModel::create(keyframes);
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

                // FIXME: We should transition if an !important property changes even when an animation is running,
                // but this is a bit hard to do with the current applyMatchedProperties system.
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

    if (update->newAnimations().isEmpty() && update->cancelledAnimationAnimationPlayers().isEmpty()) {
        WillBeHeapHashMap<CSSPropertyID, RefPtrWillBeMember<Interpolation> > activeInterpolationsForAnimations(AnimationStack::activeInterpolations(animationStack, 0, 0, Animation::DefaultPriority, timelineCurrentTime));
        update->adoptActiveInterpolationsForAnimations(activeInterpolationsForAnimations);
        return;
    }

    WillBeHeapVector<RawPtrWillBeMember<InertAnimation> > newAnimations;
    for (size_t i = 0; i < update->newAnimations().size(); ++i) {
        newAnimations.append(update->newAnimations()[i].animation.get());
    }
    WillBeHeapHashMap<CSSPropertyID, RefPtrWillBeMember<Interpolation> > activeInterpolationsForAnimations(AnimationStack::activeInterpolations(animationStack, &newAnimations, &update->cancelledAnimationAnimationPlayers(), Animation::DefaultPriority, timelineCurrentTime));
    update->adoptActiveInterpolationsForAnimations(activeInterpolationsForAnimations);
}

void CSSAnimations::calculateTransitionActiveInterpolations(CSSAnimationUpdate* update, const Element* element, double timelineCurrentTime)
{
    ActiveAnimations* activeAnimations = element ? element->activeAnimations() : 0;
    AnimationStack* animationStack = activeAnimations ? &activeAnimations->defaultStack() : 0;

    WillBeHeapHashMap<CSSPropertyID, RefPtrWillBeMember<Interpolation> > activeInterpolationsForTransitions;
    if (update->newTransitions().isEmpty() && update->cancelledTransitions().isEmpty()) {
        activeInterpolationsForTransitions = AnimationStack::activeInterpolations(animationStack, 0, 0, Animation::TransitionPriority, timelineCurrentTime);
    } else {
        WillBeHeapVector<RawPtrWillBeMember<InertAnimation> > newTransitions;
        for (CSSAnimationUpdate::NewTransitionMap::const_iterator iter = update->newTransitions().begin(); iter != update->newTransitions().end(); ++iter)
            newTransitions.append(iter->value.animation.get());

        WillBeHeapHashSet<RawPtrWillBeMember<const AnimationPlayer> > cancelledAnimationPlayers;
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
        for (WillBeHeapHashMap<CSSPropertyID, RefPtrWillBeMember<Interpolation> >::const_iterator iter = update->activeInterpolationsForAnimations().begin(); iter != update->activeInterpolationsForAnimations().end(); ++iter)
            activeInterpolationsForTransitions.remove(iter->key);
    }
    update->adoptActiveInterpolationsForTransitions(activeInterpolationsForTransitions);
}

void CSSAnimations::AnimationEventDelegate::maybeDispatch(Document::ListenerType listenerType, const AtomicString& eventName, double elapsedTime)
{
    if (m_target->document().hasListenerType(listenerType)) {
        RefPtrWillBeRawPtr<AnimationEvent> event = AnimationEvent::create(eventName, m_name, elapsedTime);
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

void CSSAnimations::AnimationEventDelegate::trace(Visitor* visitor)
{
    visitor->trace(m_target);
    AnimationNode::EventDelegate::trace(visitor);
}

void CSSAnimations::TransitionEventDelegate::onEventCondition(const AnimationNode* animationNode)
{
    const AnimationNode::Phase currentPhase = animationNode->phase();
    if (currentPhase == AnimationNode::PhaseAfter && currentPhase != m_previousPhase && m_target->document().hasListenerType(Document::TRANSITIONEND_LISTENER)) {
        String propertyName = getPropertyNameString(m_property);
        const Timing& timing = animationNode->specifiedTiming();
        double elapsedTime = timing.iterationDuration;
        const AtomicString& eventType = EventTypeNames::transitionend;
        RefPtrWillBeRawPtr<TransitionEvent> event = TransitionEvent::create(eventType, propertyName, elapsedTime);
        event->setTarget(m_target);
        m_target->document().enqueueAnimationFrameEvent(event);
    }

    m_previousPhase = currentPhase;
}

void CSSAnimations::TransitionEventDelegate::trace(Visitor* visitor)
{
    visitor->trace(m_target);
    AnimationNode::EventDelegate::trace(visitor);
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
    case CSSPropertyWebkitAnimation:
    case CSSPropertyWebkitAnimationDelay:
    case CSSPropertyWebkitAnimationDirection:
    case CSSPropertyWebkitAnimationDuration:
    case CSSPropertyWebkitAnimationFillMode:
    case CSSPropertyWebkitAnimationIterationCount:
    case CSSPropertyWebkitAnimationName:
    case CSSPropertyWebkitAnimationPlayState:
    case CSSPropertyWebkitAnimationTimingFunction:
    case CSSPropertyWebkitTransition:
    case CSSPropertyWebkitTransitionDelay:
    case CSSPropertyWebkitTransitionDuration:
    case CSSPropertyWebkitTransitionProperty:
    case CSSPropertyWebkitTransitionTimingFunction:
        return false;
    default:
        return true;
    }
}

void CSSAnimations::trace(Visitor* visitor)
{
#if ENABLE(OILPAN)
    visitor->trace(m_transitions);
    visitor->trace(m_pendingUpdate);
    visitor->trace(m_animations);
    visitor->trace(m_previousActiveInterpolationsForAnimations);
#endif
}

void CSSAnimationUpdate::trace(Visitor* visitor)
{
#if ENABLE(OILPAN)
    visitor->trace(m_newTransitions);
    visitor->trace(m_activeInterpolationsForAnimations);
    visitor->trace(m_activeInterpolationsForTransitions);
    visitor->trace(m_newAnimations);
    visitor->trace(m_cancelledAnimationPlayers);
#endif
}

} // namespace blink
