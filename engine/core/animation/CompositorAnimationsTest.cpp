/*
 * Copyright (c) 2013, Google Inc. All rights reserved.
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

#include "core/animation/CompositorAnimationsImpl.h"
#include "core/animation/CompositorAnimationsTestHelper.h"
#include "core/animation/animatable/AnimatableDouble.h"
#include "core/animation/animatable/AnimatableFilterOperations.h"
#include "core/animation/animatable/AnimatableTransform.h"
#include "core/animation/animatable/AnimatableValueTestHelper.h"
#include "platform/geometry/FloatBox.h"
#include "platform/geometry/IntSize.h"
#include "platform/graphics/filters/FilterOperations.h"
#include "platform/transforms/TransformOperations.h"
#include "platform/transforms/TranslateTransformOperation.h"
#include "public/platform/WebCompositorAnimation.h"
#include "wtf/HashFunctions.h"
#include "wtf/OwnPtr.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefPtr.h"

#include <gmock/gmock.h>
#include <gtest/gtest.h>

namespace blink {

using ::testing::CloneToPassOwnPtr;
using ::testing::ExpectationSet;
using ::testing::Ref;
using ::testing::Return;
using ::testing::_;

class AnimationCompositorAnimationsTest : public AnimationCompositorAnimationsTestBase {
protected:
    RefPtr<TimingFunction> m_linearTimingFunction;
    RefPtr<TimingFunction> m_cubicEaseTimingFunction;
    RefPtr<TimingFunction> m_cubicCustomTimingFunction;
    RefPtr<TimingFunction> m_stepTimingFunction;

    Timing m_timing;
    CompositorAnimationsImpl::CompositorTiming m_compositorTiming;
    OwnPtrWillBePersistent<AnimatableValueKeyframeVector> m_keyframeVector2;
    RefPtrWillBePersistent<AnimatableValueKeyframeEffectModel> m_keyframeAnimationEffect2;
    OwnPtrWillBePersistent<AnimatableValueKeyframeVector> m_keyframeVector5;
    RefPtrWillBePersistent<AnimatableValueKeyframeEffectModel> m_keyframeAnimationEffect5;

    virtual void SetUp()
    {
        AnimationCompositorAnimationsTestBase::SetUp();

        m_linearTimingFunction = LinearTimingFunction::shared();
        m_cubicEaseTimingFunction = CubicBezierTimingFunction::preset(CubicBezierTimingFunction::Ease);
        m_cubicCustomTimingFunction = CubicBezierTimingFunction::create(1, 2, 3, 4);
        m_stepTimingFunction = StepsTimingFunction::create(1, StepsTimingFunction::StepAtEnd);

        m_timing = createCompositableTiming();
        m_compositorTiming = CompositorAnimationsImpl::CompositorTiming();
        // Make sure the CompositableTiming is really compositable, otherwise
        // most other tests will fail.
        ASSERT(convertTimingForCompositor(m_timing, m_compositorTiming));

        m_keyframeVector2 = createCompositableFloatKeyframeVector(2);
        m_keyframeAnimationEffect2 = AnimatableValueKeyframeEffectModel::create(*m_keyframeVector2);

        m_keyframeVector5 = createCompositableFloatKeyframeVector(5);
        m_keyframeAnimationEffect5 = AnimatableValueKeyframeEffectModel::create(*m_keyframeVector5);
    }

public:

    bool convertTimingForCompositor(const Timing& t, CompositorAnimationsImpl::CompositorTiming& out)
    {
        return CompositorAnimationsImpl::convertTimingForCompositor(t, 0, out);
    }
    bool isCandidateForAnimationOnCompositor(const Timing& timing, const AnimationEffect& effect)
    {
        return CompositorAnimations::instance()->isCandidateForAnimationOnCompositor(timing, effect);
    }
    void getAnimationOnCompositor(Timing& timing, AnimatableValueKeyframeEffectModel& effect, Vector<OwnPtr<WebCompositorAnimation> >& animations)
    {
        return CompositorAnimationsImpl::getAnimationOnCompositor(timing, std::numeric_limits<double>::quiet_NaN(), 0, effect, animations);
    }
    bool getAnimationBounds(FloatBox& boundingBox, const AnimationEffect& effect, double minValue, double maxValue)
    {
        return CompositorAnimations::instance()->getAnimatedBoundingBox(boundingBox, effect, minValue, maxValue);
    }

    bool duplicateSingleKeyframeAndTestIsCandidateOnResult(AnimatableValueKeyframe* frame)
    {
        EXPECT_EQ(frame->offset(), 0);
        AnimatableValueKeyframeVector frames;
        RefPtrWillBeRawPtr<Keyframe> second = frame->cloneWithOffset(1);

        frames.append(frame);
        frames.append(toAnimatableValueKeyframe(second.get()));
        return isCandidateForAnimationOnCompositor(m_timing, *AnimatableValueKeyframeEffectModel::create(frames).get());
    }

    // -------------------------------------------------------------------

    Timing createCompositableTiming()
    {
        Timing timing;
        timing.startDelay = 0;
        timing.fillMode = Timing::FillModeNone;
        timing.iterationStart = 0;
        timing.iterationCount = 1;
        timing.iterationDuration = 1.0;
        timing.playbackRate = 1.0;
        timing.direction = Timing::PlaybackDirectionNormal;
        ASSERT(m_linearTimingFunction);
        timing.timingFunction = m_linearTimingFunction;
        return timing;
    }

    PassRefPtrWillBeRawPtr<AnimatableValueKeyframe> createReplaceOpKeyframe(CSSPropertyID id, AnimatableValue* value, double offset = 0)
    {
        RefPtrWillBeRawPtr<AnimatableValueKeyframe> keyframe = AnimatableValueKeyframe::create();
        keyframe->setPropertyValue(id, value);
        keyframe->setComposite(AnimationEffect::CompositeReplace);
        keyframe->setOffset(offset);
        keyframe->setEasing(LinearTimingFunction::shared());
        return keyframe;
    }

    PassRefPtrWillBeRawPtr<AnimatableValueKeyframe> createDefaultKeyframe(CSSPropertyID id, AnimationEffect::CompositeOperation op, double offset = 0)
    {
        RefPtrWillBeRawPtr<AnimatableValue> value = nullptr;
        if (id == CSSPropertyTransform)
            value = AnimatableTransform::create(TransformOperations());
        else
            value = AnimatableDouble::create(10.0);

        RefPtrWillBeRawPtr<AnimatableValueKeyframe> keyframe = createReplaceOpKeyframe(id, value.get(), offset);
        keyframe->setComposite(op);
        return keyframe;
    }

    PassOwnPtrWillBeRawPtr<AnimatableValueKeyframeVector> createCompositableFloatKeyframeVector(size_t n)
    {
        Vector<double> values;
        for (size_t i = 0; i < n; i++) {
            values.append(static_cast<double>(i));
        }
        return createCompositableFloatKeyframeVector(values);
    }

    PassOwnPtrWillBeRawPtr<AnimatableValueKeyframeVector> createCompositableFloatKeyframeVector(Vector<double>& values)
    {
        OwnPtrWillBeRawPtr<AnimatableValueKeyframeVector> frames = adoptPtrWillBeNoop(new AnimatableValueKeyframeVector);
        for (size_t i = 0; i < values.size(); i++) {
            double offset = 1.0 / (values.size() - 1) * i;
            RefPtrWillBeRawPtr<AnimatableDouble> value = AnimatableDouble::create(values[i]);
            frames->append(createReplaceOpKeyframe(CSSPropertyOpacity, value.get(), offset).get());
        }
        return frames.release();
    }

    PassOwnPtrWillBeRawPtr<AnimatableValueKeyframeVector> createCompositableTransformKeyframeVector(const Vector<TransformOperations>& values)
    {
        OwnPtrWillBeRawPtr<AnimatableValueKeyframeVector> frames = adoptPtrWillBeNoop(new AnimatableValueKeyframeVector);
        for (size_t i = 0; i < values.size(); ++i) {
            double offset = 1.0f / (values.size() - 1) * i;
            RefPtrWillBeRawPtr<AnimatableTransform> value = AnimatableTransform::create(values[i]);
            frames->append(createReplaceOpKeyframe(CSSPropertyTransform, value.get(), offset).get());
        }
        return frames.release();
    }

    PassRefPtrWillBeRawPtr<AnimatableValueKeyframeEffectModel> createKeyframeEffectModel(PassRefPtrWillBeRawPtr<AnimatableValueKeyframe> prpFrom, PassRefPtrWillBeRawPtr<AnimatableValueKeyframe> prpTo, PassRefPtrWillBeRawPtr<AnimatableValueKeyframe> prpC = nullptr, PassRefPtrWillBeRawPtr<AnimatableValueKeyframe> prpD = nullptr)
    {
        RefPtrWillBeRawPtr<AnimatableValueKeyframe> from = prpFrom;
        RefPtrWillBeRawPtr<AnimatableValueKeyframe> to = prpTo;
        RefPtrWillBeRawPtr<AnimatableValueKeyframe> c = prpC;
        RefPtrWillBeRawPtr<AnimatableValueKeyframe> d = prpD;

        EXPECT_EQ(from->offset(), 0);
        AnimatableValueKeyframeVector frames;
        frames.append(from);
        EXPECT_LE(from->offset(), to->offset());
        frames.append(to);
        if (c) {
            EXPECT_LE(to->offset(), c->offset());
            frames.append(c);
        }
        if (d) {
            frames.append(d);
            EXPECT_LE(c->offset(), d->offset());
            EXPECT_EQ(d->offset(), 1.0);
        } else {
            EXPECT_EQ(to->offset(), 1.0);
        }
        if (!HasFatalFailure()) {
            return AnimatableValueKeyframeEffectModel::create(frames);
        }
        return nullptr;
    }

};

// -----------------------------------------------------------------------
// -----------------------------------------------------------------------

TEST_F(AnimationCompositorAnimationsTest, isCandidateForAnimationOnCompositorKeyframeMultipleCSSProperties)
{
    RefPtrWillBeRawPtr<AnimatableValueKeyframe> keyframeGoodMultiple = createDefaultKeyframe(CSSPropertyOpacity, AnimationEffect::CompositeReplace);
    keyframeGoodMultiple->setPropertyValue(CSSPropertyTransform, AnimatableTransform::create(TransformOperations()).get());
    EXPECT_TRUE(duplicateSingleKeyframeAndTestIsCandidateOnResult(keyframeGoodMultiple.get()));

    RefPtrWillBeRawPtr<AnimatableValueKeyframe> keyframeBadMultipleID = createDefaultKeyframe(CSSPropertyColor, AnimationEffect::CompositeReplace);
    keyframeBadMultipleID->setPropertyValue(CSSPropertyOpacity, AnimatableDouble::create(10.0).get());
    EXPECT_FALSE(duplicateSingleKeyframeAndTestIsCandidateOnResult(keyframeBadMultipleID.get()));
}

TEST_F(AnimationCompositorAnimationsTest, isNotCandidateForCompositorAnimationTransformDependsOnBoxSize)
{
    TransformOperations ops;
    ops.operations().append(TranslateTransformOperation::create(Length(2, Fixed), Length(2, Fixed), TransformOperation::TranslateX));
    RefPtrWillBeRawPtr<AnimatableValueKeyframe> goodKeyframe = createReplaceOpKeyframe(CSSPropertyTransform, AnimatableTransform::create(ops).get());
    EXPECT_TRUE(duplicateSingleKeyframeAndTestIsCandidateOnResult(goodKeyframe.get()));

    ops.operations().append(TranslateTransformOperation::create(Length(50, Percent), Length(2, Fixed), TransformOperation::TranslateX));
    RefPtrWillBeRawPtr<AnimatableValueKeyframe> badKeyframe = createReplaceOpKeyframe(CSSPropertyTransform, AnimatableTransform::create(ops).get());
    EXPECT_FALSE(duplicateSingleKeyframeAndTestIsCandidateOnResult(badKeyframe.get()));

    TransformOperations ops2;
    Length calcLength = Length(100, Percent).blend(Length(100, Fixed), 0.5, ValueRangeAll);
    ops2.operations().append(TranslateTransformOperation::create(calcLength, Length(0, Fixed), TransformOperation::TranslateX));
    RefPtrWillBeRawPtr<AnimatableValueKeyframe> badKeyframe2 = createReplaceOpKeyframe(CSSPropertyTransform, AnimatableTransform::create(ops2).get());
    EXPECT_FALSE(duplicateSingleKeyframeAndTestIsCandidateOnResult(badKeyframe2.get()));
}

TEST_F(AnimationCompositorAnimationsTest, isCandidateForAnimationOnCompositorKeyframeEffectModelMultipleFramesOkay)
{
    AnimatableValueKeyframeVector framesSame;
    framesSame.append(createDefaultKeyframe(CSSPropertyOpacity, AnimationEffect::CompositeReplace, 0.0).get());
    framesSame.append(createDefaultKeyframe(CSSPropertyOpacity, AnimationEffect::CompositeReplace, 1.0).get());
    EXPECT_TRUE(isCandidateForAnimationOnCompositor(m_timing, *AnimatableValueKeyframeEffectModel::create(framesSame).get()));

    AnimatableValueKeyframeVector framesMixed;
    framesMixed.append(createDefaultKeyframe(CSSPropertyOpacity, AnimationEffect::CompositeReplace, 0.0).get());
    framesMixed.append(createDefaultKeyframe(CSSPropertyTransform, AnimationEffect::CompositeReplace, 1.0).get());
    EXPECT_FALSE(isCandidateForAnimationOnCompositor(m_timing, *AnimatableValueKeyframeEffectModel::create(framesMixed).get()));
}

TEST_F(AnimationCompositorAnimationsTest, isCandidateForAnimationOnCompositorKeyframeEffectModel)
{
    AnimatableValueKeyframeVector framesSame;
    framesSame.append(createDefaultKeyframe(CSSPropertyColor, AnimationEffect::CompositeReplace, 0.0).get());
    framesSame.append(createDefaultKeyframe(CSSPropertyColor, AnimationEffect::CompositeReplace, 1.0).get());
    EXPECT_FALSE(isCandidateForAnimationOnCompositor(m_timing, *AnimatableValueKeyframeEffectModel::create(framesSame).get()));

    AnimatableValueKeyframeVector framesMixedProperties;
    framesMixedProperties.append(createDefaultKeyframe(CSSPropertyOpacity, AnimationEffect::CompositeReplace, 0.0).get());
    framesMixedProperties.append(createDefaultKeyframe(CSSPropertyColor, AnimationEffect::CompositeReplace, 1.0).get());
    EXPECT_FALSE(isCandidateForAnimationOnCompositor(m_timing, *AnimatableValueKeyframeEffectModel::create(framesMixedProperties).get()));
}

TEST_F(AnimationCompositorAnimationsTest, AnimatedBoundingBox)
{
    Vector<TransformOperations> transformVector;
    transformVector.append(TransformOperations());
    transformVector.last().operations().append(TranslateTransformOperation::create(Length(0, Fixed), Length(0, Fixed), 0.0, TransformOperation::Translate3D));
    transformVector.append(TransformOperations());
    transformVector.last().operations().append(TranslateTransformOperation::create(Length(200, Fixed), Length(200, Fixed), 0.0, TransformOperation::Translate3D));
    OwnPtrWillBePersistent<AnimatableValueKeyframeVector> frames = createCompositableTransformKeyframeVector(transformVector);
    FloatBox bounds;
    EXPECT_TRUE(getAnimationBounds(bounds, *AnimatableValueKeyframeEffectModel::create(*frames).get(), 0, 1));
    EXPECT_EQ(FloatBox(0.0f, 0.f, 0.0f, 200.0f, 200.0f, 0.0f), bounds);
    bounds = FloatBox();
    EXPECT_TRUE(getAnimationBounds(bounds, *AnimatableValueKeyframeEffectModel::create(*frames).get(), -1, 1));
    EXPECT_EQ(FloatBox(-200.0f, -200.0, 0.0, 400.0f, 400.0f, 0.0f), bounds);
    transformVector.append(TransformOperations());
    transformVector.last().operations().append(TranslateTransformOperation::create(Length(-300, Fixed), Length(-400, Fixed), 1.0f, TransformOperation::Translate3D));
    bounds = FloatBox();
    frames = createCompositableTransformKeyframeVector(transformVector);
    EXPECT_TRUE(getAnimationBounds(bounds, *AnimatableValueKeyframeEffectModel::create(*frames).get(), 0, 1));
    EXPECT_EQ(FloatBox(-300.0f, -400.f, 0.0f, 500.0f, 600.0f, 1.0f), bounds);
    bounds = FloatBox();
    EXPECT_TRUE(getAnimationBounds(bounds, *AnimatableValueKeyframeEffectModel::create(*frames).get(), -1, 2));
    EXPECT_EQ(FloatBox(-1300.0f, -1600.f, 0.0f, 1500.0f, 1800.0f, 3.0f), bounds);
}

TEST_F(AnimationCompositorAnimationsTest, ConvertTimingForCompositorStartDelay)
{
    m_timing.iterationDuration = 20.0;

    m_timing.startDelay = 2.0;
    EXPECT_TRUE(convertTimingForCompositor(m_timing, m_compositorTiming));
    EXPECT_DOUBLE_EQ(-2.0, m_compositorTiming.scaledTimeOffset);

    m_timing.startDelay = -2.0;
    EXPECT_TRUE(convertTimingForCompositor(m_timing, m_compositorTiming));
    EXPECT_DOUBLE_EQ(2.0, m_compositorTiming.scaledTimeOffset);
}

TEST_F(AnimationCompositorAnimationsTest, ConvertTimingForCompositorIterationStart)
{
    m_timing.iterationStart = 2.2;
    EXPECT_FALSE(convertTimingForCompositor(m_timing, m_compositorTiming));
}

TEST_F(AnimationCompositorAnimationsTest, ConvertTimingForCompositorIterationCount)
{
    m_timing.iterationCount = 5.0;
    EXPECT_TRUE(convertTimingForCompositor(m_timing, m_compositorTiming));
    EXPECT_EQ(5, m_compositorTiming.adjustedIterationCount);

    m_timing.iterationCount = 5.5;
    EXPECT_TRUE(convertTimingForCompositor(m_timing, m_compositorTiming));
    EXPECT_EQ(5.5, m_compositorTiming.adjustedIterationCount);

    // EXPECT_DEATH tests are flaky on Android.
#if ENABLE(ASSERT) && !OS(ANDROID)
    m_timing.iterationCount = -1;
    EXPECT_DEATH(convertTimingForCompositor(m_timing, m_compositorTiming), "");
#endif

    m_timing.iterationCount = std::numeric_limits<double>::infinity();
    EXPECT_TRUE(convertTimingForCompositor(m_timing, m_compositorTiming));
    EXPECT_EQ(-1, m_compositorTiming.adjustedIterationCount);

    m_timing.iterationCount = std::numeric_limits<double>::infinity();
    m_timing.iterationDuration = 5.0;
    m_timing.startDelay = -6.0;
    EXPECT_TRUE(convertTimingForCompositor(m_timing, m_compositorTiming));
    EXPECT_DOUBLE_EQ(6.0, m_compositorTiming.scaledTimeOffset);
    EXPECT_EQ(-1, m_compositorTiming.adjustedIterationCount);
}

TEST_F(AnimationCompositorAnimationsTest, ConvertTimingForCompositorIterationsAndStartDelay)
{
    m_timing.iterationCount = 4.0;
    m_timing.iterationDuration = 5.0;

    m_timing.startDelay = 6.0;
    EXPECT_TRUE(convertTimingForCompositor(m_timing, m_compositorTiming));
    EXPECT_DOUBLE_EQ(-6.0, m_compositorTiming.scaledTimeOffset);
    EXPECT_DOUBLE_EQ(4.0, m_compositorTiming.adjustedIterationCount);

    m_timing.startDelay = -6.0;
    EXPECT_TRUE(convertTimingForCompositor(m_timing, m_compositorTiming));
    EXPECT_DOUBLE_EQ(6.0, m_compositorTiming.scaledTimeOffset);
    EXPECT_DOUBLE_EQ(4.0, m_compositorTiming.adjustedIterationCount);

    m_timing.startDelay = 21.0;
    EXPECT_FALSE(convertTimingForCompositor(m_timing, m_compositorTiming));
}

TEST_F(AnimationCompositorAnimationsTest, ConvertTimingForCompositorPlaybackRate)
{
    m_timing.playbackRate = 2.0;
    EXPECT_FALSE(convertTimingForCompositor(m_timing, m_compositorTiming));

    m_timing.playbackRate = 0.0;
    EXPECT_FALSE(convertTimingForCompositor(m_timing, m_compositorTiming));

    m_timing.playbackRate = -2.0;
    EXPECT_FALSE(convertTimingForCompositor(m_timing, m_compositorTiming));
}

TEST_F(AnimationCompositorAnimationsTest, ConvertTimingForCompositorDirection)
{
    m_timing.direction = Timing::PlaybackDirectionAlternate;
    EXPECT_TRUE(convertTimingForCompositor(m_timing, m_compositorTiming));
    EXPECT_TRUE(m_compositorTiming.alternate);
    EXPECT_FALSE(m_compositorTiming.reverse);

    m_timing.direction = Timing::PlaybackDirectionAlternateReverse;
    EXPECT_TRUE(convertTimingForCompositor(m_timing, m_compositorTiming));
    EXPECT_TRUE(m_compositorTiming.alternate);
    EXPECT_TRUE(m_compositorTiming.reverse);

    m_timing.direction = Timing::PlaybackDirectionReverse;
    EXPECT_TRUE(convertTimingForCompositor(m_timing, m_compositorTiming));
    EXPECT_FALSE(m_compositorTiming.alternate);
    EXPECT_TRUE(m_compositorTiming.reverse);
}

TEST_F(AnimationCompositorAnimationsTest, ConvertTimingForCompositorDirectionIterationsAndStartDelay)
{
    m_timing.direction = Timing::PlaybackDirectionAlternate;
    m_timing.iterationCount = 4.0;
    m_timing.iterationDuration = 5.0;
    m_timing.startDelay = -6.0;
    EXPECT_TRUE(convertTimingForCompositor(m_timing, m_compositorTiming));
    EXPECT_DOUBLE_EQ(6.0, m_compositorTiming.scaledTimeOffset);
    EXPECT_EQ(4, m_compositorTiming.adjustedIterationCount);
    EXPECT_TRUE(m_compositorTiming.alternate);
    EXPECT_FALSE(m_compositorTiming.reverse);

    m_timing.direction = Timing::PlaybackDirectionAlternate;
    m_timing.iterationCount = 4.0;
    m_timing.iterationDuration = 5.0;
    m_timing.startDelay = -11.0;
    EXPECT_TRUE(convertTimingForCompositor(m_timing, m_compositorTiming));
    EXPECT_DOUBLE_EQ(11.0, m_compositorTiming.scaledTimeOffset);
    EXPECT_EQ(4, m_compositorTiming.adjustedIterationCount);
    EXPECT_TRUE(m_compositorTiming.alternate);
    EXPECT_FALSE(m_compositorTiming.reverse);

    m_timing.direction = Timing::PlaybackDirectionAlternateReverse;
    m_timing.iterationCount = 4.0;
    m_timing.iterationDuration = 5.0;
    m_timing.startDelay = -6.0;
    EXPECT_TRUE(convertTimingForCompositor(m_timing, m_compositorTiming));
    EXPECT_DOUBLE_EQ(6.0, m_compositorTiming.scaledTimeOffset);
    EXPECT_EQ(4, m_compositorTiming.adjustedIterationCount);
    EXPECT_TRUE(m_compositorTiming.alternate);
    EXPECT_TRUE(m_compositorTiming.reverse);

    m_timing.direction = Timing::PlaybackDirectionAlternateReverse;
    m_timing.iterationCount = 4.0;
    m_timing.iterationDuration = 5.0;
    m_timing.startDelay = -11.0;
    EXPECT_TRUE(convertTimingForCompositor(m_timing, m_compositorTiming));
    EXPECT_DOUBLE_EQ(11.0, m_compositorTiming.scaledTimeOffset);
    EXPECT_EQ(4, m_compositorTiming.adjustedIterationCount);
    EXPECT_TRUE(m_compositorTiming.alternate);
    EXPECT_TRUE(m_compositorTiming.reverse);
}

TEST_F(AnimationCompositorAnimationsTest, isCandidateForAnimationOnCompositorTimingTimingFunctionPassThru)
{
    m_timing.timingFunction = m_stepTimingFunction;
    EXPECT_FALSE(isCandidateForAnimationOnCompositor(m_timing, *m_keyframeAnimationEffect2.get()));
}

TEST_F(AnimationCompositorAnimationsTest, isCandidateForAnimationOnCompositorTimingFunctionLinear)
{
    m_timing.timingFunction = m_linearTimingFunction;
    EXPECT_TRUE(isCandidateForAnimationOnCompositor(m_timing, *m_keyframeAnimationEffect2.get()));
    EXPECT_TRUE(isCandidateForAnimationOnCompositor(m_timing, *m_keyframeAnimationEffect5.get()));
}

TEST_F(AnimationCompositorAnimationsTest, isCandidateForAnimationOnCompositorTimingFunctionCubic)
{
    m_timing.timingFunction = m_cubicEaseTimingFunction;
    EXPECT_TRUE(isCandidateForAnimationOnCompositor(m_timing, *m_keyframeAnimationEffect2.get()));
    EXPECT_FALSE(isCandidateForAnimationOnCompositor(m_timing, *m_keyframeAnimationEffect5.get()));

    m_timing.timingFunction = m_cubicCustomTimingFunction;
    EXPECT_TRUE(isCandidateForAnimationOnCompositor(m_timing, *m_keyframeAnimationEffect2.get()));
    EXPECT_FALSE(isCandidateForAnimationOnCompositor(m_timing, *m_keyframeAnimationEffect5.get()));
}

TEST_F(AnimationCompositorAnimationsTest, isCandidateForAnimationOnCompositorTimingFunctionSteps)
{
    m_timing.timingFunction = m_stepTimingFunction;
    EXPECT_FALSE(isCandidateForAnimationOnCompositor(m_timing, *m_keyframeAnimationEffect2.get()));
    EXPECT_FALSE(isCandidateForAnimationOnCompositor(m_timing, *m_keyframeAnimationEffect5.get()));
}

TEST_F(AnimationCompositorAnimationsTest, isCandidateForAnimationOnCompositorTimingFunctionChainedLinear)
{
    EXPECT_TRUE(isCandidateForAnimationOnCompositor(m_timing, *m_keyframeAnimationEffect2.get()));
    EXPECT_TRUE(isCandidateForAnimationOnCompositor(m_timing, *m_keyframeAnimationEffect5.get()));
}

TEST_F(AnimationCompositorAnimationsTest, isCandidateForAnimationOnCompositorNonLinearTimingFunctionOnFirstFrame)
{
    m_timing.timingFunction = m_cubicEaseTimingFunction;

    EXPECT_TRUE(isCandidateForAnimationOnCompositor(m_timing, *m_keyframeAnimationEffect2.get()));

    (*m_keyframeVector2)[0]->setEasing(m_cubicEaseTimingFunction.get());
    m_keyframeAnimationEffect2 = AnimatableValueKeyframeEffectModel::create(*m_keyframeVector2);
    EXPECT_FALSE(isCandidateForAnimationOnCompositor(m_timing, *m_keyframeAnimationEffect2.get()));
}

TEST_F(AnimationCompositorAnimationsTest, isCandidateForAnimationOnCompositorTimingFunctionChainedCubicMatchingOffsets)
{
    (*m_keyframeVector2)[0]->setEasing(m_cubicEaseTimingFunction.get());
    m_keyframeAnimationEffect2 = AnimatableValueKeyframeEffectModel::create(*m_keyframeVector2);
    EXPECT_TRUE(isCandidateForAnimationOnCompositor(m_timing, *m_keyframeAnimationEffect2.get()));

    (*m_keyframeVector2)[0]->setEasing(m_cubicCustomTimingFunction.get());
    m_keyframeAnimationEffect2 = AnimatableValueKeyframeEffectModel::create(*m_keyframeVector2);
    EXPECT_TRUE(isCandidateForAnimationOnCompositor(m_timing, *m_keyframeAnimationEffect2.get()));

    (*m_keyframeVector5)[0]->setEasing(m_cubicEaseTimingFunction.get());
    (*m_keyframeVector5)[1]->setEasing(m_cubicCustomTimingFunction.get());
    (*m_keyframeVector5)[2]->setEasing(m_cubicCustomTimingFunction.get());
    (*m_keyframeVector5)[3]->setEasing(m_cubicCustomTimingFunction.get());
    m_keyframeAnimationEffect5 = AnimatableValueKeyframeEffectModel::create(*m_keyframeVector5);
    EXPECT_TRUE(isCandidateForAnimationOnCompositor(m_timing, *m_keyframeAnimationEffect5.get()));
}

TEST_F(AnimationCompositorAnimationsTest, isCandidateForAnimationOnCompositorTimingFunctionMixedGood)
{
    (*m_keyframeVector5)[0]->setEasing(m_linearTimingFunction.get());
    (*m_keyframeVector5)[1]->setEasing(m_cubicEaseTimingFunction.get());
    (*m_keyframeVector5)[2]->setEasing(m_cubicEaseTimingFunction.get());
    (*m_keyframeVector5)[3]->setEasing(m_linearTimingFunction.get());
    m_keyframeAnimationEffect5 = AnimatableValueKeyframeEffectModel::create(*m_keyframeVector5);
    EXPECT_TRUE(isCandidateForAnimationOnCompositor(m_timing, *m_keyframeAnimationEffect5.get()));
}

TEST_F(AnimationCompositorAnimationsTest, isCandidateForAnimationOnCompositorTimingFunctionWithStepNotOkay)
{
    (*m_keyframeVector2)[0]->setEasing(m_stepTimingFunction.get());
    m_keyframeAnimationEffect2 = AnimatableValueKeyframeEffectModel::create(*m_keyframeVector2);
    EXPECT_FALSE(isCandidateForAnimationOnCompositor(m_timing, *m_keyframeAnimationEffect2.get()));

    (*m_keyframeVector5)[0]->setEasing(m_stepTimingFunction.get());
    (*m_keyframeVector5)[1]->setEasing(m_linearTimingFunction.get());
    (*m_keyframeVector5)[2]->setEasing(m_cubicEaseTimingFunction.get());
    (*m_keyframeVector5)[3]->setEasing(m_linearTimingFunction.get());
    m_keyframeAnimationEffect5 = AnimatableValueKeyframeEffectModel::create(*m_keyframeVector5);
    EXPECT_FALSE(isCandidateForAnimationOnCompositor(m_timing, *m_keyframeAnimationEffect5.get()));

    (*m_keyframeVector5)[0]->setEasing(m_linearTimingFunction.get());
    (*m_keyframeVector5)[1]->setEasing(m_stepTimingFunction.get());
    (*m_keyframeVector5)[2]->setEasing(m_cubicEaseTimingFunction.get());
    (*m_keyframeVector5)[3]->setEasing(m_linearTimingFunction.get());
    m_keyframeAnimationEffect5 = AnimatableValueKeyframeEffectModel::create(*m_keyframeVector5);
    EXPECT_FALSE(isCandidateForAnimationOnCompositor(m_timing, *m_keyframeAnimationEffect5.get()));

    (*m_keyframeVector5)[0]->setEasing(m_linearTimingFunction.get());
    (*m_keyframeVector5)[1]->setEasing(m_cubicEaseTimingFunction.get());
    (*m_keyframeVector5)[2]->setEasing(m_cubicEaseTimingFunction.get());
    (*m_keyframeVector5)[3]->setEasing(m_stepTimingFunction.get());
    m_keyframeAnimationEffect5 = AnimatableValueKeyframeEffectModel::create(*m_keyframeVector5);
    EXPECT_FALSE(isCandidateForAnimationOnCompositor(m_timing, *m_keyframeAnimationEffect5.get()));
}

TEST_F(AnimationCompositorAnimationsTest, isCandidateForAnimationOnCompositor)
{
    Timing linearTiming(createCompositableTiming());

    AnimatableValueKeyframeVector basicFramesVector;
    basicFramesVector.append(createDefaultKeyframe(CSSPropertyOpacity, AnimationEffect::CompositeReplace, 0.0).get());
    basicFramesVector.append(createDefaultKeyframe(CSSPropertyOpacity, AnimationEffect::CompositeReplace, 1.0).get());

    AnimatableValueKeyframeVector nonBasicFramesVector;
    nonBasicFramesVector.append(createDefaultKeyframe(CSSPropertyOpacity, AnimationEffect::CompositeReplace, 0.0).get());
    nonBasicFramesVector.append(createDefaultKeyframe(CSSPropertyOpacity, AnimationEffect::CompositeReplace, 0.5).get());
    nonBasicFramesVector.append(createDefaultKeyframe(CSSPropertyOpacity, AnimationEffect::CompositeReplace, 1.0).get());

    basicFramesVector[0]->setEasing(m_linearTimingFunction.get());
    RefPtrWillBeRawPtr<AnimatableValueKeyframeEffectModel> basicFrames = AnimatableValueKeyframeEffectModel::create(basicFramesVector).get();
    EXPECT_TRUE(isCandidateForAnimationOnCompositor(linearTiming, *basicFrames.get()));

    basicFramesVector[0]->setEasing(CubicBezierTimingFunction::preset(CubicBezierTimingFunction::EaseIn));
    basicFrames = AnimatableValueKeyframeEffectModel::create(basicFramesVector).get();
    EXPECT_TRUE(isCandidateForAnimationOnCompositor(linearTiming, *basicFrames.get()));

    nonBasicFramesVector[0]->setEasing(m_linearTimingFunction.get());
    nonBasicFramesVector[1]->setEasing(CubicBezierTimingFunction::preset(CubicBezierTimingFunction::EaseIn));
    RefPtrWillBeRawPtr<AnimatableValueKeyframeEffectModel> nonBasicFrames = AnimatableValueKeyframeEffectModel::create(nonBasicFramesVector).get();
    EXPECT_TRUE(CompositorAnimations::instance()->isCandidateForAnimationOnCompositor(linearTiming, *nonBasicFrames.get()));
}

// -----------------------------------------------------------------------
// -----------------------------------------------------------------------

TEST_F(AnimationCompositorAnimationsTest, createSimpleOpacityAnimation)
{
    // Animation to convert
    RefPtrWillBeRawPtr<AnimatableValueKeyframeEffectModel> effect = createKeyframeEffectModel(
        createReplaceOpKeyframe(CSSPropertyOpacity, AnimatableDouble::create(2.0).get(), 0),
        createReplaceOpKeyframe(CSSPropertyOpacity, AnimatableDouble::create(5.0).get(), 1.0));
    // --

    WebCompositorSupportMock mockCompositor;

    // Curve is created
    WebFloatAnimationCurveMock* mockCurvePtr = new WebFloatAnimationCurveMock;
    ExpectationSet usesMockCurve;
    EXPECT_CALL(mockCompositor, createFloatAnimationCurve())
        .WillOnce(Return(mockCurvePtr));

    usesMockCurve += EXPECT_CALL(*mockCurvePtr, add(WebFloatKeyframe(0.0, 2.0), WebCompositorAnimationCurve::TimingFunctionTypeLinear));
    usesMockCurve += EXPECT_CALL(*mockCurvePtr, add(WebFloatKeyframe(1.0, 5.0)));

    // Create animation
    WebCompositorAnimationMock* mockAnimationPtr = new WebCompositorAnimationMock(WebCompositorAnimation::TargetPropertyOpacity);
    ExpectationSet usesMockAnimation;

    usesMockCurve += EXPECT_CALL(mockCompositor, createAnimation(Ref(*mockCurvePtr), WebCompositorAnimation::TargetPropertyOpacity, _))
        .WillOnce(Return(mockAnimationPtr));

    usesMockAnimation += EXPECT_CALL(*mockAnimationPtr, setIterations(1));
    usesMockAnimation += EXPECT_CALL(*mockAnimationPtr, setTimeOffset(0.0));
    usesMockAnimation += EXPECT_CALL(*mockAnimationPtr, setAlternatesDirection(false));

    EXPECT_CALL(*mockAnimationPtr, delete_())
        .Times(1)
        .After(usesMockAnimation);
    EXPECT_CALL(*mockCurvePtr, delete_())
        .Times(1)
        .After(usesMockCurve);

    // Go!
    setCompositorForTesting(mockCompositor);
    Vector<OwnPtr<WebCompositorAnimation> > result;
    getAnimationOnCompositor(m_timing, *effect.get(), result);
    EXPECT_EQ(1U, result.size());
    result[0].clear();
}

TEST_F(AnimationCompositorAnimationsTest, createSimpleOpacityAnimationDuration)
{
    // Animation to convert
    RefPtrWillBeRawPtr<AnimatableValueKeyframeEffectModel> effect = createKeyframeEffectModel(
        createReplaceOpKeyframe(CSSPropertyOpacity, AnimatableDouble::create(2.0).get(), 0),
        createReplaceOpKeyframe(CSSPropertyOpacity, AnimatableDouble::create(5.0).get(), 1.0));

    m_timing.iterationDuration = 10.0;
    // --

    WebCompositorSupportMock mockCompositor;

    // Curve is created
    WebFloatAnimationCurveMock* mockCurvePtr = new WebFloatAnimationCurveMock;
    ExpectationSet usesMockCurve;
    EXPECT_CALL(mockCompositor, createFloatAnimationCurve())
        .WillOnce(Return(mockCurvePtr));

    usesMockCurve += EXPECT_CALL(*mockCurvePtr, add(WebFloatKeyframe(0.0, 2.0), WebCompositorAnimationCurve::TimingFunctionTypeLinear));
    usesMockCurve += EXPECT_CALL(*mockCurvePtr, add(WebFloatKeyframe(10.0, 5.0)));

    // Create animation
    WebCompositorAnimationMock* mockAnimationPtr = new WebCompositorAnimationMock(WebCompositorAnimation::TargetPropertyOpacity);
    ExpectationSet usesMockAnimation;

    usesMockCurve += EXPECT_CALL(mockCompositor, createAnimation(Ref(*mockCurvePtr), WebCompositorAnimation::TargetPropertyOpacity, _))
        .WillOnce(Return(mockAnimationPtr));

    usesMockAnimation += EXPECT_CALL(*mockAnimationPtr, setIterations(1));
    usesMockAnimation += EXPECT_CALL(*mockAnimationPtr, setTimeOffset(0.0));
    usesMockAnimation += EXPECT_CALL(*mockAnimationPtr, setAlternatesDirection(false));

    EXPECT_CALL(*mockAnimationPtr, delete_())
        .Times(1)
        .After(usesMockAnimation);
    EXPECT_CALL(*mockCurvePtr, delete_())
        .Times(1)
        .After(usesMockCurve);

    // Go!
    setCompositorForTesting(mockCompositor);
    Vector<OwnPtr<WebCompositorAnimation> > result;
    getAnimationOnCompositor(m_timing, *effect.get(), result);
    EXPECT_EQ(1U, result.size());
    result[0].clear();
}

TEST_F(AnimationCompositorAnimationsTest, createMultipleKeyframeOpacityAnimationLinear)
{
    // Animation to convert
    RefPtrWillBeRawPtr<AnimatableValueKeyframeEffectModel> effect = createKeyframeEffectModel(
        createReplaceOpKeyframe(CSSPropertyOpacity, AnimatableDouble::create(2.0).get(), 0),
        createReplaceOpKeyframe(CSSPropertyOpacity, AnimatableDouble::create(-1.0).get(), 0.25),
        createReplaceOpKeyframe(CSSPropertyOpacity, AnimatableDouble::create(20.0).get(), 0.5),
        createReplaceOpKeyframe(CSSPropertyOpacity, AnimatableDouble::create(5.0).get(), 1.0));

    m_timing.iterationCount = 5;
    m_timing.direction = Timing::PlaybackDirectionAlternate;
    // --

    WebCompositorSupportMock mockCompositor;

    // Curve is created
    WebFloatAnimationCurveMock* mockCurvePtr = new WebFloatAnimationCurveMock();
    ExpectationSet usesMockCurve;

    EXPECT_CALL(mockCompositor, createFloatAnimationCurve())
        .WillOnce(Return(mockCurvePtr));

    usesMockCurve += EXPECT_CALL(*mockCurvePtr, add(WebFloatKeyframe(0.0, 2.0), WebCompositorAnimationCurve::TimingFunctionTypeLinear));
    usesMockCurve += EXPECT_CALL(*mockCurvePtr, add(WebFloatKeyframe(0.25, -1.0), WebCompositorAnimationCurve::TimingFunctionTypeLinear));
    usesMockCurve += EXPECT_CALL(*mockCurvePtr, add(WebFloatKeyframe(0.5, 20.0), WebCompositorAnimationCurve::TimingFunctionTypeLinear));
    usesMockCurve += EXPECT_CALL(*mockCurvePtr, add(WebFloatKeyframe(1.0, 5.0)));

    // Animation is created
    WebCompositorAnimationMock* mockAnimationPtr = new WebCompositorAnimationMock(WebCompositorAnimation::TargetPropertyOpacity);
    ExpectationSet usesMockAnimation;

    usesMockCurve += EXPECT_CALL(mockCompositor, createAnimation(Ref(*mockCurvePtr), WebCompositorAnimation::TargetPropertyOpacity, _))
        .WillOnce(Return(mockAnimationPtr));

    usesMockAnimation += EXPECT_CALL(*mockAnimationPtr, setIterations(5));
    usesMockAnimation += EXPECT_CALL(*mockAnimationPtr, setTimeOffset(0.0));
    usesMockAnimation += EXPECT_CALL(*mockAnimationPtr, setAlternatesDirection(true));

    EXPECT_CALL(*mockAnimationPtr, delete_())
        .Times(1)
        .After(usesMockAnimation);
    EXPECT_CALL(*mockCurvePtr, delete_())
        .Times(1)
        .After(usesMockCurve);

    // Go!
    setCompositorForTesting(mockCompositor);
    Vector<OwnPtr<WebCompositorAnimation> > result;
    getAnimationOnCompositor(m_timing, *effect.get(), result);
    EXPECT_EQ(1U, result.size());
    result[0].clear();
}

TEST_F(AnimationCompositorAnimationsTest, createSimpleOpacityAnimationStartDelay)
{
    // Animation to convert
    RefPtrWillBeRawPtr<AnimatableValueKeyframeEffectModel> effect = createKeyframeEffectModel(
        createReplaceOpKeyframe(CSSPropertyOpacity, AnimatableDouble::create(2.0).get(), 0),
        createReplaceOpKeyframe(CSSPropertyOpacity, AnimatableDouble::create(5.0).get(), 1.0));

    m_timing.iterationCount = 5.0;
    m_timing.iterationDuration = 1.75;
    m_timing.startDelay = 3.25;
    // --

    WebCompositorSupportMock mockCompositor;

    // Curve is created
    WebFloatAnimationCurveMock* mockCurvePtr = new WebFloatAnimationCurveMock;
    ExpectationSet usesMockCurve;
    EXPECT_CALL(mockCompositor, createFloatAnimationCurve())
        .WillOnce(Return(mockCurvePtr));

    usesMockCurve += EXPECT_CALL(*mockCurvePtr, add(WebFloatKeyframe(0.0, 2.0), WebCompositorAnimationCurve::TimingFunctionTypeLinear));
    usesMockCurve += EXPECT_CALL(*mockCurvePtr, add(WebFloatKeyframe(1.75, 5.0)));

    // Create animation
    WebCompositorAnimationMock* mockAnimationPtr = new WebCompositorAnimationMock(WebCompositorAnimation::TargetPropertyOpacity);
    ExpectationSet usesMockAnimation;

    usesMockCurve += EXPECT_CALL(mockCompositor, createAnimation(Ref(*mockCurvePtr), WebCompositorAnimation::TargetPropertyOpacity, _))
        .WillOnce(Return(mockAnimationPtr));

    usesMockAnimation += EXPECT_CALL(*mockAnimationPtr, setIterations(5));
    usesMockAnimation += EXPECT_CALL(*mockAnimationPtr, setTimeOffset(-3.25));
    usesMockAnimation += EXPECT_CALL(*mockAnimationPtr, setAlternatesDirection(false));

    EXPECT_CALL(*mockAnimationPtr, delete_())
        .Times(1)
        .After(usesMockAnimation);
    EXPECT_CALL(*mockCurvePtr, delete_())
        .Times(1)
        .After(usesMockCurve);

    // Go!
    setCompositorForTesting(mockCompositor);
    Vector<OwnPtr<WebCompositorAnimation> > result;
    getAnimationOnCompositor(m_timing, *effect.get(), result);
    EXPECT_EQ(1U, result.size());
    result[0].clear();
}

TEST_F(AnimationCompositorAnimationsTest, createMultipleKeyframeOpacityAnimationChained)
{
    // Animation to convert
    AnimatableValueKeyframeVector frames;
    frames.append(createReplaceOpKeyframe(CSSPropertyOpacity, AnimatableDouble::create(2.0).get(), 0));
    frames.append(createReplaceOpKeyframe(CSSPropertyOpacity, AnimatableDouble::create(-1.0).get(), 0.25));
    frames.append(createReplaceOpKeyframe(CSSPropertyOpacity, AnimatableDouble::create(20.0).get(), 0.5));
    frames.append(createReplaceOpKeyframe(CSSPropertyOpacity, AnimatableDouble::create(5.0).get(), 1.0));
    frames[0]->setEasing(m_cubicEaseTimingFunction.get());
    frames[1]->setEasing(m_linearTimingFunction.get());
    frames[2]->setEasing(m_cubicCustomTimingFunction.get());
    RefPtrWillBeRawPtr<AnimatableValueKeyframeEffectModel> effect = AnimatableValueKeyframeEffectModel::create(frames);

    m_timing.timingFunction = m_linearTimingFunction.get();
    m_timing.iterationDuration = 2.0;
    m_timing.iterationCount = 10;
    m_timing.direction = Timing::PlaybackDirectionAlternate;
    // --

    WebCompositorSupportMock mockCompositor;

    // Curve is created
    WebFloatAnimationCurveMock* mockCurvePtr = new WebFloatAnimationCurveMock();
    ExpectationSet usesMockCurve;

    EXPECT_CALL(mockCompositor, createFloatAnimationCurve())
        .WillOnce(Return(mockCurvePtr));

    usesMockCurve += EXPECT_CALL(*mockCurvePtr, add(WebFloatKeyframe(0.0, 2.0), WebCompositorAnimationCurve::TimingFunctionTypeEase));
    usesMockCurve += EXPECT_CALL(*mockCurvePtr, add(WebFloatKeyframe(0.5, -1.0), WebCompositorAnimationCurve::TimingFunctionTypeLinear));
    usesMockCurve += EXPECT_CALL(*mockCurvePtr, add(WebFloatKeyframe(1.0, 20.0), 1.0, 2.0, 3.0, 4.0));
    usesMockCurve += EXPECT_CALL(*mockCurvePtr, add(WebFloatKeyframe(2.0, 5.0)));

    // Animation is created
    WebCompositorAnimationMock* mockAnimationPtr = new WebCompositorAnimationMock(WebCompositorAnimation::TargetPropertyOpacity);
    ExpectationSet usesMockAnimation;

    usesMockCurve += EXPECT_CALL(mockCompositor, createAnimation(Ref(*mockCurvePtr), WebCompositorAnimation::TargetPropertyOpacity, _))
        .WillOnce(Return(mockAnimationPtr));

    usesMockAnimation += EXPECT_CALL(*mockAnimationPtr, setIterations(10));
    usesMockAnimation += EXPECT_CALL(*mockAnimationPtr, setTimeOffset(0.0));
    usesMockAnimation += EXPECT_CALL(*mockAnimationPtr, setAlternatesDirection(true));

    EXPECT_CALL(*mockAnimationPtr, delete_())
        .Times(1)
        .After(usesMockAnimation);
    EXPECT_CALL(*mockCurvePtr, delete_())
        .Times(1)
        .After(usesMockCurve);

    // Go!
    setCompositorForTesting(mockCompositor);
    Vector<OwnPtr<WebCompositorAnimation> > result;
    getAnimationOnCompositor(m_timing, *effect.get(), result);
    EXPECT_EQ(1U, result.size());
    result[0].clear();
}

TEST_F(AnimationCompositorAnimationsTest, createReversedOpacityAnimation)
{
    RefPtr<TimingFunction> cubicEasyFlipTimingFunction = CubicBezierTimingFunction::create(0.0, 0.0, 0.0, 1.0);

    // Animation to convert
    AnimatableValueKeyframeVector frames;
    frames.append(createReplaceOpKeyframe(CSSPropertyOpacity, AnimatableDouble::create(2.0).get(), 0));
    frames.append(createReplaceOpKeyframe(CSSPropertyOpacity, AnimatableDouble::create(-1.0).get(), 0.25));
    frames.append(createReplaceOpKeyframe(CSSPropertyOpacity, AnimatableDouble::create(20.0).get(), 0.5));
    frames.append(createReplaceOpKeyframe(CSSPropertyOpacity, AnimatableDouble::create(5.0).get(), 1.0));
    frames[0]->setEasing(CubicBezierTimingFunction::preset(CubicBezierTimingFunction::EaseIn));
    frames[1]->setEasing(m_linearTimingFunction.get());
    frames[2]->setEasing(cubicEasyFlipTimingFunction.get());
    RefPtrWillBeRawPtr<AnimatableValueKeyframeEffectModel> effect = AnimatableValueKeyframeEffectModel::create(frames);

    m_timing.timingFunction = m_linearTimingFunction.get();
    m_timing.iterationCount = 10;
    m_timing.direction = Timing::PlaybackDirectionAlternateReverse;
    // --

    WebCompositorSupportMock mockCompositor;

    // Curve is created
    WebFloatAnimationCurveMock* mockCurvePtr = new WebFloatAnimationCurveMock();
    ExpectationSet usesMockCurve;

    EXPECT_CALL(mockCompositor, createFloatAnimationCurve())
        .WillOnce(Return(mockCurvePtr));

    usesMockCurve += EXPECT_CALL(*mockCurvePtr, add(WebFloatKeyframe(0.0, 5.0), 1.0, 0.0, 1.0, 1.0));
    usesMockCurve += EXPECT_CALL(*mockCurvePtr, add(WebFloatKeyframe(0.5, 20.0), WebCompositorAnimationCurve::TimingFunctionTypeLinear));
    usesMockCurve += EXPECT_CALL(*mockCurvePtr, add(WebFloatKeyframe(0.75, -1.0), WebCompositorAnimationCurve::TimingFunctionTypeEaseOut));
    usesMockCurve += EXPECT_CALL(*mockCurvePtr, add(WebFloatKeyframe(1.0, 2.0)));

    // Create the animation
    WebCompositorAnimationMock* mockAnimationPtr = new WebCompositorAnimationMock(WebCompositorAnimation::TargetPropertyOpacity);
    ExpectationSet usesMockAnimation;

    usesMockCurve += EXPECT_CALL(mockCompositor, createAnimation(Ref(*mockCurvePtr), WebCompositorAnimation::TargetPropertyOpacity, _))
        .WillOnce(Return(mockAnimationPtr));

    usesMockAnimation += EXPECT_CALL(*mockAnimationPtr, setIterations(10));
    usesMockAnimation += EXPECT_CALL(*mockAnimationPtr, setTimeOffset(0.0));
    usesMockAnimation += EXPECT_CALL(*mockAnimationPtr, setAlternatesDirection(true));

    EXPECT_CALL(*mockAnimationPtr, delete_())
        .Times(1)
        .After(usesMockAnimation);
    EXPECT_CALL(*mockCurvePtr, delete_())
        .Times(1)
        .After(usesMockCurve);

    // Go!
    setCompositorForTesting(mockCompositor);
    Vector<OwnPtr<WebCompositorAnimation> > result;
    getAnimationOnCompositor(m_timing, *effect.get(), result);
    EXPECT_EQ(1U, result.size());
    result[0].clear();
}

TEST_F(AnimationCompositorAnimationsTest, createReversedOpacityAnimationNegativeStartDelay)
{
    // Animation to convert
    RefPtrWillBeRawPtr<AnimatableValueKeyframeEffectModel> effect = createKeyframeEffectModel(
        createReplaceOpKeyframe(CSSPropertyOpacity, AnimatableDouble::create(2.0).get(), 0),
        createReplaceOpKeyframe(CSSPropertyOpacity, AnimatableDouble::create(5.0).get(), 1.0));

    m_timing.iterationCount = 5.0;
    m_timing.iterationDuration = 1.5;
    m_timing.startDelay = -3;
    m_timing.direction = Timing::PlaybackDirectionAlternateReverse;
    // --

    WebCompositorSupportMock mockCompositor;

    // Curve is created
    WebFloatAnimationCurveMock* mockCurvePtr = new WebFloatAnimationCurveMock;
    ExpectationSet usesMockCurve;
    EXPECT_CALL(mockCompositor, createFloatAnimationCurve())
        .WillOnce(Return(mockCurvePtr));

    usesMockCurve += EXPECT_CALL(*mockCurvePtr, add(WebFloatKeyframe(0.0, 5.0), WebCompositorAnimationCurve::TimingFunctionTypeLinear));
    usesMockCurve += EXPECT_CALL(*mockCurvePtr, add(WebFloatKeyframe(1.5, 2.0)));

    // Create animation
    WebCompositorAnimationMock* mockAnimationPtr = new WebCompositorAnimationMock(WebCompositorAnimation::TargetPropertyOpacity);
    ExpectationSet usesMockAnimation;

    usesMockCurve += EXPECT_CALL(mockCompositor, createAnimation(Ref(*mockCurvePtr), WebCompositorAnimation::TargetPropertyOpacity, _))
        .WillOnce(Return(mockAnimationPtr));

    usesMockAnimation += EXPECT_CALL(*mockAnimationPtr, setIterations(5));
    usesMockAnimation += EXPECT_CALL(*mockAnimationPtr, setTimeOffset(3.0));
    usesMockAnimation += EXPECT_CALL(*mockAnimationPtr, setAlternatesDirection(true));

    EXPECT_CALL(*mockAnimationPtr, delete_())
        .Times(1)
        .After(usesMockAnimation);
    EXPECT_CALL(*mockCurvePtr, delete_())
        .Times(1)
        .After(usesMockCurve);

    // Go!
    setCompositorForTesting(mockCompositor);
    Vector<OwnPtr<WebCompositorAnimation> > result;
    getAnimationOnCompositor(m_timing, *effect.get(), result);
    EXPECT_EQ(1U, result.size());
    result[0].clear();
}


} // namespace blink
