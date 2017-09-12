/*
 * Copyright (C) 2003, 2006, 2008 Apple Inc. All rights reserved.
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

#include "flutter/sky/engine/core/rendering/RootInlineBox.h"

#include "flutter/sky/engine/core/rendering/HitTestResult.h"
#include "flutter/sky/engine/core/rendering/InlineTextBox.h"
#include "flutter/sky/engine/core/rendering/PaintInfo.h"
#include "flutter/sky/engine/core/rendering/RenderInline.h"
#include "flutter/sky/engine/core/rendering/RenderParagraph.h"
#include "flutter/sky/engine/core/rendering/RenderView.h"
#include "flutter/sky/engine/core/rendering/VerticalPositionCache.h"
#include "flutter/sky/engine/platform/text/BidiResolver.h"
#include "flutter/sky/engine/wtf/unicode/Unicode.h"

namespace blink {

struct SameSizeAsRootInlineBox : public InlineFlowBox {
  unsigned unsignedVariable;
  void* pointers[2];
  LayoutUnit layoutVariables[5];
};

COMPILE_ASSERT(sizeof(RootInlineBox) == sizeof(SameSizeAsRootInlineBox),
               RootInlineBox_should_stay_small);

RootInlineBox::RootInlineBox(RenderParagraph& block)
    : InlineFlowBox(block),
      m_lineBreakPos(0),
      m_lineBreakObj(0),
      m_lineTop(0),
      m_lineBottom(0),
      m_lineTopWithLeading(0),
      m_lineBottomWithLeading(0),
      m_selectionBottom(0) {}

void RootInlineBox::destroy() {
  InlineFlowBox::destroy();
}

RenderLineBoxList* RootInlineBox::rendererLineBoxes() const {
  return block().lineBoxes();
}

void RootInlineBox::clearTruncation() {}

int RootInlineBox::baselinePosition(FontBaseline baselineType) const {
  return boxModelObject()->baselinePosition(baselineType, isFirstLineStyle(),
                                            HorizontalLine,
                                            PositionOfInteriorLineBoxes);
}

LayoutUnit RootInlineBox::lineHeight() const {
  return boxModelObject()->lineHeight(isFirstLineStyle(), HorizontalLine,
                                      PositionOfInteriorLineBoxes);
}

void RootInlineBox::paint(PaintInfo& paintInfo,
                          const LayoutPoint& paintOffset,
                          LayoutUnit lineTop,
                          LayoutUnit lineBottom,
                          Vector<RenderBox*>& layers) {
  InlineFlowBox::paint(paintInfo, paintOffset, lineTop, lineBottom, layers);
}

bool RootInlineBox::nodeAtPoint(const HitTestRequest& request,
                                HitTestResult& result,
                                const HitTestLocation& locationInContainer,
                                const LayoutPoint& accumulatedOffset,
                                LayoutUnit lineTop,
                                LayoutUnit lineBottom) {
  return InlineFlowBox::nodeAtPoint(request, result, locationInContainer,
                                    accumulatedOffset, lineTop, lineBottom);
}

void RootInlineBox::adjustPosition(float dx, float dy) {
  InlineFlowBox::adjustPosition(dx, dy);
  LayoutUnit blockDirectionDelta =
      dy;  // The block direction delta is a LayoutUnit.
  m_lineTop += blockDirectionDelta;
  m_lineBottom += blockDirectionDelta;
  m_lineTopWithLeading += blockDirectionDelta;
  m_lineBottomWithLeading += blockDirectionDelta;
  m_selectionBottom += blockDirectionDelta;
}

void RootInlineBox::childRemoved(InlineBox* box) {
  if (&box->renderer() == m_lineBreakObj)
    setLineBreakInfo(0, 0, BidiStatus());

  for (RootInlineBox* prev = prevRootBox();
       prev && prev->lineBreakObj() == &box->renderer();
       prev = prev->prevRootBox()) {
    prev->setLineBreakInfo(0, 0, BidiStatus());
    prev->markDirty();
  }
}

LayoutUnit RootInlineBox::alignBoxesInBlockDirection(
    LayoutUnit heightOfBlock,
    GlyphOverflowAndFallbackFontsMap& textBoxDataMap,
    VerticalPositionCache& verticalPositionCache) {
  // SVG will handle vertical alignment on its own.
  if (isSVGRootInlineBox())
    return 0;

  LayoutUnit maxPositionTop = 0;
  LayoutUnit maxPositionBottom = 0;
  int maxAscent = 0;
  int maxDescent = 0;
  bool setMaxAscent = false;
  bool setMaxDescent = false;

  m_baselineType = AlphabeticBaseline;

  computeLogicalBoxHeights(this, maxPositionTop, maxPositionBottom, maxAscent,
                           maxDescent, setMaxAscent, setMaxDescent, true,
                           textBoxDataMap, baselineType(),
                           verticalPositionCache);

  if (maxAscent + maxDescent < std::max(maxPositionTop, maxPositionBottom))
    adjustMaxAscentAndDescent(maxAscent, maxDescent, maxPositionTop,
                              maxPositionBottom);

  LayoutUnit maxHeight = maxAscent + maxDescent;
  LayoutUnit lineTop = heightOfBlock;
  LayoutUnit lineBottom = heightOfBlock;
  LayoutUnit lineTopIncludingMargins = heightOfBlock;
  LayoutUnit lineBottomIncludingMargins = heightOfBlock;
  LayoutUnit selectionBottom = heightOfBlock;
  bool setLineTop = false;
  bool hasAnnotationsBefore = false;
  bool hasAnnotationsAfter = false;
  placeBoxesInBlockDirection(heightOfBlock, maxHeight, maxAscent, true, lineTop,
                             lineBottom, selectionBottom, setLineTop,
                             lineTopIncludingMargins,
                             lineBottomIncludingMargins, hasAnnotationsBefore,
                             hasAnnotationsAfter, baselineType());
  m_hasAnnotationsBefore = hasAnnotationsBefore;
  m_hasAnnotationsAfter = hasAnnotationsAfter;

  maxHeight =
      std::max<LayoutUnit>(0, maxHeight);  // FIXME: Is this really necessary?

  setLineTopBottomPositions(lineTop, lineBottom, heightOfBlock,
                            heightOfBlock + maxHeight, selectionBottom);

  LayoutUnit annotationsAdjustment = beforeAnnotationsAdjustment();
  if (annotationsAdjustment) {
    // FIXME: Need to handle pagination here. We might have to move to the next
    // page/column as a result of the ruby expansion.
    adjustBlockDirectionPosition(annotationsAdjustment.toFloat());
    heightOfBlock += annotationsAdjustment;
  }

  return heightOfBlock + maxHeight;
}

float RootInlineBox::maxLogicalTop() const {
  float maxLogicalTop = 0;
  computeMaxLogicalTop(maxLogicalTop);
  return maxLogicalTop;
}

LayoutUnit RootInlineBox::beforeAnnotationsAdjustment() const {
  LayoutUnit result = 0;

  // Annotations under the previous line may push us down.
  if (prevRootBox() && prevRootBox()->hasAnnotationsAfter())
    result = prevRootBox()->computeUnderAnnotationAdjustment(lineTop());

  if (!hasAnnotationsBefore())
    return result;

  // Annotations over this line may push us further down.
  LayoutUnit highestAllowedPosition =
      prevRootBox() ? std::min(prevRootBox()->lineBottom(), lineTop()) + result
                    : static_cast<LayoutUnit>(block().borderBefore());
  result = computeOverAnnotationAdjustment(highestAllowedPosition);

  return result;
}

GapRects RootInlineBox::lineSelectionGap(
    RenderBlock* rootBlock,
    const LayoutPoint& rootBlockPhysicalPosition,
    const LayoutSize& offsetFromRootBlock,
    LayoutUnit selTop,
    LayoutUnit selHeight,
    const PaintInfo* paintInfo) {
  RenderObject::SelectionState lineState = selectionState();

  bool leftGap, rightGap;
  block().getSelectionGapInfo(lineState, leftGap, rightGap);

  GapRects result;

  InlineBox* firstBox = firstSelectedBox();
  InlineBox* lastBox = lastSelectedBox();
  if (leftGap) {
    result.uniteLeft(block().logicalLeftSelectionGap(
        rootBlock, rootBlockPhysicalPosition, offsetFromRootBlock,
        &firstBox->parent()->renderer(), firstBox->logicalLeft(), selTop,
        selHeight, paintInfo));
  }
  if (rightGap) {
    result.uniteRight(block().logicalRightSelectionGap(
        rootBlock, rootBlockPhysicalPosition, offsetFromRootBlock,
        &lastBox->parent()->renderer(), lastBox->logicalRight(), selTop,
        selHeight, paintInfo));
  }

  // When dealing with bidi text, a non-contiguous selection region is possible.
  // e.g. The logical text aaaAAAbbb (capitals denote RTL text and non-capitals
  // LTR) is layed out visually as 3 text runs |aaa|bbb|AAA| if we select 4
  // characters from the start of the text the selection will look like
  // (underline denotes selection): |aaa|bbb|AAA|
  //  ___       _
  // We can see that the |bbb| run is not part of the selection while the runs
  // around it are.
  if (firstBox && firstBox != lastBox) {
    // Now fill in any gaps on the line that occurred between two selected
    // elements.
    LayoutUnit lastLogicalLeft = firstBox->logicalRight();
    bool isPreviousBoxSelected =
        firstBox->selectionState() != RenderObject::SelectionNone;
    for (InlineBox* box = firstBox->nextLeafChild(); box;
         box = box->nextLeafChild()) {
      if (box->selectionState() != RenderObject::SelectionNone) {
        LayoutRect logicalRect(lastLogicalLeft, selTop,
                               box->logicalLeft() - lastLogicalLeft, selHeight);
        logicalRect.move(offsetFromRootBlock);
        LayoutRect gapRect = rootBlock->logicalRectToPhysicalRect(
            rootBlockPhysicalPosition, logicalRect);
        if (isPreviousBoxSelected && gapRect.width() > 0 &&
            gapRect.height() > 0) {
          if (paintInfo)
            paintInfo->context->fillRect(
                gapRect, box->parent()->renderer().selectionBackgroundColor());
          // VisibleSelection may be non-contiguous, see comment above.
          result.uniteCenter(gapRect);
        }
        lastLogicalLeft = box->logicalRight();
      }
      if (box == lastBox)
        break;
      isPreviousBoxSelected =
          box->selectionState() != RenderObject::SelectionNone;
    }
  }

  return result;
}

RenderObject::SelectionState RootInlineBox::selectionState() {
  // Walk over all of the selected boxes.
  RenderObject::SelectionState state = RenderObject::SelectionNone;
  for (InlineBox* box = firstLeafChild(); box; box = box->nextLeafChild()) {
    RenderObject::SelectionState boxState = box->selectionState();
    if ((boxState == RenderObject::SelectionStart &&
         state == RenderObject::SelectionEnd) ||
        (boxState == RenderObject::SelectionEnd &&
         state == RenderObject::SelectionStart))
      state = RenderObject::SelectionBoth;
    else if (state == RenderObject::SelectionNone ||
             ((boxState == RenderObject::SelectionStart ||
               boxState == RenderObject::SelectionEnd) &&
              (state == RenderObject::SelectionNone ||
               state == RenderObject::SelectionInside)))
      state = boxState;
    else if (boxState == RenderObject::SelectionNone &&
             state == RenderObject::SelectionStart) {
      // We are past the end of the selection.
      state = RenderObject::SelectionBoth;
    }
    if (state == RenderObject::SelectionBoth)
      break;
  }

  return state;
}

InlineBox* RootInlineBox::firstSelectedBox() {
  for (InlineBox* box = firstLeafChild(); box; box = box->nextLeafChild()) {
    if (box->selectionState() != RenderObject::SelectionNone)
      return box;
  }

  return 0;
}

InlineBox* RootInlineBox::lastSelectedBox() {
  for (InlineBox* box = lastLeafChild(); box; box = box->prevLeafChild()) {
    if (box->selectionState() != RenderObject::SelectionNone)
      return box;
  }

  return 0;
}

LayoutUnit RootInlineBox::selectionTop() const {
  LayoutUnit selectionTop = m_lineTop;

  if (m_hasAnnotationsBefore)
    selectionTop -= computeOverAnnotationAdjustment(m_lineTop);

  if (!prevRootBox())
    return selectionTop;

  return prevRootBox()->selectionBottom();
}

LayoutUnit RootInlineBox::selectionTopAdjustedForPrecedingBlock() const {
  LayoutUnit top = selectionTop();

  RenderObject::SelectionState blockSelectionState =
      root().block().selectionState();
  if (blockSelectionState != RenderObject::SelectionInside &&
      blockSelectionState != RenderObject::SelectionEnd)
    return top;

  LayoutSize offsetToBlockBefore;
  if (RenderBlock* block =
          root().block().blockBeforeWithinSelectionRoot(offsetToBlockBefore)) {
    if (block->isRenderParagraph()) {
      if (RootInlineBox* lastLine = toRenderParagraph(block)->lastRootBox()) {
        RenderObject::SelectionState lastLineSelectionState =
            lastLine->selectionState();
        if (lastLineSelectionState != RenderObject::SelectionInside &&
            lastLineSelectionState != RenderObject::SelectionStart)
          return top;

        LayoutUnit lastLineSelectionBottom =
            lastLine->selectionBottom() + offsetToBlockBefore.height();
        top = std::max(top, lastLineSelectionBottom);
      }
    }
  }

  return top;
}

LayoutUnit RootInlineBox::selectionBottom() const {
  LayoutUnit selectionBottom = m_selectionBottom;
  if (m_hasAnnotationsAfter)
    selectionBottom += computeUnderAnnotationAdjustment(m_lineBottom);
  return selectionBottom;
}

int RootInlineBox::blockDirectionPointInLine() const {
  return std::max(lineTop(), selectionTop());
}

RenderParagraph& RootInlineBox::block() const {
  return toRenderParagraph(renderer());
}

static bool isEditableLeaf(InlineBox* leaf) {
  return false;
}

InlineBox* RootInlineBox::closestLeafChildForPoint(
    const IntPoint& pointInContents,
    bool onlyEditableLeaves) {
  return closestLeafChildForLogicalLeftPosition(pointInContents.x(),
                                                onlyEditableLeaves);
}

InlineBox* RootInlineBox::closestLeafChildForLogicalLeftPosition(
    int leftPosition,
    bool onlyEditableLeaves) {
  InlineBox* firstLeaf = firstLeafChild();
  InlineBox* lastLeaf = lastLeafChild();

  if (firstLeaf != lastLeaf) {
    if (firstLeaf->isLineBreak())
      firstLeaf = firstLeaf->nextLeafChildIgnoringLineBreak();
    else if (lastLeaf->isLineBreak())
      lastLeaf = lastLeaf->prevLeafChildIgnoringLineBreak();
  }

  if (firstLeaf == lastLeaf &&
      (!onlyEditableLeaves || isEditableLeaf(firstLeaf)))
    return firstLeaf;

  // Avoid returning a list marker when possible.
  if (leftPosition <= firstLeaf->logicalLeft() &&
      (!onlyEditableLeaves || isEditableLeaf(firstLeaf)))
    // The leftPosition coordinate is less or equal to left edge of the
    // firstLeaf. Return it.
    return firstLeaf;

  if (leftPosition >= lastLeaf->logicalRight() &&
      (!onlyEditableLeaves || isEditableLeaf(lastLeaf)))
    // The leftPosition coordinate is greater or equal to right edge of the
    // lastLeaf. Return it.
    return lastLeaf;

  InlineBox* closestLeaf = 0;
  for (InlineBox* leaf = firstLeaf; leaf;
       leaf = leaf->nextLeafChildIgnoringLineBreak()) {
    if (!onlyEditableLeaves || isEditableLeaf(leaf)) {
      closestLeaf = leaf;
      if (leftPosition < leaf->logicalRight())
        // The x coordinate is less than the right edge of the box.
        // Return it.
        return leaf;
    }
  }

  return closestLeaf ? closestLeaf : lastLeaf;
}

BidiStatus RootInlineBox::lineBreakBidiStatus() const {
  return BidiStatus(
      static_cast<WTF::Unicode::Direction>(m_lineBreakBidiStatusEor),
      static_cast<WTF::Unicode::Direction>(m_lineBreakBidiStatusLastStrong),
      static_cast<WTF::Unicode::Direction>(m_lineBreakBidiStatusLast),
      m_lineBreakContext);
}

void RootInlineBox::setLineBreakInfo(RenderObject* obj,
                                     unsigned breakPos,
                                     const BidiStatus& status) {
  // When setting lineBreakObj, the RenderObject must not be a RenderInline
  // with no line boxes, otherwise all sorts of invariants are broken later.
  // This has security implications because if the RenderObject does not
  // point to at least one line box, then that RenderInline can be deleted
  // later without resetting the lineBreakObj, leading to use-after-free.
  ASSERT_WITH_SECURITY_IMPLICATION(!obj || obj->isText() ||
                                   !(obj->isRenderInline() && obj->isBox() &&
                                     !toRenderBox(obj)->inlineBoxWrapper()));

  m_lineBreakObj = obj;
  m_lineBreakPos = breakPos;
  m_lineBreakBidiStatusEor = status.eor;
  m_lineBreakBidiStatusLastStrong = status.lastStrong;
  m_lineBreakBidiStatusLast = status.last;
  m_lineBreakContext = status.context;
}

void RootInlineBox::removeLineBoxFromRenderObject() {
  block().lineBoxes()->removeLineBox(this);
}

void RootInlineBox::extractLineBoxFromRenderObject() {
  block().lineBoxes()->extractLineBox(this);
}

void RootInlineBox::attachLineBoxToRenderObject() {
  block().lineBoxes()->attachLineBox(this);
}

LayoutRect RootInlineBox::paddedLayoutOverflowRect(
    LayoutUnit endPadding) const {
  LayoutRect lineLayoutOverflow = layoutOverflowRect(lineTop(), lineBottom());
  if (!endPadding)
    return lineLayoutOverflow;

  if (isLeftToRightDirection())
    lineLayoutOverflow.shiftMaxXEdgeTo(std::max<LayoutUnit>(
        lineLayoutOverflow.maxX(), logicalRight() + endPadding));
  else
    lineLayoutOverflow.shiftXEdgeTo(std::min<LayoutUnit>(
        lineLayoutOverflow.x(), logicalLeft() - endPadding));

  return lineLayoutOverflow;
}

static void setAscentAndDescent(int& ascent,
                                int& descent,
                                int newAscent,
                                int newDescent,
                                bool& ascentDescentSet) {
  if (!ascentDescentSet) {
    ascentDescentSet = true;
    ascent = newAscent;
    descent = newDescent;
  } else {
    ascent = std::max(ascent, newAscent);
    descent = std::max(descent, newDescent);
  }
}

void RootInlineBox::ascentAndDescentForBox(
    InlineBox* box,
    GlyphOverflowAndFallbackFontsMap& textBoxDataMap,
    int& ascent,
    int& descent,
    bool& affectsAscent,
    bool& affectsDescent) const {
  bool ascentDescentSet = false;

  // Replaced boxes will return 0 for the line-height if line-box-contain says
  // they are not to be included.
  if (box->renderer().isReplaced()) {
    if (renderer().style(isFirstLineStyle())->lineBoxContain() &
        LineBoxContainReplaced) {
      ascent = box->baselinePosition(baselineType());
      descent = box->lineHeight() - ascent;

      // Replaced elements always affect both the ascent and descent.
      affectsAscent = true;
      affectsDescent = true;
    }
    return;
  }

  Vector<const SimpleFontData*>* usedFonts = 0;
  GlyphOverflow* glyphOverflow = 0;
  if (box->isText()) {
    GlyphOverflowAndFallbackFontsMap::iterator it =
        textBoxDataMap.find(toInlineTextBox(box));
    usedFonts = it == textBoxDataMap.end() ? 0 : &it->value.first;
    glyphOverflow = it == textBoxDataMap.end() ? 0 : &it->value.second;
  }

  bool includeLeading = includeLeadingForBox(box);
  bool includeFont = includeFontForBox(box);

  bool setUsedFont = false;
  bool setUsedFontWithLeading = false;

  if (usedFonts && !usedFonts->isEmpty() &&
      (includeFont ||
       (box->renderer().style(isFirstLineStyle())->lineHeight().isNegative() &&
        includeLeading))) {
    usedFonts->append(
        box->renderer().style(isFirstLineStyle())->font().primaryFont());
    for (size_t i = 0; i < usedFonts->size(); ++i) {
      const FontMetrics& fontMetrics = usedFonts->at(i)->fontMetrics();
      int usedFontAscent = fontMetrics.ascent(baselineType());
      int usedFontDescent = fontMetrics.descent(baselineType());
      int halfLeading = (fontMetrics.lineSpacing() - fontMetrics.height()) / 2;
      int usedFontAscentAndLeading = usedFontAscent + halfLeading;
      int usedFontDescentAndLeading =
          fontMetrics.lineSpacing() - usedFontAscentAndLeading;
      if (includeFont) {
        setAscentAndDescent(ascent, descent, usedFontAscent, usedFontDescent,
                            ascentDescentSet);
        setUsedFont = true;
      }
      if (includeLeading) {
        setAscentAndDescent(ascent, descent, usedFontAscentAndLeading,
                            usedFontDescentAndLeading, ascentDescentSet);
        setUsedFontWithLeading = true;
      }
      if (!affectsAscent)
        affectsAscent = usedFontAscent - box->logicalTop() > 0;
      if (!affectsDescent)
        affectsDescent = usedFontDescent + box->logicalTop() > 0;
    }
  }

  // If leading is included for the box, then we compute that box.
  if (includeLeading && !setUsedFontWithLeading) {
    int ascentWithLeading = box->baselinePosition(baselineType());
    int descentWithLeading = box->lineHeight() - ascentWithLeading;
    setAscentAndDescent(ascent, descent, ascentWithLeading, descentWithLeading,
                        ascentDescentSet);

    // Examine the font box for inline flows and text boxes to see if any part
    // of it is above the baseline. If the top of our font box relative to the
    // root box baseline is above the root box baseline, then we are
    // contributing to the maxAscent value. Descent is similar. If any part of
    // our font box is below the root box's baseline, then we contribute to the
    // maxDescent value.
    affectsAscent = ascentWithLeading - box->logicalTop() > 0;
    affectsDescent = descentWithLeading + box->logicalTop() > 0;
  }

  if (includeFontForBox(box) && !setUsedFont) {
    int fontAscent = box->renderer()
                         .style(isFirstLineStyle())
                         ->fontMetrics()
                         .ascent(baselineType());
    int fontDescent = box->renderer()
                          .style(isFirstLineStyle())
                          ->fontMetrics()
                          .descent(baselineType());
    setAscentAndDescent(ascent, descent, fontAscent, fontDescent,
                        ascentDescentSet);
    affectsAscent = fontAscent - box->logicalTop() > 0;
    affectsDescent = fontDescent + box->logicalTop() > 0;
  }

  if (includeGlyphsForBox(box) && glyphOverflow &&
      glyphOverflow->computeBounds) {
    setAscentAndDescent(ascent, descent, glyphOverflow->top,
                        glyphOverflow->bottom, ascentDescentSet);
    affectsAscent = glyphOverflow->top - box->logicalTop() > 0;
    affectsDescent = glyphOverflow->bottom + box->logicalTop() > 0;
    glyphOverflow->top =
        std::min(glyphOverflow->top,
                 std::max(0, glyphOverflow->top - box->renderer()
                                                      .style(isFirstLineStyle())
                                                      ->fontMetrics()
                                                      .ascent(baselineType())));
    glyphOverflow->bottom = std::min(
        glyphOverflow->bottom,
        std::max(0, glyphOverflow->bottom - box->renderer()
                                                .style(isFirstLineStyle())
                                                ->fontMetrics()
                                                .descent(baselineType())));
  }

  if (includeMarginForBox(box)) {
    LayoutUnit ascentWithMargin = box->renderer()
                                      .style(isFirstLineStyle())
                                      ->fontMetrics()
                                      .ascent(baselineType());
    LayoutUnit descentWithMargin = box->renderer()
                                       .style(isFirstLineStyle())
                                       ->fontMetrics()
                                       .descent(baselineType());
    if (box->parent() && !box->renderer().isText()) {
      ascentWithMargin += box->boxModelObject()->borderBefore() +
                          box->boxModelObject()->paddingBefore() +
                          box->boxModelObject()->marginBefore();
      descentWithMargin += box->boxModelObject()->borderAfter() +
                           box->boxModelObject()->paddingAfter() +
                           box->boxModelObject()->marginAfter();
    }
    setAscentAndDescent(ascent, descent, ascentWithMargin, descentWithMargin,
                        ascentDescentSet);

    // Treat like a replaced element, since we're using the margin box.
    affectsAscent = true;
    affectsDescent = true;
  }
}

LayoutUnit RootInlineBox::verticalPositionForBox(
    InlineBox* box,
    VerticalPositionCache& verticalPositionCache) {
  if (box->renderer().isText())
    return box->parent()->logicalTop();

  RenderBoxModelObject* renderer = box->boxModelObject();
  ASSERT(renderer->isInline());
  if (!renderer->isInline())
    return 0;

  bool firstLine = false;

  // Check the cache.
  bool isRenderInline = renderer->isRenderInline();
  if (isRenderInline && !firstLine) {
    LayoutUnit verticalPosition =
        verticalPositionCache.get(renderer, baselineType());
    if (verticalPosition != PositionUndefined)
      return verticalPosition;
  }

  LayoutUnit verticalPosition = 0;
  EVerticalAlign verticalAlign = renderer->style()->verticalAlign();
  if (verticalAlign == TOP || verticalAlign == BOTTOM)
    return 0;

  RenderObject* parent = renderer->parent();
  if (parent->isRenderInline() && parent->style()->verticalAlign() != TOP &&
      parent->style()->verticalAlign() != BOTTOM)
    verticalPosition = box->parent()->logicalTop();

  if (verticalAlign != BASELINE) {
    const Font& font = parent->style(firstLine)->font();
    const FontMetrics& fontMetrics = font.fontMetrics();
    int fontSize = font.fontDescription().computedPixelSize();

    LineDirectionMode lineDirection = HorizontalLine;

    if (verticalAlign == SUB)
      verticalPosition += fontSize / 5 + 1;
    else if (verticalAlign == SUPER)
      verticalPosition -= fontSize / 3 + 1;
    else if (verticalAlign == TEXT_TOP)
      verticalPosition +=
          renderer->baselinePosition(baselineType(), firstLine, lineDirection) -
          fontMetrics.ascent(baselineType());
    else if (verticalAlign == MIDDLE)
      verticalPosition =
          (verticalPosition -
           static_cast<LayoutUnit>(fontMetrics.xHeight() / 2) -
           renderer->lineHeight(firstLine, lineDirection) / 2 +
           renderer->baselinePosition(baselineType(), firstLine, lineDirection))
              .round();
    else if (verticalAlign == TEXT_BOTTOM) {
      verticalPosition += fontMetrics.descent(baselineType());
      // lineHeight - baselinePosition is always 0 for replaced elements (except
      // inline blocks), so don't bother wasting time in that case.
      if (!renderer->isReplaced() || renderer->isInlineBlock())
        verticalPosition -= (renderer->lineHeight(firstLine, lineDirection) -
                             renderer->baselinePosition(
                                 baselineType(), firstLine, lineDirection));
    } else if (verticalAlign == BASELINE_MIDDLE)
      verticalPosition +=
          -renderer->lineHeight(firstLine, lineDirection) / 2 +
          renderer->baselinePosition(baselineType(), firstLine, lineDirection);
    else if (verticalAlign == LENGTH) {
      LayoutUnit lineHeight;
      // Per http://www.w3.org/TR/CSS21/visudet.html#propdef-vertical-align:
      // 'Percentages: refer to the 'line-height' of the element itself'.
      if (renderer->style()->verticalAlignLength().isPercent())
        lineHeight = renderer->style()->computedLineHeight();
      else
        lineHeight = renderer->lineHeight(firstLine, lineDirection);
      verticalPosition -=
          valueForLength(renderer->style()->verticalAlignLength(), lineHeight);
    }
  }

  // Store the cached value.
  if (isRenderInline && !firstLine)
    verticalPositionCache.set(renderer, baselineType(), verticalPosition);

  return verticalPosition;
}

bool RootInlineBox::includeLeadingForBox(InlineBox* box) const {
  if (box->renderer().isReplaced() ||
      (box->renderer().isText() && !box->isText()))
    return false;

  LineBoxContain lineBoxContain = renderer().style()->lineBoxContain();
  return (lineBoxContain & LineBoxContainInline) ||
         (box == this && (lineBoxContain & LineBoxContainBlock));
}

bool RootInlineBox::includeFontForBox(InlineBox* box) const {
  if (box->renderer().isReplaced() ||
      (box->renderer().isText() && !box->isText()))
    return false;

  if (!box->isText() && box->isInlineFlowBox() &&
      !toInlineFlowBox(box)->hasTextChildren())
    return false;

  // For now map "glyphs" to "font" in vertical text mode until the bounds
  // returned by glyphs aren't garbage.
  LineBoxContain lineBoxContain = renderer().style()->lineBoxContain();
  return lineBoxContain & LineBoxContainFont;
}

bool RootInlineBox::includeGlyphsForBox(InlineBox* box) const {
  if (box->renderer().isReplaced() ||
      (box->renderer().isText() && !box->isText()))
    return false;

  if (!box->isText() && box->isInlineFlowBox() &&
      !toInlineFlowBox(box)->hasTextChildren())
    return false;

  // FIXME: We can't fit to glyphs yet for vertical text, since the bounds
  // returned are garbage.
  LineBoxContain lineBoxContain = renderer().style()->lineBoxContain();
  return lineBoxContain & LineBoxContainGlyphs;
}

bool RootInlineBox::includeMarginForBox(InlineBox* box) const {
  if (box->renderer().isReplaced() ||
      (box->renderer().isText() && !box->isText()))
    return false;

  LineBoxContain lineBoxContain = renderer().style()->lineBoxContain();
  return lineBoxContain & LineBoxContainInlineBox;
}

bool RootInlineBox::fitsToGlyphs() const {
  // FIXME: We can't fit to glyphs yet for vertical text, since the bounds
  // returned are garbage.
  LineBoxContain lineBoxContain = renderer().style()->lineBoxContain();
  return lineBoxContain & LineBoxContainGlyphs;
}

bool RootInlineBox::includesRootLineBoxFontOrLeading() const {
  LineBoxContain lineBoxContain = renderer().style()->lineBoxContain();
  return (lineBoxContain & LineBoxContainBlock) ||
         (lineBoxContain & LineBoxContainInline) ||
         (lineBoxContain & LineBoxContainFont);
}

#ifndef NDEBUG
const char* RootInlineBox::boxName() const {
  return "RootInlineBox";
}
#endif

}  // namespace blink
