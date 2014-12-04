/**
 * Copyright (C) 2003, 2006 Apple Computer, Inc.
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

#include "sky/engine/config.h"
#include "sky/engine/core/rendering/EllipsisBox.h"

#include "sky/engine/core/rendering/HitTestResult.h"
#include "sky/engine/core/rendering/InlineTextBox.h"
#include "sky/engine/core/rendering/PaintInfo.h"
#include "sky/engine/core/rendering/RenderBlock.h"
#include "sky/engine/core/rendering/RootInlineBox.h"
#include "sky/engine/core/rendering/TextRunConstructor.h"
#include "sky/engine/core/rendering/style/ShadowList.h"
#include "sky/engine/platform/fonts/Font.h"
#include "sky/engine/platform/graphics/GraphicsContextStateSaver.h"
#include "sky/engine/platform/text/TextRun.h"

namespace blink {

void EllipsisBox::paint(PaintInfo& paintInfo, const LayoutPoint& paintOffset, LayoutUnit lineTop, LayoutUnit lineBottom)
{
    GraphicsContext* context = paintInfo.context;
    RenderStyle* style = renderer().style(isFirstLineStyle());

    const Font& font = style->font();
    FloatPoint boxOrigin = locationIncludingFlipping();
    boxOrigin.moveBy(FloatPoint(paintOffset));
    FloatRect boxRect(boxOrigin, LayoutSize(logicalWidth(), virtualLogicalHeight()));
    GraphicsContextStateSaver stateSaver(*context);
    FloatPoint textOrigin = FloatPoint(boxOrigin.x(), boxOrigin.y() + font.fontMetrics().ascent());

    Color styleTextColor = renderer().resolveColor(style, CSSPropertyWebkitTextFillColor);
    if (styleTextColor != context->fillColor())
        context->setFillColor(styleTextColor);

    if (selectionState() != RenderObject::SelectionNone) {
        paintSelection(context, boxOrigin, style, font);

        // Select the correct color for painting the text.
        Color foreground = renderer().selectionForegroundColor();
        if (foreground != styleTextColor)
            context->setFillColor(foreground);
    }

    const ShadowList* shadowList = style->textShadow();
    bool hasShadow = shadowList;
    if (hasShadow)
        context->setDrawLooper(shadowList->createDrawLooper(DrawLooperBuilder::ShadowIgnoresAlpha));

    TextRun textRun = constructTextRun(&renderer(), font, m_str, style, TextRun::AllowTrailingExpansion);
    TextRunPaintInfo textRunPaintInfo(textRun);
    textRunPaintInfo.bounds = boxRect;
    context->drawText(font, textRunPaintInfo, textOrigin);

    // Restore the regular fill color.
    if (styleTextColor != context->fillColor())
        context->setFillColor(styleTextColor);

    if (hasShadow)
        context->clearDrawLooper();

    paintMarkupBox(paintInfo, paintOffset, lineTop, lineBottom, style);
}

InlineBox* EllipsisBox::markupBox() const
{
    if (!m_shouldPaintMarkupBox || !renderer().isRenderBlock())
        return 0;

    RenderBlock& block = toRenderBlock(renderer());
    RootInlineBox* lastLine = block.lineAtIndex(block.lineCount() - 1);
    if (!lastLine)
        return 0;

    // If the last line-box on the last line of a block is a link, -webkit-line-clamp paints that box after the ellipsis.
    // It does not actually move the link.
    InlineBox* anchorBox = lastLine->lastChild();
    if (!anchorBox || !anchorBox->renderer().style()->isLink())
        return 0;

    return anchorBox;
}

void EllipsisBox::paintMarkupBox(PaintInfo& paintInfo, const LayoutPoint& paintOffset, LayoutUnit lineTop, LayoutUnit lineBottom, RenderStyle* style)
{
    InlineBox* markupBox = this->markupBox();
    if (!markupBox)
        return;

    LayoutPoint adjustedPaintOffset = paintOffset;
    adjustedPaintOffset.move(x() + m_logicalWidth - markupBox->x(),
        y() + style->fontMetrics().ascent() - (markupBox->y() + markupBox->renderer().style(isFirstLineStyle())->fontMetrics().ascent()));
    markupBox->paint(paintInfo, adjustedPaintOffset, lineTop, lineBottom);
}

IntRect EllipsisBox::selectionRect()
{
    RenderStyle* style = renderer().style(isFirstLineStyle());
    const Font& font = style->font();
    return enclosingIntRect(font.selectionRectForText(constructTextRun(&renderer(), font, m_str, style, TextRun::AllowTrailingExpansion), IntPoint(logicalLeft(), logicalTop() + root().selectionTopAdjustedForPrecedingBlock()), root().selectionHeightAdjustedForPrecedingBlock()));
}

void EllipsisBox::paintSelection(GraphicsContext* context, const FloatPoint& boxOrigin, RenderStyle* style, const Font& font)
{
    Color textColor = renderer().resolveColor(style, CSSPropertyColor);
    Color c = renderer().selectionBackgroundColor();
    if (!c.alpha())
        return;

    // If the text color ends up being the same as the selection background, invert the selection
    // background.
    if (textColor == c)
        c = Color(0xff - c.red(), 0xff - c.green(), 0xff - c.blue());

    GraphicsContextStateSaver stateSaver(*context);
    LayoutUnit top = root().selectionTop();
    LayoutUnit h = root().selectionHeight();
    const int deltaY = roundToInt(logicalTop() - top);
    const FloatPoint localOrigin(boxOrigin.x(), boxOrigin.y() - deltaY);
    FloatRect clipRect(localOrigin, FloatSize(m_logicalWidth, h.toFloat()));
    context->clip(clipRect);
    context->drawHighlightForText(font, constructTextRun(&renderer(), font, m_str, style, TextRun::AllowTrailingExpansion), localOrigin, h, c);
}

bool EllipsisBox::nodeAtPoint(const HitTestRequest& request, HitTestResult& result, const HitTestLocation& locationInContainer, const LayoutPoint& accumulatedOffset, LayoutUnit lineTop, LayoutUnit lineBottom)
{
    LayoutPoint adjustedLocation = accumulatedOffset + roundedLayoutPoint(topLeft());

    // Hit test the markup box.
    if (InlineBox* markupBox = this->markupBox()) {
        RenderStyle* style = renderer().style(isFirstLineStyle());
        LayoutUnit mtx = adjustedLocation.x() + m_logicalWidth - markupBox->x();
        LayoutUnit mty = adjustedLocation.y() + style->fontMetrics().ascent() - (markupBox->y() + markupBox->renderer().style(isFirstLineStyle())->fontMetrics().ascent());
        if (markupBox->nodeAtPoint(request, result, locationInContainer, LayoutPoint(mtx, mty), lineTop, lineBottom)) {
            renderer().updateHitTestResult(result, locationInContainer.point() - LayoutSize(mtx, mty));
            return true;
        }
    }

    FloatPoint boxOrigin = locationIncludingFlipping();
    boxOrigin.moveBy(accumulatedOffset);
    FloatRect boundsRect(boxOrigin, size());
    if (visibleToHitTestRequest(request) && boundsRect.intersects(HitTestLocation::rectForPoint(locationInContainer.point(), 0, 0, 0, 0))) {
        renderer().updateHitTestResult(result, locationInContainer.point() - toLayoutSize(adjustedLocation));
        if (!result.addNodeToRectBasedTestResult(renderer().node(), request, locationInContainer, boundsRect))
            return true;
    }

    return false;
}

} // namespace blink
