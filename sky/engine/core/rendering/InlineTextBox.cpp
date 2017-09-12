/*
 * (C) 1999 Lars Knoll (knoll@kde.org)
 * (C) 2000 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011 Apple Inc. All
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
 *
 */

#include "flutter/sky/engine/core/rendering/InlineTextBox.h"

#include "flutter/sky/engine/core/editing/CompositionUnderline.h"
#include "flutter/sky/engine/core/editing/CompositionUnderlineRangeFilter.h"
#include "flutter/sky/engine/core/rendering/HitTestResult.h"
#include "flutter/sky/engine/core/rendering/PaintInfo.h"
#include "flutter/sky/engine/core/rendering/RenderBlock.h"
#include "flutter/sky/engine/core/rendering/RenderTheme.h"
#include "flutter/sky/engine/core/rendering/style/ShadowList.h"
#include "flutter/sky/engine/platform/animation/UnitBezier.h"
#include "flutter/sky/engine/platform/fonts/FontCache.h"
#include "flutter/sky/engine/platform/fonts/GlyphBuffer.h"
#include "flutter/sky/engine/platform/fonts/WidthIterator.h"
#include "flutter/sky/engine/platform/graphics/GraphicsContextStateSaver.h"
#include "flutter/sky/engine/wtf/Vector.h"
#include "flutter/sky/engine/wtf/text/CString.h"
#include "flutter/sky/engine/wtf/text/StringBuilder.h"

#include <algorithm>

namespace blink {

struct SameSizeAsInlineTextBox : public InlineBox {
  unsigned variables[1];
  unsigned short variables2[2];
  void* pointers[3];
};

COMPILE_ASSERT(sizeof(InlineTextBox) == sizeof(SameSizeAsInlineTextBox),
               InlineTextBox_should_stay_small);

typedef WTF::HashMap<const InlineTextBox*, LayoutRect> InlineTextBoxOverflowMap;
static InlineTextBoxOverflowMap* gTextBoxesWithOverflow;

void InlineTextBox::destroy() {
  if (!knownToHaveNoOverflow() && gTextBoxesWithOverflow)
    gTextBoxesWithOverflow->remove(this);
  InlineBox::destroy();
}

void InlineTextBox::markDirty() {
  m_len = 0;
  m_start = 0;
  InlineBox::markDirty();
}

LayoutRect InlineTextBox::logicalOverflowRect() const {
  if (knownToHaveNoOverflow() || !gTextBoxesWithOverflow)
    return enclosingIntRect(logicalFrameRect());
  return gTextBoxesWithOverflow->get(this);
}

void InlineTextBox::setLogicalOverflowRect(const LayoutRect& rect) {
  ASSERT(!knownToHaveNoOverflow());
  if (!gTextBoxesWithOverflow)
    gTextBoxesWithOverflow = new InlineTextBoxOverflowMap;
  gTextBoxesWithOverflow->add(this, rect);
}

int InlineTextBox::baselinePosition(FontBaseline baselineType) const {
  if (!isText() || !parent())
    return 0;
  if (parent()->renderer() == renderer().parent())
    return parent()->baselinePosition(baselineType);
  return toRenderBoxModelObject(renderer().parent())
      ->baselinePosition(baselineType, isFirstLineStyle(), HorizontalLine,
                         PositionOnContainingLine);
}

LayoutUnit InlineTextBox::lineHeight() const {
  if (!isText() || !renderer().parent())
    return 0;
  if (parent()->renderer() == renderer().parent())
    return parent()->lineHeight();
  return toRenderBoxModelObject(renderer().parent())
      ->lineHeight(isFirstLineStyle(), HorizontalLine,
                   PositionOnContainingLine);
}

LayoutUnit InlineTextBox::selectionTop() {
  return root().selectionTop();
}

LayoutUnit InlineTextBox::selectionBottom() {
  return root().selectionBottom();
}

LayoutUnit InlineTextBox::selectionHeight() {
  return root().selectionHeight();
}

bool InlineTextBox::isSelected(int startPos, int endPos) const {
  int sPos = std::max(startPos - m_start, 0);
  // The position after a hard line break is considered to be past its end.
  // See the corresponding code in InlineTextBox::selectionState.
  int ePos = std::min(endPos - m_start, int(m_len) + (isLineBreak() ? 0 : 1));
  return (sPos < ePos);
}

RenderObject::SelectionState InlineTextBox::selectionState() {
  RenderObject::SelectionState state = renderer().selectionState();
  if (state == RenderObject::SelectionStart ||
      state == RenderObject::SelectionEnd ||
      state == RenderObject::SelectionBoth) {
    int startPos, endPos;
    renderer().selectionStartEnd(startPos, endPos);
    // The position after a hard line break is considered to be past its end.
    // See the corresponding code in InlineTextBox::isSelected.
    int lastSelectable = start() + len() - (isLineBreak() ? 1 : 0);

    // FIXME: Remove -webkit-line-break: LineBreakAfterWhiteSpace.
    int endOfLineAdjustmentForCSSLineBreak =
        renderer().style()->lineBreak() == LineBreakAfterWhiteSpace ? -1 : 0;
    bool start =
        (state != RenderObject::SelectionEnd && startPos >= m_start &&
         startPos <= m_start + m_len + endOfLineAdjustmentForCSSLineBreak);
    bool end = (state != RenderObject::SelectionStart && endPos > m_start &&
                endPos <= lastSelectable);
    if (start && end)
      state = RenderObject::SelectionBoth;
    else if (start)
      state = RenderObject::SelectionStart;
    else if (end)
      state = RenderObject::SelectionEnd;
    else if ((state == RenderObject::SelectionEnd || startPos < m_start) &&
             (state == RenderObject::SelectionStart || endPos > lastSelectable))
      state = RenderObject::SelectionInside;
    else if (state == RenderObject::SelectionBoth)
      state = RenderObject::SelectionNone;
  }

  return state;
}

LayoutRect InlineTextBox::localSelectionRect(int startPos, int endPos) {
  int sPos = std::max(startPos - m_start, 0);
  int ePos = std::min(endPos - m_start, (int)m_len);

  if (sPos > ePos)
    return LayoutRect();

  FontCachePurgePreventer fontCachePurgePreventer;

  LayoutUnit selTop = selectionTop();
  LayoutUnit selHeight = selectionHeight();
  RenderStyle* styleToUse = renderer().style(isFirstLineStyle());
  const Font& font = styleToUse->font();

  StringBuilder charactersWithHyphen;
  bool respectHyphen = ePos == m_len && hasHyphen();
  TextRun textRun = constructTextRun(styleToUse, font,
                                     respectHyphen ? &charactersWithHyphen : 0);

  FloatPoint startingPoint = FloatPoint(logicalLeft(), selTop.toFloat());
  LayoutRect r;
  if (sPos || ePos != static_cast<int>(m_len))
    r = enclosingIntRect(font.selectionRectForText(textRun, startingPoint,
                                                   selHeight, sPos, ePos));
  else  // Avoid computing the font width when the entire line box is selected
        // as an optimization.
    r = enclosingIntRect(FloatRect(
        startingPoint, FloatSize(m_logicalWidth, selHeight.toFloat())));

  LayoutUnit logicalWidth = r.width();
  if (r.x() > logicalRight())
    logicalWidth = 0;
  else if (r.maxX() > logicalRight())
    logicalWidth = logicalRight() - r.x();

  LayoutPoint topPoint = LayoutPoint(r.x(), selTop);
  return LayoutRect(topPoint, LayoutSize(logicalWidth, selHeight));
}

void InlineTextBox::deleteLine() {
  renderer().removeTextBox(this);
  destroy();
}

void InlineTextBox::extractLine() {
  if (extracted())
    return;

  renderer().extractTextBox(this);
}

void InlineTextBox::attachLine() {
  if (!extracted())
    return;

  renderer().attachTextBox(this);
}

bool InlineTextBox::isLineBreak() const {
  return renderer().style()->preserveNewline() && len() == 1 &&
         (*renderer().text().impl())[start()] == '\n';
}

bool InlineTextBox::nodeAtPoint(const HitTestRequest& request,
                                HitTestResult& result,
                                const HitTestLocation& locationInContainer,
                                const LayoutPoint& accumulatedOffset,
                                LayoutUnit /* lineTop */,
                                LayoutUnit /*lineBottom*/) {
  if (isLineBreak())
    return false;

  FloatPoint boxOrigin = locationIncludingFlipping();
  boxOrigin.moveBy(accumulatedOffset);
  FloatRect rect(boxOrigin, size());
  if (m_truncation != cFullTruncation && visibleToHitTestRequest(request) &&
      locationInContainer.intersects(rect)) {
    renderer().updateHitTestResult(
        result, locationInContainer.point() - toLayoutSize(accumulatedOffset));
    return true;
  }
  return false;
}

bool InlineTextBox::getEmphasisMarkPosition(
    RenderStyle* style,
    TextEmphasisPosition& emphasisPosition) const {
  if (style->textEmphasisMark() == TextEmphasisMarkNone)
    return false;
  // FIXME(sky): remove this function, it was for ruby.
  emphasisPosition = style->textEmphasisPosition();
  return true;
}

namespace {

struct TextPaintingStyle {
  Color fillColor;
  Color strokeColor;
  Color emphasisMarkColor;
  float strokeWidth;
  const ShadowList* shadow;

  bool operator==(const TextPaintingStyle& other) {
    return fillColor == other.fillColor && strokeColor == other.strokeColor &&
           emphasisMarkColor == other.emphasisMarkColor &&
           strokeWidth == other.strokeWidth && shadow == other.shadow;
  }
  bool operator!=(const TextPaintingStyle& other) { return !(*this == other); }
};

TextPaintingStyle textPaintingStyle(RenderText& renderer, RenderStyle* style) {
  TextPaintingStyle textStyle;
  textStyle.fillColor = style->resolveColor(style->textFillColor());
  textStyle.strokeColor = style->resolveColor(style->textStrokeColor());
  textStyle.emphasisMarkColor = style->resolveColor(style->textEmphasisColor());
  textStyle.strokeWidth = style->textStrokeWidth();
  textStyle.shadow = style->textShadow();
  return textStyle;
}

TextPaintingStyle selectionPaintingStyle(RenderText& renderer,
                                         bool haveSelection,
                                         const TextPaintingStyle& textStyle) {
  TextPaintingStyle selectionStyle = textStyle;

  if (haveSelection) {
    selectionStyle.fillColor = renderer.selectionForegroundColor();
    selectionStyle.emphasisMarkColor = renderer.selectionEmphasisMarkColor();
  }

  return selectionStyle;
}

void updateGraphicsContext(GraphicsContext* context,
                           const TextPaintingStyle& textStyle,
                           GraphicsContextStateSaver& stateSaver) {
  TextDrawingModeFlags mode = context->textDrawingMode();
  if (textStyle.strokeWidth > 0) {
    TextDrawingModeFlags newMode = mode | TextModeStroke;
    if (mode != newMode) {
      if (!stateSaver.saved())
        stateSaver.save();
      context->setTextDrawingMode(newMode);
      mode = newMode;
    }
  }

  if (mode & TextModeFill && textStyle.fillColor != context->fillColor())
    context->setFillColor(textStyle.fillColor);

  if (mode & TextModeStroke) {
    if (textStyle.strokeColor != context->strokeColor())
      context->setStrokeColor(textStyle.strokeColor);
    if (textStyle.strokeWidth != context->strokeThickness())
      context->setStrokeThickness(textStyle.strokeWidth);
  }

  if (textStyle.shadow) {
    if (!stateSaver.saved())
      stateSaver.save();
    context->setDrawLooper(textStyle.shadow->createDrawLooper(
        DrawLooperBuilder::ShadowIgnoresAlpha));
  }
}

void paintText(GraphicsContext* context,
               const Font& font,
               const TextRun& textRun,
               const AtomicString& emphasisMark,
               int emphasisMarkOffset,
               int startOffset,
               int endOffset,
               int truncationPoint,
               const FloatPoint& textOrigin,
               const FloatRect& boxRect,
               TextBlobPtr* cachedTextBlob = 0) {
  TextRunPaintInfo textRunPaintInfo(textRun);
  textRunPaintInfo.bounds = boxRect;
  if (startOffset <= endOffset) {
    textRunPaintInfo.from = startOffset;
    textRunPaintInfo.to = endOffset;
    // FIXME: We should be able to use cachedTextBlob in more cases.
    textRunPaintInfo.cachedTextBlob = cachedTextBlob;
    if (emphasisMark.isEmpty())
      context->drawText(font, textRunPaintInfo, textOrigin);
    else
      context->drawEmphasisMarks(font, textRunPaintInfo, emphasisMark,
                                 textOrigin + IntSize(0, emphasisMarkOffset));
  } else {
    if (endOffset > 0) {
      textRunPaintInfo.from = 0;
      textRunPaintInfo.to = endOffset;
      if (emphasisMark.isEmpty())
        context->drawText(font, textRunPaintInfo, textOrigin);
      else
        context->drawEmphasisMarks(font, textRunPaintInfo, emphasisMark,
                                   textOrigin + IntSize(0, emphasisMarkOffset));
    }
    if (startOffset < truncationPoint) {
      textRunPaintInfo.from = startOffset;
      textRunPaintInfo.to = truncationPoint;
      if (emphasisMark.isEmpty())
        context->drawText(font, textRunPaintInfo, textOrigin);
      else
        context->drawEmphasisMarks(font, textRunPaintInfo, emphasisMark,
                                   textOrigin + IntSize(0, emphasisMarkOffset));
    }
  }
}

inline void paintEmphasisMark(GraphicsContext* context,
                              const AtomicString& emphasisMark,
                              int emphasisMarkOffset,
                              int startOffset,
                              int endOffset,
                              int paintRunLength,
                              const Font& font,
                              const TextRun& textRun,
                              const FloatPoint& textOrigin,
                              const FloatRect& boxRect) {
  ASSERT(!emphasisMark.isEmpty());
  paintText(context, font, textRun, emphasisMark, emphasisMarkOffset,
            startOffset, endOffset, paintRunLength, textOrigin, boxRect);
}

void paintTextWithEmphasisMark(GraphicsContext* context,
                               const Font& font,
                               const TextPaintingStyle& textStyle,
                               const TextRun& textRun,
                               const AtomicString& emphasisMark,
                               int emphasisMarkOffset,
                               int startOffset,
                               int endOffset,
                               int length,
                               const FloatPoint& textOrigin,
                               const FloatRect& boxRect,
                               TextBlobPtr* cachedTextBlob = 0) {
  GraphicsContextStateSaver stateSaver(*context, false);
  updateGraphicsContext(context, textStyle, stateSaver);
  paintText(context, font, textRun, nullAtom, 0, startOffset, endOffset, length,
            textOrigin, boxRect, cachedTextBlob);

  if (!emphasisMark.isEmpty()) {
    if (textStyle.emphasisMarkColor != textStyle.fillColor)
      context->setFillColor(textStyle.emphasisMarkColor);
    paintEmphasisMark(context, emphasisMark, emphasisMarkOffset, startOffset,
                      endOffset, length, font, textRun, textOrigin, boxRect);
  }
}

}  // namespace

void InlineTextBox::paint(PaintInfo& paintInfo,
                          const LayoutPoint& paintOffset,
                          LayoutUnit /*lineTop*/,
                          LayoutUnit /*lineBottom*/,
                          Vector<RenderBox*>& layers) {
  if (isLineBreak() || m_truncation == cFullTruncation || !m_len)
    return;

  LayoutRect logicalVisualOverflow = logicalOverflowRect();
  LayoutUnit logicalStart = logicalVisualOverflow.x() + paintOffset.x();
  LayoutUnit logicalExtent = logicalVisualOverflow.width();

  LayoutUnit paintEnd = paintInfo.rect.maxX();
  LayoutUnit paintStart = paintInfo.rect.x();

  // When subpixel font scaling is enabled text runs are positioned at
  // subpixel boundaries on the x-axis and thus there is no reason to
  // snap the x value. We still round the y-axis to ensure consistent
  // line heights.
  LayoutPoint adjustedPaintOffset =
      LayoutPoint(paintOffset.x(), paintOffset.y().round());

  if (logicalStart >= paintEnd || logicalStart + logicalExtent <= paintStart)
    return;

  if (m_truncation != cNoTruncation) {
    if (renderer().containingBlock()->style()->isLeftToRightDirection() !=
        isLeftToRightDirection()) {
      // Make the visible fragment of text hug the edge closest to the rest of
      // the run by moving the origin at which we start drawing text. e.g. In
      // the case of LTR text truncated in an RTL Context, the correct behavior
      // is: |Hello|CBA| -> |...He|CBA| In order to draw the fragment "He"
      // aligned to the right edge of it's box, we need to start drawing farther
      // to the right. NOTE: WebKit's behavior differs from that of IE which
      // appears to just overlay the ellipsis on top of the truncated string
      // i.e.  |Hello|CBA| -> |...lo|CBA|
      LayoutUnit widthOfVisibleText = renderer().width(
          m_start, m_truncation, textPos(),
          isLeftToRightDirection() ? LTR : RTL, isFirstLineStyle());
      LayoutUnit widthOfHiddenText = m_logicalWidth - widthOfVisibleText;
      // FIXME: The hit testing logic also needs to take this translation into
      // account.
      LayoutSize truncationOffset(
          isLeftToRightDirection() ? widthOfHiddenText : -widthOfHiddenText, 0);
      adjustedPaintOffset.move(truncationOffset);
    }
  }

  GraphicsContext* context = paintInfo.context;
  RenderStyle* styleToUse = renderer().style(isFirstLineStyle());

  FloatPoint boxOrigin = locationIncludingFlipping();
  boxOrigin.move(adjustedPaintOffset.x().toFloat(),
                 adjustedPaintOffset.y().toFloat());
  FloatRect boxRect(boxOrigin, LayoutSize(logicalWidth(), logicalHeight()));

  bool haveSelection = selectionState() != RenderObject::SelectionNone;

  // Determine text colors.
  TextPaintingStyle textStyle = textPaintingStyle(renderer(), styleToUse);
  TextPaintingStyle selectionStyle =
      selectionPaintingStyle(renderer(), haveSelection, textStyle);
  bool paintSelectedTextSeparately = textStyle != selectionStyle;

  // Set our font.
  const Font& font = styleToUse->font();

  FloatPoint textOrigin =
      FloatPoint(boxOrigin.x(), boxOrigin.y() + font.fontMetrics().ascent());

  // 1. Paint backgrounds behind text if needed. Examples of such backgrounds
  // include selection.
  if (haveSelection)
    paintSelection(context, boxOrigin, styleToUse, font,
                   selectionStyle.fillColor);

  // 2. Now paint the foreground, including text and decorations like
  // underline/overline (in quirks mode only).
  int length = m_len;
  int maximumLength;
  StringView string = renderer().text().createView();
  if (static_cast<unsigned>(length) != string.length() || m_start)
    string.narrow(m_start, length);
  maximumLength = renderer().textLength() - m_start;

  StringBuilder charactersWithEllipsis;
  if (hasAddedEllipsis()) {
    const AtomicString& ellipsis =
        renderer().containingBlock()->style()->ellipsis();
    charactersWithEllipsis.reserveCapacity(string.length() + ellipsis.length());
    charactersWithEllipsis.append(string);
    charactersWithEllipsis.append(ellipsis);
    string = charactersWithEllipsis.toString().createView();
    maximumLength = string.length();
  }

  StringBuilder charactersWithHyphen;
  TextRun textRun = constructTextRun(styleToUse, font, string, maximumLength,
                                     hasHyphen() ? &charactersWithHyphen : 0);
  if (hasHyphen() || hasAddedEllipsis())
    length = textRun.length();

  int sPos = 0;
  int ePos = 0;
  if (paintSelectedTextSeparately)
    selectionStartEnd(sPos, ePos);

  bool respectHyphen = ePos == m_len && hasHyphen();
  if (respectHyphen)
    ePos = textRun.length();

  if (m_truncation != cNoTruncation) {
    sPos = std::min<int>(sPos, m_truncation);
    ePos = std::min<int>(ePos, m_truncation);
    length = m_truncation;
  }

  int emphasisMarkOffset = 0;
  TextEmphasisPosition emphasisMarkPosition;
  bool hasTextEmphasis =
      getEmphasisMarkPosition(styleToUse, emphasisMarkPosition);
  const AtomicString& emphasisMark =
      hasTextEmphasis ? styleToUse->textEmphasisMarkString() : nullAtom;
  if (!emphasisMark.isEmpty())
    emphasisMarkOffset = emphasisMarkPosition == TextEmphasisPositionOver
                             ? -font.fontMetrics().ascent() -
                                   font.emphasisMarkDescent(emphasisMark)
                             : font.fontMetrics().descent() +
                                   font.emphasisMarkAscent(emphasisMark);

  // FIXME: Truncate right-to-left text correctly.
  int startOffset = 0;
  int endOffset = length;
  if (paintSelectedTextSeparately && ePos > sPos) {
    startOffset = ePos;
    endOffset = sPos;
  }
  // FIXME: This cache should probably ultimately be held somewhere else.
  // A hashmap is convenient to avoid a memory hit when the
  // RuntimeEnabledFeature is off.
  bool textBlobIsCacheable = startOffset == 0 && endOffset == length;
  TextBlobPtr* cachedTextBlob =
      textBlobIsCacheable ? &m_cachedTextBlob : nullptr;
  paintTextWithEmphasisMark(context, font, textStyle, textRun, emphasisMark,
                            emphasisMarkOffset, startOffset, endOffset, length,
                            textOrigin, boxRect, cachedTextBlob);

  if (paintSelectedTextSeparately && sPos < ePos) {
    // paint only the text that is selected
    bool textBlobIsCacheable = sPos == 0 && ePos == length;
    TextBlobPtr* cachedTextBlob =
        textBlobIsCacheable ? &m_cachedTextBlob : nullptr;
    paintTextWithEmphasisMark(context, font, selectionStyle, textRun,
                              emphasisMark, emphasisMarkOffset, sPos, ePos,
                              length, textOrigin, boxRect, cachedTextBlob);
  }

  // Paint decorations
  TextDecoration textDecorations = styleToUse->textDecorationsInEffect();
  if (textDecorations != TextDecorationNone) {
    GraphicsContextStateSaver stateSaver(*context, false);
    updateGraphicsContext(context, textStyle, stateSaver);
    paintDecoration(context, boxOrigin, textDecorations);
  }
}

void InlineTextBox::selectionStartEnd(int& sPos, int& ePos) {
  int startPos, endPos;
  if (renderer().selectionState() == RenderObject::SelectionInside) {
    startPos = 0;
    endPos = renderer().textLength();
  } else {
    renderer().selectionStartEnd(startPos, endPos);
    if (renderer().selectionState() == RenderObject::SelectionStart)
      endPos = renderer().textLength();
    else if (renderer().selectionState() == RenderObject::SelectionEnd)
      startPos = 0;
  }

  sPos = std::max(startPos - m_start, 0);
  ePos = std::min(endPos - m_start, (int)m_len);
}

void InlineTextBox::paintSelection(GraphicsContext* context,
                                   const FloatPoint& boxOrigin,
                                   RenderStyle* style,
                                   const Font& font,
                                   Color textColor) {
  // See if we have a selection to paint at all.
  int sPos, ePos;
  selectionStartEnd(sPos, ePos);
  if (sPos >= ePos)
    return;

  Color c = renderer().selectionBackgroundColor();
  if (!c.alpha())
    return;

  // If the text color ends up being the same as the selection background,
  // invert the selection background.
  if (textColor == c)
    c = Color(0xff - c.red(), 0xff - c.green(), 0xff - c.blue());

  // If the text is truncated, let the thing being painted in the truncation
  // draw its own highlight.
  int length = m_truncation != cNoTruncation ? m_truncation : m_len;
  StringView string = renderer().text().createView();

  if (string.length() != static_cast<unsigned>(length) || m_start)
    string.narrow(m_start, length);

  StringBuilder charactersWithHyphen;
  bool respectHyphen = ePos == length && hasHyphen();
  TextRun textRun =
      constructTextRun(style, font, string, renderer().textLength() - m_start,
                       respectHyphen ? &charactersWithHyphen : 0);
  if (respectHyphen)
    ePos = textRun.length();

  LayoutUnit selectionBottom = root().selectionBottom();
  LayoutUnit selectionTop = root().selectionTopAdjustedForPrecedingBlock();

  int deltaY = roundToInt(logicalTop() - selectionTop);
  int selHeight = std::max(0, roundToInt(selectionBottom - selectionTop));

  FloatPoint localOrigin(boxOrigin.x(), boxOrigin.y() - deltaY);
  FloatRect clipRect(localOrigin, FloatSize(m_logicalWidth, selHeight));

  GraphicsContextStateSaver stateSaver(*context);
  context->clip(clipRect);
  context->drawHighlightForText(font, textRun, localOrigin, selHeight, c, sPos,
                                ePos);
}

unsigned InlineTextBox::underlinePaintStart(
    const CompositionUnderline& underline) {
  return std::max(static_cast<unsigned>(m_start), underline.startOffset);
}

unsigned InlineTextBox::underlinePaintEnd(
    const CompositionUnderline& underline) {
  unsigned paintEnd = std::min(
      end() + 1,
      underline.endOffset);  // end() points at the last char, not past it.
  if (m_truncation != cNoTruncation)
    paintEnd =
        std::min(paintEnd, static_cast<unsigned>(m_start + m_truncation));
  return paintEnd;
}

void InlineTextBox::paintSingleCompositionBackgroundRun(
    GraphicsContext* context,
    const FloatPoint& boxOrigin,
    RenderStyle* style,
    const Font& font,
    Color backgroundColor,
    int startPos,
    int endPos) {
  int sPos = std::max(startPos - m_start, 0);
  int ePos = std::min(endPos - m_start, static_cast<int>(m_len));
  if (sPos >= ePos)
    return;

  int deltaY = logicalTop() - selectionTop();
  int selHeight = selectionHeight();
  FloatPoint localOrigin(boxOrigin.x(), boxOrigin.y() - deltaY);
  context->drawHighlightForText(font, constructTextRun(style, font),
                                localOrigin, selHeight, backgroundColor, sPos,
                                ePos);
}

static StrokeStyle textDecorationStyleToStrokeStyle(
    TextDecorationStyle decorationStyle) {
  StrokeStyle strokeStyle = SolidStroke;
  switch (decorationStyle) {
    case TextDecorationStyleSolid:
      strokeStyle = SolidStroke;
      break;
    case TextDecorationStyleDouble:
      strokeStyle = DoubleStroke;
      break;
    case TextDecorationStyleDotted:
      strokeStyle = DottedStroke;
      break;
    case TextDecorationStyleDashed:
      strokeStyle = DashedStroke;
      break;
    case TextDecorationStyleWavy:
      strokeStyle = WavyStroke;
      break;
  }

  return strokeStyle;
}

static int computeUnderlineOffset(const TextUnderlinePosition underlinePosition,
                                  const FontMetrics& fontMetrics,
                                  const InlineTextBox* inlineTextBox,
                                  const float textDecorationThickness) {
  // Compute the gap between the font and the underline. Use at least one
  // pixel gap, if underline is thick then use a bigger gap.
  int gap = 0;

  // Underline position of zero means draw underline on Baseline Position,
  // in Blink we need at least 1-pixel gap to adding following check.
  // Positive underline Position means underline should be drawn above baselin e
  // and negative value means drawing below baseline, negating the value as in
  // Blink downward Y-increases.

  if (fontMetrics.underlinePosition())
    gap = -fontMetrics.underlinePosition();
  else
    gap = std::max<int>(1, ceilf(textDecorationThickness / 2.f));

  // FIXME: We support only horizontal text for now.
  switch (underlinePosition) {
    case TextUnderlinePositionAuto:
      return fontMetrics.ascent() +
             gap;  // Position underline near the alphabetic baseline.
    case TextUnderlinePositionUnder: {
      // Position underline relative to the under edge of the lowest element's
      // content box.
      const float offset =
          inlineTextBox->root().maxLogicalTop() - inlineTextBox->logicalTop();
      if (offset > 0)
        return inlineTextBox->logicalHeight() + gap + offset;
      return inlineTextBox->logicalHeight() + gap;
    }
  }

  ASSERT_NOT_REACHED();
  return fontMetrics.ascent() + gap;
}

struct CurveAlongX {
  static inline float x(const FloatPoint& p) { return p.x(); }
  static inline float y(const FloatPoint& p) { return p.y(); }
  static inline FloatPoint p(float x, float y) { return FloatPoint(x, y); }
  static inline void setX(FloatPoint& p, double x) { p.setX(x); }
};

struct CurveAlongY {
  static inline float x(const FloatPoint& p) { return p.y(); }
  static inline float y(const FloatPoint& p) { return p.x(); }
  static inline FloatPoint p(float x, float y) { return FloatPoint(y, x); }
  static inline void setX(FloatPoint& p, double x) { p.setY(x); }
};

/*
 * Draw one cubic Bezier curve and repeat the same pattern along the
 * the decoration's axis. The start point (p1), controlPoint1,
 * controlPoint2 and end point (p2) of the Bezier curve form a diamond
 * shape, as follows (the four points marked +):
 *
 *                              step
 *                         |-----------|
 *
 *                   controlPoint1
 *                         +
 *
 *
 *                  . .
 *                .     .
 *              .         .
 * (x1, y1) p1 +           .            + p2 (x2, y2) - <--- Decoration's axis
 *                          .         .               |
 *                            .     .                 |
 *                              . .                   | controlPointDistance
 *                                                    |
 *                                                    |
 *                         +                          -
 *                   controlPoint2
 *
 *             |-----------|
 *                 step
 *
 * strokeWavyTextDecorationInternal() takes two points, p1 and p2.
 * These must be axis-aligned. If they are horizontally-aligned,
 * specialize it with CurveAlongX; if they are vertically aligned,
 * specialize it with CurveAlongY. The function is written as if it
 * was doing everything along the X axis; CurveAlongY just flips the
 * coordinates around.
 */
template <class Curve>
static void strokeWavyTextDecorationInternal(GraphicsContext* context,
                                             FloatPoint p1,
                                             FloatPoint p2,
                                             float strokeThickness) {
  ASSERT(Curve::y(p1) ==
         Curve::y(p2));  // verify that this is indeed axis-aligned

  context->adjustLineToPixelBoundaries(p1, p2, strokeThickness,
                                       context->strokeStyle());

  Path path;
  path.moveTo(p1);

  float controlPointDistance = 2 * strokeThickness;
  float step = controlPointDistance;

  float yAxis = Curve::y(p1);
  float x1;
  float x2;

  if (Curve::x(p1) < Curve::x(p2)) {
    x1 = Curve::x(p1);
    x2 = Curve::x(p2);
  } else {
    x1 = Curve::x(p2);
    x2 = Curve::x(p1);
  }

  FloatPoint controlPoint1 = Curve::p(0, yAxis + controlPointDistance);
  FloatPoint controlPoint2 = Curve::p(0, yAxis - controlPointDistance);

  float x;
  for (x = x1; x + 2 * step <= x2;) {
    Curve::setX(controlPoint1, x + step);
    Curve::setX(controlPoint2, x + step);
    x += 2 * step;
    path.addBezierCurveTo(controlPoint1, controlPoint2, Curve::p(x, yAxis));
  }

  if (x < x2) {
    Curve::setX(controlPoint1, x + step);
    Curve::setX(controlPoint2, x + step);
    float xScale = 1.0 / (2 * step);
    float yScale = 1.0 / (2 * controlPointDistance);
    OwnPtr<UnitBezier> bezier =
        adoptPtr(new UnitBezier((Curve::x(controlPoint1) - x) * xScale,
                                (Curve::y(controlPoint1) - yAxis) * yScale,
                                (Curve::x(controlPoint2) - x) * xScale,
                                (Curve::y(controlPoint2) - yAxis) * yScale));
    float t = bezier->solveCurveX((x2 - x) / (2.0 * step),
                                  std::numeric_limits<double>::epsilon());
    // following math based on http://stackoverflow.com/a/879213
    float u1 = 1.0 - t;
    float qxb = x * u1 * u1 + Curve::x(controlPoint1) * 2 * t * u1 +
                Curve::x(controlPoint2) * t * t;
    float qxd = Curve::x(controlPoint1) * u1 * u1 +
                Curve::x(controlPoint2) * 2 * t * u1 + (x + step) * t * t;
    float qyb = yAxis * u1 * u1 + Curve::y(controlPoint1) * 2 * t * u1 +
                Curve::y(controlPoint2) * t * t;
    float qyd = Curve::y(controlPoint1) * u1 * u1 +
                Curve::y(controlPoint2) * 2 * t * u1 + yAxis * t * t;
    float xb = x * u1 + Curve::x(controlPoint1) * t;
    float yb = yAxis * u1 + Curve::y(controlPoint1) * t;
    float xc = qxb;
    float xd = qxb * u1 + qxd * t;
    float yc = qyb;
    float yd = qyb * u1 + qyd * t;
    path.addBezierCurveTo(Curve::p(xb, yb), Curve::p(xc, yc), Curve::p(xd, yd));
  }

  context->setShouldAntialias(true);
  context->strokePath(path);
}

static void strokeWavyTextDecoration(GraphicsContext* context,
                                     FloatPoint p1,
                                     FloatPoint p2,
                                     float strokeThickness) {
  if (p1.y() == p2.y())  // horizontal line
    strokeWavyTextDecorationInternal<CurveAlongX>(context, p1, p2,
                                                  strokeThickness);
  else  // vertical line
    strokeWavyTextDecorationInternal<CurveAlongY>(context, p1, p2,
                                                  strokeThickness);
}

static bool shouldSetDecorationAntialias(TextDecorationStyle decorationStyle) {
  return decorationStyle == TextDecorationStyleDotted ||
         decorationStyle == TextDecorationStyleDashed;
}

static bool shouldSetDecorationAntialias(TextDecorationStyle underline,
                                         TextDecorationStyle overline,
                                         TextDecorationStyle linethrough) {
  return shouldSetDecorationAntialias(underline) ||
         shouldSetDecorationAntialias(overline) ||
         shouldSetDecorationAntialias(linethrough);
}

static void paintAppliedDecoration(
    GraphicsContext* context,
    FloatPoint start,
    float width,
    float doubleOffset,
    int wavyOffsetFactor,
    RenderObject::AppliedTextDecoration decoration,
    float thickness,
    bool antialiasDecoration) {
  context->setStrokeStyle(textDecorationStyleToStrokeStyle(decoration.style));
  context->setStrokeColor(decoration.color);

  switch (decoration.style) {
    case TextDecorationStyleWavy:
      strokeWavyTextDecoration(
          context, start + FloatPoint(0, doubleOffset * wavyOffsetFactor),
          start + FloatPoint(width, doubleOffset * wavyOffsetFactor),
          thickness);
      break;
    case TextDecorationStyleDotted:
    case TextDecorationStyleDashed:
      context->setShouldAntialias(antialiasDecoration);
      // Fall through
    default:
      context->drawLineForText(start, width);

      if (decoration.style == TextDecorationStyleDouble)
        context->drawLineForText(start + FloatPoint(0, doubleOffset), width);
  }
}

void InlineTextBox::paintDecoration(GraphicsContext* context,
                                    const FloatPoint& boxOrigin,
                                    TextDecoration deco) {
  GraphicsContextStateSaver stateSaver(*context);

  if (m_truncation == cFullTruncation)
    return;

  FloatPoint localOrigin = boxOrigin;

  float width = m_logicalWidth;
  if (m_truncation != cNoTruncation) {
    width = renderer().width(m_start, m_truncation, textPos(),
                             isLeftToRightDirection() ? LTR : RTL,
                             isFirstLineStyle());
    if (!isLeftToRightDirection())
      localOrigin.move(m_logicalWidth - width, 0);
  }

  // Get the text decoration colors.
  RenderObject::AppliedTextDecoration underline, overline, linethrough;
  renderer().getTextDecorations(deco, underline, overline, linethrough, true);
  if (isFirstLineStyle())
    renderer().getTextDecorations(deco, underline, overline, linethrough, true,
                                  true);

  // Use a special function for underlines to get the positioning exactly right.

  RenderStyle* styleToUse = renderer().style(isFirstLineStyle());
  int baseline = styleToUse->fontMetrics().ascent();

  // Set the thick of the line to be 10% (or something else ?)of the computed
  // font size and not less than 1px.

  // Update Underline thickness, in case we have Faulty Font Metrics calculating
  // underline thickness by old method.
  float textDecorationThickness =
      styleToUse->fontMetrics()
          .underlineThickness();  // TODO(ianh): Make this author-controllable
  int fontHeightInt = (int)(styleToUse->fontMetrics().floatHeight() + 0.5);
  if ((textDecorationThickness == 0.f) ||
      (textDecorationThickness >= (fontHeightInt >> 1)))
    textDecorationThickness =
        std::max(1.f, styleToUse->computedFontSize() / 10.f);

  context->setStrokeThickness(textDecorationThickness);

  bool antialiasDecoration =
      shouldSetDecorationAntialias(overline.style, underline.style,
                                   linethrough.style) &&
      RenderBoxModelObject::shouldAntialiasLines(context);

  // Offset between lines - always non-zero, so lines never cross each other.
  float doubleOffset = textDecorationThickness + 1.f;

  if (deco & TextDecorationUnderline) {
    const int underlineOffset = computeUnderlineOffset(
        styleToUse->textUnderlinePosition(), styleToUse->fontMetrics(), this,
        textDecorationThickness);
    paintAppliedDecoration(context,
                           localOrigin + FloatPoint(0, underlineOffset), width,
                           doubleOffset, 1, underline, textDecorationThickness,
                           antialiasDecoration);
  }
  if (deco & TextDecorationOverline) {
    paintAppliedDecoration(context, localOrigin, width, -doubleOffset, 1,
                           overline, textDecorationThickness,
                           antialiasDecoration);
  }
  if (deco & TextDecorationLineThrough) {
    const float lineThroughOffset = 2 * baseline / 3;
    paintAppliedDecoration(context,
                           localOrigin + FloatPoint(0, lineThroughOffset),
                           width, doubleOffset, 0, linethrough,
                           textDecorationThickness, antialiasDecoration);
  }
}

void InlineTextBox::paintCompositionBackgrounds(GraphicsContext* pt,
                                                const FloatPoint& boxOrigin,
                                                RenderStyle* style,
                                                const Font& font,
                                                bool useCustomUnderlines) {
  ASSERT_NOT_REACHED();  // TODO(ianh): this is unused right now, but we should
                         // probably expose it if it's useful
  if (useCustomUnderlines) {
    // Paint custom background highlights for compositions.
    Vector<CompositionUnderline> underlines;  // TODO(ianh): if we expose this
                                              // function, provide a way to let
                                              // authors set this
    CompositionUnderlineRangeFilter filter(underlines, start(), end());
    for (CompositionUnderlineRangeFilter::ConstIterator it = filter.begin();
         it != filter.end(); ++it) {
      if (it->backgroundColor == Color::transparent)
        continue;
      paintSingleCompositionBackgroundRun(
          pt, boxOrigin, style, font, it->backgroundColor,
          underlinePaintStart(*it), underlinePaintEnd(*it));
    }

  } else {
    unsigned start = 0;  // TODO(ianh): if we expose this function, provide a
                         // way to let authors set this
    unsigned end = 0;  // TODO(ianh): if we expose this function, provide a way
                       // to let authors set this
    paintSingleCompositionBackgroundRun(
        pt, boxOrigin, style, font,
        RenderTheme::theme().platformDefaultCompositionBackgroundColor(), start,
        end);
  }
}

void InlineTextBox::paintCompositionUnderline(
    GraphicsContext* ctx,
    const FloatPoint& boxOrigin,
    const CompositionUnderline& underline) {
  if (m_truncation == cFullTruncation)
    return;

  unsigned paintStart = underlinePaintStart(underline);
  unsigned paintEnd = underlinePaintEnd(underline);

  // start of line to draw, relative to paintOffset.
  float start = paintStart == static_cast<unsigned>(m_start)
                    ? 0
                    : renderer().width(m_start, paintStart - m_start, textPos(),
                                       isLeftToRightDirection() ? LTR : RTL,
                                       isFirstLineStyle());
  // how much line to draw
  float width = (paintStart == static_cast<unsigned>(m_start) &&
                 paintEnd == static_cast<unsigned>(end()) + 1)
                    ? m_logicalWidth
                    : renderer().width(paintStart, paintEnd - paintStart,
                                       textPos() + start,
                                       isLeftToRightDirection() ? LTR : RTL,
                                       isFirstLineStyle());

  // Thick marked text underlines are 2px thick as long as there is room for the
  // 2px line under the baseline. All other marked text underlines are 1px
  // thick. If there's not enough space the underline will touch or overlap
  // characters.
  int lineThickness = 1;
  int baseline = renderer().style(isFirstLineStyle())->fontMetrics().ascent();
  if (underline.thick && logicalHeight() - baseline >= 2)
    lineThickness = 2;

  // We need to have some space between underlines of subsequent clauses,
  // because some input methods do not use different underline styles for those.
  // We make each line shorter, which has a harmless side effect of shortening
  // the first and last clauses, too.
  start += 1;
  width -= 2;

  ctx->setStrokeColor(underline.color);
  ctx->setStrokeThickness(lineThickness);
  ctx->drawLineForText(
      FloatPoint(boxOrigin.x() + start,
                 boxOrigin.y() + logicalHeight() - lineThickness),
      width);
}

int InlineTextBox::caretMinOffset() const {
  return m_start;
}

int InlineTextBox::caretMaxOffset() const {
  return m_start + m_len;
}

float InlineTextBox::textPos() const {
  // When computing the width of a text run,
  // RenderParagraph::computeInlineDirectionPositionsForLine() doesn't include
  // the actual offset from the containing block edge in its measurement.
  // textPos() should be consistent so the text are rendered in the same width.
  if (logicalLeft() == 0)
    return 0;
  return logicalLeft() - root().logicalLeft();
}

int InlineTextBox::offsetForPosition(float lineOffset,
                                     bool includePartialGlyphs) const {
  if (isLineBreak())
    return 0;

  if (lineOffset - logicalLeft() > logicalWidth())
    return isLeftToRightDirection() ? len() : 0;
  if (lineOffset - logicalLeft() < 0)
    return isLeftToRightDirection() ? 0 : len();

  FontCachePurgePreventer fontCachePurgePreventer;

  RenderText& text = renderer();
  RenderStyle* style = text.style(isFirstLineStyle());
  const Font& font = style->font();
  return font.offsetForPosition(constructTextRun(style, font),
                                lineOffset - logicalLeft(),
                                includePartialGlyphs);
}

float InlineTextBox::positionForOffset(int offset) const {
  ASSERT(offset >= m_start);
  ASSERT(offset <= m_start + m_len);

  if (isLineBreak())
    return logicalLeft();

  FontCachePurgePreventer fontCachePurgePreventer;

  RenderText& text = renderer();
  RenderStyle* styleToUse = text.style(isFirstLineStyle());
  ASSERT(styleToUse);
  const Font& font = styleToUse->font();
  int from = !isLeftToRightDirection() ? offset - m_start : 0;
  int to = !isLeftToRightDirection() ? m_len : offset - m_start;
  // FIXME: Do we need to add rightBearing here?
  return font
      .selectionRectForText(constructTextRun(styleToUse, font),
                            IntPoint(logicalLeft(), 0), 0, from, to)
      .maxX();
}

bool InlineTextBox::containsCaretOffset(int offset) const {
  // Offsets before the box are never "in".
  if (offset < m_start)
    return false;

  int pastEnd = m_start + m_len;

  // Offsets inside the box (not at either edge) are always "in".
  if (offset < pastEnd)
    return true;

  // Offsets outside the box are always "out".
  if (offset > pastEnd)
    return false;

  // Offsets at the end are "out" for line breaks (they are on the next line).
  if (isLineBreak())
    return false;

  // Offsets at the end are "in" for normal boxes (but the caller has to check
  // affinity).
  return true;
}

void InlineTextBox::characterWidths(Vector<float>& widths) const {
  FontCachePurgePreventer fontCachePurgePreventer;

  RenderStyle* styleToUse = renderer().style(isFirstLineStyle());
  const Font& font = styleToUse->font();

  TextRun textRun = constructTextRun(styleToUse, font);

  GlyphBuffer glyphBuffer;
  WidthIterator it(&font, textRun);
  float lastWidth = 0;
  widths.resize(m_len);
  for (unsigned i = 0; i < m_len; i++) {
    it.advance(i + 1, &glyphBuffer);
    widths[i] = it.m_runWidthSoFar - lastWidth;
    lastWidth = it.m_runWidthSoFar;
  }
}

TextRun InlineTextBox::constructTextRun(
    RenderStyle* style,
    const Font& font,
    StringBuilder* charactersWithHyphen) const {
  ASSERT(style);
  ASSERT(renderer().text());

  StringView string = renderer().text().createView();
  unsigned startPos = start();
  unsigned length = len();

  if (string.length() != length || startPos)
    string.narrow(startPos, length);

  return constructTextRun(style, font, string,
                          renderer().textLength() - startPos,
                          charactersWithHyphen);
}

TextRun InlineTextBox::constructTextRun(
    RenderStyle* style,
    const Font& font,
    StringView string,
    int maximumLength,
    StringBuilder* charactersWithHyphen) const {
  ASSERT(style);

  if (charactersWithHyphen) {
    const AtomicString& hyphenString = style->hyphenString();
    charactersWithHyphen->reserveCapacity(string.length() +
                                          hyphenString.length());
    charactersWithHyphen->append(string);
    charactersWithHyphen->append(hyphenString);
    string = charactersWithHyphen->toString().createView();
    maximumLength = string.length();
  }

  ASSERT(maximumLength >= static_cast<int>(string.length()));

  TextRun run(string, textPos(), expansion(), expansionBehavior(), direction(),
              dirOverride() || style->rtlOrdering() == VisualOrder,
              !renderer().canUseSimpleFontCodePath());
  run.setTabSize(!style->collapseWhiteSpace(), style->tabSize());
  run.setCharacterScanForCodePath(!renderer().canUseSimpleFontCodePath());
  // Propagate the maximum length of the characters buffer to the TextRun, even
  // when we're only processing a substring.
  run.setCharactersLength(maximumLength);
  ASSERT(run.charactersLength() >= run.length());
  return run;
}

TextRun InlineTextBox::constructTextRunForInspector(RenderStyle* style,
                                                    const Font& font) const {
  return InlineTextBox::constructTextRun(style, font);
}

#ifndef NDEBUG

const char* InlineTextBox::boxName() const {
  return "InlineTextBox";
}

void InlineTextBox::showBox(int printedCharacters) const {
  const RenderText& obj = renderer();
  String value = obj.text();
  value = value.substring(start(), len());
  value.replaceWithLiteral('\\', "\\\\");
  value.replaceWithLiteral('\n', "\\n");
  printedCharacters += fprintf(stderr, "%s\t%p", boxName(), this);
  for (; printedCharacters < showTreeCharacterOffset; printedCharacters++)
    fputc(' ', stderr);
  printedCharacters = fprintf(stderr, "\t%s %p", obj.renderName(), &obj);
  const int rendererCharacterOffset = 24;
  for (; printedCharacters < rendererCharacterOffset; printedCharacters++)
    fputc(' ', stderr);
  fprintf(stderr, "(%d,%d) \"%s\"\n", start(), start() + len(),
          value.utf8().data());
}

#endif

}  // namespace blink
