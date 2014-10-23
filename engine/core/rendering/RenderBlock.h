/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2007 David Smith (catfish.man@gmail.com)
 * Copyright (C) 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010 Apple Inc. All rights reserved.
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

#ifndef RenderBlock_h
#define RenderBlock_h

#include "core/rendering/FloatingObjects.h"
#include "core/rendering/GapRects.h"
#include "core/rendering/RenderBox.h"
#include "core/rendering/RenderLineBoxList.h"
#include "core/rendering/RootInlineBox.h"
#include "core/rendering/style/ShapeValue.h"
#include "platform/text/TextBreakIterator.h"
#include "platform/text/TextRun.h"
#include "wtf/ListHashSet.h"
#include "wtf/OwnPtr.h"

namespace blink {

class LineInfo;
class LineLayoutState;
struct PaintInfo;
class RenderInline;
class RenderText;
class WordMeasurement;

template <class Run> class BidiRunList;
typedef WTF::ListHashSet<RenderBox*, 16> TrackedRendererListHashSet;
typedef WTF::HashMap<const RenderBlock*, OwnPtr<TrackedRendererListHashSet> > TrackedDescendantsMap;
typedef WTF::HashMap<const RenderBox*, OwnPtr<HashSet<RenderBlock*> > > TrackedContainerMap;
typedef Vector<WordMeasurement, 64> WordMeasurements;

enum ContainingBlockState { NewContainingBlock, SameContainingBlock };

class RenderBlock : public RenderBox {
public:
    virtual void destroy() OVERRIDE;
    virtual void trace(Visitor*) OVERRIDE;
    friend class LineLayoutState;

protected:
    explicit RenderBlock(ContainerNode*);
    virtual ~RenderBlock();

public:
    RenderObject* firstChild() const { ASSERT(children() == virtualChildren()); return children()->firstChild(); }
    RenderObject* lastChild() const { ASSERT(children() == virtualChildren()); return children()->lastChild(); }

    // If you have a RenderBlock, use firstChild or lastChild instead.
    void slowFirstChild() const WTF_DELETED_FUNCTION;
    void slowLastChild() const WTF_DELETED_FUNCTION;

    const RenderObjectChildList* children() const { return &m_children; }
    RenderObjectChildList* children() { return &m_children; }

    bool beingDestroyed() const { return m_beingDestroyed; }

    // These two functions are overridden for inline-block.
    virtual LayoutUnit lineHeight(bool firstLine, LineDirectionMode, LinePositionMode = PositionOnContainingLine) const OVERRIDE FINAL;
    virtual int baselinePosition(FontBaseline, bool firstLine, LineDirectionMode, LinePositionMode = PositionOnContainingLine) const OVERRIDE;

    LayoutUnit minLineHeightForReplacedRenderer(bool isFirstLine, LayoutUnit replacedHeight) const;

protected:
    RenderLineBoxList* lineBoxes() { return &m_lineBoxes; }

    InlineFlowBox* firstLineBox() const { return m_lineBoxes.firstLineBox(); }
    InlineFlowBox* lastLineBox() const { return m_lineBoxes.lastLineBox(); }

    RootInlineBox* firstRootBox() const { return static_cast<RootInlineBox*>(firstLineBox()); }
    RootInlineBox* lastRootBox() const { return static_cast<RootInlineBox*>(lastLineBox()); }

public:
    // FIXME-BLOCKFLOW: Remove virtualizaion when all callers have moved to RenderBlockFlow
    virtual void deleteLineBoxTree();

    virtual void addChild(RenderObject* newChild, RenderObject* beforeChild = 0) OVERRIDE;
    virtual void removeChild(RenderObject*) OVERRIDE;

    virtual void layoutBlock(bool relayoutChildren);

    void insertPositionedObject(RenderBox*);
    static void removePositionedObject(RenderBox*);
    void removePositionedObjects(RenderBlock*, ContainingBlockState = SameContainingBlock);

    TrackedRendererListHashSet* positionedObjects() const;
    bool hasPositionedObjects() const
    {
        TrackedRendererListHashSet* objects = positionedObjects();
        return objects && !objects->isEmpty();
    }

    void addPercentHeightDescendant(RenderBox*);
    static void removePercentHeightDescendant(RenderBox*);
    static bool hasPercentHeightContainerMap();
    static bool hasPercentHeightDescendant(RenderBox*);
    static void clearPercentHeightDescendantsFrom(RenderBox*);
    static void removePercentHeightDescendantIfNeeded(RenderBox*);

    TrackedRendererListHashSet* percentHeightDescendants() const;
    bool hasPercentHeightDescendants() const
    {
        TrackedRendererListHashSet* descendants = percentHeightDescendants();
        return descendants && !descendants->isEmpty();
    }

    void setHasMarkupTruncation(bool b) { m_hasMarkupTruncation = b; }
    bool hasMarkupTruncation() const { return m_hasMarkupTruncation; }

    void setHasMarginBeforeQuirk(bool b) { m_hasMarginBeforeQuirk = b; }
    void setHasMarginAfterQuirk(bool b) { m_hasMarginAfterQuirk = b; }

    bool hasMarginBeforeQuirk() const { return m_hasMarginBeforeQuirk; }
    bool hasMarginAfterQuirk() const { return m_hasMarginAfterQuirk; }

    bool hasMarginBeforeQuirk(const RenderBox* child) const;
    bool hasMarginAfterQuirk(const RenderBox* child) const;

    void markPositionedObjectsForLayout();

    LayoutUnit textIndentOffset() const;

    virtual PositionWithAffinity positionForPoint(const LayoutPoint&) OVERRIDE;

    // Block flows subclass availableWidth to handle multi column layout (shrinking the width available to children when laying out.)
    virtual LayoutUnit availableLogicalWidth() const OVERRIDE FINAL;

    LayoutUnit blockDirectionOffset(const LayoutSize& offsetFromBlock) const;
    LayoutUnit inlineDirectionOffset(const LayoutSize& offsetFromBlock) const;

    virtual bool shouldPaintSelectionGaps() const OVERRIDE FINAL;
    GapRects selectionGapRectsForPaintInvalidation(const RenderLayerModelObject* paintInvalidationContainer);
    LayoutRect logicalLeftSelectionGap(RenderBlock* rootBlock, const LayoutPoint& rootBlockPhysicalPosition, const LayoutSize& offsetFromRootBlock,
                                       RenderObject* selObj, LayoutUnit logicalLeft, LayoutUnit logicalTop, LayoutUnit logicalHeight, const PaintInfo*);
    LayoutRect logicalRightSelectionGap(RenderBlock* rootBlock, const LayoutPoint& rootBlockPhysicalPosition, const LayoutSize& offsetFromRootBlock,
                                        RenderObject* selObj, LayoutUnit logicalRight, LayoutUnit logicalTop, LayoutUnit logicalHeight, const PaintInfo*);
    void getSelectionGapInfo(SelectionState, bool& leftGap, bool& rightGap);
    RenderBlock* blockBeforeWithinSelectionRoot(LayoutSize& offset) const;

    virtual void setSelectionState(SelectionState) OVERRIDE;

    LayoutRect logicalRectToPhysicalRect(const LayoutPoint& physicalPosition, const LayoutRect& logicalRect);

    // Helper methods for computing line counts and heights for line counts.
    RootInlineBox* lineAtIndex(int) const;
    int lineCount(const RootInlineBox* = 0, bool* = 0) const;
    int heightForLineCount(int);
    void clearTruncation();

    void addContinuationWithOutline(RenderInline*);
    bool paintsContinuationOutline(RenderInline*);

    virtual RenderBoxModelObject* virtualContinuation() const OVERRIDE FINAL { return continuation(); }
    bool isAnonymousBlockContinuation() const { return continuation() && isAnonymousBlock(); }
    RenderInline* inlineElementContinuation() const;
    RenderBlock* blockElementContinuation() const;

    using RenderBoxModelObject::continuation;
    using RenderBoxModelObject::setContinuation;

    static RenderBlock* createAnonymousWithParentRendererAndDisplay(const RenderObject*, EDisplay = BLOCK);
    RenderBlock* createAnonymousBlock(EDisplay display = BLOCK) const { return createAnonymousWithParentRendererAndDisplay(this, display); }

    virtual RenderBox* createAnonymousBoxWithSameTypeAs(const RenderObject* parent) const OVERRIDE;

    // Accessors for logical width/height and margins in the containing block's block-flow direction.
    LayoutUnit logicalWidthForChild(const RenderBox* child) const { return isHorizontalWritingMode() ? child->width() : child->height(); }
    LayoutUnit logicalHeightForChild(const RenderBox* child) const { return isHorizontalWritingMode() ? child->height() : child->width(); }
    LayoutSize logicalSizeForChild(const RenderBox* child) const { return isHorizontalWritingMode() ? child->size() : child->size().transposedSize(); }
    LayoutUnit logicalTopForChild(const RenderBox* child) const { return isHorizontalWritingMode() ? child->y() : child->x(); }
    LayoutUnit marginBeforeForChild(const RenderBoxModelObject* child) const { return child->marginBefore(style()); }
    LayoutUnit marginAfterForChild(const RenderBoxModelObject* child) const { return child->marginAfter(style()); }
    LayoutUnit marginStartForChild(const RenderBoxModelObject* child) const { return child->marginStart(style()); }
    LayoutUnit marginEndForChild(const RenderBoxModelObject* child) const { return child->marginEnd(style()); }
    void setMarginStartForChild(RenderBox* child, LayoutUnit value) const { child->setMarginStart(value, style()); }
    void setMarginEndForChild(RenderBox* child, LayoutUnit value) const { child->setMarginEnd(value, style()); }
    void setMarginBeforeForChild(RenderBox* child, LayoutUnit value) const { child->setMarginBefore(value, style()); }
    void setMarginAfterForChild(RenderBox* child, LayoutUnit value) const { child->setMarginAfter(value, style()); }
    LayoutUnit collapsedMarginBeforeForChild(const RenderBox* child) const;
    LayoutUnit collapsedMarginAfterForChild(const RenderBox* child) const;

    virtual bool nodeAtPoint(const HitTestRequest&, HitTestResult&, const HitTestLocation& locationInContainer, const LayoutPoint& accumulatedOffset, HitTestAction) OVERRIDE;

    virtual void scrollbarsChanged(bool /*horizontalScrollbarChanged*/, bool /*verticalScrollbarChanged*/) { }

    LayoutUnit availableLogicalWidthForContent() const { return max<LayoutUnit>(0, logicalRightOffsetForContent() - logicalLeftOffsetForContent()); }
    LayoutUnit logicalLeftOffsetForContent() const { return isHorizontalWritingMode() ? borderLeft() + paddingLeft() : borderTop() + paddingTop(); }
    LayoutUnit logicalRightOffsetForContent() const { return logicalLeftOffsetForContent() + availableLogicalWidth(); }
    LayoutUnit startOffsetForContent() const { return style()->isLeftToRightDirection() ? logicalLeftOffsetForContent() : logicalWidth() - logicalRightOffsetForContent(); }
    LayoutUnit endOffsetForContent() const { return !style()->isLeftToRightDirection() ? logicalLeftOffsetForContent() : logicalWidth() - logicalRightOffsetForContent(); }

#if ENABLE(ASSERT)
    void checkPositionedObjectsNeedLayout();
#endif
#ifndef NDEBUG
    void showLineTreeAndMark(const InlineBox* = 0, const char* = 0, const InlineBox* = 0, const char* = 0, const RenderObject* = 0) const;
#endif

    // inline-block elements paint all phases atomically. This function ensures that. Certain other elements
    // (grid items, flex items) require this behavior as well, and this function exists as a helper for them.
    // It is expected that the caller will call this function independent of the value of paintInfo.phase.
    static void paintAsInlineBlock(RenderObject*, PaintInfo&, const LayoutPoint&);

    bool recalcChildOverflowAfterStyleChange();
    bool recalcOverflowAfterStyleChange();

protected:
    virtual void willBeDestroyed() OVERRIDE;

    void dirtyForLayoutFromPercentageHeightDescendants(SubtreeLayoutScope&);

    virtual void layout() OVERRIDE;
    virtual bool updateImageLoadingPriorities() OVERRIDE FINAL;

    enum PositionedLayoutBehavior {
        DefaultLayout,
        LayoutOnlyFixedPositionedObjects,
        ForcedLayoutAfterContainingBlockMoved
    };

    void layoutPositionedObjects(bool relayoutChildren, PositionedLayoutBehavior = DefaultLayout);
    void markFixedPositionObjectForLayoutIfNeeded(RenderObject* child, SubtreeLayoutScope&);

    LayoutUnit marginIntrinsicLogicalWidthForChild(RenderBox* child) const;

    int beforeMarginInLineDirection(LineDirectionMode) const;

    virtual void paint(PaintInfo&, const LayoutPoint&) OVERRIDE;
    virtual void paintObject(PaintInfo&, const LayoutPoint&) OVERRIDE;
    virtual void paintChildren(PaintInfo&, const LayoutPoint&);
    void paintChild(RenderBox*, PaintInfo&, const LayoutPoint&);
    void paintChildAsInlineBlock(RenderBox*, PaintInfo&, const LayoutPoint&);

    virtual void adjustInlineDirectionLineBounds(unsigned /* expansionOpportunityCount */, float& /* logicalLeft */, float& /* logicalWidth */) const { }

    virtual void computeIntrinsicLogicalWidths(LayoutUnit& minLogicalWidth, LayoutUnit& maxLogicalWidth) const OVERRIDE;
    virtual void computePreferredLogicalWidths() OVERRIDE;

    virtual int firstLineBoxBaseline() const OVERRIDE;
    virtual int inlineBlockBaseline(LineDirectionMode) const OVERRIDE;
    int lastLineBoxBaseline(LineDirectionMode) const;

    virtual void updateHitTestResult(HitTestResult&, const LayoutPoint&) OVERRIDE;

    // Delay update scrollbar until finishDelayUpdateScrollInfo() will be
    // called. This function is used when a flexbox is laying out its
    // descendant. If multiple calls are made to startDelayUpdateScrollInfo(),
    // finishDelayUpdateScrollInfo() will do nothing until finishDelayUpdateScrollInfo()
    // is called the same number of times.
    static void startDelayUpdateScrollInfo();
    static void finishDelayUpdateScrollInfo();

    void updateScrollInfoAfterLayout();

    virtual void styleWillChange(StyleDifference, const RenderStyle& newStyle) OVERRIDE;
    virtual void styleDidChange(StyleDifference, const RenderStyle* oldStyle) OVERRIDE;

    virtual bool hasLineIfEmpty() const;

    bool simplifiedLayout();
    virtual void simplifiedNormalFlowLayout();

public:
    virtual void computeOverflow(LayoutUnit oldClientAfterEdge, bool = false);
protected:
    virtual void addOverflowFromChildren();
    void addOverflowFromPositionedObjects();
    void addOverflowFromBlockChildren();

    virtual void addFocusRingRects(Vector<IntRect>&, const LayoutPoint& additionalOffset, const RenderLayerModelObject* paintContainer = 0) const OVERRIDE;

    virtual void computeSelfHitTestRects(Vector<LayoutRect>&, const LayoutPoint& layerOffset) const OVERRIDE;

    void updateBlockChildDirtyBitsBeforeLayout(bool relayoutChildren, RenderBox*);

    virtual bool isInlineBlock() const OVERRIDE FINAL { return isInline() && isReplaced(); }

    virtual void invalidateTreeIfNeeded(const PaintInvalidationState&) OVERRIDE;

private:
    virtual RenderObjectChildList* virtualChildren() OVERRIDE FINAL { return children(); }
    virtual const RenderObjectChildList* virtualChildren() const OVERRIDE FINAL { return children(); }

    virtual const char* renderName() const OVERRIDE;

    virtual bool isRenderBlock() const OVERRIDE FINAL { return true; }

    void makeChildrenNonInline(RenderObject* insertionPoint = 0);
    virtual void removeLeftoverAnonymousBlock(RenderBlock* child);

    static void collapseAnonymousBlockChild(RenderBlock* parent, RenderBlock* child);

    virtual void dirtyLinesFromChangedChild(RenderObject* child) OVERRIDE FINAL { m_lineBoxes.dirtyLinesFromChangedChild(this, child); }

    void addChildToContinuation(RenderObject* newChild, RenderObject* beforeChild);
    virtual void addChildIgnoringContinuation(RenderObject* newChild, RenderObject* beforeChild) OVERRIDE;

    void addChildIgnoringAnonymousColumnBlocks(RenderObject* newChild, RenderObject* beforeChild = 0);

    virtual bool isSelfCollapsingBlock() const OVERRIDE;

    void insertIntoTrackedRendererMaps(RenderBox* descendant, TrackedDescendantsMap*&, TrackedContainerMap*&);
    static void removeFromTrackedRendererMaps(RenderBox* descendant, TrackedDescendantsMap*&, TrackedContainerMap*&);

    Node* nodeForHitTest() const;

    // FIXME-BLOCKFLOW: Remove virtualizaion when all callers have moved to RenderBlockFlow
    virtual void paintFloats(PaintInfo&, const LayoutPoint&, bool) { }
    void paintContents(PaintInfo&, const LayoutPoint&);
    void paintSelection(PaintInfo&, const LayoutPoint&);
    void paintCarets(PaintInfo&, const LayoutPoint&);

    bool hasCaret() const;

    virtual bool avoidsFloats() const OVERRIDE { return true; }

    bool hitTestContents(const HitTestRequest&, HitTestResult&, const HitTestLocation& locationInContainer, const LayoutPoint& accumulatedOffset, HitTestAction);
    // FIXME-BLOCKFLOW: Remove virtualizaion when all callers have moved to RenderBlockFlow
    virtual bool hitTestFloats(const HitTestRequest&, HitTestResult&, const HitTestLocation&, const LayoutPoint&) { return false; }

    virtual bool isPointInOverflowControl(HitTestResult&, const LayoutPoint& locationInContainer, const LayoutPoint& accumulatedOffset);

    void computeBlockPreferredLogicalWidths(LayoutUnit& minLogicalWidth, LayoutUnit& maxLogicalWidth) const;

    // Obtains the nearest enclosing block (including this block) that contributes a first-line style to our inline
    // children.
    virtual RenderBlock* firstLineBlock() const OVERRIDE;

    virtual LayoutRect rectWithOutlineForPaintInvalidation(const RenderLayerModelObject* paintInvalidationContainer, LayoutUnit outlineWidth, const PaintInvalidationState* = 0) const OVERRIDE FINAL;

    virtual RenderObject* hoverAncestor() const OVERRIDE FINAL;
    virtual void childBecameNonInline(RenderObject* child) OVERRIDE FINAL;

    virtual LayoutRect selectionRectForPaintInvalidation(const RenderLayerModelObject* paintInvalidationContainer, bool /*clipToVisibleContent*/) OVERRIDE FINAL
    {
        return selectionGapRectsForPaintInvalidation(paintInvalidationContainer);
    }
    bool isSelectionRoot() const;
    GapRects selectionGaps(RenderBlock* rootBlock, const LayoutPoint& rootBlockPhysicalPosition, const LayoutSize& offsetFromRootBlock,
                           LayoutUnit& lastLogicalTop, LayoutUnit& lastLogicalLeft, LayoutUnit& lastLogicalRight, const PaintInfo* = 0);
    GapRects blockSelectionGaps(RenderBlock* rootBlock, const LayoutPoint& rootBlockPhysicalPosition, const LayoutSize& offsetFromRootBlock,
                                LayoutUnit& lastLogicalTop, LayoutUnit& lastLogicalLeft, LayoutUnit& lastLogicalRight, const PaintInfo*);
    LayoutRect blockSelectionGap(RenderBlock* rootBlock, const LayoutPoint& rootBlockPhysicalPosition, const LayoutSize& offsetFromRootBlock,
                                 LayoutUnit lastLogicalTop, LayoutUnit lastLogicalLeft, LayoutUnit lastLogicalRight, LayoutUnit logicalBottom, const PaintInfo*);
    virtual LayoutUnit logicalLeftSelectionOffset(RenderBlock* rootBlock, LayoutUnit position);
    virtual LayoutUnit logicalRightSelectionOffset(RenderBlock* rootBlock, LayoutUnit position);

    // FIXME-BLOCKFLOW: Remove virtualizaion when all callers have moved to RenderBlockFlow
    virtual void clipOutFloatingObjects(RenderBlock*, const PaintInfo*, const LayoutPoint&, const LayoutSize&) { };

    virtual void absoluteRects(Vector<IntRect>&, const LayoutPoint& accumulatedOffset) const OVERRIDE;
    virtual void absoluteQuads(Vector<FloatQuad>&, bool* wasFixed) const OVERRIDE;

    void paintContinuationOutlines(PaintInfo&, const LayoutPoint&);

    virtual LayoutRect localCaretRect(InlineBox*, int caretOffset, LayoutUnit* extraWidthToEndOfLine = 0) OVERRIDE FINAL;

    void markLinesDirtyInBlockRange(LayoutUnit logicalTop, LayoutUnit logicalBottom, RootInlineBox* highest = 0);

    Position positionForBox(InlineBox*, bool start = true) const;
    PositionWithAffinity positionForPointWithInlineChildren(const LayoutPoint&);

    void splitBlocks(RenderBlock* fromBlock, RenderBlock* toBlock, RenderBlock* middleBlock,
                     RenderObject* beforeChild, RenderBoxModelObject* oldCont);
    RenderBlock* clone() const;
    RenderBlock* continuationBefore(RenderObject* beforeChild);

    // End helper functions and structs used by layoutBlockChildren.

    void removeFromGlobalMaps();
    bool widthAvailableToChildrenHasChanged();

protected:
    bool createsBlockFormattingContext() const;

    // Adjust from painting offsets to the local coords of this renderer
    void offsetForContents(LayoutPoint&) const;

    virtual bool updateLogicalWidthAndColumnWidth();

    virtual bool canCollapseAnonymousBlockChild() const { return true; }

protected:
    RenderObjectChildList m_children;
    RenderLineBoxList m_lineBoxes;   // All of the root line boxes created for this block flow.  For example, <div>Hello<br>world.</div> will have two total lines for the <div>.

    LayoutUnit m_pageLogicalOffset;

    unsigned m_hasMarginBeforeQuirk : 1; // Note these quirk values can't be put in RenderBlockRareData since they are set too frequently.
    unsigned m_hasMarginAfterQuirk : 1;
    unsigned m_beingDestroyed : 1;
    unsigned m_hasMarkupTruncation : 1;
    unsigned m_hasBorderOrPaddingLogicalWidthChanged : 1;
    mutable unsigned m_hasOnlySelfCollapsingChildren : 1;
    mutable unsigned m_descendantsWithFloatsMarkedForLayout : 1;

    // FIXME-BLOCKFLOW: Remove this when the line layout stuff has all moved out of RenderBlock
    friend class LineBreaker;

    // FIXME: This is temporary as we move code that accesses block flow
    // member variables out of RenderBlock and into RenderBlockFlow.
    friend class RenderBlockFlow;
};

DEFINE_RENDER_OBJECT_TYPE_CASTS(RenderBlock, isRenderBlock());

} // namespace blink

#endif // RenderBlock_h
