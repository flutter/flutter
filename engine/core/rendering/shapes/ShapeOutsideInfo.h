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
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER “AS IS” AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
 * OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
 * THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#ifndef ShapeOutsideInfo_h
#define ShapeOutsideInfo_h

#include "core/rendering/shapes/Shape.h"
#include "core/rendering/style/RenderStyle.h"
#include "core/rendering/style/ShapeValue.h"
#include "platform/geometry/FloatRect.h"
#include "platform/geometry/LayoutSize.h"
#include "wtf/OwnPtr.h"

namespace blink {

class RenderBlockFlow;
class RenderBox;
class FloatingObject;

class ShapeOutsideDeltas final {
public:
    ShapeOutsideDeltas()
        : m_lineOverlapsShape(false)
        , m_isValid(false)
    {
    }

    ShapeOutsideDeltas(LayoutUnit leftMarginBoxDelta, LayoutUnit rightMarginBoxDelta, bool lineOverlapsShape, LayoutUnit borderBoxLineTop, LayoutUnit lineHeight)
        : m_leftMarginBoxDelta(leftMarginBoxDelta)
        , m_rightMarginBoxDelta(rightMarginBoxDelta)
        , m_borderBoxLineTop(borderBoxLineTop)
        , m_lineHeight(lineHeight)
        , m_lineOverlapsShape(lineOverlapsShape)
        , m_isValid(true)
    {
    }

    bool isForLine(LayoutUnit borderBoxLineTop, LayoutUnit lineHeight)
    {
        return m_isValid && m_borderBoxLineTop == borderBoxLineTop && m_lineHeight == lineHeight;
    }

    bool isValid() { return m_isValid; }
    LayoutUnit leftMarginBoxDelta() { ASSERT(m_isValid); return m_leftMarginBoxDelta; }
    LayoutUnit rightMarginBoxDelta() { ASSERT(m_isValid); return m_rightMarginBoxDelta; }
    bool lineOverlapsShape() { ASSERT(m_isValid); return m_lineOverlapsShape; }

private:
    LayoutUnit m_leftMarginBoxDelta;
    LayoutUnit m_rightMarginBoxDelta;
    LayoutUnit m_borderBoxLineTop;
    LayoutUnit m_lineHeight;
    bool m_lineOverlapsShape : 1;
    bool m_isValid : 1;
};

class ShapeOutsideInfo final {
    WTF_MAKE_FAST_ALLOCATED;
public:
    void setReferenceBoxLogicalSize(LayoutSize);

    LayoutUnit shapeLogicalTop() const { return computedShape().shapeMarginLogicalBoundingBox().y() + logicalTopOffset(); }
    LayoutUnit shapeLogicalBottom() const { return computedShape().shapeMarginLogicalBoundingBox().maxY() + logicalTopOffset(); }
    LayoutUnit shapeLogicalLeft() const { return computedShape().shapeMarginLogicalBoundingBox().x() + logicalLeftOffset(); }
    LayoutUnit shapeLogicalRight() const { return computedShape().shapeMarginLogicalBoundingBox().maxX() + logicalLeftOffset(); }
    LayoutUnit shapeLogicalWidth() const { return computedShape().shapeMarginLogicalBoundingBox().width(); }
    LayoutUnit shapeLogicalHeight() const { return computedShape().shapeMarginLogicalBoundingBox().height(); }

    static PassOwnPtr<ShapeOutsideInfo> createInfo(const RenderBox& renderer) { return adoptPtr(new ShapeOutsideInfo(renderer)); }
    static bool isEnabledFor(const RenderBox&);

    ShapeOutsideDeltas computeDeltasForContainingBlockLine(const RenderBlockFlow&, const FloatingObject&, LayoutUnit lineTop, LayoutUnit lineHeight);

    static ShapeOutsideInfo& ensureInfo(const RenderBox& key)
    {
        InfoMap& infoMap = ShapeOutsideInfo::infoMap();
        if (ShapeOutsideInfo* info = infoMap.get(&key))
            return *info;
        InfoMap::AddResult result = infoMap.add(&key, ShapeOutsideInfo::createInfo(key));
        return *result.storedValue->value;
    }
    static void removeInfo(const RenderBox& key) { infoMap().remove(&key); }
    static ShapeOutsideInfo* info(const RenderBox& key) { return infoMap().get(&key); }

    void markShapeAsDirty() { m_shape.clear(); }
    bool isShapeDirty() { return !m_shape.get(); }
    LayoutSize shapeSize() const { return m_referenceBoxLogicalSize; }

    LayoutRect computedShapePhysicalBoundingBox() const;
    FloatPoint shapeToRendererPoint(FloatPoint) const;
    FloatSize shapeToRendererSize(FloatSize) const;
    const Shape& computedShape() const;

protected:
    ShapeOutsideInfo(const RenderBox& renderer)
        : m_renderer(renderer)
    { }

private:
    PassOwnPtr<Shape> createShapeForImage(StyleImage*, float shapeImageThreshold, WritingMode, float margin) const;

    LayoutUnit logicalTopOffset() const;
    LayoutUnit logicalLeftOffset() const;

    typedef HashMap<const RenderBox*, OwnPtr<ShapeOutsideInfo> > InfoMap;
    static InfoMap& infoMap()
    {
        DEFINE_STATIC_LOCAL(InfoMap, staticInfoMap, ());
        return staticInfoMap;
    }

    const RenderBox& m_renderer;
    mutable OwnPtr<Shape> m_shape;
    LayoutSize m_referenceBoxLogicalSize;
    ShapeOutsideDeltas m_shapeOutsideDeltas;
};

}
#endif
