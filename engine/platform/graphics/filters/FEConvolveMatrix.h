/*
 * Copyright (C) 2004, 2005, 2006, 2007 Nikolas Zimmermann <zimmermann@kde.org>
 * Copyright (C) 2004, 2005 Rob Buis <buis@kde.org>
 * Copyright (C) 2005 Eric Seidel <eric@webkit.org>
 * Copyright (C) 2010 Zoltan Herczeg <zherczeg@webkit.org>
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

#ifndef FEConvolveMatrix_h
#define FEConvolveMatrix_h

#include "platform/geometry/FloatPoint.h"
#include "platform/geometry/FloatSize.h"
#include "platform/graphics/filters/Filter.h"
#include "platform/graphics/filters/FilterEffect.h"
#include "wtf/Vector.h"

namespace blink {

enum EdgeModeType {
    EDGEMODE_UNKNOWN   = 0,
    EDGEMODE_DUPLICATE = 1,
    EDGEMODE_WRAP      = 2,
    EDGEMODE_NONE      = 3
};

class PLATFORM_EXPORT FEConvolveMatrix : public FilterEffect {
public:
    static PassRefPtr<FEConvolveMatrix> create(Filter*, const IntSize&,
            float, float, const IntPoint&, EdgeModeType, const FloatPoint&,
            bool, const Vector<float>&);

    IntSize kernelSize() const;
    void setKernelSize(const IntSize&);

    const Vector<float>& kernel() const;
    void setKernel(const Vector<float>&);

    float divisor() const;
    bool setDivisor(float);

    float bias() const;
    bool setBias(float);

    IntPoint targetOffset() const;
    bool setTargetOffset(const IntPoint&);

    EdgeModeType edgeMode() const;
    bool setEdgeMode(EdgeModeType);

    FloatPoint kernelUnitLength() const;
    bool setKernelUnitLength(const FloatPoint&);

    bool preserveAlpha() const;
    bool setPreserveAlpha(bool);

    virtual PassRefPtr<SkImageFilter> createImageFilter(SkiaImageFilterBuilder*) OVERRIDE;

    virtual FloatRect mapPaintRect(const FloatRect&, bool forward = true) OVERRIDE FINAL;

    virtual TextStream& externalRepresentation(TextStream&, int indention) const OVERRIDE;

private:

    struct PaintingData {
        Uint8ClampedArray* srcPixelArray;
        Uint8ClampedArray* dstPixelArray;
        int width;
        int height;
        float bias;
    };

    FEConvolveMatrix(Filter*, const IntSize&, float, float,
            const IntPoint&, EdgeModeType, const FloatPoint&, bool, const Vector<float>&);

    virtual void applySoftware() OVERRIDE;

    template<bool preserveAlphaValues>
    ALWAYS_INLINE void fastSetInteriorPixels(PaintingData&, int clipRight, int clipBottom, int yStart, int yEnd);

    ALWAYS_INLINE int getPixelValue(PaintingData&, int x, int y);

    template<bool preserveAlphaValues>
    void fastSetOuterPixels(PaintingData&, int x1, int y1, int x2, int y2);

    // Wrapper functions
    ALWAYS_INLINE void setInteriorPixels(PaintingData&, int clipRight, int clipBottom, int yStart, int yEnd);
    ALWAYS_INLINE void setOuterPixels(PaintingData&, int x1, int y1, int x2, int y2);

    // Parallelization parts
    static const int s_minimalRectDimension = (100 * 100); // Empirical data limit for parallel jobs

    template<typename Type>
    friend class ParallelJobs;

    struct InteriorPixelParameters {
        FEConvolveMatrix* filter;
        PaintingData* paintingData;
        int clipBottom;
        int clipRight;
        int yStart;
        int yEnd;
    };

    static void setInteriorPixelsWorker(InteriorPixelParameters*);

    IntSize m_kernelSize;
    float m_divisor;
    float m_bias;
    IntPoint m_targetOffset;
    EdgeModeType m_edgeMode;
    FloatPoint m_kernelUnitLength;
    bool m_preserveAlpha;
    Vector<float> m_kernelMatrix;
};

} // namespace blink

#endif // FEConvolveMatrix_h
