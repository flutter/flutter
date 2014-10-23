/*
 * Copyright (C) 2012 Adobe Systems Incorporated. All rights reserved.
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

#ifndef Shape_h
#define Shape_h

#include "core/rendering/style/BasicShapes.h"
#include "core/rendering/style/StyleImage.h"
#include "platform/geometry/LayoutRect.h"
#include "platform/geometry/RoundedRect.h"
#include "platform/graphics/Path.h"
#include "platform/text/WritingMode.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/Vector.h"

namespace blink {

struct LineSegment {
    LineSegment()
        : logicalLeft(0)
        , logicalRight(0)
        , isValid(false)
    {
    }

    LineSegment(float logicalLeft, float logicalRight)
        : logicalLeft(logicalLeft)
        , logicalRight(logicalRight)
        , isValid(true)
    {
    }

    float logicalLeft;
    float logicalRight;
    bool isValid;
};

// A representation of a BasicShape that enables layout code to determine how to break a line up into segments
// that will fit within or around a shape. The line is defined by a pair of logical Y coordinates and the
// computed segments are returned as pairs of logical X coordinates. The BasicShape itself is defined in
// physical coordinates.

class Shape {
public:
    struct DisplayPaths {
        Path shape;
        Path marginShape;
    };
    static PassOwnPtr<Shape> createShape(const BasicShape*, const LayoutSize& logicalBoxSize, WritingMode, float margin);
    static PassOwnPtr<Shape> createRasterShape(Image*, float threshold, const LayoutRect& imageRect, const LayoutRect& marginRect, WritingMode, float margin);
    static PassOwnPtr<Shape> createEmptyRasterShape(WritingMode, float margin);
    static PassOwnPtr<Shape> createLayoutBoxShape(const RoundedRect&, WritingMode, float margin);

    virtual ~Shape() { }

    virtual LayoutRect shapeMarginLogicalBoundingBox() const = 0;
    virtual bool isEmpty() const = 0;
    virtual LineSegment getExcludedInterval(LayoutUnit logicalTop, LayoutUnit logicalHeight) const = 0;

    bool lineOverlapsShapeMarginBounds(LayoutUnit lineTop, LayoutUnit lineHeight) const { return lineOverlapsBoundingBox(lineTop, lineHeight, shapeMarginLogicalBoundingBox()); }
    virtual void buildDisplayPaths(DisplayPaths&) const = 0;

protected:
    float shapeMargin() const { return m_margin; }

private:
    bool lineOverlapsBoundingBox(LayoutUnit lineTop, LayoutUnit lineHeight, const LayoutRect& rect) const
    {
        if (rect.isEmpty())
            return false;
        return (lineTop < rect.maxY() && lineTop + lineHeight > rect.y()) || (!lineHeight && lineTop == rect.y());
    }

    WritingMode m_writingMode;
    float m_margin;
};

} // namespace blink

#endif // Shape_h
