/*
 * Copyright (C) 2006, 2007, 2008, 2009, 2010, 2011, 2012 Apple Inc. All rights reserved.
 *
 * Portions are Copyright (C) 1998 Netscape Communications Corporation.
 *
 * Other contributors:
 *   Robert O'Callahan <roc+@cs.cmu.edu>
 *   David Baron <dbaron@fas.harvard.edu>
 *   Christian Biesinger <cbiesinger@web.de>
 *   Randall Jesup <rjesup@wgate.com>
 *   Roland Mainz <roland.mainz@informatik.med.uni-giessen.de>
 *   Josh Soref <timeless@mac.com>
 *   Boris Zbarsky <bzbarsky@mit.edu>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 * Alternatively, the contents of this file may be used under the terms
 * of either the Mozilla Public License Version 1.1, found at
 * http://www.mozilla.org/MPL/ (the "MPL") or the GNU General Public
 * License Version 2.0, found at http://www.fsf.org/copyleft/gpl.html
 * (the "GPL"), in which case the provisions of the MPL or the GPL are
 * applicable instead of those above.  If you wish to allow use of your
 * version of this file only under the terms of one of those two
 * licenses (the MPL or the GPL) and not to allow others to use your
 * version of this file under the LGPL, indicate your decision by
 * deletingthe provisions above and replace them with the notice and
 * other provisions required by the MPL or the GPL, as the case may be.
 * If you do not delete the provisions above, a recipient may use your
 * version of this file under any of the LGPL, the MPL or the GPL.
 */

#include "sky/engine/config.h"
#include "sky/engine/core/rendering/RenderLayer.h"

#include "sky/engine/core/dom/Node.h"
#include "sky/engine/core/dom/shadow/ShadowRoot.h"
#include "sky/engine/core/editing/FrameSelection.h"
#include "sky/engine/core/frame/FrameView.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/inspector/InspectorTraceEvents.h"
#include "sky/engine/core/page/Chrome.h"
#include "sky/engine/core/page/EventHandler.h"
#include "sky/engine/core/page/FocusController.h"
#include "sky/engine/core/page/Page.h"
#include "sky/engine/core/rendering/HitTestResult.h"
#include "sky/engine/core/rendering/RenderGeometryMap.h"
#include "sky/engine/core/rendering/RenderView.h"
#include "sky/engine/platform/PlatformGestureEvent.h"
#include "sky/engine/platform/PlatformMouseEvent.h"
#include "sky/engine/platform/graphics/GraphicsContextStateSaver.h"
#include "sky/engine/platform/graphics/GraphicsLayer.h"
#include "sky/engine/platform/scroll/ScrollAnimator.h"
#include "sky/engine/platform/scroll/Scrollbar.h"
#include "sky/engine/public/platform/Platform.h"

namespace blink {

RenderLayerScrollableArea::RenderLayerScrollableArea(RenderLayer& layer)
    : m_layer(layer)
    , m_scrollsOverflow(false)
    , m_scrollDimensionsDirty(true)
    , m_inOverflowRelayout(false)
    , m_nextTopmostScrollChild(0)
    , m_topmostScrollChild(0)
    , m_needsCompositedScrolling(false)
{
    ScrollableArea::setConstrainsScrollingToContentEdge(false);

    Node* node = box().node();
    if (node && node->isElementNode()) {
        // We save and restore only the scrollOffset as the other scroll values are recalculated.
        Element* element = toElement(node);
        m_scrollOffset = element->savedLayerScrollOffset();
        if (!m_scrollOffset.isZero())
            scrollAnimator()->setCurrentPosition(FloatPoint(m_scrollOffset.width(), m_scrollOffset.height()));
        element->setSavedLayerScrollOffset(IntSize());
    }
}

RenderLayerScrollableArea::~RenderLayerScrollableArea()
{
    if (!box().documentBeingDestroyed()) {
        Node* node = box().node();
        if (node && node->isElementNode())
            toElement(node)->setSavedLayerScrollOffset(m_scrollOffset);
    }

    destroyScrollbar(HorizontalScrollbar);
    destroyScrollbar(VerticalScrollbar);
}

HostWindow* RenderLayerScrollableArea::hostWindow() const
{
    if (Page* page = box().frame()->page())
        return &page->chrome();
    return nullptr;
}

void RenderLayerScrollableArea::invalidateScrollbarRect(Scrollbar* scrollbar, const IntRect& rect)
{
    // See crbug.com/343132.
    DisableCompositingQueryAsserts disabler;

    IntRect scrollRect = rect;
    // If we are not yet inserted into the tree, there is no need to issue paint invaldiations.
    if (!box().parent())
        return;

    if (scrollbar == m_vBar.get())
        scrollRect.move(verticalScrollbarStart(0, box().width()), box().borderTop());
    else
        scrollRect.move(horizontalScrollbarStart(0), box().height() - box().borderBottom() - scrollbar->height());

    if (scrollRect.isEmpty())
        return;

    IntRect intRect = pixelSnappedIntRect(scrollRect);

    if (box().frameView()->isInPerformLayout())
        addScrollbarDamage(scrollbar, intRect);
    else
        box().invalidatePaintRectangle(intRect);
}

bool RenderLayerScrollableArea::isActive() const
{
    Page* page = box().frame()->page();
    return page && page->focusController().isActive();
}

static int cornerStart(const RenderStyle* style, int minX, int maxX, int thickness)
{
    if (style->shouldPlaceBlockDirectionScrollbarOnLogicalLeft())
        return minX + style->borderLeftWidth();
    return maxX - thickness - style->borderRightWidth();
}

IntRect RenderLayerScrollableArea::scrollCornerRect() const
{
    // We have a scrollbar corner when a scrollbar is visible and not filling the entire length of the box.
    // This happens when both scrollbars are present.
    const Scrollbar* horizontalBar = horizontalScrollbar();
    const Scrollbar* verticalBar = verticalScrollbar();
    if (!horizontalBar || !verticalBar)
        return IntRect();

    const RenderStyle* style = box().style();
    int horizontalThickness = verticalBar->width();
    int verticalThickness = horizontalBar->height();
    const IntRect& bounds = box().pixelSnappedBorderBoxRect();
    return IntRect(cornerStart(style, bounds.x(), bounds.maxX(), horizontalThickness),
        bounds.maxY() - verticalThickness - style->borderBottomWidth(),
        horizontalThickness, verticalThickness);
}

IntRect RenderLayerScrollableArea::convertFromScrollbarToContainingView(const Scrollbar* scrollbar, const IntRect& scrollbarRect) const
{
    RenderView* view = box().view();
    if (!view)
        return scrollbarRect;

    IntRect rect = scrollbarRect;
    rect.move(scrollbarOffset(scrollbar));

    return view->frameView()->convertFromRenderer(box(), rect);
}

IntRect RenderLayerScrollableArea::convertFromContainingViewToScrollbar(const Scrollbar* scrollbar, const IntRect& parentRect) const
{
    RenderView* view = box().view();
    if (!view)
        return parentRect;

    IntRect rect = view->frameView()->convertToRenderer(box(), parentRect);
    rect.move(-scrollbarOffset(scrollbar));
    return rect;
}

IntPoint RenderLayerScrollableArea::convertFromScrollbarToContainingView(const Scrollbar* scrollbar, const IntPoint& scrollbarPoint) const
{
    RenderView* view = box().view();
    if (!view)
        return scrollbarPoint;

    IntPoint point = scrollbarPoint;
    point.move(scrollbarOffset(scrollbar));
    return view->frameView()->convertFromRenderer(box(), point);
}

IntPoint RenderLayerScrollableArea::convertFromContainingViewToScrollbar(const Scrollbar* scrollbar, const IntPoint& parentPoint) const
{
    RenderView* view = box().view();
    if (!view)
        return parentPoint;

    IntPoint point = view->frameView()->convertToRenderer(box(), parentPoint);

    point.move(-scrollbarOffset(scrollbar));
    return point;
}

int RenderLayerScrollableArea::scrollSize(ScrollbarOrientation orientation) const
{
    IntSize scrollDimensions = maximumScrollPosition() - minimumScrollPosition();
    return (orientation == HorizontalScrollbar) ? scrollDimensions.width() : scrollDimensions.height();
}

void RenderLayerScrollableArea::setScrollOffset(const IntPoint& newScrollOffset)
{
    // Ensure that the dimensions will be computed if they need to be (for overflow:hidden blocks).
    if (m_scrollDimensionsDirty)
        computeScrollDimensions();

    if (scrollOffset() == toIntSize(newScrollOffset))
        return;

    setScrollOffset(toIntSize(newScrollOffset));

    LocalFrame* frame = box().frame();
    ASSERT(frame);

    RefPtr<FrameView> frameView = box().frameView();

    TRACE_EVENT1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline"), "ScrollLayer", "data", InspectorScrollLayerEvent::data(&box()));

    const RenderLayerModelObject* paintInvalidationContainer = box().containerForPaintInvalidation();

    // Update the positions of our child layers (if needed as only fixed layers should be impacted by a scroll).
    // We don't update compositing layers, because we need to do a deep update from the compositing ancestor.
    if (!frameView->isInPerformLayout()) {
        // If we're in the middle of layout, we'll just update layers once layout has finished.
        layer()->clipper().clearClipRectsIncludingDescendants();
        box().setPreviousPaintInvalidationRect(box().boundsRectForPaintInvalidation(paintInvalidationContainer));
    }

    // The caret rect needs to be invalidated after scrolling
    frame->selection().setCaretRectNeedsUpdate();

    FloatQuad quadForFakeMouseMoveEvent = FloatQuad(layer()->renderer()->previousPaintInvalidationRect());

    quadForFakeMouseMoveEvent = paintInvalidationContainer->localToAbsoluteQuad(quadForFakeMouseMoveEvent);
    frame->eventHandler().dispatchFakeMouseMoveEventSoonInQuad(quadForFakeMouseMoveEvent);

    if (box().frameView()->isInPerformLayout())
        box().setShouldDoFullPaintInvalidation(true);
    else
        box().invalidatePaintUsingContainer(paintInvalidationContainer, layer()->renderer()->previousPaintInvalidationRect(), InvalidationScroll);

    // Schedule the scroll DOM event.
    if (box().node())
        box().node()->document().enqueueScrollEventForNode(box().node());
}

IntPoint RenderLayerScrollableArea::scrollPosition() const
{
    return IntPoint(m_scrollOffset);
}

IntPoint RenderLayerScrollableArea::minimumScrollPosition() const
{
    return -scrollOrigin();
}

IntPoint RenderLayerScrollableArea::maximumScrollPosition() const
{
    if (!box().hasOverflowClip())
        return -scrollOrigin();
    return -scrollOrigin() + IntPoint(pixelSnappedScrollWidth(), pixelSnappedScrollHeight()) - enclosingIntRect(box().clientBoxRect()).size();
}

IntRect RenderLayerScrollableArea::visibleContentRect(IncludeScrollbarsInRect scrollbarInclusion) const
{
    return IntRect(IntPoint(scrollXOffset(), scrollYOffset()),
        IntSize(max(0, layer()->size().width()), max(0, layer()->size().height())));
}

int RenderLayerScrollableArea::visibleHeight() const
{
    return layer()->size().height();
}

int RenderLayerScrollableArea::visibleWidth() const
{
    return layer()->size().width();
}

IntSize RenderLayerScrollableArea::contentsSize() const
{
    return IntSize(scrollWidth(), scrollHeight());
}

IntSize RenderLayerScrollableArea::overhangAmount() const
{
    return IntSize();
}

IntPoint RenderLayerScrollableArea::lastKnownMousePosition() const
{
    return box().frame() ? box().frame()->eventHandler().lastKnownMousePosition() : IntPoint();
}

IntRect RenderLayerScrollableArea::scrollableAreaBoundingBox() const
{
    return box().absoluteBoundingBoxRect();
}

bool RenderLayerScrollableArea::userInputScrollable(ScrollbarOrientation orientation) const
{
    EOverflow overflowStyle = (orientation == HorizontalScrollbar) ?
        box().style()->overflowX() : box().style()->overflowY();
    return (overflowStyle == OSCROLL || overflowStyle == OAUTO || overflowStyle == OOVERLAY);
}

bool RenderLayerScrollableArea::shouldPlaceVerticalScrollbarOnLeft() const
{
    return box().style()->shouldPlaceBlockDirectionScrollbarOnLogicalLeft();
}

int RenderLayerScrollableArea::pageStep(ScrollbarOrientation orientation) const
{
    int length = (orientation == HorizontalScrollbar) ?
        box().pixelSnappedClientWidth() : box().pixelSnappedClientHeight();
    int minPageStep = static_cast<float>(length) * ScrollableArea::minFractionToStepWhenPaging();
    int pageStep = max(minPageStep, length - ScrollableArea::maxOverlapBetweenPages());

    return max(pageStep, 1);
}

RenderBox& RenderLayerScrollableArea::box() const
{
    return *m_layer.renderBox();
}

RenderLayer* RenderLayerScrollableArea::layer() const
{
    return &m_layer;
}

LayoutUnit RenderLayerScrollableArea::scrollWidth() const
{
    if (m_scrollDimensionsDirty)
        const_cast<RenderLayerScrollableArea*>(this)->computeScrollDimensions();
    return m_overflowRect.width();
}

LayoutUnit RenderLayerScrollableArea::scrollHeight() const
{
    if (m_scrollDimensionsDirty)
        const_cast<RenderLayerScrollableArea*>(this)->computeScrollDimensions();
    return m_overflowRect.height();
}

int RenderLayerScrollableArea::pixelSnappedScrollWidth() const
{
    return snapSizeToPixel(scrollWidth(), box().clientLeft() + box().x());
}

int RenderLayerScrollableArea::pixelSnappedScrollHeight() const
{
    return snapSizeToPixel(scrollHeight(), box().clientTop() + box().y());
}

void RenderLayerScrollableArea::computeScrollDimensions()
{
    m_scrollDimensionsDirty = false;

    m_overflowRect = box().layoutOverflowRect();

    int scrollableLeftOverflow = m_overflowRect.x() - box().borderLeft();
    int scrollableTopOverflow = m_overflowRect.y() - box().borderTop();
    setScrollOrigin(IntPoint(-scrollableLeftOverflow, -scrollableTopOverflow));
}

void RenderLayerScrollableArea::scrollToOffset(const IntSize& scrollOffset, ScrollOffsetClamping clamp)
{
    IntSize newScrollOffset = clamp == ScrollOffsetClamped ? clampScrollOffset(scrollOffset) : scrollOffset;
    if (newScrollOffset != adjustedScrollOffset())
        scrollToOffsetWithoutAnimation(-scrollOrigin() + newScrollOffset);
}

void RenderLayerScrollableArea::updateAfterLayout()
{
    m_scrollDimensionsDirty = true;
    IntSize originalScrollOffset = adjustedScrollOffset();

    computeScrollDimensions();

    // Layout may cause us to be at an invalid scroll position. In this case we need
    // to pull our scroll offsets back to the max (or push them up to the min).
    IntSize clampedScrollOffset = clampScrollOffset(adjustedScrollOffset());
    if (clampedScrollOffset != adjustedScrollOffset())
        scrollToOffset(clampedScrollOffset);

    if (originalScrollOffset != adjustedScrollOffset())
        scrollToOffsetWithoutAnimation(-scrollOrigin() + adjustedScrollOffset());

    bool hasHorizontalOverflow = this->hasHorizontalOverflow();
    bool hasVerticalOverflow = this->hasVerticalOverflow();

    {
        // Hits in compositing/overflow/automatically-opt-into-composited-scrolling-after-style-change.html.
        DisableCompositingQueryAsserts disabler;

        // overflow:scroll should just enable/disable.
        if (box().style()->overflowX() == OSCROLL)
            horizontalScrollbar()->setEnabled(hasHorizontalOverflow);
        if (box().style()->overflowY() == OSCROLL)
            verticalScrollbar()->setEnabled(hasVerticalOverflow);
    }

    // overflow:auto may need to lay out again if scrollbars got added/removed.
    bool autoHorizontalScrollBarChanged = box().hasAutoHorizontalScrollbar() && (hasHorizontalScrollbar() != hasHorizontalOverflow);
    bool autoVerticalScrollBarChanged = box().hasAutoVerticalScrollbar() && (hasVerticalScrollbar() != hasVerticalOverflow);

    if (autoHorizontalScrollBarChanged || autoVerticalScrollBarChanged) {
        if (box().hasAutoHorizontalScrollbar())
            setHasHorizontalScrollbar(hasHorizontalOverflow);
        if (box().hasAutoVerticalScrollbar())
            setHasVerticalScrollbar(hasVerticalOverflow);

        layer()->updateSelfPaintingLayer();

        if (box().style()->overflowX() == OAUTO || box().style()->overflowY() == OAUTO) {
            if (!m_inOverflowRelayout) {
                // Our proprietary overflow: overlay value doesn't trigger a layout.
                m_inOverflowRelayout = true;
                SubtreeLayoutScope layoutScope(box());
                layoutScope.setNeedsLayout(&box());
                if (box().isRenderBlock()) {
                    RenderBlock& block = toRenderBlock(box());
                    block.scrollbarsChanged(autoHorizontalScrollBarChanged, autoVerticalScrollBarChanged);
                    block.layoutBlock(true);
                } else {
                    box().layout();
                }
                m_inOverflowRelayout = false;
            }
        }
    }

    {
        // Hits in compositing/overflow/automatically-opt-into-composited-scrolling-after-style-change.html.
        DisableCompositingQueryAsserts disabler;

        // Set up the range (and page step/line step).
        if (Scrollbar* horizontalScrollbar = this->horizontalScrollbar()) {
            int clientWidth = box().pixelSnappedClientWidth();
            horizontalScrollbar->setProportion(clientWidth, overflowRect().width());
        }
        if (Scrollbar* verticalScrollbar = this->verticalScrollbar()) {
            int clientHeight = box().pixelSnappedClientHeight();
            verticalScrollbar->setProportion(clientHeight, overflowRect().height());
        }
    }

    bool hasOverflow = hasScrollableHorizontalOverflow() || hasScrollableVerticalOverflow();
    updateScrollableAreaSet(hasOverflow);

    if (hasOverflow) {
        DisableCompositingQueryAsserts disabler;
        positionOverflowControls(IntSize());
    }
}

bool RenderLayerScrollableArea::hasHorizontalOverflow() const
{
    ASSERT(!m_scrollDimensionsDirty);

    return pixelSnappedScrollWidth() > box().pixelSnappedClientWidth();
}

bool RenderLayerScrollableArea::hasVerticalOverflow() const
{
    ASSERT(!m_scrollDimensionsDirty);

    return pixelSnappedScrollHeight() > box().pixelSnappedClientHeight();
}

bool RenderLayerScrollableArea::hasScrollableHorizontalOverflow() const
{
    return hasHorizontalOverflow() && box().scrollsOverflowX();
}

bool RenderLayerScrollableArea::hasScrollableVerticalOverflow() const
{
    return hasVerticalOverflow() && box().scrollsOverflowY();
}

static bool overflowRequiresScrollbar(EOverflow overflow)
{
    return overflow == OSCROLL;
}

static bool overflowDefinesAutomaticScrollbar(EOverflow overflow)
{
    return overflow == OAUTO || overflow == OOVERLAY;
}

// This function returns true if the given box requires overflow scrollbars (as
// opposed to the 'viewport' scrollbars managed by the RenderLayerCompositor).
// FIXME: we should use the same scrolling machinery for both the viewport and
// overflow. Currently, we need to avoid producing scrollbars here if they'll be
// handled externally in the RLC.
static bool canHaveOverflowScrollbars(const RenderBox& box)
{
    return !box.isRenderView() && box.document().viewportDefiningElement() != box.node();
}

void RenderLayerScrollableArea::updateAfterStyleChange(const RenderStyle* oldStyle)
{
    if (!canHaveOverflowScrollbars(box()))
        return;

    if (!m_scrollDimensionsDirty)
        updateScrollableAreaSet(hasScrollableHorizontalOverflow() || hasScrollableVerticalOverflow());

    EOverflow overflowX = box().style()->overflowX();
    EOverflow overflowY = box().style()->overflowY();

    // To avoid doing a relayout in updateScrollbarsAfterLayout, we try to keep any automatic scrollbar that was already present.
    bool needsHorizontalScrollbar = (hasHorizontalScrollbar() && overflowDefinesAutomaticScrollbar(overflowX)) || overflowRequiresScrollbar(overflowX);
    bool needsVerticalScrollbar = (hasVerticalScrollbar() && overflowDefinesAutomaticScrollbar(overflowY)) || overflowRequiresScrollbar(overflowY);
    setHasHorizontalScrollbar(needsHorizontalScrollbar);
    setHasVerticalScrollbar(needsVerticalScrollbar);

    // With overflow: scroll, scrollbars are always visible but may be disabled.
    // When switching to another value, we need to re-enable them (see bug 11985).
    if (needsHorizontalScrollbar && oldStyle && oldStyle->overflowX() == OSCROLL && overflowX != OSCROLL) {
        ASSERT(hasHorizontalScrollbar());
        m_hBar->setEnabled(true);
    }

    if (needsVerticalScrollbar && oldStyle && oldStyle->overflowY() == OSCROLL && overflowY != OSCROLL) {
        ASSERT(hasVerticalScrollbar());
        m_vBar->setEnabled(true);
    }
}

bool RenderLayerScrollableArea::updateAfterCompositingChange()
{
    const bool layersChanged = m_topmostScrollChild != m_nextTopmostScrollChild;
    m_topmostScrollChild = m_nextTopmostScrollChild;
    m_nextTopmostScrollChild = nullptr;
    return layersChanged;
}

void RenderLayerScrollableArea::updateAfterOverflowRecalc()
{
    computeScrollDimensions();
    if (Scrollbar* horizontalScrollbar = this->horizontalScrollbar()) {
        int clientWidth = box().pixelSnappedClientWidth();
        horizontalScrollbar->setProportion(clientWidth, overflowRect().width());
    }
    if (Scrollbar* verticalScrollbar = this->verticalScrollbar()) {
        int clientHeight = box().pixelSnappedClientHeight();
        verticalScrollbar->setProportion(clientHeight, overflowRect().height());
    }

    bool hasHorizontalOverflow = this->hasHorizontalOverflow();
    bool hasVerticalOverflow = this->hasVerticalOverflow();
    bool autoHorizontalScrollBarChanged = box().hasAutoHorizontalScrollbar() && (hasHorizontalScrollbar() != hasHorizontalOverflow);
    bool autoVerticalScrollBarChanged = box().hasAutoVerticalScrollbar() && (hasVerticalScrollbar() != hasVerticalOverflow);
    if (autoHorizontalScrollBarChanged || autoVerticalScrollBarChanged)
        box().setNeedsLayoutAndFullPaintInvalidation();
}

IntSize RenderLayerScrollableArea::clampScrollOffset(const IntSize& scrollOffset) const
{
    int maxX = scrollWidth() - box().pixelSnappedClientWidth();
    int maxY = scrollHeight() - box().pixelSnappedClientHeight();

    int x = std::max(std::min(scrollOffset.width(), maxX), 0);
    int y = std::max(std::min(scrollOffset.height(), maxY), 0);
    return IntSize(x, y);
}

IntRect RenderLayerScrollableArea::rectForHorizontalScrollbar(const IntRect& borderBoxRect) const
{
    if (!m_hBar)
        return IntRect();

    const IntRect& scrollCorner = scrollCornerRect();

    return IntRect(horizontalScrollbarStart(borderBoxRect.x()),
        borderBoxRect.maxY() - box().borderBottom() - m_hBar->height(),
        borderBoxRect.width() - (box().borderLeft() + box().borderRight()) - scrollCorner.width(),
        m_hBar->height());
}

IntRect RenderLayerScrollableArea::rectForVerticalScrollbar(const IntRect& borderBoxRect) const
{
    if (!m_vBar)
        return IntRect();

    const IntRect& scrollCorner = scrollCornerRect();

    return IntRect(verticalScrollbarStart(borderBoxRect.x(), borderBoxRect.maxX()),
        borderBoxRect.y() + box().borderTop(),
        m_vBar->width(),
        borderBoxRect.height() - (box().borderTop() + box().borderBottom()) - scrollCorner.height());
}

LayoutUnit RenderLayerScrollableArea::verticalScrollbarStart(int minX, int maxX) const
{
    if (box().style()->shouldPlaceBlockDirectionScrollbarOnLogicalLeft())
        return minX + box().borderLeft();
    return maxX - box().borderRight() - m_vBar->width();
}

LayoutUnit RenderLayerScrollableArea::horizontalScrollbarStart(int minX) const
{
    return minX + box().borderLeft();
}

IntSize RenderLayerScrollableArea::scrollbarOffset(const Scrollbar* scrollbar) const
{
    if (scrollbar == m_vBar.get())
        return IntSize(verticalScrollbarStart(0, box().width()), box().borderTop());

    if (scrollbar == m_hBar.get())
        return IntSize(horizontalScrollbarStart(0), box().height() - box().borderBottom() - scrollbar->height());

    ASSERT_NOT_REACHED();
    return IntSize();
}

PassRefPtr<Scrollbar> RenderLayerScrollableArea::createScrollbar(ScrollbarOrientation orientation)
{
    RefPtr<Scrollbar> widget = Scrollbar::create(this, orientation);
    if (orientation == HorizontalScrollbar)
        didAddScrollbar(widget.get(), HorizontalScrollbar);
    else
        didAddScrollbar(widget.get(), VerticalScrollbar);
    return widget.release();
}

void RenderLayerScrollableArea::destroyScrollbar(ScrollbarOrientation orientation)
{
    RefPtr<Scrollbar>& scrollbar = orientation == HorizontalScrollbar ? m_hBar : m_vBar;
    if (!scrollbar)
        return;

    willRemoveScrollbar(scrollbar.get(), orientation);

    scrollbar->disconnectFromScrollableArea();
    scrollbar = nullptr;
}

void RenderLayerScrollableArea::setHasHorizontalScrollbar(bool hasScrollbar)
{
    if (hasScrollbar == hasHorizontalScrollbar())
        return;

    if (hasScrollbar) {
        // This doesn't hit in any tests, but since the equivalent code in setHasVerticalScrollbar
        // does, presumably this code does as well.
        DisableCompositingQueryAsserts disabler;
        m_hBar = createScrollbar(HorizontalScrollbar);
    } else {
        destroyScrollbar(HorizontalScrollbar);
    }
}

void RenderLayerScrollableArea::setHasVerticalScrollbar(bool hasScrollbar)
{
    if (hasScrollbar == hasVerticalScrollbar())
        return;

    if (hasScrollbar) {
        // Hits in compositing/overflow/automatically-opt-into-composited-scrolling-after-style-change.html
        DisableCompositingQueryAsserts disabler;
        m_vBar = createScrollbar(VerticalScrollbar);
    } else {
        destroyScrollbar(VerticalScrollbar);
    }
}

void RenderLayerScrollableArea::positionOverflowControls(const IntSize& offsetFromRoot)
{
    if (!hasScrollbar())
        return;

    const IntRect borderBox = box().pixelSnappedBorderBoxRect();
    if (Scrollbar* verticalScrollbar = this->verticalScrollbar()) {
        IntRect vBarRect = rectForVerticalScrollbar(borderBox);
        vBarRect.move(offsetFromRoot);
        verticalScrollbar->setFrameRect(vBarRect);
    }

    if (Scrollbar* horizontalScrollbar = this->horizontalScrollbar()) {
        IntRect hBarRect = rectForHorizontalScrollbar(borderBox);
        hBarRect.move(offsetFromRoot);
        horizontalScrollbar->setFrameRect(hBarRect);
    }
}

void RenderLayerScrollableArea::paintOverflowControls(GraphicsContext* context, const IntPoint& paintOffset, const IntRect& damageRect, bool paintingOverlayControls)
{
    // Don't do anything if we have no overflow.
    if (!box().hasOverflowClip())
        return;

    IntPoint adjustedPaintOffset = paintOffset;
    if (paintingOverlayControls)
        adjustedPaintOffset = m_cachedOverlayScrollbarOffset;

    // Move the scrollbar widgets if necessary. We normally move and resize widgets during layout,
    // but sometimes widgets can move without layout occurring (most notably when you scroll a
    // document that contains fixed positioned elements).
    positionOverflowControls(toIntSize(adjustedPaintOffset));

    // Overlay scrollbars paint in a second pass through the layer tree so that they will paint
    // on top of everything else. If this is the normal painting pass, paintingOverlayControls
    // will be false, and we should just tell the root layer that there are overlay scrollbars
    // that need to be painted. That will cause the second pass through the layer tree to run,
    // and we'll paint the scrollbars then. In the meantime, cache tx and ty so that the
    // second pass doesn't need to re-enter the RenderTree to get it right.
    if (hasOverlayScrollbars() && !paintingOverlayControls) {
        m_cachedOverlayScrollbarOffset = paintOffset;
        IntRect localDamgeRect = damageRect;
        localDamgeRect.moveBy(-paintOffset);
        if (!overflowControlsIntersectRect(localDamgeRect))
            return;

        RenderView* renderView = box().view();

        RenderLayer* paintingRoot = layer()->enclosingLayerWithCompositedLayerMapping(IncludeSelf);
        if (!paintingRoot)
            paintingRoot = renderView->layer();

        paintingRoot->setContainsDirtyOverlayScrollbars(true);
        return;
    }

    // This check is required to avoid painting custom CSS scrollbars twice.
    if (paintingOverlayControls && !hasOverlayScrollbars())
        return;

    // Now that we're sure the scrollbars are in the right place, paint them.
    if (m_hBar)
        m_hBar->paint(context, damageRect);
    if (m_vBar)
        m_vBar->paint(context, damageRect);
}

bool RenderLayerScrollableArea::overflowControlsIntersectRect(const IntRect& localRect) const
{
    const IntRect borderBox = box().pixelSnappedBorderBoxRect();

    if (rectForHorizontalScrollbar(borderBox).intersects(localRect))
        return true;

    if (rectForVerticalScrollbar(borderBox).intersects(localRect))
        return true;

    return false;
}

LayoutRect RenderLayerScrollableArea::exposeRect(const LayoutRect& rect, const ScrollAlignment& alignX, const ScrollAlignment& alignY)
{
    LayoutRect localExposeRect(box().absoluteToLocalQuad(FloatQuad(FloatRect(rect)), UseTransforms).boundingBox());
    LayoutRect layerBounds(0, 0, box().clientWidth(), box().clientHeight());
    LayoutRect r = ScrollAlignment::getRectToExpose(layerBounds, localExposeRect, alignX, alignY);

    IntSize clampedScrollOffset = clampScrollOffset(adjustedScrollOffset() + toIntSize(roundedIntRect(r).location()));
    if (clampedScrollOffset == adjustedScrollOffset())
        return rect;

    IntSize oldScrollOffset = adjustedScrollOffset();
    scrollToOffset(clampedScrollOffset);
    IntSize scrollOffsetDifference = adjustedScrollOffset() - oldScrollOffset;
    localExposeRect.move(-scrollOffsetDifference);
    return LayoutRect(box().localToAbsoluteQuad(FloatQuad(FloatRect(localExposeRect)), UseTransforms).boundingBox());
}

void RenderLayerScrollableArea::updateScrollableAreaSet(bool hasOverflow)
{
    LocalFrame* frame = box().frame();
    if (!frame)
        return;

    FrameView* frameView = frame->view();
    if (!frameView)
        return;

    // FIXME: Does this need to be fixed later for OOPI?
    bool isVisibleToHitTest = box().visibleToHitTesting();
    bool didScrollOverflow = m_scrollsOverflow;

    m_scrollsOverflow = hasOverflow && isVisibleToHitTest;
    if (didScrollOverflow == scrollsOverflow())
        return;

    if (m_scrollsOverflow)
        frameView->addScrollableArea(this);
    else
        frameView->removeScrollableArea(this);
}

void RenderLayerScrollableArea::setTopmostScrollChild(RenderLayer* scrollChild)
{
    // We only want to track the topmost scroll child for scrollable areas with
    // overlay scrollbars.
    if (!hasOverlayScrollbars())
        return;
    m_nextTopmostScrollChild = scrollChild;
}

} // namespace blink
