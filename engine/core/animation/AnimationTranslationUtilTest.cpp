/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
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

#include "core/animation/AnimationTranslationUtil.h"

#include "core/animation/css/CSSAnimationData.h"
#include "platform/animation/KeyframeValueList.h"
#include "platform/geometry/IntSize.h"
#include "platform/graphics/filters/FilterOperations.h"
#include "platform/transforms/Matrix3DTransformOperation.h"
#include "platform/transforms/RotateTransformOperation.h"
#include "platform/transforms/ScaleTransformOperation.h"
#include "platform/transforms/TransformOperations.h"
#include "platform/transforms/TranslateTransformOperation.h"
#include "public/platform/WebCompositorAnimation.h"
#include "public/platform/WebFilterOperations.h"
#include "public/platform/WebTransformOperations.h"
#include "wtf/RefPtr.h"
#include <gmock/gmock.h>
#include <gtest/gtest.h>

using namespace blink;

namespace {

class WebTransformOperationsMock : public WebTransformOperations {
public:
    MOCK_CONST_METHOD1(canBlendWith, bool(const WebTransformOperations&));
    MOCK_METHOD3(appendTranslate, void(double, double, double));
    MOCK_METHOD4(appendRotate, void(double, double, double, double));
    MOCK_METHOD3(appendScale, void(double, double, double));
    MOCK_METHOD2(appendSkew, void(double, double));
    MOCK_METHOD1(appendPerspective, void(double));
    MOCK_METHOD1(appendMatrix, void(const SkMatrix44&));
    MOCK_METHOD0(appendIdentity, void());
    MOCK_CONST_METHOD0(isIdentity, bool());
};

class WebFilterOperationsMock : public WebFilterOperations {
public:
    MOCK_METHOD1(appendGrayscaleFilter, void(float));
    MOCK_METHOD1(appendSepiaFilter, void(float));
    MOCK_METHOD1(appendSaturateFilter, void(float));
    MOCK_METHOD1(appendHueRotateFilter, void(float));
    MOCK_METHOD1(appendInvertFilter, void(float));
    MOCK_METHOD1(appendBrightnessFilter, void(float));
    MOCK_METHOD1(appendContrastFilter, void(float));
    MOCK_METHOD1(appendOpacityFilter, void(float));
    MOCK_METHOD1(appendBlurFilter, void(float));
    MOCK_METHOD3(appendDropShadowFilter, void(WebPoint, float, WebColor));
    MOCK_METHOD1(appendColorMatrixFilter, void(SkScalar[20]));
    MOCK_METHOD2(appendZoomFilter, void(float, int));
    MOCK_METHOD1(appendSaturatingBrightnessFilter, void(float));
    MOCK_METHOD1(appendReferenceFilter, void(SkImageFilter*));
    MOCK_METHOD0(clear, void());
};

TEST(AnimationTranslationUtilTest, transformsWork)
{
    TransformOperations ops;
    WebTransformOperationsMock outOps;

    EXPECT_CALL(outOps, appendTranslate(2, 0, 0));
    EXPECT_CALL(outOps, appendRotate(0.1, 0.2, 0.3, 200000.4));
    EXPECT_CALL(outOps, appendScale(50.2, 100, -4));

    ops.operations().append(TranslateTransformOperation::create(Length(2, Fixed), Length(0, Fixed), TransformOperation::TranslateX));
    ops.operations().append(RotateTransformOperation::create(0.1, 0.2, 0.3, 200000.4, TransformOperation::Rotate3D));
    ops.operations().append(ScaleTransformOperation::create(50.2, 100, -4, TransformOperation::Scale3D));
    toWebTransformOperations(ops, &outOps);
}

TEST(AnimationTranslationUtilTest, filtersWork)
{
    FilterOperations ops;
    WebFilterOperationsMock outOps;

    EXPECT_CALL(outOps, appendSaturateFilter(0.5));
    EXPECT_CALL(outOps, appendGrayscaleFilter(0.2f));
    EXPECT_CALL(outOps, appendSepiaFilter(0.8f));
    EXPECT_CALL(outOps, appendOpacityFilter(0.1f));

    ops.operations().append(BasicColorMatrixFilterOperation::create(0.5, FilterOperation::SATURATE));
    ops.operations().append(BasicColorMatrixFilterOperation::create(0.2, FilterOperation::GRAYSCALE));
    ops.operations().append(BasicColorMatrixFilterOperation::create(0.8, FilterOperation::SEPIA));
    ops.operations().append(BasicColorMatrixFilterOperation::create(0.1, FilterOperation::OPACITY));
    toWebFilterOperations(ops, &outOps);
}

}

