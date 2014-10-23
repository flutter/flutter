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
#include "platform/graphics/filters/FEColorMatrix.h"

#include "SkColorFilterImageFilter.h"
#include "SkColorMatrixFilter.h"
#include "platform/graphics/GraphicsContext.h"
#include "platform/graphics/filters/SkiaImageFilterBuilder.h"
#include "platform/graphics/skia/NativeImageSkia.h"
#include "platform/text/TextStream.h"
#include "wtf/MathExtras.h"
#include "wtf/Uint8ClampedArray.h"

namespace blink {

FEColorMatrix::FEColorMatrix(Filter* filter, ColorMatrixType type, const Vector<float>& values)
    : FilterEffect(filter)
    , m_type(type)
    , m_values(values)
{
}

PassRefPtr<FEColorMatrix> FEColorMatrix::create(Filter* filter, ColorMatrixType type, const Vector<float>& values)
{
    return adoptRef(new FEColorMatrix(filter, type, values));
}

ColorMatrixType FEColorMatrix::type() const
{
    return m_type;
}

bool FEColorMatrix::setType(ColorMatrixType type)
{
    if (m_type == type)
        return false;
    m_type = type;
    return true;
}

const Vector<float>& FEColorMatrix::values() const
{
    return m_values;
}

bool FEColorMatrix::setValues(const Vector<float> &values)
{
    if (m_values == values)
        return false;
    m_values = values;
    return true;
}

static void saturateMatrix(float s, SkScalar matrix[20])
{
    matrix[0] = 0.213f + 0.787f * s;
    matrix[1] = 0.715f - 0.715f * s;
    matrix[2] = 0.072f - 0.072f * s;
    matrix[3] = matrix[4] = 0;
    matrix[5] = 0.213f - 0.213f * s;
    matrix[6] = 0.715f + 0.285f * s;
    matrix[7] = 0.072f - 0.072f * s;
    matrix[8] = matrix[9] = 0;
    matrix[10] = 0.213f - 0.213f * s;
    matrix[11] = 0.715f - 0.715f * s;
    matrix[12] = 0.072f + 0.928f * s;
    matrix[13] = matrix[14] = 0;
    matrix[15] = matrix[16] = matrix[17] = 0;
    matrix[18] = 1;
    matrix[19] = 0;
}

static void hueRotateMatrix(float hue, SkScalar matrix[20])
{
    float cosHue = cosf(hue * piFloat / 180);
    float sinHue = sinf(hue * piFloat / 180);
    matrix[0] = 0.213f + cosHue * 0.787f - sinHue * 0.213f;
    matrix[1] = 0.715f - cosHue * 0.715f - sinHue * 0.715f;
    matrix[2] = 0.072f - cosHue * 0.072f + sinHue * 0.928f;
    matrix[3] = matrix[4] = 0;
    matrix[5] = 0.213f - cosHue * 0.213f + sinHue * 0.143f;
    matrix[6] = 0.715f + cosHue * 0.285f + sinHue * 0.140f;
    matrix[7] = 0.072f - cosHue * 0.072f - sinHue * 0.283f;
    matrix[8] = matrix[9] = 0;
    matrix[10] = 0.213f - cosHue * 0.213f - sinHue * 0.787f;
    matrix[11] = 0.715f - cosHue * 0.715f + sinHue * 0.715f;
    matrix[12] = 0.072f + cosHue * 0.928f + sinHue * 0.072f;
    matrix[13] = matrix[14] = 0;
    matrix[15] = matrix[16] = matrix[17] = 0;
    matrix[18] = 1;
    matrix[19] = 0;
}

static void luminanceToAlphaMatrix(SkScalar matrix[20])
{
    memset(matrix, 0, 20 * sizeof(SkScalar));
    matrix[15] = 0.2125f;
    matrix[16] = 0.7154f;
    matrix[17] = 0.0721f;
}

static SkColorFilter* createColorFilter(ColorMatrixType type, const float* values)
{
    SkScalar matrix[20];
    switch (type) {
    case FECOLORMATRIX_TYPE_UNKNOWN:
        break;
    case FECOLORMATRIX_TYPE_MATRIX:
        for (int i = 0; i < 20; ++i)
            matrix[i] = values[i];

        matrix[4] *= SkScalar(255);
        matrix[9] *= SkScalar(255);
        matrix[14] *= SkScalar(255);
        matrix[19] *= SkScalar(255);
        break;
    case FECOLORMATRIX_TYPE_SATURATE:
        saturateMatrix(values[0], matrix);
        break;
    case FECOLORMATRIX_TYPE_HUEROTATE:
        hueRotateMatrix(values[0], matrix);
        break;
    case FECOLORMATRIX_TYPE_LUMINANCETOALPHA:
        luminanceToAlphaMatrix(matrix);
        break;
    }
    return SkColorMatrixFilter::Create(matrix);
}

void FEColorMatrix::applySoftware()
{
    ImageBuffer* resultImage = createImageBufferResult();
    if (!resultImage)
        return;

    FilterEffect* in = inputEffect(0);

    IntRect drawingRegion = drawingRegionOfInputImage(in->absolutePaintRect());

    SkAutoTUnref<SkColorFilter> filter(createColorFilter(m_type, m_values.data()));

    RefPtr<Image> image = in->asImageBuffer()->copyImage(DontCopyBackingStore);
    RefPtr<NativeImageSkia> nativeImage = image->nativeImageForCurrentFrame();
    if (!nativeImage)
        return;

    SkPaint paint;
    paint.setColorFilter(filter);
    paint.setXfermodeMode(SkXfermode::kSrc_Mode);
    resultImage->context()->drawBitmap(nativeImage->bitmap(), drawingRegion.x(), drawingRegion.y(), &paint);

    if (affectsTransparentPixels()) {
        IntRect fullRect = IntRect(IntPoint(), absolutePaintRect().size());
        resultImage->context()->clipOut(drawingRegion);
        resultImage->context()->fillRect(fullRect, Color(m_values[4], m_values[9], m_values[14], m_values[19]));
    }
    return;
}

bool FEColorMatrix::affectsTransparentPixels()
{
    // Because the input pixels are premultiplied, the only way clear pixels can be
    // painted is if the additive component for the alpha is not 0.
    return m_type == FECOLORMATRIX_TYPE_MATRIX && m_values[19] > 0;
}

PassRefPtr<SkImageFilter> FEColorMatrix::createImageFilter(SkiaImageFilterBuilder* builder)
{
    RefPtr<SkImageFilter> input(builder->build(inputEffect(0), operatingColorSpace()));
    SkAutoTUnref<SkColorFilter> filter(createColorFilter(m_type, m_values.data()));
    SkImageFilter::CropRect rect = getCropRect(builder->cropOffset());
    return adoptRef(SkColorFilterImageFilter::Create(filter, input.get(), &rect));
}

static TextStream& operator<<(TextStream& ts, const ColorMatrixType& type)
{
    switch (type) {
    case FECOLORMATRIX_TYPE_UNKNOWN:
        ts << "UNKNOWN";
        break;
    case FECOLORMATRIX_TYPE_MATRIX:
        ts << "MATRIX";
        break;
    case FECOLORMATRIX_TYPE_SATURATE:
        ts << "SATURATE";
        break;
    case FECOLORMATRIX_TYPE_HUEROTATE:
        ts << "HUEROTATE";
        break;
    case FECOLORMATRIX_TYPE_LUMINANCETOALPHA:
        ts << "LUMINANCETOALPHA";
        break;
    }
    return ts;
}

TextStream& FEColorMatrix::externalRepresentation(TextStream& ts, int indent) const
{
    writeIndent(ts, indent);
    ts << "[feColorMatrix";
    FilterEffect::externalRepresentation(ts);
    ts << " type=\"" << m_type << "\"";
    if (!m_values.isEmpty()) {
        ts << " values=\"";
        Vector<float>::const_iterator ptr = m_values.begin();
        const Vector<float>::const_iterator end = m_values.end();
        while (ptr < end) {
            ts << *ptr;
            ++ptr;
            if (ptr < end)
                ts << " ";
        }
        ts << "\"";
    }
    ts << "]\n";
    inputEffect(0)->externalRepresentation(ts, indent + 1);
    return ts;
}

} // namespace blink
