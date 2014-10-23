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
#include "platform/graphics/filters/FEMorphology.h"

#include "SkMorphologyImageFilter.h"
#include "platform/graphics/GraphicsContext.h"
#include "platform/graphics/Image.h"
#include "platform/graphics/filters/ParallelJobs.h"
#include "platform/graphics/filters/SkiaImageFilterBuilder.h"
#include "platform/text/TextStream.h"
#include "wtf/Uint8ClampedArray.h"

namespace blink {

FEMorphology::FEMorphology(Filter* filter, MorphologyOperatorType type, float radiusX, float radiusY)
    : FilterEffect(filter)
    , m_type(type)
    , m_radiusX(radiusX)
    , m_radiusY(radiusY)
{
}

PassRefPtr<FEMorphology> FEMorphology::create(Filter* filter, MorphologyOperatorType type, float radiusX, float radiusY)
{
    return adoptRef(new FEMorphology(filter, type, radiusX, radiusY));
}

MorphologyOperatorType FEMorphology::morphologyOperator() const
{
    return m_type;
}

bool FEMorphology::setMorphologyOperator(MorphologyOperatorType type)
{
    if (m_type == type)
        return false;
    m_type = type;
    return true;
}

float FEMorphology::radiusX() const
{
    return m_radiusX;
}

bool FEMorphology::setRadiusX(float radiusX)
{
    if (m_radiusX == radiusX)
        return false;
    m_radiusX = radiusX;
    return true;
}

float FEMorphology::radiusY() const
{
    return m_radiusY;
}

FloatRect FEMorphology::mapRect(const FloatRect& rect, bool)
{
    FloatRect result = rect;
    result.inflateX(filter()->applyHorizontalScale(m_radiusX));
    result.inflateY(filter()->applyVerticalScale(m_radiusY));
    return result;
}

bool FEMorphology::setRadiusY(float radiusY)
{
    if (m_radiusY == radiusY)
        return false;
    m_radiusY = radiusY;
    return true;
}

void FEMorphology::applySoftware()
{
    ImageBuffer* resultImage = createImageBufferResult();
    if (!resultImage)
        return;

    FilterEffect* in = inputEffect(0);

    IntRect drawingRegion = drawingRegionOfInputImage(in->absolutePaintRect());

    setIsAlphaImage(in->isAlphaImage());

    float radiusX = filter()->applyHorizontalScale(m_radiusX);
    float radiusY = filter()->applyVerticalScale(m_radiusY);

    RefPtr<Image> image = in->asImageBuffer()->copyImage(DontCopyBackingStore);

    SkPaint paint;
    GraphicsContext* dstContext = resultImage->context();
    if (m_type == FEMORPHOLOGY_OPERATOR_DILATE)
        paint.setImageFilter(SkDilateImageFilter::Create(radiusX, radiusY))->unref();
    else if (m_type == FEMORPHOLOGY_OPERATOR_ERODE)
        paint.setImageFilter(SkErodeImageFilter::Create(radiusX, radiusY))->unref();

    SkRect bounds = SkRect::MakeWH(absolutePaintRect().width(), absolutePaintRect().height());
    dstContext->saveLayer(&bounds, &paint);
    dstContext->drawImage(image.get(), drawingRegion.location(), CompositeCopy);
    dstContext->restoreLayer();
}

PassRefPtr<SkImageFilter> FEMorphology::createImageFilter(SkiaImageFilterBuilder* builder)
{
    RefPtr<SkImageFilter> input(builder->build(inputEffect(0), operatingColorSpace()));
    SkScalar radiusX = SkFloatToScalar(filter()->applyHorizontalScale(m_radiusX));
    SkScalar radiusY = SkFloatToScalar(filter()->applyVerticalScale(m_radiusY));
    SkImageFilter::CropRect rect = getCropRect(builder->cropOffset());
    if (m_type == FEMORPHOLOGY_OPERATOR_DILATE)
        return adoptRef(SkDilateImageFilter::Create(radiusX, radiusY, input.get(), &rect));
    return adoptRef(SkErodeImageFilter::Create(radiusX, radiusY, input.get(), &rect));
}

static TextStream& operator<<(TextStream& ts, const MorphologyOperatorType& type)
{
    switch (type) {
    case FEMORPHOLOGY_OPERATOR_UNKNOWN:
        ts << "UNKNOWN";
        break;
    case FEMORPHOLOGY_OPERATOR_ERODE:
        ts << "ERODE";
        break;
    case FEMORPHOLOGY_OPERATOR_DILATE:
        ts << "DILATE";
        break;
    }
    return ts;
}

TextStream& FEMorphology::externalRepresentation(TextStream& ts, int indent) const
{
    writeIndent(ts, indent);
    ts << "[feMorphology";
    FilterEffect::externalRepresentation(ts);
    ts << " operator=\"" << morphologyOperator() << "\" "
        << "radius=\"" << radiusX() << ", " << radiusY() << "\"]\n";
    inputEffect(0)->externalRepresentation(ts, indent + 1);
    return ts;
}

} // namespace blink
