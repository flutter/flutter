/*
 * Copyright (C) 2013 Adobe Systems Incorporated. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer.
 * 2. Redistributions in binary form must reproduce the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer in the documentation and/or other materials
 *    provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "core/rendering/shapes/RasterShape.h"

#include "wtf/MathExtras.h"

namespace blink {

class MarginIntervalGenerator {
public:
    MarginIntervalGenerator(unsigned radius);
    void set(int y, const IntShapeInterval&);
    IntShapeInterval intervalAt(int y) const;

private:
    Vector<int> m_xIntercepts;
    int m_y;
    int m_x1;
    int m_x2;
};

MarginIntervalGenerator::MarginIntervalGenerator(unsigned radius)
    : m_y(0)
    , m_x1(0)
    , m_x2(0)
{
    m_xIntercepts.resize(radius + 1);
    unsigned radiusSquared = radius * radius;
    for (unsigned y = 0; y <= radius; y++)
        m_xIntercepts[y] = sqrt(static_cast<double>(radiusSquared - y * y));
}

void MarginIntervalGenerator::set(int y, const IntShapeInterval& interval)
{
    ASSERT(y >= 0 && interval.x1() >= 0);
    m_y = y;
    m_x1 = interval.x1();
    m_x2 = interval.x2();
}

IntShapeInterval MarginIntervalGenerator::intervalAt(int y) const
{
    unsigned xInterceptsIndex = abs(y - m_y);
    int dx = (xInterceptsIndex >= m_xIntercepts.size()) ? 0 : m_xIntercepts[xInterceptsIndex];
    return IntShapeInterval(m_x1 - dx, m_x2 + dx);
}

PassOwnPtr<RasterShapeIntervals> RasterShapeIntervals::computeShapeMarginIntervals(int shapeMargin) const
{
    int marginIntervalsSize = (offset() > shapeMargin) ? size() : size() - offset() * 2 + shapeMargin * 2;
    OwnPtr<RasterShapeIntervals> result = adoptPtr(new RasterShapeIntervals(marginIntervalsSize, std::max(shapeMargin, offset())));
    MarginIntervalGenerator marginIntervalGenerator(shapeMargin);

    for (int y = bounds().y(); y < bounds().maxY(); ++y) {
        const IntShapeInterval& intervalAtY = intervalAt(y);
        if (intervalAtY.isEmpty())
            continue;

        marginIntervalGenerator.set(y, intervalAtY);
        int marginY0 = std::max(minY(), y - shapeMargin);
        int marginY1 = std::min(maxY(), y + shapeMargin + 1);

        for (int marginY = y - 1; marginY >= marginY0; --marginY) {
            if (marginY > bounds().y() && intervalAt(marginY).contains(intervalAtY))
                break;
            result->intervalAt(marginY).unite(marginIntervalGenerator.intervalAt(marginY));
        }

        result->intervalAt(y).unite(marginIntervalGenerator.intervalAt(y));

        for (int marginY = y + 1; marginY < marginY1; ++marginY) {
            if (marginY < bounds().maxY() && intervalAt(marginY).contains(intervalAtY))
                break;
            result->intervalAt(marginY).unite(marginIntervalGenerator.intervalAt(marginY));
        }
    }

    result->initializeBounds();
    return result.release();
}

void RasterShapeIntervals::initializeBounds()
{
    m_bounds = IntRect();
    for (int y = minY(); y < maxY(); ++y) {
        const IntShapeInterval& intervalAtY = intervalAt(y);
        if (intervalAtY.isEmpty())
            continue;
        m_bounds.unite(IntRect(intervalAtY.x1(), y, intervalAtY.width(), 1));
    }
}

void RasterShapeIntervals::buildBoundsPath(Path& path) const
{
    int maxY = bounds().maxY();
    for (int y = bounds().y(); y < maxY; y++) {
        if (intervalAt(y).isEmpty())
            continue;

        IntShapeInterval extent = intervalAt(y);
        int endY = y + 1;
        for (; endY < maxY; endY++) {
            if (intervalAt(endY).isEmpty() || intervalAt(endY) != extent)
                break;
        }
        path.addRect(FloatRect(extent.x1(), y, extent.width(), endY - y));
        y = endY - 1;
    }
}

const RasterShapeIntervals& RasterShape::marginIntervals() const
{
    ASSERT(shapeMargin() >= 0);
    if (!shapeMargin())
        return *m_intervals;

    int shapeMarginInt = clampToPositiveInteger(ceil(shapeMargin()));
    int maxShapeMarginInt = std::max(m_marginRectSize.width(), m_marginRectSize.height()) * sqrtf(2);
    if (!m_marginIntervals)
        m_marginIntervals = m_intervals->computeShapeMarginIntervals(std::min(shapeMarginInt, maxShapeMarginInt));

    return *m_marginIntervals;
}

LineSegment RasterShape::getExcludedInterval(LayoutUnit logicalTop, LayoutUnit logicalHeight) const
{
    const RasterShapeIntervals& intervals = marginIntervals();
    if (intervals.isEmpty())
        return LineSegment();

    int y1 = logicalTop;
    int y2 = logicalTop + logicalHeight;
    ASSERT(y2 >= y1);
    if (y2 < intervals.bounds().y() || y1 >= intervals.bounds().maxY())
        return LineSegment();

    y1 = std::max(y1, intervals.bounds().y());
    y2 = std::min(y2, intervals.bounds().maxY());
    IntShapeInterval excludedInterval;

    if (y1 == y2) {
        excludedInterval = intervals.intervalAt(y1);
    } else {
        for (int y = y1; y < y2; y++)
            excludedInterval.unite(intervals.intervalAt(y));
    }

    // Note: |marginIntervals()| returns end-point exclusive
    // intervals. |excludedInterval.x2()| contains the left-most pixel
    // offset to the right of the calculated union.
    return LineSegment(excludedInterval.x1(), excludedInterval.x2());
}

} // namespace blink
