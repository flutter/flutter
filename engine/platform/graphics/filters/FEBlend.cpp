/*
 * Copyright (C) 2004, 2005, 2006, 2007 Nikolas Zimmermann <zimmermann@kde.org>
 * Copyright (C) 2004, 2005 Rob Buis <buis@kde.org>
 * Copyright (C) 2005 Eric Seidel <eric@webkit.org>
 * Copyright (C) 2009 Dirk Schulze <krit@webkit.org>
 * Copyright (C) 2012 Nokia Corporation and/or its subsidiary(-ies)
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
#include "platform/graphics/filters/FEBlend.h"

#include "SkBitmapSource.h"
#include "SkXfermodeImageFilter.h"
#include "platform/graphics/GraphicsContext.h"
#include "platform/graphics/cpu/arm/filters/FEBlendNEON.h"
#include "platform/graphics/filters/SkiaImageFilterBuilder.h"
#include "platform/graphics/skia/NativeImageSkia.h"
#include "platform/graphics/skia/SkiaUtils.h"
#include "platform/text/TextStream.h"
#include "wtf/Uint8ClampedArray.h"

typedef unsigned char (*BlendType)(unsigned char colorA, unsigned char colorB, unsigned char alphaA, unsigned char alphaB);

namespace blink {

FEBlend::FEBlend(Filter* filter, WebBlendMode mode)
    : FilterEffect(filter)
    , m_mode(mode)
{
}

PassRefPtr<FEBlend> FEBlend::create(Filter* filter, WebBlendMode mode)
{
    return adoptRef(new FEBlend(filter, mode));
}

WebBlendMode FEBlend::blendMode() const
{
    return m_mode;
}

bool FEBlend::setBlendMode(WebBlendMode mode)
{
    if (m_mode == mode)
        return false;
    m_mode = mode;
    return true;
}

#if HAVE(ARM_NEON_INTRINSICS)
bool FEBlend::applySoftwareNEON()
{
    if (m_mode != WebBlendModeNormal
        && m_mode != WebBlendModeMultiply
        && m_mode != WebBlendModeScreen
        && m_mode != WebBlendModeDarken
        && m_mode != WebBlendModeLighten)
        return false;

    Uint8ClampedArray* dstPixelArray = createPremultipliedImageResult();
    if (!dstPixelArray)
        return true;

    FilterEffect* in = inputEffect(0);
    FilterEffect* in2 = inputEffect(1);

    IntRect effectADrawingRect = requestedRegionOfInputImageData(in->absolutePaintRect());
    RefPtr<Uint8ClampedArray> srcPixelArrayA = in->asPremultipliedImage(effectADrawingRect);

    IntRect effectBDrawingRect = requestedRegionOfInputImageData(in2->absolutePaintRect());
    RefPtr<Uint8ClampedArray> srcPixelArrayB = in2->asPremultipliedImage(effectBDrawingRect);

    unsigned pixelArrayLength = srcPixelArrayA->length();
    ASSERT(pixelArrayLength == srcPixelArrayB->length());

    if (pixelArrayLength >= 8) {
        platformApplyNEON(srcPixelArrayA->data(), srcPixelArrayB->data(), dstPixelArray->data(), pixelArrayLength);
    } else {
        // If there is just one pixel we expand it to two.
        ASSERT(pixelArrayLength > 0);
        uint32_t sourceA[2] = {0, 0};
        uint32_t sourceBAndDest[2] = {0, 0};

        sourceA[0] = reinterpret_cast<uint32_t*>(srcPixelArrayA->data())[0];
        sourceBAndDest[0] = reinterpret_cast<uint32_t*>(srcPixelArrayB->data())[0];
        platformApplyNEON(reinterpret_cast<uint8_t*>(sourceA), reinterpret_cast<uint8_t*>(sourceBAndDest), reinterpret_cast<uint8_t*>(sourceBAndDest), 8);
        reinterpret_cast<uint32_t*>(dstPixelArray->data())[0] = sourceBAndDest[0];
    }
    return true;
}
#endif

void FEBlend::applySoftware()
{
#if HAVE(ARM_NEON_INTRINSICS)
    if (applySoftwareNEON())
        return;
#endif

    FilterEffect* in = inputEffect(0);
    FilterEffect* in2 = inputEffect(1);

    ImageBuffer* resultImage = createImageBufferResult();
    if (!resultImage)
        return;
    GraphicsContext* filterContext = resultImage->context();

    ImageBuffer* imageBuffer = in->asImageBuffer();
    ImageBuffer* imageBuffer2 = in2->asImageBuffer();
    ASSERT(imageBuffer);
    ASSERT(imageBuffer2);

    filterContext->drawImageBuffer(imageBuffer2, drawingRegionOfInputImage(in2->absolutePaintRect()));
    filterContext->drawImageBuffer(imageBuffer, drawingRegionOfInputImage(in->absolutePaintRect()), 0, CompositeSourceOver, m_mode);
}

PassRefPtr<SkImageFilter> FEBlend::createImageFilter(SkiaImageFilterBuilder* builder)
{
    RefPtr<SkImageFilter> foreground(builder->build(inputEffect(0), operatingColorSpace()));
    RefPtr<SkImageFilter> background(builder->build(inputEffect(1), operatingColorSpace()));
    RefPtr<SkXfermode> mode(adoptRef(SkXfermode::Create(WebCoreCompositeToSkiaComposite(CompositeSourceOver, m_mode))));
    SkImageFilter::CropRect cropRect = getCropRect(builder->cropOffset());
    return adoptRef(SkXfermodeImageFilter::Create(mode.get(), background.get(), foreground.get(), &cropRect));
}

TextStream& FEBlend::externalRepresentation(TextStream& ts, int indent) const
{
    writeIndent(ts, indent);
    ts << "[feBlend";
    FilterEffect::externalRepresentation(ts);
    ts << " mode=\"" << (m_mode == WebBlendModeNormal ? "normal" : compositeOperatorName(CompositeSourceOver, m_mode)) << "\"]\n";
    inputEffect(0)->externalRepresentation(ts, indent + 1);
    inputEffect(1)->externalRepresentation(ts, indent + 1);
    return ts;
}

} // namespace blink
