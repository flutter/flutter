/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2007 David Smith (catfish.man@gmail.com)
 * Copyright (C) 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010 Apple Inc. All
 * rights reserved.
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

#ifndef SKY_ENGINE_CORE_RENDERING_RENDERBLOCK_H_
#define SKY_ENGINE_CORE_RENDERING_RENDERBLOCK_H_

#include "flutter/sky/engine/core/rendering/GapRects.h"
#include "flutter/sky/engine/core/rendering/RenderBox.h"
#include "flutter/sky/engine/core/rendering/RenderLineBoxList.h"
#include "flutter/sky/engine/core/rendering/RootInlineBox.h"
#include "flutter/sky/engine/core/rendering/style/ShapeValue.h"
#include "flutter/sky/engine/platform/text/TextBreakIterator.h"
#include "flutter/sky/engine/platform/text/TextRun.h"
#include "flutter/sky/engine/wtf/ListHashSet.h"
#include "flutter/sky/engine/wtf/OwnPtr.h"

namespace blink {

class LineInfo;
class LineLayoutState;
struct PaintInfo;
class RenderInline;
class RenderText;
class WordMeasurement;

template <class Run>
class BidiRunList;
typedef WTF::ListHashSet<RenderBox*, 16> TrackedRendererListHashSet;
typedef WTF::HashMap<const RenderBlock*, OwnPtr<TrackedRendererListHashSet>>
    TrackedDescendantsMap;
typedef WTF::HashMap<const RenderBox*, OwnPtr<HashSet<RenderBlock*>>>
    TrackedContainerMap;
typedef Vector<WordMeasurement, 64> WordMeasurements;

enum ContainingBlockState { NewContainingBlock, SameContainingBlock };

class RenderBlock : public RenderBox {
 public:
  virtual void destroy() override;
  friend class LineLayoutState;

 protected:
  explicit RenderBlock();
  virtual ~RenderBlock();

 public:
  RenderObject* firstChild() const {
    ASSERT(children() == virtualChildren());
    return children()->firstChild();
  }
  RenderObject* lastChild() const {
    ASSERT(children() == virtualChildren());
    return children()->lastChild();
  }

  // If you have a RenderBlock, use firstChild or lastChild instead.
  void slowFirstChild() const = delete;
  void slowLastChild() const = delete;

  const RenderObjectChildList* children() const { return &m_children; }
  RenderObjectChildList* children() { return &m_children; }

  bool beingDestroyed() const { return m_beingDestroyed; }

  // These two functions are overridden for inline-block.
  virtual LayoutUnit lineHeight(
      bool firstLine,
      LineDirectionMode,
      LinePositionMode = PositionOnContainingLine) const override final;
  virtual int baselinePosition(
      FontBaseline,
      bool firstLine,
      LineDirectionMode,
      LinePositionMode = PositionOnContainingLine) const override;

  LayoutUnit minLineHeightForReplacedRenderer(bool isFirstLine,
                                              LayoutUnit replacedHeight) const;

 protected:
  RenderLineBoxList* lineBoxes() { return &m_lineBoxes; }

  InlineFlowBox* firstLineBox() const { return m_lineBoxes.firstLineBox(); }
  InlineFlowBox* lastLineBox() const { return m_lineBoxes.lastLineBox(); }

  RootInlineBox* firstRootBox() const {
    return static_cast<RootInlineBox*>(firstLineBox());
  }
  RootInlineBox* lastRootBox() const {
    return static_cast<RootInlineBox*>(lastLineBox());
  }

 public:
  // FIXME-BLOCKFLOW: Remove virtualizaion when all callers have moved to
  // RenderParagraph
  virtual void deleteLineBoxTree();

  virtual void addChild(RenderObject* newChild,
                        RenderObject* beforeChild = 0) override;
  virtual void removeChild(RenderObject*) override;

  void insertPositionedObject(RenderBox*);
  static void removePositionedObject(RenderBox*);
  void removePositionedObjects(RenderBlock*,
                               ContainingBlockState = SameContainingBlock);

  TrackedRendererListHashSet* positionedObjects() const;
  bool hasPositionedObjects() const {
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
  bool hasPercentHeightDescendants() const {
    TrackedRendererListHashSet* descendants = percentHeightDescendants();
    return descendants && !descendants->isEmpty();
  }

  void setHasMarginBeforeQuirk(bool b) { m_hasMarginBeforeQuirk = b; }
  void setHasMarginAfterQuirk(bool b) { m_hasMarginAfterQuirk = b; }

  bool hasMarginBeforeQuirk() const { return m_hasMarginBeforeQuirk; }
  bool hasMarginAfterQuirk() const { return m_hasMarginAfterQuirk; }

  bool hasMarginBeforeQuirk(const RenderBox* child) const;
  bool hasMarginAfterQuirk(const RenderBox* child) const;

  void markPositionedObjectsForLayout();

  LayoutUnit textIndentOffset() const;

  virtual PositionWithAffinity positionForPoint(const LayoutPoint&) override;

  // Block flows subclass availableWidth to handle multi column layout
  // (shrinking the width available to children when laying out.)
  virtual LayoutUnit availableLogicalWidth() const override final;

  LayoutUnit blockDirectionOffset(const LayoutSize& offsetFromBlock) const;
  LayoutUnit inlineDirectionOffset(const LayoutSize& offsetFromBlock) const;

  virtual bool shouldPaintSelectionGaps() const override final;
  LayoutRect logicalLeftSelectionGap(
      RenderBlock* rootBlock,
      const LayoutPoint& rootBlockPhysicalPosition,
      const LayoutSize& offsetFromRootBlock,
      RenderObject* selObj,
      LayoutUnit logicalLeft,
      LayoutUnit logicalTop,
      LayoutUnit logicalHeight,
      const PaintInfo*);
  LayoutRect logicalRightSelectionGap(
      RenderBlock* rootBlock,
      const LayoutPoint& rootBlockPhysicalPosition,
      const LayoutSize& offsetFromRootBlock,
      RenderObject* selObj,
      LayoutUnit logicalRight,
      LayoutUnit logicalTop,
      LayoutUnit logicalHeight,
      const PaintInfo*);
  void getSelectionGapInfo(SelectionState, bool& leftGap, bool& rightGap);
  RenderBlock* blockBeforeWithinSelectionRoot(LayoutSize& offset) const;

  virtual void setSelectionState(SelectionState) override;

  LayoutRect logicalRectToPhysicalRect(const LayoutPoint& physicalPosition,
                                       const LayoutRect& logicalRect);

  // Helper methods for computing line counts and heights for line counts.
  virtual RootInlineBox* lineAtIndex(int) const;
  virtual int lineCount(const RootInlineBox* = 0, bool* = 0) const;
  void clearTruncation();

  // Accessors for logical width/height and margins in the containing block's
  // block-flow direction.
  LayoutUnit logicalWidthForChild(const RenderBox* child) const {
    return child->width();
  }
  LayoutUnit logicalHeightForChild(const RenderBox* child) const {
    return child->height();
  }
  LayoutSize logicalSizeForChild(const RenderBox* child) const {
    return child->size();
  }
  LayoutUnit logicalTopForChild(const RenderBox* child) const {
    return child->y();
  }
  LayoutUnit marginBeforeForChild(const RenderBoxModelObject* child) const {
    return child->marginBefore(style());
  }
  LayoutUnit marginAfterForChild(const RenderBoxModelObject* child) const {
    return child->marginAfter(style());
  }
  LayoutUnit marginStartForChild(const RenderBoxModelObject* child) const {
    return child->marginStart(style());
  }
  LayoutUnit marginEndForChild(const RenderBoxModelObject* child) const {
    return child->marginEnd(style());
  }
  void setMarginStartForChild(RenderBox* child, LayoutUnit value) const {
    child->setMarginStart(value, style());
  }
  void setMarginEndForChild(RenderBox* child, LayoutUnit value) const {
    child->setMarginEnd(value, style());
  }
  void setMarginBeforeForChild(RenderBox* child, LayoutUnit value) const {
    child->setMarginBefore(value, style());
  }
  void setMarginAfterForChild(RenderBox* child, LayoutUnit value) const {
    child->setMarginAfter(value, style());
  }
  LayoutUnit marginBeforeForChild(const RenderBox* child) const;
  LayoutUnit marginAfterForChild(const RenderBox* child) const;

  virtual bool nodeAtPoint(const HitTestRequest&,
                           HitTestResult&,
                           const HitTestLocation& locationInContainer,
                           const LayoutPoint& accumulatedOffset) override;

  LayoutUnit availableLogicalWidthForContent() const {
    return max<LayoutUnit>(
        0, logicalRightOffsetForContent() - logicalLeftOffsetForContent());
  }
  LayoutUnit logicalLeftOffsetForContent() const {
    return borderLeft() + paddingLeft();
  }
  LayoutUnit logicalRightOffsetForContent() const {
    return logicalLeftOffsetForContent() + availableLogicalWidth();
  }
  LayoutUnit startOffsetForContent() const {
    return style()->isLeftToRightDirection()
               ? logicalLeftOffsetForContent()
               : logicalWidth() - logicalRightOffsetForContent();
  }
  LayoutUnit endOffsetForContent() const {
    return !style()->isLeftToRightDirection()
               ? logicalLeftOffsetForContent()
               : logicalWidth() - logicalRightOffsetForContent();
  }

#if ENABLE(ASSERT)
  void checkPositionedObjectsNeedLayout();
#endif
#ifndef NDEBUG
  void showLineTreeAndMark(const InlineBox* = 0,
                           const char* = 0,
                           const InlineBox* = 0,
                           const char* = 0,
                           const RenderObject* = 0) const;
#endif

  bool recalcChildOverflowAfterStyleChange();
  bool recalcOverflowAfterStyleChange();

 protected:
  virtual void willBeDestroyed() override;

  void dirtyForLayoutFromPercentageHeightDescendants(SubtreeLayoutScope&);

  enum PositionedLayoutBehavior {
    DefaultLayout,
    ForcedLayoutAfterContainingBlockMoved
  };

  void layoutPositionedObjects(bool relayoutChildren,
                               PositionedLayoutBehavior = DefaultLayout);

  LayoutUnit marginIntrinsicLogicalWidthForChild(RenderBox* child) const;

  int beforeMarginInLineDirection(LineDirectionMode) const;

  virtual void paint(PaintInfo&,
                     const LayoutPoint&,
                     Vector<RenderBox*>& layers) override;
  void paintObject(PaintInfo&, const LayoutPoint&, Vector<RenderBox*>& layers);
  virtual void paintChildren(PaintInfo&,
                             const LayoutPoint&,
                             Vector<RenderBox*>& layers);

  virtual void adjustInlineDirectionLineBounds(
      unsigned /* expansionOpportunityCount */,
      float& /* logicalLeft */,
      float& /* logicalWidth */) const {}

  virtual void computeIntrinsicLogicalWidths(
      LayoutUnit& minLogicalWidth,
      LayoutUnit& maxLogicalWidth) const override;
  virtual void computePreferredLogicalWidths() override;

  virtual int firstLineBoxBaseline(
      FontBaselineOrAuto baselineType) const override;
  virtual int inlineBlockBaseline(LineDirectionMode) const override;
  virtual int lastLineBoxBaseline(LineDirectionMode) const;

  virtual void updateHitTestResult(HitTestResult&, const LayoutPoint&) override;

  virtual void styleWillChange(StyleDifference,
                               const RenderStyle& newStyle) override;
  virtual void styleDidChange(StyleDifference,
                              const RenderStyle* oldStyle) override;

  virtual bool hasLineIfEmpty() const;

  bool simplifiedLayout();
  virtual void simplifiedNormalFlowLayout();

 public:
  virtual void computeOverflow(LayoutUnit oldClientAfterEdge, bool = false);

 protected:
  virtual void addOverflowFromChildren();
  void addOverflowFromPositionedObjects();

  virtual void addFocusRingRects(
      Vector<IntRect>&,
      const LayoutPoint& additionalOffset,
      const RenderBox* paintContainer = 0) const override;

  void updateBlockChildDirtyBitsBeforeLayout(bool relayoutChildren, RenderBox*);

  virtual bool isInlineBlock() const override final {
    return isInline() && isReplaced();
  }

  virtual bool hitTestContents(const HitTestRequest&,
                               HitTestResult&,
                               const HitTestLocation& locationInContainer,
                               const LayoutPoint& accumulatedOffset);

 private:
  virtual RenderObjectChildList* virtualChildren() override final {
    return children();
  }
  virtual const RenderObjectChildList* virtualChildren() const override final {
    return children();
  }

  virtual const char* renderName() const override;

  virtual bool isRenderBlock() const override final { return true; }

  virtual void dirtyLinesFromChangedChild(RenderObject* child) override final {
    m_lineBoxes.dirtyLinesFromChangedChild(this, child);
  }

  void insertIntoTrackedRendererMaps(RenderBox* descendant,
                                     TrackedDescendantsMap*&,
                                     TrackedContainerMap*&);
  static void removeFromTrackedRendererMaps(RenderBox* descendant,
                                            TrackedDescendantsMap*&,
                                            TrackedContainerMap*&);

  void paintSelection(PaintInfo&, const LayoutPoint&);

  // Obtains the nearest enclosing block (including this block) that contributes
  // a first-line style to our inline children.
  virtual RenderBlock* firstLineBlock() const override;

  bool isSelectionRoot() const;
  GapRects selectionGaps(RenderBlock* rootBlock,
                         const LayoutPoint& rootBlockPhysicalPosition,
                         const LayoutSize& offsetFromRootBlock,
                         LayoutUnit& lastLogicalTop,
                         LayoutUnit& lastLogicalLeft,
                         LayoutUnit& lastLogicalRight,
                         const PaintInfo* = 0);
  GapRects blockSelectionGaps(RenderBlock* rootBlock,
                              const LayoutPoint& rootBlockPhysicalPosition,
                              const LayoutSize& offsetFromRootBlock,
                              LayoutUnit& lastLogicalTop,
                              LayoutUnit& lastLogicalLeft,
                              LayoutUnit& lastLogicalRight,
                              const PaintInfo*);
  LayoutRect blockSelectionGap(RenderBlock* rootBlock,
                               const LayoutPoint& rootBlockPhysicalPosition,
                               const LayoutSize& offsetFromRootBlock,
                               LayoutUnit lastLogicalTop,
                               LayoutUnit lastLogicalLeft,
                               LayoutUnit lastLogicalRight,
                               LayoutUnit logicalBottom,
                               const PaintInfo*);
  virtual LayoutUnit logicalLeftSelectionOffset(RenderBlock* rootBlock,
                                                LayoutUnit position);
  virtual LayoutUnit logicalRightSelectionOffset(RenderBlock* rootBlock,
                                                 LayoutUnit position);

  virtual void absoluteQuads(Vector<FloatQuad>&) const override;

  virtual LayoutRect localCaretRect(
      InlineBox*,
      int caretOffset,
      LayoutUnit* extraWidthToEndOfLine = 0) override final;

  PositionWithAffinity positionForPointWithInlineChildren(const LayoutPoint&);

  void removeFromGlobalMaps();
  bool widthAvailableToChildrenHasChanged();

 protected:
  bool updateLogicalWidthAndColumnWidth();

  RenderObjectChildList m_children;
  RenderLineBoxList m_lineBoxes;  // All of the root line boxes created for this
                                  // block flow.  For example,
                                  // <div>Hello<br>world.</div> will have two
                                  // total lines for the <div>.

  LayoutUnit m_pageLogicalOffset;

  unsigned m_hasMarginBeforeQuirk : 1;  // Note these quirk values can't be put
                                        // in RenderBlockRareData since they are
                                        // set too frequently.
  unsigned m_hasMarginAfterQuirk : 1;
  unsigned m_beingDestroyed : 1;
  unsigned m_hasBorderOrPaddingLogicalWidthChanged : 1;

  // FIXME-BLOCKFLOW: Remove this when the line layout stuff has all moved out
  // of RenderBlock
  friend class LineBreaker;

  // FIXME: This is temporary as we move code that accesses block flow
  // member variables out of RenderBlock and into RenderParagraph.
  friend class RenderParagraph;
};

DEFINE_RENDER_OBJECT_TYPE_CASTS(RenderBlock, isRenderBlock());

}  // namespace blink

#endif  // SKY_ENGINE_CORE_RENDERING_RENDERBLOCK_H_
