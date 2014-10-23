/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
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

#include "SkImageFilter.h"
#include "platform/graphics/filters/FEBlend.h"
#include "platform/graphics/filters/FEGaussianBlur.h"
#include "platform/graphics/filters/FEMerge.h"
#include "platform/graphics/filters/FilterOperations.h"
#include "platform/graphics/filters/ReferenceFilter.h"
#include "platform/graphics/filters/SkiaImageFilterBuilder.h"
#include "platform/graphics/filters/SourceGraphic.h"
#include <gtest/gtest.h>

using testing::Test;
using namespace blink;

class ImageFilterBuilderTest : public Test {
protected:
    void colorSpaceTest()
    {
        // Build filter tree
        RefPtr<ReferenceFilter> referenceFilter = ReferenceFilter::create();

        // Add a dummy source graphic input
        RefPtr<FilterEffect> sourceEffect = referenceFilter->sourceGraphic();
        sourceEffect->setOperatingColorSpace(ColorSpaceDeviceRGB);

        // Add a blur effect (with input : source)
        RefPtr<FilterEffect> blurEffect =
            FEGaussianBlur::create(referenceFilter.get(), 3.0f, 3.0f);
        blurEffect->setOperatingColorSpace(ColorSpaceLinearRGB);
        blurEffect->inputEffects().append(sourceEffect);

        // Add a blend effect (with inputs : blur, source)
        RefPtr<FilterEffect> blendEffect =
            FEBlend::create(referenceFilter.get(), WebBlendModeNormal);
        blendEffect->setOperatingColorSpace(ColorSpaceDeviceRGB);
        FilterEffectVector& blendInputs = blendEffect->inputEffects();
        blendInputs.reserveCapacity(2);
        blendInputs.append(sourceEffect);
        blendInputs.append(blurEffect);

        // Add a merge effect (with inputs : blur, blend)
        RefPtr<FilterEffect> mergeEffect = FEMerge::create(referenceFilter.get());
        mergeEffect->setOperatingColorSpace(ColorSpaceLinearRGB);
        FilterEffectVector& mergeInputs = mergeEffect->inputEffects();
        mergeInputs.reserveCapacity(2);
        mergeInputs.append(blurEffect);
        mergeInputs.append(blendEffect);
        referenceFilter->setLastEffect(mergeEffect);

        // Get SkImageFilter resulting tree
        SkiaImageFilterBuilder builder;
        RefPtr<SkImageFilter> filter = builder.build(referenceFilter->lastEffect(), ColorSpaceDeviceRGB);

        // Let's check that the resulting tree looks like this :
        //      ColorSpace (Linear->Device) : CS (L->D)
        //                |
        //             Merge (L)
        //              |     |
        //              |    CS (D->L)
        //              |          |
        //              |      Blend (D)
        //              |       /    |
        //              |  CS (L->D) |
        //              |  /         |
        //             Blur (L)      |
        //                 \         |
        //               CS (D->L)   |
        //                   \       |
        //                 Source Graphic (D)

        EXPECT_EQ(filter->countInputs(), 1); // Should be CS (L->D)
        SkImageFilter* child = filter->getInput(0); // Should be Merge
        EXPECT_EQ(child->asColorFilter(0), false);
        EXPECT_EQ(child->countInputs(), 2);
        child = child->getInput(1); // Should be CS (D->L)
        EXPECT_EQ(child->asColorFilter(0), true);
        EXPECT_EQ(child->countInputs(), 1);
        child = child->getInput(0); // Should be Blend
        EXPECT_EQ(child->asColorFilter(0), false);
        EXPECT_EQ(child->countInputs(), 2);
        child = child->getInput(0); // Should be CS (L->D)
        EXPECT_EQ(child->asColorFilter(0), true);
        EXPECT_EQ(child->countInputs(), 1);
        child = child->getInput(0); // Should be Blur
        EXPECT_EQ(child->asColorFilter(0), false);
        EXPECT_EQ(child->countInputs(), 1);
        child = child->getInput(0); // Should be CS (D->L)
        EXPECT_EQ(child->asColorFilter(0), true);
        EXPECT_EQ(child->countInputs(), 1);
    }
};

namespace {

TEST_F(ImageFilterBuilderTest, testColorSpace)
{
    colorSpaceTest();
}

} // namespace
