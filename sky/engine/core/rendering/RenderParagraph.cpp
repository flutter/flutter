// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/sky/engine/core/rendering/RenderParagraph.h"

#include "flutter/sky/engine/core/rendering/BidiRunForLine.h"
#include "flutter/sky/engine/core/rendering/InlineIterator.h"
#include "flutter/sky/engine/core/rendering/RenderLayer.h"
#include "flutter/sky/engine/core/rendering/RenderObjectInlines.h"
#include "flutter/sky/engine/core/rendering/RenderView.h"
#include "flutter/sky/engine/core/rendering/TextRunConstructor.h"
#include "flutter/sky/engine/core/rendering/VerticalPositionCache.h"
#include "flutter/sky/engine/core/rendering/line/BreakingContextInlineHeaders.h"
#include "flutter/sky/engine/core/rendering/line/LineLayoutState.h"
#include "flutter/sky/engine/core/rendering/line/LineWidth.h"
#include "flutter/sky/engine/core/rendering/line/RenderTextInfo.h"
#include "flutter/sky/engine/core/rendering/line/WordMeasurement.h"
#include "flutter/sky/engine/platform/fonts/Character.h"
#include "flutter/sky/engine/platform/text/BidiResolver.h"
#include "flutter/sky/engine/wtf/RefCountedLeakCounter.h"
#include "flutter/sky/engine/wtf/StdLibExtras.h"
#include "flutter/sky/engine/wtf/Vector.h"
#include "flutter/sky/engine/wtf/unicode/CharacterNames.h"

namespace blink {

using namespace WTF::Unicode;

RenderParagraph::RenderParagraph() : m_didExceedMaxLines(false) {}

RenderParagraph::~RenderParagraph() {}

const char* RenderParagraph::renderName() const {
  return "RenderParagraph";
}

LayoutUnit RenderParagraph::logicalLeftSelectionOffset(RenderBlock* rootBlock,
                                                       LayoutUnit position) {
  LayoutUnit logicalLeft = logicalLeftOffsetForLine(false);
  if (logicalLeft == logicalLeftOffsetForContent())
    return RenderBlock::logicalLeftSelectionOffset(rootBlock, position);

  RenderBlock* cb = this;
  while (cb != rootBlock) {
    logicalLeft += cb->logicalLeft();
    cb = cb->containingBlock();
  }
  return logicalLeft;
}

LayoutUnit RenderParagraph::logicalRightSelectionOffset(RenderBlock* rootBlock,
                                                        LayoutUnit position) {
  LayoutUnit logicalRight = logicalRightOffsetForLine(false);
  if (logicalRight == logicalRightOffsetForContent())
    return RenderBlock::logicalRightSelectionOffset(rootBlock, position);

  RenderBlock* cb = this;
  while (cb != rootBlock) {
    logicalRight += cb->logicalLeft();
    cb = cb->containingBlock();
  }
  return logicalRight;
}

RootInlineBox* RenderParagraph::lineAtIndex(int i) const {
  ASSERT(i >= 0);

  for (RootInlineBox* box = firstRootBox(); box; box = box->nextRootBox()) {
    if (!i--)
      return box;
  }

  return 0;
}

int RenderParagraph::lineCount(const RootInlineBox* stopRootInlineBox,
                               bool* found) const {
  int count = 0;
  for (RootInlineBox* box = firstRootBox(); box; box = box->nextRootBox()) {
    count++;
    if (box == stopRootInlineBox) {
      if (found)
        *found = true;
      break;
    }
  }

  return count;
}

void RenderParagraph::deleteLineBoxTree() {
  m_lineBoxes.deleteLineBoxTree();
}

GapRects RenderParagraph::inlineSelectionGaps(
    RenderBlock* rootBlock,
    const LayoutPoint& rootBlockPhysicalPosition,
    const LayoutSize& offsetFromRootBlock,
    LayoutUnit& lastLogicalTop,
    LayoutUnit& lastLogicalLeft,
    LayoutUnit& lastLogicalRight,
    const PaintInfo* paintInfo) {
  GapRects result;

  bool containsStart =
      selectionState() == SelectionStart || selectionState() == SelectionBoth;

  if (!firstLineBox()) {
    if (containsStart) {
      // Go ahead and update our lastLogicalTop to be the bottom of the block.
      // <hr>s or empty blocks with height can trip this case.
      lastLogicalTop = rootBlock->blockDirectionOffset(offsetFromRootBlock) +
                       logicalHeight();
      lastLogicalLeft = logicalLeftSelectionOffset(rootBlock, logicalHeight());
      lastLogicalRight =
          logicalRightSelectionOffset(rootBlock, logicalHeight());
    }
    return result;
  }

  RootInlineBox* lastSelectedLine = 0;
  RootInlineBox* curr;
  for (curr = firstRootBox(); curr && !curr->hasSelectedChildren();
       curr = curr->nextRootBox()) {
  }

  // Now paint the gaps for the lines.
  for (; curr && curr->hasSelectedChildren(); curr = curr->nextRootBox()) {
    LayoutUnit selTop = curr->selectionTopAdjustedForPrecedingBlock();
    LayoutUnit selHeight = curr->selectionHeightAdjustedForPrecedingBlock();

    if (!containsStart && !lastSelectedLine &&
        selectionState() != SelectionStart &&
        selectionState() != SelectionBoth) {
      result.uniteCenter(blockSelectionGap(rootBlock, rootBlockPhysicalPosition,
                                           offsetFromRootBlock, lastLogicalTop,
                                           lastLogicalLeft, lastLogicalRight,
                                           selTop, paintInfo));
    }

    LayoutRect logicalRect(curr->logicalLeft(), selTop, curr->logicalWidth(),
                           selTop + selHeight);
    logicalRect.move(offsetFromRootBlock);
    LayoutRect physicalRect = rootBlock->logicalRectToPhysicalRect(
        rootBlockPhysicalPosition, logicalRect);
    if (!paintInfo || (physicalRect.y() < paintInfo->rect.maxY() &&
                       physicalRect.maxY() > paintInfo->rect.y()))
      result.unite(curr->lineSelectionGap(rootBlock, rootBlockPhysicalPosition,
                                          offsetFromRootBlock, selTop,
                                          selHeight, paintInfo));

    lastSelectedLine = curr;
  }

  if (containsStart && !lastSelectedLine) {
    // VisibleSelection must start just after our last line.
    lastSelectedLine = lastRootBox();
  }

  if (lastSelectedLine && selectionState() != SelectionEnd &&
      selectionState() != SelectionBoth) {
    // Go ahead and update our lastY to be the bottom of the last selected line.
    lastLogicalTop = rootBlock->blockDirectionOffset(offsetFromRootBlock) +
                     lastSelectedLine->selectionBottom();
    lastLogicalLeft = logicalLeftSelectionOffset(
        rootBlock, lastSelectedLine->selectionBottom());
    lastLogicalRight = logicalRightSelectionOffset(
        rootBlock, lastSelectedLine->selectionBottom());
  }
  return result;
}

void RenderParagraph::addOverflowFromChildren() {
  LayoutUnit endPadding = hasOverflowClip() ? paddingEnd() : LayoutUnit();
  for (RootInlineBox* curr = firstRootBox(); curr; curr = curr->nextRootBox()) {
    addLayoutOverflow(curr->paddedLayoutOverflowRect(endPadding));
    LayoutRect visualOverflow =
        curr->visualOverflowRect(curr->lineTop(), curr->lineBottom());
    addContentsVisualOverflow(visualOverflow);
  }
}

void RenderParagraph::simplifiedNormalFlowLayout() {
  ListHashSet<RootInlineBox*> lineBoxes;
  for (InlineWalker walker(this); !walker.atEnd(); walker.advance()) {
    RenderObject* o = walker.current();
    if (!o->isOutOfFlowPositioned() && o->isReplaced()) {
      o->layoutIfNeeded();
      if (toRenderBox(o)->inlineBoxWrapper()) {
        RootInlineBox& box = toRenderBox(o)->inlineBoxWrapper()->root();
        lineBoxes.add(&box);
      }
    } else if (o->isText() ||
               (o->isRenderInline() && !walker.atEndOfInline())) {
      o->clearNeedsLayout();
    }
  }

  // FIXME: Glyph overflow will get lost in this case, but not really a big
  // deal.
  GlyphOverflowAndFallbackFontsMap textBoxDataMap;
  for (ListHashSet<RootInlineBox*>::const_iterator it = lineBoxes.begin();
       it != lineBoxes.end(); ++it) {
    RootInlineBox* box = *it;
    box->computeOverflow(box->lineTop(), box->lineBottom(), textBoxDataMap);
  }
}

void RenderParagraph::paintChildren(PaintInfo& paintInfo,
                                    const LayoutPoint& paintOffset,
                                    Vector<RenderBox*>& layers) {
  m_lineBoxes.paint(this, paintInfo, paintOffset, layers);

  for (RenderObject* child = firstChild(); child;
       child = child->nextSibling()) {
    // TODO(ojan): This is wrong at the moment. Inlines can have self painting
    // layers as well. Either make inlines with self-painting layers work or
    // don't allow inlines to be self painting.
    if (child->isBox()) {
      RenderBox* box = toRenderBox(child);
      if (box->hasSelfPaintingLayer())
        layers.append(box);
    }
  }
}

bool RenderParagraph::hitTestContents(
    const HitTestRequest& request,
    HitTestResult& result,
    const HitTestLocation& locationInContainer,
    const LayoutPoint& accumulatedOffset) {
  return m_lineBoxes.hitTest(this, request, result, locationInContainer,
                             accumulatedOffset);
}

void RenderParagraph::markLinesDirtyInBlockRange(LayoutUnit logicalTop,
                                                 LayoutUnit logicalBottom,
                                                 RootInlineBox* highest) {
  if (logicalTop >= logicalBottom)
    return;

  RootInlineBox* lowestDirtyLine = lastRootBox();
  RootInlineBox* afterLowest = lowestDirtyLine;
  while (lowestDirtyLine &&
         lowestDirtyLine->lineBottomWithLeading() >= logicalBottom &&
         logicalBottom < LayoutUnit::max()) {
    afterLowest = lowestDirtyLine;
    lowestDirtyLine = lowestDirtyLine->prevRootBox();
  }

  while (afterLowest && afterLowest != highest &&
         (afterLowest->lineBottomWithLeading() >= logicalTop ||
          afterLowest->lineBottomWithLeading() < 0)) {
    afterLowest->markDirty();
    afterLowest = afterLowest->prevRootBox();
  }
}

static void updateLogicalWidthForLeftAlignedBlock(bool isLeftToRightDirection,
                                                  BidiRun* trailingSpaceRun,
                                                  float& logicalLeft,
                                                  float& totalLogicalWidth,
                                                  float availableLogicalWidth) {
  // The direction of the block should determine what happens with wide lines.
  // In particular with RTL blocks, wide lines should still spill out to the
  // left.
  if (isLeftToRightDirection) {
    if (totalLogicalWidth > availableLogicalWidth && trailingSpaceRun)
      trailingSpaceRun->m_box->setLogicalWidth(
          std::max<float>(0, trailingSpaceRun->m_box->logicalWidth() -
                                 totalLogicalWidth + availableLogicalWidth));
    return;
  }

  if (trailingSpaceRun)
    trailingSpaceRun->m_box->setLogicalWidth(0);
  else if (totalLogicalWidth > availableLogicalWidth)
    logicalLeft -= (totalLogicalWidth - availableLogicalWidth);
}

static void updateLogicalWidthForRightAlignedBlock(
    bool isLeftToRightDirection,
    BidiRun* trailingSpaceRun,
    float& logicalLeft,
    float& totalLogicalWidth,
    float availableLogicalWidth) {
  // Wide lines spill out of the block based off direction.
  // So even if text-align is right, if direction is LTR, wide lines should
  // overflow out of the right side of the block.
  if (isLeftToRightDirection) {
    if (trailingSpaceRun) {
      totalLogicalWidth -= trailingSpaceRun->m_box->logicalWidth();
      trailingSpaceRun->m_box->setLogicalWidth(0);
    }
    if (totalLogicalWidth < availableLogicalWidth)
      logicalLeft += availableLogicalWidth - totalLogicalWidth;
    return;
  }

  if (totalLogicalWidth > availableLogicalWidth && trailingSpaceRun) {
    trailingSpaceRun->m_box->setLogicalWidth(
        std::max<float>(0, trailingSpaceRun->m_box->logicalWidth() -
                               totalLogicalWidth + availableLogicalWidth));
    totalLogicalWidth -= trailingSpaceRun->m_box->logicalWidth();
  } else
    logicalLeft += availableLogicalWidth - totalLogicalWidth;
}

static void updateLogicalWidthForCenterAlignedBlock(
    bool isLeftToRightDirection,
    BidiRun* trailingSpaceRun,
    float& logicalLeft,
    float& totalLogicalWidth,
    float availableLogicalWidth) {
  float trailingSpaceWidth = 0;
  if (trailingSpaceRun) {
    totalLogicalWidth -= trailingSpaceRun->m_box->logicalWidth();
    trailingSpaceWidth =
        std::min(trailingSpaceRun->m_box->logicalWidth(),
                 (availableLogicalWidth - totalLogicalWidth + 1) / 2);
    trailingSpaceRun->m_box->setLogicalWidth(
        std::max<float>(0, trailingSpaceWidth));
  }
  if (isLeftToRightDirection)
    logicalLeft +=
        std::max<float>((availableLogicalWidth - totalLogicalWidth) / 2, 0);
  else
    logicalLeft += totalLogicalWidth > availableLogicalWidth
                       ? (availableLogicalWidth - totalLogicalWidth)
                       : (availableLogicalWidth - totalLogicalWidth) / 2 -
                             trailingSpaceWidth;
}

void RenderParagraph::updateLogicalWidthForAlignment(
    const ETextAlign& textAlign,
    const RootInlineBox* rootInlineBox,
    BidiRun* trailingSpaceRun,
    float& logicalLeft,
    float& totalLogicalWidth,
    float& availableLogicalWidth,
    unsigned expansionOpportunityCount) {
  TextDirection direction;
  if (rootInlineBox &&
      rootInlineBox->renderer().style()->unicodeBidi() == Plaintext)
    direction = rootInlineBox->direction();
  else
    direction = style()->direction();

  // Armed with the total width of the line (without justification),
  // we now examine our text-align property in order to determine where to
  // position the objects horizontally. The total width of the line can be
  // increased if we end up justifying text.
  switch (textAlign) {
    case LEFT:
      updateLogicalWidthForLeftAlignedBlock(
          style()->isLeftToRightDirection(), trailingSpaceRun, logicalLeft,
          totalLogicalWidth, availableLogicalWidth);
      break;
    case RIGHT:
      updateLogicalWidthForRightAlignedBlock(
          style()->isLeftToRightDirection(), trailingSpaceRun, logicalLeft,
          totalLogicalWidth, availableLogicalWidth);
      break;
    case CENTER:
      updateLogicalWidthForCenterAlignedBlock(
          style()->isLeftToRightDirection(), trailingSpaceRun, logicalLeft,
          totalLogicalWidth, availableLogicalWidth);
      break;
    case JUSTIFY:
      adjustInlineDirectionLineBounds(expansionOpportunityCount, logicalLeft,
                                      availableLogicalWidth);
      if (expansionOpportunityCount) {
        if (trailingSpaceRun) {
          totalLogicalWidth -= trailingSpaceRun->m_box->logicalWidth();
          trailingSpaceRun->m_box->setLogicalWidth(0);
        }
        break;
      }
      // Fall through
    case TASTART:
      if (direction == LTR)
        updateLogicalWidthForLeftAlignedBlock(
            style()->isLeftToRightDirection(), trailingSpaceRun, logicalLeft,
            totalLogicalWidth, availableLogicalWidth);
      else
        updateLogicalWidthForRightAlignedBlock(
            style()->isLeftToRightDirection(), trailingSpaceRun, logicalLeft,
            totalLogicalWidth, availableLogicalWidth);
      break;
    case TAEND:
      if (direction == LTR)
        updateLogicalWidthForRightAlignedBlock(
            style()->isLeftToRightDirection(), trailingSpaceRun, logicalLeft,
            totalLogicalWidth, availableLogicalWidth);
      else
        updateLogicalWidthForLeftAlignedBlock(
            style()->isLeftToRightDirection(), trailingSpaceRun, logicalLeft,
            totalLogicalWidth, availableLogicalWidth);
      break;
  }
}

RootInlineBox* RenderParagraph::createAndAppendRootInlineBox() {
  RootInlineBox* rootBox = createRootInlineBox();
  m_lineBoxes.appendLineBox(rootBox);
  return rootBox;
}

RootInlineBox* RenderParagraph::createRootInlineBox() {
  return new RootInlineBox(*this);
}

InlineBox* RenderParagraph::createInlineBoxForRenderer(RenderObject* obj,
                                                       bool isRootLineBox,
                                                       bool isOnlyRun) {
  if (isRootLineBox)
    return toRenderParagraph(obj)->createAndAppendRootInlineBox();

  if (obj->isText()) {
    InlineTextBox* textBox = toRenderText(obj)->createInlineTextBox();
    // We only treat a box as text for a <br> if we are on a line by ourself or
    // in strict mode (Note the use of strict mode.  In "almost strict" mode, we
    // don't treat the box for <br> as text.)
    return textBox;
  }

  if (obj->isBox())
    return toRenderBox(obj)->createInlineBox();

  return toRenderInline(obj)->createAndAppendInlineFlowBox();
}

static inline void dirtyLineBoxesForRenderer(RenderObject* o, bool fullLayout) {
  if (o->isText()) {
    RenderText* renderText = toRenderText(o);
    renderText->dirtyLineBoxes(fullLayout);
  } else
    toRenderInline(o)->dirtyLineBoxes(fullLayout);
}

static bool parentIsConstructedOrHaveNext(InlineFlowBox* parentBox) {
  do {
    if (parentBox->isConstructed() || parentBox->nextOnLine())
      return true;
    parentBox = parentBox->parent();
  } while (parentBox);
  return false;
}

InlineFlowBox* RenderParagraph::createLineBoxes(RenderObject* obj,
                                                const LineInfo& lineInfo,
                                                InlineBox* childBox) {
  // See if we have an unconstructed line box for this object that is also
  // the last item on the line.
  unsigned lineDepth = 1;
  InlineFlowBox* parentBox = 0;
  InlineFlowBox* result = 0;
  bool hasDefaultLineBoxContain =
      style()->lineBoxContain() == RenderStyle::initialLineBoxContain();
  do {
    ASSERT_WITH_SECURITY_IMPLICATION(obj->isRenderInline() || obj == this);

    RenderInline* inlineFlow = (obj != this) ? toRenderInline(obj) : 0;

    // Get the last box we made for this render object.
    parentBox = inlineFlow ? inlineFlow->lastLineBox()
                           : toRenderBlock(obj)->lastLineBox();

    // If this box or its ancestor is constructed then it is from a previous
    // line, and we need to make a new box for our line.  If this box or its
    // ancestor is unconstructed but it has something following it on the line,
    // then we know we have to make a new box as well.  In this situation our
    // inline has actually been split in two on the same line (this can happen
    // with very fancy language mixtures).
    bool constructedNewBox = false;
    bool allowedToConstructNewBox = !hasDefaultLineBoxContain || !inlineFlow ||
                                    inlineFlow->alwaysCreateLineBoxes();
    bool canUseExistingParentBox =
        parentBox && !parentIsConstructedOrHaveNext(parentBox);
    if (allowedToConstructNewBox && !canUseExistingParentBox) {
      // We need to make a new box for this render object.  Once
      // made, we need to place it at the end of the current line.
      InlineBox* newBox = createInlineBoxForRenderer(obj, obj == this);
      ASSERT_WITH_SECURITY_IMPLICATION(newBox->isInlineFlowBox());
      parentBox = toInlineFlowBox(newBox);
      parentBox->setFirstLineStyleBit(lineInfo.isFirstLine());
      if (!hasDefaultLineBoxContain)
        parentBox->clearDescendantsHaveSameLineHeightAndBaseline();
      constructedNewBox = true;
    }

    if (constructedNewBox || canUseExistingParentBox) {
      if (!result)
        result = parentBox;

      // If we have hit the block itself, then |box| represents the root
      // inline box for the line, and it doesn't have to be appended to any
      // parent inline.
      if (childBox)
        parentBox->addToLine(childBox);

      if (!constructedNewBox || obj == this)
        break;

      childBox = parentBox;
    }

    // If we've exceeded our line depth, then jump straight to the root and skip
    // all the remaining intermediate inline flows.
    obj = (++lineDepth >= cMaxLineDepth) ? this : obj->parent();

  } while (true);

  return result;
}

template <typename CharacterType>
static inline bool endsWithASCIISpaces(const CharacterType* characters,
                                       unsigned pos,
                                       unsigned end) {
  while (isASCIISpace(characters[pos])) {
    pos++;
    if (pos >= end)
      return true;
  }
  return false;
}

static bool reachedEndOfTextRenderer(const BidiRunList<BidiRun>& bidiRuns) {
  BidiRun* run = bidiRuns.logicallyLastRun();
  if (!run)
    return true;
  unsigned pos = run->stop();
  RenderObject* r = run->m_object;
  if (!r->isText())
    return false;
  RenderText* renderText = toRenderText(r);
  unsigned length = renderText->textLength();
  if (pos >= length)
    return true;

  if (renderText->is8Bit())
    return endsWithASCIISpaces(renderText->characters8(), pos, length);
  return endsWithASCIISpaces(renderText->characters16(), pos, length);
}

RootInlineBox* RenderParagraph::constructLine(BidiRunList<BidiRun>& bidiRuns,
                                              const LineInfo& lineInfo) {
  ASSERT(bidiRuns.firstRun());

  bool rootHasSelectedChildren = false;
  InlineFlowBox* parentBox = 0;
  int runCount = bidiRuns.runCount() - lineInfo.runsFromLeadingWhitespace();
  for (BidiRun* r = bidiRuns.firstRun(); r; r = r->next()) {
    // Create a box for our object.
    bool isOnlyRun = (runCount == 1);
    if (runCount == 2)
      isOnlyRun = false;

    if (lineInfo.isEmpty())
      continue;

    InlineBox* box = createInlineBoxForRenderer(r->m_object, false, isOnlyRun);
    r->m_box = box;

    ASSERT(box);
    if (!box)
      continue;

    if (!rootHasSelectedChildren &&
        box->renderer().selectionState() != RenderObject::SelectionNone)
      rootHasSelectedChildren = true;

    // If we have no parent box yet, or if the run is not simply a sibling,
    // then we need to construct inline boxes as necessary to properly enclose
    // the run's inline box. Segments can only be siblings at the root level, as
    // they are positioned separately.
    if (!parentBox || parentBox->renderer() != r->m_object->parent()) {
      // Create new inline boxes all the way back to the appropriate insertion
      // point.
      parentBox = createLineBoxes(r->m_object->parent(), lineInfo, box);
    } else {
      // Append the inline box to this line.
      parentBox->addToLine(box);
    }

    box->setBidiLevel(r->level());

    if (box->isInlineTextBox()) {
      InlineTextBox* text = toInlineTextBox(box);
      text->setStart(r->m_start);
      text->setLen(r->m_stop - r->m_start);
      text->setDirOverride(r->dirOverride());
      if (r->m_hasHyphen)
        text->setHasHyphen(true);
      if (r->m_hasAddedEllipsis)
        text->setHasAddedEllipsis(true);
    }
  }

  ASSERT(lastLineBox() && !lastLineBox()->isConstructed());

  // Set the m_selectedChildren flag on the root inline box if one of the leaf
  // inline box from the bidi runs walk above has a selection state.
  if (rootHasSelectedChildren)
    lastLineBox()->root().setHasSelectedChildren(true);

  // Set bits on our inline flow boxes that indicate which sides should
  // paint borders/margins/padding.  This knowledge will ultimately be used when
  // we determine the horizontal positions and widths of all the inline boxes on
  // the line.
  bool isLogicallyLastRunWrapped =
      bidiRuns.logicallyLastRun()->m_object &&
              bidiRuns.logicallyLastRun()->m_object->isText()
          ? !reachedEndOfTextRenderer(bidiRuns)
          : true;
  lastLineBox()->determineSpacingForFlowBoxes(
      lineInfo.isLastLine(), isLogicallyLastRunWrapped,
      bidiRuns.logicallyLastRun()->m_object);

  // Now mark the line boxes as being constructed.
  lastLineBox()->setConstructed();

  // Return the last line.
  return lastRootBox();
}

ETextAlign RenderParagraph::textAlignmentForLine(bool endsWithSoftBreak) const {
  ETextAlign alignment = style()->textAlign();
  if (endsWithSoftBreak)
    return alignment;
  return (alignment == JUSTIFY) ? TASTART : alignment;
}

static inline void setLogicalWidthForTextRun(
    RootInlineBox* lineBox,
    BidiRun* run,
    RenderText* renderer,
    float xPos,
    const LineInfo& lineInfo,
    GlyphOverflowAndFallbackFontsMap& textBoxDataMap,
    VerticalPositionCache& verticalPositionCache,
    WordMeasurements& wordMeasurements) {
  HashSet<const SimpleFontData*> fallbackFonts;
  GlyphOverflow glyphOverflow;

  const Font& font = renderer->style(lineInfo.isFirstLine())->font();
  // Always compute glyph overflow if the block's line-box-contain value is
  // "glyphs".
  if (lineBox->fitsToGlyphs()) {
    // If we don't stick out of the root line's font box, then don't bother
    // computing our glyph overflow. This optimization will keep us from
    // computing glyph bounds in nearly all cases.
    bool includeRootLine = lineBox->includesRootLineBoxFontOrLeading();
    int baselineShift =
        lineBox->verticalPositionForBox(run->m_box, verticalPositionCache);
    int rootDescent = includeRootLine ? font.fontMetrics().descent() : 0;
    int rootAscent = includeRootLine ? font.fontMetrics().ascent() : 0;
    int boxAscent = font.fontMetrics().ascent() - baselineShift;
    int boxDescent = font.fontMetrics().descent() + baselineShift;
    if (boxAscent > rootDescent || boxDescent > rootAscent)
      glyphOverflow.computeBounds = true;
  }

  LayoutUnit hyphenWidth = 0;
  if (toInlineTextBox(run->m_box)->hasHyphen()) {
    const Font& font = renderer->style(lineInfo.isFirstLine())->font();
    hyphenWidth = measureHyphenWidth(renderer, font, run->direction());
  }
  float measuredWidth = 0;

  bool kerningIsEnabled =
      font.fontDescription().typesettingFeatures() & Kerning;

  bool canUseSimpleFontCodePath = renderer->canUseSimpleFontCodePath();

  // Since we don't cache glyph overflows, we need to re-measure the run if
  // the style is linebox-contain: glyph.

  if (!lineBox->fitsToGlyphs() && canUseSimpleFontCodePath) {
    int lastEndOffset = run->m_start;
    for (size_t i = 0, size = wordMeasurements.size();
         i < size && lastEndOffset < run->m_stop; ++i) {
      const WordMeasurement& wordMeasurement = wordMeasurements[i];
      if (wordMeasurement.width <= 0 ||
          wordMeasurement.startOffset == wordMeasurement.endOffset)
        continue;
      if (wordMeasurement.renderer != renderer ||
          wordMeasurement.startOffset != lastEndOffset ||
          wordMeasurement.endOffset > run->m_stop)
        continue;

      lastEndOffset = wordMeasurement.endOffset;
      if (kerningIsEnabled && lastEndOffset == run->m_stop) {
        int wordLength = lastEndOffset - wordMeasurement.startOffset;
        measuredWidth +=
            renderer->width(wordMeasurement.startOffset, wordLength, xPos,
                            run->direction(), lineInfo.isFirstLine());
        if (i > 0 && wordLength == 1 &&
            renderer->characterAt(wordMeasurement.startOffset) == ' ')
          measuredWidth += renderer->style()->wordSpacing();
      } else
        measuredWidth += wordMeasurement.width;
      if (!wordMeasurement.fallbackFonts.isEmpty()) {
        HashSet<const SimpleFontData*>::const_iterator end =
            wordMeasurement.fallbackFonts.end();
        for (HashSet<const SimpleFontData*>::const_iterator it =
                 wordMeasurement.fallbackFonts.begin();
             it != end; ++it)
          fallbackFonts.add(*it);
      }
    }
    if (measuredWidth && lastEndOffset != run->m_stop) {
      // If we don't have enough cached data, we'll measure the run again.
      measuredWidth = 0;
      fallbackFonts.clear();
    }
  }

  if (!measuredWidth)
    measuredWidth = renderer->width(
        run->m_start, run->m_stop - run->m_start, xPos, run->direction(),
        lineInfo.isFirstLine(), &fallbackFonts, &glyphOverflow);

  run->m_box->setLogicalWidth(measuredWidth + hyphenWidth);
  if (!fallbackFonts.isEmpty()) {
    ASSERT(run->m_box->isText());
    GlyphOverflowAndFallbackFontsMap::ValueType* it =
        textBoxDataMap
            .add(toInlineTextBox(run->m_box),
                 std::make_pair(Vector<const SimpleFontData*>(),
                                GlyphOverflow()))
            .storedValue;
    ASSERT(it->value.first.isEmpty());
    copyToVector(fallbackFonts, it->value.first);
    run->m_box->parent()->clearDescendantsHaveSameLineHeightAndBaseline();
  }
  if (!glyphOverflow.isZero()) {
    ASSERT(run->m_box->isText());
    GlyphOverflowAndFallbackFontsMap::ValueType* it =
        textBoxDataMap
            .add(toInlineTextBox(run->m_box),
                 std::make_pair(Vector<const SimpleFontData*>(),
                                GlyphOverflow()))
            .storedValue;
    it->value.second = glyphOverflow;
    run->m_box->clearKnownToHaveNoOverflow();
  }
}

static inline void computeExpansionForJustifiedText(
    BidiRun* firstRun,
    BidiRun* trailingSpaceRun,
    Vector<unsigned, 16>& expansionOpportunities,
    unsigned expansionOpportunityCount,
    float& totalLogicalWidth,
    float availableLogicalWidth) {
  if (!expansionOpportunityCount || availableLogicalWidth <= totalLogicalWidth)
    return;

  size_t i = 0;
  for (BidiRun* r = firstRun; r; r = r->next()) {
    if (!r->m_box || r == trailingSpaceRun)
      continue;

    if (r->m_object->isText()) {
      unsigned opportunitiesInRun = expansionOpportunities[i++];

      ASSERT(opportunitiesInRun <= expansionOpportunityCount);

      // Don't justify for white-space: pre.
      if (r->m_object->style()->whiteSpace() != PRE) {
        InlineTextBox* textBox = toInlineTextBox(r->m_box);
        int expansion = (availableLogicalWidth - totalLogicalWidth) *
                        opportunitiesInRun / expansionOpportunityCount;
        textBox->setExpansion(expansion);
        totalLogicalWidth += expansion;
      }
      expansionOpportunityCount -= opportunitiesInRun;
      if (!expansionOpportunityCount)
        break;
    }
  }
}

static void updateLogicalInlinePositions(RenderParagraph* block,
                                         float& lineLogicalLeft,
                                         float& lineLogicalRight,
                                         float& availableLogicalWidth,
                                         IndentTextOrNot shouldIndentText) {
  lineLogicalLeft =
      block->logicalLeftOffsetForLine(shouldIndentText == IndentText).toFloat();
  lineLogicalRight =
      block->logicalRightOffsetForLine(shouldIndentText == IndentText)
          .toFloat();
  availableLogicalWidth = lineLogicalRight - lineLogicalLeft;
}

void RenderParagraph::computeInlineDirectionPositionsForLine(
    RootInlineBox* lineBox,
    const LineInfo& lineInfo,
    BidiRun* firstRun,
    BidiRun* trailingSpaceRun,
    bool reachedEnd,
    GlyphOverflowAndFallbackFontsMap& textBoxDataMap,
    VerticalPositionCache& verticalPositionCache,
    WordMeasurements& wordMeasurements) {
  ETextAlign textAlign =
      textAlignmentForLine(!reachedEnd && !lineBox->endsWithBreak());

  // CSS 2.1: "'Text-indent' only affects a line if it is the first formatted
  // line of an element. For example, the first line of an anonymous block box
  // is only affected if it is the first child of its parent element." CSS3
  // "text-indent", "each-line" affects the first line of the block container as
  // well as each line after a forced line break, but does not affect lines
  // after a soft wrap break.
  bool isFirstLine = lineInfo.isFirstLine();
  bool isAfterHardLineBreak =
      lineBox->prevRootBox() && lineBox->prevRootBox()->endsWithBreak();
  IndentTextOrNot shouldIndentText =
      requiresIndent(isFirstLine, isAfterHardLineBreak, style());
  float lineLogicalLeft;
  float lineLogicalRight;
  float availableLogicalWidth;
  updateLogicalInlinePositions(this, lineLogicalLeft, lineLogicalRight,
                               availableLogicalWidth, shouldIndentText);
  bool needsWordSpacing;

  if (firstRun && firstRun->m_object->isReplaced())
    updateLogicalInlinePositions(this, lineLogicalLeft, lineLogicalRight,
                                 availableLogicalWidth, shouldIndentText);

  computeInlineDirectionPositionsForSegment(
      lineBox, lineInfo, textAlign, lineLogicalLeft, availableLogicalWidth,
      firstRun, trailingSpaceRun, textBoxDataMap, verticalPositionCache,
      wordMeasurements);
  // The widths of all runs are now known. We can now place every inline box
  // (and compute accurate widths for the inline flow boxes).
  needsWordSpacing = false;
  lineBox->placeBoxesInInlineDirection(lineLogicalLeft, needsWordSpacing);
}

BidiRun* RenderParagraph::computeInlineDirectionPositionsForSegment(
    RootInlineBox* lineBox,
    const LineInfo& lineInfo,
    ETextAlign textAlign,
    float& logicalLeft,
    float& availableLogicalWidth,
    BidiRun* firstRun,
    BidiRun* trailingSpaceRun,
    GlyphOverflowAndFallbackFontsMap& textBoxDataMap,
    VerticalPositionCache& verticalPositionCache,
    WordMeasurements& wordMeasurements) {
  bool needsWordSpacing = true;
  float totalLogicalWidth = lineBox->getFlowSpacingLogicalWidth().toFloat();
  unsigned expansionOpportunityCount = 0;
  bool isAfterExpansion = true;
  Vector<unsigned, 16> expansionOpportunities;
  TextJustify textJustify = style()->textJustify();

  BidiRun* r = firstRun;
  for (; r; r = r->next()) {
    if (!r->m_box || r->m_object->isOutOfFlowPositioned() ||
        r->m_box->isLineBreak())
      continue;  // Positioned objects are only participating to figure out
                 // their correct static x position.  They have no effect on the
                 // width. Similarly, line break boxes have no effect on the
                 // width.
    if (r->m_object->isText()) {
      RenderText* rt = toRenderText(r->m_object);
      if (textAlign == JUSTIFY && r != trailingSpaceRun &&
          textJustify != TextJustifyNone) {
        if (!isAfterExpansion)
          toInlineTextBox(r->m_box)->setCanHaveLeadingExpansion(true);
        unsigned opportunitiesInRun;
        if (rt->is8Bit())
          opportunitiesInRun = Character::expansionOpportunityCount(
              rt->characters8() + r->m_start, r->m_stop - r->m_start,
              r->m_box->direction(), isAfterExpansion);
        else
          opportunitiesInRun = Character::expansionOpportunityCount(
              rt->characters16() + r->m_start, r->m_stop - r->m_start,
              r->m_box->direction(), isAfterExpansion);
        expansionOpportunities.append(opportunitiesInRun);
        expansionOpportunityCount += opportunitiesInRun;
      }

      if (rt->textLength()) {
        if (!r->m_start && needsWordSpacing &&
            isSpaceOrNewline(rt->characterAt(r->m_start)))
          totalLogicalWidth += rt->style(lineInfo.isFirstLine())
                                   ->font()
                                   .fontDescription()
                                   .wordSpacing();
        needsWordSpacing = !isSpaceOrNewline(rt->characterAt(r->m_stop - 1));
      }

      setLogicalWidthForTextRun(lineBox, r, rt, totalLogicalWidth, lineInfo,
                                textBoxDataMap, verticalPositionCache,
                                wordMeasurements);
    } else {
      isAfterExpansion = false;
      if (!r->m_object->isRenderInline()) {
        RenderBox* renderBox = toRenderBox(r->m_object);
        r->m_box->setLogicalWidth(logicalWidthForChild(renderBox).toFloat());
        totalLogicalWidth +=
            marginStartForChild(renderBox) + marginEndForChild(renderBox);
      }
    }

    totalLogicalWidth += r->m_box->logicalWidth();
  }

  if (isAfterExpansion && !expansionOpportunities.isEmpty()) {
    expansionOpportunities.last()--;
    expansionOpportunityCount--;
  }

  updateLogicalWidthForAlignment(
      textAlign, lineBox, trailingSpaceRun, logicalLeft, totalLogicalWidth,
      availableLogicalWidth, expansionOpportunityCount);

  computeExpansionForJustifiedText(
      firstRun, trailingSpaceRun, expansionOpportunities,
      expansionOpportunityCount, totalLogicalWidth, availableLogicalWidth);

  return r;
}

void RenderParagraph::computeBlockDirectionPositionsForLine(
    RootInlineBox* lineBox,
    BidiRun* firstRun,
    GlyphOverflowAndFallbackFontsMap& textBoxDataMap,
    VerticalPositionCache& verticalPositionCache) {
  setLogicalHeight(lineBox->alignBoxesInBlockDirection(
      logicalHeight(), textBoxDataMap, verticalPositionCache));

  // Now make sure we place replaced render objects correctly.
  for (BidiRun* r = firstRun; r; r = r->next()) {
    ASSERT(r->m_box);
    if (!r->m_box)
      continue;  // Skip runs with no line boxes.

    // Align positioned boxes with the top of the line box.  This is
    // a reasonable approximation of an appropriate y position.
    if (r->m_object->isOutOfFlowPositioned())
      r->m_box->setLogicalTop(logicalHeight().toFloat());

    // Position is used to properly position both replaced elements and
    // to update the static normal flow x/y of positioned elements.
    if (r->m_object->isText())
      toRenderText(r->m_object)->positionLineBox(r->m_box);
    else if (r->m_object->isBox())
      toRenderBox(r->m_object)->positionLineBox(r->m_box);
  }
}

// This function constructs line boxes for all of the text runs in the resolver
// and computes their position.
RootInlineBox* RenderParagraph::createLineBoxesFromBidiRuns(
    unsigned bidiLevel,
    BidiRunList<BidiRun>& bidiRuns,
    const InlineIterator& end,
    LineInfo& lineInfo,
    VerticalPositionCache& verticalPositionCache,
    BidiRun* trailingSpaceRun,
    WordMeasurements& wordMeasurements) {
  if (!bidiRuns.runCount())
    return 0;

  // FIXME: Why is this only done when we had runs?
  lineInfo.setLastLine(!end.object());

  RootInlineBox* lineBox = constructLine(bidiRuns, lineInfo);
  if (!lineBox)
    return 0;

  lineBox->setBidiLevel(bidiLevel);
  lineBox->setEndsWithBreak(lineInfo.previousLineBrokeCleanly());

  GlyphOverflowAndFallbackFontsMap textBoxDataMap;

  // Now we position all of our text runs horizontally.
  computeInlineDirectionPositionsForLine(
      lineBox, lineInfo, bidiRuns.firstRun(), trailingSpaceRun, end.atEnd(),
      textBoxDataMap, verticalPositionCache, wordMeasurements);

  // Now position our text runs vertically.
  computeBlockDirectionPositionsForLine(lineBox, bidiRuns.firstRun(),
                                        textBoxDataMap, verticalPositionCache);

  // Compute our overflow now.
  lineBox->computeOverflow(lineBox->lineTop(), lineBox->lineBottom(),
                           textBoxDataMap);

  return lineBox;
}

static void deleteLineRange(LineLayoutState& layoutState,
                            RootInlineBox* startLine,
                            RootInlineBox* stopLine = 0) {
  RootInlineBox* boxToDelete = startLine;
  while (boxToDelete && boxToDelete != stopLine) {
    // Note: deleteLineRange(firstRootBox()) is not identical to
    // deleteLineBoxTree(). deleteLineBoxTree uses nextLineBox() instead of
    // nextRootBox() when traversing.
    RootInlineBox* next = boxToDelete->nextRootBox();
    boxToDelete->deleteLine();
    boxToDelete = next;
  }
}

void RenderParagraph::layoutRunsAndFloats(LineLayoutState& layoutState) {
  // We want to skip ahead to the first dirty line
  InlineBidiResolver resolver;
  RootInlineBox* startLine = determineStartPosition(layoutState, resolver);

  // We also find the first clean line and extract these lines.  We will add
  // them back if we determine that we're able to synchronize after handling all
  // our dirty lines.
  InlineIterator cleanLineStart;
  BidiStatus cleanLineBidiStatus;
  if (!layoutState.isFullLayout() && startLine)
    determineEndPosition(layoutState, startLine, cleanLineStart,
                         cleanLineBidiStatus);

  if (startLine)
    deleteLineRange(layoutState, startLine);

  layoutRunsAndFloatsInRange(layoutState, resolver, cleanLineStart,
                             cleanLineBidiStatus);
  linkToEndLineIfNeeded(layoutState);
}

void RenderParagraph::layoutRunsAndFloatsInRange(
    LineLayoutState& layoutState,
    InlineBidiResolver& resolver,
    const InlineIterator& cleanLineStart,
    const BidiStatus& cleanLineBidiStatus) {
  RenderStyle* styleToUse = style();
  LineMidpointState& lineMidpointState = resolver.midpointState();
  InlineIterator endOfLine = resolver.position();
  bool checkForEndLineMatch = layoutState.endLine();
  RenderTextInfo renderTextInfo;
  VerticalPositionCache verticalPositionCache;
  LineBreaker lineBreaker(this);

  m_didExceedMaxLines = false;

  while (!endOfLine.atEnd()) {
    // FIXME: Is this check necessary before the first iteration or can it be
    // moved to the end?
    if (checkForEndLineMatch) {
      layoutState.setEndLineMatched(matchedEndLine(
          layoutState, resolver, cleanLineStart, cleanLineBidiStatus));
      if (layoutState.endLineMatched()) {
        resolver.setPosition(InlineIterator(resolver.position().root(), 0, 0),
                             0);
        break;
      }
    }

    lineMidpointState.reset();

    layoutState.lineInfo().setEmpty(true);
    layoutState.lineInfo().resetRunsFromLeadingWhitespace();

    bool isNewUBAParagraph = layoutState.lineInfo().previousLineBrokeCleanly();
    FloatingObject* lastFloatFromPreviousLine = 0;

    WordMeasurements wordMeasurements;
    endOfLine = lineBreaker.nextLineBreak(
        resolver, layoutState.lineInfo(), renderTextInfo,
        lastFloatFromPreviousLine, wordMeasurements);
    renderTextInfo.m_lineBreakIterator.resetPriorContext();
    m_didExceedMaxLines =
        layoutState.lineInfo().lineIndex() > styleToUse->maxLines() &&
        !layoutState.lineInfo().isEmpty();
    if (resolver.position().atEnd() || m_didExceedMaxLines) {
      // FIXME: We shouldn't be creating any runs in nextLineBreak to begin
      // with! Once BidiRunList is separated from BidiResolver this will not be
      // needed.
      resolver.runs().deleteRuns();
      resolver.markCurrentRunEmpty();  // FIXME: This can probably be replaced
                                       // by an ASSERT (or just removed).
      resolver.setPosition(InlineIterator(resolver.position().root(), 0, 0), 0);
      break;
    }

    ASSERT(endOfLine != resolver.position());

    // This is a short-cut for empty lines.
    if (layoutState.lineInfo().isEmpty()) {
      if (lastRootBox())
        lastRootBox()->setLineBreakInfo(endOfLine.object(), endOfLine.offset(),
                                        resolver.status());
    } else {
      VisualDirectionOverride override =
          (styleToUse->rtlOrdering() == VisualOrder
               ? (styleToUse->direction() == LTR ? VisualLeftToRightOverride
                                                 : VisualRightToLeftOverride)
               : NoVisualOverride);
      if (isNewUBAParagraph && styleToUse->unicodeBidi() == Plaintext &&
          !resolver.context()->parent()) {
        TextDirection direction = determinePlaintextDirectionality(
            resolver.position().root(), resolver.position().object(),
            resolver.position().offset());
        resolver.setStatus(
            BidiStatus(direction, isOverride(styleToUse->unicodeBidi())));
      }
      // FIXME: This ownership is reversed. We should own the BidiRunList and
      // pass it to createBidiRunsForLine.
      BidiRunList<BidiRun>& bidiRuns = resolver.runs();
      constructBidiRunsForLine(
          resolver, bidiRuns, endOfLine, override,
          layoutState.lineInfo().previousLineBrokeCleanly(), isNewUBAParagraph);
      ASSERT(resolver.position() == endOfLine);

      BidiRun* trailingSpaceRun = resolver.trailingSpaceRun();

      if (bidiRuns.runCount() && lineBreaker.lineWasHyphenated())
        bidiRuns.logicallyLastRun()->m_hasHyphen = true;
      if (bidiRuns.runCount() && lineBreaker.lineWasEllipsized())
        bidiRuns.logicallyLastRun()->m_hasAddedEllipsis = true;

      // Now that the runs have been ordered, we create the line boxes.
      // At the same time we figure out where border/padding/margin should be
      // applied for inline flow boxes.

      RootInlineBox* lineBox = createLineBoxesFromBidiRuns(
          resolver.status().context->level(), bidiRuns, endOfLine,
          layoutState.lineInfo(), verticalPositionCache, trailingSpaceRun,
          wordMeasurements);

      bidiRuns.deleteRuns();
      resolver.markCurrentRunEmpty();  // FIXME: This can probably be replaced
                                       // by an ASSERT (or just removed).

      if (lineBox)
        lineBox->setLineBreakInfo(endOfLine.object(), endOfLine.offset(),
                                  resolver.status());
    }

    if (!layoutState.lineInfo().isEmpty())
      layoutState.lineInfo().setFirstLine(false);

    lineMidpointState.reset();
    resolver.setPosition(endOfLine, numberOfIsolateAncestors(endOfLine));

    // Limit ellipsized text to a single line.
    if (lineBreaker.lineWasEllipsized()) {
      m_didExceedMaxLines = true;
      resolver.setPosition(InlineIterator(resolver.position().root(), 0, 0), 0);
      break;
    }
  }
}

void RenderParagraph::linkToEndLineIfNeeded(LineLayoutState& layoutState) {
  if (layoutState.endLine()) {
    if (layoutState.endLineMatched()) {
      // Attach all the remaining lines, and then adjust their y-positions as
      // needed.
      LayoutUnit delta = logicalHeight() - layoutState.endLineLogicalTop();
      for (RootInlineBox* line = layoutState.endLine(); line;
           line = line->nextRootBox()) {
        line->attachLine();
        if (delta)
          line->adjustBlockDirectionPosition(delta.toFloat());
      }
      setLogicalHeight(lastRootBox()->lineBottomWithLeading());
    } else {
      // Delete all the remaining lines.
      deleteLineRange(layoutState, layoutState.endLine());
    }
  }
}

struct InlineMinMaxIterator {
  /* InlineMinMaxIterator is a class that will iterate over all render objects
     that contribute to inline min/max width calculations.  Note the following
     about the way it walks: (1) Positioned content is skipped (since it does
     not contribute to min/max width of a block) (2) We do not drill into the
     children of floats or replaced elements, since you can't break in the
     middle of such an element. (3) Inline flows (e.g., <a>, <span>, <i>) are
     walked twice, since each side can have distinct borders/margin/padding that
     contribute to the min/max width.
  */
  RenderObject* parent;
  RenderObject* current;
  bool endOfInline;

  InlineMinMaxIterator(RenderObject* p)
      : parent(p), current(p), endOfInline(false) {}

  RenderObject* next();
};

RenderObject* InlineMinMaxIterator::next() {
  RenderObject* result = 0;
  bool oldEndOfInline = endOfInline;
  endOfInline = false;
  while (current || current == parent) {
    if (!oldEndOfInline &&
        (current == parent ||
         (!current->isReplaced() && !current->isOutOfFlowPositioned())))
      result = current->slowFirstChild();

    if (!result) {
      // We hit the end of our inline. (It was empty, e.g., <span></span>.)
      if (!oldEndOfInline && current->isRenderInline()) {
        result = current;
        endOfInline = true;
        break;
      }

      while (current && current != parent) {
        result = current->nextSibling();
        if (result)
          break;
        current = current->parent();
        if (current && current != parent && current->isRenderInline()) {
          result = current;
          endOfInline = true;
          break;
        }
      }
    }

    if (!result)
      break;

    if (!result->isOutOfFlowPositioned() &&
        (result->isText() || result->isReplaced() || result->isRenderInline()))
      break;

    current = result;
    result = 0;
  }

  // Update our position.
  current = result;
  return current;
}

static LayoutUnit getBPMWidth(LayoutUnit childValue, Length cssUnit) {
  if (cssUnit.type() != Auto)
    return (cssUnit.isFixed() ? static_cast<LayoutUnit>(cssUnit.value())
                              : childValue);
  return 0;
}

static LayoutUnit getBorderPaddingMargin(RenderBoxModelObject* child,
                                         bool endOfInline) {
  RenderStyle* childStyle = child->style();
  if (endOfInline) {
    return getBPMWidth(child->marginEnd(), childStyle->marginEnd()) +
           getBPMWidth(child->paddingEnd(), childStyle->paddingEnd()) +
           child->borderEnd();
  }
  return getBPMWidth(child->marginStart(), childStyle->marginStart()) +
         getBPMWidth(child->paddingStart(), childStyle->paddingStart()) +
         child->borderStart();
}

static inline void stripTrailingSpace(float& inlineMax,
                                      float& inlineMin,
                                      RenderObject* trailingSpaceChild) {
  if (trailingSpaceChild && trailingSpaceChild->isText()) {
    // Collapse away the trailing space at the end of a block.
    RenderText* t = toRenderText(trailingSpaceChild);
    const UChar space = ' ';
    const Font& font = t->style()->font();  // FIXME: This ignores first-line.
    float spaceWidth =
        font.width(constructTextRun(t, font, &space, 1, t->style(), LTR));
    inlineMax -= spaceWidth + font.fontDescription().wordSpacing();
    if (inlineMin > inlineMax)
      inlineMin = inlineMax;
  }
}

static inline void updatePreferredWidth(LayoutUnit& preferredWidth,
                                        float& result) {
  LayoutUnit snappedResult = LayoutUnit::fromFloatCeil(result);
  preferredWidth = std::max(snappedResult, preferredWidth);
}

// When converting between floating point and LayoutUnits we risk losing
// precision with each conversion. When this occurs while accumulating our
// preferred widths, we can wind up with a line width that's larger than our
// maxPreferredWidth due to pure float accumulation.
static inline LayoutUnit adjustFloatForSubPixelLayout(float value) {
  return LayoutUnit::fromFloatCeil(value);
}

// FIXME: This function should be broken into something less monolithic.
// FIXME: The main loop here is very similar to LineBreaker::nextSegmentBreak.
// They can probably reuse code.
void RenderParagraph::computeIntrinsicLogicalWidths(
    LayoutUnit& minLogicalWidth,
    LayoutUnit& maxLogicalWidth) const {
  float inlineMax = 0;
  float inlineMin = 0;

  RenderStyle* styleToUse = style();
  RenderBlock* containingBlock = this->containingBlock();
  LayoutUnit cw =
      containingBlock ? containingBlock->contentLogicalWidth() : LayoutUnit();

  // If we are at the start of a line, we want to ignore all white-space.
  // Also strip spaces if we previously had text that ended in a trailing space.
  bool stripFrontSpaces = true;
  RenderObject* trailingSpaceChild = 0;

  bool autoWrap, oldAutoWrap;
  autoWrap = oldAutoWrap = styleToUse->autoWrap();

  InlineMinMaxIterator childIterator(const_cast<RenderParagraph*>(this));

  // Only gets added to the max preffered width once.
  bool addedTextIndent = false;
  // Signals the text indent was more negative than the min preferred width
  bool hasRemainingNegativeTextIndent = false;

  LayoutUnit textIndent = minimumValueForLength(styleToUse->textIndent(), cw);
  bool isPrevChildInlineFlow = false;
  bool shouldBreakLineAfterText = false;
  while (RenderObject* child = childIterator.next()) {
    autoWrap = child->isReplaced() ? child->parent()->style()->autoWrap()
                                   : child->style()->autoWrap();

    // Step One: determine whether or not we need to go ahead and
    // terminate our current line. Each discrete chunk can become
    // the new min-width, if it is the widest chunk seen so far, and
    // it can also become the max-width.

    // Children fall into three categories:
    // (1) An inline flow object. These objects always have a min/max of 0,
    // and are included in the iteration solely so that their margins can
    // be added in.
    //
    // (2) An inline non-text non-flow object, e.g., an inline replaced element.
    // These objects can always be on a line by themselves, so in this situation
    // we need to go ahead and break the current line, and then add in our own
    // margins and min/max width on its own line, and then terminate the line.
    //
    // (3) A text object. Text runs can have breakable characters at the start,
    // the middle or the end. They may also lose whitespace off the front if
    // we're already ignoring whitespace. In order to compute accurate min-width
    // information, we need three pieces of information.
    // (a) the min-width of the first non-breakable run. Should be 0 if the text
    // string starts with whitespace. (b) the min-width of the last
    // non-breakable run. Should be 0 if the text string ends with whitespace.
    // (c) the min/max width of the string (trimmed for whitespace).
    //
    // If the text string starts with whitespace, then we need to go ahead and
    // terminate our current line (unless we're already in a whitespace
    // stripping mode.
    //
    // If the text string has a breakable character in the middle, but didn't
    // start with whitespace, then we add the width of the first non-breakable
    // run and then end the current line. We then need to use the intermediate
    // min/max width values (if any of them are larger than our current
    // min/max). We then look at the width of the last non-breakable run and use
    // that to start a new line (unless we end in whitespace).
    RenderStyle* childStyle = child->style();
    float childMin = 0;
    float childMax = 0;

    if (!child->isText()) {
      // Case (1) and (2). Inline replaced and inline flow elements.
      if (child->isRenderInline()) {
        // Add in padding/border/margin from the appropriate side of
        // the element.
        float bpm = getBorderPaddingMargin(toRenderInline(child),
                                           childIterator.endOfInline)
                        .toFloat();
        childMin += bpm;
        childMax += bpm;

        inlineMin += childMin;
        inlineMax += childMax;

        child->clearPreferredLogicalWidthsDirty();
      } else {
        // Inline replaced elts add in their margins to their min/max values.
        LayoutUnit margins = 0;
        Length startMargin = childStyle->marginStart();
        Length endMargin = childStyle->marginEnd();
        if (startMargin.isFixed())
          margins += adjustFloatForSubPixelLayout(startMargin.value());
        if (endMargin.isFixed())
          margins += adjustFloatForSubPixelLayout(endMargin.value());
        childMin += margins.ceilToFloat();
        childMax += margins.ceilToFloat();
      }
    }

    if (!child->isRenderInline() && !child->isText()) {
      // Case (2). Inline replaced elements and floats.
      // Go ahead and terminate the current line as far as
      // minwidth is concerned.
      LayoutUnit childMinPreferredLogicalWidth =
          child->minPreferredLogicalWidth();
      LayoutUnit childMaxPreferredLogicalWidth =
          child->maxPreferredLogicalWidth();
      childMin += childMinPreferredLogicalWidth.ceilToFloat();
      childMax += childMaxPreferredLogicalWidth.ceilToFloat();

      bool canBreakReplacedElement = true;
      if ((canBreakReplacedElement && (autoWrap || oldAutoWrap) &&
           (!isPrevChildInlineFlow || shouldBreakLineAfterText))) {
        updatePreferredWidth(minLogicalWidth, inlineMin);
        inlineMin = 0;
      }

      // Add in text-indent. This is added in only once.
      if (!addedTextIndent) {
        float ceiledTextIndent = textIndent.ceilToFloat();
        childMin += ceiledTextIndent;
        childMax += ceiledTextIndent;

        if (childMin < 0)
          textIndent = adjustFloatForSubPixelLayout(childMin);
        else
          addedTextIndent = true;
      }

      // Add our width to the max.
      inlineMax += std::max<float>(0, childMax);

      if (!autoWrap || !canBreakReplacedElement ||
          (isPrevChildInlineFlow && !shouldBreakLineAfterText)) {
        inlineMin += childMin;
      } else {
        // Now check our line.
        updatePreferredWidth(minLogicalWidth, childMin);

        // Now start a new line.
        inlineMin = 0;
      }

      if (autoWrap && canBreakReplacedElement && isPrevChildInlineFlow) {
        updatePreferredWidth(minLogicalWidth, inlineMin);
        inlineMin = 0;
      }

      // We are no longer stripping whitespace at the start of
      // a line.
      stripFrontSpaces = false;
      trailingSpaceChild = 0;
    } else if (child->isText()) {
      // Case (3). Text.
      RenderText* t = toRenderText(child);

      // Determine if we have a breakable character. Pass in
      // whether or not we should ignore any spaces at the front
      // of the string. If those are going to be stripped out,
      // then they shouldn't be considered in the breakable char
      // check.
      bool hasBreakableChar, hasBreak;
      float firstLineMinWidth, lastLineMinWidth;
      bool hasBreakableStart, hasBreakableEnd;
      float firstLineMaxWidth, lastLineMaxWidth;
      t->trimmedPrefWidths(inlineMax, firstLineMinWidth, hasBreakableStart,
                           lastLineMinWidth, hasBreakableEnd, hasBreakableChar,
                           hasBreak, firstLineMaxWidth, lastLineMaxWidth,
                           childMin, childMax, stripFrontSpaces,
                           styleToUse->direction());

      // This text object will not be rendered, but it may still provide a
      // breaking opportunity.
      if (!hasBreak && !childMax) {
        if (autoWrap && (hasBreakableStart || hasBreakableEnd)) {
          updatePreferredWidth(minLogicalWidth, inlineMin);
          inlineMin = 0;
        }
        continue;
      }

      if (stripFrontSpaces)
        trailingSpaceChild = child;
      else
        trailingSpaceChild = 0;

      // Add in text-indent. This is added in only once.
      float ti = 0;
      if (!addedTextIndent || hasRemainingNegativeTextIndent) {
        ti = textIndent.ceilToFloat();
        childMin += ti;
        firstLineMinWidth += ti;

        // It the text indent negative and larger than the child minimum, we
        // re-use the remainder in future minimum calculations, but using the
        // negative value again on the maximum will lead to under-counting the
        // max pref width.
        if (!addedTextIndent) {
          childMax += ti;
          firstLineMaxWidth += ti;
          addedTextIndent = true;
        }

        if (childMin < 0) {
          textIndent = childMin;
          hasRemainingNegativeTextIndent = true;
        }
      }

      // If we have no breakable characters at all,
      // then this is the easy case. We add ourselves to the current
      // min and max and continue.
      if (!hasBreakableChar) {
        inlineMin += childMin;
      } else {
        if (hasBreakableStart) {
          updatePreferredWidth(minLogicalWidth, inlineMin);
        } else {
          inlineMin += firstLineMinWidth;
          updatePreferredWidth(minLogicalWidth, inlineMin);
          childMin -= ti;
        }

        inlineMin = childMin;

        if (hasBreakableEnd) {
          updatePreferredWidth(minLogicalWidth, inlineMin);
          inlineMin = 0;
          shouldBreakLineAfterText = false;
        } else {
          updatePreferredWidth(minLogicalWidth, inlineMin);
          inlineMin = lastLineMinWidth;
          shouldBreakLineAfterText = true;
        }
      }

      if (hasBreak) {
        inlineMax += firstLineMaxWidth;
        updatePreferredWidth(maxLogicalWidth, inlineMax);
        updatePreferredWidth(maxLogicalWidth, childMax);
        inlineMax = lastLineMaxWidth;
        addedTextIndent = true;
      } else {
        inlineMax += std::max<float>(0, childMax);
      }
    }

    if (!child->isText() && child->isRenderInline())
      isPrevChildInlineFlow = true;
    else
      isPrevChildInlineFlow = false;

    oldAutoWrap = autoWrap;
  }

  if (styleToUse->collapseWhiteSpace())
    stripTrailingSpace(inlineMax, inlineMin, trailingSpaceChild);

  updatePreferredWidth(minLogicalWidth, inlineMin);
  updatePreferredWidth(maxLogicalWidth, inlineMax);

  maxLogicalWidth = std::max(minLogicalWidth, maxLogicalWidth);
}

int RenderParagraph::firstLineBoxBaseline(
    FontBaselineOrAuto baselineType) const {
  if (!firstLineBox())
    return -1;
  FontBaseline baseline;
  if (baselineType.m_auto)
    baseline = firstRootBox()->baselineType();
  else
    baseline = baselineType.m_baseline;
  return firstLineBox()->logicalTop() +
         style(true)->fontMetrics().ascent(baseline);
}

int RenderParagraph::lastLineBoxBaseline(
    LineDirectionMode lineDirection) const {
  if (!firstLineBox() && hasLineIfEmpty()) {
    const FontMetrics& fontMetrics = firstLineStyle()->fontMetrics();
    return fontMetrics.ascent() +
           (lineHeight(true, lineDirection, PositionOfInteriorLineBoxes) -
            fontMetrics.height()) /
               2 +
           (lineDirection == HorizontalLine ? borderTop() + paddingTop()
                                            : borderRight() + paddingRight());
  }
  if (lastLineBox())
    return lastLineBox()->logicalTop() +
           style(lastLineBox() == firstLineBox())
               ->fontMetrics()
               .ascent(lastRootBox()->baselineType());
  return -1;
}

void RenderParagraph::layout() {
  ASSERT(needsLayout());
  ASSERT(isInlineBlock() || !isInline());

  if (simplifiedLayout())
    return;

  SubtreeLayoutScope layoutScope(*this);

  LayoutUnit oldLeft = logicalLeft();
  bool logicalWidthChanged = updateLogicalWidthAndColumnWidth();
  bool relayoutChildren = logicalWidthChanged;

  LayoutUnit beforeEdge = borderBefore() + paddingBefore();
  LayoutUnit afterEdge = borderAfter() + paddingAfter();
  LayoutUnit previousHeight = logicalHeight();
  setLogicalHeight(beforeEdge);

  layoutChildren(relayoutChildren, layoutScope, beforeEdge, afterEdge);

  LayoutUnit oldClientAfterEdge = clientLogicalBottom();

  updateLogicalHeight();

  if (previousHeight != logicalHeight())
    relayoutChildren = true;

  layoutPositionedObjects(relayoutChildren,
                          oldLeft != logicalLeft()
                              ? ForcedLayoutAfterContainingBlockMoved
                              : DefaultLayout);

  // Add overflow from children (unless we're multi-column, since in that case
  // all our child overflow is clipped anyway).
  computeOverflow(oldClientAfterEdge);

  updateLayerTransformAfterLayout();

  clearNeedsLayout();
}

void RenderParagraph::layoutChildren(bool relayoutChildren,
                                     SubtreeLayoutScope& layoutScope,
                                     LayoutUnit beforeEdge,
                                     LayoutUnit afterEdge) {
  // Figure out if we should clear out our line boxes.
  // FIXME: Handle resize eventually!
  bool isFullLayout = !firstLineBox() || selfNeedsLayout() || relayoutChildren;
  LineLayoutState layoutState(isFullLayout);

  if (isFullLayout)
    lineBoxes()->deleteLineBoxes();

  if (firstChild()) {
    // In full layout mode, clear the line boxes of children upfront. Otherwise,
    // siblings can run into stale root lineboxes during layout. Then layout
    // the replaced elements later. In partial layout mode, line boxes are not
    // deleted and only dirtied. In that case, we can layout the replaced
    // elements at the same time.
    Vector<RenderBox*> replacedChildren;
    for (InlineWalker walker(this); !walker.atEnd(); walker.advance()) {
      RenderObject* o = walker.current();

      if (!layoutState.hasInlineChild() && o->isInline())
        layoutState.setHasInlineChild(true);

      if (o->isReplaced() || o->isOutOfFlowPositioned()) {
        RenderBox* box = toRenderBox(o);

        updateBlockChildDirtyBitsBeforeLayout(relayoutChildren, box);

        if (o->isOutOfFlowPositioned()) {
          o->containingBlock()->insertPositionedObject(box);
        } else if (isFullLayout || o->needsLayout()) {
          // Replaced element.
          box->dirtyLineBoxes(isFullLayout);
          if (isFullLayout)
            replacedChildren.append(box);
          else
            o->layoutIfNeeded();
        }
      } else if (o->isText() ||
                 (o->isRenderInline() && !walker.atEndOfInline())) {
        if (!o->isText())
          toRenderInline(o)->updateAlwaysCreateLineBoxes(
              layoutState.isFullLayout());
        if (layoutState.isFullLayout() || o->selfNeedsLayout())
          dirtyLineBoxesForRenderer(o, layoutState.isFullLayout());
        o->clearNeedsLayout();
      }
    }

    for (size_t i = 0; i < replacedChildren.size(); i++)
      replacedChildren[i]->layoutIfNeeded();

    layoutRunsAndFloats(layoutState);
  }

  // Expand the last line to accommodate Ruby and emphasis marks.
  int lastLineAnnotationsAdjustment = 0;
  if (lastRootBox()) {
    LayoutUnit lowestAllowedPosition =
        std::max(lastRootBox()->lineBottom(), logicalHeight() + paddingAfter());
    lastLineAnnotationsAdjustment =
        lastRootBox()->computeUnderAnnotationAdjustment(lowestAllowedPosition);
  }

  // Now add in the bottom border/padding.
  setLogicalHeight(logicalHeight() + lastLineAnnotationsAdjustment + afterEdge);

  if (!firstLineBox() && hasLineIfEmpty())
    setLogicalHeight(logicalHeight() + lineHeight(true, HorizontalLine,
                                                  PositionOfInteriorLineBoxes));
}

RootInlineBox* RenderParagraph::determineStartPosition(
    LineLayoutState& layoutState,
    InlineBidiResolver& resolver) {
  RootInlineBox* curr = 0;
  RootInlineBox* last = 0;

  if (layoutState.isFullLayout()) {
    // If we encountered a new float and have inline children, mark ourself to
    // force us to issue paint invalidations.
    if (layoutState.hasInlineChild() && !selfNeedsLayout()) {
      setNeedsLayout(MarkOnlyThis);
    }

    // FIXME: This should just call deleteLineBoxTree, but that causes
    // crashes for fast/repaint tests.
    curr = firstRootBox();
    while (curr) {
      // Note: This uses nextRootBox() insted of nextLineBox() like
      // deleteLineBoxTree does.
      RootInlineBox* next = curr->nextRootBox();
      curr->deleteLine();
      curr = next;
    }
    ASSERT(!firstLineBox() && !lastLineBox());
  } else {
    if (curr) {
      // We have a dirty line.
      if (RootInlineBox* prevRootBox = curr->prevRootBox()) {
        // We have a previous line.
        if (!prevRootBox->endsWithBreak() || !prevRootBox->lineBreakObj() ||
            (prevRootBox->lineBreakObj()->isText() &&
             prevRootBox->lineBreakPos() >=
                 toRenderText(prevRootBox->lineBreakObj())->textLength()))
          // The previous line didn't break cleanly or broke at a newline
          // that has been deleted, so treat it as dirty too.
          curr = prevRootBox;
      }
    } else {
      // No dirty lines were found.
      // If the last line didn't break cleanly, treat it as dirty.
      if (lastRootBox() && !lastRootBox()->endsWithBreak())
        curr = lastRootBox();
    }

    // If we have no dirty lines, then last is just the last root box.
    last = curr ? curr->prevRootBox() : lastRootBox();
  }

  layoutState.lineInfo().setFirstLine(!last);
  layoutState.lineInfo().setPreviousLineBrokeCleanly(!last ||
                                                     last->endsWithBreak());

  if (last) {
    setLogicalHeight(last->lineBottomWithLeading());
    InlineIterator iter =
        InlineIterator(this, last->lineBreakObj(), last->lineBreakPos());
    resolver.setPosition(iter, numberOfIsolateAncestors(iter));
    resolver.setStatus(last->lineBreakBidiStatus());
  } else {
    TextDirection direction = style()->direction();
    if (style()->unicodeBidi() == Plaintext)
      direction = determinePlaintextDirectionality(this);
    resolver.setStatus(
        BidiStatus(direction, isOverride(style()->unicodeBidi())));
    InlineIterator iter = InlineIterator(
        this, bidiFirstSkippingEmptyInlines(this, resolver.runs(), &resolver),
        0);
    resolver.setPosition(iter, numberOfIsolateAncestors(iter));
  }
  return curr;
}

void RenderParagraph::determineEndPosition(LineLayoutState& layoutState,
                                           RootInlineBox* startLine,
                                           InlineIterator& cleanLineStart,
                                           BidiStatus& cleanLineBidiStatus) {
  ASSERT(!layoutState.endLine());
  RootInlineBox* last = 0;
  for (RootInlineBox* curr = startLine->nextRootBox(); curr;
       curr = curr->nextRootBox()) {
    if (curr->isDirty())
      last = 0;
    else if (!last)
      last = curr;
  }

  if (!last)
    return;

  // At this point, |last| is the first line in a run of clean lines that ends
  // with the last line in the block.

  RootInlineBox* prev = last->prevRootBox();
  cleanLineStart =
      InlineIterator(this, prev->lineBreakObj(), prev->lineBreakPos());
  cleanLineBidiStatus = prev->lineBreakBidiStatus();
  layoutState.setEndLineLogicalTop(prev->lineBottomWithLeading());

  for (RootInlineBox* line = last; line; line = line->nextRootBox())
    line->extractLine();  // Disconnect all line boxes from their render objects
                          // while preserving their connections to one another.

  layoutState.setEndLine(last);
}

bool RenderParagraph::checkPaginationAndFloatsAtEndLine(
    LineLayoutState& layoutState) {
  // FIXME(sky): Remove this.
  return true;
}

bool RenderParagraph::matchedEndLine(LineLayoutState& layoutState,
                                     const InlineBidiResolver& resolver,
                                     const InlineIterator& endLineStart,
                                     const BidiStatus& endLineStatus) {
  if (resolver.position() == endLineStart) {
    if (resolver.status() != endLineStatus)
      return false;
    return checkPaginationAndFloatsAtEndLine(layoutState);
  }

  // The first clean line doesn't match, but we can check a handful of following
  // lines to try to match back up.
  static int numLines = 8;  // The # of lines we're willing to match against.
  RootInlineBox* originalEndLine = layoutState.endLine();
  RootInlineBox* line = originalEndLine;
  for (int i = 0; i < numLines && line; i++, line = line->nextRootBox()) {
    if (line->lineBreakObj() == resolver.position().object() &&
        line->lineBreakPos() == resolver.position().offset()) {
      // We have a match.
      if (line->lineBreakBidiStatus() != resolver.status())
        return false;  // ...but the bidi state doesn't match.

      bool matched = false;
      RootInlineBox* result = line->nextRootBox();
      layoutState.setEndLine(result);
      if (result) {
        layoutState.setEndLineLogicalTop(line->lineBottomWithLeading());
        matched = checkPaginationAndFloatsAtEndLine(layoutState);
      }

      // Now delete the lines that we failed to sync.
      deleteLineRange(layoutState, originalEndLine, result);
      return matched;
    }
  }

  return false;
}

}  // namespace blink
