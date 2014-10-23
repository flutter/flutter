/*
 * Copyright (C) 2008 Alex Mathews <possessedpenguinbob@gmail.com>
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
#include "platform/graphics/filters/FETile.h"

#include "SkTileImageFilter.h"

#include "platform/graphics/GraphicsContext.h"
#include "platform/graphics/Pattern.h"
#include "platform/graphics/UnacceleratedImageBufferSurface.h"
#include "platform/graphics/filters/SkiaImageFilterBuilder.h"
#include "platform/text/TextStream.h"
#include "platform/transforms/AffineTransform.h"
#include "third_party/skia/include/core/SkDevice.h"

namespace blink {

FETile::FETile(Filter* filter)
    : FilterEffect(filter)
{
}

PassRefPtr<FETile> FETile::create(Filter* filter)
{
    return adoptRef(new FETile(filter));
}

FloatRect FETile::mapPaintRect(const FloatRect& rect, bool forward)
{
    return forward ? maxEffectRect() : inputEffect(0)->maxEffectRect();
}

void FETile::applySoftware()
{
    FilterEffect* in = inputEffect(0);

    ImageBuffer* resultImage = createImageBufferResult();
    if (!resultImage)
        return;

    setIsAlphaImage(in->isAlphaImage());

    // Source input needs more attention. It has the size of the filterRegion but gives the
    // size of the cutted sourceImage back. This is part of the specification and optimization.
    FloatRect tileRect = in->maxEffectRect();
    FloatPoint inMaxEffectLocation = tileRect.location();
    FloatPoint maxEffectLocation = maxEffectRect().location();
    if (in->filterEffectType() == FilterEffectTypeSourceInput) {
        Filter* filter = this->filter();
        tileRect = filter->absoluteFilterRegion();
    }

    OwnPtr<ImageBufferSurface> surface;
    IntSize intTileSize = roundedIntSize(tileRect.size());
    surface = adoptPtr(new UnacceleratedImageBufferSurface(intTileSize));
    OwnPtr<ImageBuffer> tileImage = ImageBuffer::create(surface.release());
    if (!tileImage)
        return;

    GraphicsContext* tileImageContext = tileImage->context();
    tileImageContext->scale(intTileSize.width() / tileRect.width(), intTileSize.height() / tileRect.height());
    tileImageContext->translate(-inMaxEffectLocation.x(), -inMaxEffectLocation.y());

    if (ImageBuffer* tileImageBuffer = in->asImageBuffer())
        tileImageContext->drawImageBuffer(tileImageBuffer, IntRect(in->absolutePaintRect().location(), tileImageBuffer->size()));

    RefPtr<Pattern> pattern = Pattern::createBitmapPattern(tileImage->copyImage(CopyBackingStore));

    AffineTransform patternTransform;
    patternTransform.translate(inMaxEffectLocation.x() - maxEffectLocation.x(), inMaxEffectLocation.y() - maxEffectLocation.y());
    pattern->setPatternSpaceTransform(patternTransform);
    GraphicsContext* filterContext = resultImage->context();
    filterContext->setFillPattern(pattern);
    filterContext->fillRect(FloatRect(FloatPoint(), absolutePaintRect().size()));
}

static FloatRect getRect(FilterEffect* effect)
{
    FloatRect result = effect->filter()->filterRegion();
    FloatRect boundaries = effect->effectBoundaries();
    if (effect->hasX())
        result.setX(boundaries.x());
    if (effect->hasY())
        result.setY(boundaries.y());
    if (effect->hasWidth())
        result.setWidth(boundaries.width());
    if (effect->hasHeight())
        result.setHeight(boundaries.height());
    return result;
}

PassRefPtr<SkImageFilter> FETile::createImageFilter(SkiaImageFilterBuilder* builder)
{
    RefPtr<SkImageFilter> input(builder->build(inputEffect(0), operatingColorSpace()));
    FloatRect srcRect = inputEffect(0) ? getRect(inputEffect(0)) : filter()->filterRegion();
    FloatRect dstRect = getRect(this);
    return adoptRef(SkTileImageFilter::Create(srcRect, dstRect, input.get()));
}

TextStream& FETile::externalRepresentation(TextStream& ts, int indent) const
{
    writeIndent(ts, indent);
    ts << "[feTile";
    FilterEffect::externalRepresentation(ts);
    ts << "]\n";
    inputEffect(0)->externalRepresentation(ts, indent + 1);

    return ts;
}

} // namespace blink
