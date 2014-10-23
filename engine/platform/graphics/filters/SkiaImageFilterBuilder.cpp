/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
#include "config.h"

#include "platform/graphics/filters/SkiaImageFilterBuilder.h"

#include "SkBlurImageFilter.h"
#include "SkColorFilterImageFilter.h"
#include "SkColorMatrixFilter.h"
#include "SkDropShadowImageFilter.h"
#include "SkMatrixImageFilter.h"
#include "SkTableColorFilter.h"
#include "platform/graphics/ImageBuffer.h"
#include "platform/graphics/filters/FilterEffect.h"
#include "platform/graphics/filters/FilterOperations.h"
#include "platform/graphics/filters/SourceGraphic.h"
#include "platform/graphics/skia/SkiaUtils.h"
#include "public/platform/WebPoint.h"

namespace blink {

SkiaImageFilterBuilder::SkiaImageFilterBuilder()
    : m_context(0)
    , m_sourceGraphic(0)
{
}

SkiaImageFilterBuilder::SkiaImageFilterBuilder(GraphicsContext* context)
    : m_context(context)
    , m_sourceGraphic(0)
{
}

SkiaImageFilterBuilder::~SkiaImageFilterBuilder()
{
}

PassRefPtr<SkImageFilter> SkiaImageFilterBuilder::build(FilterEffect* effect, ColorSpace colorSpace, bool destinationRequiresValidPreMultipliedPixels)
{
    if (!effect)
        return nullptr;

    bool requiresPMColorValidation = effect->mayProduceInvalidPreMultipliedPixels() && destinationRequiresValidPreMultipliedPixels;

    if (SkImageFilter* filter = effect->getImageFilter(colorSpace, requiresPMColorValidation))
        return filter;

    // Note that we may still need the color transform even if the filter is null
    RefPtr<SkImageFilter> origFilter = requiresPMColorValidation ? effect->createImageFilter(this) : effect->createImageFilterWithoutValidation(this);
    RefPtr<SkImageFilter> filter = transformColorSpace(origFilter.get(), effect->operatingColorSpace(), colorSpace);
    effect->setImageFilter(colorSpace, requiresPMColorValidation, filter.get());
    if (filter.get() != origFilter.get())
        effect->setImageFilter(effect->operatingColorSpace(), requiresPMColorValidation, origFilter.get());
    return filter.release();
}

PassRefPtr<SkImageFilter> SkiaImageFilterBuilder::transformColorSpace(
    SkImageFilter* input, ColorSpace srcColorSpace, ColorSpace dstColorSpace) {

    RefPtr<SkColorFilter> colorFilter = ImageBuffer::createColorSpaceFilter(srcColorSpace, dstColorSpace);
    if (!colorFilter)
        return input;

    return adoptRef(SkColorFilterImageFilter::Create(colorFilter.get(), input));
}

void SkiaImageFilterBuilder::buildFilterOperations(const FilterOperations& operations, WebFilterOperations* filters)
{
    ColorSpace currentColorSpace = ColorSpaceDeviceRGB;
    SkImageFilter* const nullFilter = 0;

    for (size_t i = 0; i < operations.size(); ++i) {
        const FilterOperation& op = *operations.at(i);
        switch (op.type()) {
        case FilterOperation::REFERENCE: {
            RefPtr<SkImageFilter> filter;
            ReferenceFilter* referenceFilter = toReferenceFilterOperation(op).filter();
            if (referenceFilter && referenceFilter->lastEffect()) {
                FilterEffect* filterEffect = referenceFilter->lastEffect();
                // Prepopulate SourceGraphic with two image filters: one with a null image
                // filter, and the other with a colorspace conversion filter.
                // We don't know what color space the interior nodes will request, so we have to
                // initialize SourceGraphic with both options.
                // Since we know SourceGraphic is always PM-valid, we also use
                // these for the PM-validated options.
                RefPtr<SkImageFilter> deviceFilter = transformColorSpace(nullFilter, currentColorSpace, ColorSpaceDeviceRGB);
                RefPtr<SkImageFilter> linearFilter = transformColorSpace(nullFilter, currentColorSpace, ColorSpaceLinearRGB);
                FilterEffect* sourceGraphic = referenceFilter->sourceGraphic();
                sourceGraphic->setImageFilter(ColorSpaceDeviceRGB, false, deviceFilter.get());
                sourceGraphic->setImageFilter(ColorSpaceLinearRGB, false, linearFilter.get());
                sourceGraphic->setImageFilter(ColorSpaceDeviceRGB, true, deviceFilter.get());
                sourceGraphic->setImageFilter(ColorSpaceLinearRGB, true, linearFilter.get());

                currentColorSpace = filterEffect->operatingColorSpace();
                filter = SkiaImageFilterBuilder::build(filterEffect, currentColorSpace);
                filters->appendReferenceFilter(filter.get());
            }
            break;
        }
        case FilterOperation::GRAYSCALE:
        case FilterOperation::SEPIA:
        case FilterOperation::SATURATE:
        case FilterOperation::HUE_ROTATE: {
            float amount = toBasicColorMatrixFilterOperation(op).amount();
            switch (op.type()) {
            case FilterOperation::GRAYSCALE:
                filters->appendGrayscaleFilter(amount);
                break;
            case FilterOperation::SEPIA:
                filters->appendSepiaFilter(amount);
                break;
            case FilterOperation::SATURATE:
                filters->appendSaturateFilter(amount);
                break;
            case FilterOperation::HUE_ROTATE:
                filters->appendHueRotateFilter(amount);
                break;
            default:
                ASSERT_NOT_REACHED();
            }
            break;
        }
        case FilterOperation::INVERT:
        case FilterOperation::OPACITY:
        case FilterOperation::BRIGHTNESS:
        case FilterOperation::CONTRAST: {
            float amount = toBasicComponentTransferFilterOperation(op).amount();
            switch (op.type()) {
            case FilterOperation::INVERT:
                filters->appendInvertFilter(amount);
                break;
            case FilterOperation::OPACITY:
                filters->appendOpacityFilter(amount);
                break;
            case FilterOperation::BRIGHTNESS:
                filters->appendBrightnessFilter(amount);
                break;
            case FilterOperation::CONTRAST:
                filters->appendContrastFilter(amount);
                break;
            default:
                ASSERT_NOT_REACHED();
            }
            break;
        }
        case FilterOperation::BLUR: {
            float pixelRadius = toBlurFilterOperation(op).stdDeviation().getFloatValue();
            filters->appendBlurFilter(pixelRadius);
            break;
        }
        case FilterOperation::DROP_SHADOW: {
            const DropShadowFilterOperation& drop = toDropShadowFilterOperation(op);
            filters->appendDropShadowFilter(WebPoint(drop.x(), drop.y()), drop.stdDeviation(), drop.color().rgb());
            break;
        }
        case FilterOperation::NONE:
            break;
        }
    }
    if (currentColorSpace != ColorSpaceDeviceRGB) {
        // Transform to device color space at the end of processing, if required
        RefPtr<SkImageFilter> filter = transformColorSpace(nullFilter, currentColorSpace, ColorSpaceDeviceRGB);
        filters->appendReferenceFilter(filter.get());
    }
}

PassRefPtr<SkImageFilter> SkiaImageFilterBuilder::buildTransform(const AffineTransform& transform, SkImageFilter* input)
{
    return adoptRef(SkMatrixImageFilter::Create(affineTransformToSkMatrix(transform), SkPaint::kHigh_FilterLevel, input));
}

} // namespace blink
