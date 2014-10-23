/*
 * Copyright (C) 2004, 2005, 2006, 2007 Nikolas Zimmermann <zimmermann@kde.org>
 * Copyright (C) 2004, 2005 Rob Buis <buis@kde.org>
 * Copyright (C) 2005 Eric Seidel <eric@webkit.org>
 * Copyright (C) 2009 Dirk Schulze <krit@webkit.org>
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
#include "platform/graphics/filters/FEFlood.h"

#include "SkColorFilter.h"
#include "SkColorFilterImageFilter.h"
#include "platform/graphics/GraphicsContext.h"
#include "platform/graphics/filters/SkiaImageFilterBuilder.h"
#include "platform/text/TextStream.h"
#include "third_party/skia/include/core/SkDevice.h"

namespace blink {

FEFlood::FEFlood(Filter* filter, const Color& floodColor, float floodOpacity)
    : FilterEffect(filter)
    , m_floodColor(floodColor)
    , m_floodOpacity(floodOpacity)
{
    FilterEffect::setOperatingColorSpace(ColorSpaceDeviceRGB);
}

PassRefPtr<FEFlood> FEFlood::create(Filter* filter, const Color& floodColor, float floodOpacity)
{
    return adoptRef(new FEFlood(filter, floodColor, floodOpacity));
}

Color FEFlood::floodColor() const
{
    return m_floodColor;
}

bool FEFlood::setFloodColor(const Color& color)
{
    if (m_floodColor == color)
        return false;
    m_floodColor = color;
    return true;
}

float FEFlood::floodOpacity() const
{
    return m_floodOpacity;
}

bool FEFlood::setFloodOpacity(float floodOpacity)
{
    if (m_floodOpacity == floodOpacity)
        return false;
    m_floodOpacity = floodOpacity;
    return true;
}

void FEFlood::applySoftware()
{
    ImageBuffer* resultImage = createImageBufferResult();
    if (!resultImage)
        return;

    Color color = floodColor().combineWithAlpha(floodOpacity());
    resultImage->context()->fillRect(FloatRect(FloatPoint(), absolutePaintRect().size()), color);
    FilterEffect::setResultColorSpace(ColorSpaceDeviceRGB);
}

PassRefPtr<SkImageFilter> FEFlood::createImageFilter(SkiaImageFilterBuilder* builder)
{
    Color color = floodColor().combineWithAlpha(floodOpacity());

    SkImageFilter::CropRect rect = getCropRect(builder->cropOffset());
    SkAutoTUnref<SkColorFilter> cf(SkColorFilter::CreateModeFilter(color.rgb(), SkXfermode::kSrc_Mode));
    return adoptRef(SkColorFilterImageFilter::Create(cf, 0, &rect));
}

TextStream& FEFlood::externalRepresentation(TextStream& ts, int indent) const
{
    writeIndent(ts, indent);
    ts << "[feFlood";
    FilterEffect::externalRepresentation(ts);
    ts << " flood-color=\"" << floodColor().nameForRenderTreeAsText() << "\" "
       << "flood-opacity=\"" << floodOpacity() << "\"]\n";
    return ts;
}

} // namespace blink
