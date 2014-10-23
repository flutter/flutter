/*
 * Copyright (C) 2004, 2005, 2006, 2007 Nikolas Zimmermann <zimmermann@kde.org>
 * Copyright (C) 2004, 2005 Rob Buis <buis@kde.org>
 * Copyright (C) 2005 Eric Seidel <eric@webkit.org>
 * Copyright (C) 2009 Dirk Schulze <krit@webkit.org>
 * Copyright (C) Research In Motion Limited 2010. All rights reserved.
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
#include "platform/graphics/filters/FEDisplacementMap.h"

#include "SkBitmapSource.h"
#include "SkDisplacementMapEffect.h"
#include "platform/graphics/GraphicsContext.h"
#include "platform/graphics/filters/SkiaImageFilterBuilder.h"
#include "platform/graphics/skia/NativeImageSkia.h"
#include "platform/text/TextStream.h"
#include "wtf/Uint8ClampedArray.h"

namespace blink {

FEDisplacementMap::FEDisplacementMap(Filter* filter, ChannelSelectorType xChannelSelector, ChannelSelectorType yChannelSelector, float scale)
    : FilterEffect(filter)
    , m_xChannelSelector(xChannelSelector)
    , m_yChannelSelector(yChannelSelector)
    , m_scale(scale)
{
}

PassRefPtr<FEDisplacementMap> FEDisplacementMap::create(Filter* filter, ChannelSelectorType xChannelSelector,
    ChannelSelectorType yChannelSelector, float scale)
{
    return adoptRef(new FEDisplacementMap(filter, xChannelSelector, yChannelSelector, scale));
}

FloatRect FEDisplacementMap::mapPaintRect(const FloatRect& rect, bool)
{
    FloatRect result = rect;
    result.inflateX(filter()->applyHorizontalScale(m_scale / 2));
    result.inflateY(filter()->applyVerticalScale(m_scale / 2));
    return result;
}

ChannelSelectorType FEDisplacementMap::xChannelSelector() const
{
    return m_xChannelSelector;
}

bool FEDisplacementMap::setXChannelSelector(const ChannelSelectorType xChannelSelector)
{
    if (m_xChannelSelector == xChannelSelector)
        return false;
    m_xChannelSelector = xChannelSelector;
    return true;
}

ChannelSelectorType FEDisplacementMap::yChannelSelector() const
{
    return m_yChannelSelector;
}

bool FEDisplacementMap::setYChannelSelector(const ChannelSelectorType yChannelSelector)
{
    if (m_yChannelSelector == yChannelSelector)
        return false;
    m_yChannelSelector = yChannelSelector;
    return true;
}

float FEDisplacementMap::scale() const
{
    return m_scale;
}

bool FEDisplacementMap::setScale(float scale)
{
    if (m_scale == scale)
        return false;
    m_scale = scale;
    return true;
}

void FEDisplacementMap::setResultColorSpace(ColorSpace)
{
    // Spec: The 'color-interpolation-filters' property only applies to the 'in2' source image
    // and does not apply to the 'in' source image. The 'in' source image must remain in its
    // current color space.
    // The result is in that smae color space because it is a displacement of the 'in' image.
    FilterEffect::setResultColorSpace(inputEffect(0)->resultColorSpace());
}

void FEDisplacementMap::transformResultColorSpace(FilterEffect* in, const int index)
{
    // Do not transform the first primitive input, as per the spec.
    if (index)
        in->transformResultColorSpace(operatingColorSpace());
}

void FEDisplacementMap::applySoftware()
{
    FilterEffect* in = inputEffect(0);
    FilterEffect* in2 = inputEffect(1);

    ASSERT(m_xChannelSelector != CHANNEL_UNKNOWN);
    ASSERT(m_yChannelSelector != CHANNEL_UNKNOWN);

    Uint8ClampedArray* dstPixelArray = createPremultipliedImageResult();
    if (!dstPixelArray)
        return;

    IntRect effectADrawingRect = requestedRegionOfInputImageData(in->absolutePaintRect());
    RefPtr<Uint8ClampedArray> srcPixelArrayA = in->asPremultipliedImage(effectADrawingRect);

    IntRect effectBDrawingRect = requestedRegionOfInputImageData(in2->absolutePaintRect());
    RefPtr<Uint8ClampedArray> srcPixelArrayB = in2->asUnmultipliedImage(effectBDrawingRect);

    ASSERT(srcPixelArrayA->length() == srcPixelArrayB->length());

    Filter* filter = this->filter();
    IntSize paintSize = absolutePaintRect().size();
    float scaleX = filter->applyHorizontalScale(m_scale);
    float scaleY = filter->applyVerticalScale(m_scale);
    float scaleForColorX = scaleX / 255.0;
    float scaleForColorY = scaleY / 255.0;
    float scaledOffsetX = 0.5 - scaleX * 0.5;
    float scaledOffsetY = 0.5 - scaleY * 0.5;
    int stride = paintSize.width() * 4;
    for (int y = 0; y < paintSize.height(); ++y) {
        int line = y * stride;
        for (int x = 0; x < paintSize.width(); ++x) {
            int dstIndex = line + x * 4;
            int srcX = x + static_cast<int>(scaleForColorX * srcPixelArrayB->item(dstIndex + m_xChannelSelector - 1) + scaledOffsetX);
            int srcY = y + static_cast<int>(scaleForColorY * srcPixelArrayB->item(dstIndex + m_yChannelSelector - 1) + scaledOffsetY);
            for (unsigned channel = 0; channel < 4; ++channel) {
                if (srcX < 0 || srcX >= paintSize.width() || srcY < 0 || srcY >= paintSize.height()) {
                    dstPixelArray->set(dstIndex + channel, static_cast<unsigned char>(0));
                } else {
                    unsigned char pixelValue = srcPixelArrayA->item(srcY * stride + srcX * 4 + channel);
                    dstPixelArray->set(dstIndex + channel, pixelValue);
                }
            }
        }
    }
}

static SkDisplacementMapEffect::ChannelSelectorType toSkiaMode(ChannelSelectorType type)
{
    switch (type) {
    case CHANNEL_R:
        return SkDisplacementMapEffect::kR_ChannelSelectorType;
    case CHANNEL_G:
        return SkDisplacementMapEffect::kG_ChannelSelectorType;
    case CHANNEL_B:
        return SkDisplacementMapEffect::kB_ChannelSelectorType;
    case CHANNEL_A:
        return SkDisplacementMapEffect::kA_ChannelSelectorType;
    case CHANNEL_UNKNOWN:
    default:
        return SkDisplacementMapEffect::kUnknown_ChannelSelectorType;
    }
}

PassRefPtr<SkImageFilter> FEDisplacementMap::createImageFilter(SkiaImageFilterBuilder* builder)
{
    RefPtr<SkImageFilter> color = builder->build(inputEffect(0), operatingColorSpace());
    RefPtr<SkImageFilter> displ = builder->build(inputEffect(1), operatingColorSpace());
    SkDisplacementMapEffect::ChannelSelectorType typeX = toSkiaMode(m_xChannelSelector);
    SkDisplacementMapEffect::ChannelSelectorType typeY = toSkiaMode(m_yChannelSelector);
    SkImageFilter::CropRect cropRect = getCropRect(builder->cropOffset());
    // FIXME : Only applyHorizontalScale is used and applyVerticalScale is ignored
    // This can be fixed by adding a 2nd scale parameter to SkDisplacementMapEffect
    return adoptRef(SkDisplacementMapEffect::Create(typeX, typeY, SkFloatToScalar(filter()->applyHorizontalScale(m_scale)), displ.get(), color.get(), &cropRect));
}

static TextStream& operator<<(TextStream& ts, const ChannelSelectorType& type)
{
    switch (type) {
    case CHANNEL_UNKNOWN:
        ts << "UNKNOWN";
        break;
    case CHANNEL_R:
        ts << "RED";
        break;
    case CHANNEL_G:
        ts << "GREEN";
        break;
    case CHANNEL_B:
        ts << "BLUE";
        break;
    case CHANNEL_A:
        ts << "ALPHA";
        break;
    }
    return ts;
}

TextStream& FEDisplacementMap::externalRepresentation(TextStream& ts, int indent) const
{
    writeIndent(ts, indent);
    ts << "[feDisplacementMap";
    FilterEffect::externalRepresentation(ts);
    ts << " scale=\"" << m_scale << "\" "
       << "xChannelSelector=\"" << m_xChannelSelector << "\" "
       << "yChannelSelector=\"" << m_yChannelSelector << "\"]\n";
    inputEffect(0)->externalRepresentation(ts, indent + 1);
    inputEffect(1)->externalRepresentation(ts, indent + 1);
    return ts;
}

FloatRect FEDisplacementMap::determineAbsolutePaintRect(const FloatRect& requestedRect)
{
    FloatRect rect = requestedRect;
    if (clipsToBounds())
        rect.intersect(maxEffectRect());

    if (absolutePaintRect().contains(enclosingIntRect(rect)))
        return rect;

    rect = mapPaintRect(rect, false);
    rect = inputEffect(0)->determineAbsolutePaintRect(rect);
    rect = mapPaintRect(rect, true);
    rect.intersect(requestedRect);

    addAbsolutePaintRect(rect);
    return rect;
}

} // namespace blink
