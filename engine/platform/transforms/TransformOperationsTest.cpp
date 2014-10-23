/*
 * Copyright (C) 2014 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "platform/transforms/TransformOperations.h"

#include "platform/geometry/FloatBox.h"
#include "platform/geometry/FloatBoxTestHelpers.h"
#include "platform/transforms/IdentityTransformOperation.h"
#include "platform/transforms/Matrix3DTransformOperation.h"
#include "platform/transforms/MatrixTransformOperation.h"
#include "platform/transforms/PerspectiveTransformOperation.h"
#include "platform/transforms/RotateTransformOperation.h"
#include "platform/transforms/ScaleTransformOperation.h"
#include "platform/transforms/SkewTransformOperation.h"
#include "platform/transforms/TranslateTransformOperation.h"

#include <gtest/gtest.h>

using namespace blink;
namespace {

static const TransformOperations identityOperations;

static void EmpiricallyTestBounds(const TransformOperations& from,
    const TransformOperations& to,
    const double& minProgress,
    const double& maxProgress)
{
    FloatBox box(200, 500, 100, 100, 300, 200);
    FloatBox bounds;

    EXPECT_TRUE(to.blendedBoundsForBox(box, from, minProgress, maxProgress, &bounds));
    bool firstTime = true;

    FloatBox empiricalBounds;
    static const size_t numSteps = 10;
    for (size_t step = 0; step < numSteps; ++step) {
        float t = step / (numSteps - 1);
        t = minProgress + (maxProgress - minProgress) * t;
        TransformOperations operations = from.blend(to, t);
        TransformationMatrix matrix;
        operations.apply(FloatSize(0, 0), matrix);
        FloatBox transformed = box;
        matrix.transformBox(transformed);

        if (firstTime)
            empiricalBounds = transformed;
        else
            empiricalBounds.unionBounds(transformed);
        firstTime = false;
    }

    ASSERT_PRED_FORMAT2(FloatBoxTest::AssertContains, bounds, empiricalBounds);
}

TEST(TransformOperationsTest, AbsoluteAnimatedTranslatedBoundsTest)
{
    TransformOperations fromOps;
    TransformOperations toOps;
    fromOps.operations().append(TranslateTransformOperation::create(Length(-30, blink::Fixed), Length(20, blink::Fixed), 15, TransformOperation::Translate3D));
    toOps.operations().append(TranslateTransformOperation::create(Length(10, blink::Fixed), Length(10, blink::Fixed), 200, TransformOperation::Translate3D));
    FloatBox box(0, 0, 0, 10, 10, 10);
    FloatBox bounds;

    EXPECT_TRUE(toOps.blendedBoundsForBox(box, identityOperations, 0, 1, &bounds));
    EXPECT_PRED_FORMAT2(FloatBoxTest::AssertAlmostEqual, FloatBox(0, 0, 0, 20, 20, 210), bounds);

    EXPECT_TRUE(identityOperations.blendedBoundsForBox(box, toOps, 0, 1, &bounds));
    EXPECT_PRED_FORMAT2(FloatBoxTest::AssertAlmostEqual, FloatBox(0, 0, 0, 20, 20, 210), bounds);

    EXPECT_TRUE(identityOperations.blendedBoundsForBox(box, fromOps, 0, 1, &bounds));
    EXPECT_PRED_FORMAT2(FloatBoxTest::AssertAlmostEqual, FloatBox(-30, 0, 0, 40, 30, 25), bounds);

    EXPECT_TRUE(toOps.blendedBoundsForBox(box, fromOps, 0, 1, &bounds));
    EXPECT_PRED_FORMAT2(FloatBoxTest::AssertAlmostEqual, FloatBox(-30, 10, 15, 50, 20, 195), bounds);

    EXPECT_TRUE(toOps.blendedBoundsForBox(box, fromOps, -0.5, 1.25, &bounds));
    EXPECT_PRED_FORMAT2(FloatBoxTest::AssertAlmostEqual, FloatBox(-50, 7.5, -77.5, 80, 27.5, 333.75), bounds);
}

TEST(TransformOperationsTest, EmpiricalAnimatedTranslatedBoundsTest)
{
    float testTransforms[][2][3] = {
        { { 0, 0, 0 }, { 10, 10, 0 } } ,
        { { -100, 202.5, -32.6 }, { 43.2, 56.1, 89.75 } },
        { { 43.2, 56.1, 89.75 }, { -100, 202.5, -32.6 } }
    };

    // All progressions for animations start and end at 0, 1 respectively,
    // we can go outside of these bounds, but will always at least contain
    // [0,1].
    float progress[][2] = {
        { 0, 1 },
        { -.25, 1.25 }
    };

    for (size_t i = 0; i < WTF_ARRAY_LENGTH(testTransforms); ++i) {
        for (size_t j = 0; j < WTF_ARRAY_LENGTH(progress); ++j) {
            TransformOperations fromOps;
            TransformOperations toOps;
            fromOps.operations().append(TranslateTransformOperation::create(Length(testTransforms[i][0][0], blink::Fixed), Length(testTransforms[i][0][1], blink::Fixed), testTransforms[i][0][2], TransformOperation::Translate3D));
            toOps.operations().append(TranslateTransformOperation::create(Length(testTransforms[i][1][0], blink::Fixed), Length(testTransforms[i][1][1], blink::Fixed), testTransforms[i][1][2], TransformOperation::Translate3D));
            EmpiricallyTestBounds(fromOps, toOps, 0, 1);
        }
    }
}

TEST(TransformOperationsTest, AbsoluteAnimatedScaleBoundsTest)
{
    TransformOperations fromOps;
    TransformOperations toOps;
    fromOps.operations().append(ScaleTransformOperation::create(4, -3, TransformOperation::Scale));
    toOps.operations().append(ScaleTransformOperation::create(5, 2, TransformOperation::Scale));

    FloatBox box(0, 0, 0, 10, 10, 10);
    FloatBox bounds;

    EXPECT_TRUE(toOps.blendedBoundsForBox(box, identityOperations, 0, 1, &bounds));
    EXPECT_PRED_FORMAT2(FloatBoxTest::AssertAlmostEqual, FloatBox(0, 0, 0, 50, 20, 10), bounds);

    EXPECT_TRUE(identityOperations.blendedBoundsForBox(box, toOps, 0, 1, &bounds));
    EXPECT_PRED_FORMAT2(FloatBoxTest::AssertAlmostEqual, FloatBox(0, 0, 0, 50, 20, 10), bounds);

    EXPECT_TRUE(identityOperations.blendedBoundsForBox(box, fromOps, 0, 1, &bounds));
    EXPECT_PRED_FORMAT2(FloatBoxTest::AssertAlmostEqual, FloatBox(0, -30, 0, 40, 40, 10), bounds);

    EXPECT_TRUE(toOps.blendedBoundsForBox(box, fromOps, 0, 1, &bounds));
    EXPECT_PRED_FORMAT2(FloatBoxTest::AssertAlmostEqual, FloatBox(0, -30, 0, 50, 50, 10), bounds);

    EXPECT_TRUE(toOps.blendedBoundsForBox(box, fromOps, -0.5, 1.25, &bounds));
    EXPECT_PRED_FORMAT2(FloatBoxTest::AssertAlmostEqual, FloatBox(0, -55, 0, 52.5, 87.5, 10), bounds);
}

TEST(TransformOperationsTest, EmpiricalAnimatedScaleBoundsTest)
{

    float testTransforms[][2][3] = {
        { { 1, 1, 1 }, { 10, 10, -32}},
        { { 1, 2, 5 }, { -1, -2, -4}},
        { { 0, 0, 0 }, { 1, 2, 3}},
        { { 0, 0, 0 }, { 0, 0, 0}}
    };

    // All progressions for animations start and end at 0, 1 respectively,
    // we can go outside of these bounds, but will always at least contain
    // [0,1].
    float progress[][2] = {
        { 0, 1 },
        { -.25f, 1.25f }
    };

    for (size_t i = 0; i < WTF_ARRAY_LENGTH(testTransforms); ++i) {
        for (size_t j = 0; j < WTF_ARRAY_LENGTH(progress); ++j) {
            TransformOperations fromOps;
            TransformOperations toOps;
            fromOps.operations().append(TranslateTransformOperation::create(Length(testTransforms[i][0][0], blink::Fixed), Length(testTransforms[i][0][1], blink::Fixed), testTransforms[i][0][2], TransformOperation::Translate3D));
            toOps.operations().append(TranslateTransformOperation::create(Length(testTransforms[i][1][0], blink::Fixed), Length(testTransforms[i][1][1], blink::Fixed), testTransforms[i][1][2], TransformOperation::Translate3D));
            EmpiricallyTestBounds(fromOps, toOps, 0, 1);
        }
    }
}

TEST(TransformOperationsTest, AbsoluteAnimatedRotationBounds)
{
    TransformOperations fromOps;
    TransformOperations toOps;
    fromOps.operations().append(RotateTransformOperation::create(0, TransformOperation::Rotate));
    toOps.operations().append(RotateTransformOperation::create(360, TransformOperation::Rotate));
    float sqrt2 = sqrt(2.0f);
    FloatBox box(-sqrt2, -sqrt2, 0, sqrt2, sqrt2, 0);
    FloatBox bounds;

    // Since we're rotating 360 degrees, any box with dimensions between 0 and
    // 2 * sqrt(2) should give the same result.
    float sizes[] = { 0, 0.1f, sqrt2, 2*sqrt2 };
    toOps.blendedBoundsForBox(box, fromOps, 0, 1, &bounds);
    for (size_t i = 0; i < WTF_ARRAY_LENGTH(sizes); ++i) {
        box.setSize(FloatPoint3D(sizes[i], sizes[i], 0));

        EXPECT_TRUE(toOps.blendedBoundsForBox(box, fromOps, 0, 1, &bounds));
        EXPECT_PRED_FORMAT2(FloatBoxTest::AssertAlmostEqual, FloatBox(-2, -2, 0, 4, 4, 0), bounds);
    }
}

TEST(TransformOperationsTest, AbsoluteAnimatedExtremeRotationBounds)
{
    // If the normal is off-plane, we can have up to 6 exrema (min/max in each
    // dimension between) the endpoints of the arg. This makes sure we are
    // catching all 6.
    TransformOperations fromOps;
    TransformOperations toOps;
    fromOps.operations().append(RotateTransformOperation::create(1, 1, 1, 30, TransformOperation::Rotate3D));
    toOps.operations().append(RotateTransformOperation::create(1, 1, 1, 390,  TransformOperation::Rotate3D));

    FloatBox box(1, 0, 0, 0, 0, 0);
    FloatBox bounds;
    float min = -1 / 3.0f;
    float max = 1;
    float size = max - min;
    EXPECT_TRUE(toOps.blendedBoundsForBox(box, fromOps, 0, 1, &bounds));
    EXPECT_PRED_FORMAT2(FloatBoxTest::AssertAlmostEqual, FloatBox(min, min, min, size, size, size), bounds);
}

TEST(TransformOperationsTest, AbsoluteAnimatedAxisRotationBounds)
{
    // We can handle rotations about a single axis. If the axes are different,
    // we revert to matrix interpolation for which inflated bounds cannot be
    // computed.
    TransformOperations fromOps;
    TransformOperations toSame;
    TransformOperations toOpposite;
    TransformOperations toDifferent;
    fromOps.operations().append(RotateTransformOperation::create(1, 1, 1, 30, TransformOperation::Rotate3D));
    toSame.operations().append(RotateTransformOperation::create(1, 1, 1, 390,  TransformOperation::Rotate3D));
    toOpposite.operations().append(RotateTransformOperation::create(-1, -1, -1, 390,  TransformOperation::Rotate3D));
    toDifferent.operations().append(RotateTransformOperation::create(1, 3, 1, 390,  TransformOperation::Rotate3D));

    FloatBox box(1, 0, 0, 0, 0, 0);
    FloatBox bounds;
    EXPECT_TRUE(toSame.blendedBoundsForBox(box, fromOps, 0, 1, &bounds));
    EXPECT_TRUE(toOpposite.blendedBoundsForBox(box, fromOps, 0, 1, &bounds));
    EXPECT_FALSE(toDifferent.blendedBoundsForBox(box, fromOps, 0, 1, &bounds));
}

TEST(TransformOperationsTest, AbsoluteAnimatedOnAxisRotationBounds)
{
    // If we rotate a point that is on the axis of rotation, the box should not
    // change at all.
    TransformOperations fromOps;
    TransformOperations toOps;
    fromOps.operations().append(RotateTransformOperation::create(1, 1, 1, 30, TransformOperation::Rotate3D));
    toOps.operations().append(RotateTransformOperation::create(1, 1, 1, 390,  TransformOperation::Rotate3D));

    FloatBox box(1, 1, 1, 0, 0, 0);
    FloatBox bounds;

    EXPECT_TRUE(toOps.blendedBoundsForBox(box, fromOps, 0, 1, &bounds));
    EXPECT_PRED_FORMAT2(FloatBoxTest::AssertAlmostEqual, box, bounds);
}

// This would have been best as anonymous structs, but |WTF_ARRAY_LENGTH|
// does not get along with anonymous structs once we support C++11
// WTF_ARRAY_LENGTH will automatically support anonymous structs.

struct ProblematicAxisTest {
    double x;
    double y;
    double z;
    FloatBox expected;
};

TEST(TransformOperationsTest, AbsoluteAnimatedProblematicAxisRotationBounds)
{
    // Zeros in the components of the axis osf rotation turned out to be tricky to
    // deal with in practice. This function tests some potentially problematic
    // axes to ensure sane behavior.

    // Some common values used in the expected boxes.
    float dim1 = 0.292893f;
    float dim2 = sqrt(2.0f);
    float dim3 = 2 * dim2;

    ProblematicAxisTest tests[] = {
        { 0, 0, 0, FloatBox(1, 1, 1, 0, 0, 0) },
        { 1, 0, 0, FloatBox(1, -dim2, -dim2, 0, dim3, dim3) },
        { 0, 1, 0, FloatBox(-dim2, 1, -dim2, dim3, 0, dim3) },
        { 0, 0, 1, FloatBox(-dim2, -dim2, 1, dim3, dim3, 0) },
        { 1, 1, 0, FloatBox(dim1, dim1, -1, dim2, dim2, 2) },
        { 0, 1, 1, FloatBox(-1, dim1, dim1, 2, dim2, dim2) },
        { 1, 0, 1, FloatBox(dim1, -1, dim1, dim2, 2, dim2) }
    };

    for (size_t i = 0; i < WTF_ARRAY_LENGTH(tests); ++i) {
        float x = tests[i].x;
        float y = tests[i].y;
        float z = tests[i].z;
        TransformOperations fromOps;
        fromOps.operations().append(RotateTransformOperation::create(x, y, z, 0, TransformOperation::Rotate3D));
        TransformOperations toOps;
        toOps.operations().append(RotateTransformOperation::create(x, y, z, 360, TransformOperation::Rotate3D));
        FloatBox box(1, 1, 1, 0, 0, 0);
        FloatBox bounds;

        EXPECT_TRUE(toOps.blendedBoundsForBox(
            box, fromOps, 0, 1, &bounds));
        EXPECT_PRED_FORMAT2(FloatBoxTest::AssertAlmostEqual, tests[i].expected, bounds);
    }
}


TEST(TransformOperationsTest, BlendedBoundsForRotationEmpiricalTests)
{
    float axes[][3] = {
        { 1, 1, 1 },
        { -1, -1, -1 },
        { -1, 2, 3 },
        { 1, -2, 3 },
        { 0, 0, 0 },
        { 1, 0, 0 },
        { 0, 1, 0 },
        { 0, 0, 1 },
        { 1, 1, 0 },
        { 0, 1, 1 },
        { 1, 0, 1 },
        { -1, 0, 0 },
        { 0, -1, 0 },
        { 0, 0, -1 },
        { -1, -1, 0 },
        { 0, -1, -1 },
        { -1, 0, -1 }
    };

    float angles[][2] = {
        { 5, 100 },
        { 10, 5 },
        { 0, 360 },
        { 20, 180 },
        { -20, -180 },
        { 180, -220 },
        { 220, 320 },
        { 1020, 1120 },
        {-3200, 120 },
        {-9000, -9050 }
    };

    float progress[][2] = {
        { 0, 1 },
        { -0.25f, 1.25f }
    };

    for (size_t i = 0; i < WTF_ARRAY_LENGTH(axes); ++i) {
        for (size_t j = 0; j < WTF_ARRAY_LENGTH(angles); ++j) {
            for (size_t k = 0; k < WTF_ARRAY_LENGTH(progress); ++k) {
                float x = axes[i][0];
                float y = axes[i][1];
                float z = axes[i][2];

                TransformOperations fromOps;
                TransformOperations toOps;

                fromOps.operations().append(RotateTransformOperation::create(x, y, z, angles[j][0], TransformOperation::Rotate3D));
                toOps.operations().append(RotateTransformOperation::create(x, y, z, angles[j][1], TransformOperation::Rotate3D));
                EmpiricallyTestBounds(fromOps, toOps, progress[k][0], progress[k][1]);
            }
        }
    }
}

TEST(TransformOperationsTest, AbsoluteAnimatedPerspectiveBoundsTest)
{
    TransformOperations fromOps;
    TransformOperations toOps;
    fromOps.operations().append(PerspectiveTransformOperation::create(10));
    toOps.operations().append(PerspectiveTransformOperation::create(30));
    FloatBox box(0, 0, 0, 10, 10, 10);
    FloatBox bounds;
    toOps.blendedBoundsForBox(box, fromOps, 0, 1, &bounds);
    EXPECT_PRED_FORMAT2(FloatBoxTest::AssertAlmostEqual, FloatBox(0, 0, 0, 15, 15, 15), bounds);

    fromOps.blendedBoundsForBox(box, toOps, -0.25, 1.25, &bounds);
    EXPECT_PRED_FORMAT2(FloatBoxTest::AssertAlmostEqual, FloatBox(-40, -40, -40, 52, 52, 52), bounds);
}

TEST(TransformOperationsTest, EmpiricalAnimatedPerspectiveBoundsTest)
{
    float depths[][2] = {
        { 600, 400 },
        { 800, 1000 },
        { 800, std::numeric_limits<float>::infinity() }
    };

    float progress[][2] = {
        { 0, 1 },
        {-0.1f, 1.1f }
    };

    for (size_t i = 0; i < WTF_ARRAY_LENGTH(depths); ++i) {
        for (size_t j = 0; j < WTF_ARRAY_LENGTH(progress); ++j) {
            TransformOperations fromOps;
            TransformOperations toOps;

            fromOps.operations().append(PerspectiveTransformOperation::create(depths[i][0]));
            toOps.operations().append(PerspectiveTransformOperation::create(depths[i][1]));

            EmpiricallyTestBounds(fromOps, toOps, progress[j][0], progress[j][1]);
        }
    }
}


TEST(TransformOperationsTest, AnimatedSkewBoundsTest)
{
    TransformOperations fromOps;
    TransformOperations toOps;
    fromOps.operations().append(SkewTransformOperation::create(-45, 0, TransformOperation::Skew));
    toOps.operations().append(SkewTransformOperation::create(0, 45, TransformOperation::Skew));
    FloatBox box(0, 0, 0, 10, 10, 10);
    FloatBox bounds;

    toOps.blendedBoundsForBox(box, identityOperations, 0, 1, &bounds);
    ASSERT_PRED_FORMAT2(FloatBoxTest::AssertAlmostEqual, FloatBox(0, 0, 0, 10, 20, 10), bounds);

    identityOperations.blendedBoundsForBox(box, fromOps, 0, 1, &bounds);
    ASSERT_PRED_FORMAT2(FloatBoxTest::AssertAlmostEqual, FloatBox(-10, 0, 0, 20, 10, 10), bounds);

    toOps.blendedBoundsForBox(box, fromOps, 0, 1, &bounds);
    ASSERT_PRED_FORMAT2(FloatBoxTest::AssertAlmostEqual, FloatBox(-10, 0, 0, 20, 20, 10), bounds);

    fromOps.blendedBoundsForBox(box, toOps, 0, 1, &bounds);
    ASSERT_PRED_FORMAT2(FloatBoxTest::AssertAlmostEqual, FloatBox(-10, 0, 0, 20, 20, 10), bounds);
}

TEST(TransformOperationsTest, NonCommutativeRotations)
{
    TransformOperations fromOps;
    fromOps.operations().append(RotateTransformOperation::create(1, 0, 0, 0, TransformOperation::Rotate3D));
    fromOps.operations().append(RotateTransformOperation::create(0, 1, 0, 0, TransformOperation::Rotate3D));
    TransformOperations toOps;
    toOps.operations().append(RotateTransformOperation::create(1, 0, 0, 45, TransformOperation::Rotate3D));
    toOps.operations().append(RotateTransformOperation::create(0, 1, 0, 135, TransformOperation::Rotate3D));

    FloatBox box(0, 0, 0, 1, 1, 1);
    FloatBox bounds;

    double minProgress = 0;
    double maxProgress = 1;
    EXPECT_TRUE(toOps.blendedBoundsForBox(
        box, fromOps, minProgress, maxProgress, &bounds));

    TransformOperations operations = toOps.blend(fromOps, maxProgress);
    TransformationMatrix blendedTransform;
    operations.apply(FloatSize(0, 0), blendedTransform);

    FloatPoint3D blendedPoint(0.9f, 0.9f, 0);
    blendedPoint = blendedTransform.mapPoint(blendedPoint);
    FloatBox expandedBounds = bounds;
    expandedBounds.expandTo(blendedPoint);

    ASSERT_PRED_FORMAT2(FloatBoxTest::AssertAlmostEqual, bounds, expandedBounds);
}

TEST(TransformOperationsTest, AbsoluteSequenceBoundsTest)
{
    TransformOperations fromOps;
    TransformOperations toOps;

    fromOps.operations().append(TranslateTransformOperation::create(Length(1, Fixed), Length(-5, Fixed), 1, TransformOperation::Translate3D));
    fromOps.operations().append(ScaleTransformOperation::create(-1, 2, 3, TransformOperation::Scale3D));
    fromOps.operations().append(TranslateTransformOperation::create(Length(2, Fixed), Length(4, Fixed), -1, TransformOperation::Translate3D));

    toOps.operations().append(TranslateTransformOperation::create(Length(13, Fixed), Length(-1, Fixed), 5, TransformOperation::Translate3D));
    toOps.operations().append(ScaleTransformOperation::create(-3, -2, 5, TransformOperation::Scale3D));
    toOps.operations().append(TranslateTransformOperation::create(Length(6, Fixed), Length(-2, Fixed), 3, TransformOperation::Translate3D));

    FloatBox box(1, 2, 3, 4, 4, 4);
    FloatBox bounds;

    EXPECT_TRUE(toOps.blendedBoundsForBox(box, fromOps, -0.5, 1.5, &bounds));
    EXPECT_PRED_FORMAT2(FloatBoxTest::AssertAlmostEqual, FloatBox(-57, -59, -1, 76, 112, 80), bounds);

    EXPECT_TRUE(toOps.blendedBoundsForBox(box, fromOps, 0, 1, &bounds));
    EXPECT_PRED_FORMAT2(FloatBoxTest::AssertAlmostEqual, FloatBox(-32, -25, 7, 42, 44, 48), bounds);

    EXPECT_TRUE(toOps.blendedBoundsForBox(box, identityOperations, 0, 1, &bounds));
    EXPECT_PRED_FORMAT2(FloatBoxTest::AssertAlmostEqual, FloatBox(-33, -13, 3, 57, 19, 52), bounds);

    EXPECT_TRUE(identityOperations.blendedBoundsForBox(box, fromOps, 0, 1, &bounds));
    EXPECT_PRED_FORMAT2(FloatBoxTest::AssertAlmostEqual, FloatBox(-7, -3, 2, 15, 23, 20), bounds);
}

} // namespace
