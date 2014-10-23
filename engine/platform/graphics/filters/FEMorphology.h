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

#ifndef FEMorphology_h
#define FEMorphology_h

#include "platform/graphics/filters/Filter.h"
#include "platform/graphics/filters/FilterEffect.h"

namespace blink {

enum MorphologyOperatorType {
    FEMORPHOLOGY_OPERATOR_UNKNOWN = 0,
    FEMORPHOLOGY_OPERATOR_ERODE = 1,
    FEMORPHOLOGY_OPERATOR_DILATE = 2
};

class PLATFORM_EXPORT FEMorphology : public FilterEffect {
public:
    static PassRefPtr<FEMorphology> create(Filter*, MorphologyOperatorType, float radiusX, float radiusY);
    MorphologyOperatorType morphologyOperator() const;
    bool setMorphologyOperator(MorphologyOperatorType);

    float radiusX() const;
    bool setRadiusX(float);

    float radiusY() const;
    bool setRadiusY(float);

    virtual PassRefPtr<SkImageFilter> createImageFilter(SkiaImageFilterBuilder*) OVERRIDE;

    virtual FloatRect mapRect(const FloatRect&, bool forward = true) OVERRIDE FINAL;

    virtual TextStream& externalRepresentation(TextStream&, int indention) const OVERRIDE;

    struct PaintingData {
        Uint8ClampedArray* srcPixelArray;
        Uint8ClampedArray* dstPixelArray;
        int width;
        int height;
        int radiusX;
        int radiusY;
    };

    static const int s_minimalArea = (300 * 300); // Empirical data limit for parallel jobs

    struct PlatformApplyParameters {
        FEMorphology* filter;
        int startY;
        int endY;
        PaintingData* paintingData;
    };

private:
    FEMorphology(Filter*, MorphologyOperatorType, float radiusX, float radiusY);

    virtual void applySoftware() OVERRIDE;

    MorphologyOperatorType m_type;
    float m_radiusX;
    float m_radiusY;
};

} // namespace blink

#endif // FEMorphology_h
