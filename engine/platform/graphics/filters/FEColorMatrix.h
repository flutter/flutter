/*
 * Copyright (C) 2004, 2005, 2006, 2007 Nikolas Zimmermann <zimmermann@kde.org>
 * Copyright (C) 2004, 2005 Rob Buis <buis@kde.org>
 * Copyright (C) 2005 Eric Seidel <eric@webkit.org>
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

#ifndef FEColorMatrix_h
#define FEColorMatrix_h

#include "platform/graphics/filters/Filter.h"
#include "platform/graphics/filters/FilterEffect.h"
#include "wtf/Vector.h"

namespace blink {

enum ColorMatrixType {
    FECOLORMATRIX_TYPE_UNKNOWN          = 0,
    FECOLORMATRIX_TYPE_MATRIX           = 1,
    FECOLORMATRIX_TYPE_SATURATE         = 2,
    FECOLORMATRIX_TYPE_HUEROTATE        = 3,
    FECOLORMATRIX_TYPE_LUMINANCETOALPHA = 4
};

class PLATFORM_EXPORT FEColorMatrix : public FilterEffect {
public:
    static PassRefPtr<FEColorMatrix> create(Filter*, ColorMatrixType, const Vector<float>&);

    ColorMatrixType type() const;
    bool setType(ColorMatrixType);

    const Vector<float>& values() const;
    bool setValues(const Vector<float>&);

    virtual PassRefPtr<SkImageFilter> createImageFilter(SkiaImageFilterBuilder*) override;

    virtual TextStream& externalRepresentation(TextStream&, int indention) const override;

    static inline void calculateSaturateComponents(float* components, float value);
    static inline void calculateHueRotateComponents(float* components, float value);

private:
    FEColorMatrix(Filter*, ColorMatrixType, const Vector<float>&);

    virtual void applySoftware() override;

    virtual bool affectsTransparentPixels() override;

    ColorMatrixType m_type;
    Vector<float> m_values;
};

} // namespace blink

#endif // FEColorMatrix_h
