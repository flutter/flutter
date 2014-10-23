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
#include "core/animation/CompositorAnimations.h"

#include "core/animation/AnimationTranslationUtil.h"
#include "core/animation/CompositorAnimationsImpl.h"
#include "core/animation/animatable/AnimatableDouble.h"
#include "core/animation/animatable/AnimatableFilterOperations.h"
#include "core/animation/animatable/AnimatableTransform.h"
#include "core/animation/animatable/AnimatableValue.h"
#include "core/rendering/RenderBoxModelObject.h"
#include "core/rendering/RenderLayer.h"
#include "core/rendering/RenderObject.h"
#include "core/rendering/compositing/CompositedLayerMapping.h"
#include "platform/geometry/FloatBox.h"
#include "public/platform/Platform.h"
#include "public/platform/WebCompositorAnimation.h"
#include "public/platform/WebCompositorSupport.h"
#include "public/platform/WebFilterAnimationCurve.h"
#include "public/platform/WebFilterKeyframe.h"
#include "public/platform/WebFloatAnimationCurve.h"
#include "public/platform/WebFloatKeyframe.h"
#include "public/platform/WebTransformAnimationCurve.h"
#include "public/platform/WebTransformKeyframe.h"

#include <algorithm>
#include <cmath>

namespace blink {

namespace {

void getKeyframeValuesForProperty(const KeyframeEffectModelBase* effect, CSSPropertyID id, double scale, bool reverse, PropertySpecificKeyframeVector& values)
{
    ASSERT(values.isEmpty());
    const PropertySpecificKeyframeVector& group = effect->getPropertySpecificKeyframes(id);

    if (reverse) {
        for (size_t i = group.size(); i--;) {
            double offset = (1 - group[i]->offset()) * scale;
            values.append(group[i]->cloneWithOffset(offset));
        }
    } else {
        for (size_t i = 0; i < group.size(); ++i) {
            double offset = group[i]->offset() * scale;
            values.append(group[i]->cloneWithOffset(offset));
        }
    }
}

}

// -----------------------------------------------------------------------
// TimingFunctionReverser methods
// -----------------------------------------------------------------------

PassRefPtr<TimingFunction> CompositorAnimationsTimingFunctionReverser::reverse(const LinearTimingFunction& timefunc)
{
    return const_cast<LinearTimingFunction*>(&timefunc);
}

PassRefPtr<TimingFunction> CompositorAnimationsTimingFunctionReverser::reverse(const CubicBezierTimingFunction& timefunc)
{
    switch (timefunc.subType()) {
    case CubicBezierTimingFunction::EaseIn:
        return CubicBezierTimingFunction::preset(CubicBezierTimingFunction::EaseOut);
    case CubicBezierTimingFunction::EaseOut:
        return CubicBezierTimingFunction::preset(CubicBezierTimingFunction::EaseIn);
    case CubicBezierTimingFunction::EaseInOut:
        return const_cast<CubicBezierTimingFunction*>(&timefunc);
    case CubicBezierTimingFunction::Ease: // Ease is not symmetrical
    case CubicBezierTimingFunction::Custom:
        return CubicBezierTimingFunction::create(1 - timefunc.x2(), 1 - timefunc.y2(), 1 - timefunc.x1(), 1 - timefunc.y1());
    default:
        ASSERT_NOT_REACHED();
        return PassRefPtr<TimingFunction>();
    }
}

PassRefPtr<TimingFunction> CompositorAnimationsTimingFunctionReverser::reverse(const TimingFunction& timefunc)
{
    switch (timefunc.type()) {
    case TimingFunction::LinearFunction: {
        const LinearTimingFunction& linear = toLinearTimingFunction(timefunc);
        return reverse(linear);
    }
    case TimingFunction::CubicBezierFunction: {
        const CubicBezierTimingFunction& cubic = toCubicBezierTimingFunction(timefunc);
        return reverse(cubic);
    }

    // Steps function can not be reversed.
    case TimingFunction::StepsFunction:
    default:
        ASSERT_NOT_REACHED();
        return PassRefPtr<TimingFunction>();
    }
}

bool CompositorAnimations::getAnimatedBoundingBox(FloatBox& box, const AnimationEffect& effect, double minValue, double maxValue) const
{
    const KeyframeEffectModelBase& keyframeEffect = toKeyframeEffectModelBase(effect);

    PropertySet properties = keyframeEffect.properties();

    if (properties.isEmpty())
        return true;

    minValue = std::min(minValue, 0.0);
    maxValue = std::max(maxValue, 1.0);

    for (PropertySet::const_iterator it = properties.begin(); it != properties.end(); ++it) {
        // TODO: Add the ability to get expanded bounds for filters as well.
        if (*it != CSSPropertyTransform && *it != CSSPropertyWebkitTransform)
            continue;

        const PropertySpecificKeyframeVector& frames = keyframeEffect.getPropertySpecificKeyframes(*it);
        if (frames.isEmpty() || frames.size() < 2)
            continue;

        FloatBox originalBox(box);

        for (size_t j = 0; j < frames.size() - 1; ++j) {
            const AnimatableTransform* startTransform = toAnimatableTransform(frames[j]->getAnimatableValue().get());
            const AnimatableTransform* endTransform = toAnimatableTransform(frames[j+1]->getAnimatableValue().get());
            // TODO: Add support for inflating modes other than Replace.
            if (frames[j]->composite() != AnimationEffect::CompositeReplace)
                return false;

            const TimingFunction& timing = frames[j]->easing();
            double min = 0;
            double max = 1;
            if (j == 0) {
                float frameLength = frames[j+1]->offset();
                if (frameLength > 0) {
                    min = minValue / frameLength;
                }
            }

            if (j == frames.size() - 2) {
                float frameLength = frames[j+1]->offset() - frames[j]->offset();
                if (frameLength > 0) {
                    max = 1 + (maxValue - 1) / frameLength;
                }
            }

            FloatBox bounds;
            timing.range(&min, &max);
            if (!endTransform->transformOperations().blendedBoundsForBox(originalBox, startTransform->transformOperations(), min, max, &bounds))
                return false;
            box.expandTo(bounds);
        }
    }
    return true;
}

// -----------------------------------------------------------------------
// CompositorAnimations public API
// -----------------------------------------------------------------------

bool CompositorAnimations::isCandidateForAnimationOnCompositor(const Timing& timing, const AnimationEffect& effect)
{
    const KeyframeEffectModelBase& keyframeEffect = toKeyframeEffectModelBase(effect);

    PropertySet properties = keyframeEffect.properties();

    if (properties.isEmpty())
        return false;

    for (PropertySet::const_iterator it = properties.begin(); it != properties.end(); ++it) {
        const PropertySpecificKeyframeVector& frames = keyframeEffect.getPropertySpecificKeyframes(*it);
        ASSERT(frames.size() >= 2);
        for (size_t i = 0; i < frames.size(); ++i) {
            const Keyframe::PropertySpecificKeyframe *frame = frames[i].get();
            // FIXME: Determine candidacy based on the CSSValue instead of a snapshot AnimatableValue.
            if (frame->composite() != AnimationEffect::CompositeReplace || !frame->getAnimatableValue())
                return false;

            switch (*it) {
            case CSSPropertyOpacity:
                break;
            case CSSPropertyTransform:
                if (toAnimatableTransform(frame->getAnimatableValue().get())->transformOperations().dependsOnBoxSize())
                    return false;
                break;
            case CSSPropertyWebkitFilter: {
                const FilterOperations& operations = toAnimatableFilterOperations(frame->getAnimatableValue().get())->operations();
                if (operations.hasFilterThatMovesPixels())
                    return false;
                break;
            }
            default:
                return false;
            }

            // FIXME: Remove this check when crbug.com/229405 is resolved
            if (i < frames.size() - 1 && frame->easing().type() == TimingFunction::StepsFunction)
                return false;
        }
    }

    CompositorAnimationsImpl::CompositorTiming out;
    if (!CompositorAnimationsImpl::convertTimingForCompositor(timing, 0, out))
        return false;

    if (timing.timingFunction->type() != TimingFunction::LinearFunction) {
        // Checks the of size of KeyframeVector instead of PropertySpecificKeyframeVector.
        const KeyframeVector& keyframes = keyframeEffect.getFrames();
        if (keyframes.size() == 2 && keyframes[0]->easing().type() == TimingFunction::LinearFunction && timing.timingFunction->type() != TimingFunction::StepsFunction)
            return true;

        // FIXME: Support non-linear timing functions in the compositor for
        // more than two keyframes and step timing functions in the compositor.
        return false;
    }

    return true;
}

bool CompositorAnimations::canStartAnimationOnCompositor(const Element& element)
{
    return element.renderer() && element.renderer()->compositingState() == PaintsIntoOwnBacking;
}

bool CompositorAnimations::startAnimationOnCompositor(const Element& element, double startTime, double timeOffset, const Timing& timing, const AnimationEffect& effect, Vector<int>& startedAnimationIds)
{
    ASSERT(startedAnimationIds.isEmpty());
    ASSERT(isCandidateForAnimationOnCompositor(timing, effect));
    ASSERT(canStartAnimationOnCompositor(element));

    const KeyframeEffectModelBase& keyframeEffect = toKeyframeEffectModelBase(effect);

    RenderLayer* layer = toRenderBoxModelObject(element.renderer())->layer();
    ASSERT(layer);

    Vector<OwnPtr<WebCompositorAnimation> > animations;
    CompositorAnimationsImpl::getAnimationOnCompositor(timing, startTime, timeOffset, keyframeEffect, animations);
    ASSERT(!animations.isEmpty());
    for (size_t i = 0; i < animations.size(); ++i) {
        int id = animations[i]->id();
        if (!layer->compositedLayerMapping()->mainGraphicsLayer()->addAnimation(animations[i].release())) {
            // FIXME: We should know ahead of time whether these animations can be started.
            for (size_t j = 0; j < startedAnimationIds.size(); ++j)
                cancelAnimationOnCompositor(element, startedAnimationIds[j]);
            startedAnimationIds.clear();
            return false;
        }
        startedAnimationIds.append(id);
    }
    ASSERT(!startedAnimationIds.isEmpty());
    return true;
}

void CompositorAnimations::cancelAnimationOnCompositor(const Element& element, int id)
{
    if (!canStartAnimationOnCompositor(element)) {
        // When an element is being detached, we cancel any associated
        // AnimationPlayers for CSS animations. But by the time we get
        // here the mapping will have been removed.
        // FIXME: Defer remove/pause operations until after the
        // compositing update.
        return;
    }
    toRenderBoxModelObject(element.renderer())->layer()->compositedLayerMapping()->mainGraphicsLayer()->removeAnimation(id);
}

void CompositorAnimations::pauseAnimationForTestingOnCompositor(const Element& element, int id, double pauseTime)
{
    // FIXME: canStartAnimationOnCompositor queries compositingState, which is not necessarily up to date.
    // https://code.google.com/p/chromium/issues/detail?id=339847
    DisableCompositingQueryAsserts disabler;

    if (!canStartAnimationOnCompositor(element)) {
        ASSERT_NOT_REACHED();
        return;
    }
    toRenderBoxModelObject(element.renderer())->layer()->compositedLayerMapping()->mainGraphicsLayer()->pauseAnimation(id, pauseTime);
}

// -----------------------------------------------------------------------
// CompositorAnimationsImpl
// -----------------------------------------------------------------------

bool CompositorAnimationsImpl::convertTimingForCompositor(const Timing& timing, double timeOffset, CompositorTiming& out)
{
    timing.assertValid();

    // All fill modes are supported (the calling code handles them).

    // FIXME: Support non-zero iteration start.
    if (timing.iterationStart)
        return false;

    if (timing.iterationCount <= 0)
        return false;

    if (std::isnan(timing.iterationDuration) || !timing.iterationDuration)
        return false;

    // FIXME: Support other playback rates
    if (timing.playbackRate != 1)
        return false;

    // All directions are supported.

    // Now attempt an actual conversion
    out.scaledDuration = timing.iterationDuration;
    ASSERT(out.scaledDuration > 0);

    double scaledStartDelay = timing.startDelay;
    if (scaledStartDelay > 0 && scaledStartDelay > out.scaledDuration * timing.iterationCount)
        return false;

    out.reverse = (timing.direction == Timing::PlaybackDirectionReverse
        || timing.direction == Timing::PlaybackDirectionAlternateReverse);
    out.alternate = (timing.direction == Timing::PlaybackDirectionAlternate
        || timing.direction == Timing::PlaybackDirectionAlternateReverse);

    if (!std::isfinite(timing.iterationCount)) {
        out.adjustedIterationCount = -1;
    } else {
        out.adjustedIterationCount = timing.iterationCount;
        ASSERT(out.adjustedIterationCount > 0);
    }

    // Compositor's time offset is positive for seeking into the animation.
    out.scaledTimeOffset = -scaledStartDelay + timeOffset;
    return true;
}

namespace {

template<typename PlatformAnimationCurveType, typename PlatformAnimationKeyframeType>
void addKeyframeWithTimingFunction(PlatformAnimationCurveType& curve, const PlatformAnimationKeyframeType& keyframe, const TimingFunction* timingFunction)
{
    if (!timingFunction) {
        curve.add(keyframe);
        return;
    }

    switch (timingFunction->type()) {
    case TimingFunction::LinearFunction:
        curve.add(keyframe, WebCompositorAnimationCurve::TimingFunctionTypeLinear);
        return;

    case TimingFunction::CubicBezierFunction: {
        const CubicBezierTimingFunction* cubic = toCubicBezierTimingFunction(timingFunction);

        if (cubic->subType() == CubicBezierTimingFunction::Custom) {
            curve.add(keyframe, cubic->x1(), cubic->y1(), cubic->x2(), cubic->y2());
        } else {

            WebCompositorAnimationCurve::TimingFunctionType easeType;
            switch (cubic->subType()) {
            case CubicBezierTimingFunction::Ease:
                easeType = WebCompositorAnimationCurve::TimingFunctionTypeEase;
                break;
            case CubicBezierTimingFunction::EaseIn:
                easeType = WebCompositorAnimationCurve::TimingFunctionTypeEaseIn;
                break;
            case CubicBezierTimingFunction::EaseOut:
                easeType = WebCompositorAnimationCurve::TimingFunctionTypeEaseOut;
                break;
            case CubicBezierTimingFunction::EaseInOut:
                easeType = WebCompositorAnimationCurve::TimingFunctionTypeEaseInOut;
                break;

            // Custom Bezier are handled seperately.
            case CubicBezierTimingFunction::Custom:
            default:
                ASSERT_NOT_REACHED();
                return;
            }

            curve.add(keyframe, easeType);
        }
        return;
    }

    case TimingFunction::StepsFunction:
    default:
        ASSERT_NOT_REACHED();
        return;
    }
}

} // namespace anoymous

void CompositorAnimationsImpl::addKeyframesToCurve(WebCompositorAnimationCurve& curve, const PropertySpecificKeyframeVector& keyframes, const Timing& timing, bool reverse)
{
    for (size_t i = 0; i < keyframes.size(); i++) {
        RefPtr<TimingFunction> reversedTimingFunction;
        const TimingFunction* keyframeTimingFunction = 0;
        if (i < keyframes.size() - 1) { // Ignore timing function of last frame.
            if (keyframes.size() == 2 && keyframes[0]->easing().type() == TimingFunction::LinearFunction) {
                if (reverse) {
                    reversedTimingFunction = CompositorAnimationsTimingFunctionReverser::reverse(*timing.timingFunction.get());
                    keyframeTimingFunction = reversedTimingFunction.get();
                } else {
                    keyframeTimingFunction = timing.timingFunction.get();
                }
            } else {
                if (reverse) {
                    reversedTimingFunction = CompositorAnimationsTimingFunctionReverser::reverse(keyframes[i + 1]->easing());
                    keyframeTimingFunction = reversedTimingFunction.get();
                } else {
                    keyframeTimingFunction = &keyframes[i]->easing();
                }
            }
        }

        // FIXME: This relies on StringKeyframes being eagerly evaluated, which will
        // not happen eventually. Instead we should extract the CSSValue here
        // and convert using another set of toAnimatableXXXOperations functions.
        const AnimatableValue* value = keyframes[i]->getAnimatableValue().get();

        switch (curve.type()) {
        case WebCompositorAnimationCurve::AnimationCurveTypeFilter: {
            OwnPtr<WebFilterOperations> ops = adoptPtr(Platform::current()->compositorSupport()->createFilterOperations());
            toWebFilterOperations(toAnimatableFilterOperations(value)->operations(), ops.get());

            WebFilterKeyframe filterKeyframe(keyframes[i]->offset(), ops.release());
            WebFilterAnimationCurve* filterCurve = static_cast<WebFilterAnimationCurve*>(&curve);
            addKeyframeWithTimingFunction(*filterCurve, filterKeyframe, keyframeTimingFunction);
            break;
        }
        case WebCompositorAnimationCurve::AnimationCurveTypeFloat: {
            WebFloatKeyframe floatKeyframe(keyframes[i]->offset(), toAnimatableDouble(value)->toDouble());
            WebFloatAnimationCurve* floatCurve = static_cast<WebFloatAnimationCurve*>(&curve);
            addKeyframeWithTimingFunction(*floatCurve, floatKeyframe, keyframeTimingFunction);
            break;
        }
        case WebCompositorAnimationCurve::AnimationCurveTypeTransform: {
            OwnPtr<WebTransformOperations> ops = adoptPtr(Platform::current()->compositorSupport()->createTransformOperations());
            toWebTransformOperations(toAnimatableTransform(value)->transformOperations(), ops.get());

            WebTransformKeyframe transformKeyframe(keyframes[i]->offset(), ops.release());
            WebTransformAnimationCurve* transformCurve = static_cast<WebTransformAnimationCurve*>(&curve);
            addKeyframeWithTimingFunction(*transformCurve, transformKeyframe, keyframeTimingFunction);
            break;
        }
        default:
            ASSERT_NOT_REACHED();
        }
    }
}

void CompositorAnimationsImpl::getAnimationOnCompositor(const Timing& timing, double startTime, double timeOffset, const KeyframeEffectModelBase& effect, Vector<OwnPtr<WebCompositorAnimation> >& animations)
{
    ASSERT(animations.isEmpty());
    CompositorTiming compositorTiming;
    bool timingValid = convertTimingForCompositor(timing, timeOffset, compositorTiming);
    ASSERT_UNUSED(timingValid, timingValid);

    PropertySet properties = effect.properties();
    ASSERT(!properties.isEmpty());
    for (PropertySet::iterator it = properties.begin(); it != properties.end(); ++it) {

        PropertySpecificKeyframeVector values;
        getKeyframeValuesForProperty(&effect, *it, compositorTiming.scaledDuration, compositorTiming.reverse, values);

        WebCompositorAnimation::TargetProperty targetProperty;
        OwnPtr<WebCompositorAnimationCurve> curve;
        switch (*it) {
        case CSSPropertyOpacity: {
            targetProperty = WebCompositorAnimation::TargetPropertyOpacity;

            WebFloatAnimationCurve* floatCurve = Platform::current()->compositorSupport()->createFloatAnimationCurve();
            addKeyframesToCurve(*floatCurve, values, timing, compositorTiming.reverse);
            curve = adoptPtr(floatCurve);
            break;
        }
        case CSSPropertyWebkitFilter: {
            targetProperty = WebCompositorAnimation::TargetPropertyFilter;
            WebFilterAnimationCurve* filterCurve = Platform::current()->compositorSupport()->createFilterAnimationCurve();
            addKeyframesToCurve(*filterCurve, values, timing, compositorTiming.reverse);
            curve = adoptPtr(filterCurve);
            break;
        }
        case CSSPropertyTransform: {
            targetProperty = WebCompositorAnimation::TargetPropertyTransform;
            WebTransformAnimationCurve* transformCurve = Platform::current()->compositorSupport()->createTransformAnimationCurve();
            addKeyframesToCurve(*transformCurve, values, timing, compositorTiming.reverse);
            curve = adoptPtr(transformCurve);
            break;
        }
        default:
            ASSERT_NOT_REACHED();
            continue;
        }
        ASSERT(curve.get());

        OwnPtr<WebCompositorAnimation> animation = adoptPtr(Platform::current()->compositorSupport()->createAnimation(*curve, targetProperty));

        if (!std::isnan(startTime))
            animation->setStartTime(startTime);

        animation->setIterations(compositorTiming.adjustedIterationCount);
        animation->setTimeOffset(compositorTiming.scaledTimeOffset);
        animation->setAlternatesDirection(compositorTiming.alternate);

        animations.append(animation.release());
    }
    ASSERT(!animations.isEmpty());
}

} // namespace blink
