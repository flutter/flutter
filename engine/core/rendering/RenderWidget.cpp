/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2000 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2004, 2006, 2009, 2010 Apple Inc. All rights reserved.
 * Copyright (C) 2013 Google Inc. All rights reserved.
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

#include "config.h"
#include "core/rendering/RenderWidget.h"

#include "core/frame/LocalFrame.h"
#include "core/rendering/GraphicsContextAnnotator.h"
#include "core/rendering/HitTestResult.h"
#include "core/rendering/RenderLayer.h"
#include "core/rendering/RenderView.h"
#include "core/rendering/compositing/CompositedLayerMapping.h"
#include "core/rendering/compositing/RenderLayerCompositor.h"
#include "wtf/HashMap.h"

namespace blink {

RenderWidget::RenderWidget(Element* element)
    : RenderReplaced(element)
#if !ENABLE(OILPAN)
    // Reference counting is used to prevent the widget from being
    // destroyed while inside the Widget code, which might not be
    // able to handle that.
    , m_refCount(1)
#endif
{
    ASSERT(element);
    frameView()->addWidget(this);
}

void RenderWidget::willBeDestroyed()
{
    frameView()->removeWidget(this);
    RenderReplaced::willBeDestroyed();
}

void RenderWidget::destroy()
{
#if ENABLE(ASSERT) && ENABLE(OILPAN)
    ASSERT(!m_didCallDestroy);
    m_didCallDestroy = true;
#endif
    willBeDestroyed();
    clearNode();
#if ENABLE(OILPAN)
    // In Oilpan, postDestroy doesn't delete |this|. So calling it here is safe
    // though |this| will be referred in FrameView.
    postDestroy();
#else
    deref();
#endif
}

RenderWidget::~RenderWidget()
{
#if !ENABLE(OILPAN)
    ASSERT(m_refCount <= 0);
#endif
}

Widget* RenderWidget::widget() const
{
    return 0;
}

// Widgets are always placed on integer boundaries, so rounding the size is actually
// the desired behavior. This function is here because it's otherwise seldom what we
// want to do with a LayoutRect.
static inline IntRect roundedIntRect(const LayoutRect& rect)
{
    return IntRect(roundedIntPoint(rect.location()), roundedIntSize(rect.size()));
}

bool RenderWidget::setWidgetGeometry(const LayoutRect& frame)
{
    if (!node())
        return false;

    Widget* widget = this->widget();
    ASSERT(widget);

    IntRect newFrame = roundedIntRect(frame);

    if (widget->frameRect() == newFrame)
        return false;

    RefPtr<RenderWidget> protector(this);
    RefPtr<Node> protectedNode(node());
    widget->setFrameRect(newFrame);
    return widget->frameRect().size() != newFrame.size();
}

bool RenderWidget::updateWidgetGeometry()
{
    Widget* widget = this->widget();
    ASSERT(widget);

    LayoutRect contentBox = contentBoxRect();
    LayoutRect absoluteContentBox(localToAbsoluteQuad(FloatQuad(contentBox)).boundingBox());
    if (widget->isFrameView()) {
        contentBox.setLocation(absoluteContentBox.location());
        return setWidgetGeometry(contentBox);
    }

    return setWidgetGeometry(absoluteContentBox);
}

void RenderWidget::layout()
{
    ASSERT(needsLayout());

    clearNeedsLayout();
}

void RenderWidget::styleDidChange(StyleDifference diff, const RenderStyle* oldStyle)
{
    RenderReplaced::styleDidChange(diff, oldStyle);
}

void RenderWidget::paintContents(PaintInfo& paintInfo, const LayoutPoint& paintOffset)
{
    LayoutPoint adjustedPaintOffset = paintOffset + location();

    Widget* widget = this->widget();
    ASSERT(widget);

    // Tell the widget to paint now. This is the only time the widget is allowed
    // to paint itself. That way it will composite properly with z-indexed layers.
    IntPoint widgetLocation = widget->frameRect().location();
    IntPoint paintLocation(roundToInt(adjustedPaintOffset.x() + borderLeft() + paddingLeft()),
        roundToInt(adjustedPaintOffset.y() + borderTop() + paddingTop()));
    IntRect paintRect = paintInfo.rect;

    IntSize widgetPaintOffset = paintLocation - widgetLocation;
    // When painting widgets into compositing layers, tx and ty are relative to the enclosing compositing layer,
    // not the root. In this case, shift the CTM and adjust the paintRect to be root-relative to fix plug-in drawing.
    if (!widgetPaintOffset.isZero()) {
        paintInfo.context->translate(widgetPaintOffset.width(), widgetPaintOffset.height());
        paintRect.move(-widgetPaintOffset);
    }
    widget->paint(paintInfo.context, paintRect);

    if (!widgetPaintOffset.isZero())
        paintInfo.context->translate(-widgetPaintOffset.width(), -widgetPaintOffset.height());
}

void RenderWidget::paint(PaintInfo& paintInfo, const LayoutPoint& paintOffset)
{
    ANNOTATE_GRAPHICS_CONTEXT(paintInfo, this);

    if (!shouldPaint(paintInfo, paintOffset))
        return;

    LayoutPoint adjustedPaintOffset = paintOffset + location();

    if (hasBoxDecorationBackground() && (paintInfo.phase == PaintPhaseForeground || paintInfo.phase == PaintPhaseSelection))
        paintBoxDecorationBackground(paintInfo, adjustedPaintOffset);

    if (paintInfo.phase == PaintPhaseMask) {
        paintMask(paintInfo, adjustedPaintOffset);
        return;
    }

    if ((paintInfo.phase == PaintPhaseOutline || paintInfo.phase == PaintPhaseSelfOutline) && style()->hasOutline())
        paintOutline(paintInfo, LayoutRect(adjustedPaintOffset, size()));

    if (paintInfo.phase != PaintPhaseForeground)
        return;

    if (style()->hasBorderRadius()) {
        LayoutRect borderRect = LayoutRect(adjustedPaintOffset, size());

        if (borderRect.isEmpty())
            return;

        // Push a clip if we have a border radius, since we want to round the foreground content that gets painted.
        paintInfo.context->save();
        RoundedRect roundedInnerRect = style()->getRoundedInnerBorderFor(borderRect,
            paddingTop() + borderTop(), paddingBottom() + borderBottom(), paddingLeft() + borderLeft(), paddingRight() + borderRight(), true, true);
        clipRoundedInnerRect(paintInfo.context, borderRect, roundedInnerRect);
    }

    Widget* widget = this->widget();
    if (widget)
        paintContents(paintInfo, paintOffset);

    if (style()->hasBorderRadius())
        paintInfo.context->restore();

    // Paint a partially transparent wash over selected widgets.
    if (isSelected()) {
        LayoutRect rect = localSelectionRect();
        rect.moveBy(adjustedPaintOffset);
        paintInfo.context->fillRect(pixelSnappedIntRect(rect), selectionBackgroundColor());
    }

    if (canResize())
        layer()->scrollableArea()->paintResizer(paintInfo.context, roundedIntPoint(adjustedPaintOffset), paintInfo.rect);
}

#if !ENABLE(OILPAN)
void RenderWidget::deref()
{
    if (--m_refCount <= 0)
        postDestroy();
}
#endif

void RenderWidget::updateOnWidgetChange()
{
    Widget* widget = this->widget();
    if (!widget)
        return;

    if (!style())
        return;

    if (!needsLayout())
        updateWidgetGeometry();
}

void RenderWidget::updateWidgetPosition()
{
    Widget* widget = this->widget();
    if (!widget || !node()) // Check the node in case destroy() has been called.
        return;

    bool boundsChanged = updateWidgetGeometry();

    // if the frame bounds got changed, or if view needs layout (possibly indicating
    // content size is wrong) we have to do a layout to set the right widget size
    if (widget && widget->isFrameView()) {
        FrameView* frameView = toFrameView(widget);
        // Check the frame's page to make sure that the frame isn't in the process of being destroyed.
        if ((boundsChanged || frameView->needsLayout()) && frameView->frame().page())
            frameView->layout();
    }
}

void RenderWidget::widgetPositionsUpdated()
{
    Widget* widget = this->widget();
    if (!widget)
        return;
    widget->widgetPositionsUpdated();
}

bool RenderWidget::nodeAtPoint(const HitTestRequest& request, HitTestResult& result, const HitTestLocation& locationInContainer, const LayoutPoint& accumulatedOffset, HitTestAction action)
{
    bool hadResult = result.innerNode();
    bool inside = RenderReplaced::nodeAtPoint(request, result, locationInContainer, accumulatedOffset, action);

    // Check to see if we are really over the widget itself (and not just in the border/padding area).
    if ((inside || result.isRectBasedTest()) && !hadResult && result.innerNode() == node())
        result.setIsOverWidget(contentBoxRect().contains(result.localPoint()));
    return inside;
}

CursorDirective RenderWidget::getCursor(const LayoutPoint& point, Cursor& cursor) const
{
    return RenderReplaced::getCursor(point, cursor);
}

} // namespace blink
