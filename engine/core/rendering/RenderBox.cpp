/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2005 Allan Sandfeld Jensen (kde@carewolf.com)
 *           (C) 2005, 2006 Samuel Weinig (sam.weinig@gmail.com)
 * Copyright (C) 2005, 2006, 2007, 2008, 2009, 2010 Apple Inc. All rights reserved.
 * Copyright (C) 2013 Adobe Systems Incorporated. All rights reserved.
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
#include "sky/engine/core/rendering/RenderBox.h"

#include <math.h>
#include <algorithm>
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/editing/htmlediting.h"
#include "sky/engine/core/frame/FrameHost.h"
#include "sky/engine/core/frame/FrameView.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/frame/Settings.h"
#include "sky/engine/core/html/HTMLElement.h"
#include "sky/engine/core/page/AutoscrollController.h"
#include "sky/engine/core/page/EventHandler.h"
#include "sky/engine/core/page/Page.h"
#include "sky/engine/core/rendering/HitTestResult.h"
#include "sky/engine/core/rendering/PaintInfo.h"
#include "sky/engine/core/rendering/RenderFlexibleBox.h"
#include "sky/engine/core/rendering/RenderGeometryMap.h"
#include "sky/engine/core/rendering/RenderInline.h"
#include "sky/engine/core/rendering/RenderLayer.h"
#include "sky/engine/core/rendering/RenderView.h"
#include "sky/engine/platform/LengthFunctions.h"
#include "sky/engine/platform/geometry/FloatQuad.h"
#include "sky/engine/platform/geometry/TransformState.h"
#include "sky/engine/platform/graphics/GraphicsContextStateSaver.h"

namespace blink {

// Size of border belt for autoscroll. When mouse pointer in border belt,
// autoscroll is started.
static const int autoscrollBeltSize = 20;
static const unsigned backgroundObscurationTestMaxDepth = 4;

RenderBox::RenderBox(ContainerNode* node)
    : RenderBoxModelObject(node)
    , m_intrinsicContentLogicalHeight(-1)
    , m_minPreferredLogicalWidth(-1)
    , m_maxPreferredLogicalWidth(-1)
{
    setIsBox();
}

void RenderBox::willBeDestroyed()
{
    clearOverrideSize();
    RenderBlock::removePercentHeightDescendantIfNeeded(this);
    RenderBoxModelObject::willBeDestroyed();
}

void RenderBox::removeFloatingOrPositionedChildFromBlockLists()
{
    ASSERT(isFloatingOrOutOfFlowPositioned());

    if (documentBeingDestroyed())
        return;

    if (isOutOfFlowPositioned())
        RenderBlock::removePositionedObject(this);
}

void RenderBox::styleWillChange(StyleDifference diff, const RenderStyle& newStyle)
{
    RenderStyle* oldStyle = style();
    if (oldStyle) {
        // When a layout hint happens and an object's position style changes, we have to do a layout
        // to dirty the render tree using the old position value now.
        if (diff.needsFullLayout() && parent() && oldStyle->position() != newStyle.position()) {
            markContainingBlocksForLayout();
            if (newStyle.hasOutOfFlowPosition())
                parent()->setChildNeedsLayout();
        }
    }

    RenderBoxModelObject::styleWillChange(diff, newStyle);
}

void RenderBox::styleDidChange(StyleDifference diff, const RenderStyle* oldStyle)
{
    RenderBoxModelObject::styleDidChange(diff, oldStyle);

    RenderStyle* newStyle = style();
    if (needsLayout() && oldStyle) {
        RenderBlock::removePercentHeightDescendantIfNeeded(this);

        // Normally we can do optimized positioning layout for absolute/fixed positioned objects. There is one special case, however, which is
        // when the positioned object's margin-before is changed. In this case the parent has to get a layout in order to run margin collapsing
        // to determine the new static position.
        if (isOutOfFlowPositioned() && newStyle->hasStaticBlockPosition() && oldStyle->marginBefore() != newStyle->marginBefore()
            && parent() && !parent()->normalChildNeedsLayout())
            parent()->setChildNeedsLayout();
    }

    // Our opaqueness might have changed without triggering layout.
    if (diff.needsPaintInvalidation()) {
        RenderObject* parentToInvalidate = parent();
        for (unsigned i = 0; i < backgroundObscurationTestMaxDepth && parentToInvalidate; ++i) {
            parentToInvalidate->invalidateBackgroundObscurationStatus();
            parentToInvalidate = parentToInvalidate->parent();
        }
    }
}

void RenderBox::updateFromStyle()
{
    RenderBoxModelObject::updateFromStyle();

    RenderStyle* styleToUse = style();
    bool isRootObject = isDocumentElement();
    bool isViewObject = isRenderView();

    // The root and the RenderView always paint their backgrounds/borders.
    if (isRootObject || isViewObject)
        setHasBoxDecorationBackground(true);

    bool boxHasOverflowClip = false;
    if (!styleToUse->isOverflowVisible() && isRenderBlock() && !isViewObject) {
        // If overflow has been propagated to the viewport, it has no effect here.
        if (node() != document().viewportDefiningElement())
            boxHasOverflowClip = true;
    }

    setHasOverflowClip(boxHasOverflowClip);
    setHasTransform(styleToUse->hasTransformRelatedProperty());
}

void RenderBox::layout()
{
    ASSERT(needsLayout());

    RenderObject* child = slowFirstChild();
    if (!child) {
        clearNeedsLayout();
        return;
    }

    LayoutState state(*this, locationOffset());
    while (child) {
        child->layoutIfNeeded();
        ASSERT(!child->needsLayout());
        child = child->nextSibling();
    }
    invalidateBackgroundObscurationStatus();
    clearNeedsLayout();
}

// More IE extensions.  clientWidth and clientHeight represent the interior of an object
// excluding border and scrollbar.
LayoutUnit RenderBox::clientWidth() const
{
    return width() - borderLeft() - borderRight();
}

LayoutUnit RenderBox::clientHeight() const
{
    return height() - borderTop() - borderBottom();
}

int RenderBox::pixelSnappedClientWidth() const
{
    return snapSizeToPixel(clientWidth(), x() + clientLeft());
}

int RenderBox::pixelSnappedClientHeight() const
{
    return snapSizeToPixel(clientHeight(), y() + clientTop());
}

int RenderBox::pixelSnappedOffsetWidth() const
{
    return snapSizeToPixel(offsetWidth(), x() + clientLeft());
}

int RenderBox::pixelSnappedOffsetHeight() const
{
    return snapSizeToPixel(offsetHeight(), y() + clientTop());
}

LayoutUnit RenderBox::scrollWidth() const
{
    if (hasOverflowClip())
        return layer()->scrollableArea()->scrollWidth();
    // For objects with visible overflow, this matches IE.
    // FIXME: Need to work right with writing modes.
    if (style()->isLeftToRightDirection())
        return std::max(clientWidth(), layoutOverflowRect().maxX() - borderLeft());
    return clientWidth() - std::min<LayoutUnit>(0, layoutOverflowRect().x() - borderLeft());
}

LayoutUnit RenderBox::scrollHeight() const
{
    if (hasOverflowClip())
        return layer()->scrollableArea()->scrollHeight();
    // For objects with visible overflow, this matches IE.
    // FIXME: Need to work right with writing modes.
    return std::max(clientHeight(), layoutOverflowRect().maxY() - borderTop());
}

LayoutUnit RenderBox::scrollLeft() const
{
    return hasOverflowClip() ? layer()->scrollableArea()->scrollXOffset() : 0;
}

LayoutUnit RenderBox::scrollTop() const
{
    return hasOverflowClip() ? layer()->scrollableArea()->scrollYOffset() : 0;
}

int RenderBox::pixelSnappedScrollWidth() const
{
    return snapSizeToPixel(scrollWidth(), x() + clientLeft());
}

int RenderBox::pixelSnappedScrollHeight() const
{
    if (hasOverflowClip())
        return layer()->scrollableArea()->scrollHeight();
    // For objects with visible overflow, this matches IE.
    // FIXME: Need to work right with writing modes.
    return snapSizeToPixel(scrollHeight(), y() + clientTop());
}

void RenderBox::setScrollLeft(LayoutUnit newLeft)
{
    if (hasOverflowClip())
        layer()->scrollableArea()->scrollToXOffset(newLeft, ScrollOffsetClamped);
}

void RenderBox::setScrollTop(LayoutUnit newTop)
{
    if (hasOverflowClip())
        layer()->scrollableArea()->scrollToYOffset(newTop, ScrollOffsetClamped);
}

void RenderBox::scrollToOffset(const IntSize& offset)
{
    ASSERT(hasOverflowClip());
    layer()->scrollableArea()->scrollToOffset(offset, ScrollOffsetClamped);
}

void RenderBox::scrollRectToVisible(const LayoutRect& rect, const ScrollAlignment& alignX, const ScrollAlignment& alignY)
{
    RenderBox* parentBox = 0;
    LayoutRect newRect = rect;

    if (parent()) {
        parentBox = parent()->enclosingBox();
    }

    if (hasOverflowClip()) {
        // Don't scroll to reveal an overflow layer that is restricted by the -webkit-line-clamp property.
        // This will prevent us from revealing text hidden by the slider in Safari RSS.
        newRect = layer()->scrollableArea()->exposeRect(rect, alignX, alignY);
    }

    if (frame()->page()->autoscrollController().autoscrollInProgress())
        parentBox = enclosingScrollableBox();

    if (parentBox)
        parentBox->scrollRectToVisible(newRect, alignX, alignY);
}

void RenderBox::absoluteRects(Vector<IntRect>& rects, const LayoutPoint& accumulatedOffset) const
{
    rects.append(pixelSnappedIntRect(accumulatedOffset, size()));
}

void RenderBox::absoluteQuads(Vector<FloatQuad>& quads) const
{
    quads.append(localToAbsoluteQuad(FloatRect(0, 0, width().toFloat(), height().toFloat()), 0 /* mode */));
}

void RenderBox::updateLayerTransformAfterLayout()
{
    // Transform-origin depends on box size, so we need to update the layer transform after layout.
    if (hasLayer())
        layer()->updateTransformationMatrix();
}

LayoutUnit RenderBox::constrainLogicalWidthByMinMax(LayoutUnit logicalWidth, LayoutUnit availableWidth, RenderBlock* cb) const
{
    RenderStyle* styleToUse = style();
    if (!styleToUse->logicalMaxWidth().isMaxSizeNone())
        logicalWidth = std::min(logicalWidth, computeLogicalWidthUsing(MaxSize, styleToUse->logicalMaxWidth(), availableWidth, cb));
    return std::max(logicalWidth, computeLogicalWidthUsing(MinSize, styleToUse->logicalMinWidth(), availableWidth, cb));
}

LayoutUnit RenderBox::constrainLogicalHeightByMinMax(LayoutUnit logicalHeight, LayoutUnit intrinsicContentHeight) const
{
    RenderStyle* styleToUse = style();
    if (!styleToUse->logicalMaxHeight().isMaxSizeNone()) {
        LayoutUnit maxH = computeLogicalHeightUsing(styleToUse->logicalMaxHeight(), intrinsicContentHeight);
        if (maxH != -1)
            logicalHeight = std::min(logicalHeight, maxH);
    }
    return std::max(logicalHeight, computeLogicalHeightUsing(styleToUse->logicalMinHeight(), intrinsicContentHeight));
}

LayoutUnit RenderBox::constrainContentBoxLogicalHeightByMinMax(LayoutUnit logicalHeight, LayoutUnit intrinsicContentHeight) const
{
    RenderStyle* styleToUse = style();
    if (!styleToUse->logicalMaxHeight().isMaxSizeNone()) {
        LayoutUnit maxH = computeContentLogicalHeight(styleToUse->logicalMaxHeight(), intrinsicContentHeight);
        if (maxH != -1)
            logicalHeight = std::min(logicalHeight, maxH);
    }
    return std::max(logicalHeight, computeContentLogicalHeight(styleToUse->logicalMinHeight(), intrinsicContentHeight));
}

IntRect RenderBox::absoluteContentBox() const
{
    // This is wrong with transforms and flipped writing modes.
    IntRect rect = pixelSnappedIntRect(contentBoxRect());
    FloatPoint absPos = localToAbsolute();
    rect.move(absPos.x(), absPos.y());
    return rect;
}

FloatQuad RenderBox::absoluteContentQuad() const
{
    LayoutRect rect = contentBoxRect();
    return localToAbsoluteQuad(FloatRect(rect));
}

void RenderBox::addFocusRingRects(Vector<IntRect>& rects, const LayoutPoint& additionalOffset, const RenderLayerModelObject*) const
{
    if (!size().isEmpty())
        rects.append(pixelSnappedIntRect(additionalOffset, size()));
}

bool RenderBox::scroll(ScrollDirection direction, ScrollGranularity granularity, float delta)
{
    if (!layer() || !layer()->scrollableArea())
        return false;
    return layer()->scrollableArea()->scroll(direction, granularity, delta);
}

bool RenderBox::canBeScrolledAndHasScrollableArea() const
{
    return canBeProgramaticallyScrolled() && (pixelSnappedScrollHeight() != pixelSnappedClientHeight() || pixelSnappedScrollWidth() != pixelSnappedClientWidth());
}

bool RenderBox::canBeProgramaticallyScrolled() const
{
    Node* node = this->node();
    if (node && node->isDocumentNode())
        return true;

    if (!hasOverflowClip())
        return false;

    bool hasScrollableOverflow = hasScrollableOverflowX() || hasScrollableOverflowY();
    if (scrollsOverflow() && hasScrollableOverflow)
        return true;

    return node && node->hasEditableStyle();
}

void RenderBox::autoscroll(const IntPoint& position)
{
    LocalFrame* frame = this->frame();
    if (!frame)
        return;

    FrameView* frameView = frame->view();
    if (!frameView)
        return;

    IntPoint currentDocumentPosition = frameView->windowToContents(position);
    scrollRectToVisible(LayoutRect(currentDocumentPosition, LayoutSize(1, 1)), ScrollAlignment::alignToEdgeIfNeeded, ScrollAlignment::alignToEdgeIfNeeded);
}

bool RenderBox::autoscrollInProgress() const
{
    return frame() && frame()->page() && frame()->page()->autoscrollController().autoscrollInProgress(this);
}

// FIXME(sky): Replace with canBeScrolledAndHasScrollableArea.
bool RenderBox::canAutoscroll() const
{
    return canBeScrolledAndHasScrollableArea();
}

// If specified point is in border belt, returned offset denotes direction of
// scrolling.
IntSize RenderBox::calculateAutoscrollDirection(const IntPoint& windowPoint) const
{
    if (!frame())
        return IntSize();

    FrameView* frameView = frame()->view();
    if (!frameView)
        return IntSize();

    IntRect box(absoluteBoundingBoxRect());
    IntRect windowBox = view()->frameView()->contentsToWindow(box);

    IntPoint windowAutoscrollPoint = windowPoint;

    if (windowAutoscrollPoint.x() < windowBox.x() + autoscrollBeltSize)
        windowAutoscrollPoint.move(-autoscrollBeltSize, 0);
    else if (windowAutoscrollPoint.x() > windowBox.maxX() - autoscrollBeltSize)
        windowAutoscrollPoint.move(autoscrollBeltSize, 0);

    if (windowAutoscrollPoint.y() < windowBox.y() + autoscrollBeltSize)
        windowAutoscrollPoint.move(0, -autoscrollBeltSize);
    else if (windowAutoscrollPoint.y() > windowBox.maxY() - autoscrollBeltSize)
        windowAutoscrollPoint.move(0, autoscrollBeltSize);

    return windowAutoscrollPoint - windowPoint;
}

RenderBox* RenderBox::findAutoscrollable(RenderObject* renderer)
{
    while (renderer && !(renderer->isBox() && toRenderBox(renderer)->canAutoscroll())) {
        renderer = renderer->parent();
    }

    return renderer && renderer->isBox() ? toRenderBox(renderer) : 0;
}

void RenderBox::scrollByRecursively(const IntSize& delta, ScrollOffsetClamping clamp)
{
    if (delta.isZero())
        return;

    if (hasOverflowClip()) {
        IntSize newScrollOffset = layer()->scrollableArea()->adjustedScrollOffset() + delta;
        layer()->scrollableArea()->scrollToOffset(newScrollOffset, clamp);

        // If this layer can't do the scroll we ask the next layer up that can scroll to try
        IntSize remainingScrollOffset = newScrollOffset - layer()->scrollableArea()->adjustedScrollOffset();
        if (!remainingScrollOffset.isZero() && parent()) {
            if (RenderBox* scrollableBox = enclosingScrollableBox())
                scrollableBox->scrollByRecursively(remainingScrollOffset, clamp);

            LocalFrame* frame = this->frame();
            if (frame && frame->page())
                frame->page()->autoscrollController().updateAutoscrollRenderer();
        }
    }
}

bool RenderBox::needsPreferredWidthsRecalculation() const
{
    return style()->paddingStart().isPercent() || style()->paddingEnd().isPercent();
}

IntSize RenderBox::scrolledContentOffset() const
{
    ASSERT(hasOverflowClip());
    ASSERT(hasLayer());
    return layer()->scrollableArea()->scrollOffset();
}

void RenderBox::computeIntrinsicLogicalWidths(LayoutUnit& minLogicalWidth, LayoutUnit& maxLogicalWidth) const
{
    minLogicalWidth = minPreferredLogicalWidth() - borderAndPaddingLogicalWidth();
    maxLogicalWidth = maxPreferredLogicalWidth() - borderAndPaddingLogicalWidth();
}

LayoutUnit RenderBox::minPreferredLogicalWidth() const
{
    if (preferredLogicalWidthsDirty()) {
#if ENABLE(ASSERT)
        SetLayoutNeededForbiddenScope layoutForbiddenScope(const_cast<RenderBox&>(*this));
#endif
        const_cast<RenderBox*>(this)->computePreferredLogicalWidths();
    }

    return m_minPreferredLogicalWidth;
}

LayoutUnit RenderBox::maxPreferredLogicalWidth() const
{
    if (preferredLogicalWidthsDirty()) {
#if ENABLE(ASSERT)
        SetLayoutNeededForbiddenScope layoutForbiddenScope(const_cast<RenderBox&>(*this));
#endif
        const_cast<RenderBox*>(this)->computePreferredLogicalWidths();
    }

    return m_maxPreferredLogicalWidth;
}

bool RenderBox::hasOverrideHeight() const
{
    return m_rareData && m_rareData->m_overrideLogicalContentHeight != -1;
}

bool RenderBox::hasOverrideWidth() const
{
    return m_rareData && m_rareData->m_overrideLogicalContentWidth != -1;
}

void RenderBox::setOverrideLogicalContentHeight(LayoutUnit height)
{
    ASSERT(height >= 0);
    ensureRareData().m_overrideLogicalContentHeight = height;
}

void RenderBox::setOverrideLogicalContentWidth(LayoutUnit width)
{
    ASSERT(width >= 0);
    ensureRareData().m_overrideLogicalContentWidth = width;
}

void RenderBox::clearOverrideLogicalContentHeight()
{
    if (m_rareData)
        m_rareData->m_overrideLogicalContentHeight = -1;
}

void RenderBox::clearOverrideLogicalContentWidth()
{
    if (m_rareData)
        m_rareData->m_overrideLogicalContentWidth = -1;
}

void RenderBox::clearOverrideSize()
{
    clearOverrideLogicalContentHeight();
    clearOverrideLogicalContentWidth();
}

LayoutUnit RenderBox::overrideLogicalContentWidth() const
{
    ASSERT(hasOverrideWidth());
    return m_rareData->m_overrideLogicalContentWidth;
}

LayoutUnit RenderBox::overrideLogicalContentHeight() const
{
    ASSERT(hasOverrideHeight());
    return m_rareData->m_overrideLogicalContentHeight;
}

LayoutUnit RenderBox::adjustBorderBoxLogicalWidthForBoxSizing(LayoutUnit width) const
{
    LayoutUnit bordersPlusPadding = borderAndPaddingLogicalWidth();
    if (style()->boxSizing() == CONTENT_BOX)
        return width + bordersPlusPadding;
    return std::max(width, bordersPlusPadding);
}

LayoutUnit RenderBox::adjustBorderBoxLogicalHeightForBoxSizing(LayoutUnit height) const
{
    LayoutUnit bordersPlusPadding = borderAndPaddingLogicalHeight();
    if (style()->boxSizing() == CONTENT_BOX)
        return height + bordersPlusPadding;
    return std::max(height, bordersPlusPadding);
}

LayoutUnit RenderBox::adjustContentBoxLogicalWidthForBoxSizing(LayoutUnit width) const
{
    if (style()->boxSizing() == BORDER_BOX)
        width -= borderAndPaddingLogicalWidth();
    return std::max<LayoutUnit>(0, width);
}

LayoutUnit RenderBox::adjustContentBoxLogicalHeightForBoxSizing(LayoutUnit height) const
{
    if (style()->boxSizing() == BORDER_BOX)
        height -= borderAndPaddingLogicalHeight();
    return std::max<LayoutUnit>(0, height);
}

bool RenderBox::nodeAtPoint(const HitTestRequest& request, HitTestResult& result, const HitTestLocation& locationInContainer, const LayoutPoint& accumulatedOffset, HitTestAction action)
{
    LayoutPoint adjustedLocation = accumulatedOffset + location();

    // Check kids first.
    for (RenderObject* child = slowLastChild(); child; child = child->previousSibling()) {
        if ((!child->hasLayer() || !toRenderLayerModelObject(child)->layer()->isSelfPaintingLayer()) && child->nodeAtPoint(request, result, locationInContainer, adjustedLocation, action)) {
            updateHitTestResult(result, locationInContainer.point() - toLayoutSize(adjustedLocation));
            return true;
        }
    }

    // Check our bounds next. For this purpose always assume that we can only be hit in the
    // foreground phase (which is true for replaced elements like images).
    LayoutRect boundsRect = borderBoxRect();
    boundsRect.moveBy(adjustedLocation);
    if (visibleToHitTestRequest(request) && action == HitTestForeground && locationInContainer.intersects(boundsRect)) {
        updateHitTestResult(result, locationInContainer.point() - toLayoutSize(adjustedLocation));
        if (!result.addNodeToRectBasedTestResult(node(), request, locationInContainer, boundsRect))
            return true;
    }

    return false;
}

// --------------------- painting stuff -------------------------------

void RenderBox::paint(PaintInfo& paintInfo, const LayoutPoint& paintOffset)
{
    LayoutPoint adjustedPaintOffset = paintOffset + location();
    // default implementation. Just pass paint through to the children
    PaintInfo childInfo(paintInfo);
    childInfo.updatePaintingRootForChildren(this);
    for (RenderObject* child = slowFirstChild(); child; child = child->nextSibling())
        child->paint(childInfo, adjustedPaintOffset);
}

void RenderBox::paintRootBoxFillLayers(const PaintInfo& paintInfo)
{
    const FillLayer& bgLayer = style()->backgroundLayers();
    Color bgColor = resolveColor(CSSPropertyBackgroundColor);

    paintFillLayers(paintInfo, bgColor, bgLayer, view()->backgroundRect(this), BackgroundBleedNone, this);
}

BackgroundBleedAvoidance RenderBox::determineBackgroundBleedAvoidance(GraphicsContext* context, const BoxDecorationData& boxDecorationData) const
{
    if (!boxDecorationData.hasBackground || !boxDecorationData.hasBorder || !style()->hasBorderRadius() || canRenderBorderImage())
        return BackgroundBleedNone;

    // FIXME: See crbug.com/382491. getCTM does not accurately reflect the scale at the time content is
    // rasterized, and should not be relied on to make decisions about bleeding.
    AffineTransform ctm = context->getCTM();
    FloatSize contextScaling(static_cast<float>(ctm.xScale()), static_cast<float>(ctm.yScale()));

    // Because RoundedRect uses IntRect internally the inset applied by the
    // BackgroundBleedShrinkBackground strategy cannot be less than one integer
    // layout coordinate, even with subpixel layout enabled. To take that into
    // account, we clamp the contextScaling to 1.0 for the following test so
    // that borderObscuresBackgroundEdge can only return true if the border
    // widths are greater than 2 in both layout coordinates and screen
    // coordinates.
    // This precaution will become obsolete if RoundedRect is ever promoted to
    // a sub-pixel representation.
    if (contextScaling.width() > 1)
        contextScaling.setWidth(1);
    if (contextScaling.height() > 1)
        contextScaling.setHeight(1);

    if (borderObscuresBackgroundEdge(contextScaling))
        return BackgroundBleedShrinkBackground;
    if (borderObscuresBackground() && backgroundHasOpaqueTopLayer())
        return BackgroundBleedBackgroundOverBorder;

    return BackgroundBleedClipBackground;
}

void RenderBox::paintBoxDecorationBackground(PaintInfo& paintInfo, const LayoutPoint& paintOffset)
{
    if (!paintInfo.shouldPaintWithinRoot(this))
        return;

    LayoutRect paintRect = borderBoxRect();
    paintRect.moveBy(paintOffset);
    paintBoxDecorationBackgroundWithRect(paintInfo, paintOffset, paintRect);
}

void RenderBox::paintBoxDecorationBackgroundWithRect(PaintInfo& paintInfo, const LayoutPoint& paintOffset, const LayoutRect& paintRect)
{
    RenderStyle* style = this->style();
    BoxDecorationData boxDecorationData(*style);
    BackgroundBleedAvoidance bleedAvoidance = determineBackgroundBleedAvoidance(paintInfo.context, boxDecorationData);

    // FIXME: Should eventually give the theme control over whether the box shadow should paint, since controls could have
    // custom shadows of their own.
    if (!boxShadowShouldBeAppliedToBackground(bleedAvoidance))
        paintBoxShadow(paintInfo, paintRect, style, Normal);

    GraphicsContextStateSaver stateSaver(*paintInfo.context, false);
    if (bleedAvoidance == BackgroundBleedClipBackground) {
        stateSaver.save();
        RoundedRect border = style->getRoundedBorderFor(paintRect);
        paintInfo.context->clipRoundedRect(border);
    }

    if (bleedAvoidance == BackgroundBleedBackgroundOverBorder)
        paintBorder(paintInfo, paintRect, style, bleedAvoidance);

    paintBackground(paintInfo, paintRect, boxDecorationData.backgroundColor, bleedAvoidance);
    paintBoxShadow(paintInfo, paintRect, style, Inset);

    // The theme will tell us whether or not we should also paint the CSS border.
    if (boxDecorationData.hasBorder && bleedAvoidance != BackgroundBleedBackgroundOverBorder)
        paintBorder(paintInfo, paintRect, style, bleedAvoidance);
}

void RenderBox::paintBackground(const PaintInfo& paintInfo, const LayoutRect& paintRect, const Color& backgroundColor, BackgroundBleedAvoidance bleedAvoidance)
{
    if (isDocumentElement()) {
        paintRootBoxFillLayers(paintInfo);
        return;
    }
    if (boxDecorationBackgroundIsKnownToBeObscured())
        return;
    paintFillLayers(paintInfo, backgroundColor, style()->backgroundLayers(), paintRect, bleedAvoidance);
}

bool RenderBox::getBackgroundPaintedExtent(LayoutRect& paintedExtent) const
{
    ASSERT(hasBackground());
    LayoutRect backgroundRect = pixelSnappedIntRect(borderBoxRect());

    Color backgroundColor = resolveColor(CSSPropertyBackgroundColor);
    if (backgroundColor.alpha()) {
        paintedExtent = backgroundRect;
        return true;
    }

    if (!style()->backgroundLayers().image() || style()->backgroundLayers().next()) {
        paintedExtent =  backgroundRect;
        return true;
    }

    BackgroundImageGeometry geometry;
    calculateBackgroundImageGeometry(0, style()->backgroundLayers(), backgroundRect, geometry);
    if (geometry.hasNonLocalGeometry())
        return false;
    paintedExtent = geometry.destRect();
    return true;
}

bool RenderBox::backgroundIsKnownToBeOpaqueInRect(const LayoutRect& localRect) const
{
    Color backgroundColor = resolveColor(CSSPropertyBackgroundColor);
    if (backgroundColor.hasAlpha())
        return false;

    // FIXME: Check the opaqueness of background images.

    // FIXME: Use rounded rect if border radius is present.
    if (style()->hasBorderRadius())
        return false;
    // FIXME: The background color clip is defined by the last layer.
    if (style()->backgroundLayers().next())
        return false;
    LayoutRect backgroundRect;
    switch (style()->backgroundClip()) {
    case BorderFillBox:
        backgroundRect = borderBoxRect();
        break;
    case PaddingFillBox:
        backgroundRect = paddingBoxRect();
        break;
    case ContentFillBox:
        backgroundRect = contentBoxRect();
        break;
    default:
        break;
    }
    return backgroundRect.contains(localRect);
}

static bool isCandidateForOpaquenessTest(RenderBox* childBox)
{
    RenderStyle* childStyle = childBox->style();
    if (childStyle->position() != StaticPosition && childBox->containingBlock() != childBox->parent())
        return false;
    if (!childBox->width() || !childBox->height())
        return false;
    if (RenderLayer* childLayer = childBox->layer()) {
        // FIXME: Deal with z-index.
        if (!childStyle->hasAutoZIndex())
            return false;
        if (childLayer->hasTransform() || childLayer->isTransparent() || childLayer->hasFilter())
            return false;
        if (childBox->hasOverflowClip() && childStyle->hasBorderRadius())
            return false;
    }
    return true;
}

bool RenderBox::foregroundIsKnownToBeOpaqueInRect(const LayoutRect& localRect, unsigned maxDepthToTest) const
{
    if (!maxDepthToTest)
        return false;
    for (RenderObject* child = slowFirstChild(); child; child = child->nextSibling()) {
        if (!child->isBox())
            continue;
        RenderBox* childBox = toRenderBox(child);
        if (!isCandidateForOpaquenessTest(childBox))
            continue;
        LayoutPoint childLocation = childBox->location();
        if (childBox->isRelPositioned())
            childLocation.move(childBox->relativePositionOffset());
        LayoutRect childLocalRect = localRect;
        childLocalRect.moveBy(-childLocation);
        if (childLocalRect.y() < 0 || childLocalRect.x() < 0) {
            // If there is unobscured area above/left of a static positioned box then the rect is probably not covered.
            if (childBox->style()->position() == StaticPosition)
                return false;
            continue;
        }
        if (childLocalRect.maxY() > childBox->height() || childLocalRect.maxX() > childBox->width())
            continue;
        if (childBox->backgroundIsKnownToBeOpaqueInRect(childLocalRect))
            return true;
        if (childBox->foregroundIsKnownToBeOpaqueInRect(childLocalRect, maxDepthToTest - 1))
            return true;
    }
    return false;
}

bool RenderBox::computeBackgroundIsKnownToBeObscured()
{
    // Test to see if the children trivially obscure the background.
    // FIXME: This test can be much more comprehensive.
    if (!hasBackground())
        return false;
    // Table and root background painting is special.
    if (isDocumentElement())
        return false;
    // FIXME: box-shadow is painted while background painting.
    if (style()->boxShadow())
        return false;
    LayoutRect backgroundRect;
    if (!getBackgroundPaintedExtent(backgroundRect))
        return false;
    return foregroundIsKnownToBeOpaqueInRect(backgroundRect, backgroundObscurationTestMaxDepth);
}

bool RenderBox::backgroundHasOpaqueTopLayer() const
{
    const FillLayer& fillLayer = style()->backgroundLayers();
    if (fillLayer.clip() != BorderFillBox)
        return false;

    // Clipped with local scrolling
    if (hasOverflowClip() && fillLayer.attachment() == LocalBackgroundAttachment)
        return false;

    if (fillLayer.hasOpaqueImage(this) && fillLayer.hasRepeatXY() && fillLayer.image()->canRender(*this))
        return true;

    // If there is only one layer and no image, check whether the background color is opaque
    if (!fillLayer.next() && !fillLayer.hasImage()) {
        Color bgColor = resolveColor(CSSPropertyBackgroundColor);
        if (bgColor.alpha() == 255)
            return true;
    }

    return false;
}

void RenderBox::paintMask(PaintInfo& paintInfo, const LayoutPoint& paintOffset)
{
    if (!paintInfo.shouldPaintWithinRoot(this) || paintInfo.phase != PaintPhaseMask)
        return;

    LayoutRect paintRect = LayoutRect(paintOffset, size());
    paintMaskImages(paintInfo, paintRect);
}

void RenderBox::paintMaskImages(const PaintInfo& paintInfo, const LayoutRect& paintRect)
{
    paintFillLayers(paintInfo, Color::transparent, style()->maskLayers(), paintRect, BackgroundBleedNone);
    paintNinePieceImage(paintInfo.context, paintRect, style(), style()->maskBoxImage());
}

void RenderBox::paintFillLayers(const PaintInfo& paintInfo, const Color& c, const FillLayer& fillLayer, const LayoutRect& rect,
    BackgroundBleedAvoidance bleedAvoidance, RenderObject* backgroundObject)
{
    Vector<const FillLayer*, 8> layers;
    const FillLayer* curLayer = &fillLayer;
    bool shouldDrawBackgroundInSeparateBuffer = false;
    bool isBottomLayerOccluded = false;
    while (curLayer) {
        layers.append(curLayer);
        // Stop traversal when an opaque layer is encountered.
        // FIXME : It would be possible for the following occlusion culling test to be more aggressive
        // on layers with no repeat by testing whether the image covers the layout rect.
        // Testing that here would imply duplicating a lot of calculations that are currently done in
        // RenderBoxModelObject::paintFillLayerExtended. A more efficient solution might be to move
        // the layer recursion into paintFillLayerExtended, or to compute the layer geometry here
        // and pass it down.

        if (!shouldDrawBackgroundInSeparateBuffer && curLayer->blendMode() != WebBlendModeNormal)
            shouldDrawBackgroundInSeparateBuffer = true;

        // The clipOccludesNextLayers condition must be evaluated first to avoid short-circuiting.
        if (curLayer->clipOccludesNextLayers(curLayer == &fillLayer) && curLayer->hasOpaqueImage(this) && curLayer->image()->canRender(*this) && curLayer->hasRepeatXY() && curLayer->blendMode() == WebBlendModeNormal && !boxShadowShouldBeAppliedToBackground(bleedAvoidance))
            break;
        curLayer = curLayer->next();
    }

    if (layers.size() > 0  && (**layers.rbegin()).next())
        isBottomLayerOccluded = true;

    GraphicsContext* context = paintInfo.context;
    if (!context)
        shouldDrawBackgroundInSeparateBuffer = false;

    bool skipBaseColor = false;
    if (shouldDrawBackgroundInSeparateBuffer) {
        bool isBaseColorVisible = !isBottomLayerOccluded && c.hasAlpha();

        // Paint the document's base background color outside the transparency layer,
        // so that the background images don't blend with this color: http://crbug.com/389039.
        if (isBaseColorVisible && isDocumentElementWithOpaqueBackground()) {
            paintRootBackgroundColor(paintInfo, rect, Color());
            skipBaseColor = true;
        }
        context->beginTransparencyLayer(1);
    }

    Vector<const FillLayer*>::const_reverse_iterator topLayer = layers.rend();
    for (Vector<const FillLayer*>::const_reverse_iterator it = layers.rbegin(); it != topLayer; ++it)
        paintFillLayer(paintInfo, c, **it, rect, bleedAvoidance, backgroundObject, skipBaseColor);

    if (shouldDrawBackgroundInSeparateBuffer)
        context->endLayer();
}

void RenderBox::paintFillLayer(const PaintInfo& paintInfo, const Color& c, const FillLayer& fillLayer, const LayoutRect& rect,
    BackgroundBleedAvoidance bleedAvoidance, RenderObject* backgroundObject, bool skipBaseColor)
{
    paintFillLayerExtended(paintInfo, c, fillLayer, rect, bleedAvoidance, 0, LayoutSize(), backgroundObject, skipBaseColor);
}

bool RenderBox::pushContentsClip(PaintInfo& paintInfo, const LayoutPoint& accumulatedOffset, ContentsClipBehavior contentsClipBehavior)
{
    if (paintInfo.phase == PaintPhaseBlockBackground || paintInfo.phase == PaintPhaseSelfOutline || paintInfo.phase == PaintPhaseMask)
        return false;

    bool isControlClip = hasControlClip();
    bool isOverflowClip = hasOverflowClip() && !layer()->isSelfPaintingLayer();

    if (!isControlClip && !isOverflowClip)
        return false;

    LayoutRect clipRect = isControlClip ? controlClipRect(accumulatedOffset) : overflowClipRect(accumulatedOffset);
    RoundedRect clipRoundedRect(0, 0, 0, 0);
    bool hasBorderRadius = style()->hasBorderRadius();
    if (hasBorderRadius)
        clipRoundedRect = style()->getRoundedInnerBorderFor(LayoutRect(accumulatedOffset, size()));

    if (contentsClipBehavior == SkipContentsClipIfPossible) {
        LayoutRect contentsVisualOverflow = contentsVisualOverflowRect();
        if (contentsVisualOverflow.isEmpty())
            return false;

        LayoutRect conservativeClipRect = clipRect;
        if (hasBorderRadius)
            conservativeClipRect.intersect(clipRoundedRect.radiusCenterRect());
        conservativeClipRect.moveBy(-accumulatedOffset);
        if (hasLayer())
            conservativeClipRect.move(scrolledContentOffset());
        if (conservativeClipRect.contains(contentsVisualOverflow))
            return false;
    }

    if (paintInfo.phase == PaintPhaseOutline)
        paintInfo.phase = PaintPhaseChildOutlines;
    else if (paintInfo.phase == PaintPhaseChildBlockBackground) {
        paintInfo.phase = PaintPhaseBlockBackground;
        paintObject(paintInfo, accumulatedOffset);
        paintInfo.phase = PaintPhaseChildBlockBackgrounds;
    }
    paintInfo.context->save();
    if (hasBorderRadius)
        paintInfo.context->clipRoundedRect(clipRoundedRect);
    paintInfo.context->clip(pixelSnappedIntRect(clipRect));
    return true;
}

void RenderBox::popContentsClip(PaintInfo& paintInfo, PaintPhase originalPhase, const LayoutPoint& accumulatedOffset)
{
    ASSERT(hasControlClip() || (hasOverflowClip() && !layer()->isSelfPaintingLayer()));

    paintInfo.context->restore();
    if (originalPhase == PaintPhaseOutline) {
        paintInfo.phase = PaintPhaseSelfOutline;
        paintObject(paintInfo, accumulatedOffset);
        paintInfo.phase = originalPhase;
    } else if (originalPhase == PaintPhaseChildBlockBackground)
        paintInfo.phase = originalPhase;
}

LayoutRect RenderBox::overflowClipRect(const LayoutPoint& location)
{
    LayoutRect clipRect = borderBoxRect();
    clipRect.setLocation(location + clipRect.location() + LayoutSize(borderLeft(), borderTop()));
    clipRect.setSize(clipRect.size() - LayoutSize(borderLeft() + borderRight(), borderTop() + borderBottom()));
    return clipRect;
}

LayoutRect RenderBox::clipRect(const LayoutPoint& location)
{
    LayoutRect borderBoxRect = this->borderBoxRect();
    LayoutRect clipRect = LayoutRect(borderBoxRect.location() + location, borderBoxRect.size());

    if (!style()->clipLeft().isAuto()) {
        LayoutUnit c = valueForLength(style()->clipLeft(), borderBoxRect.width());
        clipRect.move(c, 0);
        clipRect.contract(c, 0);
    }

    if (!style()->clipRight().isAuto())
        clipRect.contract(width() - valueForLength(style()->clipRight(), width()), 0);

    if (!style()->clipTop().isAuto()) {
        LayoutUnit c = valueForLength(style()->clipTop(), borderBoxRect.height());
        clipRect.move(0, c);
        clipRect.contract(0, c);
    }

    if (!style()->clipBottom().isAuto())
        clipRect.contract(0, height() - valueForLength(style()->clipBottom(), height()));

    return clipRect;
}

LayoutUnit RenderBox::containingBlockLogicalHeightForContent(AvailableLogicalHeightType heightType) const
{
    return containingBlock()->availableLogicalHeight(heightType);
}

void RenderBox::mapLocalToContainer(const RenderLayerModelObject* paintInvalidationContainer, TransformState& transformState, MapCoordinatesFlags mode, const PaintInvalidationState* paintInvalidationState) const
{
    if (paintInvalidationContainer == this)
        return;

    if (paintInvalidationState && paintInvalidationState->canMapToContainer(paintInvalidationContainer)) {
        LayoutSize offset = paintInvalidationState->paintOffset() + locationOffset();
        if (style()->hasInFlowPosition() && layer())
            offset += layer()->offsetForInFlowPosition();
        transformState.move(offset);
        return;
    }

    bool containerSkipped;
    RenderObject* o = container(paintInvalidationContainer, &containerSkipped);
    if (!o)
        return;

    LayoutSize containerOffset = offsetFromContainer(o, roundedLayoutPoint(transformState.mappedPoint()));

    bool preserve3D = mode & UseTransforms && (o->style()->preserves3D() || style()->preserves3D());
    if (mode & UseTransforms && shouldUseTransformFromContainer(o)) {
        TransformationMatrix t;
        getTransformFromContainer(o, containerOffset, t);
        transformState.applyTransform(t, preserve3D ? TransformState::AccumulateTransform : TransformState::FlattenTransform);
    } else
        transformState.move(containerOffset.width(), containerOffset.height(), preserve3D ? TransformState::AccumulateTransform : TransformState::FlattenTransform);

    if (containerSkipped) {
        // There can't be a transform between paintInvalidationContainer and o, because transforms create containers, so it should be safe
        // to just subtract the delta between the paintInvalidationContainer and o.
        LayoutSize containerOffset = paintInvalidationContainer->offsetFromAncestorContainer(o);
        transformState.move(-containerOffset.width(), -containerOffset.height(), preserve3D ? TransformState::AccumulateTransform : TransformState::FlattenTransform);
        return;
    }

    mode &= ~ApplyContainerFlip;

    o->mapLocalToContainer(paintInvalidationContainer, transformState, mode);
}

LayoutSize RenderBox::offsetFromContainer(const RenderObject* o, const LayoutPoint& point, bool* offsetDependsOnPoint) const
{
    ASSERT(o == container());

    LayoutSize offset;
    if (isRelPositioned())
        offset += offsetForInFlowPosition();

    if (!isInline() || isReplaced())
        offset += locationOffset();

    if (o->hasOverflowClip())
        offset -= toRenderBox(o)->scrolledContentOffset();

    if (style()->position() == AbsolutePosition && o->isRelPositioned() && o->isRenderInline())
        offset += toRenderInline(o)->offsetForInFlowPositionedInline(*this);

    return offset;
}

InlineBox* RenderBox::createInlineBox()
{
    return new InlineBox(*this);
}

void RenderBox::dirtyLineBoxes(bool fullLayout)
{
    if (inlineBoxWrapper()) {
        if (fullLayout) {
            inlineBoxWrapper()->destroy();
            ASSERT(m_rareData);
            m_rareData->m_inlineBoxWrapper = 0;
        } else {
            inlineBoxWrapper()->dirtyLineBoxes();
        }
    }
}

void RenderBox::positionLineBox(InlineBox* box)
{
    if (isOutOfFlowPositioned()) {
        // Cache the x position only if we were an INLINE type originally.
        bool wasInline = style()->isOriginalDisplayInlineType();
        if (wasInline) {
            // The value is cached in the xPos of the box.  We only need this value if
            // our object was inline originally, since otherwise it would have ended up underneath
            // the inlines.
            RootInlineBox& root = box->root();
            root.block().setStaticInlinePositionForChild(this, LayoutUnit::fromFloatRound(box->logicalLeft()));
            if (style()->hasStaticInlinePosition())
                setChildNeedsLayout(MarkOnlyThis); // Just go ahead and mark the positioned object as needing layout, so it will update its position properly.
        } else {
            // Our object was a block originally, so we make our normal flow position be
            // just below the line box (as though all the inlines that came before us got
            // wrapped in an anonymous block, which is what would have happened had we been
            // in flow).  This value was cached in the y() of the box.
            layer()->setStaticBlockPosition(box->logicalTop());
            if (style()->hasStaticBlockPosition())
                setChildNeedsLayout(MarkOnlyThis); // Just go ahead and mark the positioned object as needing layout, so it will update its position properly.
        }

        if (container()->isRenderInline())
            moveWithEdgeOfInlineContainerIfNecessary();

        // Nuke the box.
        box->remove(DontMarkLineBoxes);
        box->destroy();
    } else if (isReplaced()) {
        setLocation(roundedLayoutPoint(box->topLeft()));
        setInlineBoxWrapper(box);
    }
}

void RenderBox::moveWithEdgeOfInlineContainerIfNecessary()
{
    ASSERT(isOutOfFlowPositioned() && container()->isRenderInline() && container()->isRelPositioned());
    // If this object is inside a relative positioned inline and its inline position is an explicit offset from the edge of its container
    // then it will need to move if its inline container has changed width. We do not track if the width has changed
    // but if we are here then we are laying out lines inside it, so it probably has - mark our object for layout so that it can
    // move to the new offset created by the new width.
    if (!normalChildNeedsLayout() && !style()->hasStaticInlinePosition())
        setChildNeedsLayout(MarkOnlyThis);
}

void RenderBox::deleteLineBoxWrapper()
{
    if (inlineBoxWrapper()) {
        if (!documentBeingDestroyed())
            inlineBoxWrapper()->remove();
        inlineBoxWrapper()->destroy();
        ASSERT(m_rareData);
        m_rareData->m_inlineBoxWrapper = 0;
    }
}

void RenderBox::updateLogicalWidth()
{
    LogicalExtentComputedValues computedValues;
    computeLogicalWidth(computedValues);

    setLogicalWidth(computedValues.m_extent);
    setLogicalLeft(computedValues.m_position);
    setMarginStart(computedValues.m_margins.m_start);
    setMarginEnd(computedValues.m_margins.m_end);
}

void RenderBox::computeLogicalWidth(LogicalExtentComputedValues& computedValues) const
{
    computedValues.m_extent = logicalWidth();
    computedValues.m_position = logicalLeft();
    computedValues.m_margins.m_start = marginStart();
    computedValues.m_margins.m_end = marginEnd();

    if (isOutOfFlowPositioned()) {
        // FIXME: This calculation is not patched for block-flow yet.
        // https://bugs.webkit.org/show_bug.cgi?id=46500
        computePositionedLogicalWidth(computedValues);
        return;
    }

    // If layout is limited to a subtree, the subtree root's logical width does not change.
    if (node() && view()->frameView() && view()->frameView()->layoutRoot(true) == this)
        return;

    // The parent box is flexing us, so it has increased or decreased our
    // width.  Use the width from the style context.
    // FIXME: Account for block-flow in flexible boxes.
    // https://bugs.webkit.org/show_bug.cgi?id=46418
    if (hasOverrideWidth() && parent()->isFlexibleBox()) {
        computedValues.m_extent = overrideLogicalContentWidth() + borderAndPaddingLogicalWidth();
        return;
    }

    bool treatAsReplaced = shouldComputeSizeAsReplaced();

    RenderStyle* styleToUse = style();
    Length logicalWidthLength = treatAsReplaced ? Length(computeReplacedLogicalWidth(), Fixed) : styleToUse->logicalWidth();

    RenderBlock* cb = containingBlock();
    LayoutUnit containerLogicalWidth = std::max<LayoutUnit>(0, containingBlockLogicalWidthForContent());

    if (isInline() && !isInlineBlock()) {
        // just calculate margins
        computedValues.m_margins.m_start = minimumValueForLength(styleToUse->marginStart(), containerLogicalWidth);
        computedValues.m_margins.m_end = minimumValueForLength(styleToUse->marginEnd(), containerLogicalWidth);
        if (treatAsReplaced)
            computedValues.m_extent = std::max<LayoutUnit>(floatValueForLength(logicalWidthLength, 0) + borderAndPaddingLogicalWidth(), minPreferredLogicalWidth());
        return;
    }

    // Width calculations
    if (treatAsReplaced)
        computedValues.m_extent = logicalWidthLength.value() + borderAndPaddingLogicalWidth();
    else {
        LayoutUnit preferredWidth = computeLogicalWidthUsing(MainOrPreferredSize, styleToUse->logicalWidth(), containerLogicalWidth, cb);
        computedValues.m_extent = constrainLogicalWidthByMinMax(preferredWidth, containerLogicalWidth, cb);
    }

    // Margin calculations.
    computeMarginsForDirection(InlineDirection, cb, containerLogicalWidth, computedValues.m_extent, computedValues.m_margins.m_start,
        computedValues.m_margins.m_end, style()->marginStart(), style()->marginEnd());

    if (containerLogicalWidth && containerLogicalWidth != (computedValues.m_extent + computedValues.m_margins.m_start + computedValues.m_margins.m_end)
        && !isInline() && !cb->isFlexibleBox()) {
        LayoutUnit newMargin = containerLogicalWidth - computedValues.m_extent - cb->marginStartForChild(this);
        bool hasInvertedDirection = cb->style()->isLeftToRightDirection() != style()->isLeftToRightDirection();
        if (hasInvertedDirection)
            computedValues.m_margins.m_start = newMargin;
        else
            computedValues.m_margins.m_end = newMargin;
    }
}

LayoutUnit RenderBox::fillAvailableMeasure(LayoutUnit availableLogicalWidth) const
{
    LayoutUnit marginStart = minimumValueForLength(style()->marginStart(), availableLogicalWidth);
    LayoutUnit marginEnd = minimumValueForLength(style()->marginEnd(), availableLogicalWidth);
    return availableLogicalWidth - marginStart - marginEnd;
}

LayoutUnit RenderBox::computeIntrinsicLogicalWidthUsing(const Length& logicalWidthLength, LayoutUnit availableLogicalWidth, LayoutUnit borderAndPadding) const
{
    if (logicalWidthLength.type() == FillAvailable)
        return fillAvailableMeasure(availableLogicalWidth);

    LayoutUnit minLogicalWidth = 0;
    LayoutUnit maxLogicalWidth = 0;
    computeIntrinsicLogicalWidths(minLogicalWidth, maxLogicalWidth);

    if (logicalWidthLength.type() == MinContent)
        return minLogicalWidth + borderAndPadding;

    if (logicalWidthLength.type() == MaxContent)
        return maxLogicalWidth + borderAndPadding;

    if (logicalWidthLength.type() == FitContent) {
        minLogicalWidth += borderAndPadding;
        maxLogicalWidth += borderAndPadding;
        return std::max(minLogicalWidth, std::min(maxLogicalWidth, fillAvailableMeasure(availableLogicalWidth)));
    }

    ASSERT_NOT_REACHED();
    return 0;
}

LayoutUnit RenderBox::computeLogicalWidthUsing(SizeType widthType, const Length& logicalWidth, LayoutUnit availableLogicalWidth, const RenderBlock* cb) const
{
    if (!logicalWidth.isIntrinsicOrAuto()) {
        // FIXME: If the containing block flow is perpendicular to our direction we need to use the available logical height instead.
        return adjustBorderBoxLogicalWidthForBoxSizing(valueForLength(logicalWidth, availableLogicalWidth));
    }

    if (logicalWidth.isIntrinsic())
        return computeIntrinsicLogicalWidthUsing(logicalWidth, availableLogicalWidth, borderAndPaddingLogicalWidth());

    LayoutUnit logicalWidthResult = fillAvailableMeasure(availableLogicalWidth);

    if (widthType == MainOrPreferredSize && sizesLogicalWidthToFitContent(logicalWidth))
        return std::max(minPreferredLogicalWidth(), std::min(maxPreferredLogicalWidth(), logicalWidthResult));
    return logicalWidthResult;
}

static bool columnFlexItemHasStretchAlignment(const RenderObject* flexitem)
{
    RenderObject* parent = flexitem->parent();
    // auto margins mean we don't stretch. Note that this function will only be used for
    // widths, so we don't have to check marginBefore/marginAfter.
    ASSERT(parent->style()->isColumnFlexDirection());
    if (flexitem->style()->marginStart().isAuto() || flexitem->style()->marginEnd().isAuto())
        return false;
    return flexitem->style()->alignSelf() == ItemPositionStretch || (flexitem->style()->alignSelf() == ItemPositionAuto && parent->style()->alignItems() == ItemPositionStretch);
}

bool RenderBox::sizesLogicalWidthToFitContent(const Length& logicalWidth) const
{
    if (isInlineBlock())
        return true;

    if (logicalWidth.type() == Intrinsic)
        return true;

    // Flexible box items should shrink wrap, so we lay them out at their intrinsic widths.
    // In the case of columns that have a stretch alignment, we go ahead and layout at the
    // stretched size to avoid an extra layout when applying alignment.
    if (parent()->isFlexibleBox()) {
        // For multiline columns, we need to apply align-content first, so we can't stretch now.
        if (!parent()->style()->isColumnFlexDirection() || parent()->style()->flexWrap() != FlexNoWrap)
            return true;
        if (!columnFlexItemHasStretchAlignment(this))
            return true;
    }

    return false;
}

void RenderBox::computeMarginsForDirection(MarginDirection flowDirection, const RenderBlock* containingBlock, LayoutUnit containerWidth, LayoutUnit childWidth, LayoutUnit& marginStart, LayoutUnit& marginEnd, Length marginStartLength, Length marginEndLength) const
{
    if (flowDirection == BlockDirection || isInline()) {
        // Margins are calculated with respect to the logical width of
        // the containing block (8.3)
        // Inline blocks/tables and floats don't have their margins increased.
        marginStart = minimumValueForLength(marginStartLength, containerWidth);
        marginEnd = minimumValueForLength(marginEndLength, containerWidth);
        return;
    }

    if (containingBlock->isFlexibleBox()) {
        // We need to let flexbox handle the margin adjustment - otherwise, flexbox
        // will think we're wider than we actually are and calculate line sizes wrong.
        // See also http://dev.w3.org/csswg/css-flexbox/#auto-margins
        if (marginStartLength.isAuto())
            marginStartLength.setValue(0);
        if (marginEndLength.isAuto())
            marginEndLength.setValue(0);
    }

    LayoutUnit marginStartWidth = minimumValueForLength(marginStartLength, containerWidth);
    LayoutUnit marginEndWidth = minimumValueForLength(marginEndLength, containerWidth);

    // CSS 2.1 (10.3.3): "If 'width' is not 'auto' and 'border-left-width' + 'padding-left' + 'width' + 'padding-right' + 'border-right-width'
    // (plus any of 'margin-left' or 'margin-right' that are not 'auto') is larger than the width of the containing block, then any 'auto'
    // values for 'margin-left' or 'margin-right' are, for the following rules, treated as zero.
    LayoutUnit marginBoxWidth = childWidth + (!style()->width().isAuto() ? marginStartWidth + marginEndWidth : LayoutUnit());

    // CSS 2.1: "If both 'margin-left' and 'margin-right' are 'auto', their used values are equal. This horizontally centers the element
    // with respect to the edges of the containing block."
    if (marginStartLength.isAuto() && marginEndLength.isAuto() && marginBoxWidth < containerWidth) {
        // Other browsers center the margin box for align=center elements so we match them here.
        LayoutUnit centeredMarginBoxStart = std::max<LayoutUnit>(0, (containerWidth - childWidth - marginStartWidth - marginEndWidth) / 2);
        marginStart = centeredMarginBoxStart + marginStartWidth;
        marginEnd = containerWidth - childWidth - marginStart + marginEndWidth;
        return;
    }

    // CSS 2.1: "If there is exactly one value specified as 'auto', its used value follows from the equality."
    if (marginEndLength.isAuto() && marginBoxWidth < containerWidth) {
        marginStart = marginStartWidth;
        marginEnd = containerWidth - childWidth - marginStart;
        return;
    }

    if (marginStartLength.isAuto() && marginBoxWidth < containerWidth) {
        marginEnd = marginEndWidth;
        marginStart = containerWidth - childWidth - marginEnd;
        return;
    }

    // Either no auto margins, or our margin box width is >= the container width, auto margins will just turn into 0.
    marginStart = marginStartWidth;
    marginEnd = marginEndWidth;
}

void RenderBox::updateLogicalHeight()
{
    m_intrinsicContentLogicalHeight = contentLogicalHeight();

    LogicalExtentComputedValues computedValues;
    computeLogicalHeight(logicalHeight(), logicalTop(), computedValues);

    setLogicalHeight(computedValues.m_extent);
    setLogicalTop(computedValues.m_position);
    setMarginBefore(computedValues.m_margins.m_before);
    setMarginAfter(computedValues.m_margins.m_after);
}

void RenderBox::computeLogicalHeight(LayoutUnit logicalHeight, LayoutUnit logicalTop, LogicalExtentComputedValues& computedValues) const
{
    computedValues.m_extent = logicalHeight;
    computedValues.m_position = logicalTop;

    // Cell height is managed by the table and inline non-replaced elements do not support a height property.
    if (isInline() && !isReplaced())
        return;

    Length h;
    if (isOutOfFlowPositioned())
        computePositionedLogicalHeight(computedValues);
    else {
        RenderBlock* cb = containingBlock();

        // If we are perpendicular to our containing block then we need to resolve our block-start and block-end margins so that if they
        // are 'auto' we are centred or aligned within the inline flow containing block: this is done by computing the margins as though they are inline.
        // Note that as this is the 'sizing phase' we are using our own writing mode rather than the containing block's. We use the containing block's
        // writing mode when figuring out the block-direction margins for positioning in |computeAndSetBlockDirectionMargins| (i.e. margin collapsing etc.).
        // See http://www.w3.org/TR/2014/CR-css-writing-modes-3-20140320/#orthogonal-flows
        // FIXME(sky): Remove MarginDirection enum.
        MarginDirection flowDirection = BlockDirection;

        bool treatAsReplaced = shouldComputeSizeAsReplaced();
        bool checkMinMaxHeight = false;

        // The parent box is flexing us, so it has increased or decreased our height.  We have to
        // grab our cached flexible height.
        // FIXME: Account for block-flow in flexible boxes.
        // https://bugs.webkit.org/show_bug.cgi?id=46418
        if (hasOverrideHeight() && parent()->isFlexibleBox())
            h = Length(overrideLogicalContentHeight(), Fixed);
        else if (treatAsReplaced)
            h = Length(computeReplacedLogicalHeight(), Fixed);
        else {
            h = style()->logicalHeight();
            checkMinMaxHeight = true;
        }

        LayoutUnit heightResult;
        if (checkMinMaxHeight) {
            heightResult = computeLogicalHeightUsing(style()->logicalHeight(), computedValues.m_extent - borderAndPaddingLogicalHeight());
            if (heightResult == -1)
                heightResult = computedValues.m_extent;
            heightResult = constrainLogicalHeightByMinMax(heightResult, computedValues.m_extent - borderAndPaddingLogicalHeight());
        } else {
            // The only times we don't check min/max height are when a fixed length has
            // been given as an override.  Just use that.  The value has already been adjusted
            // for box-sizing.
            ASSERT(h.isFixed());
            heightResult = h.value() + borderAndPaddingLogicalHeight();
        }

        computedValues.m_extent = heightResult;
        computeMarginsForDirection(flowDirection, cb, containingBlockLogicalWidthForContent(), computedValues.m_extent, computedValues.m_margins.m_before,
            computedValues.m_margins.m_after, style()->marginBefore(), style()->marginAfter());
    }
}

LayoutUnit RenderBox::computeLogicalHeightUsing(const Length& height, LayoutUnit intrinsicContentHeight) const
{
    LayoutUnit logicalHeight = computeContentLogicalHeightUsing(height, intrinsicContentHeight);
    if (logicalHeight != -1)
        logicalHeight = adjustBorderBoxLogicalHeightForBoxSizing(logicalHeight);
    return logicalHeight;
}

LayoutUnit RenderBox::computeContentLogicalHeight(const Length& height, LayoutUnit intrinsicContentHeight) const
{
    LayoutUnit heightIncludingScrollbar = computeContentLogicalHeightUsing(height, intrinsicContentHeight);
    if (heightIncludingScrollbar == -1)
        return -1;
    return std::max<LayoutUnit>(0, adjustContentBoxLogicalHeightForBoxSizing(heightIncludingScrollbar));
}

LayoutUnit RenderBox::computeIntrinsicLogicalContentHeightUsing(const Length& logicalHeightLength, LayoutUnit intrinsicContentHeight, LayoutUnit borderAndPadding) const
{
    // FIXME(cbiesinger): The css-sizing spec is considering changing what min-content/max-content should resolve to.
    // If that happens, this code will have to change.
    if (logicalHeightLength.isMinContent() || logicalHeightLength.isMaxContent() || logicalHeightLength.isFitContent()) {
        if (isReplaced())
            return intrinsicSize().height();
        if (m_intrinsicContentLogicalHeight != -1)
            return m_intrinsicContentLogicalHeight;
        return intrinsicContentHeight;
    }
    if (logicalHeightLength.isFillAvailable())
        return containingBlock()->availableLogicalHeight(ExcludeMarginBorderPadding) - borderAndPadding;
    ASSERT_NOT_REACHED();
    return 0;
}

LayoutUnit RenderBox::computeContentLogicalHeightUsing(const Length& height, LayoutUnit intrinsicContentHeight) const
{
    // FIXME(cbiesinger): The css-sizing spec is considering changing what min-content/max-content should resolve to.
    // If that happens, this code will have to change.
    if (height.isIntrinsic()) {
        if (intrinsicContentHeight == -1)
            return -1; // Intrinsic height isn't available.
        return computeIntrinsicLogicalContentHeightUsing(height, intrinsicContentHeight, borderAndPaddingLogicalHeight());
    }
    if (height.isFixed())
        return height.value();
    if (height.isPercent())
        return computePercentageLogicalHeight(height);
    return -1;
}

bool RenderBox::skipContainingBlockForPercentHeightCalculation(const RenderBox* containingBlock) const
{
    if (!containingBlock->isAnonymousBlock())
        return false;
    return !containingBlock->isOutOfFlowPositioned() && containingBlock->style()->logicalHeight().isAuto();
}

LayoutUnit RenderBox::computePercentageLogicalHeight(const Length& height) const
{
    LayoutUnit availableHeight = -1;

    bool skippedAutoHeightContainingBlock = false;
    RenderBlock* cb = containingBlock();
    const RenderBox* containingBlockChild = this;
    LayoutUnit rootMarginBorderPaddingHeight = 0;
    while (!cb->isRenderView() && skipContainingBlockForPercentHeightCalculation(cb)) {
        if (cb->isDocumentElement())
            rootMarginBorderPaddingHeight += cb->marginBefore() + cb->marginAfter() + cb->borderAndPaddingLogicalHeight();
        skippedAutoHeightContainingBlock = true;
        containingBlockChild = cb;
        cb = cb->containingBlock();
    }
    cb->addPercentHeightDescendant(const_cast<RenderBox*>(this));

    RenderStyle* cbstyle = cb->style();

    // A positioned element that specified both top/bottom or that specifies height should be treated as though it has a height
    // explicitly specified that can be used for any percentage computations.
    bool isOutOfFlowPositionedWithSpecifiedHeight = cb->isOutOfFlowPositioned() && (!cbstyle->logicalHeight().isAuto() || (!cbstyle->logicalTop().isAuto() && !cbstyle->logicalBottom().isAuto()));

    if (cbstyle->logicalHeight().isFixed()) {
        LayoutUnit contentBoxHeight = cb->adjustContentBoxLogicalHeightForBoxSizing(cbstyle->logicalHeight().value());
        availableHeight = std::max<LayoutUnit>(0, cb->constrainContentBoxLogicalHeightByMinMax(contentBoxHeight, -1));
    } else if (cbstyle->logicalHeight().isPercent() && !isOutOfFlowPositionedWithSpecifiedHeight) {
        // We need to recur and compute the percentage height for our containing block.
        LayoutUnit heightWithScrollbar = cb->computePercentageLogicalHeight(cbstyle->logicalHeight());
        if (heightWithScrollbar != -1) {
            LayoutUnit contentBoxHeightWithScrollbar = cb->adjustContentBoxLogicalHeightForBoxSizing(heightWithScrollbar);
            // We need to adjust for min/max height because this method does not
            // handle the min/max of the current block, its caller does. So the
            // return value from the recursive call will not have been adjusted
            // yet.
            LayoutUnit contentBoxHeight = cb->constrainContentBoxLogicalHeightByMinMax(contentBoxHeightWithScrollbar, -1);
            availableHeight = std::max<LayoutUnit>(0, contentBoxHeight);
        }
    } else if (isOutOfFlowPositionedWithSpecifiedHeight) {
        // Don't allow this to affect the block' height() member variable, since this
        // can get called while the block is still laying out its kids.
        LogicalExtentComputedValues computedValues;
        cb->computeLogicalHeight(cb->logicalHeight(), 0, computedValues);
        availableHeight = computedValues.m_extent - cb->borderAndPaddingLogicalHeight();
    } else if (cb->isRenderView())
        availableHeight = view()->viewLogicalHeightForPercentages();

    if (availableHeight == -1)
        return availableHeight;

    availableHeight -= rootMarginBorderPaddingHeight;

    LayoutUnit result = valueForLength(height, availableHeight);
    return result;
}

LayoutUnit RenderBox::computeReplacedLogicalWidth(ShouldComputePreferred shouldComputePreferred) const
{
    return computeReplacedLogicalWidthRespectingMinMaxWidth(computeReplacedLogicalWidthUsing(style()->logicalWidth()), shouldComputePreferred);
}

LayoutUnit RenderBox::computeReplacedLogicalWidthRespectingMinMaxWidth(LayoutUnit logicalWidth, ShouldComputePreferred shouldComputePreferred) const
{
    LayoutUnit minLogicalWidth = (shouldComputePreferred == ComputePreferred && style()->logicalMinWidth().isPercent()) || style()->logicalMinWidth().isMaxSizeNone() ? logicalWidth : computeReplacedLogicalWidthUsing(style()->logicalMinWidth());
    LayoutUnit maxLogicalWidth = (shouldComputePreferred == ComputePreferred && style()->logicalMaxWidth().isPercent()) || style()->logicalMaxWidth().isMaxSizeNone() ? logicalWidth : computeReplacedLogicalWidthUsing(style()->logicalMaxWidth());
    return std::max(minLogicalWidth, std::min(logicalWidth, maxLogicalWidth));
}

LayoutUnit RenderBox::computeReplacedLogicalWidthUsing(const Length& logicalWidth) const
{
    switch (logicalWidth.type()) {
        case Fixed:
            return adjustContentBoxLogicalWidthForBoxSizing(logicalWidth.value());
        case MinContent:
        case MaxContent: {
            // MinContent/MaxContent don't need the availableLogicalWidth argument.
            LayoutUnit availableLogicalWidth = 0;
            return computeIntrinsicLogicalWidthUsing(logicalWidth, availableLogicalWidth, borderAndPaddingLogicalWidth()) - borderAndPaddingLogicalWidth();
        }
        case FitContent:
        case FillAvailable:
        case Percent:
        case Calculated: {
            // FIXME: containingBlockLogicalWidthForContent() is wrong if the replaced element's block-flow is perpendicular to the
            // containing block's block-flow.
            // https://bugs.webkit.org/show_bug.cgi?id=46496
            const LayoutUnit cw = isOutOfFlowPositioned() ? containingBlockLogicalWidthForPositioned(toRenderBoxModelObject(container())) : containingBlockLogicalWidthForContent();
            Length containerLogicalWidth = containingBlock()->style()->logicalWidth();
            // FIXME: Handle cases when containing block width is calculated or viewport percent.
            // https://bugs.webkit.org/show_bug.cgi?id=91071
            if (logicalWidth.isIntrinsic())
                return computeIntrinsicLogicalWidthUsing(logicalWidth, cw, borderAndPaddingLogicalWidth()) - borderAndPaddingLogicalWidth();
            if (cw > 0 || (!cw && (containerLogicalWidth.isFixed() || containerLogicalWidth.isPercent())))
                return adjustContentBoxLogicalWidthForBoxSizing(minimumValueForLength(logicalWidth, cw));
            return 0;
        }
        case Intrinsic:
        case MinIntrinsic:
        case Auto:
        case MaxSizeNone:
            return intrinsicLogicalWidth();
        case DeviceWidth:
        case DeviceHeight:
            break;
    }

    ASSERT_NOT_REACHED();
    return 0;
}

LayoutUnit RenderBox::computeReplacedLogicalHeight() const
{
    return computeReplacedLogicalHeightRespectingMinMaxHeight(computeReplacedLogicalHeightUsing(style()->logicalHeight()));
}

bool RenderBox::logicalHeightComputesAsNone(SizeType sizeType) const
{
    ASSERT(sizeType == MinSize || sizeType == MaxSize);
    Length logicalHeight = sizeType == MinSize ? style()->logicalMinHeight() : style()->logicalMaxHeight();
    Length initialLogicalHeight = sizeType == MinSize ? RenderStyle::initialMinSize() : RenderStyle::initialMaxSize();

    if (logicalHeight == initialLogicalHeight)
        return true;

    if (!logicalHeight.isPercent() || isOutOfFlowPositioned())
        return false;

    // Anonymous block boxes are ignored when resolving percentage values that would refer to it:
    // the closest non-anonymous ancestor box is used instead.
    RenderBlock* containingBlock = this->containingBlock();
    while (containingBlock->isAnonymous())
        containingBlock = containingBlock->containingBlock();

    return containingBlock->hasAutoHeightOrContainingBlockWithAutoHeight();
}

LayoutUnit RenderBox::computeReplacedLogicalHeightRespectingMinMaxHeight(LayoutUnit logicalHeight) const
{
    // If the height of the containing block is not specified explicitly (i.e., it depends on content height), and this element is not absolutely positioned,
    // the percentage value is treated as '0' (for 'min-height') or 'none' (for 'max-height').
    LayoutUnit minLogicalHeight;
    if (!logicalHeightComputesAsNone(MinSize))
        minLogicalHeight = computeReplacedLogicalHeightUsing(style()->logicalMinHeight());
    LayoutUnit maxLogicalHeight = logicalHeight;
    if (!logicalHeightComputesAsNone(MaxSize))
        maxLogicalHeight =  computeReplacedLogicalHeightUsing(style()->logicalMaxHeight());
    return std::max(minLogicalHeight, std::min(logicalHeight, maxLogicalHeight));
}

LayoutUnit RenderBox::computeReplacedLogicalHeightUsing(const Length& logicalHeight) const
{
    switch (logicalHeight.type()) {
        case Fixed:
            return adjustContentBoxLogicalHeightForBoxSizing(logicalHeight.value());
        case Percent:
        case Calculated:
        {
            RenderObject* cb = isOutOfFlowPositioned() ? container() : containingBlock();
            while (cb->isAnonymous())
                cb = cb->containingBlock();
            if (cb->isRenderBlock())
                toRenderBlock(cb)->addPercentHeightDescendant(const_cast<RenderBox*>(this));

            // FIXME: This calculation is not patched for block-flow yet.
            // https://bugs.webkit.org/show_bug.cgi?id=46500
            if (cb->isOutOfFlowPositioned() && cb->style()->height().isAuto() && !(cb->style()->top().isAuto() || cb->style()->bottom().isAuto())) {
                ASSERT_WITH_SECURITY_IMPLICATION(cb->isRenderBlock());
                RenderBlock* block = toRenderBlock(cb);
                LogicalExtentComputedValues computedValues;
                block->computeLogicalHeight(block->logicalHeight(), 0, computedValues);
                LayoutUnit newContentHeight = computedValues.m_extent - block->borderAndPaddingLogicalHeight();
                LayoutUnit newHeight = block->adjustContentBoxLogicalHeightForBoxSizing(newContentHeight);
                return adjustContentBoxLogicalHeightForBoxSizing(valueForLength(logicalHeight, newHeight));
            }

            // FIXME: availableLogicalHeight() is wrong if the replaced element's block-flow is perpendicular to the
            // containing block's block-flow.
            // https://bugs.webkit.org/show_bug.cgi?id=46496
            LayoutUnit availableHeight;
            if (isOutOfFlowPositioned())
                availableHeight = containingBlockLogicalHeightForPositioned(toRenderBoxModelObject(cb));
            else {
                availableHeight = containingBlockLogicalHeightForContent(IncludeMarginBorderPadding);
                // It is necessary to use the border-box to match WinIE's broken
                // box model.  This is essential for sizing inside
                // table cells using percentage heights.
                // FIXME: This needs to be made block-flow-aware.  If the cell and image are perpendicular block-flows, this isn't right.
                // https://bugs.webkit.org/show_bug.cgi?id=46997
                while (cb && !cb->isRenderView() && (cb->style()->logicalHeight().isAuto() || cb->style()->logicalHeight().isPercent())) {
                    toRenderBlock(cb)->addPercentHeightDescendant(const_cast<RenderBox*>(this));
                    cb = cb->containingBlock();
                }
            }
            return adjustContentBoxLogicalHeightForBoxSizing(valueForLength(logicalHeight, availableHeight));
        }
        case MinContent:
        case MaxContent:
        case FitContent:
        case FillAvailable:
            return adjustContentBoxLogicalHeightForBoxSizing(computeIntrinsicLogicalContentHeightUsing(logicalHeight, intrinsicLogicalHeight(), borderAndPaddingHeight()));
        default:
            return intrinsicLogicalHeight();
    }
}

LayoutUnit RenderBox::availableLogicalHeight(AvailableLogicalHeightType heightType) const
{
    // http://www.w3.org/TR/CSS2/visudet.html#propdef-height - We are interested in the content height.
    return constrainContentBoxLogicalHeightByMinMax(availableLogicalHeightUsing(style()->logicalHeight(), heightType), -1);
}

LayoutUnit RenderBox::availableLogicalHeightUsing(const Length& h, AvailableLogicalHeightType heightType) const
{
    if (isRenderView())
        return toRenderView(this)->frameView()->unscaledVisibleContentSize().height();

    if (h.isPercent() && isOutOfFlowPositioned()) {
        // FIXME: This is wrong if the containingBlock has a perpendicular writing mode.
        LayoutUnit availableHeight = containingBlockLogicalHeightForPositioned(containingBlock());
        return adjustContentBoxLogicalHeightForBoxSizing(valueForLength(h, availableHeight));
    }

    LayoutUnit heightIncludingScrollbar = computeContentLogicalHeightUsing(h, -1);
    if (heightIncludingScrollbar != -1)
        return std::max<LayoutUnit>(0, adjustContentBoxLogicalHeightForBoxSizing(heightIncludingScrollbar));

    // FIXME: Check logicalTop/logicalBottom here to correctly handle vertical writing-mode.
    // https://bugs.webkit.org/show_bug.cgi?id=46500
    if (isRenderBlock() && isOutOfFlowPositioned() && style()->height().isAuto() && !(style()->top().isAuto() || style()->bottom().isAuto())) {
        RenderBlock* block = const_cast<RenderBlock*>(toRenderBlock(this));
        LogicalExtentComputedValues computedValues;
        block->computeLogicalHeight(block->logicalHeight(), 0, computedValues);
        LayoutUnit newContentHeight = computedValues.m_extent - block->borderAndPaddingLogicalHeight();
        return adjustContentBoxLogicalHeightForBoxSizing(newContentHeight);
    }

    // FIXME: This is wrong if the containingBlock has a perpendicular writing mode.
    LayoutUnit availableHeight = containingBlockLogicalHeightForContent(heightType);
    if (heightType == ExcludeMarginBorderPadding) {
        // FIXME: Margin collapsing hasn't happened yet, so this incorrectly removes collapsed margins.
        availableHeight -= marginBefore() + marginAfter() + borderAndPaddingLogicalHeight();
    }
    return availableHeight;
}

void RenderBox::computeAndSetBlockDirectionMargins(const RenderBlock* containingBlock)
{
    LayoutUnit marginBefore;
    LayoutUnit marginAfter;
    computeMarginsForDirection(BlockDirection, containingBlock, containingBlockLogicalWidthForContent(), logicalHeight(), marginBefore, marginAfter,
        style()->marginBeforeUsing(containingBlock->style()),
        style()->marginAfterUsing(containingBlock->style()));
    // Note that in this 'positioning phase' of the layout we are using the containing block's writing mode rather than our own when calculating margins.
    // See http://www.w3.org/TR/2014/CR-css-writing-modes-3-20140320/#orthogonal-flows
    containingBlock->setMarginBeforeForChild(this, marginBefore);
    containingBlock->setMarginAfterForChild(this, marginAfter);
}

LayoutUnit RenderBox::containingBlockLogicalWidthForPositioned(const RenderBoxModelObject* containingBlock) const
{
    if (containingBlock->isBox())
        return toRenderBox(containingBlock)->clientLogicalWidth();

    ASSERT(containingBlock->isRenderInline() && containingBlock->isRelPositioned());

    const RenderInline* flow = toRenderInline(containingBlock);
    InlineFlowBox* first = flow->firstLineBox();
    InlineFlowBox* last = flow->lastLineBox();

    // If the containing block is empty, return a width of 0.
    if (!first || !last)
        return 0;

    LayoutUnit fromLeft;
    LayoutUnit fromRight;
    if (containingBlock->style()->isLeftToRightDirection()) {
        fromLeft = first->logicalLeft() + first->borderLogicalLeft();
        fromRight = last->logicalLeft() + last->logicalWidth() - last->borderLogicalRight();
    } else {
        fromRight = first->logicalLeft() + first->logicalWidth() - first->borderLogicalRight();
        fromLeft = last->logicalLeft() + last->borderLogicalLeft();
    }

    return std::max<LayoutUnit>(0, fromRight - fromLeft);
}

LayoutUnit RenderBox::containingBlockLogicalHeightForPositioned(const RenderBoxModelObject* containingBlock) const
{
    if (containingBlock->isBox()) {
        const RenderBlock* cb = containingBlock->isRenderBlock() ?
            toRenderBlock(containingBlock) : containingBlock->containingBlock();
        return cb->clientLogicalHeight();
    }

    ASSERT(containingBlock->isRenderInline() && containingBlock->isRelPositioned());

    const RenderInline* flow = toRenderInline(containingBlock);
    InlineFlowBox* first = flow->firstLineBox();
    InlineFlowBox* last = flow->lastLineBox();

    // If the containing block is empty, return a height of 0.
    if (!first || !last)
        return 0;

    LayoutRect boundingBox = flow->linesBoundingBox();
    LayoutUnit heightResult = boundingBox.height();
    heightResult -= (containingBlock->borderBefore() + containingBlock->borderAfter());
    return heightResult;
}

static void computeInlineStaticDistance(Length& logicalLeft, Length& logicalRight, const RenderBox* child, const RenderBoxModelObject* containerBlock, LayoutUnit containerLogicalWidth)
{
    if (!logicalLeft.isAuto() || !logicalRight.isAuto())
        return;

    // FIXME: The static distance computation has not been patched for mixed writing modes yet.
    if (child->parent()->style()->direction() == LTR) {
        LayoutUnit staticPosition = child->layer()->staticInlinePosition() - containerBlock->borderLogicalLeft();
        for (RenderObject* curr = child->parent(); curr && curr != containerBlock; curr = curr->container()) {
            if (curr->isBox()) {
                staticPosition += toRenderBox(curr)->logicalLeft();
                if (toRenderBox(curr)->isRelPositioned())
                    staticPosition += toRenderBox(curr)->relativePositionOffset().width();
            } else if (curr->isInline()) {
                if (curr->isRelPositioned()) {
                    if (!curr->style()->logicalLeft().isAuto())
                        staticPosition += curr->style()->logicalLeft().value();
                    else
                        staticPosition -= curr->style()->logicalRight().value();
                }
            }
        }
        logicalLeft.setValue(Fixed, staticPosition);
    } else {
        RenderBox* enclosingBox = child->parent()->enclosingBox();
        LayoutUnit staticPosition = child->layer()->staticInlinePosition() + containerLogicalWidth + containerBlock->borderLogicalLeft();
        for (RenderObject* curr = child->parent(); curr; curr = curr->container()) {
            if (curr->isBox()) {
                if (curr != containerBlock) {
                    staticPosition -= toRenderBox(curr)->logicalLeft();
                    if (toRenderBox(curr)->isRelPositioned())
                        staticPosition -= toRenderBox(curr)->relativePositionOffset().width();
                }
                if (curr == enclosingBox)
                    staticPosition -= enclosingBox->logicalWidth();
            } else if (curr->isInline()) {
                if (curr->isRelPositioned()) {
                    if (!curr->style()->logicalLeft().isAuto())
                        staticPosition -= curr->style()->logicalLeft().value();
                    else
                        staticPosition += curr->style()->logicalRight().value();
                }
            }
            if (curr == containerBlock)
                break;
        }
        logicalRight.setValue(Fixed, staticPosition);
    }
}

void RenderBox::computePositionedLogicalWidth(LogicalExtentComputedValues& computedValues) const
{
    if (isReplaced()) {
        computePositionedLogicalWidthReplaced(computedValues);
        return;
    }

    // QUESTIONS
    // FIXME 1: Should we still deal with these the cases of 'left' or 'right' having
    // the type 'static' in determining whether to calculate the static distance?
    // NOTE: 'static' is not a legal value for 'left' or 'right' as of CSS 2.1.

    // FIXME 2: Can perhaps optimize out cases when max-width/min-width are greater
    // than or less than the computed width().  Be careful of box-sizing and
    // percentage issues.

    // The following is based off of the W3C Working Draft from April 11, 2006 of
    // CSS 2.1: Section 10.3.7 "Absolutely positioned, non-replaced elements"
    // <http://www.w3.org/TR/CSS21/visudet.html#abs-non-replaced-width>
    // (block-style-comments in this function and in computePositionedLogicalWidthUsing()
    // correspond to text from the spec)


    // We don't use containingBlock(), since we may be positioned by an enclosing
    // relative positioned inline.
    const RenderBoxModelObject* containerBlock = toRenderBoxModelObject(container());

    const LayoutUnit containerLogicalWidth = containingBlockLogicalWidthForPositioned(containerBlock);

    // Use the container block's direction except when calculating the static distance
    // This conforms with the reference results for abspos-replaced-width-margin-000.htm
    // of the CSS 2.1 test suite
    TextDirection containerDirection = containerBlock->style()->direction();

    const LayoutUnit bordersPlusPadding = borderAndPaddingLogicalWidth();
    const Length marginLogicalLeft = style()->marginLeft();
    const Length marginLogicalRight = style()->marginRight();

    Length logicalLeftLength = style()->logicalLeft();
    Length logicalRightLength = style()->logicalRight();

    /*---------------------------------------------------------------------------*\
     * For the purposes of this section and the next, the term "static position"
     * (of an element) refers, roughly, to the position an element would have had
     * in the normal flow. More precisely:
     *
     * * The static position for 'left' is the distance from the left edge of the
     *   containing block to the left margin edge of a hypothetical box that would
     *   have been the first box of the element if its 'position' property had
     *   been 'static' and 'float' had been 'none'. The value is negative if the
     *   hypothetical box is to the left of the containing block.
     * * The static position for 'right' is the distance from the right edge of the
     *   containing block to the right margin edge of the same hypothetical box as
     *   above. The value is positive if the hypothetical box is to the left of the
     *   containing block's edge.
     *
     * But rather than actually calculating the dimensions of that hypothetical box,
     * user agents are free to make a guess at its probable position.
     *
     * For the purposes of calculating the static position, the containing block of
     * fixed positioned elements is the initial containing block instead of the
     * viewport, and all scrollable boxes should be assumed to be scrolled to their
     * origin.
    \*---------------------------------------------------------------------------*/

    // see FIXME 1
    // Calculate the static distance if needed.
    computeInlineStaticDistance(logicalLeftLength, logicalRightLength, this, containerBlock, containerLogicalWidth);

    // Calculate constraint equation values for 'width' case.
    computePositionedLogicalWidthUsing(style()->logicalWidth(), containerBlock, containerDirection,
                                       containerLogicalWidth, bordersPlusPadding,
                                       logicalLeftLength, logicalRightLength, marginLogicalLeft, marginLogicalRight,
                                       computedValues);

    // Calculate constraint equation values for 'max-width' case.
    if (!style()->logicalMaxWidth().isMaxSizeNone()) {
        LogicalExtentComputedValues maxValues;

        computePositionedLogicalWidthUsing(style()->logicalMaxWidth(), containerBlock, containerDirection,
                                           containerLogicalWidth, bordersPlusPadding,
                                           logicalLeftLength, logicalRightLength, marginLogicalLeft, marginLogicalRight,
                                           maxValues);

        if (computedValues.m_extent > maxValues.m_extent) {
            computedValues.m_extent = maxValues.m_extent;
            computedValues.m_position = maxValues.m_position;
            computedValues.m_margins.m_start = maxValues.m_margins.m_start;
            computedValues.m_margins.m_end = maxValues.m_margins.m_end;
        }
    }

    // Calculate constraint equation values for 'min-width' case.
    if (!style()->logicalMinWidth().isZero() || style()->logicalMinWidth().isIntrinsic()) {
        LogicalExtentComputedValues minValues;

        computePositionedLogicalWidthUsing(style()->logicalMinWidth(), containerBlock, containerDirection,
                                           containerLogicalWidth, bordersPlusPadding,
                                           logicalLeftLength, logicalRightLength, marginLogicalLeft, marginLogicalRight,
                                           minValues);

        if (computedValues.m_extent < minValues.m_extent) {
            computedValues.m_extent = minValues.m_extent;
            computedValues.m_position = minValues.m_position;
            computedValues.m_margins.m_start = minValues.m_margins.m_start;
            computedValues.m_margins.m_end = minValues.m_margins.m_end;
        }
    }

    computedValues.m_extent += bordersPlusPadding;
}

static void computeLogicalLeftPositionedOffset(LayoutUnit& logicalLeftPos, const RenderBox* child, LayoutUnit logicalWidthValue, const RenderBoxModelObject* containerBlock, LayoutUnit containerLogicalWidth)
{
    // FIXME(sky): Remove
    logicalLeftPos += containerBlock->borderLeft();
}

void RenderBox::shrinkToFitWidth(const LayoutUnit availableSpace, const LayoutUnit logicalLeftValue, const LayoutUnit bordersPlusPadding, LogicalExtentComputedValues& computedValues) const
{
    // FIXME: would it be better to have shrink-to-fit in one step?
    LayoutUnit preferredWidth = maxPreferredLogicalWidth() - bordersPlusPadding;
    LayoutUnit preferredMinWidth = minPreferredLogicalWidth() - bordersPlusPadding;
    LayoutUnit availableWidth = availableSpace - logicalLeftValue;
    computedValues.m_extent = std::min(std::max(preferredMinWidth, availableWidth), preferredWidth);
}

void RenderBox::computePositionedLogicalWidthUsing(Length logicalWidth, const RenderBoxModelObject* containerBlock, TextDirection containerDirection,
                                                   LayoutUnit containerLogicalWidth, LayoutUnit bordersPlusPadding,
                                                   const Length& logicalLeft, const Length& logicalRight, const Length& marginLogicalLeft,
                                                   const Length& marginLogicalRight, LogicalExtentComputedValues& computedValues) const
{
    if (logicalWidth.isIntrinsic())
        logicalWidth = Length(computeIntrinsicLogicalWidthUsing(logicalWidth, containerLogicalWidth, bordersPlusPadding) - bordersPlusPadding, Fixed);

    // 'left' and 'right' cannot both be 'auto' because one would of been
    // converted to the static position already
    ASSERT(!(logicalLeft.isAuto() && logicalRight.isAuto()));

    LayoutUnit logicalLeftValue = 0;

    const LayoutUnit containerRelativeLogicalWidth = containingBlockLogicalWidthForPositioned(containerBlock);

    bool logicalWidthIsAuto = logicalWidth.isIntrinsicOrAuto();
    bool logicalLeftIsAuto = logicalLeft.isAuto();
    bool logicalRightIsAuto = logicalRight.isAuto();
    LayoutUnit& marginLogicalLeftValue = style()->isLeftToRightDirection() ? computedValues.m_margins.m_start : computedValues.m_margins.m_end;
    LayoutUnit& marginLogicalRightValue = style()->isLeftToRightDirection() ? computedValues.m_margins.m_end : computedValues.m_margins.m_start;
    if (!logicalLeftIsAuto && !logicalWidthIsAuto && !logicalRightIsAuto) {
        /*-----------------------------------------------------------------------*\
         * If none of the three is 'auto': If both 'margin-left' and 'margin-
         * right' are 'auto', solve the equation under the extra constraint that
         * the two margins get equal values, unless this would make them negative,
         * in which case when direction of the containing block is 'ltr' ('rtl'),
         * set 'margin-left' ('margin-right') to zero and solve for 'margin-right'
         * ('margin-left'). If one of 'margin-left' or 'margin-right' is 'auto',
         * solve the equation for that value. If the values are over-constrained,
         * ignore the value for 'left' (in case the 'direction' property of the
         * containing block is 'rtl') or 'right' (in case 'direction' is 'ltr')
         * and solve for that value.
        \*-----------------------------------------------------------------------*/
        // NOTE:  It is not necessary to solve for 'right' in the over constrained
        // case because the value is not used for any further calculations.

        logicalLeftValue = valueForLength(logicalLeft, containerLogicalWidth);
        computedValues.m_extent = adjustContentBoxLogicalWidthForBoxSizing(valueForLength(logicalWidth, containerLogicalWidth));

        const LayoutUnit availableSpace = containerLogicalWidth - (logicalLeftValue + computedValues.m_extent + valueForLength(logicalRight, containerLogicalWidth) + bordersPlusPadding);

        // Margins are now the only unknown
        if (marginLogicalLeft.isAuto() && marginLogicalRight.isAuto()) {
            // Both margins auto, solve for equality
            if (availableSpace >= 0) {
                marginLogicalLeftValue = availableSpace / 2; // split the difference
                marginLogicalRightValue = availableSpace - marginLogicalLeftValue; // account for odd valued differences
            } else {
                // Use the containing block's direction rather than the parent block's
                // per CSS 2.1 reference test abspos-non-replaced-width-margin-000.
                if (containerDirection == LTR) {
                    marginLogicalLeftValue = 0;
                    marginLogicalRightValue = availableSpace; // will be negative
                } else {
                    marginLogicalLeftValue = availableSpace; // will be negative
                    marginLogicalRightValue = 0;
                }
            }
        } else if (marginLogicalLeft.isAuto()) {
            // Solve for left margin
            marginLogicalRightValue = valueForLength(marginLogicalRight, containerRelativeLogicalWidth);
            marginLogicalLeftValue = availableSpace - marginLogicalRightValue;
        } else if (marginLogicalRight.isAuto()) {
            // Solve for right margin
            marginLogicalLeftValue = valueForLength(marginLogicalLeft, containerRelativeLogicalWidth);
            marginLogicalRightValue = availableSpace - marginLogicalLeftValue;
        } else {
            // Over-constrained, solve for left if direction is RTL
            marginLogicalLeftValue = valueForLength(marginLogicalLeft, containerRelativeLogicalWidth);
            marginLogicalRightValue = valueForLength(marginLogicalRight, containerRelativeLogicalWidth);

            // Use the containing block's direction rather than the parent block's
            // per CSS 2.1 reference test abspos-non-replaced-width-margin-000.
            if (containerDirection == RTL)
                logicalLeftValue = (availableSpace + logicalLeftValue) - marginLogicalLeftValue - marginLogicalRightValue;
        }
    } else {
        /*--------------------------------------------------------------------*\
         * Otherwise, set 'auto' values for 'margin-left' and 'margin-right'
         * to 0, and pick the one of the following six rules that applies.
         *
         * 1. 'left' and 'width' are 'auto' and 'right' is not 'auto', then the
         *    width is shrink-to-fit. Then solve for 'left'
         *
         *              OMIT RULE 2 AS IT SHOULD NEVER BE HIT
         * ------------------------------------------------------------------
         * 2. 'left' and 'right' are 'auto' and 'width' is not 'auto', then if
         *    the 'direction' property of the containing block is 'ltr' set
         *    'left' to the static position, otherwise set 'right' to the
         *    static position. Then solve for 'left' (if 'direction is 'rtl')
         *    or 'right' (if 'direction' is 'ltr').
         * ------------------------------------------------------------------
         *
         * 3. 'width' and 'right' are 'auto' and 'left' is not 'auto', then the
         *    width is shrink-to-fit . Then solve for 'right'
         * 4. 'left' is 'auto', 'width' and 'right' are not 'auto', then solve
         *    for 'left'
         * 5. 'width' is 'auto', 'left' and 'right' are not 'auto', then solve
         *    for 'width'
         * 6. 'right' is 'auto', 'left' and 'width' are not 'auto', then solve
         *    for 'right'
         *
         * Calculation of the shrink-to-fit width is similar to calculating the
         * width of a table cell using the automatic table layout algorithm.
         * Roughly: calculate the preferred width by formatting the content
         * without breaking lines other than where explicit line breaks occur,
         * and also calculate the preferred minimum width, e.g., by trying all
         * possible line breaks. CSS 2.1 does not define the exact algorithm.
         * Thirdly, calculate the available width: this is found by solving
         * for 'width' after setting 'left' (in case 1) or 'right' (in case 3)
         * to 0.
         *
         * Then the shrink-to-fit width is:
         * min(max(preferred minimum width, available width), preferred width).
        \*--------------------------------------------------------------------*/
        // NOTE: For rules 3 and 6 it is not necessary to solve for 'right'
        // because the value is not used for any further calculations.

        // Calculate margins, 'auto' margins are ignored.
        marginLogicalLeftValue = minimumValueForLength(marginLogicalLeft, containerRelativeLogicalWidth);
        marginLogicalRightValue = minimumValueForLength(marginLogicalRight, containerRelativeLogicalWidth);

        const LayoutUnit availableSpace = containerLogicalWidth - (marginLogicalLeftValue + marginLogicalRightValue + bordersPlusPadding);

        // FIXME: Is there a faster way to find the correct case?
        // Use rule/case that applies.
        if (logicalLeftIsAuto && logicalWidthIsAuto && !logicalRightIsAuto) {
            // RULE 1: (use shrink-to-fit for width, and solve of left)
            LayoutUnit logicalRightValue = valueForLength(logicalRight, containerLogicalWidth);

            // FIXME: would it be better to have shrink-to-fit in one step?
            LayoutUnit preferredWidth = maxPreferredLogicalWidth() - bordersPlusPadding;
            LayoutUnit preferredMinWidth = minPreferredLogicalWidth() - bordersPlusPadding;
            LayoutUnit availableWidth = availableSpace - logicalRightValue;
            computedValues.m_extent = std::min(std::max(preferredMinWidth, availableWidth), preferredWidth);
            logicalLeftValue = availableSpace - (computedValues.m_extent + logicalRightValue);
        } else if (!logicalLeftIsAuto && logicalWidthIsAuto && logicalRightIsAuto) {
            // RULE 3: (use shrink-to-fit for width, and no need solve of right)
            logicalLeftValue = valueForLength(logicalLeft, containerLogicalWidth);

            shrinkToFitWidth(availableSpace, logicalLeftValue, bordersPlusPadding, computedValues);
        } else if (logicalLeftIsAuto && !logicalWidthIsAuto && !logicalRightIsAuto) {
            // RULE 4: (solve for left)
            computedValues.m_extent = adjustContentBoxLogicalWidthForBoxSizing(valueForLength(logicalWidth, containerLogicalWidth));
            logicalLeftValue = availableSpace - (computedValues.m_extent + valueForLength(logicalRight, containerLogicalWidth));
        } else if (!logicalLeftIsAuto && logicalWidthIsAuto && !logicalRightIsAuto) {
            // RULE 5: (solve for width)
            logicalLeftValue = valueForLength(logicalLeft, containerLogicalWidth);
            computedValues.m_extent = availableSpace - (logicalLeftValue + valueForLength(logicalRight, containerLogicalWidth));
        } else if (!logicalLeftIsAuto && !logicalWidthIsAuto && logicalRightIsAuto) {
            // RULE 6: (no need solve for right)
            logicalLeftValue = valueForLength(logicalLeft, containerLogicalWidth);
            computedValues.m_extent = adjustContentBoxLogicalWidthForBoxSizing(valueForLength(logicalWidth, containerLogicalWidth));
        }
    }

    // Use computed values to calculate the horizontal position.

    // FIXME: This hack is needed to calculate the  logical left position for a 'rtl' relatively
    // positioned, inline because right now, it is using the logical left position
    // of the first line box when really it should use the last line box.  When
    // this is fixed elsewhere, this block should be removed.
    if (containerBlock->isRenderInline() && !containerBlock->style()->isLeftToRightDirection()) {
        const RenderInline* flow = toRenderInline(containerBlock);
        InlineFlowBox* firstLine = flow->firstLineBox();
        InlineFlowBox* lastLine = flow->lastLineBox();
        if (firstLine && lastLine && firstLine != lastLine) {
            computedValues.m_position = logicalLeftValue + marginLogicalLeftValue + lastLine->borderLogicalLeft() + (lastLine->logicalLeft() - firstLine->logicalLeft());
            return;
        }
    }

    computedValues.m_position = logicalLeftValue + marginLogicalLeftValue;
    computeLogicalLeftPositionedOffset(computedValues.m_position, this, computedValues.m_extent, containerBlock, containerLogicalWidth);
}

static void computeBlockStaticDistance(Length& logicalTop, Length& logicalBottom, const RenderBox* child, const RenderBoxModelObject* containerBlock)
{
    if (!logicalTop.isAuto() || !logicalBottom.isAuto())
        return;

    // FIXME: The static distance computation has not been patched for mixed writing modes.
    LayoutUnit staticLogicalTop = child->layer()->staticBlockPosition() - containerBlock->borderBefore();
    for (RenderObject* curr = child->parent(); curr && curr != containerBlock; curr = curr->container()) {
        if (curr->isBox())
            staticLogicalTop += toRenderBox(curr)->logicalTop();
    }
    logicalTop.setValue(Fixed, staticLogicalTop);
}

void RenderBox::computePositionedLogicalHeight(LogicalExtentComputedValues& computedValues) const
{
    if (isReplaced()) {
        computePositionedLogicalHeightReplaced(computedValues);
        return;
    }

    // The following is based off of the W3C Working Draft from April 11, 2006 of
    // CSS 2.1: Section 10.6.4 "Absolutely positioned, non-replaced elements"
    // <http://www.w3.org/TR/2005/WD-CSS21-20050613/visudet.html#abs-non-replaced-height>
    // (block-style-comments in this function and in computePositionedLogicalHeightUsing()
    // correspond to text from the spec)


    // We don't use containingBlock(), since we may be positioned by an enclosing relpositioned inline.
    const RenderBoxModelObject* containerBlock = toRenderBoxModelObject(container());

    const LayoutUnit containerLogicalHeight = containingBlockLogicalHeightForPositioned(containerBlock);

    RenderStyle* styleToUse = style();
    const LayoutUnit bordersPlusPadding = borderAndPaddingLogicalHeight();
    const Length marginBefore = styleToUse->marginBefore();
    const Length marginAfter = styleToUse->marginAfter();
    Length logicalTopLength = styleToUse->logicalTop();
    Length logicalBottomLength = styleToUse->logicalBottom();

    /*---------------------------------------------------------------------------*\
     * For the purposes of this section and the next, the term "static position"
     * (of an element) refers, roughly, to the position an element would have had
     * in the normal flow. More precisely, the static position for 'top' is the
     * distance from the top edge of the containing block to the top margin edge
     * of a hypothetical box that would have been the first box of the element if
     * its 'position' property had been 'static' and 'float' had been 'none'. The
     * value is negative if the hypothetical box is above the containing block.
     *
     * But rather than actually calculating the dimensions of that hypothetical
     * box, user agents are free to make a guess at its probable position.
     *
     * For the purposes of calculating the static position, the containing block
     * of fixed positioned elements is the initial containing block instead of
     * the viewport.
    \*---------------------------------------------------------------------------*/

    // see FIXME 1
    // Calculate the static distance if needed.
    computeBlockStaticDistance(logicalTopLength, logicalBottomLength, this, containerBlock);

    // Calculate constraint equation values for 'height' case.
    LayoutUnit logicalHeight = computedValues.m_extent;
    computePositionedLogicalHeightUsing(styleToUse->logicalHeight(), containerBlock, containerLogicalHeight, bordersPlusPadding, logicalHeight,
                                        logicalTopLength, logicalBottomLength, marginBefore, marginAfter,
                                        computedValues);

    // Avoid doing any work in the common case (where the values of min-height and max-height are their defaults).
    // see FIXME 2

    // Calculate constraint equation values for 'max-height' case.
    if (!styleToUse->logicalMaxHeight().isMaxSizeNone()) {
        LogicalExtentComputedValues maxValues;

        computePositionedLogicalHeightUsing(styleToUse->logicalMaxHeight(), containerBlock, containerLogicalHeight, bordersPlusPadding, logicalHeight,
                                            logicalTopLength, logicalBottomLength, marginBefore, marginAfter,
                                            maxValues);

        if (computedValues.m_extent > maxValues.m_extent) {
            computedValues.m_extent = maxValues.m_extent;
            computedValues.m_position = maxValues.m_position;
            computedValues.m_margins.m_before = maxValues.m_margins.m_before;
            computedValues.m_margins.m_after = maxValues.m_margins.m_after;
        }
    }

    // Calculate constraint equation values for 'min-height' case.
    if (!styleToUse->logicalMinHeight().isZero() || styleToUse->logicalMinHeight().isIntrinsic()) {
        LogicalExtentComputedValues minValues;

        computePositionedLogicalHeightUsing(styleToUse->logicalMinHeight(), containerBlock, containerLogicalHeight, bordersPlusPadding, logicalHeight,
                                            logicalTopLength, logicalBottomLength, marginBefore, marginAfter,
                                            minValues);

        if (computedValues.m_extent < minValues.m_extent) {
            computedValues.m_extent = minValues.m_extent;
            computedValues.m_position = minValues.m_position;
            computedValues.m_margins.m_before = minValues.m_margins.m_before;
            computedValues.m_margins.m_after = minValues.m_margins.m_after;
        }
    }

    // Set final height value.
    computedValues.m_extent += bordersPlusPadding;
}

static void computeLogicalTopPositionedOffset(LayoutUnit& logicalTopPos, const RenderBox* child, LayoutUnit logicalHeightValue, const RenderBoxModelObject* containerBlock, LayoutUnit containerLogicalHeight)
{
    // FIXME(sky): Remove
    logicalTopPos += containerBlock->borderTop();
}

void RenderBox::computePositionedLogicalHeightUsing(Length logicalHeightLength, const RenderBoxModelObject* containerBlock,
                                                    LayoutUnit containerLogicalHeight, LayoutUnit bordersPlusPadding, LayoutUnit logicalHeight,
                                                    const Length& logicalTop, const Length& logicalBottom, const Length& marginBefore,
                                                    const Length& marginAfter, LogicalExtentComputedValues& computedValues) const
{
    // 'top' and 'bottom' cannot both be 'auto' because 'top would of been
    // converted to the static position in computePositionedLogicalHeight()
    ASSERT(!(logicalTop.isAuto() && logicalBottom.isAuto()));

    LayoutUnit logicalHeightValue;
    LayoutUnit contentLogicalHeight = logicalHeight - bordersPlusPadding;

    const LayoutUnit containerRelativeLogicalWidth = containingBlockLogicalWidthForPositioned(containerBlock);

    LayoutUnit logicalTopValue = 0;

    bool logicalHeightIsAuto = logicalHeightLength.isAuto();
    bool logicalTopIsAuto = logicalTop.isAuto();
    bool logicalBottomIsAuto = logicalBottom.isAuto();

    LayoutUnit resolvedLogicalHeight;
    if (logicalHeightLength.isIntrinsic())
        resolvedLogicalHeight = computeIntrinsicLogicalContentHeightUsing(logicalHeightLength, contentLogicalHeight, bordersPlusPadding);
    else
        resolvedLogicalHeight = adjustContentBoxLogicalHeightForBoxSizing(valueForLength(logicalHeightLength, containerLogicalHeight));

    if (!logicalTopIsAuto && !logicalHeightIsAuto && !logicalBottomIsAuto) {
        /*-----------------------------------------------------------------------*\
         * If none of the three are 'auto': If both 'margin-top' and 'margin-
         * bottom' are 'auto', solve the equation under the extra constraint that
         * the two margins get equal values. If one of 'margin-top' or 'margin-
         * bottom' is 'auto', solve the equation for that value. If the values
         * are over-constrained, ignore the value for 'bottom' and solve for that
         * value.
        \*-----------------------------------------------------------------------*/
        // NOTE:  It is not necessary to solve for 'bottom' in the over constrained
        // case because the value is not used for any further calculations.

        logicalHeightValue = resolvedLogicalHeight;
        logicalTopValue = valueForLength(logicalTop, containerLogicalHeight);

        const LayoutUnit availableSpace = containerLogicalHeight - (logicalTopValue + logicalHeightValue + valueForLength(logicalBottom, containerLogicalHeight) + bordersPlusPadding);

        // Margins are now the only unknown
        if (marginBefore.isAuto() && marginAfter.isAuto()) {
            // Both margins auto, solve for equality
            // NOTE: This may result in negative values.
            computedValues.m_margins.m_before = availableSpace / 2; // split the difference
            computedValues.m_margins.m_after = availableSpace - computedValues.m_margins.m_before; // account for odd valued differences
        } else if (marginBefore.isAuto()) {
            // Solve for top margin
            computedValues.m_margins.m_after = valueForLength(marginAfter, containerRelativeLogicalWidth);
            computedValues.m_margins.m_before = availableSpace - computedValues.m_margins.m_after;
        } else if (marginAfter.isAuto()) {
            // Solve for bottom margin
            computedValues.m_margins.m_before = valueForLength(marginBefore, containerRelativeLogicalWidth);
            computedValues.m_margins.m_after = availableSpace - computedValues.m_margins.m_before;
        } else {
            // Over-constrained, (no need solve for bottom)
            computedValues.m_margins.m_before = valueForLength(marginBefore, containerRelativeLogicalWidth);
            computedValues.m_margins.m_after = valueForLength(marginAfter, containerRelativeLogicalWidth);
        }
    } else {
        /*--------------------------------------------------------------------*\
         * Otherwise, set 'auto' values for 'margin-top' and 'margin-bottom'
         * to 0, and pick the one of the following six rules that applies.
         *
         * 1. 'top' and 'height' are 'auto' and 'bottom' is not 'auto', then
         *    the height is based on the content, and solve for 'top'.
         *
         *              OMIT RULE 2 AS IT SHOULD NEVER BE HIT
         * ------------------------------------------------------------------
         * 2. 'top' and 'bottom' are 'auto' and 'height' is not 'auto', then
         *    set 'top' to the static position, and solve for 'bottom'.
         * ------------------------------------------------------------------
         *
         * 3. 'height' and 'bottom' are 'auto' and 'top' is not 'auto', then
         *    the height is based on the content, and solve for 'bottom'.
         * 4. 'top' is 'auto', 'height' and 'bottom' are not 'auto', and
         *    solve for 'top'.
         * 5. 'height' is 'auto', 'top' and 'bottom' are not 'auto', and
         *    solve for 'height'.
         * 6. 'bottom' is 'auto', 'top' and 'height' are not 'auto', and
         *    solve for 'bottom'.
        \*--------------------------------------------------------------------*/
        // NOTE: For rules 3 and 6 it is not necessary to solve for 'bottom'
        // because the value is not used for any further calculations.

        // Calculate margins, 'auto' margins are ignored.
        computedValues.m_margins.m_before = minimumValueForLength(marginBefore, containerRelativeLogicalWidth);
        computedValues.m_margins.m_after = minimumValueForLength(marginAfter, containerRelativeLogicalWidth);

        const LayoutUnit availableSpace = containerLogicalHeight - (computedValues.m_margins.m_before + computedValues.m_margins.m_after + bordersPlusPadding);

        // Use rule/case that applies.
        if (logicalTopIsAuto && logicalHeightIsAuto && !logicalBottomIsAuto) {
            // RULE 1: (height is content based, solve of top)
            logicalHeightValue = contentLogicalHeight;
            logicalTopValue = availableSpace - (logicalHeightValue + valueForLength(logicalBottom, containerLogicalHeight));
        } else if (!logicalTopIsAuto && logicalHeightIsAuto && logicalBottomIsAuto) {
            // RULE 3: (height is content based, no need solve of bottom)
            logicalTopValue = valueForLength(logicalTop, containerLogicalHeight);
            logicalHeightValue = contentLogicalHeight;
        } else if (logicalTopIsAuto && !logicalHeightIsAuto && !logicalBottomIsAuto) {
            // RULE 4: (solve of top)
            logicalHeightValue = resolvedLogicalHeight;
            logicalTopValue = availableSpace - (logicalHeightValue + valueForLength(logicalBottom, containerLogicalHeight));
        } else if (!logicalTopIsAuto && logicalHeightIsAuto && !logicalBottomIsAuto) {
            // RULE 5: (solve of height)
            logicalTopValue = valueForLength(logicalTop, containerLogicalHeight);
            logicalHeightValue = std::max<LayoutUnit>(0, availableSpace - (logicalTopValue + valueForLength(logicalBottom, containerLogicalHeight)));
        } else if (!logicalTopIsAuto && !logicalHeightIsAuto && logicalBottomIsAuto) {
            // RULE 6: (no need solve of bottom)
            logicalHeightValue = resolvedLogicalHeight;
            logicalTopValue = valueForLength(logicalTop, containerLogicalHeight);
        }
    }
    computedValues.m_extent = logicalHeightValue;

    // Use computed values to calculate the vertical position.
    computedValues.m_position = logicalTopValue + computedValues.m_margins.m_before;
    computeLogicalTopPositionedOffset(computedValues.m_position, this, logicalHeightValue, containerBlock, containerLogicalHeight);
}

void RenderBox::computePositionedLogicalWidthReplaced(LogicalExtentComputedValues& computedValues) const
{
    // The following is based off of the W3C Working Draft from April 11, 2006 of
    // CSS 2.1: Section 10.3.8 "Absolutely positioned, replaced elements"
    // <http://www.w3.org/TR/2005/WD-CSS21-20050613/visudet.html#abs-replaced-width>
    // (block-style-comments in this function correspond to text from the spec and
    // the numbers correspond to numbers in spec)

    // We don't use containingBlock(), since we may be positioned by an enclosing
    // relative positioned inline.
    const RenderBoxModelObject* containerBlock = toRenderBoxModelObject(container());

    const LayoutUnit containerLogicalWidth = containingBlockLogicalWidthForPositioned(containerBlock);
    const LayoutUnit containerRelativeLogicalWidth = containingBlockLogicalWidthForPositioned(containerBlock);

    // To match WinIE, in quirks mode use the parent's 'direction' property
    // instead of the the container block's.
    TextDirection containerDirection = containerBlock->style()->direction();

    // Variables to solve.
    Length logicalLeft = style()->logicalLeft();
    Length logicalRight = style()->logicalRight();
    Length marginLogicalLeft = style()->marginLeft();
    Length marginLogicalRight = style()->marginRight();
    LayoutUnit& marginLogicalLeftAlias = style()->isLeftToRightDirection() ? computedValues.m_margins.m_start : computedValues.m_margins.m_end;
    LayoutUnit& marginLogicalRightAlias = style()->isLeftToRightDirection() ? computedValues.m_margins.m_end : computedValues.m_margins.m_start;

    /*-----------------------------------------------------------------------*\
     * 1. The used value of 'width' is determined as for inline replaced
     *    elements.
    \*-----------------------------------------------------------------------*/
    // NOTE: This value of width is final in that the min/max width calculations
    // are dealt with in computeReplacedWidth().  This means that the steps to produce
    // correct max/min in the non-replaced version, are not necessary.
    computedValues.m_extent = computeReplacedLogicalWidth() + borderAndPaddingLogicalWidth();

    const LayoutUnit availableSpace = containerLogicalWidth - computedValues.m_extent;

    /*-----------------------------------------------------------------------*\
     * 2. If both 'left' and 'right' have the value 'auto', then if 'direction'
     *    of the containing block is 'ltr', set 'left' to the static position;
     *    else if 'direction' is 'rtl', set 'right' to the static position.
    \*-----------------------------------------------------------------------*/
    // see FIXME 1
    computeInlineStaticDistance(logicalLeft, logicalRight, this, containerBlock, containerLogicalWidth);

    /*-----------------------------------------------------------------------*\
     * 3. If 'left' or 'right' are 'auto', replace any 'auto' on 'margin-left'
     *    or 'margin-right' with '0'.
    \*-----------------------------------------------------------------------*/
    if (logicalLeft.isAuto() || logicalRight.isAuto()) {
        if (marginLogicalLeft.isAuto())
            marginLogicalLeft.setValue(Fixed, 0);
        if (marginLogicalRight.isAuto())
            marginLogicalRight.setValue(Fixed, 0);
    }

    /*-----------------------------------------------------------------------*\
     * 4. If at this point both 'margin-left' and 'margin-right' are still
     *    'auto', solve the equation under the extra constraint that the two
     *    margins must get equal values, unless this would make them negative,
     *    in which case when the direction of the containing block is 'ltr'
     *    ('rtl'), set 'margin-left' ('margin-right') to zero and solve for
     *    'margin-right' ('margin-left').
    \*-----------------------------------------------------------------------*/
    LayoutUnit logicalLeftValue = 0;
    LayoutUnit logicalRightValue = 0;

    if (marginLogicalLeft.isAuto() && marginLogicalRight.isAuto()) {
        // 'left' and 'right' cannot be 'auto' due to step 3
        ASSERT(!(logicalLeft.isAuto() && logicalRight.isAuto()));

        logicalLeftValue = valueForLength(logicalLeft, containerLogicalWidth);
        logicalRightValue = valueForLength(logicalRight, containerLogicalWidth);

        LayoutUnit difference = availableSpace - (logicalLeftValue + logicalRightValue);
        if (difference > 0) {
            marginLogicalLeftAlias = difference / 2; // split the difference
            marginLogicalRightAlias = difference - marginLogicalLeftAlias; // account for odd valued differences
        } else {
            // Use the containing block's direction rather than the parent block's
            // per CSS 2.1 reference test abspos-replaced-width-margin-000.
            if (containerDirection == LTR) {
                marginLogicalLeftAlias = 0;
                marginLogicalRightAlias = difference; // will be negative
            } else {
                marginLogicalLeftAlias = difference; // will be negative
                marginLogicalRightAlias = 0;
            }
        }

    /*-----------------------------------------------------------------------*\
     * 5. If at this point there is an 'auto' left, solve the equation for
     *    that value.
    \*-----------------------------------------------------------------------*/
    } else if (logicalLeft.isAuto()) {
        marginLogicalLeftAlias = valueForLength(marginLogicalLeft, containerRelativeLogicalWidth);
        marginLogicalRightAlias = valueForLength(marginLogicalRight, containerRelativeLogicalWidth);
        logicalRightValue = valueForLength(logicalRight, containerLogicalWidth);

        // Solve for 'left'
        logicalLeftValue = availableSpace - (logicalRightValue + marginLogicalLeftAlias + marginLogicalRightAlias);
    } else if (logicalRight.isAuto()) {
        marginLogicalLeftAlias = valueForLength(marginLogicalLeft, containerRelativeLogicalWidth);
        marginLogicalRightAlias = valueForLength(marginLogicalRight, containerRelativeLogicalWidth);
        logicalLeftValue = valueForLength(logicalLeft, containerLogicalWidth);

        // Solve for 'right'
        logicalRightValue = availableSpace - (logicalLeftValue + marginLogicalLeftAlias + marginLogicalRightAlias);
    } else if (marginLogicalLeft.isAuto()) {
        marginLogicalRightAlias = valueForLength(marginLogicalRight, containerRelativeLogicalWidth);
        logicalLeftValue = valueForLength(logicalLeft, containerLogicalWidth);
        logicalRightValue = valueForLength(logicalRight, containerLogicalWidth);

        // Solve for 'margin-left'
        marginLogicalLeftAlias = availableSpace - (logicalLeftValue + logicalRightValue + marginLogicalRightAlias);
    } else if (marginLogicalRight.isAuto()) {
        marginLogicalLeftAlias = valueForLength(marginLogicalLeft, containerRelativeLogicalWidth);
        logicalLeftValue = valueForLength(logicalLeft, containerLogicalWidth);
        logicalRightValue = valueForLength(logicalRight, containerLogicalWidth);

        // Solve for 'margin-right'
        marginLogicalRightAlias = availableSpace - (logicalLeftValue + logicalRightValue + marginLogicalLeftAlias);
    } else {
        // Nothing is 'auto', just calculate the values.
        marginLogicalLeftAlias = valueForLength(marginLogicalLeft, containerRelativeLogicalWidth);
        marginLogicalRightAlias = valueForLength(marginLogicalRight, containerRelativeLogicalWidth);
        logicalRightValue = valueForLength(logicalRight, containerLogicalWidth);
        logicalLeftValue = valueForLength(logicalLeft, containerLogicalWidth);
        // If the containing block is right-to-left, then push the left position as far to the right as possible
        if (containerDirection == RTL) {
            int totalLogicalWidth = computedValues.m_extent + logicalLeftValue + logicalRightValue +  marginLogicalLeftAlias + marginLogicalRightAlias;
            logicalLeftValue = containerLogicalWidth - (totalLogicalWidth - logicalLeftValue);
        }
    }

    /*-----------------------------------------------------------------------*\
     * 6. If at this point the values are over-constrained, ignore the value
     *    for either 'left' (in case the 'direction' property of the
     *    containing block is 'rtl') or 'right' (in case 'direction' is
     *    'ltr') and solve for that value.
    \*-----------------------------------------------------------------------*/
    // NOTE: Constraints imposed by the width of the containing block and its content have already been accounted for above.

    // FIXME: Deal with differing writing modes here.  Our offset needs to be in the containing block's coordinate space, so that
    // can make the result here rather complicated to compute.

    // Use computed values to calculate the horizontal position.

    // FIXME: This hack is needed to calculate the logical left position for a 'rtl' relatively
    // positioned, inline containing block because right now, it is using the logical left position
    // of the first line box when really it should use the last line box.  When
    // this is fixed elsewhere, this block should be removed.
    if (containerBlock->isRenderInline() && !containerBlock->style()->isLeftToRightDirection()) {
        const RenderInline* flow = toRenderInline(containerBlock);
        InlineFlowBox* firstLine = flow->firstLineBox();
        InlineFlowBox* lastLine = flow->lastLineBox();
        if (firstLine && lastLine && firstLine != lastLine) {
            computedValues.m_position = logicalLeftValue + marginLogicalLeftAlias + lastLine->borderLogicalLeft() + (lastLine->logicalLeft() - firstLine->logicalLeft());
            return;
        }
    }

    LayoutUnit logicalLeftPos = logicalLeftValue + marginLogicalLeftAlias;
    computeLogicalLeftPositionedOffset(logicalLeftPos, this, computedValues.m_extent, containerBlock, containerLogicalWidth);
    computedValues.m_position = logicalLeftPos;
}

void RenderBox::computePositionedLogicalHeightReplaced(LogicalExtentComputedValues& computedValues) const
{
    // The following is based off of the W3C Working Draft from April 11, 2006 of
    // CSS 2.1: Section 10.6.5 "Absolutely positioned, replaced elements"
    // <http://www.w3.org/TR/2005/WD-CSS21-20050613/visudet.html#abs-replaced-height>
    // (block-style-comments in this function correspond to text from the spec and
    // the numbers correspond to numbers in spec)

    // We don't use containingBlock(), since we may be positioned by an enclosing relpositioned inline.
    const RenderBoxModelObject* containerBlock = toRenderBoxModelObject(container());

    const LayoutUnit containerLogicalHeight = containingBlockLogicalHeightForPositioned(containerBlock);
    const LayoutUnit containerRelativeLogicalWidth = containingBlockLogicalWidthForPositioned(containerBlock);

    // Variables to solve.
    Length marginBefore = style()->marginBefore();
    Length marginAfter = style()->marginAfter();
    LayoutUnit& marginBeforeAlias = computedValues.m_margins.m_before;
    LayoutUnit& marginAfterAlias = computedValues.m_margins.m_after;

    Length logicalTop = style()->logicalTop();
    Length logicalBottom = style()->logicalBottom();

    /*-----------------------------------------------------------------------*\
     * 1. The used value of 'height' is determined as for inline replaced
     *    elements.
    \*-----------------------------------------------------------------------*/
    // NOTE: This value of height is final in that the min/max height calculations
    // are dealt with in computeReplacedHeight().  This means that the steps to produce
    // correct max/min in the non-replaced version, are not necessary.
    computedValues.m_extent = computeReplacedLogicalHeight() + borderAndPaddingLogicalHeight();
    const LayoutUnit availableSpace = containerLogicalHeight - computedValues.m_extent;

    /*-----------------------------------------------------------------------*\
     * 2. If both 'top' and 'bottom' have the value 'auto', replace 'top'
     *    with the element's static position.
    \*-----------------------------------------------------------------------*/
    // see FIXME 1
    computeBlockStaticDistance(logicalTop, logicalBottom, this, containerBlock);

    /*-----------------------------------------------------------------------*\
     * 3. If 'bottom' is 'auto', replace any 'auto' on 'margin-top' or
     *    'margin-bottom' with '0'.
    \*-----------------------------------------------------------------------*/
    // FIXME: The spec. says that this step should only be taken when bottom is
    // auto, but if only top is auto, this makes step 4 impossible.
    if (logicalTop.isAuto() || logicalBottom.isAuto()) {
        if (marginBefore.isAuto())
            marginBefore.setValue(Fixed, 0);
        if (marginAfter.isAuto())
            marginAfter.setValue(Fixed, 0);
    }

    /*-----------------------------------------------------------------------*\
     * 4. If at this point both 'margin-top' and 'margin-bottom' are still
     *    'auto', solve the equation under the extra constraint that the two
     *    margins must get equal values.
    \*-----------------------------------------------------------------------*/
    LayoutUnit logicalTopValue = 0;
    LayoutUnit logicalBottomValue = 0;

    if (marginBefore.isAuto() && marginAfter.isAuto()) {
        // 'top' and 'bottom' cannot be 'auto' due to step 2 and 3 combined.
        ASSERT(!(logicalTop.isAuto() || logicalBottom.isAuto()));

        logicalTopValue = valueForLength(logicalTop, containerLogicalHeight);
        logicalBottomValue = valueForLength(logicalBottom, containerLogicalHeight);

        LayoutUnit difference = availableSpace - (logicalTopValue + logicalBottomValue);
        // NOTE: This may result in negative values.
        marginBeforeAlias =  difference / 2; // split the difference
        marginAfterAlias = difference - marginBeforeAlias; // account for odd valued differences

    /*-----------------------------------------------------------------------*\
     * 5. If at this point there is only one 'auto' left, solve the equation
     *    for that value.
    \*-----------------------------------------------------------------------*/
    } else if (logicalTop.isAuto()) {
        marginBeforeAlias = valueForLength(marginBefore, containerRelativeLogicalWidth);
        marginAfterAlias = valueForLength(marginAfter, containerRelativeLogicalWidth);
        logicalBottomValue = valueForLength(logicalBottom, containerLogicalHeight);

        // Solve for 'top'
        logicalTopValue = availableSpace - (logicalBottomValue + marginBeforeAlias + marginAfterAlias);
    } else if (logicalBottom.isAuto()) {
        marginBeforeAlias = valueForLength(marginBefore, containerRelativeLogicalWidth);
        marginAfterAlias = valueForLength(marginAfter, containerRelativeLogicalWidth);
        logicalTopValue = valueForLength(logicalTop, containerLogicalHeight);

        // Solve for 'bottom'
        // NOTE: It is not necessary to solve for 'bottom' because we don't ever
        // use the value.
    } else if (marginBefore.isAuto()) {
        marginAfterAlias = valueForLength(marginAfter, containerRelativeLogicalWidth);
        logicalTopValue = valueForLength(logicalTop, containerLogicalHeight);
        logicalBottomValue = valueForLength(logicalBottom, containerLogicalHeight);

        // Solve for 'margin-top'
        marginBeforeAlias = availableSpace - (logicalTopValue + logicalBottomValue + marginAfterAlias);
    } else if (marginAfter.isAuto()) {
        marginBeforeAlias = valueForLength(marginBefore, containerRelativeLogicalWidth);
        logicalTopValue = valueForLength(logicalTop, containerLogicalHeight);
        logicalBottomValue = valueForLength(logicalBottom, containerLogicalHeight);

        // Solve for 'margin-bottom'
        marginAfterAlias = availableSpace - (logicalTopValue + logicalBottomValue + marginBeforeAlias);
    } else {
        // Nothing is 'auto', just calculate the values.
        marginBeforeAlias = valueForLength(marginBefore, containerRelativeLogicalWidth);
        marginAfterAlias = valueForLength(marginAfter, containerRelativeLogicalWidth);
        logicalTopValue = valueForLength(logicalTop, containerLogicalHeight);
        // NOTE: It is not necessary to solve for 'bottom' because we don't ever
        // use the value.
     }

    /*-----------------------------------------------------------------------*\
     * 6. If at this point the values are over-constrained, ignore the value
     *    for 'bottom' and solve for that value.
    \*-----------------------------------------------------------------------*/
    // NOTE: It is not necessary to do this step because we don't end up using
    // the value of 'bottom' regardless of whether the values are over-constrained
    // or not.

    // Use computed values to calculate the vertical position.
    LayoutUnit logicalTopPos = logicalTopValue + marginBeforeAlias;
    computeLogicalTopPositionedOffset(logicalTopPos, this, computedValues.m_extent, containerBlock, containerLogicalHeight);
    computedValues.m_position = logicalTopPos;
}

LayoutRect RenderBox::localCaretRect(InlineBox* box, int caretOffset, LayoutUnit* extraWidthToEndOfLine)
{
    // VisiblePositions at offsets inside containers either a) refer to the positions before/after
    // those containers (tables and select elements) or b) refer to the position inside an empty block.
    // They never refer to children.
    // FIXME: Paint the carets inside empty blocks differently than the carets before/after elements.

    LayoutRect rect(location(), LayoutSize(caretWidth, height()));
    bool ltr = box ? box->isLeftToRightDirection() : style()->isLeftToRightDirection();

    if ((!caretOffset) ^ ltr)
        rect.move(LayoutSize(width() - caretWidth, 0));

    if (box) {
        RootInlineBox& rootBox = box->root();
        LayoutUnit top = rootBox.lineTop();
        rect.setY(top);
        rect.setHeight(rootBox.lineBottom() - top);
    }

    // If height of box is smaller than font height, use the latter one,
    // otherwise the caret might become invisible.
    //
    // Also, if the box is not a replaced element, always use the font height.
    // This prevents the "big caret" bug described in:
    // <rdar://problem/3777804> Deleting all content in a document can result in giant tall-as-window insertion point
    //
    // FIXME: ignoring :first-line, missing good reason to take care of
    LayoutUnit fontHeight = style()->fontMetrics().height();
    if (fontHeight > rect.height() || !isReplaced())
        rect.setHeight(fontHeight);

    if (extraWidthToEndOfLine)
        *extraWidthToEndOfLine = x() + width() - rect.maxX();

    // Move to local coords
    rect.moveBy(-location());

    // FIXME: Border/padding should be added for all elements but this workaround
    // is needed because we use offsets inside an "atomic" element to represent
    // positions before and after the element in deprecated editing offsets.
    if (node() && !(editingIgnoresContent(node()) || isRenderedTableElement(node()))) {
        rect.setX(rect.x() + borderLeft() + paddingLeft());
        rect.setY(rect.y() + paddingTop() + borderTop());
    }

    return rect;
}

PositionWithAffinity RenderBox::positionForPoint(const LayoutPoint& point)
{
    // no children...return this render object's element, if there is one, and offset 0
    RenderObject* firstChild = slowFirstChild();
    if (!firstChild)
        return createPositionWithAffinity(node() ? firstPositionInOrBeforeNode(node()) : Position());

    // Pass off to the closest child.
    LayoutUnit minDist = LayoutUnit::max();
    RenderBox* closestRenderer = 0;
    LayoutPoint adjustedPoint = point;

    for (RenderObject* renderObject = firstChild; renderObject; renderObject = renderObject->nextSibling()) {
        if (!renderObject->slowFirstChild() && !renderObject->isInline() && !renderObject->isRenderBlockFlow())
            continue;

        if (!renderObject->isBox())
            continue;

        RenderBox* renderer = toRenderBox(renderObject);

        LayoutUnit top = renderer->borderTop() + renderer->paddingTop() + renderer->y();
        LayoutUnit bottom = top + renderer->contentHeight();
        LayoutUnit left = renderer->borderLeft() + renderer->paddingLeft() + renderer->x();
        LayoutUnit right = left + renderer->contentWidth();

        if (point.x() <= right && point.x() >= left && point.y() <= top && point.y() >= bottom)
            return renderer->positionForPoint(point - renderer->locationOffset());

        // Find the distance from (x, y) to the box.  Split the space around the box into 8 pieces
        // and use a different compare depending on which piece (x, y) is in.
        LayoutPoint cmp;
        if (point.x() > right) {
            if (point.y() < top)
                cmp = LayoutPoint(right, top);
            else if (point.y() > bottom)
                cmp = LayoutPoint(right, bottom);
            else
                cmp = LayoutPoint(right, point.y());
        } else if (point.x() < left) {
            if (point.y() < top)
                cmp = LayoutPoint(left, top);
            else if (point.y() > bottom)
                cmp = LayoutPoint(left, bottom);
            else
                cmp = LayoutPoint(left, point.y());
        } else {
            if (point.y() < top)
                cmp = LayoutPoint(point.x(), top);
            else
                cmp = LayoutPoint(point.x(), bottom);
        }

        LayoutSize difference = cmp - point;

        LayoutUnit dist = difference.width() * difference.width() + difference.height() * difference.height();
        if (dist < minDist) {
            closestRenderer = renderer;
            minDist = dist;
        }
    }

    if (closestRenderer)
        return closestRenderer->positionForPoint(adjustedPoint - closestRenderer->locationOffset());
    return createPositionWithAffinity(firstPositionInOrBeforeNode(node()));
}

void RenderBox::addVisualEffectOverflow()
{
    if (!style()->hasVisualOverflowingEffect())
        return;

    // Add in the final overflow with shadows, outsets and outline combined.
    LayoutRect visualEffectOverflow = borderBoxRect();
    visualEffectOverflow.expand(computeVisualEffectOverflowExtent());
    addVisualOverflow(visualEffectOverflow);
}

LayoutBoxExtent RenderBox::computeVisualEffectOverflowExtent() const
{
    ASSERT(style()->hasVisualOverflowingEffect());

    LayoutUnit top;
    LayoutUnit right;
    LayoutUnit bottom;
    LayoutUnit left;

    if (style()->boxShadow()) {
        style()->getBoxShadowExtent(top, right, bottom, left);

        // Box shadow extent's top and left are negative when extend to left and top direction, respectively.
        // Negate to make them positive.
        top = -top;
        left = -left;
    }

    if (style()->hasBorderImageOutsets()) {
        LayoutBoxExtent borderOutsets = style()->borderImageOutsets();
        top = std::max(top, borderOutsets.top());
        right = std::max(right, borderOutsets.right());
        bottom = std::max(bottom, borderOutsets.bottom());
        left = std::max(left, borderOutsets.left());
    }

    if (style()->hasOutline()) {
        if (style()->outlineStyleIsAuto()) {
            // The result focus ring rects are in coordinates of this object's border box.
            Vector<IntRect> focusRingRects;
            addFocusRingRects(focusRingRects, LayoutPoint(), this);
            IntRect rect = unionRect(focusRingRects);

            int outlineSize = GraphicsContext::focusRingOutsetExtent(style()->outlineOffset(), style()->outlineWidth());
            top = std::max<LayoutUnit>(top, -rect.y() + outlineSize);
            right = std::max<LayoutUnit>(right, rect.maxX() - width() + outlineSize);
            bottom = std::max<LayoutUnit>(bottom, rect.maxY() - height() + outlineSize);
            left = std::max<LayoutUnit>(left, -rect.x() + outlineSize);
        } else {
            LayoutUnit outlineSize = style()->outlineSize();
            top = std::max(top, outlineSize);
            right = std::max(right, outlineSize);
            bottom = std::max(bottom, outlineSize);
            left = std::max(left, outlineSize);
        }
    }

    return LayoutBoxExtent(top, right, bottom, left);
}

void RenderBox::addOverflowFromChild(RenderBox* child, const LayoutSize& delta)
{
    // Only propagate layout overflow from the child if the child isn't clipping its overflow.  If it is, then
    // its overflow is internal to it, and we don't care about it.  layoutOverflowRectForPropagation takes care of this
    // and just propagates the border box rect instead.
    LayoutRect childLayoutOverflowRect = child->layoutOverflowRectForPropagation();
    childLayoutOverflowRect.move(delta);
    addLayoutOverflow(childLayoutOverflowRect);

    // Add in visual overflow from the child.  Even if the child clips its overflow, it may still
    // have visual overflow of its own set from box shadows or reflections.  It is unnecessary to propagate this
    // overflow if we are clipping our own overflow.
    if (child->hasSelfPaintingLayer())
        return;
    LayoutRect childVisualOverflowRect = child->visualOverflowRect();
    childVisualOverflowRect.move(delta);
    addContentsVisualOverflow(childVisualOverflowRect);
}

void RenderBox::addLayoutOverflow(const LayoutRect& rect)
{
    LayoutRect clientBox = paddingBoxRect();
    if (clientBox.contains(rect) || rect.isEmpty())
        return;

    // For overflow clip objects, we don't want to propagate overflow into unreachable areas.
    LayoutRect overflowRect(rect);
    if (hasOverflowClip() || isRenderView()) {
        // Overflow is in the block's coordinate space and thus is flipped for horizontal-bt and vertical-rl
        // writing modes.  At this stage that is actually a simplification, since we can treat horizontal-tb/bt as the same
        // and vertical-lr/rl as the same.
        bool hasTopOverflow = false;
        bool hasLeftOverflow = !style()->isLeftToRightDirection();
        if (isFlexibleBox() && style()->isReverseFlexDirection()) {
            RenderFlexibleBox* flexibleBox = toRenderFlexibleBox(this);
            if (flexibleBox->isHorizontalFlow())
                hasLeftOverflow = true;
            else
                hasTopOverflow = true;
        }

        if (!hasTopOverflow)
            overflowRect.shiftYEdgeTo(std::max(overflowRect.y(), clientBox.y()));
        else
            overflowRect.shiftMaxYEdgeTo(std::min(overflowRect.maxY(), clientBox.maxY()));
        if (!hasLeftOverflow)
            overflowRect.shiftXEdgeTo(std::max(overflowRect.x(), clientBox.x()));
        else
            overflowRect.shiftMaxXEdgeTo(std::min(overflowRect.maxX(), clientBox.maxX()));

        // Now re-test with the adjusted rectangle and see if it has become unreachable or fully
        // contained.
        if (clientBox.contains(overflowRect) || overflowRect.isEmpty())
            return;
    }

    if (!m_overflow)
        m_overflow = adoptPtr(new RenderOverflow(clientBox, borderBoxRect()));

    m_overflow->addLayoutOverflow(overflowRect);
}

void RenderBox::addVisualOverflow(const LayoutRect& rect)
{
    LayoutRect borderBox = borderBoxRect();
    if (borderBox.contains(rect) || rect.isEmpty())
        return;

    if (!m_overflow)
        m_overflow = adoptPtr(new RenderOverflow(paddingBoxRect(), borderBox));

    m_overflow->addVisualOverflow(rect);
}

void RenderBox::addContentsVisualOverflow(const LayoutRect& rect)
{
    if (!hasOverflowClip()) {
        addVisualOverflow(rect);
        return;
    }

    if (!m_overflow)
        m_overflow = adoptPtr(new RenderOverflow(paddingBoxRect(), borderBoxRect()));
    m_overflow->addContentsVisualOverflow(rect);
}

void RenderBox::clearLayoutOverflow()
{
    if (!m_overflow)
        return;

    if (!hasVisualOverflow() && contentsVisualOverflowRect().isEmpty()) {
        clearAllOverflows();
        return;
    }

    m_overflow->setLayoutOverflow(paddingBoxRect());
}

bool RenderBox::percentageLogicalHeightIsResolvableFromBlock(const RenderBlock* containingBlock, bool isOutOfFlowPositioned)
{
    // In quirks mode, blocks with auto height are skipped, and we keep looking for an enclosing
    // block that may have a specified height and then use it. In strict mode, this violates the
    // specification, which states that percentage heights just revert to auto if the containing
    // block has an auto height. We still skip anonymous containing blocks in both modes, though, and look
    // only at explicit containers.
    const RenderBlock* cb = containingBlock;
    while (!cb->isRenderView() && !cb->isOutOfFlowPositioned() && cb->style()->logicalHeight().isAuto()) {
        if (!cb->isAnonymousBlock())
            break;
        cb = cb->containingBlock();
    }

    // A positioned element that specified both top/bottom or that specifies height should be treated as though it has a height
    // explicitly specified that can be used for any percentage computations.
    // FIXME: We can't just check top/bottom here.
    // https://bugs.webkit.org/show_bug.cgi?id=46500
    bool isOutOfFlowPositionedWithSpecifiedHeight = cb->isOutOfFlowPositioned() && (!cb->style()->logicalHeight().isAuto() || (!cb->style()->top().isAuto() && !cb->style()->bottom().isAuto()));

    // Otherwise we only use our percentage height if our containing block had a specified
    // height.
    if (cb->style()->logicalHeight().isFixed())
        return true;
    if (cb->style()->logicalHeight().isPercent() && !isOutOfFlowPositionedWithSpecifiedHeight)
        return percentageLogicalHeightIsResolvableFromBlock(cb->containingBlock(), cb->isOutOfFlowPositioned());
    if (cb->isRenderView() || isOutOfFlowPositionedWithSpecifiedHeight)
        return true;
    if (cb->isDocumentElement() && isOutOfFlowPositioned) {
        // Match the positioned objects behavior, which is that positioned objects will fill their viewport
        // always.  Note we could only hit this case by recurring into computePercentageLogicalHeight on a positioned containing block.
        return true;
    }

    return false;
}

LayoutUnit RenderBox::lineHeight(bool /*firstLine*/, LineDirectionMode direction, LinePositionMode /*linePositionMode*/) const
{
    if (isReplaced())
        return direction == HorizontalLine ? m_marginBox.top() + height() + m_marginBox.bottom() : m_marginBox.right() + width() + m_marginBox.left();
    return 0;
}

int RenderBox::baselinePosition(FontBaseline baselineType, bool /*firstLine*/, LineDirectionMode direction, LinePositionMode linePositionMode) const
{
    ASSERT(linePositionMode == PositionOnContainingLine);
    if (isReplaced()) {
        int result = direction == HorizontalLine ? m_marginBox.top() + height() + m_marginBox.bottom() : m_marginBox.right() + width() + m_marginBox.left();
        if (baselineType == AlphabeticBaseline)
            return result;
        return result - result / 2;
    }
    return 0;
}


RenderLayer* RenderBox::enclosingFloatPaintingLayer() const
{
    const RenderObject* curr = this;
    while (curr) {
        RenderLayer* layer = curr->hasLayer() && curr->isBox() ? toRenderBox(curr)->layer() : 0;
        if (layer && layer->isSelfPaintingLayer())
            return layer;
        curr = curr->parent();
    }
    return 0;
}

LayoutRect RenderBox::layoutOverflowRectForPropagation() const
{
    // Only propagate interior layout overflow if we don't clip it.
    LayoutRect rect = borderBoxRect();
    rect.expand(LayoutSize(LayoutUnit(), marginAfter()));

    if (!hasOverflowClip())
        rect.unite(layoutOverflowRect());

    bool hasTransform = hasLayer() && layer()->transform();
    if (isRelPositioned() || hasTransform) {
        if (hasTransform)
            rect = layer()->currentTransform().mapRect(rect);

        if (isRelPositioned())
            rect.move(offsetForInFlowPosition());
    }

    return rect;
}

LayoutUnit RenderBox::offsetLeft() const
{
    return adjustedPositionRelativeToOffsetParent(location()).x();
}

LayoutUnit RenderBox::offsetTop() const
{
    return adjustedPositionRelativeToOffsetParent(location()).y();
}

bool RenderBox::hasRelativeLogicalHeight() const
{
    return style()->logicalHeight().isPercent()
        || style()->logicalMinHeight().isPercent()
        || style()->logicalMaxHeight().isPercent();
}

void RenderBox::savePreviousBorderBoxSizeIfNeeded()
{
    // If m_rareData is already created, always save.
    if (!m_rareData) {
        LayoutSize paintInvalidationSize = previousPaintInvalidationRect().size();

        // Don't save old border box size if the paint rect is empty because we'll
        // full invalidate once the paint rect becomes non-empty.
        if (paintInvalidationSize.isEmpty())
            return;

        // Don't save old border box size if we can use size of the old paint rect
        // as the old border box size in the next invalidation.
        if (paintInvalidationSize == size())
            return;

        // We need the old border box size only when the box has background or box decorations.
        if (!style()->hasBackground() && !style()->hasBoxDecorations())
            return;
    }

    ensureRareData().m_previousBorderBoxSize = size();
}

LayoutSize RenderBox::computePreviousBorderBoxSize(const LayoutSize& previousBoundsSize) const
{
    // PreviousBorderBoxSize is only valid when there is background or box decorations.
    ASSERT(style()->hasBackground() || style()->hasBoxDecorations());

    if (m_rareData && m_rareData->m_previousBorderBoxSize.width() != -1)
        return m_rareData->m_previousBorderBoxSize;

    // We didn't save the old border box size because it was the same as the size of oldBounds.
    return previousBoundsSize;
}

RenderBox::BoxDecorationData::BoxDecorationData(const RenderStyle& style)
{
    backgroundColor = style.colorIncludingFallback(CSSPropertyBackgroundColor);
    hasBackground = backgroundColor.alpha() || style.hasBackgroundImage();
    ASSERT(hasBackground == style.hasBackground());
    hasBorder = style.hasBorder();
}

} // namespace blink
