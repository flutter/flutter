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
#include "platform/graphics/filters/FEOffset.h"

#include "SkOffsetImageFilter.h"
#include "platform/graphics/GraphicsContext.h"
#include "platform/graphics/filters/SkiaImageFilterBuilder.h"
#include "platform/text/TextStream.h"
#include "third_party/skia/include/core/SkDevice.h"

namespace blink {

FEOffset::FEOffset(Filter* filter, float dx, float dy)
    : FilterEffect(filter)
    , m_dx(dx)
    , m_dy(dy)
{
}

PassRefPtr<FEOffset> FEOffset::create(Filter* filter, float dx, float dy)
{
    return adoptRef(new FEOffset(filter, dx, dy));
}

float FEOffset::dx() const
{
    return m_dx;
}

void FEOffset::setDx(float dx)
{
    m_dx = dx;
}

float FEOffset::dy() const
{
    return m_dy;
}

void FEOffset::setDy(float dy)
{
    m_dy = dy;
}

FloatRect FEOffset::mapRect(const FloatRect& rect, bool forward)
{
    FloatRect result = rect;
    if (forward)
        result.move(filter()->applyHorizontalScale(m_dx), filter()->applyVerticalScale(m_dy));
    else
        result.move(-filter()->applyHorizontalScale(m_dx), -filter()->applyVerticalScale(m_dy));
    return result;
}

void FEOffset::applySoftware()
{
    FilterEffect* in = inputEffect(0);

    ImageBuffer* resultImage = createImageBufferResult();
    if (!resultImage)
        return;

    setIsAlphaImage(in->isAlphaImage());

    FloatRect drawingRegion = drawingRegionOfInputImage(in->absolutePaintRect());
    Filter* filter = this->filter();
    drawingRegion.move(filter->applyHorizontalScale(m_dx), filter->applyVerticalScale(m_dy));
    resultImage->context()->drawImageBuffer(in->asImageBuffer(), drawingRegion);
}

PassRefPtr<SkImageFilter> FEOffset::createImageFilter(SkiaImageFilterBuilder* builder)
{
    RefPtr<SkImageFilter> input(builder->build(inputEffect(0), operatingColorSpace()));
    Filter* filter = this->filter();
    SkImageFilter::CropRect cropRect = getCropRect(builder->cropOffset());
    return adoptRef(SkOffsetImageFilter::Create(SkFloatToScalar(filter->applyHorizontalScale(m_dx)), SkFloatToScalar(filter->applyVerticalScale(m_dy)), input.get(), &cropRect));
}

TextStream& FEOffset::externalRepresentation(TextStream& ts, int indent) const
{
    writeIndent(ts, indent);
    ts << "[feOffset";
    FilterEffect::externalRepresentation(ts);
    ts << " dx=\"" << dx() << "\" dy=\"" << dy() << "\"]\n";
    inputEffect(0)->externalRepresentation(ts, indent + 1);
    return ts;
}

} // namespace blink
