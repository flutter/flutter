/*
 * Copyright (C) Research In Motion Limited 2011. All rights reserved.
 * Copyright (C) 2013 Google Inc. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */

#include "config.h"
#include "platform/graphics/filters/FEDropShadow.h"

#include "platform/graphics/GraphicsContext.h"
#include "platform/graphics/filters/FEGaussianBlur.h"
#include "platform/graphics/filters/SkiaImageFilterBuilder.h"
#include "platform/text/TextStream.h"
#include "third_party/skia/include/core/SkColorFilter.h"
#include "third_party/skia/include/effects/SkBlurImageFilter.h"
#include "third_party/skia/include/effects/SkDropShadowImageFilter.h"

namespace blink {

FEDropShadow::FEDropShadow(Filter* filter, float stdX, float stdY, float dx, float dy, const Color& shadowColor, float shadowOpacity)
    : FilterEffect(filter)
    , m_stdX(stdX)
    , m_stdY(stdY)
    , m_dx(dx)
    , m_dy(dy)
    , m_shadowColor(shadowColor)
    , m_shadowOpacity(shadowOpacity)
{
}

PassRefPtr<FEDropShadow> FEDropShadow::create(Filter* filter, float stdX, float stdY, float dx, float dy, const Color& shadowColor, float shadowOpacity)
{
    return adoptRef(new FEDropShadow(filter, stdX, stdY, dx, dy, shadowColor, shadowOpacity));
}

FloatRect FEDropShadow::mapRect(const FloatRect& rect, bool forward)
{
    FloatRect result = rect;
    Filter* filter = this->filter();
    ASSERT(filter);

    FloatRect offsetRect = rect;
    if (forward)
        offsetRect.move(filter->applyHorizontalScale(m_dx), filter->applyVerticalScale(m_dy));
    else
        offsetRect.move(-filter->applyHorizontalScale(m_dx), -filter->applyVerticalScale(m_dy));
    result.unite(offsetRect);

    IntSize kernelSize = FEGaussianBlur::calculateKernelSize(filter, FloatPoint(m_stdX, m_stdY));

    // We take the half kernel size and multiply it with three, because we run box blur three times.
    result.inflateX(3 * kernelSize.width() * 0.5f);
    result.inflateY(3 * kernelSize.height() * 0.5f);
    return result;
}

void FEDropShadow::applySoftware()
{
    FilterEffect* in = inputEffect(0);

    ImageBuffer* resultImage = createImageBufferResult();
    if (!resultImage)
        return;

    Filter* filter = this->filter();
    FloatSize blurRadius(filter->applyHorizontalScale(m_stdX), filter->applyVerticalScale(m_stdY));
    FloatSize offset(filter->applyHorizontalScale(m_dx), filter->applyVerticalScale(m_dy));

    FloatRect drawingRegion = drawingRegionOfInputImage(in->absolutePaintRect());
    GraphicsContext* resultContext = resultImage->context();
    ASSERT(resultContext);

    Color color = adaptColorToOperatingColorSpace(m_shadowColor.combineWithAlpha(m_shadowOpacity));
    SkAutoTUnref<SkImageFilter> blurFilter(SkBlurImageFilter::Create(blurRadius.width(), blurRadius.height()));
    SkAutoTUnref<SkColorFilter> colorFilter(SkColorFilter::CreateModeFilter(color.rgb(), SkXfermode::kSrcIn_Mode));
    SkPaint paint;
    paint.setImageFilter(blurFilter.get());
    paint.setColorFilter(colorFilter.get());
    paint.setXfermodeMode(SkXfermode::kSrcOver_Mode);
    RefPtr<Image> image = in->asImageBuffer()->copyImage(DontCopyBackingStore);

    RefPtr<NativeImageSkia> nativeImage = image->nativeImageForCurrentFrame();

    if (!nativeImage)
        return;

    resultContext->drawBitmap(nativeImage->bitmap(), drawingRegion.x() + offset.width(), drawingRegion.y() + offset.height(), &paint);
    resultContext->drawBitmap(nativeImage->bitmap(), drawingRegion.x(), drawingRegion.y());
}

PassRefPtr<SkImageFilter> FEDropShadow::createImageFilter(SkiaImageFilterBuilder* builder)
{
    RefPtr<SkImageFilter> input(builder->build(inputEffect(0), operatingColorSpace()));
    float dx = filter()->applyHorizontalScale(m_dx);
    float dy = filter()->applyVerticalScale(m_dy);
    float stdX = filter()->applyHorizontalScale(m_stdX);
    float stdY = filter()->applyVerticalScale(m_stdY);
    Color color = adaptColorToOperatingColorSpace(m_shadowColor.combineWithAlpha(m_shadowOpacity));
    SkImageFilter::CropRect cropRect = getCropRect(builder->cropOffset());
    return adoptRef(SkDropShadowImageFilter::Create(SkFloatToScalar(dx), SkFloatToScalar(dy), SkFloatToScalar(stdX), SkFloatToScalar(stdY), color.rgb(), input.get(), &cropRect));
}


TextStream& FEDropShadow::externalRepresentation(TextStream& ts, int indent) const
{
    writeIndent(ts, indent);
    ts << "[feDropShadow";
    FilterEffect::externalRepresentation(ts);
    ts << " stdDeviation=\"" << m_stdX << ", " << m_stdY << "\" dx=\"" << m_dx << "\" dy=\"" << m_dy << "\" flood-color=\"" << m_shadowColor.nameForRenderTreeAsText() <<"\" flood-opacity=\"" << m_shadowOpacity << "]\n";
    inputEffect(0)->externalRepresentation(ts, indent + 1);
    return ts;
}

} // namespace blink
