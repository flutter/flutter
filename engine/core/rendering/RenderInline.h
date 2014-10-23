/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2003, 2004, 2005, 2006, 2007, 2008, 2009 Apple Inc. All rights reserved.
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
 *
 */

#ifndef RenderInline_h
#define RenderInline_h

#include "core/editing/PositionWithAffinity.h"
#include "core/rendering/InlineFlowBox.h"
#include "core/rendering/RenderBoxModelObject.h"
#include "core/rendering/RenderLineBoxList.h"

namespace blink {

class RenderInline : public RenderBoxModelObject {
public:
    explicit RenderInline(Element*);
    virtual void trace(Visitor*) OVERRIDE;

    static RenderInline* createAnonymous(Document*);

    RenderObject* firstChild() const { ASSERT(children() == virtualChildren()); return children()->firstChild(); }
    RenderObject* lastChild() const { ASSERT(children() == virtualChildren()); return children()->lastChild(); }

    // If you have a RenderInline, use firstChild or lastChild instead.
    void slowFirstChild() const WTF_DELETED_FUNCTION;
    void slowLastChild() const WTF_DELETED_FUNCTION;

    virtual void addChild(RenderObject* newChild, RenderObject* beforeChild = 0) OVERRIDE;

    Element* node() const { return toElement(RenderBoxModelObject::node()); }

    virtual LayoutUnit marginLeft() const OVERRIDE FINAL;
    virtual LayoutUnit marginRight() const OVERRIDE FINAL;
    virtual LayoutUnit marginTop() const OVERRIDE FINAL;
    virtual LayoutUnit marginBottom() const OVERRIDE FINAL;
    virtual LayoutUnit marginBefore(const RenderStyle* otherStyle = 0) const OVERRIDE FINAL;
    virtual LayoutUnit marginAfter(const RenderStyle* otherStyle = 0) const OVERRIDE FINAL;
    virtual LayoutUnit marginStart(const RenderStyle* otherStyle = 0) const OVERRIDE FINAL;
    virtual LayoutUnit marginEnd(const RenderStyle* otherStyle = 0) const OVERRIDE FINAL;

    virtual void absoluteRects(Vector<IntRect>&, const LayoutPoint& accumulatedOffset) const OVERRIDE FINAL;
    virtual void absoluteQuads(Vector<FloatQuad>&, bool* wasFixed) const OVERRIDE;

    virtual LayoutSize offsetFromContainer(const RenderObject*, const LayoutPoint&, bool* offsetDependsOnPoint = 0) const OVERRIDE FINAL;

    IntRect linesBoundingBox() const;
    LayoutRect linesVisualOverflowBoundingBox() const;

    InlineFlowBox* createAndAppendInlineFlowBox();

    void dirtyLineBoxes(bool fullLayout);
    void deleteLineBoxTree();

    RenderLineBoxList* lineBoxes() { return &m_lineBoxes; }
    const RenderLineBoxList* lineBoxes() const { return &m_lineBoxes; }

    InlineFlowBox* firstLineBox() const { return m_lineBoxes.firstLineBox(); }
    InlineFlowBox* lastLineBox() const { return m_lineBoxes.lastLineBox(); }
    InlineBox* firstLineBoxIncludingCulling() const { return alwaysCreateLineBoxes() ? firstLineBox() : culledInlineFirstLineBox(); }
    InlineBox* lastLineBoxIncludingCulling() const { return alwaysCreateLineBoxes() ? lastLineBox() : culledInlineLastLineBox(); }

    virtual RenderBoxModelObject* virtualContinuation() const OVERRIDE FINAL { return continuation(); }
    RenderInline* inlineElementContinuation() const;

    LayoutSize offsetForInFlowPositionedInline(const RenderBox& child) const;

    virtual void addFocusRingRects(Vector<IntRect>&, const LayoutPoint& additionalOffset, const RenderLayerModelObject* paintContainer = 0) const OVERRIDE FINAL;
    void paintOutline(PaintInfo&, const LayoutPoint&);

    using RenderBoxModelObject::continuation;
    virtual void setContinuation(RenderBoxModelObject*) OVERRIDE FINAL;

    bool alwaysCreateLineBoxes() const { return alwaysCreateLineBoxesForRenderInline(); }
    void setAlwaysCreateLineBoxes(bool alwaysCreateLineBoxes = true) { setAlwaysCreateLineBoxesForRenderInline(alwaysCreateLineBoxes); }
    void updateAlwaysCreateLineBoxes(bool fullLayout);

    virtual LayoutRect localCaretRect(InlineBox*, int, LayoutUnit* extraWidthToEndOfLine) OVERRIDE FINAL;

    bool hitTestCulledInline(const HitTestRequest&, HitTestResult&, const HitTestLocation& locationInContainer, const LayoutPoint& accumulatedOffset);

protected:
    virtual void willBeDestroyed() OVERRIDE;

    virtual void styleDidChange(StyleDifference, const RenderStyle* oldStyle) OVERRIDE;

    virtual void computeSelfHitTestRects(Vector<LayoutRect>& rects, const LayoutPoint& layerOffset) const OVERRIDE;

private:
    virtual RenderObjectChildList* virtualChildren() OVERRIDE FINAL { return children(); }
    virtual const RenderObjectChildList* virtualChildren() const OVERRIDE FINAL { return children(); }
    const RenderObjectChildList* children() const { return &m_children; }
    RenderObjectChildList* children() { return &m_children; }

    virtual const char* renderName() const OVERRIDE;

    virtual bool isRenderInline() const OVERRIDE FINAL { return true; }

    LayoutRect culledInlineVisualOverflowBoundingBox() const;
    InlineBox* culledInlineFirstLineBox() const;
    InlineBox* culledInlineLastLineBox() const;

    template<typename GeneratorContext>
    void generateLineBoxRects(GeneratorContext& yield) const;
    template<typename GeneratorContext>
    void generateCulledLineBoxRects(GeneratorContext& yield, const RenderInline* container) const;

    void addChildToContinuation(RenderObject* newChild, RenderObject* beforeChild);
    virtual void addChildIgnoringContinuation(RenderObject* newChild, RenderObject* beforeChild = 0) OVERRIDE FINAL;

    void splitInlines(RenderBlock* fromBlock, RenderBlock* toBlock, RenderBlock* middleBlock,
                      RenderObject* beforeChild, RenderBoxModelObject* oldCont);
    void splitFlow(RenderObject* beforeChild, RenderBlock* newBlockBox,
                   RenderObject* newChild, RenderBoxModelObject* oldCont);

    virtual void layout() OVERRIDE FINAL { ASSERT_NOT_REACHED(); } // Do nothing for layout()

    virtual void paint(PaintInfo&, const LayoutPoint&) OVERRIDE FINAL;

    virtual bool nodeAtPoint(const HitTestRequest&, HitTestResult&, const HitTestLocation& locationInContainer, const LayoutPoint& accumulatedOffset, HitTestAction) OVERRIDE FINAL;

    virtual LayerType layerTypeRequired() const OVERRIDE { return isRelPositioned() || createsGroup() || hasClipPath() || style()->shouldCompositeForCurrentAnimations() ? NormalLayer : NoLayer; }

    virtual LayoutUnit offsetLeft() const OVERRIDE FINAL;
    virtual LayoutUnit offsetTop() const OVERRIDE FINAL;
    virtual LayoutUnit offsetWidth() const OVERRIDE FINAL { return linesBoundingBox().width(); }
    virtual LayoutUnit offsetHeight() const OVERRIDE FINAL { return linesBoundingBox().height(); }

    virtual LayoutRect clippedOverflowRectForPaintInvalidation(const RenderLayerModelObject* paintInvalidationContainer, const PaintInvalidationState* = 0) const OVERRIDE;
    virtual LayoutRect rectWithOutlineForPaintInvalidation(const RenderLayerModelObject* paintInvalidationContainer, LayoutUnit outlineWidth, const PaintInvalidationState* = 0) const OVERRIDE FINAL;
    virtual void mapRectToPaintInvalidationBacking(const RenderLayerModelObject* paintInvalidationContainer, LayoutRect&, const PaintInvalidationState*) const OVERRIDE FINAL;

    virtual void mapLocalToContainer(const RenderLayerModelObject* paintInvalidationContainer, TransformState&, MapCoordinatesFlags = ApplyContainerFlip, bool* wasFixed = 0, const PaintInvalidationState* = 0) const OVERRIDE;

    virtual PositionWithAffinity positionForPoint(const LayoutPoint&) OVERRIDE FINAL;

    virtual IntRect borderBoundingBox() const OVERRIDE FINAL
    {
        IntRect boundingBox = linesBoundingBox();
        return IntRect(0, 0, boundingBox.width(), boundingBox.height());
    }

    virtual InlineFlowBox* createInlineFlowBox(); // Subclassed by SVG and Ruby

    virtual void dirtyLinesFromChangedChild(RenderObject* child) OVERRIDE FINAL { m_lineBoxes.dirtyLinesFromChangedChild(this, child); }

    virtual LayoutUnit lineHeight(bool firstLine, LineDirectionMode, LinePositionMode = PositionOnContainingLine) const OVERRIDE FINAL;
    virtual int baselinePosition(FontBaseline, bool firstLine, LineDirectionMode, LinePositionMode = PositionOnContainingLine) const OVERRIDE FINAL;

    virtual void childBecameNonInline(RenderObject* child) OVERRIDE FINAL;

    virtual void updateHitTestResult(HitTestResult&, const LayoutPoint&) OVERRIDE FINAL;

    virtual void imageChanged(WrappedImagePtr, const IntRect* = 0) OVERRIDE FINAL;

    virtual void updateFromStyle() OVERRIDE FINAL;

    RenderInline* clone() const;

    void paintOutlineForLine(GraphicsContext*, const LayoutPoint&, const LayoutRect& prevLine, const LayoutRect& thisLine,
                             const LayoutRect& nextLine, const Color);
    RenderBoxModelObject* continuationBefore(RenderObject* beforeChild);

    RenderObjectChildList m_children;
    RenderLineBoxList m_lineBoxes;   // All of the line boxes created for this inline flow.  For example, <i>Hello<br>world.</i> will have two <i> line boxes.
};

DEFINE_RENDER_OBJECT_TYPE_CASTS(RenderInline, isRenderInline());

} // namespace blink

#endif // RenderInline_h
