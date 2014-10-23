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

#include "config.h"
#include "core/rendering/RenderLayer.h"

#include "core/dom/Node.h"
#include "core/dom/shadow/ShadowRoot.h"
#include "core/editing/FrameSelection.h"
#include "core/frame/FrameView.h"
#include "core/frame/LocalFrame.h"
#include "core/inspector/InspectorTraceEvents.h"
#include "core/page/Chrome.h"
#include "core/page/EventHandler.h"
#include "core/page/FocusController.h"
#include "core/page/Page.h"
#include "core/page/scrolling/ScrollingCoordinator.h"
#include "core/rendering/HitTestResult.h"
#include "core/rendering/RenderGeometryMap.h"
#include "core/rendering/RenderView.h"
#include "core/rendering/compositing/CompositedLayerMapping.h"
#include "core/rendering/compositing/RenderLayerCompositor.h"
#include "platform/PlatformGestureEvent.h"
#include "platform/PlatformMouseEvent.h"
#include "platform/graphics/GraphicsContextStateSaver.h"
#include "platform/graphics/GraphicsLayer.h"
#include "platform/scroll/ScrollAnimator.h"
#include "platform/scroll/Scrollbar.h"
#include "public/platform/Platform.h"

namespace blink {

const int ResizerControlExpandRatioForTouch = 2;

RenderLayerScrollableArea::RenderLayerScrollableArea(RenderLayer& layer)
    : m_layer(layer)
    , m_inResizeMode(false)
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

    updateResizerAreaSet();
}

RenderLayerScrollableArea::~RenderLayerScrollableArea()
{
    if (inResizeMode() && !box().documentBeingDestroyed()) {
        if (LocalFrame* frame = box().frame())
            frame->eventHandler().resizeScrollableAreaDestroyed();
    }

    if (LocalFrame* frame = box().frame()) {
        if (FrameView* frameView = frame->view()) {
            frameView->removeScrollableArea(this);
        }
    }

    if (box().frame() && box().frame()->page()) {
        if (ScrollingCoordinator* scrollingCoordinator = box().frame()->page()->scrollingCoordinator())
            scrollingCoordinator->willDestroyScrollableArea(this);
    }

    if (!box().documentBeingDestroyed()) {
        Node* node = box().node();
        if (node && node->isElementNode())
            toElement(node)->setSavedLayerScrollOffset(m_scrollOffset);
    }

    if (LocalFrame* frame = box().frame()) {
        if (FrameView* frameView = frame->view())
            frameView->removeResizerArea(box());
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

GraphicsLayer* RenderLayerScrollableArea::layerForScrolling() const
{
    return layer()->hasCompositedLayerMapping() ? layer()->compositedLayerMapping()->scrollingContentsLayer() : 0;
}

GraphicsLayer* RenderLayerScrollableArea::layerForHorizontalScrollbar() const
{
    // See crbug.com/343132.
    DisableCompositingQueryAsserts disabler;

    return layer()->hasCompositedLayerMapping() ? layer()->compositedLayerMapping()->layerForHorizontalScrollbar() : 0;
}

GraphicsLayer* RenderLayerScrollableArea::layerForVerticalScrollbar() const
{
    // See crbug.com/343132.
    DisableCompositingQueryAsserts disabler;

    return layer()->hasCompositedLayerMapping() ? layer()->compositedLayerMapping()->layerForVerticalScrollbar() : 0;
}

GraphicsLayer* RenderLayerScrollableArea::layerForScrollCorner() const
{
    // See crbug.com/343132.
    DisableCompositingQueryAsserts disabler;

    return layer()->hasCompositedLayerMapping() ? layer()->compositedLayerMapping()->layerForScrollCorner() : 0;
}

void RenderLayerScrollableArea::invalidateScrollbarRect(Scrollbar* scrollbar, const IntRect& rect)
{
    // See crbug.com/343132.
    DisableCompositingQueryAsserts disabler;

    if (scrollbar == m_vBar.get()) {
        if (GraphicsLayer* layer = layerForVerticalScrollbar()) {
            layer->setNeedsDisplayInRect(rect);
            return;
        }
    } else {
        if (GraphicsLayer* layer = layerForHorizontalScrollbar()) {
            layer->setNeedsDisplayInRect(rect);
            return;
        }
    }

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

    LayoutRect paintInvalidationRect = scrollRect;
    box().flipForWritingMode(paintInvalidationRect);

    IntRect intRect = pixelSnappedIntRect(paintInvalidationRect);

    if (box().frameView()->isInPerformLayout())
        addScrollbarDamage(scrollbar, intRect);
    else
        box().invalidatePaintRectangle(intRect);
}

void RenderLayerScrollableArea::invalidateScrollCornerRect(const IntRect& rect)
{
    if (GraphicsLayer* layer = layerForScrollCorner()) {
        layer->setNeedsDisplayInRect(rect);
        return;
    }
}

bool RenderLayerScrollableArea::isActive() const
{
    Page* page = box().frame()->page();
    return page && page->focusController().isActive();
}

bool RenderLayerScrollableArea::isScrollCornerVisible() const
{
    return !scrollCornerRect().isEmpty();
}

static int cornerStart(const RenderStyle* style, int minX, int maxX, int thickness)
{
    if (style->shouldPlaceBlockDirectionScrollbarOnLogicalLeft())
        return minX + style->borderLeftWidth();
    return maxX - thickness - style->borderRightWidth();
}

static IntRect cornerRect(const RenderStyle* style, const Scrollbar* horizontalScrollbar, const Scrollbar* verticalScrollbar, const IntRect& bounds)
{
    int horizontalThickness;
    int verticalThickness;
    if (!verticalScrollbar && !horizontalScrollbar) {
        // FIXME: This isn't right. We need to know the thickness of custom scrollbars
        // even when they don't exist in order to set the resizer square size properly.
        horizontalThickness = Scrollbar::scrollbarThickness();
        verticalThickness = horizontalThickness;
    } else if (verticalScrollbar && !horizontalScrollbar) {
        horizontalThickness = verticalScrollbar->width();
        verticalThickness = horizontalThickness;
    } else if (horizontalScrollbar && !verticalScrollbar) {
        verticalThickness = horizontalScrollbar->height();
        horizontalThickness = verticalThickness;
    } else {
        horizontalThickness = verticalScrollbar->width();
        verticalThickness = horizontalScrollbar->height();
    }
    return IntRect(cornerStart(style, bounds.x(), bounds.maxX(), horizontalThickness),
        bounds.maxY() - verticalThickness - style->borderBottomWidth(),
        horizontalThickness, verticalThickness);
}

IntRect RenderLayerScrollableArea::scrollCornerRect() const
{
    // We have a scrollbar corner when a scrollbar is visible and not filling the entire length of the box.
    // This happens when:
    // (a) A resizer is present and at least one scrollbar is present
    // (b) Both scrollbars are present.
    bool hasHorizontalBar = horizontalScrollbar();
    bool hasVerticalBar = verticalScrollbar();
    bool hasResizer = box().style()->resize() != RESIZE_NONE;
    if ((hasHorizontalBar && hasVerticalBar) || (hasResizer && (hasHorizontalBar || hasVerticalBar)))
        return cornerRect(box().style(), horizontalScrollbar(), verticalScrollbar(), box().pixelSnappedBorderBoxRect());
    return IntRect();
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
        // Update regions, scrolling may change the clip of a particular region.
        frameView->setNeedsUpdateWidgetPositions();
        updateCompositingLayersAfterScroll();
    }

    // The caret rect needs to be invalidated after scrolling
    frame->selection().setCaretRectNeedsUpdate();

    FloatQuad quadForFakeMouseMoveEvent = FloatQuad(layer()->renderer()->previousPaintInvalidationRect());

    quadForFakeMouseMoveEvent = paintInvalidationContainer->localToAbsoluteQuad(quadForFakeMouseMoveEvent);
    frame->eventHandler().dispatchFakeMouseMoveEventSoonInQuad(quadForFakeMouseMoveEvent);

    bool requiresPaintInvalidation = true;

    if (box().view()->compositor()->inCompositingMode()) {
        // Hits in virtual/gpu/fast/canvas/canvas-scroll-path-into-view.html.
        DisableCompositingQueryAsserts disabler;
        bool onlyScrolledCompositedLayers = scrollsOverflow()
            && !layer()->hasVisibleNonLayerContent()
            && !layer()->hasNonCompositedChild()
            && !layer()->hasBlockSelectionGapBounds()
            && box().style()->backgroundLayers().attachment() != LocalBackgroundAttachment;

        if (usesCompositedScrolling() || onlyScrolledCompositedLayers)
            requiresPaintInvalidation = false;
    }

    // Just schedule a full paint invalidation of our object.
    if (requiresPaintInvalidation) {
        // For querying RenderLayer::compositingState()
        // This code appears correct, since scrolling outside of layout happens during activities that do not dirty compositing state.
        DisableCompositingQueryAsserts disabler;
        if (box().frameView()->isInPerformLayout())
            box().setShouldDoFullPaintInvalidation(true);
        else
            box().invalidatePaintUsingContainer(paintInvalidationContainer, layer()->renderer()->previousPaintInvalidationRect(), InvalidationScroll);
    }

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
    int verticalScrollbarWidth = 0;
    int horizontalScrollbarHeight = 0;
    if (scrollbarInclusion == IncludeScrollbars) {
        verticalScrollbarWidth = (verticalScrollbar() && !verticalScrollbar()->isOverlayScrollbar()) ? verticalScrollbar()->width() : 0;
        horizontalScrollbarHeight = (horizontalScrollbar() && !horizontalScrollbar()->isOverlayScrollbar()) ? horizontalScrollbar()->height() : 0;
    }

    return IntRect(IntPoint(scrollXOffset(), scrollYOffset()),
        IntSize(max(0, layer()->size().width() - verticalScrollbarWidth), max(0, layer()->size().height() - horizontalScrollbarHeight)));
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

bool RenderLayerScrollableArea::scrollbarsCanBeActive() const
{
    RenderView* view = box().view();
    if (!view)
        return false;
    return view->frameView()->scrollbarsCanBeActive();
}

IntRect RenderLayerScrollableArea::scrollableAreaBoundingBox() const
{
    return box().absoluteBoundingBoxRect();
}

bool RenderLayerScrollableArea::userInputScrollable(ScrollbarOrientation orientation) const
{
    if (box().isIntristicallyScrollable(orientation))
        return true;

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
    box().flipForWritingMode(m_overflowRect);

    int scrollableLeftOverflow = m_overflowRect.x() - box().borderLeft() - (box().style()->shouldPlaceBlockDirectionScrollbarOnLogicalLeft() ? box().verticalScrollbarWidth() : 0);
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

    // FIXME: Need to detect a swap from custom to native scrollbars (and vice versa).
    if (m_hBar)
        m_hBar->styleChanged();
    if (m_vBar)
        m_vBar->styleChanged();

    updateResizerAreaSet();
}

bool RenderLayerScrollableArea::updateAfterCompositingChange()
{
    layer()->updateScrollingStateAfterCompositingChange();
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
    int x = minX + box().borderLeft();
    if (box().style()->shouldPlaceBlockDirectionScrollbarOnLogicalLeft())
        x += m_vBar ? m_vBar->width() : resizerCornerRect(box().pixelSnappedBorderBoxRect(), ResizerForPointer).width();
    return x;
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
    box().document().view()->addChild(widget.get());
    return widget.release();
}

void RenderLayerScrollableArea::destroyScrollbar(ScrollbarOrientation orientation)
{
    RefPtr<Scrollbar>& scrollbar = orientation == HorizontalScrollbar ? m_hBar : m_vBar;
    if (!scrollbar)
        return;

    if (!scrollbar->isCustomScrollbar())
        willRemoveScrollbar(scrollbar.get(), orientation);

    scrollbar->removeFromParent();
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

    // Destroying or creating one bar can cause our scrollbar corner to come and go. We need to update the opposite scrollbar's style.
    if (m_hBar)
        m_hBar->styleChanged();
    if (m_vBar)
        m_vBar->styleChanged();
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

    // Destroying or creating one bar can cause our scrollbar corner to come and go. We need to update the opposite scrollbar's style.
    if (m_hBar)
        m_hBar->styleChanged();
    if (m_vBar)
        m_vBar->styleChanged();
}

int RenderLayerScrollableArea::verticalScrollbarWidth(OverlayScrollbarSizeRelevancy relevancy) const
{
    if (!m_vBar || (m_vBar->isOverlayScrollbar() && (relevancy == IgnoreOverlayScrollbarSize || !m_vBar->shouldParticipateInHitTesting())))
        return 0;
    return m_vBar->width();
}

int RenderLayerScrollableArea::horizontalScrollbarHeight(OverlayScrollbarSizeRelevancy relevancy) const
{
    if (!m_hBar || (m_hBar->isOverlayScrollbar() && (relevancy == IgnoreOverlayScrollbarSize || !m_hBar->shouldParticipateInHitTesting())))
        return 0;
    return m_hBar->height();
}

void RenderLayerScrollableArea::positionOverflowControls(const IntSize& offsetFromRoot)
{
    if (!hasScrollbar() && !box().canResize())
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

    // FIXME, this should eventually be removed, once we are certain that composited
    // controls get correctly positioned on a compositor update. For now, conservatively
    // leaving this unchanged.
    if (layer()->hasCompositedLayerMapping())
        layer()->compositedLayerMapping()->positionOverflowControlsLayers(offsetFromRoot);
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
        // It's not necessary to do the second pass if the scrollbars paint into layers.
        if ((m_hBar && layerForHorizontalScrollbar()) || (m_vBar && layerForVerticalScrollbar()))
            return;
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
    if (m_hBar && !layerForHorizontalScrollbar())
        m_hBar->paint(context, damageRect);
    if (m_vBar && !layerForVerticalScrollbar())
        m_vBar->paint(context, damageRect);

    if (layerForScrollCorner())
        return;

    // We fill our scroll corner with white if we have a scrollbar that doesn't run all the way up to the
    // edge of the box.
    paintScrollCorner(context, adjustedPaintOffset, damageRect);

    // Paint our resizer last, since it sits on top of the scroll corner.
    paintResizer(context, adjustedPaintOffset, damageRect);
}

void RenderLayerScrollableArea::paintScrollCorner(GraphicsContext* context, const IntPoint& paintOffset, const IntRect& damageRect)
{
    IntRect absRect = scrollCornerRect();
    absRect.moveBy(paintOffset);
    if (!absRect.intersects(damageRect))
        return;

    // We don't want to paint white if we have overlay scrollbars, since we need
    // to see what is behind it.
    if (!hasOverlayScrollbars())
        context->fillRect(absRect, Color::white);
}

bool RenderLayerScrollableArea::hitTestOverflowControls(HitTestResult& result, const IntPoint& localPoint)
{
    if (!hasScrollbar() && !box().canResize())
        return false;

    IntRect resizeControlRect;
    if (box().style()->resize() != RESIZE_NONE) {
        resizeControlRect = resizerCornerRect(box().pixelSnappedBorderBoxRect(), ResizerForPointer);
        if (resizeControlRect.contains(localPoint))
            return true;
    }

    int resizeControlSize = max(resizeControlRect.height(), 0);
    if (m_vBar && m_vBar->shouldParticipateInHitTesting()) {
        LayoutRect vBarRect(verticalScrollbarStart(0, box().width()),
            box().borderTop(),
            m_vBar->width(),
            box().height() - (box().borderTop() + box().borderBottom()) - (m_hBar ? m_hBar->height() : resizeControlSize));
        if (vBarRect.contains(localPoint)) {
            result.setScrollbar(m_vBar.get());
            return true;
        }
    }

    resizeControlSize = max(resizeControlRect.width(), 0);
    if (m_hBar && m_hBar->shouldParticipateInHitTesting()) {
        LayoutRect hBarRect(horizontalScrollbarStart(0),
            box().height() - box().borderBottom() - m_hBar->height(),
            box().width() - (box().borderLeft() + box().borderRight()) - (m_vBar ? m_vBar->width() : resizeControlSize),
            m_hBar->height());
        if (hBarRect.contains(localPoint)) {
            result.setScrollbar(m_hBar.get());
            return true;
        }
    }

    return false;
}

IntRect RenderLayerScrollableArea::resizerCornerRect(const IntRect& bounds, ResizerHitTestType resizerHitTestType) const
{
    if (box().style()->resize() == RESIZE_NONE)
        return IntRect();
    IntRect corner = cornerRect(box().style(), horizontalScrollbar(), verticalScrollbar(), bounds);

    if (resizerHitTestType == ResizerForTouch) {
        // We make the resizer virtually larger for touch hit testing. With the
        // expanding ratio k = ResizerControlExpandRatioForTouch, we first move
        // the resizer rect (of width w & height h), by (-w * (k-1), -h * (k-1)),
        // then expand the rect by new_w/h = w/h * k.
        int expandRatio = ResizerControlExpandRatioForTouch - 1;
        corner.move(-corner.width() * expandRatio, -corner.height() * expandRatio);
        corner.expand(corner.width() * expandRatio, corner.height() * expandRatio);
    }

    return corner;
}

IntRect RenderLayerScrollableArea::scrollCornerAndResizerRect() const
{
    IntRect scrollCornerAndResizer = scrollCornerRect();
    if (scrollCornerAndResizer.isEmpty())
        scrollCornerAndResizer = resizerCornerRect(box().pixelSnappedBorderBoxRect(), ResizerForPointer);
    return scrollCornerAndResizer;
}

bool RenderLayerScrollableArea::overflowControlsIntersectRect(const IntRect& localRect) const
{
    const IntRect borderBox = box().pixelSnappedBorderBoxRect();

    if (rectForHorizontalScrollbar(borderBox).intersects(localRect))
        return true;

    if (rectForVerticalScrollbar(borderBox).intersects(localRect))
        return true;

    if (scrollCornerRect().intersects(localRect))
        return true;

    if (resizerCornerRect(borderBox, ResizerForPointer).intersects(localRect))
        return true;

    return false;
}

void RenderLayerScrollableArea::paintResizer(GraphicsContext* context, const IntPoint& paintOffset, const IntRect& damageRect)
{
    if (box().style()->resize() == RESIZE_NONE)
        return;

    IntRect absRect = resizerCornerRect(box().pixelSnappedBorderBoxRect(), ResizerForPointer);
    absRect.moveBy(paintOffset);
    if (!absRect.intersects(damageRect))
        return;

    drawPlatformResizerImage(context, absRect);

    // Draw a frame around the resizer (1px grey line) if there are any scrollbars present.
    // Clipping will exclude the right and bottom edges of this frame.
    if (!hasOverlayScrollbars() && hasScrollbar()) {
        GraphicsContextStateSaver stateSaver(*context);
        context->clip(absRect);
        IntRect largerCorner = absRect;
        largerCorner.setSize(IntSize(largerCorner.width() + 1, largerCorner.height() + 1));
        context->setStrokeColor(Color(217, 217, 217));
        context->setStrokeThickness(1.0f);
        context->setFillColor(Color::transparent);
        context->drawRect(largerCorner);
    }
}

bool RenderLayerScrollableArea::isPointInResizeControl(const IntPoint& absolutePoint, ResizerHitTestType resizerHitTestType) const
{
    if (!box().canResize())
        return false;

    IntPoint localPoint = roundedIntPoint(box().absoluteToLocal(absolutePoint, UseTransforms));
    IntRect localBounds(0, 0, box().pixelSnappedWidth(), box().pixelSnappedHeight());
    return resizerCornerRect(localBounds, resizerHitTestType).contains(localPoint);
}

bool RenderLayerScrollableArea::hitTestResizerInFragments(const LayerFragments& layerFragments, const HitTestLocation& hitTestLocation) const
{
    if (!box().canResize())
        return false;

    if (layerFragments.isEmpty())
        return false;

    for (int i = layerFragments.size() - 1; i >= 0; --i) {
        const LayerFragment& fragment = layerFragments.at(i);
        if (fragment.backgroundRect.intersects(hitTestLocation) && resizerCornerRect(pixelSnappedIntRect(fragment.layerBounds), ResizerForPointer).contains(hitTestLocation.roundedPoint()))
            return true;
    }

    return false;
}

void RenderLayerScrollableArea::updateResizerAreaSet()
{
    LocalFrame* frame = box().frame();
    if (!frame)
        return;
    FrameView* frameView = frame->view();
    if (!frameView)
        return;
    if (box().canResize())
        frameView->addResizerArea(box());
    else
        frameView->removeResizerArea(box());
}

void RenderLayerScrollableArea::drawPlatformResizerImage(GraphicsContext* context, IntRect resizerCornerRect)
{
    float deviceScaleFactor = blink::deviceScaleFactor(box().frame());

    RefPtr<Image> resizeCornerImage;
    IntSize cornerResizerSize;
    if (deviceScaleFactor >= 2) {
        DEFINE_STATIC_REF(Image, resizeCornerImageHiRes, (Image::loadPlatformResource("textAreaResizeCorner@2x")));
        resizeCornerImage = resizeCornerImageHiRes;
        cornerResizerSize = resizeCornerImage->size();
        cornerResizerSize.scale(0.5f);
    } else {
        DEFINE_STATIC_REF(Image, resizeCornerImageLoRes, (Image::loadPlatformResource("textAreaResizeCorner")));
        resizeCornerImage = resizeCornerImageLoRes;
        cornerResizerSize = resizeCornerImage->size();
    }

    if (box().style()->shouldPlaceBlockDirectionScrollbarOnLogicalLeft()) {
        context->save();
        context->translate(resizerCornerRect.x() + cornerResizerSize.width(), resizerCornerRect.y() + resizerCornerRect.height() - cornerResizerSize.height());
        context->scale(-1.0, 1.0);
        context->drawImage(resizeCornerImage.get(), IntRect(IntPoint(), cornerResizerSize));
        context->restore();
        return;
    }
    IntRect imageRect(resizerCornerRect.maxXMaxYCorner() - cornerResizerSize, cornerResizerSize);
    context->drawImage(resizeCornerImage.get(), imageRect);
}

IntSize RenderLayerScrollableArea::offsetFromResizeCorner(const IntPoint& absolutePoint) const
{
    // Currently the resize corner is either the bottom right corner or the bottom left corner.
    // FIXME: This assumes the location is 0, 0. Is this guaranteed to always be the case?
    IntSize elementSize = layer()->size();
    if (box().style()->shouldPlaceBlockDirectionScrollbarOnLogicalLeft())
        elementSize.setWidth(0);
    IntPoint resizerPoint = IntPoint(elementSize);
    IntPoint localPoint = roundedIntPoint(box().absoluteToLocal(absolutePoint, UseTransforms));
    return localPoint - resizerPoint;
}

void RenderLayerScrollableArea::resize(const PlatformEvent& evt, const LayoutSize& oldOffset)
{
    // FIXME: This should be possible on generated content but is not right now.
    if (!inResizeMode() || !box().canResize() || !box().node())
        return;

    ASSERT(box().node()->isElementNode());
    Element* element = toElement(box().node());

    Document& document = element->document();

    IntPoint pos;
    const PlatformGestureEvent* gevt = 0;

    switch (evt.type()) {
    case PlatformEvent::MouseMoved:
        if (!document.frame()->eventHandler().mousePressed())
            return;
        pos = static_cast<const PlatformMouseEvent*>(&evt)->position();
        break;
    case PlatformEvent::GestureScrollUpdate:
    case PlatformEvent::GestureScrollUpdateWithoutPropagation:
        pos = static_cast<const PlatformGestureEvent*>(&evt)->position();
        gevt = static_cast<const PlatformGestureEvent*>(&evt);
        pos = gevt->position();
        pos.move(gevt->deltaX(), gevt->deltaY());
        break;
    default:
        ASSERT_NOT_REACHED();
    }

    float zoomFactor = box().style()->effectiveZoom();

    LayoutSize newOffset = offsetFromResizeCorner(document.view()->windowToContents(pos));
    newOffset.setWidth(newOffset.width() / zoomFactor);
    newOffset.setHeight(newOffset.height() / zoomFactor);

    LayoutSize currentSize = LayoutSize(box().width() / zoomFactor, box().height() / zoomFactor);
    LayoutSize minimumSize = element->minimumSizeForResizing().shrunkTo(currentSize);
    element->setMinimumSizeForResizing(minimumSize);

    LayoutSize adjustedOldOffset = LayoutSize(oldOffset.width() / zoomFactor, oldOffset.height() / zoomFactor);
    if (box().style()->shouldPlaceBlockDirectionScrollbarOnLogicalLeft()) {
        newOffset.setWidth(-newOffset.width());
        adjustedOldOffset.setWidth(-adjustedOldOffset.width());
    }

    LayoutSize difference = (currentSize + newOffset - adjustedOldOffset).expandedTo(minimumSize) - currentSize;

    bool isBoxSizingBorder = box().style()->boxSizing() == BORDER_BOX;

    EResize resize = box().style()->resize();
    if (resize != RESIZE_VERTICAL && difference.width()) {
        if (element->isFormControlElement()) {
            // Make implicit margins from the theme explicit (see <http://bugs.webkit.org/show_bug.cgi?id=9547>).
            element->setInlineStyleProperty(CSSPropertyMarginLeft, box().marginLeft() / zoomFactor, CSSPrimitiveValue::CSS_PX);
            element->setInlineStyleProperty(CSSPropertyMarginRight, box().marginRight() / zoomFactor, CSSPrimitiveValue::CSS_PX);
        }
        LayoutUnit baseWidth = box().width() - (isBoxSizingBorder ? LayoutUnit() : box().borderAndPaddingWidth());
        baseWidth = baseWidth / zoomFactor;
        element->setInlineStyleProperty(CSSPropertyWidth, roundToInt(baseWidth + difference.width()), CSSPrimitiveValue::CSS_PX);
    }

    if (resize != RESIZE_HORIZONTAL && difference.height()) {
        if (element->isFormControlElement()) {
            // Make implicit margins from the theme explicit (see <http://bugs.webkit.org/show_bug.cgi?id=9547>).
            element->setInlineStyleProperty(CSSPropertyMarginTop, box().marginTop() / zoomFactor, CSSPrimitiveValue::CSS_PX);
            element->setInlineStyleProperty(CSSPropertyMarginBottom, box().marginBottom() / zoomFactor, CSSPrimitiveValue::CSS_PX);
        }
        LayoutUnit baseHeight = box().height() - (isBoxSizingBorder ? LayoutUnit() : box().borderAndPaddingHeight());
        baseHeight = baseHeight / zoomFactor;
        element->setInlineStyleProperty(CSSPropertyHeight, roundToInt(baseHeight + difference.height()), CSSPrimitiveValue::CSS_PX);
    }

    document.updateLayout();

    // FIXME (Radar 4118564): We should also autoscroll the window as necessary to keep the point under the cursor in view.
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

void RenderLayerScrollableArea::updateCompositingLayersAfterScroll()
{
    RenderLayerCompositor* compositor = box().view()->compositor();
    if (compositor->inCompositingMode()) {
        if (usesCompositedScrolling()) {
            DisableCompositingQueryAsserts disabler;
            ASSERT(layer()->hasCompositedLayerMapping());
            layer()->compositedLayerMapping()->setNeedsGraphicsLayerUpdate(GraphicsLayerUpdateSubtree);
            compositor->setNeedsCompositingUpdate(CompositingUpdateAfterGeometryChange);
        } else {
            layer()->setNeedsCompositingInputsUpdate();
        }
    }
}

bool RenderLayerScrollableArea::usesCompositedScrolling() const
{
    // Scroll form controls on the main thread so they exhibit correct touch scroll event bubbling
    if (box().isIntristicallyScrollable(VerticalScrollbar) || box().isIntristicallyScrollable(HorizontalScrollbar))
        return false;

    // See https://codereview.chromium.org/176633003/ for the tests that fail without this disabler.
    DisableCompositingQueryAsserts disabler;
    return layer()->hasCompositedLayerMapping() && layer()->compositedLayerMapping()->scrollingLayer();
}

static bool layerNeedsCompositedScrolling(const RenderLayer* layer)
{
    return layer->scrollsOverflow()
        && layer->compositor()->preferCompositingToLCDTextEnabled()
        && !layer->hasDescendantWithClipPath()
        && !layer->hasAncestorWithClipPath();
}

void RenderLayerScrollableArea::updateNeedsCompositedScrolling()
{
    const bool needsCompositedScrolling = layerNeedsCompositedScrolling(layer());
    if (static_cast<bool>(m_needsCompositedScrolling) != needsCompositedScrolling) {
        m_needsCompositedScrolling = needsCompositedScrolling;
        layer()->didUpdateNeedsCompositedScrolling();
    }
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
