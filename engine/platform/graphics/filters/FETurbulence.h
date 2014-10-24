/*
 * Copyright (C) 2004, 2005, 2006, 2007 Nikolas Zimmermann <zimmermann@kde.org>
 * Copyright (C) 2004, 2005 Rob Buis <buis@kde.org>
 * Copyright (C) 2005 Eric Seidel <eric@webkit.org>
 * Copyright (C) 2009 Dirk Schulze <krit@webkit.org>
 * Copyright (C) 2010 Renata Hodovan <reni@inf.u-szeged.hu>
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

#ifndef FETurbulence_h
#define FETurbulence_h

#include "platform/graphics/filters/Filter.h"
#include "platform/graphics/filters/FilterEffect.h"

namespace blink {

enum TurbulenceType {
    FETURBULENCE_TYPE_UNKNOWN = 0,
    FETURBULENCE_TYPE_FRACTALNOISE = 1,
    FETURBULENCE_TYPE_TURBULENCE = 2
};

class PLATFORM_EXPORT FETurbulence : public FilterEffect {
public:
    static PassRefPtr<FETurbulence> create(Filter*, TurbulenceType, float, float, int, float, bool);

    TurbulenceType type() const;
    bool setType(TurbulenceType);

    float baseFrequencyY() const;
    bool setBaseFrequencyY(float);

    float baseFrequencyX() const;
    bool setBaseFrequencyX(float);

    float seed() const;
    bool setSeed(float);

    int numOctaves() const;
    bool setNumOctaves(int);

    bool stitchTiles() const;
    bool setStitchTiles(bool);

    static void fillRegionWorker(void*);

    virtual TextStream& externalRepresentation(TextStream&, int indention) const override;

private:
    static const int s_blockSize = 256;
    static const int s_blockMask = s_blockSize - 1;

    static const int s_minimalRectDimension = (100 * 100); // Empirical data limit for parallel jobs.

    struct PaintingData {
        PaintingData(long paintingSeed, const IntSize& paintingSize)
            : seed(paintingSeed)
            , filterSize(paintingSize)
        {
        }

        long seed;
        int latticeSelector[2 * s_blockSize + 2];
        float gradient[4][2 * s_blockSize + 2][2];
        IntSize filterSize;

        inline long random();
    };

    struct StitchData {
        StitchData()
            : width(0)
            , wrapX(0)
            , height(0)
            , wrapY(0)
        {
        }

        int width; // How much to subtract to wrap for stitching.
        int wrapX; // Minimum value to wrap.
        int height;
        int wrapY;
    };

    template<typename Type>
    friend class ParallelJobs;

    struct FillRegionParameters {
        FETurbulence* filter;
        Uint8ClampedArray* pixelArray;
        PaintingData* paintingData;
        int startY;
        int endY;
        float baseFrequencyX;
        float baseFrequencyY;
    };

    static void fillRegionWorker(FillRegionParameters*);

    FETurbulence(Filter*, TurbulenceType, float, float, int, float, bool);

    virtual void applySoftware() override;
    virtual PassRefPtr<SkImageFilter> createImageFilter(SkiaImageFilterBuilder*) override;
    SkShader* createShader();

    inline void initPaint(PaintingData&);
    float noise2D(int channel, PaintingData&, StitchData&, const FloatPoint&);
    unsigned char calculateTurbulenceValueForPoint(int channel, PaintingData&, StitchData&, const FloatPoint&, float, float);
    inline void fillRegion(Uint8ClampedArray*, PaintingData&, int, int, float, float);

    TurbulenceType m_type;
    float m_baseFrequencyX;
    float m_baseFrequencyY;
    int m_numOctaves;
    float m_seed;
    bool m_stitchTiles;
};

} // namespace blink

#endif // FETurbulence_h
