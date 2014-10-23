/*
 * Copyright (C) 2012 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef ScrollingConstraints_h
#define ScrollingConstraints_h

#include "platform/geometry/FloatRect.h"

namespace blink {

// ViewportConstraints classes encapsulate data and logic required to reposition elements whose layout
// depends on the viewport rect (i.e., position fixed), when scrolling and zooming.
class ViewportConstraints {
public:
    // FIXME: Simplify this code now that position: sticky doesn't exist.
    enum ConstraintType {
        FixedPositionConstaint,
    };

    enum AnchorEdgeFlags {
        AnchorEdgeLeft = 1 << 0,
        AnchorEdgeRight = 1 << 1,
        AnchorEdgeTop = 1 << 2,
        AnchorEdgeBottom = 1 << 3
    };
    typedef unsigned AnchorEdges;

    ViewportConstraints(const ViewportConstraints& other)
        : m_alignmentOffset(other.m_alignmentOffset)
        , m_anchorEdges(other.m_anchorEdges)
    { }

    virtual ~ViewportConstraints() { }

    virtual ConstraintType constraintType() const = 0;

    AnchorEdges anchorEdges() const { return m_anchorEdges; }
    bool hasAnchorEdge(AnchorEdgeFlags flag) const { return m_anchorEdges & flag; }
    void addAnchorEdge(AnchorEdgeFlags edgeFlag) { m_anchorEdges |= edgeFlag; }
    void setAnchorEdges(AnchorEdges edges) { m_anchorEdges = edges; }

    FloatSize alignmentOffset() const { return m_alignmentOffset; }
    void setAlignmentOffset(const FloatSize& offset) { m_alignmentOffset = offset; }

protected:
    ViewportConstraints()
        : m_anchorEdges(0)
    { }

    FloatSize m_alignmentOffset;
    AnchorEdges m_anchorEdges;
};

class FixedPositionViewportConstraints FINAL : public ViewportConstraints {
public:
    FixedPositionViewportConstraints()
        : ViewportConstraints()
    { }

    FixedPositionViewportConstraints(const FixedPositionViewportConstraints& other)
        : ViewportConstraints(other)
        , m_viewportRectAtLastLayout(other.m_viewportRectAtLastLayout)
        , m_layerPositionAtLastLayout(other.m_layerPositionAtLastLayout)
    { }

    FloatPoint layerPositionForViewportRect(const FloatRect& viewportRect) const;

    const FloatRect& viewportRectAtLastLayout() const { return m_viewportRectAtLastLayout; }
    void setViewportRectAtLastLayout(const FloatRect& rect) { m_viewportRectAtLastLayout = rect; }

    const FloatPoint& layerPositionAtLastLayout() const { return m_layerPositionAtLastLayout; }
    void setLayerPositionAtLastLayout(const FloatPoint& point) { m_layerPositionAtLastLayout = point; }

    bool operator==(const FixedPositionViewportConstraints& other) const
    {
        return m_alignmentOffset == other.m_alignmentOffset
            && m_anchorEdges == other.m_anchorEdges
            && m_viewportRectAtLastLayout == other.m_viewportRectAtLastLayout
            && m_layerPositionAtLastLayout == other.m_layerPositionAtLastLayout;
    }

    bool operator!=(const FixedPositionViewportConstraints& other) const { return !(*this == other); }

private:
    virtual ConstraintType constraintType() const OVERRIDE { return FixedPositionConstaint; }

    FloatRect m_viewportRectAtLastLayout;
    FloatPoint m_layerPositionAtLastLayout;
};

} // namespace blink

#endif // ScrollingConstraints_h
