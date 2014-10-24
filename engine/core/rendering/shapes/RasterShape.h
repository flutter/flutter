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

#ifndef RasterShape_h
#define RasterShape_h

#include "core/rendering/shapes/Shape.h"
#include "core/rendering/shapes/ShapeInterval.h"
#include "platform/geometry/FloatRect.h"
#include "wtf/Assertions.h"
#include "wtf/Vector.h"

namespace blink {

class RasterShapeIntervals {
public:
    RasterShapeIntervals(unsigned size, int offset = 0)
        : m_offset(offset)
    {
        m_intervals.resize(clampTo<int>(size));
    }

    void initializeBounds();
    const IntRect& bounds() const { return m_bounds; }
    bool isEmpty() const { return m_bounds.isEmpty(); }

    IntShapeInterval& intervalAt(int y)
    {
        ASSERT(y + m_offset >= 0 && static_cast<unsigned>(y + m_offset) < m_intervals.size());
        return m_intervals[y + m_offset];
    }

    const IntShapeInterval& intervalAt(int y) const
    {
        ASSERT(y + m_offset >= 0 && static_cast<unsigned>(y + m_offset) < m_intervals.size());
        return m_intervals[y + m_offset];
    }

    PassOwnPtr<RasterShapeIntervals> computeShapeMarginIntervals(int shapeMargin) const;

    void buildBoundsPath(Path&) const;

private:
    int size() const { return m_intervals.size(); }
    int offset() const { return m_offset; }
    int minY() const { return -m_offset; }
    int maxY() const { return -m_offset + m_intervals.size(); }

    IntRect m_bounds;
    Vector<IntShapeInterval> m_intervals;
    int m_offset;
};

class RasterShape final : public Shape {
    WTF_MAKE_NONCOPYABLE(RasterShape);
public:
    RasterShape(PassOwnPtr<RasterShapeIntervals> intervals, const IntSize& marginRectSize)
        : m_intervals(intervals)
        , m_marginRectSize(marginRectSize)
    {
        m_intervals->initializeBounds();
    }

    virtual LayoutRect shapeMarginLogicalBoundingBox() const override { return static_cast<LayoutRect>(marginIntervals().bounds()); }
    virtual bool isEmpty() const override { return m_intervals->isEmpty(); }
    virtual LineSegment getExcludedInterval(LayoutUnit logicalTop, LayoutUnit logicalHeight) const override;
    virtual void buildDisplayPaths(DisplayPaths& paths) const override
    {
        m_intervals->buildBoundsPath(paths.shape);
        if (shapeMargin())
            marginIntervals().buildBoundsPath(paths.marginShape);
    }

private:
    const RasterShapeIntervals& marginIntervals() const;

    OwnPtr<RasterShapeIntervals> m_intervals;
    mutable OwnPtr<RasterShapeIntervals> m_marginIntervals;
    IntSize m_marginRectSize;
};

} // namespace blink

#endif // RasterShape_h
