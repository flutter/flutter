/*
 * Copyright (C) 2003, 2004, 2005, 2006, 2007 Apple Inc. All rights reserved.
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

#ifndef SKY_ENGINE_CORE_RENDERING_INLINEFLOWBOX_H_
#define SKY_ENGINE_CORE_RENDERING_INLINEFLOWBOX_H_

#include "flutter/sky/engine/core/rendering/InlineBox.h"
#include "flutter/sky/engine/core/rendering/RenderObjectInlines.h"
#include "flutter/sky/engine/core/rendering/RenderOverflow.h"
#include "flutter/sky/engine/core/rendering/style/ShadowData.h"

namespace blink {

class HitTestRequest;
class HitTestResult;
class InlineTextBox;
class RenderLineBoxList;
class SimpleFontData;
class VerticalPositionCache;

struct GlyphOverflow;

typedef HashMap<const InlineTextBox*, pair<Vector<const SimpleFontData*>, GlyphOverflow> > GlyphOverflowAndFallbackFontsMap;

class InlineFlowBox : public InlineBox {
public:
    InlineFlowBox(RenderObject& obj)
        : InlineBox(obj)
        , m_firstChild(0)
        , m_lastChild(0)
        , m_prevLineBox(0)
        , m_nextLineBox(0)
        , m_includeLogicalLeftEdge(false)
        , m_includeLogicalRightEdge(false)
        , m_descendantsHaveSameLineHeightAndBaseline(true)
        , m_baselineType(AlphabeticBaseline)
        , m_hasAnnotationsBefore(false)
        , m_hasAnnotationsAfter(false)
        , m_lineBreakBidiStatusEor(WTF::Unicode::LeftToRight)
        , m_lineBreakBidiStatusLastStrong(WTF::Unicode::LeftToRight)
        , m_lineBreakBidiStatusLast(WTF::Unicode::LeftToRight)
#if ENABLE(ASSERT)
        , m_hasBadChildList(false)
#endif
    {
        // Internet Explorer and Firefox always create a marker for list items, even when the list-style-type is none.  We do not make a marker
        // in the list-style-type: none case, since it is wasteful to do so.  However, in order to match other browsers we have to pretend like
        // an invisible marker exists.  The side effect of having an invisible marker is that the quirks mode behavior of shrinking lines with no
        // text children must not apply.  This change also means that gaps will exist between image bullet list items.  Even when the list bullet
        // is an image, the line is still considered to be immune from the quirk.
        m_hasTextChildren = false;
        m_hasTextDescendants = m_hasTextChildren;
    }

#if ENABLE(ASSERT)
    virtual ~InlineFlowBox();
#endif

#ifndef NDEBUG
    virtual void showLineTreeAndMark(const InlineBox* = 0, const char* = 0, const InlineBox* = 0, const char* = 0, const RenderObject* = 0, int = 0) const override;
    virtual const char* boxName() const override;
#endif

    InlineFlowBox* prevLineBox() const { return m_prevLineBox; }
    InlineFlowBox* nextLineBox() const { return m_nextLineBox; }
    void setNextLineBox(InlineFlowBox* n) { m_nextLineBox = n; }
    void setPreviousLineBox(InlineFlowBox* p) { m_prevLineBox = p; }

    InlineBox* firstChild() const { checkConsistency(); return m_firstChild; }
    InlineBox* lastChild() const { checkConsistency(); return m_lastChild; }

    virtual bool isLeaf() const override final { return false; }

    InlineBox* firstLeafChild() const;
    InlineBox* lastLeafChild() const;

    typedef void (*CustomInlineBoxRangeReverse)(void* userData, Vector<InlineBox*>::iterator first, Vector<InlineBox*>::iterator last);
    void collectLeafBoxesInLogicalOrder(Vector<InlineBox*>&, CustomInlineBoxRangeReverse customReverseImplementation = 0, void* userData = 0) const;

    virtual void setConstructed() override final
    {
        InlineBox::setConstructed();
        for (InlineBox* child = firstChild(); child; child = child->nextOnLine())
            child->setConstructed();
    }

    void addToLine(InlineBox* child);
    virtual void deleteLine() override final;
    virtual void extractLine() override final;
    virtual void attachLine() override final;
    virtual void adjustPosition(float dx, float dy) override;

    virtual void extractLineBoxFromRenderObject();
    virtual void attachLineBoxToRenderObject();
    virtual void removeLineBoxFromRenderObject();

    virtual void clearTruncation() override;

    IntRect roundedFrameRect() const;

    virtual void paint(PaintInfo&, const LayoutPoint&, LayoutUnit lineTop, LayoutUnit lineBottom, Vector<RenderBox*>& layers) override;
    virtual bool nodeAtPoint(const HitTestRequest&, HitTestResult&, const HitTestLocation& locationInContainer, const LayoutPoint& accumulatedOffset, LayoutUnit lineTop, LayoutUnit lineBottom) override;

    bool boxShadowCanBeAppliedToBackground(const FillLayer&) const;

    virtual RenderLineBoxList* rendererLineBoxes() const;

    // logicalLeft = left in a horizontal line and top in a vertical line.
    LayoutUnit marginBorderPaddingLogicalLeft() const { return marginLogicalLeft() + borderLogicalLeft() + paddingLogicalLeft(); }
    LayoutUnit marginBorderPaddingLogicalRight() const { return marginLogicalRight() + borderLogicalRight() + paddingLogicalRight(); }
    LayoutUnit marginLogicalLeft() const
    {
        if (!includeLogicalLeftEdge())
            return 0;
        return boxModelObject()->marginLeft();
    }
    LayoutUnit marginLogicalRight() const
    {
        if (!includeLogicalRightEdge())
            return 0;
        return boxModelObject()->marginRight();
    }
    int borderLogicalLeft() const
    {
        if (!includeLogicalLeftEdge())
            return 0;
        return renderer().style(isFirstLineStyle())->borderLeftWidth();
    }
    int borderLogicalRight() const
    {
        if (!includeLogicalRightEdge())
            return 0;
        return renderer().style(isFirstLineStyle())->borderRightWidth();
    }
    int paddingLogicalLeft() const
    {
        if (!includeLogicalLeftEdge())
            return 0;
        return boxModelObject()->paddingLeft();
    }
    int paddingLogicalRight() const
    {
        if (!includeLogicalRightEdge())
            return 0;
        return boxModelObject()->paddingRight();
    }

    bool includeLogicalLeftEdge() const { return m_includeLogicalLeftEdge; }
    bool includeLogicalRightEdge() const { return m_includeLogicalRightEdge; }
    void setEdges(bool includeLeft, bool includeRight)
    {
        m_includeLogicalLeftEdge = includeLeft;
        m_includeLogicalRightEdge = includeRight;
    }

    // Helper functions used during line construction and placement.
    void determineSpacingForFlowBoxes(bool lastLine, bool isLogicallyLastRunWrapped, RenderObject* logicallyLastRunRenderer);
    LayoutUnit getFlowSpacingLogicalWidth();
    float placeBoxesInInlineDirection(float logicalLeft, bool& needsWordSpacing);
    float placeBoxRangeInInlineDirection(InlineBox* firstChild, InlineBox* lastChild,
        float& logicalLeft, float& minLogicalLeft, float& maxLogicalRight, bool& needsWordSpacing);
    void beginPlacingBoxRangesInInlineDirection(float logicalLeft) { setLogicalLeft(logicalLeft); }
    void endPlacingBoxRangesInInlineDirection(float logicalLeft, float logicalRight, float minLogicalLeft, float maxLogicalRight)
    {
        setLogicalWidth(logicalRight - logicalLeft);
        if (knownToHaveNoOverflow() && (minLogicalLeft < logicalLeft || maxLogicalRight > logicalRight))
            clearKnownToHaveNoOverflow();
    }

    void computeLogicalBoxHeights(RootInlineBox*, LayoutUnit& maxPositionTop, LayoutUnit& maxPositionBottom,
                                  int& maxAscent, int& maxDescent, bool& setMaxAscent, bool& setMaxDescent,
                                  bool strictMode, GlyphOverflowAndFallbackFontsMap&, FontBaseline, VerticalPositionCache&);
    void adjustMaxAscentAndDescent(int& maxAscent, int& maxDescent,
                                   int maxPositionTop, int maxPositionBottom);
    void placeBoxesInBlockDirection(LayoutUnit logicalTop, LayoutUnit maxHeight, int maxAscent, bool strictMode, LayoutUnit& lineTop, LayoutUnit& lineBottom, LayoutUnit& selectionBottom, bool& setLineTop,
                                    LayoutUnit& lineTopIncludingMargins, LayoutUnit& lineBottomIncludingMargins, bool& hasAnnotationsBefore, bool& hasAnnotationsAfter, FontBaseline);
    void flipLinesInBlockDirection(LayoutUnit lineTop, LayoutUnit lineBottom);

    LayoutUnit computeOverAnnotationAdjustment(LayoutUnit allowedPosition) const;
    LayoutUnit computeUnderAnnotationAdjustment(LayoutUnit allowedPosition) const;

    void computeOverflow(LayoutUnit lineTop, LayoutUnit lineBottom, GlyphOverflowAndFallbackFontsMap&);

    void removeChild(InlineBox* child, MarkLineBoxes);

    virtual RenderObject::SelectionState selectionState() override;

    bool hasTextChildren() const { return m_hasTextChildren; }
    bool hasTextDescendants() const { return m_hasTextDescendants; }
    void setHasTextChildren() { m_hasTextChildren = true; setHasTextDescendants(); }
    void setHasTextDescendants() { m_hasTextDescendants = true; }

    void checkConsistency() const;
    void setHasBadChildList();

    // Line visual and layout overflow are in the coordinate space of the block.  This means that they aren't purely physical directions.
    // For horizontal-tb and vertical-lr they will match physical directions, but for horizontal-bt and vertical-rl, the top/bottom and left/right
    // respectively are flipped when compared to their physical counterparts.  For example minX is on the left in vertical-lr, but it is on the right in vertical-rl.
    LayoutRect layoutOverflowRect(LayoutUnit lineTop, LayoutUnit lineBottom) const
    {
        return m_overflow ? m_overflow->layoutOverflowRect() : enclosingLayoutRect(frameRectIncludingLineHeight(lineTop, lineBottom));
    }
    LayoutUnit logicalLefxlayoutOverflow() const
    {
        return m_overflow ? m_overflow->layoutOverflowRect().x() : static_cast<LayoutUnit>(logicalLeft());
    }
    LayoutUnit logicalRightLayoutOverflow() const
    {
        return m_overflow ? m_overflow->layoutOverflowRect().maxX() : static_cast<LayoutUnit>(ceilf(logicalRight()));
    }
    LayoutUnit logicalTopLayoutOverflow(LayoutUnit lineTop) const
    {
        if (m_overflow)
            return m_overflow->layoutOverflowRect().y();
        return lineTop;
    }
    LayoutUnit logicalBottomLayoutOverflow(LayoutUnit lineBottom) const
    {
        if (m_overflow)
            return m_overflow->layoutOverflowRect().maxY();
        return lineBottom;
    }
    LayoutRect logicalLayoutOverflowRect(LayoutUnit lineTop, LayoutUnit lineBottom) const
    {
        // FIXME(sky): Remove
        return layoutOverflowRect(lineTop, lineBottom);
    }

    LayoutRect visualOverflowRect(LayoutUnit lineTop, LayoutUnit lineBottom) const
    {
        return m_overflow ? m_overflow->visualOverflowRect() : enclosingLayoutRect(frameRectIncludingLineHeight(lineTop, lineBottom));
    }
    LayoutUnit logicalLeftVisualOverflow() const { return m_overflow ? m_overflow->visualOverflowRect().x() : static_cast<LayoutUnit>(logicalLeft()); }
    LayoutUnit logicalRightVisualOverflow() const { return m_overflow ? m_overflow->visualOverflowRect().maxX() : static_cast<LayoutUnit>(ceilf(logicalRight())); }
    LayoutUnit logicalTopVisualOverflow(LayoutUnit lineTop) const
    {
        if (m_overflow)
            return m_overflow->visualOverflowRect().y();
        return lineTop;
    }
    LayoutUnit logicalBottomVisualOverflow(LayoutUnit lineBottom) const
    {
        if (m_overflow)
            return m_overflow->visualOverflowRect().maxY();
        return lineBottom;
    }
    LayoutRect logicalVisualOverflowRect(LayoutUnit lineTop, LayoutUnit lineBottom) const
    {
        return visualOverflowRect(lineTop, lineBottom);
    }

    void setOverflowFromLogicalRects(const LayoutRect& logicalLayoutOverflow, const LayoutRect& logicalVisualOverflow, LayoutUnit lineTop, LayoutUnit lineBottom);

    FloatRect frameRectIncludingLineHeight(LayoutUnit lineTop, LayoutUnit lineBottom) const
    {
        return FloatRect(m_topLeft.x(), lineTop.toFloat(), width(), (lineBottom - lineTop).toFloat());
    }

    FloatRect logicalFrameRectIncludingLineHeight(LayoutUnit lineTop, LayoutUnit lineBottom) const
    {
        return FloatRect(logicalLeft(), lineTop.toFloat(), logicalWidth(), (lineBottom - lineTop).toFloat());
    }

    bool descendantsHaveSameLineHeightAndBaseline() const { return m_descendantsHaveSameLineHeightAndBaseline; }
    void clearDescendantsHaveSameLineHeightAndBaseline()
    {
        m_descendantsHaveSameLineHeightAndBaseline = false;
        if (parent() && parent()->descendantsHaveSameLineHeightAndBaseline())
            parent()->clearDescendantsHaveSameLineHeightAndBaseline();
    }

private:
    void paintBoxDecorationBackground(PaintInfo&, const LayoutPoint&);
    void paintFillLayers(const PaintInfo&, const Color&, const FillLayer&, const LayoutRect&);
    void paintFillLayer(const PaintInfo&, const Color&, const FillLayer&, const LayoutRect&);
    void paintBoxShadow(const PaintInfo&, RenderStyle*, ShadowStyle, const LayoutRect&);

    void addBoxShadowVisualOverflow(LayoutRect& logicalVisualOverflow);
    void addBorderOutsetVisualOverflow(LayoutRect& logicalVisualOverflow);
    void addOutlineVisualOverflow(LayoutRect& logicalVisualOverflow);
    void addTextBoxVisualOverflow(InlineTextBox*, GlyphOverflowAndFallbackFontsMap&, LayoutRect& logicalVisualOverflow);
    void addReplacedChildOverflow(const InlineBox*, LayoutRect& logicalLayoutOverflow, LayoutRect& logicalVisualOverflow);

    void setLayoutOverflow(const LayoutRect&, const LayoutRect&);
    void setVisualOverflow(const LayoutRect&, const LayoutRect&);

protected:
    OwnPtr<RenderOverflow> m_overflow;

    virtual bool isInlineFlowBox() const override final { return true; }

    InlineBox* m_firstChild;
    InlineBox* m_lastChild;

    InlineFlowBox* m_prevLineBox; // The previous box that also uses our RenderObject
    InlineFlowBox* m_nextLineBox; // The next box that also uses our RenderObject

    // Maximum logicalTop among all children of an InlineFlowBox. Used to
    // calculate the offset for TextUnderlinePositionUnder.
    void computeMaxLogicalTop(float& maxLogicalTop) const;

private:
    unsigned m_includeLogicalLeftEdge : 1;
    unsigned m_includeLogicalRightEdge : 1;
    unsigned m_hasTextChildren : 1;
    unsigned m_hasTextDescendants : 1;
    unsigned m_descendantsHaveSameLineHeightAndBaseline : 1;

protected:
    // The following members are only used by RootInlineBox but moved here to keep the bits packed.

    // Whether or not this line uses alphabetic or ideographic baselines by default.
    unsigned m_baselineType : 1; // FontBaseline

    // If the line contains any ruby runs, then this will be true.
    unsigned m_hasAnnotationsBefore : 1;
    unsigned m_hasAnnotationsAfter : 1;

    unsigned m_lineBreakBidiStatusEor : 5; // WTF::Unicode::Direction
    unsigned m_lineBreakBidiStatusLastStrong : 5; // WTF::Unicode::Direction
    unsigned m_lineBreakBidiStatusLast : 5; // WTF::Unicode::Direction

    // End of RootInlineBox-specific members.

#if ENABLE(ASSERT)
private:
    unsigned m_hasBadChildList : 1;
#endif
};

DEFINE_INLINE_BOX_TYPE_CASTS(InlineFlowBox);

#if !ENABLE(ASSERT)
inline void InlineFlowBox::checkConsistency() const
{
}
#endif

inline void InlineFlowBox::setHasBadChildList()
{
#if ENABLE(ASSERT)
    m_hasBadChildList = true;
#endif
}

} // namespace blink

#ifndef NDEBUG
// Outside the WebCore namespace for ease of invocation from gdb.
void showTree(const blink::InlineFlowBox*);
#endif

#endif  // SKY_ENGINE_CORE_RENDERING_INLINEFLOWBOX_H_
