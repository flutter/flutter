/*
 * Copyright (C) 2004, 2005, 2006, 2007 Nikolas Zimmermann <zimmermann@kde.org>
 * Copyright (C) 2004, 2005 Rob Buis <buis@kde.org>
 * Copyright (C) 2005 Eric Seidel <eric@webkit.org>
 * Copyright (C) 2009 Dirk Schulze <krit@webkit.org>
 * Copyright (C) 2010 Renata Hodovan <reni@inf.u-szeged.hu>
 * Copyright (C) 2011 Gabor Loki <loki@webkit.org>
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
#include "platform/graphics/filters/FETurbulence.h"

#include "SkPerlinNoiseShader.h"
#include "SkRectShaderImageFilter.h"
#include "platform/graphics/filters/ParallelJobs.h"
#include "platform/graphics/filters/SkiaImageFilterBuilder.h"
#include "platform/text/TextStream.h"
#include "wtf/MathExtras.h"
#include "wtf/Uint8ClampedArray.h"

namespace blink {

/*
    Produces results in the range [1, 2**31 - 2]. Algorithm is:
    r = (a * r) mod m where a = randAmplitude = 16807 and
    m = randMaximum = 2**31 - 1 = 2147483647, r = seed.
    See [Park & Miller], CACM vol. 31 no. 10 p. 1195, Oct. 1988
    To test: the algorithm should produce the result 1043618065
    as the 10,000th generated number if the original seed is 1.
*/
static const int s_perlinNoise = 4096;
static const long s_randMaximum = 2147483647; // 2**31 - 1
static const int s_randAmplitude = 16807; // 7**5; primitive root of m
static const int s_randQ = 127773; // m / a
static const int s_randR = 2836; // m % a

FETurbulence::FETurbulence(Filter* filter, TurbulenceType type, float baseFrequencyX, float baseFrequencyY, int numOctaves, float seed, bool stitchTiles)
    : FilterEffect(filter)
    , m_type(type)
    , m_baseFrequencyX(baseFrequencyX)
    , m_baseFrequencyY(baseFrequencyY)
    , m_numOctaves(numOctaves)
    , m_seed(seed)
    , m_stitchTiles(stitchTiles)
{
}

PassRefPtr<FETurbulence> FETurbulence::create(Filter* filter, TurbulenceType type, float baseFrequencyX, float baseFrequencyY, int numOctaves, float seed, bool stitchTiles)
{
    return adoptRef(new FETurbulence(filter, type, baseFrequencyX, baseFrequencyY, numOctaves, seed, stitchTiles));
}

TurbulenceType FETurbulence::type() const
{
    return m_type;
}

bool FETurbulence::setType(TurbulenceType type)
{
    if (m_type == type)
        return false;
    m_type = type;
    return true;
}

float FETurbulence::baseFrequencyY() const
{
    return m_baseFrequencyY;
}

bool FETurbulence::setBaseFrequencyY(float baseFrequencyY)
{
    if (m_baseFrequencyY == baseFrequencyY)
        return false;
    m_baseFrequencyY = baseFrequencyY;
    return true;
}

float FETurbulence::baseFrequencyX() const
{
    return m_baseFrequencyX;
}

bool FETurbulence::setBaseFrequencyX(float baseFrequencyX)
{
    if (m_baseFrequencyX == baseFrequencyX)
        return false;
    m_baseFrequencyX = baseFrequencyX;
    return true;
}

float FETurbulence::seed() const
{
    return m_seed;
}

bool FETurbulence::setSeed(float seed)
{
    if (m_seed == seed)
        return false;
    m_seed = seed;
    return true;
}

int FETurbulence::numOctaves() const
{
    return m_numOctaves;
}

bool FETurbulence::setNumOctaves(int numOctaves)
{
    if (m_numOctaves == numOctaves)
        return false;
    m_numOctaves = numOctaves;
    return true;
}

bool FETurbulence::stitchTiles() const
{
    return m_stitchTiles;
}

bool FETurbulence::setStitchTiles(bool stitch)
{
    if (m_stitchTiles == stitch)
        return false;
    m_stitchTiles = stitch;
    return true;
}

// The turbulence calculation code is an adapted version of what appears in the SVG 1.1 specification:
// http://www.w3.org/TR/SVG11/filters.html#feTurbulence

// Compute pseudo random number.
inline long FETurbulence::PaintingData::random()
{
    long result = s_randAmplitude * (seed % s_randQ) - s_randR * (seed / s_randQ);
    if (result <= 0)
        result += s_randMaximum;
    seed = result;
    return result;
}

inline float smoothCurve(float t)
{
    return t * t * (3 - 2 * t);
}

inline float linearInterpolation(float t, float a, float b)
{
    return a + t * (b - a);
}

inline void FETurbulence::initPaint(PaintingData& paintingData)
{
    float normalizationFactor;

    // The seed value clamp to the range [1, s_randMaximum - 1].
    if (paintingData.seed <= 0)
        paintingData.seed = -(paintingData.seed % (s_randMaximum - 1)) + 1;
    if (paintingData.seed > s_randMaximum - 1)
        paintingData.seed = s_randMaximum - 1;

    float* gradient;
    for (int channel = 0; channel < 4; ++channel) {
        for (int i = 0; i < s_blockSize; ++i) {
            paintingData.latticeSelector[i] = i;
            gradient = paintingData.gradient[channel][i];
            gradient[0] = static_cast<float>((paintingData.random() % (2 * s_blockSize)) - s_blockSize) / s_blockSize;
            gradient[1] = static_cast<float>((paintingData.random() % (2 * s_blockSize)) - s_blockSize) / s_blockSize;
            normalizationFactor = sqrtf(gradient[0] * gradient[0] + gradient[1] * gradient[1]);
            gradient[0] /= normalizationFactor;
            gradient[1] /= normalizationFactor;
        }
    }
    for (int i = s_blockSize - 1; i > 0; --i) {
        int k = paintingData.latticeSelector[i];
        int j = paintingData.random() % s_blockSize;
        ASSERT(j >= 0);
        ASSERT(j < 2 * s_blockSize + 2);
        paintingData.latticeSelector[i] = paintingData.latticeSelector[j];
        paintingData.latticeSelector[j] = k;
    }
    for (int i = 0; i < s_blockSize + 2; ++i) {
        paintingData.latticeSelector[s_blockSize + i] = paintingData.latticeSelector[i];
        for (int channel = 0; channel < 4; ++channel) {
            paintingData.gradient[channel][s_blockSize + i][0] = paintingData.gradient[channel][i][0];
            paintingData.gradient[channel][s_blockSize + i][1] = paintingData.gradient[channel][i][1];
        }
    }
}

inline void checkNoise(int& noiseValue, int limitValue, int newValue)
{
    if (noiseValue >= limitValue)
        noiseValue -= newValue;
    if (noiseValue >= limitValue - 1)
        noiseValue -= newValue - 1;
}

float FETurbulence::noise2D(int channel, PaintingData& paintingData, StitchData& stitchData, const FloatPoint& noiseVector)
{
    struct Noise {
        int noisePositionIntegerValue;
        float noisePositionFractionValue;

        Noise(float component)
        {
            float position = component + s_perlinNoise;
            noisePositionIntegerValue = static_cast<int>(position);
            noisePositionFractionValue = position - noisePositionIntegerValue;
        }
    };

    Noise noiseX(noiseVector.x());
    Noise noiseY(noiseVector.y());
    float* q;
    float sx, sy, a, b, u, v;

    // If stitching, adjust lattice points accordingly.
    if (m_stitchTiles) {
        checkNoise(noiseX.noisePositionIntegerValue, stitchData.wrapX, stitchData.width);
        checkNoise(noiseY.noisePositionIntegerValue, stitchData.wrapY, stitchData.height);
    }

    noiseX.noisePositionIntegerValue &= s_blockMask;
    noiseY.noisePositionIntegerValue &= s_blockMask;
    int latticeIndex = paintingData.latticeSelector[noiseX.noisePositionIntegerValue];
    int nextLatticeIndex = paintingData.latticeSelector[(noiseX.noisePositionIntegerValue + 1) & s_blockMask];

    sx = smoothCurve(noiseX.noisePositionFractionValue);
    sy = smoothCurve(noiseY.noisePositionFractionValue);

    // This is taken 1:1 from SVG spec: http://www.w3.org/TR/SVG11/filters.html#feTurbulenceElement.
    int temp = paintingData.latticeSelector[latticeIndex + noiseY.noisePositionIntegerValue];
    q = paintingData.gradient[channel][temp];
    u = noiseX.noisePositionFractionValue * q[0] + noiseY.noisePositionFractionValue * q[1];
    temp = paintingData.latticeSelector[nextLatticeIndex + noiseY.noisePositionIntegerValue];
    q = paintingData.gradient[channel][temp];
    v = (noiseX.noisePositionFractionValue - 1) * q[0] + noiseY.noisePositionFractionValue * q[1];
    a = linearInterpolation(sx, u, v);
    temp = paintingData.latticeSelector[latticeIndex + noiseY.noisePositionIntegerValue + 1];
    q = paintingData.gradient[channel][temp];
    u = noiseX.noisePositionFractionValue * q[0] + (noiseY.noisePositionFractionValue - 1) * q[1];
    temp = paintingData.latticeSelector[nextLatticeIndex + noiseY.noisePositionIntegerValue + 1];
    q = paintingData.gradient[channel][temp];
    v = (noiseX.noisePositionFractionValue - 1) * q[0] + (noiseY.noisePositionFractionValue - 1) * q[1];
    b = linearInterpolation(sx, u, v);
    return linearInterpolation(sy, a, b);
}

unsigned char FETurbulence::calculateTurbulenceValueForPoint(int channel, PaintingData& paintingData, StitchData& stitchData, const FloatPoint& point, float baseFrequencyX, float baseFrequencyY)
{
    float tileWidth = paintingData.filterSize.width();
    float tileHeight = paintingData.filterSize.height();
    ASSERT(tileWidth > 0 && tileHeight > 0);
    // Adjust the base frequencies if necessary for stitching.
    if (m_stitchTiles) {
        // When stitching tiled turbulence, the frequencies must be adjusted
        // so that the tile borders will be continuous.
        if (baseFrequencyX) {
            float lowFrequency = floorf(tileWidth * baseFrequencyX) / tileWidth;
            float highFrequency = ceilf(tileWidth * baseFrequencyX) / tileWidth;
            // BaseFrequency should be non-negative according to the standard.
            if (baseFrequencyX / lowFrequency < highFrequency / baseFrequencyX)
                baseFrequencyX = lowFrequency;
            else
                baseFrequencyX = highFrequency;
        }
        if (baseFrequencyY) {
            float lowFrequency = floorf(tileHeight * baseFrequencyY) / tileHeight;
            float highFrequency = ceilf(tileHeight * baseFrequencyY) / tileHeight;
            if (baseFrequencyY / lowFrequency < highFrequency / baseFrequencyY)
                baseFrequencyY = lowFrequency;
            else
                baseFrequencyY = highFrequency;
        }
        // Set up TurbulenceInitial stitch values.
        stitchData.width = roundf(tileWidth * baseFrequencyX);
        stitchData.wrapX = s_perlinNoise + stitchData.width;
        stitchData.height = roundf(tileHeight * baseFrequencyY);
        stitchData.wrapY = s_perlinNoise + stitchData.height;
    }
    float turbulenceFunctionResult = 0;
    FloatPoint noiseVector(point.x() * baseFrequencyX, point.y() * baseFrequencyY);
    float ratio = 1;
    for (int octave = 0; octave < m_numOctaves; ++octave) {
        if (m_type == FETURBULENCE_TYPE_FRACTALNOISE)
            turbulenceFunctionResult += noise2D(channel, paintingData, stitchData, noiseVector) / ratio;
        else
            turbulenceFunctionResult += fabsf(noise2D(channel, paintingData, stitchData, noiseVector)) / ratio;
        noiseVector.setX(noiseVector.x() * 2);
        noiseVector.setY(noiseVector.y() * 2);
        ratio *= 2;
        if (m_stitchTiles) {
            // Update stitch values. Subtracting s_perlinNoiseoise before the multiplication and
            // adding it afterward simplifies to subtracting it once.
            stitchData.width *= 2;
            stitchData.wrapX = 2 * stitchData.wrapX - s_perlinNoise;
            stitchData.height *= 2;
            stitchData.wrapY = 2 * stitchData.wrapY - s_perlinNoise;
        }
    }

    // The value of turbulenceFunctionResult comes from ((turbulenceFunctionResult * 255) + 255) / 2 by fractalNoise
    // and (turbulenceFunctionResult * 255) by turbulence.
    if (m_type == FETURBULENCE_TYPE_FRACTALNOISE)
        turbulenceFunctionResult = turbulenceFunctionResult * 0.5f + 0.5f;
    // Clamp result
    turbulenceFunctionResult = std::max(std::min(turbulenceFunctionResult, 1.f), 0.f);
    return static_cast<unsigned char>(turbulenceFunctionResult * 255);
}

inline void FETurbulence::fillRegion(Uint8ClampedArray* pixelArray, PaintingData& paintingData, int startY, int endY, float baseFrequencyX, float baseFrequencyY)
{
    IntRect filterRegion = absolutePaintRect();
    IntPoint point(0, filterRegion.y() + startY);
    int indexOfPixelChannel = startY * (filterRegion.width() << 2);
    int channel;
    StitchData stitchData;

    for (int y = startY; y < endY; ++y) {
        point.setY(point.y() + 1);
        point.setX(filterRegion.x());
        for (int x = 0; x < filterRegion.width(); ++x) {
            point.setX(point.x() + 1);
            for (channel = 0; channel < 4; ++channel, ++indexOfPixelChannel)
                pixelArray->set(indexOfPixelChannel, calculateTurbulenceValueForPoint(channel, paintingData, stitchData, filter()->mapAbsolutePointToLocalPoint(point), baseFrequencyX, baseFrequencyY));
        }
    }
}

void FETurbulence::fillRegionWorker(FillRegionParameters* parameters)
{
    parameters->filter->fillRegion(parameters->pixelArray, *parameters->paintingData, parameters->startY, parameters->endY, parameters->baseFrequencyX, parameters->baseFrequencyY);
}

void FETurbulence::applySoftware()
{
    Uint8ClampedArray* pixelArray = createUnmultipliedImageResult();
    if (!pixelArray)
        return;

    if (absolutePaintRect().isEmpty()) {
        pixelArray->zeroFill();
        return;
    }

    PaintingData paintingData(m_seed, roundedIntSize(filterPrimitiveSubregion().size()));
    initPaint(paintingData);

    int optimalThreadNumber = (absolutePaintRect().width() * absolutePaintRect().height()) / s_minimalRectDimension;
    if (optimalThreadNumber > 1) {
        // Initialize parallel jobs
        ParallelJobs<FillRegionParameters> parallelJobs(&FETurbulence::fillRegionWorker, optimalThreadNumber);

        // Fill the parameter array
        int i = parallelJobs.numberOfJobs();
        if (i > 1) {
            // Split the job into "stepY"-sized jobs but there a few jobs that need to be slightly larger since
            // stepY * jobs < total size. These extras are handled by the remainder "jobsWithExtra".
            const int stepY = absolutePaintRect().height() / i;
            const int jobsWithExtra = absolutePaintRect().height() % i;

            int startY = 0;
            for (; i > 0; --i) {
                FillRegionParameters& params = parallelJobs.parameter(i-1);
                params.filter = this;
                params.pixelArray = pixelArray;
                params.paintingData = &paintingData;
                params.startY = startY;
                startY += i < jobsWithExtra ? stepY + 1 : stepY;
                params.endY = startY;
                params.baseFrequencyX = m_baseFrequencyX;
                params.baseFrequencyY = m_baseFrequencyY;
            }

            // Execute parallel jobs
            parallelJobs.execute();
            return;
        }
    }

    // Fallback to single threaded mode if there is no room for a new thread or the paint area is too small.
    fillRegion(pixelArray, paintingData, 0, absolutePaintRect().height(), m_baseFrequencyX, m_baseFrequencyY);
}

SkShader* FETurbulence::createShader()
{
    const SkISize size = SkISize::Make(effectBoundaries().width(), effectBoundaries().height());
    // Frequency should be scaled by page zoom, but not by primitiveUnits.
    // So we apply only the transform scale (as Filter::apply*Scale() do)
    // and not the target bounding box scale (as SVGFilter::apply*Scale()
    // would do). Note also that we divide by the scale since this is
    // a frequency, not a period.
    const AffineTransform& absoluteTransform = filter()->absoluteTransform();
    float baseFrequencyX = m_baseFrequencyX / absoluteTransform.a();
    float baseFrequencyY = m_baseFrequencyY / absoluteTransform.d();
    return (type() == FETURBULENCE_TYPE_FRACTALNOISE) ?
        SkPerlinNoiseShader::CreateFractalNoise(SkFloatToScalar(baseFrequencyX),
            SkFloatToScalar(baseFrequencyY), numOctaves(), SkFloatToScalar(seed()),
            stitchTiles() ? &size : 0) :
        SkPerlinNoiseShader::CreateTurbulence(SkFloatToScalar(baseFrequencyX),
            SkFloatToScalar(baseFrequencyY), numOctaves(), SkFloatToScalar(seed()),
            stitchTiles() ? &size : 0);
}

PassRefPtr<SkImageFilter> FETurbulence::createImageFilter(SkiaImageFilterBuilder* builder)
{
    SkAutoTUnref<SkShader> shader(createShader());
    SkImageFilter::CropRect rect = getCropRect(builder->cropOffset());
    return adoptRef(SkRectShaderImageFilter::Create(shader, &rect));
}

static TextStream& operator<<(TextStream& ts, const TurbulenceType& type)
{
    switch (type) {
    case FETURBULENCE_TYPE_UNKNOWN:
        ts << "UNKNOWN";
        break;
    case FETURBULENCE_TYPE_TURBULENCE:
        ts << "TURBULENCE";
        break;
    case FETURBULENCE_TYPE_FRACTALNOISE:
        ts << "NOISE";
        break;
    }
    return ts;
}

TextStream& FETurbulence::externalRepresentation(TextStream& ts, int indent) const
{
    writeIndent(ts, indent);
    ts << "[feTurbulence";
    FilterEffect::externalRepresentation(ts);
    ts << " type=\"" << type() << "\" "
       << "baseFrequency=\"" << baseFrequencyX() << ", " << baseFrequencyY() << "\" "
       << "seed=\"" << seed() << "\" "
       << "numOctaves=\"" << numOctaves() << "\" "
       << "stitchTiles=\"" << stitchTiles() << "\"]\n";
    return ts;
}

} // namespace blink
