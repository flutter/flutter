/*
 * (C) 1999 Lars Knoll (knoll@kde.org)
 * (C) 2000 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011 Apple Inc. All rights reserved.
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

#include "sky/engine/config.h"
#include "sky/engine/core/rendering/InlineTextBox.h"

#include "gen/sky/platform/RuntimeEnabledFeatures.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/DocumentMarkerController.h"
#include "sky/engine/core/dom/RenderedDocumentMarker.h"
#include "sky/engine/core/dom/Text.h"
#include "sky/engine/core/editing/CompositionUnderline.h"
#include "sky/engine/core/editing/CompositionUnderlineRangeFilter.h"
#include "sky/engine/core/editing/Editor.h"
#include "sky/engine/core/editing/InputMethodController.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/frame/Settings.h"
#include "sky/engine/core/page/Page.h"
#include "sky/engine/core/rendering/EllipsisBox.h"
#include "sky/engine/core/rendering/HitTestResult.h"
#include "sky/engine/core/rendering/PaintInfo.h"
#include "sky/engine/core/rendering/RenderBlock.h"
#include "sky/engine/core/rendering/RenderTheme.h"
#include "sky/engine/core/rendering/style/ShadowList.h"
#include "sky/engine/platform/fonts/FontCache.h"
#include "sky/engine/platform/fonts/GlyphBuffer.h"
#include "sky/engine/platform/fonts/WidthIterator.h"
#include "sky/engine/platform/graphics/GraphicsContextStateSaver.h"
#include "sky/engine/wtf/Vector.h"
#include "sky/engine/wtf/text/CString.h"
#include "sky/engine/wtf/text/StringBuilder.h"

#include <algorithm>

namespace blink {

struct SameSizeAsInlineTextBox : public InlineBox {
    unsigned variables[1];
    unsigned short variables2[2];
    void* pointers[2];
};

COMPILE_ASSERT(sizeof(InlineTextBox) == sizeof(SameSizeAsInlineTextBox), InlineTextBox_should_stay_small);

typedef WTF::HashMap<const InlineTextBox*, LayoutRect> InlineTextBoxOverflowMap;
static InlineTextBoxOverflowMap* gTextBoxesWithOverflow;

static const int misspellingLineThickness = 3;

void InlineTextBox::destroy()
{
    if (!knownToHaveNoOverflow() && gTextBoxesWithOverflow)
        gTextBoxesWithOverflow->remove(this);
    InlineBox::destroy();
}

void InlineTextBox::markDirty()
{
    m_len = 0;
    m_start = 0;
    InlineBox::markDirty();
}

LayoutRect InlineTextBox::logicalOverflowRect() const
{
    if (knownToHaveNoOverflow() || !gTextBoxesWithOverflow)
        return enclosingIntRect(logicalFrameRect());
    return gTextBoxesWithOverflow->get(this);
}

void InlineTextBox::setLogicalOverflowRect(const LayoutRect& rect)
{
    ASSERT(!knownToHaveNoOverflow());
    if (!gTextBoxesWithOverflow)
        gTextBoxesWithOverflow = new InlineTextBoxOverflowMap;
    gTextBoxesWithOverflow->add(this, rect);
}

int InlineTextBox::baselinePosition(FontBaseline baselineType) const
{
    if (!isText() || !parent())
        return 0;
    if (parent()->renderer() == renderer().parent())
        return parent()->baselinePosition(baselineType);
    return toRenderBoxModelObject(renderer().parent())->baselinePosition(baselineType, isFirstLineStyle(), HorizontalLine, PositionOnContainingLine);
}

LayoutUnit InlineTextBox::lineHeight() const
{
    if (!isText() || !renderer().parent())
        return 0;
    if (parent()->renderer() == renderer().parent())
        return parent()->lineHeight();
    return toRenderBoxModelObject(renderer().parent())->lineHeight(isFirstLineStyle(), HorizontalLine, PositionOnContainingLine);
}

LayoutUnit InlineTextBox::selectionTop()
{
    return root().selectionTop();
}

LayoutUnit InlineTextBox::selectionBottom()
{
    return root().selectionBottom();
}

LayoutUnit InlineTextBox::selectionHeight()
{
    return root().selectionHeight();
}

bool InlineTextBox::isSelected(int startPos, int endPos) const
{
    int sPos = std::max(startPos - m_start, 0);
    // The position after a hard line break is considered to be past its end.
    // See the corresponding code in InlineTextBox::selectionState.
    int ePos = std::min(endPos - m_start, int(m_len) + (isLineBreak() ? 0 : 1));
    return (sPos < ePos);
}

RenderObject::SelectionState InlineTextBox::selectionState()
{
    RenderObject::SelectionState state = renderer().selectionState();
    if (state == RenderObject::SelectionStart || state == RenderObject::SelectionEnd || state == RenderObject::SelectionBoth) {
        int startPos, endPos;
        renderer().selectionStartEnd(startPos, endPos);
        // The position after a hard line break is considered to be past its end.
        // See the corresponding code in InlineTextBox::isSelected.
        int lastSelectable = start() + len() - (isLineBreak() ? 1 : 0);

        // FIXME: Remove -webkit-line-break: LineBreakAfterWhiteSpace.
        int endOfLineAdjustmentForCSSLineBreak = renderer().style()->lineBreak() == LineBreakAfterWhiteSpace ? -1 : 0;
        bool start = (state != RenderObject::SelectionEnd && startPos >= m_start && startPos <= m_start + m_len + endOfLineAdjustmentForCSSLineBreak);
        bool end = (state != RenderObject::SelectionStart && endPos > m_start && endPos <= lastSelectable);
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

    // If there are ellipsis following, make sure their selection is updated.
    if (m_truncation != cNoTruncation && root().ellipsisBox()) {
        EllipsisBox* ellipsis = root().ellipsisBox();
        if (state != RenderObject::SelectionNone) {
            int start, end;
            selectionStartEnd(start, end);
            // The ellipsis should be considered to be selected if the end of
            // the selection is past the beginning of the truncation and the
            // beginning of the selection is before or at the beginning of the
            // truncation.
            ellipsis->setSelectionState(end >= m_truncation && start <= m_truncation ?
                RenderObject::SelectionInside : RenderObject::SelectionNone);
        } else
            ellipsis->setSelectionState(RenderObject::SelectionNone);
    }

    return state;
}

LayoutRect InlineTextBox::localSelectionRect(int startPos, int endPos)
{
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
    TextRun textRun = constructTextRun(styleToUse, font, respectHyphen ? &charactersWithHyphen : 0);

    FloatPoint startingPoint = FloatPoint(logicalLeft(), selTop.toFloat());
    LayoutRect r;
    if (sPos || ePos != static_cast<int>(m_len))
        r = enclosingIntRect(font.selectionRectForText(textRun, startingPoint, selHeight, sPos, ePos));
    else // Avoid computing the font width when the entire line box is selected as an optimization.
        r = enclosingIntRect(FloatRect(startingPoint, FloatSize(m_logicalWidth, selHeight.toFloat())));

    LayoutUnit logicalWidth = r.width();
    if (r.x() > logicalRight())
        logicalWidth  = 0;
    else if (r.maxX() > logicalRight())
        logicalWidth = logicalRight() - r.x();

    LayoutPoint topPoint = LayoutPoint(r.x(), selTop);
    return LayoutRect(topPoint, LayoutSize(logicalWidth, selHeight));
}

void InlineTextBox::deleteLine()
{
    renderer().removeTextBox(this);
    destroy();
}

void InlineTextBox::extractLine()
{
    if (extracted())
        return;

    renderer().extractTextBox(this);
}

void InlineTextBox::attachLine()
{
    if (!extracted())
        return;

    renderer().attachTextBox(this);
}

float InlineTextBox::placeEllipsisBox(bool flowIsLTR, float visibleLeftEdge, float visibleRightEdge, float ellipsisWidth, float &truncatedWidth, bool& foundBox)
{
    if (foundBox) {
        m_truncation = cFullTruncation;
        return -1;
    }

    // For LTR this is the left edge of the box, for RTL, the right edge in parent coordinates.
    float ellipsisX = flowIsLTR ? visibleRightEdge - ellipsisWidth : visibleLeftEdge + ellipsisWidth;

    // Criteria for full truncation:
    // LTR: the left edge of the ellipsis is to the left of our text run.
    // RTL: the right edge of the ellipsis is to the right of our text run.
    bool ltrFullTruncation = flowIsLTR && ellipsisX <= logicalLeft();
    bool rtlFullTruncation = !flowIsLTR && ellipsisX >= logicalLeft() + logicalWidth();
    if (ltrFullTruncation || rtlFullTruncation) {
        // Too far.  Just set full truncation, but return -1 and let the ellipsis just be placed at the edge of the box.
        m_truncation = cFullTruncation;
        foundBox = true;
        return -1;
    }

    bool ltrEllipsisWithinBox = flowIsLTR && (ellipsisX < logicalRight());
    bool rtlEllipsisWithinBox = !flowIsLTR && (ellipsisX > logicalLeft());
    if (ltrEllipsisWithinBox || rtlEllipsisWithinBox) {
        foundBox = true;

        // The inline box may have different directionality than it's parent.  Since truncation
        // behavior depends both on both the parent and the inline block's directionality, we
        // must keep track of these separately.
        bool ltr = isLeftToRightDirection();
        if (ltr != flowIsLTR) {
            // Width in pixels of the visible portion of the box, excluding the ellipsis.
            int visibleBoxWidth = visibleRightEdge - visibleLeftEdge  - ellipsisWidth;
            ellipsisX = ltr ? logicalLeft() + visibleBoxWidth : logicalRight() - visibleBoxWidth;
        }

        int offset = offsetForPosition(ellipsisX, false);
        if (offset == 0) {
            // No characters should be rendered.  Set ourselves to full truncation and place the ellipsis at the min of our start
            // and the ellipsis edge.
            m_truncation = cFullTruncation;
            truncatedWidth += ellipsisWidth;
            return std::min(ellipsisX, logicalLeft());
        }

        // Set the truncation index on the text run.
        m_truncation = offset;

        // If we got here that means that we were only partially truncated and we need to return the pixel offset at which
        // to place the ellipsis.
        float widthOfVisibleText = renderer().width(m_start, offset, textPos(), flowIsLTR ? LTR : RTL, isFirstLineStyle());

        // The ellipsis needs to be placed just after the last visible character.
        // Where "after" is defined by the flow directionality, not the inline
        // box directionality.
        // e.g. In the case of an LTR inline box truncated in an RTL flow then we can
        // have a situation such as |Hello| -> |...He|
        truncatedWidth += widthOfVisibleText + ellipsisWidth;
        if (flowIsLTR)
            return logicalLeft() + widthOfVisibleText;
        else
            return logicalRight() - widthOfVisibleText - ellipsisWidth;
    }
    truncatedWidth += logicalWidth();
    return -1;
}

bool InlineTextBox::isLineBreak() const
{
    return renderer().style()->preserveNewline() && len() == 1 && (*renderer().text().impl())[start()] == '\n';
}

bool InlineTextBox::nodeAtPoint(const HitTestRequest& request, HitTestResult& result, const HitTestLocation& locationInContainer, const LayoutPoint& accumulatedOffset, LayoutUnit /* lineTop */, LayoutUnit /*lineBottom*/)
{
    if (isLineBreak())
        return false;

    FloatPoint boxOrigin = locationIncludingFlipping();
    boxOrigin.moveBy(accumulatedOffset);
    FloatRect rect(boxOrigin, size());
    if (m_truncation != cFullTruncation && visibleToHitTestRequest(request) && locationInContainer.intersects(rect)) {
        renderer().updateHitTestResult(result, locationInContainer.point() - toLayoutSize(accumulatedOffset));
        if (!result.addNodeToRectBasedTestResult(renderer().node(), request, locationInContainer, rect))
            return true;
    }
    return false;
}

bool InlineTextBox::getEmphasisMarkPosition(RenderStyle* style, TextEmphasisPosition& emphasisPosition) const
{
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

    bool operator==(const TextPaintingStyle& other)
    {
        return fillColor == other.fillColor
            && strokeColor == other.strokeColor
            && emphasisMarkColor == other.emphasisMarkColor
            && strokeWidth == other.strokeWidth
            && shadow == other.shadow;
    }
    bool operator!=(const TextPaintingStyle& other) { return !(*this == other); }
};

TextPaintingStyle textPaintingStyle(RenderText& renderer, RenderStyle* style)
{
    TextPaintingStyle textStyle;
    textStyle.fillColor = renderer.resolveColor(style, CSSPropertyWebkitTextFillColor);
    textStyle.strokeColor = renderer.resolveColor(style, CSSPropertyWebkitTextStrokeColor);
    textStyle.emphasisMarkColor = renderer.resolveColor(style, CSSPropertyWebkitTextEmphasisColor);
    textStyle.strokeWidth = style->textStrokeWidth();
    textStyle.shadow = style->textShadow();
    return textStyle;
}

TextPaintingStyle selectionPaintingStyle(RenderText& renderer, bool haveSelection, const TextPaintingStyle& textStyle)
{
    TextPaintingStyle selectionStyle = textStyle;

    if (haveSelection) {
        selectionStyle.fillColor = renderer.selectionForegroundColor();
        selectionStyle.emphasisMarkColor = renderer.selectionEmphasisMarkColor();
    }

    return selectionStyle;
}

void updateGraphicsContext(GraphicsContext* context, const TextPaintingStyle& textStyle, GraphicsContextStateSaver& stateSaver)
{
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
        context->setDrawLooper(textStyle.shadow->createDrawLooper(DrawLooperBuilder::ShadowIgnoresAlpha));
    }
}

void paintText(GraphicsContext* context,
    const Font& font, const TextRun& textRun,
    const AtomicString& emphasisMark, int emphasisMarkOffset,
    int startOffset, int endOffset, int truncationPoint,
    const FloatPoint& textOrigin, const FloatRect& boxRect)
{
    TextRunPaintInfo textRunPaintInfo(textRun);
    textRunPaintInfo.bounds = boxRect;
    if (startOffset <= endOffset) {
        textRunPaintInfo.from = startOffset;
        textRunPaintInfo.to = endOffset;
        if (emphasisMark.isEmpty())
            context->drawText(font, textRunPaintInfo, textOrigin);
        else
            context->drawEmphasisMarks(font, textRunPaintInfo, emphasisMark, textOrigin + IntSize(0, emphasisMarkOffset));
    } else {
        if (endOffset > 0) {
            textRunPaintInfo.from = 0;
            textRunPaintInfo.to = endOffset;
            if (emphasisMark.isEmpty())
                context->drawText(font, textRunPaintInfo, textOrigin);
            else
                context->drawEmphasisMarks(font, textRunPaintInfo, emphasisMark, textOrigin + IntSize(0, emphasisMarkOffset));
        }
        if (startOffset < truncationPoint) {
            textRunPaintInfo.from = startOffset;
            textRunPaintInfo.to = truncationPoint;
            if (emphasisMark.isEmpty())
                context->drawText(font, textRunPaintInfo, textOrigin);
            else
                context->drawEmphasisMarks(font, textRunPaintInfo, emphasisMark, textOrigin + IntSize(0, emphasisMarkOffset));
        }
    }
}

inline void paintEmphasisMark(GraphicsContext* context,
    const AtomicString& emphasisMark, int emphasisMarkOffset,
    int startOffset, int endOffset, int paintRunLength,
    const Font& font, const TextRun& textRun,
    const FloatPoint& textOrigin, const FloatRect& boxRect)
{
    ASSERT(!emphasisMark.isEmpty());
    paintText(context, font, textRun, emphasisMark, emphasisMarkOffset, startOffset, endOffset, paintRunLength, textOrigin, boxRect);
}

void paintTextWithEmphasisMark(
    GraphicsContext* context, const Font& font, const TextPaintingStyle& textStyle, const TextRun& textRun,
    const AtomicString& emphasisMark, int emphasisMarkOffset, int startOffset, int endOffset, int length,
    const FloatPoint& textOrigin, const FloatRect& boxRect)
{
    GraphicsContextStateSaver stateSaver(*context, false);
    updateGraphicsContext(context, textStyle, stateSaver);
    paintText(context, font, textRun, nullAtom, 0, startOffset, endOffset, length, textOrigin, boxRect);

    if (!emphasisMark.isEmpty()) {
        if (textStyle.emphasisMarkColor != textStyle.fillColor)
            context->setFillColor(textStyle.emphasisMarkColor);
        paintEmphasisMark(context, emphasisMark, emphasisMarkOffset, startOffset, endOffset, length, font, textRun, textOrigin, boxRect);
    }
}

} // namespace

void InlineTextBox::paint(PaintInfo& paintInfo, const LayoutPoint& paintOffset, LayoutUnit /*lineTop*/, LayoutUnit /*lineBottom*/)
{
    if (isLineBreak() || !paintInfo.shouldPaintWithinRoot(&renderer())
        || m_truncation == cFullTruncation || paintInfo.phase == PaintPhaseOutline || !m_len)
        return;

    ASSERT(paintInfo.phase != PaintPhaseSelfOutline && paintInfo.phase != PaintPhaseChildOutlines);

    LayoutRect logicalVisualOverflow = logicalOverflowRect();
    LayoutUnit logicalStart = logicalVisualOverflow.x() + paintOffset.x();
    LayoutUnit logicalExtent = logicalVisualOverflow.width();

    LayoutUnit paintEnd = paintInfo.rect.maxX();
    LayoutUnit paintStart = paintInfo.rect.x();

    // When subpixel font scaling is enabled text runs are positioned at
    // subpixel boundaries on the x-axis and thus there is no reason to
    // snap the x value. We still round the y-axis to ensure consistent
    // line heights.
    LayoutPoint adjustedPaintOffset = RuntimeEnabledFeatures::subpixelFontScalingEnabled()
        ? LayoutPoint(paintOffset.x(), paintOffset.y().round())
        : roundedIntPoint(paintOffset);

    if (logicalStart >= paintEnd || logicalStart + logicalExtent <= paintStart)
        return;

    // Determine whether or not we're selected.
    bool haveSelection = paintInfo.phase != PaintPhaseTextClip && selectionState() != RenderObject::SelectionNone;
    if (!haveSelection && paintInfo.phase == PaintPhaseSelection)
        // When only painting the selection, don't bother to paint if there is none.
        return;

    if (m_truncation != cNoTruncation) {
        if (renderer().containingBlock()->style()->isLeftToRightDirection() != isLeftToRightDirection()) {
            // Make the visible fragment of text hug the edge closest to the rest of the run by moving the origin
            // at which we start drawing text.
            // e.g. In the case of LTR text truncated in an RTL Context, the correct behavior is:
            // |Hello|CBA| -> |...He|CBA|
            // In order to draw the fragment "He" aligned to the right edge of it's box, we need to start drawing
            // farther to the right.
            // NOTE: WebKit's behavior differs from that of IE which appears to just overlay the ellipsis on top of the
            // truncated string i.e.  |Hello|CBA| -> |...lo|CBA|
            LayoutUnit widthOfVisibleText = renderer().width(m_start, m_truncation, textPos(), isLeftToRightDirection() ? LTR : RTL, isFirstLineStyle());
            LayoutUnit widthOfHiddenText = m_logicalWidth - widthOfVisibleText;
            // FIXME: The hit testing logic also needs to take this translation into account.
            LayoutSize truncationOffset(isLeftToRightDirection() ? widthOfHiddenText : -widthOfHiddenText, 0);
            adjustedPaintOffset.move(truncationOffset);
        }
    }

    GraphicsContext* context = paintInfo.context;
    RenderStyle* styleToUse = renderer().style(isFirstLineStyle());

    FloatPoint boxOrigin = locationIncludingFlipping();
    boxOrigin.move(adjustedPaintOffset.x().toFloat(), adjustedPaintOffset.y().toFloat());
    FloatRect boxRect(boxOrigin, LayoutSize(logicalWidth(), logicalHeight()));

    // Determine whether or not we have composition underlines to draw.
    bool containsComposition = renderer().node() && renderer().frame()->inputMethodController().compositionNode() == renderer().node();
    bool useCustomUnderlines = containsComposition && renderer().frame()->inputMethodController().compositionUsesCustomUnderlines();

    // Determine text colors.
    TextPaintingStyle textStyle = textPaintingStyle(renderer(), styleToUse);
    TextPaintingStyle selectionStyle = selectionPaintingStyle(renderer(), haveSelection, textStyle);
    bool paintSelectedTextOnly = (paintInfo.phase == PaintPhaseSelection);
    bool paintSelectedTextSeparately = !paintSelectedTextOnly && textStyle != selectionStyle;

    // Set our font.
    const Font& font = styleToUse->font();

    FloatPoint textOrigin = FloatPoint(boxOrigin.x(), boxOrigin.y() + font.fontMetrics().ascent());

    // 1. Paint backgrounds behind text if needed. Examples of such backgrounds include selection
    // and composition highlights.
    if (paintInfo.phase != PaintPhaseSelection && paintInfo.phase != PaintPhaseTextClip) {
        if (containsComposition) {
            paintCompositionBackgrounds(context, boxOrigin, styleToUse, font, useCustomUnderlines);
        }

        paintDocumentMarkers(context, boxOrigin, styleToUse, font, true);

        if (haveSelection && !useCustomUnderlines)
            paintSelection(context, boxOrigin, styleToUse, font, selectionStyle.fillColor);
    }

    // 2. Now paint the foreground, including text and decorations like underline/overline (in quirks mode only).
    int length = m_len;
    int maximumLength;
    StringView string = renderer().text().createView();
    if (static_cast<unsigned>(length) != string.length() || m_start)
        string.narrow(m_start, length);
    maximumLength = renderer().textLength() - m_start;

    StringBuilder charactersWithHyphen;
    TextRun textRun = constructTextRun(styleToUse, font, string, maximumLength, hasHyphen() ? &charactersWithHyphen : 0);
    if (hasHyphen())
        length = textRun.length();

    int sPos = 0;
    int ePos = 0;
    if (paintSelectedTextOnly || paintSelectedTextSeparately)
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
    bool hasTextEmphasis = getEmphasisMarkPosition(styleToUse, emphasisMarkPosition);
    const AtomicString& emphasisMark = hasTextEmphasis ? styleToUse->textEmphasisMarkString() : nullAtom;
    if (!emphasisMark.isEmpty())
        emphasisMarkOffset = emphasisMarkPosition == TextEmphasisPositionOver ? -font.fontMetrics().ascent() - font.emphasisMarkDescent(emphasisMark) : font.fontMetrics().descent() + font.emphasisMarkAscent(emphasisMark);

    if (!paintSelectedTextOnly) {
        // FIXME: Truncate right-to-left text correctly.
        int startOffset = 0;
        int endOffset = length;
        if (paintSelectedTextSeparately && ePos > sPos) {
            startOffset = ePos;
            endOffset = sPos;
        }
        paintTextWithEmphasisMark(context, font, textStyle, textRun, emphasisMark, emphasisMarkOffset, startOffset, endOffset, length, textOrigin, boxRect);
    }

    if ((paintSelectedTextOnly || paintSelectedTextSeparately) && sPos < ePos) {
        // paint only the text that is selected
        paintTextWithEmphasisMark(context, font, selectionStyle, textRun, emphasisMark, emphasisMarkOffset, sPos, ePos, length, textOrigin, boxRect);
    }

    // Paint decorations
    TextDecoration textDecorations = styleToUse->textDecorationsInEffect();
    if (textDecorations != TextDecorationNone && !paintSelectedTextOnly) {
        GraphicsContextStateSaver stateSaver(*context, false);
        updateGraphicsContext(context, textStyle, stateSaver);
        paintDecoration(context, boxOrigin, textDecorations);
    }

    if (paintInfo.phase == PaintPhaseForeground) {
        paintDocumentMarkers(context, boxOrigin, styleToUse, font, false);

        // Paint custom underlines for compositions.
        if (useCustomUnderlines) {
            const Vector<CompositionUnderline>& underlines = renderer().frame()->inputMethodController().customCompositionUnderlines();
            CompositionUnderlineRangeFilter filter(underlines, start(), end());
            for (CompositionUnderlineRangeFilter::ConstIterator it = filter.begin(); it != filter.end(); ++it) {
                if (it->color == Color::transparent)
                    continue;
                paintCompositionUnderline(context, boxOrigin, *it);
            }
        }
    }
}

void InlineTextBox::selectionStartEnd(int& sPos, int& ePos)
{
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

void InlineTextBox::paintSelection(GraphicsContext* context, const FloatPoint& boxOrigin, RenderStyle* style, const Font& font, Color textColor)
{
    // See if we have a selection to paint at all.
    int sPos, ePos;
    selectionStartEnd(sPos, ePos);
    if (sPos >= ePos)
        return;

    Color c = renderer().selectionBackgroundColor();
    if (!c.alpha())
        return;

    // If the text color ends up being the same as the selection background, invert the selection
    // background.
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
    TextRun textRun = constructTextRun(style, font, string, renderer().textLength() - m_start, respectHyphen ? &charactersWithHyphen : 0);
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
    context->drawHighlightForText(font, textRun, localOrigin, selHeight, c, sPos, ePos);
}

unsigned InlineTextBox::underlinePaintStart(const CompositionUnderline& underline)
{
    return std::max(static_cast<unsigned>(m_start), underline.startOffset);
}

unsigned InlineTextBox::underlinePaintEnd(const CompositionUnderline& underline)
{
    unsigned paintEnd = std::min(end() + 1, underline.endOffset); // end() points at the last char, not past it.
    if (m_truncation != cNoTruncation)
        paintEnd = std::min(paintEnd, static_cast<unsigned>(m_start + m_truncation));
    return paintEnd;
}

void InlineTextBox::paintSingleCompositionBackgroundRun(GraphicsContext* context, const FloatPoint& boxOrigin, RenderStyle* style, const Font& font, Color backgroundColor, int startPos, int endPos)
{
    int sPos = std::max(startPos - m_start, 0);
    int ePos = std::min(endPos - m_start, static_cast<int>(m_len));
    if (sPos >= ePos)
        return;

    int deltaY = logicalTop() - selectionTop();
    int selHeight = selectionHeight();
    FloatPoint localOrigin(boxOrigin.x(), boxOrigin.y() - deltaY);
    context->drawHighlightForText(font, constructTextRun(style, font), localOrigin, selHeight, backgroundColor, sPos, ePos);
}

static StrokeStyle textDecorationStyleToStrokeStyle(TextDecorationStyle decorationStyle)
{
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

static int computeUnderlineOffset(const TextUnderlinePosition underlinePosition, const FontMetrics& fontMetrics, const InlineTextBox* inlineTextBox, const float textDecorationThickness)
{
    // Compute the gap between the font and the underline. Use at least one
    // pixel gap, if underline is thick then use a bigger gap.
    int gap = 0;

    // Underline position of zero means draw underline on Baseline Position,
    // in Blink we need at least 1-pixel gap to adding following check.
    // Positive underline Position means underline should be drawn above baselin e
    // and negative value means drawing below baseline, negating the value as in Blink
    // downward Y-increases.

    if (fontMetrics.underlinePosition())
        gap = -fontMetrics.underlinePosition();
    else
        gap = std::max<int>(1, ceilf(textDecorationThickness / 2.f));

    // FIXME: We support only horizontal text for now.
    switch (underlinePosition) {
    case TextUnderlinePositionAuto:
        return fontMetrics.ascent() + gap; // Position underline near the alphabetic baseline.
    case TextUnderlinePositionUnder: {
        // Position underline relative to the under edge of the lowest element's content box.
        const float offset = inlineTextBox->root().maxLogicalTop() - inlineTextBox->logicalTop();
        if (offset > 0)
            return inlineTextBox->logicalHeight() + gap + offset;
        return inlineTextBox->logicalHeight() + gap;
    }
    }

    ASSERT_NOT_REACHED();
    return fontMetrics.ascent() + gap;
}

static void adjustStepToDecorationLength(float& step, float& controlPointDistance, float length)
{
    ASSERT(step > 0);

    if (length <= 0)
        return;

    unsigned stepCount = static_cast<unsigned>(length / step);

    // Each Bezier curve starts at the same pixel that the previous one
    // ended. We need to subtract (stepCount - 1) pixels when calculating the
    // length covered to account for that.
    float uncoveredLength = length - (stepCount * step - (stepCount - 1));
    float adjustment = uncoveredLength / stepCount;
    step += adjustment;
    controlPointDistance += adjustment;
}

/*
 * Draw one cubic Bezier curve and repeat the same pattern long the the decoration's axis.
 * The start point (p1), controlPoint1, controlPoint2 and end point (p2) of the Bezier curve
 * form a diamond shape:
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
 */
static void strokeWavyTextDecoration(GraphicsContext* context, FloatPoint p1, FloatPoint p2, float strokeThickness)
{
    context->adjustLineToPixelBoundaries(p1, p2, strokeThickness, context->strokeStyle());

    Path path;
    path.moveTo(p1);

    // Distance between decoration's axis and Bezier curve's control points.
    // The height of the curve is based on this distance. Use a minimum of 6 pixels distance since
    // the actual curve passes approximately at half of that distance, that is 3 pixels.
    // The minimum height of the curve is also approximately 3 pixels. Increases the curve's height
    // as strockThickness increases to make the curve looks better.
    float controlPointDistance = 3 * std::max<float>(2, strokeThickness);

    // Increment used to form the diamond shape between start point (p1), control
    // points and end point (p2) along the axis of the decoration. Makes the
    // curve wider as strockThickness increases to make the curve looks better.
    float step = 2 * std::max<float>(2, strokeThickness);

    bool isVerticalLine = (p1.x() == p2.x());

    if (isVerticalLine) {
        ASSERT(p1.x() == p2.x());

        float xAxis = p1.x();
        float y1;
        float y2;

        if (p1.y() < p2.y()) {
            y1 = p1.y();
            y2 = p2.y();
        } else {
            y1 = p2.y();
            y2 = p1.y();
        }

        adjustStepToDecorationLength(step, controlPointDistance, y2 - y1);
        FloatPoint controlPoint1(xAxis + controlPointDistance, 0);
        FloatPoint controlPoint2(xAxis - controlPointDistance, 0);

        for (float y = y1; y + 2 * step <= y2;) {
            controlPoint1.setY(y + step);
            controlPoint2.setY(y + step);
            y += 2 * step;
            path.addBezierCurveTo(controlPoint1, controlPoint2, FloatPoint(xAxis, y));
        }
    } else {
        ASSERT(p1.y() == p2.y());

        float yAxis = p1.y();
        float x1;
        float x2;

        if (p1.x() < p2.x()) {
            x1 = p1.x();
            x2 = p2.x();
        } else {
            x1 = p2.x();
            x2 = p1.x();
        }

        adjustStepToDecorationLength(step, controlPointDistance, x2 - x1);
        FloatPoint controlPoint1(0, yAxis + controlPointDistance);
        FloatPoint controlPoint2(0, yAxis - controlPointDistance);

        for (float x = x1; x + 2 * step <= x2;) {
            controlPoint1.setX(x + step);
            controlPoint2.setX(x + step);
            x += 2 * step;
            path.addBezierCurveTo(controlPoint1, controlPoint2, FloatPoint(x, yAxis));
        }
    }

    context->setShouldAntialias(true);
    context->strokePath(path);
}

static bool shouldSetDecorationAntialias(TextDecorationStyle decorationStyle)
{
    return decorationStyle == TextDecorationStyleDotted || decorationStyle == TextDecorationStyleDashed;
}

static bool shouldSetDecorationAntialias(TextDecorationStyle underline, TextDecorationStyle overline, TextDecorationStyle linethrough)
{
    return shouldSetDecorationAntialias(underline) || shouldSetDecorationAntialias(overline) || shouldSetDecorationAntialias(linethrough);
}

static void paintAppliedDecoration(GraphicsContext* context, FloatPoint start, float width, float doubleOffset, int wavyOffsetFactor,
    RenderObject::AppliedTextDecoration decoration, float thickness, bool antialiasDecoration)
{
    context->setStrokeStyle(textDecorationStyleToStrokeStyle(decoration.style));
    context->setStrokeColor(decoration.color);

    switch (decoration.style) {
    case TextDecorationStyleWavy:
        strokeWavyTextDecoration(context, start + FloatPoint(0, doubleOffset * wavyOffsetFactor), start + FloatPoint(width, doubleOffset * wavyOffsetFactor), thickness);
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

void InlineTextBox::paintDecoration(GraphicsContext* context, const FloatPoint& boxOrigin, TextDecoration deco)
{
    GraphicsContextStateSaver stateSaver(*context);

    if (m_truncation == cFullTruncation)
        return;

    FloatPoint localOrigin = boxOrigin;

    float width = m_logicalWidth;
    if (m_truncation != cNoTruncation) {
        width = renderer().width(m_start, m_truncation, textPos(), isLeftToRightDirection() ? LTR : RTL, isFirstLineStyle());
        if (!isLeftToRightDirection())
            localOrigin.move(m_logicalWidth - width, 0);
    }

    // Get the text decoration colors.
    RenderObject::AppliedTextDecoration underline, overline, linethrough;
    renderer().getTextDecorations(deco, underline, overline, linethrough, true);
    if (isFirstLineStyle())
        renderer().getTextDecorations(deco, underline, overline, linethrough, true, true);

    // Use a special function for underlines to get the positioning exactly right.

    RenderStyle* styleToUse = renderer().style(isFirstLineStyle());
    int baseline = styleToUse->fontMetrics().ascent();

    // Set the thick of the line to be 10% (or something else ?)of the computed font size and not less than 1px.

    // Update Underline thickness, in case we have Faulty Font Metrics calculating underline thickness by old method.
    float textDecorationThickness = styleToUse->fontMetrics().underlineThickness();
    int fontHeightInt  = (int)(styleToUse->fontMetrics().floatHeight() + 0.5);
    if ((textDecorationThickness == 0.f) || (textDecorationThickness >= (fontHeightInt >> 1)))
        textDecorationThickness = std::max(1.f, styleToUse->computedFontSize() / 10.f);

    context->setStrokeThickness(textDecorationThickness);

    bool antialiasDecoration = shouldSetDecorationAntialias(overline.style, underline.style, linethrough.style)
        && RenderBoxModelObject::shouldAntialiasLines(context);

    // Offset between lines - always non-zero, so lines never cross each other.
    float doubleOffset = textDecorationThickness + 1.f;

    if (deco & TextDecorationUnderline) {
        const int underlineOffset = computeUnderlineOffset(styleToUse->textUnderlinePosition(), styleToUse->fontMetrics(), this, textDecorationThickness);
        paintAppliedDecoration(context, localOrigin + FloatPoint(0, underlineOffset), width, doubleOffset, 1, underline, textDecorationThickness, antialiasDecoration);
    }
    if (deco & TextDecorationOverline) {
        paintAppliedDecoration(context, localOrigin, width, -doubleOffset, 1, overline, textDecorationThickness, antialiasDecoration);
    }
    if (deco & TextDecorationLineThrough) {
        const float lineThroughOffset = 2 * baseline / 3;
        paintAppliedDecoration(context, localOrigin + FloatPoint(0, lineThroughOffset), width, doubleOffset, 0, linethrough, textDecorationThickness, antialiasDecoration);
    }
}

static GraphicsContext::DocumentMarkerLineStyle lineStyleForMarkerType(DocumentMarker::MarkerType markerType)
{
    switch (markerType) {
    case DocumentMarker::Spelling:
        return GraphicsContext::DocumentMarkerSpellingLineStyle;
    case DocumentMarker::Grammar:
        return GraphicsContext::DocumentMarkerGrammarLineStyle;
    default:
        ASSERT_NOT_REACHED();
        return GraphicsContext::DocumentMarkerSpellingLineStyle;
    }
}

void InlineTextBox::paintDocumentMarker(GraphicsContext* pt, const FloatPoint& boxOrigin, DocumentMarker* marker, RenderStyle* style, const Font& font, bool grammar)
{
    if (m_truncation == cFullTruncation)
        return;

    float start = 0; // start of line to draw, relative to tx
    float width = m_logicalWidth; // how much line to draw

    // Determine whether we need to measure text
    bool markerSpansWholeBox = true;
    if (m_start <= (int)marker->startOffset())
        markerSpansWholeBox = false;
    if ((end() + 1) != marker->endOffset()) // end points at the last char, not past it
        markerSpansWholeBox = false;
    if (m_truncation != cNoTruncation)
        markerSpansWholeBox = false;

    if (!markerSpansWholeBox || grammar) {
        int startPosition = std::max<int>(marker->startOffset() - m_start, 0);
        int endPosition = std::min<int>(marker->endOffset() - m_start, m_len);

        if (m_truncation != cNoTruncation)
            endPosition = std::min<int>(endPosition, m_truncation);

        // Calculate start & width
        int deltaY = logicalTop() - selectionTop();
        int selHeight = selectionHeight();
        FloatPoint startPoint(boxOrigin.x(), boxOrigin.y() - deltaY);
        TextRun run = constructTextRun(style, font);

        // FIXME: Convert the document markers to float rects.
        IntRect markerRect = enclosingIntRect(font.selectionRectForText(run, startPoint, selHeight, startPosition, endPosition));
        start = markerRect.x() - startPoint.x();
        width = markerRect.width();

        // Store rendered rects for bad grammar markers, so we can hit-test against it elsewhere in order to
        // display a toolTip. We don't do this for misspelling markers.
        if (grammar) {
            markerRect.move(-boxOrigin.x(), -boxOrigin.y());
            markerRect = renderer().localToAbsoluteQuad(FloatRect(markerRect)).enclosingBoundingBox();
            toRenderedDocumentMarker(marker)->setRenderedRect(markerRect);
        }
    }

    // IMPORTANT: The misspelling underline is not considered when calculating the text bounds, so we have to
    // make sure to fit within those bounds.  This means the top pixel(s) of the underline will overlap the
    // bottom pixel(s) of the glyphs in smaller font sizes.  The alternatives are to increase the line spacing (bad!!)
    // or decrease the underline thickness.  The overlap is actually the most useful, and matches what AppKit does.
    // So, we generally place the underline at the bottom of the text, but in larger fonts that's not so good so
    // we pin to two pixels under the baseline.
    int lineThickness = misspellingLineThickness;
    int baseline = renderer().style(isFirstLineStyle())->fontMetrics().ascent();
    int descent = logicalHeight() - baseline;
    int underlineOffset;
    if (descent <= (2 + lineThickness)) {
        // Place the underline at the very bottom of the text in small/medium fonts.
        underlineOffset = logicalHeight() - lineThickness;
    } else {
        // In larger fonts, though, place the underline up near the baseline to prevent a big gap.
        underlineOffset = baseline + 2;
    }
    pt->drawLineForDocumentMarker(FloatPoint(boxOrigin.x() + start, boxOrigin.y() + underlineOffset), width, lineStyleForMarkerType(marker->type()));
}

void InlineTextBox::paintTextMatchMarker(GraphicsContext* pt, const FloatPoint& boxOrigin, DocumentMarker* marker, RenderStyle* style, const Font& font)
{
    // Use same y positioning and height as for selection, so that when the selection and this highlight are on
    // the same word there are no pieces sticking out.
    int selHeight = selectionHeight();

    int sPos = std::max(marker->startOffset() - m_start, (unsigned)0);
    int ePos = std::min(marker->endOffset() - m_start, (unsigned)m_len);
    TextRun run = constructTextRun(style, font);

    // Always compute and store the rect associated with this marker. The computed rect is in absolute coordinates.
    IntRect markerRect = enclosingIntRect(font.selectionRectForText(run, IntPoint(x(), selectionTop()), selHeight, sPos, ePos));
    markerRect = renderer().localToAbsoluteQuad(FloatRect(markerRect)).enclosingBoundingBox();
    toRenderedDocumentMarker(marker)->setRenderedRect(markerRect);
}

void InlineTextBox::paintCompositionBackgrounds(GraphicsContext* pt, const FloatPoint& boxOrigin, RenderStyle* style, const Font& font, bool useCustomUnderlines)
{
    if (useCustomUnderlines) {
        // Paint custom background highlights for compositions.
        const Vector<CompositionUnderline>& underlines = renderer().frame()->inputMethodController().customCompositionUnderlines();
        CompositionUnderlineRangeFilter filter(underlines, start(), end());
        for (CompositionUnderlineRangeFilter::ConstIterator it = filter.begin(); it != filter.end(); ++it) {
            if (it->backgroundColor == Color::transparent)
                continue;
            paintSingleCompositionBackgroundRun(pt, boxOrigin, style, font, it->backgroundColor, underlinePaintStart(*it), underlinePaintEnd(*it));
        }

    } else {
        paintSingleCompositionBackgroundRun(pt, boxOrigin, style, font, RenderTheme::theme().platformDefaultCompositionBackgroundColor(),
            renderer().frame()->inputMethodController().compositionStart(),
            renderer().frame()->inputMethodController().compositionEnd());
    }
}

void InlineTextBox::paintDocumentMarkers(GraphicsContext* pt, const FloatPoint& boxOrigin, RenderStyle* style, const Font& font, bool background)
{
    if (!renderer().node())
        return;

    DocumentMarkerVector markers = renderer().document().markers().markersFor(renderer().node());
    DocumentMarkerVector::const_iterator markerIt = markers.begin();

    // Give any document markers that touch this run a chance to draw before the text has been drawn.
    // Note end() points at the last char, not one past it like endOffset and ranges do.
    for ( ; markerIt != markers.end(); ++markerIt) {
        DocumentMarker* marker = *markerIt;

        // Paint either the background markers or the foreground markers, but not both
        switch (marker->type()) {
            case DocumentMarker::Grammar:
            case DocumentMarker::Spelling:
                if (background)
                    continue;
                break;
            case DocumentMarker::TextMatch:
                if (!background)
                    continue;
                break;
            default:
                continue;
        }

        if (marker->endOffset() <= start())
            // marker is completely before this run.  This might be a marker that sits before the
            // first run we draw, or markers that were within runs we skipped due to truncation.
            continue;

        if (marker->startOffset() > end())
            // marker is completely after this run, bail.  A later run will paint it.
            break;

        // marker intersects this run.  Paint it.
        switch (marker->type()) {
            case DocumentMarker::Spelling:
                paintDocumentMarker(pt, boxOrigin, marker, style, font, false);
                break;
            case DocumentMarker::Grammar:
                paintDocumentMarker(pt, boxOrigin, marker, style, font, true);
                break;
            case DocumentMarker::TextMatch:
                paintTextMatchMarker(pt, boxOrigin, marker, style, font);
                break;
            default:
                ASSERT_NOT_REACHED();
        }

    }
}

void InlineTextBox::paintCompositionUnderline(GraphicsContext* ctx, const FloatPoint& boxOrigin, const CompositionUnderline& underline)
{
    if (m_truncation == cFullTruncation)
        return;

    unsigned paintStart = underlinePaintStart(underline);
    unsigned paintEnd = underlinePaintEnd(underline);

    // start of line to draw, relative to paintOffset.
    float start = paintStart == static_cast<unsigned>(m_start) ? 0 :
        renderer().width(m_start, paintStart - m_start, textPos(), isLeftToRightDirection() ? LTR : RTL, isFirstLineStyle());
    // how much line to draw
    float width = (paintStart == static_cast<unsigned>(m_start) && paintEnd == static_cast<unsigned>(end()) + 1) ? m_logicalWidth :
        renderer().width(paintStart, paintEnd - paintStart, textPos() + start, isLeftToRightDirection() ? LTR : RTL, isFirstLineStyle());

    // Thick marked text underlines are 2px thick as long as there is room for the 2px line under the baseline.
    // All other marked text underlines are 1px thick.
    // If there's not enough space the underline will touch or overlap characters.
    int lineThickness = 1;
    int baseline = renderer().style(isFirstLineStyle())->fontMetrics().ascent();
    if (underline.thick && logicalHeight() - baseline >= 2)
        lineThickness = 2;

    // We need to have some space between underlines of subsequent clauses, because some input methods do not use different underline styles for those.
    // We make each line shorter, which has a harmless side effect of shortening the first and last clauses, too.
    start += 1;
    width -= 2;

    ctx->setStrokeColor(underline.color);
    ctx->setStrokeThickness(lineThickness);
    ctx->drawLineForText(FloatPoint(boxOrigin.x() + start, boxOrigin.y() + logicalHeight() - lineThickness), width);
}

int InlineTextBox::caretMinOffset() const
{
    return m_start;
}

int InlineTextBox::caretMaxOffset() const
{
    return m_start + m_len;
}

float InlineTextBox::textPos() const
{
    // When computing the width of a text run, RenderParagraph::computeInlineDirectionPositionsForLine() doesn't include the actual offset
    // from the containing block edge in its measurement. textPos() should be consistent so the text are rendered in the same width.
    if (logicalLeft() == 0)
        return 0;
    return logicalLeft() - root().logicalLeft();
}

int InlineTextBox::offsetForPosition(float lineOffset, bool includePartialGlyphs) const
{
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
    return font.offsetForPosition(constructTextRun(style, font), lineOffset - logicalLeft(), includePartialGlyphs);
}

float InlineTextBox::positionForOffset(int offset) const
{
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
    return font.selectionRectForText(constructTextRun(styleToUse, font), IntPoint(logicalLeft(), 0), 0, from, to).maxX();
}

bool InlineTextBox::containsCaretOffset(int offset) const
{
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

    // Offsets at the end are "in" for normal boxes (but the caller has to check affinity).
    return true;
}

void InlineTextBox::characterWidths(Vector<float>& widths) const
{
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

TextRun InlineTextBox::constructTextRun(RenderStyle* style, const Font& font, StringBuilder* charactersWithHyphen) const
{
    ASSERT(style);
    ASSERT(renderer().text());

    StringView string = renderer().text().createView();
    unsigned startPos = start();
    unsigned length = len();

    if (string.length() != length || startPos)
        string.narrow(startPos, length);

    return constructTextRun(style, font, string, renderer().textLength() - startPos, charactersWithHyphen);
}

TextRun InlineTextBox::constructTextRun(RenderStyle* style, const Font& font, StringView string, int maximumLength, StringBuilder* charactersWithHyphen) const
{
    ASSERT(style);

    if (charactersWithHyphen) {
        const AtomicString& hyphenString = style->hyphenString();
        charactersWithHyphen->reserveCapacity(string.length() + hyphenString.length());
        charactersWithHyphen->append(string);
        charactersWithHyphen->append(hyphenString);
        string = charactersWithHyphen->toString().createView();
        maximumLength = string.length();
    }

    ASSERT(maximumLength >= static_cast<int>(string.length()));

    TextRun run(string, textPos(), expansion(), expansionBehavior(), direction(), dirOverride() || style->rtlOrdering() == VisualOrder, !renderer().canUseSimpleFontCodePath());
    run.setTabSize(!style->collapseWhiteSpace(), style->tabSize());
    run.setCharacterScanForCodePath(!renderer().canUseSimpleFontCodePath());
    // Propagate the maximum length of the characters buffer to the TextRun, even when we're only processing a substring.
    run.setCharactersLength(maximumLength);
    ASSERT(run.charactersLength() >= run.length());
    return run;
}

TextRun InlineTextBox::constructTextRunForInspector(RenderStyle* style, const Font& font) const
{
    return InlineTextBox::constructTextRun(style, font);
}

#ifndef NDEBUG

const char* InlineTextBox::boxName() const
{
    return "InlineTextBox";
}

void InlineTextBox::showBox(int printedCharacters) const
{
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
    fprintf(stderr, "(%d,%d) \"%s\"\n", start(), start() + len(), value.utf8().data());
}

#endif

} // namespace blink
