/*
 * Copyright (C) 2003, 2006, 2007, 2008 Apple Inc. All rights reserved.
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

#ifndef RootInlineBox_h
#define RootInlineBox_h

#include "core/rendering/InlineFlowBox.h"
#include "platform/text/BidiContext.h"

namespace blink {

class EllipsisBox;
class HitTestResult;
class RenderBlockFlow;

struct BidiStatus;
struct GapRects;

class RootInlineBox : public InlineFlowBox {
public:
    explicit RootInlineBox(RenderBlockFlow&);

    virtual void destroy() override final;

    virtual bool isRootInlineBox() const override final { return true; }

    void detachEllipsisBox();

    RootInlineBox* nextRootBox() const { return static_cast<RootInlineBox*>(m_nextLineBox); }
    RootInlineBox* prevRootBox() const { return static_cast<RootInlineBox*>(m_prevLineBox); }

    virtual void adjustPosition(float dx, float dy) override final;

    LayoutUnit lineTop() const { return m_lineTop; }
    LayoutUnit lineBottom() const { return m_lineBottom; }

    LayoutUnit lineTopWithLeading() const { return m_lineTopWithLeading; }
    LayoutUnit lineBottomWithLeading() const { return m_lineBottomWithLeading; }

    bool isFirstAfterPageBreak() const { return m_fragmentationData ? m_fragmentationData->m_isFirstAfterPageBreak : false; }
    void setIsFirstAfterPageBreak(bool isFirstAfterPageBreak) { ensureLineFragmentationData()->m_isFirstAfterPageBreak = isFirstAfterPageBreak; }

    LayoutUnit paginatedLineWidth() const { return m_fragmentationData ? m_fragmentationData->m_paginatedLineWidth : LayoutUnit(0); }
    void setPaginatedLineWidth(LayoutUnit width) { ensureLineFragmentationData()->m_paginatedLineWidth = width; }

    LayoutUnit selectionTop() const;
    LayoutUnit selectionBottom() const;
    LayoutUnit selectionHeight() const { return max<LayoutUnit>(0, selectionBottom() - selectionTop()); }

    LayoutUnit selectionTopAdjustedForPrecedingBlock() const;
    LayoutUnit selectionHeightAdjustedForPrecedingBlock() const { return max<LayoutUnit>(0, selectionBottom() - selectionTopAdjustedForPrecedingBlock()); }

    int blockDirectionPointInLine() const;

    LayoutUnit alignBoxesInBlockDirection(LayoutUnit heightOfBlock, GlyphOverflowAndFallbackFontsMap&, VerticalPositionCache&);
    void setLineTopBottomPositions(LayoutUnit top, LayoutUnit bottom, LayoutUnit topWithLeading, LayoutUnit bottomWithLeading, LayoutUnit selectionBottom = LayoutUnit::min())
    {
        m_lineTop = top;
        m_lineBottom = bottom;
        m_lineTopWithLeading = topWithLeading;
        m_lineBottomWithLeading = bottomWithLeading;
        m_selectionBottom = selectionBottom == LayoutUnit::min() ? bottom : selectionBottom;
    }

    virtual RenderLineBoxList* rendererLineBoxes() const override final;

    RenderObject* lineBreakObj() const { return m_lineBreakObj; }
    BidiStatus lineBreakBidiStatus() const;
    void setLineBreakInfo(RenderObject*, unsigned breakPos, const BidiStatus&);

    unsigned lineBreakPos() const { return m_lineBreakPos; }
    void setLineBreakPos(unsigned p) { m_lineBreakPos = p; }

    using InlineBox::endsWithBreak;
    using InlineBox::setEndsWithBreak;

    void childRemoved(InlineBox* box);

    bool lineCanAccommodateEllipsis(bool ltr, int blockEdge, int lineBoxEdge, int ellipsisWidth);
    // Return the truncatedWidth, the width of the truncated text + ellipsis.
    float placeEllipsis(const AtomicString& ellipsisStr, bool ltr, float blockLeftEdge, float blockRightEdge, float ellipsisWidth, InlineBox* markupBox = 0);
    // Return the position of the EllipsisBox or -1.
    virtual float placeEllipsisBox(bool ltr, float blockLeftEdge, float blockRightEdge, float ellipsisWidth, float &truncatedWidth, bool& foundBox) override final;

    using InlineBox::hasEllipsisBox;
    EllipsisBox* ellipsisBox() const;

    void paintEllipsisBox(PaintInfo&, const LayoutPoint&, LayoutUnit lineTop, LayoutUnit lineBottom) const;

    virtual void clearTruncation() override final;

    virtual int baselinePosition(FontBaseline baselineType) const override final;
    virtual LayoutUnit lineHeight() const override final;

    virtual void paint(PaintInfo&, const LayoutPoint&, LayoutUnit lineTop, LayoutUnit lineBottom) override;
    virtual bool nodeAtPoint(const HitTestRequest&, HitTestResult&, const HitTestLocation& locationInContainer, const LayoutPoint& accumulatedOffset, LayoutUnit lineTop, LayoutUnit lineBottom) override final;

    using InlineBox::hasSelectedChildren;
    using InlineBox::setHasSelectedChildren;

    virtual RenderObject::SelectionState selectionState() override final;
    InlineBox* firstSelectedBox();
    InlineBox* lastSelectedBox();

    GapRects lineSelectionGap(RenderBlock* rootBlock, const LayoutPoint& rootBlockPhysicalPosition, const LayoutSize& offsetFromRootBlock, LayoutUnit selTop, LayoutUnit selHeight, const PaintInfo*);

    RenderBlockFlow& block() const;

    InlineBox* closestLeafChildForPoint(const IntPoint&, bool onlyEditableLeaves);
    InlineBox* closestLeafChildForLogicalLeftPosition(int, bool onlyEditableLeaves = false);

    void appendFloat(RenderBox* floatingBox)
    {
        ASSERT(!isDirty());
        if (m_floats)
            m_floats->append(floatingBox);
        else
            m_floats= adoptPtr(new Vector<RenderBox*>(1, floatingBox));
    }

    Vector<RenderBox*>* floatsPtr() { ASSERT(!isDirty()); return m_floats.get(); }

    virtual void extractLineBoxFromRenderObject() override final;
    virtual void attachLineBoxToRenderObject() override final;
    virtual void removeLineBoxFromRenderObject() override final;

    FontBaseline baselineType() const { return static_cast<FontBaseline>(m_baselineType); }

    bool hasAnnotationsBefore() const { return m_hasAnnotationsBefore; }
    bool hasAnnotationsAfter() const { return m_hasAnnotationsAfter; }

    LayoutRect paddedLayoutOverflowRect(LayoutUnit endPadding) const;

    void ascentAndDescentForBox(InlineBox*, GlyphOverflowAndFallbackFontsMap&, int& ascent, int& descent, bool& affectsAscent, bool& affectsDescent) const;
    LayoutUnit verticalPositionForBox(InlineBox*, VerticalPositionCache&);
    bool includeLeadingForBox(InlineBox*) const;
    bool includeFontForBox(InlineBox*) const;
    bool includeGlyphsForBox(InlineBox*) const;
    bool includeMarginForBox(InlineBox*) const;
    bool fitsToGlyphs() const;
    bool includesRootLineBoxFontOrLeading() const;

    LayoutUnit logicalTopVisualOverflow() const
    {
        return InlineFlowBox::logicalTopVisualOverflow(lineTop());
    }
    LayoutUnit logicalBottomVisualOverflow() const
    {
        return InlineFlowBox::logicalBottomVisualOverflow(lineBottom());
    }
    LayoutUnit logicalTopLayoutOverflow() const
    {
        return InlineFlowBox::logicalTopLayoutOverflow(lineTop());
    }
    LayoutUnit logicalBottomLayoutOverflow() const
    {
        return InlineFlowBox::logicalBottomLayoutOverflow(lineBottom());
    }

    // Used to calculate the underline offset for TextUnderlinePositionUnder.
    float maxLogicalTop() const;

    Node* getLogicalStartBoxWithNode(InlineBox*&) const;
    Node* getLogicalEndBoxWithNode(InlineBox*&) const;

#ifndef NDEBUG
    virtual const char* boxName() const override;
#endif
private:
    LayoutUnit beforeAnnotationsAdjustment() const;

    struct LineFragmentationData;
    LineFragmentationData* ensureLineFragmentationData()
    {
        if (!m_fragmentationData)
            m_fragmentationData = adoptPtr(new LineFragmentationData());

        return m_fragmentationData.get();
    }

    // This folds into the padding at the end of InlineFlowBox on 64-bit.
    unsigned m_lineBreakPos;

    // Where this line ended.  The exact object and the position within that object are stored so that
    // we can create an InlineIterator beginning just after the end of this line.
    RenderObject* m_lineBreakObj;
    RefPtr<BidiContext> m_lineBreakContext;

    struct LineFragmentationData {
        WTF_MAKE_NONCOPYABLE(LineFragmentationData); WTF_MAKE_FAST_ALLOCATED;
    public:
        LineFragmentationData()
            : m_paginatedLineWidth(0)
            , m_isFirstAfterPageBreak(false)
        {

        }

        LayoutUnit m_paginatedLineWidth;
        bool m_isFirstAfterPageBreak;
    };

    OwnPtr<LineFragmentationData> m_fragmentationData;

    // Floats hanging off the line are pushed into this vector during layout. It is only
    // good for as long as the line has not been marked dirty.
    OwnPtr<Vector<RenderBox*> > m_floats;

    LayoutUnit m_lineTop;
    LayoutUnit m_lineBottom;
    LayoutUnit m_lineTopWithLeading;
    LayoutUnit m_lineBottomWithLeading;
    LayoutUnit m_selectionBottom;
};

} // namespace blink

#endif // RootInlineBox_h
