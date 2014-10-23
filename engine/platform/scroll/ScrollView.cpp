/*
 * Copyright (C) 2006, 2007, 2008 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "platform/scroll/ScrollView.h"

#include "platform/graphics/GraphicsContextStateSaver.h"
#include "platform/graphics/GraphicsLayer.h"
#include "platform/HostWindow.h"
#include "platform/scroll/Scrollbar.h"
#include "wtf/StdLibExtras.h"

namespace blink {

ScrollView::ScrollView()
    : m_horizontalScrollbarMode(ScrollbarAuto)
    , m_verticalScrollbarMode(ScrollbarAuto)
    , m_horizontalScrollbarLock(false)
    , m_verticalScrollbarLock(false)
    , m_scrollbarsSuppressed(false)
    , m_inUpdateScrollbars(false)
    , m_paintsEntireContents(false)
    , m_clipsRepaints(true)
{
}

ScrollView::~ScrollView()
{
}

void ScrollView::addChild(PassRefPtr<Widget> prpChild)
{
    Widget* child = prpChild.get();
    ASSERT(child != this && !child->parent());
    child->setParent(this);
    m_children.add(prpChild);
}

void ScrollView::removeChild(Widget* child)
{
    ASSERT(child->parent() == this);
    child->setParent(0);
    m_children.remove(child);
}

void ScrollView::setHasHorizontalScrollbar(bool hasBar)
{
    if (hasBar && !m_horizontalScrollbar) {
        m_horizontalScrollbar = createScrollbar(HorizontalScrollbar);
        addChild(m_horizontalScrollbar.get());
        didAddScrollbar(m_horizontalScrollbar.get(), HorizontalScrollbar);
        m_horizontalScrollbar->styleChanged();
    } else if (!hasBar && m_horizontalScrollbar) {
        willRemoveScrollbar(m_horizontalScrollbar.get(), HorizontalScrollbar);
        removeChild(m_horizontalScrollbar.get());
        m_horizontalScrollbar = nullptr;
    }
}

void ScrollView::setHasVerticalScrollbar(bool hasBar)
{
    if (hasBar && !m_verticalScrollbar) {
        m_verticalScrollbar = createScrollbar(VerticalScrollbar);
        addChild(m_verticalScrollbar.get());
        didAddScrollbar(m_verticalScrollbar.get(), VerticalScrollbar);
        m_verticalScrollbar->styleChanged();
    } else if (!hasBar && m_verticalScrollbar) {
        willRemoveScrollbar(m_verticalScrollbar.get(), VerticalScrollbar);
        removeChild(m_verticalScrollbar.get());
        m_verticalScrollbar = nullptr;
    }
}

PassRefPtr<Scrollbar> ScrollView::createScrollbar(ScrollbarOrientation orientation)
{
    return Scrollbar::create(this, orientation);
}

void ScrollView::setScrollbarModes(ScrollbarMode horizontalMode, ScrollbarMode verticalMode,
                                   bool horizontalLock, bool verticalLock)
{
    bool needsUpdate = false;

    if (horizontalMode != horizontalScrollbarMode() && !m_horizontalScrollbarLock) {
        m_horizontalScrollbarMode = horizontalMode;
        needsUpdate = true;
    }

    if (verticalMode != verticalScrollbarMode() && !m_verticalScrollbarLock) {
        m_verticalScrollbarMode = verticalMode;
        needsUpdate = true;
    }

    if (horizontalLock)
        setHorizontalScrollbarLock();

    if (verticalLock)
        setVerticalScrollbarLock();

    if (!needsUpdate)
        return;

    updateScrollbars(scrollOffset());

    if (!layerForScrolling())
        return;
    blink::WebLayer* layer = layerForScrolling()->platformLayer();
    if (!layer)
        return;
    layer->setUserScrollable(userInputScrollable(HorizontalScrollbar), userInputScrollable(VerticalScrollbar));
}

void ScrollView::scrollbarModes(ScrollbarMode& horizontalMode, ScrollbarMode& verticalMode) const
{
    horizontalMode = m_horizontalScrollbarMode;
    verticalMode = m_verticalScrollbarMode;
}

void ScrollView::setCanHaveScrollbars(bool canScroll)
{
    ScrollbarMode newHorizontalMode;
    ScrollbarMode newVerticalMode;

    scrollbarModes(newHorizontalMode, newVerticalMode);

    if (canScroll && newVerticalMode == ScrollbarAlwaysOff)
        newVerticalMode = ScrollbarAuto;
    else if (!canScroll)
        newVerticalMode = ScrollbarAlwaysOff;

    if (canScroll && newHorizontalMode == ScrollbarAlwaysOff)
        newHorizontalMode = ScrollbarAuto;
    else if (!canScroll)
        newHorizontalMode = ScrollbarAlwaysOff;

    setScrollbarModes(newHorizontalMode, newVerticalMode);
}

void ScrollView::setPaintsEntireContents(bool paintsEntireContents)
{
    m_paintsEntireContents = paintsEntireContents;
}

void ScrollView::setClipsRepaints(bool clipsRepaints)
{
    m_clipsRepaints = clipsRepaints;
}

IntSize ScrollView::unscaledVisibleContentSize(IncludeScrollbarsInRect scrollbarInclusion) const
{
    return scrollbarInclusion == ExcludeScrollbars ? excludeScrollbars(frameRect().size()) : frameRect().size();
}

IntSize ScrollView::excludeScrollbars(const IntSize& size) const
{
    int verticalScrollbarWidth = 0;
    int horizontalScrollbarHeight = 0;

    if (Scrollbar* verticalBar = verticalScrollbar())
        verticalScrollbarWidth = !verticalBar->isOverlayScrollbar() ? verticalBar->width() : 0;
    if (Scrollbar* horizontalBar = horizontalScrollbar())
        horizontalScrollbarHeight = !horizontalBar->isOverlayScrollbar() ? horizontalBar->height() : 0;

    return IntSize(std::max(0, size.width() - verticalScrollbarWidth),
        std::max(0, size.height() - horizontalScrollbarHeight));

}

IntRect ScrollView::visibleContentRect(IncludeScrollbarsInRect scollbarInclusion) const
{
    FloatSize visibleContentSize = unscaledVisibleContentSize(scollbarInclusion);
    visibleContentSize.scale(1 / visibleContentScaleFactor());
    return IntRect(IntPoint(m_scrollOffset), expandedIntSize(visibleContentSize));
}

IntSize ScrollView::contentsSize() const
{
    return m_contentsSize;
}

void ScrollView::setContentsSize(const IntSize& newSize)
{
    if (contentsSize() == newSize)
        return;
    m_contentsSize = newSize;
    updateScrollbars(scrollOffset());
    updateOverhangAreas();
}

IntPoint ScrollView::maximumScrollPosition() const
{
    IntPoint maximumOffset(contentsWidth() - visibleWidth() - scrollOrigin().x(), contentsHeight() - visibleHeight() - scrollOrigin().y());
    maximumOffset.clampNegativeToZero();
    return maximumOffset;
}

IntPoint ScrollView::minimumScrollPosition() const
{
    return IntPoint(-scrollOrigin().x(), -scrollOrigin().y());
}

IntPoint ScrollView::adjustScrollPositionWithinRange(const IntPoint& scrollPoint) const
{
    if (!constrainsScrollingToContentEdge())
        return scrollPoint;

    IntPoint newScrollPosition = scrollPoint.shrunkTo(maximumScrollPosition());
    newScrollPosition = newScrollPosition.expandedTo(minimumScrollPosition());
    return newScrollPosition;
}

void ScrollView::adjustScrollbarOpacity()
{
    if (m_horizontalScrollbar && layerForHorizontalScrollbar()) {
        bool isOpaqueScrollbar = !m_horizontalScrollbar->isOverlayScrollbar();
        layerForHorizontalScrollbar()->setContentsOpaque(isOpaqueScrollbar);
    }
    if (m_verticalScrollbar && layerForVerticalScrollbar()) {
        bool isOpaqueScrollbar = !m_verticalScrollbar->isOverlayScrollbar();
        layerForVerticalScrollbar()->setContentsOpaque(isOpaqueScrollbar);
    }
}

int ScrollView::scrollSize(ScrollbarOrientation orientation) const
{
    Scrollbar* scrollbar = ((orientation == HorizontalScrollbar) ? m_horizontalScrollbar : m_verticalScrollbar).get();

    // If no scrollbars are present, the content may still be scrollable.
    if (!scrollbar) {
        IntSize scrollSize = m_contentsSize - visibleContentRect().size();
        scrollSize.clampNegativeToZero();
        return orientation == HorizontalScrollbar ? scrollSize.width() : scrollSize.height();
    }

    return scrollbar->totalSize() - scrollbar->visibleSize();
}

void ScrollView::notifyPageThatContentAreaWillPaint() const
{
}

void ScrollView::setScrollOffset(const IntPoint& offset)
{
    scrollTo(toIntSize(adjustScrollPositionWithinRange(offset)));
}

void ScrollView::scrollTo(const IntSize& newOffset)
{
    IntSize scrollDelta = newOffset - m_scrollOffset;
    if (scrollDelta == IntSize())
        return;
    m_scrollOffset = newOffset;

    if (scrollbarsSuppressed())
        return;

    if (isFrameView())
        m_pendingScrollDelta += scrollDelta;
    else
        scrollContents(scrollDelta);
}

void ScrollView::setScrollPosition(const IntPoint& scrollPoint, ScrollBehavior scrollBehavior)
{
    IntPoint newScrollPosition = adjustScrollPositionWithinRange(scrollPoint);

    if (newScrollPosition == scrollPosition())
        return;

    if (scrollBehavior == ScrollBehaviorInstant)
        updateScrollbars(IntSize(newScrollPosition.x(), newScrollPosition.y()));
    else
        programmaticallyScrollSmoothlyToOffset(newScrollPosition);
}

bool ScrollView::scroll(ScrollDirection direction, ScrollGranularity granularity)
{
    return ScrollableArea::scroll(direction, granularity);
}

IntSize ScrollView::overhangAmount() const
{
    IntSize stretch;

    IntPoint currentScrollPosition = scrollPosition();
    IntPoint minScrollPosition = minimumScrollPosition();
    IntPoint maxScrollPosition = maximumScrollPosition();

    if (currentScrollPosition.x() < minScrollPosition.x())
        stretch.setWidth(currentScrollPosition.x() - minScrollPosition.x());
    if (currentScrollPosition.x() > maxScrollPosition.x())
        stretch.setWidth(currentScrollPosition.x() - maxScrollPosition.x());

    if (currentScrollPosition.y() < minScrollPosition.y())
        stretch.setHeight(currentScrollPosition.y() - minScrollPosition.y());
    if (currentScrollPosition.y() > maxScrollPosition.y())
        stretch.setHeight(currentScrollPosition.y() - maxScrollPosition.y());

    return stretch;
}

void ScrollView::computeScrollbarExistence(bool& newHasHorizontalScrollbar, bool& newHasVerticalScrollbar, const IntSize& docSize, ComputeScrollbarExistenceOption option) const
{
    bool hasHorizontalScrollbar = m_horizontalScrollbar;
    bool hasVerticalScrollbar = m_verticalScrollbar;

    newHasHorizontalScrollbar = hasHorizontalScrollbar;
    newHasVerticalScrollbar = hasVerticalScrollbar;

    ScrollbarMode hScroll = m_horizontalScrollbarMode;
    ScrollbarMode vScroll = m_verticalScrollbarMode;

    if (hScroll != ScrollbarAuto)
        newHasHorizontalScrollbar = (hScroll == ScrollbarAlwaysOn);
    if (vScroll != ScrollbarAuto)
        newHasVerticalScrollbar = (vScroll == ScrollbarAlwaysOn);

    if (m_scrollbarsSuppressed || (hScroll != ScrollbarAuto && vScroll != ScrollbarAuto))
        return;

    if (hScroll == ScrollbarAuto)
        newHasHorizontalScrollbar = docSize.width() > visibleWidth();
    if (vScroll == ScrollbarAuto)
        newHasVerticalScrollbar = docSize.height() > visibleHeight();
}

void ScrollView::updateScrollbarGeometry()
{
    if (m_horizontalScrollbar) {
        int clientWidth = visibleWidth();
        IntRect oldRect(m_horizontalScrollbar->frameRect());
        IntRect hBarRect((shouldPlaceVerticalScrollbarOnLeft() && m_verticalScrollbar) ? m_verticalScrollbar->width() : 0,
                        height() - m_horizontalScrollbar->height(),
                        width() - (m_verticalScrollbar ? m_verticalScrollbar->width() : 0),
                        m_horizontalScrollbar->height());
        m_horizontalScrollbar->setFrameRect(hBarRect);
        if (!m_scrollbarsSuppressed && oldRect != m_horizontalScrollbar->frameRect())
            m_horizontalScrollbar->invalidate();

        if (m_scrollbarsSuppressed)
            m_horizontalScrollbar->setSuppressInvalidation(true);
        m_horizontalScrollbar->setEnabled(contentsWidth() > clientWidth);
        m_horizontalScrollbar->setProportion(clientWidth, contentsWidth());
        m_horizontalScrollbar->offsetDidChange();
        if (m_scrollbarsSuppressed)
            m_horizontalScrollbar->setSuppressInvalidation(false);
    }

    if (m_verticalScrollbar) {
        int clientHeight = visibleHeight();
        IntRect oldRect(m_verticalScrollbar->frameRect());
        IntRect vBarRect(shouldPlaceVerticalScrollbarOnLeft() ? 0 : (width() - m_verticalScrollbar->width()),
                         0,
                         m_verticalScrollbar->width(),
                         height() - (m_horizontalScrollbar ? m_horizontalScrollbar->height() : 0));
        m_verticalScrollbar->setFrameRect(vBarRect);
        if (!m_scrollbarsSuppressed && oldRect != m_verticalScrollbar->frameRect())
            m_verticalScrollbar->invalidate();

        if (m_scrollbarsSuppressed)
            m_verticalScrollbar->setSuppressInvalidation(true);
        m_verticalScrollbar->setEnabled(contentsHeight() > clientHeight);
        m_verticalScrollbar->setProportion(clientHeight, contentsHeight());
        m_verticalScrollbar->offsetDidChange();
        if (m_scrollbarsSuppressed)
            m_verticalScrollbar->setSuppressInvalidation(false);
    }
}

bool ScrollView::adjustScrollbarExistence(ComputeScrollbarExistenceOption option)
{
    ASSERT(m_inUpdateScrollbars);

    // If we came in here with the view already needing a layout, then go ahead and do that
    // first.  (This will be the common case, e.g., when the page changes due to window resizing for example).
    // This layout will not re-enter updateScrollbars and does not count towards our max layout pass total.
    if (!m_scrollbarsSuppressed)
        scrollbarExistenceDidChange();

    bool hasHorizontalScrollbar = m_horizontalScrollbar;
    bool hasVerticalScrollbar = m_verticalScrollbar;

    bool newHasHorizontalScrollbar = false;
    bool newHasVerticalScrollbar = false;
    computeScrollbarExistence(newHasHorizontalScrollbar, newHasVerticalScrollbar, contentsSize(), option);

    bool scrollbarExistenceChanged = hasHorizontalScrollbar != newHasHorizontalScrollbar || hasVerticalScrollbar != newHasVerticalScrollbar;
    if (!scrollbarExistenceChanged)
        return false;

    setHasHorizontalScrollbar(newHasHorizontalScrollbar);
    setHasVerticalScrollbar(newHasVerticalScrollbar);

    if (m_scrollbarsSuppressed)
        return true;

    scrollbarExistenceDidChange();
    return true;
}

void ScrollView::updateScrollbars(const IntSize& desiredOffset)
{
    if (m_inUpdateScrollbars)
        return;
    InUpdateScrollbarsScope inUpdateScrollbarsScope(this);

    IntSize oldVisibleSize = visibleSize();

    bool scrollbarExistenceChanged = false;
    int maxUpdateScrollbarsPass = 1;
    for (int updateScrollbarsPass = 0; updateScrollbarsPass < maxUpdateScrollbarsPass; updateScrollbarsPass++) {
        if (!adjustScrollbarExistence(updateScrollbarsPass ? Incremental : FirstPass))
            break;
        scrollbarExistenceChanged = true;
    }

    updateScrollbarGeometry();

    if (scrollbarExistenceChanged) {
        // FIXME: Is frameRectsChanged really necessary here? Have any frame rects changed?
        frameRectsChanged();
        positionScrollbarLayers();
        updateScrollCorner();
    }

    // FIXME: We don't need to do this if we are composited.
    IntSize newVisibleSize = visibleSize();
    if (newVisibleSize.width() > oldVisibleSize.width()) {
        if (shouldPlaceVerticalScrollbarOnLeft())
            invalidateRect(IntRect(0, 0, newVisibleSize.width() - oldVisibleSize.width(), newVisibleSize.height()));
        else
            invalidateRect(IntRect(oldVisibleSize.width(), 0, newVisibleSize.width() - oldVisibleSize.width(), newVisibleSize.height()));
    }
    if (newVisibleSize.height() > oldVisibleSize.height())
        invalidateRect(IntRect(0, oldVisibleSize.height(), newVisibleSize.width(), newVisibleSize.height() - oldVisibleSize.height()));

    IntPoint adjustedScrollPosition = IntPoint(desiredOffset);
    if (!isRubberBandInProgress())
        adjustedScrollPosition = adjustScrollPositionWithinRange(adjustedScrollPosition);
    if (adjustedScrollPosition != scrollPosition() || scrollOriginChanged()) {
        ScrollableArea::scrollToOffsetWithoutAnimation(adjustedScrollPosition);
        resetScrollOriginChanged();
    }
}

IntRect ScrollView::rectToCopyOnScroll() const
{
    IntRect scrollViewRect = convertToRootView(IntRect((shouldPlaceVerticalScrollbarOnLeft() && verticalScrollbar()) ? verticalScrollbar()->width() : 0, 0, visibleWidth(), visibleHeight()));
    if (hasOverlayScrollbars()) {
        int verticalScrollbarWidth = (verticalScrollbar() && !hasLayerForVerticalScrollbar()) ? verticalScrollbar()->width() : 0;
        int horizontalScrollbarHeight = (horizontalScrollbar() && !hasLayerForHorizontalScrollbar()) ? horizontalScrollbar()->height() : 0;

        scrollViewRect.setWidth(scrollViewRect.width() - verticalScrollbarWidth);
        scrollViewRect.setHeight(scrollViewRect.height() - horizontalScrollbarHeight);
    }
    return scrollViewRect;
}

void ScrollView::scrollContentsIfNeeded()
{
    if (m_pendingScrollDelta.isZero())
        return;
    IntSize scrollDelta = m_pendingScrollDelta;
    m_pendingScrollDelta = IntSize();
    scrollContents(scrollDelta);
}

void ScrollView::scrollContents(const IntSize& scrollDelta)
{
    HostWindow* window = hostWindow();
    if (!window)
        return;

    IntRect clipRect = windowClipRect();
    IntRect updateRect = clipRect;
    updateRect.intersect(rectToCopyOnScroll());

    if (!scrollContentsFastPath(-scrollDelta))
        scrollContentsSlowPath(updateRect);

    // Invalidate the overhang areas if they are visible.
    updateOverhangAreas();

    // This call will move children with native widgets (plugins) and invalidate them as well.
    frameRectsChanged();
}

void ScrollView::scrollContentsSlowPath(const IntRect& updateRect)
{
    hostWindow()->invalidateContentsForSlowScroll(updateRect);
}

IntPoint ScrollView::rootViewToContents(const IntPoint& rootViewPoint) const
{
    IntPoint viewPoint = convertFromRootView(rootViewPoint);
    return viewPoint + scrollOffset();
}

IntPoint ScrollView::contentsToRootView(const IntPoint& contentsPoint) const
{
    IntPoint viewPoint = contentsPoint - scrollOffset();
    return convertToRootView(viewPoint);
}

IntRect ScrollView::rootViewToContents(const IntRect& rootViewRect) const
{
    IntRect viewRect = convertFromRootView(rootViewRect);
    viewRect.move(scrollOffset());
    return viewRect;
}

IntRect ScrollView::contentsToRootView(const IntRect& contentsRect) const
{
    IntRect viewRect = contentsRect;
    viewRect.move(-scrollOffset());
    return convertToRootView(viewRect);
}

IntPoint ScrollView::windowToContents(const IntPoint& windowPoint) const
{
    IntPoint viewPoint = convertFromContainingWindow(windowPoint);
    return viewPoint + scrollOffset();
}

FloatPoint ScrollView::windowToContents(const FloatPoint& windowPoint) const
{
    FloatPoint viewPoint = convertFromContainingWindow(windowPoint);
    return viewPoint + scrollOffset();
}

IntPoint ScrollView::contentsToWindow(const IntPoint& contentsPoint) const
{
    IntPoint viewPoint = contentsPoint - scrollOffset();
    return convertToContainingWindow(viewPoint);
}

IntRect ScrollView::windowToContents(const IntRect& windowRect) const
{
    IntRect viewRect = convertFromContainingWindow(windowRect);
    viewRect.move(scrollOffset());
    return viewRect;
}

IntRect ScrollView::contentsToWindow(const IntRect& contentsRect) const
{
    IntRect viewRect = contentsRect;
    viewRect.move(-scrollOffset());
    return convertToContainingWindow(viewRect);
}

IntRect ScrollView::contentsToScreen(const IntRect& rect) const
{
    HostWindow* window = hostWindow();
    if (!window)
        return IntRect();
    return window->rootViewToScreen(contentsToRootView(rect));
}

void ScrollView::setScrollbarsSuppressed(bool suppressed, bool repaintOnUnsuppress)
{
    if (suppressed == m_scrollbarsSuppressed)
        return;

    m_scrollbarsSuppressed = suppressed;

    if (repaintOnUnsuppress && !suppressed) {
        if (m_horizontalScrollbar)
            m_horizontalScrollbar->invalidate();
        if (m_verticalScrollbar)
            m_verticalScrollbar->invalidate();

        // Invalidate the scroll corner too on unsuppress.
        invalidateRect(scrollCornerRect());
    }
}

Scrollbar* ScrollView::scrollbarAtPoint(const IntPoint& windowPoint)
{
    IntPoint viewPoint = convertFromContainingWindow(windowPoint);
    if (m_horizontalScrollbar && m_horizontalScrollbar->shouldParticipateInHitTesting() && m_horizontalScrollbar->frameRect().contains(viewPoint))
        return m_horizontalScrollbar.get();
    if (m_verticalScrollbar && m_verticalScrollbar->shouldParticipateInHitTesting() && m_verticalScrollbar->frameRect().contains(viewPoint))
        return m_verticalScrollbar.get();
    return 0;
}

void ScrollView::setFrameRect(const IntRect& newRect)
{
    IntRect oldRect = frameRect();

    if (newRect == oldRect)
        return;

    Widget::setFrameRect(newRect);

    updateScrollbars(scrollOffset());

    frameRectsChanged();
}

void ScrollView::frameRectsChanged()
{
    HashSet<RefPtr<Widget> >::const_iterator end = m_children.end();
    for (HashSet<RefPtr<Widget> >::const_iterator current = m_children.begin(); current != end; ++current)
        (*current)->frameRectsChanged();
}

static void positionScrollbarLayer(GraphicsLayer* graphicsLayer, Scrollbar* scrollbar)
{
    if (!graphicsLayer || !scrollbar)
        return;

    IntRect scrollbarRect = scrollbar->frameRect();
    graphicsLayer->setPosition(scrollbarRect.location());

    if (scrollbarRect.size() == graphicsLayer->size())
        return;

    graphicsLayer->setSize(scrollbarRect.size());

    if (graphicsLayer->hasContentsLayer()) {
        graphicsLayer->setContentsRect(IntRect(0, 0, scrollbarRect.width(), scrollbarRect.height()));
        return;
    }

    graphicsLayer->setDrawsContent(true);
    graphicsLayer->setNeedsDisplay();
}

static void positionScrollCornerLayer(GraphicsLayer* graphicsLayer, const IntRect& cornerRect)
{
    if (!graphicsLayer)
        return;
    graphicsLayer->setDrawsContent(!cornerRect.isEmpty());
    graphicsLayer->setPosition(cornerRect.location());
    if (cornerRect.size() != graphicsLayer->size())
        graphicsLayer->setNeedsDisplay();
    graphicsLayer->setSize(cornerRect.size());
}

void ScrollView::positionScrollbarLayers()
{
    positionScrollbarLayer(layerForHorizontalScrollbar(), horizontalScrollbar());
    positionScrollbarLayer(layerForVerticalScrollbar(), verticalScrollbar());
    positionScrollCornerLayer(layerForScrollCorner(), scrollCornerRect());
}

bool ScrollView::userInputScrollable(ScrollbarOrientation orientation) const
{
    ScrollbarMode mode = (orientation == HorizontalScrollbar) ?
        m_horizontalScrollbarMode : m_verticalScrollbarMode;

    return mode == ScrollbarAuto || mode == ScrollbarAlwaysOn;
}

bool ScrollView::shouldPlaceVerticalScrollbarOnLeft() const
{
    return false;
}

void ScrollView::contentRectangleForPaintInvalidation(const IntRect& rect)
{
    IntRect paintRect = rect;
    if (clipsPaintInvalidations() && !paintsEntireContents())
        paintRect.intersect(visibleContentRect());
    if (paintRect.isEmpty())
        return;

    if (HostWindow* window = hostWindow())
        window->invalidateContentsAndRootView(contentsToWindow(paintRect));
}

IntRect ScrollView::scrollCornerRect() const
{
    IntRect cornerRect;

    if (hasOverlayScrollbars())
        return cornerRect;

    if (m_horizontalScrollbar && width() - m_horizontalScrollbar->width() > 0) {
        cornerRect.unite(IntRect(shouldPlaceVerticalScrollbarOnLeft() ? 0 : m_horizontalScrollbar->width(),
                                 height() - m_horizontalScrollbar->height(),
                                 width() - m_horizontalScrollbar->width(),
                                 m_horizontalScrollbar->height()));
    }

    if (m_verticalScrollbar && height() - m_verticalScrollbar->height() > 0) {
        cornerRect.unite(IntRect(shouldPlaceVerticalScrollbarOnLeft() ? 0 : (width() - m_verticalScrollbar->width()),
                                 m_verticalScrollbar->height(),
                                 m_verticalScrollbar->width(),
                                 height() - m_verticalScrollbar->height()));
    }

    return cornerRect;
}

bool ScrollView::isScrollCornerVisible() const
{
    return !scrollCornerRect().isEmpty();
}

void ScrollView::updateScrollCorner()
{
}

void ScrollView::paintScrollCorner(GraphicsContext* context, const IntRect& cornerRect)
{
    Scrollbar::paintScrollCorner(context, cornerRect);
}

void ScrollView::paintScrollbar(GraphicsContext* context, Scrollbar* bar, const IntRect& rect)
{
    bar->paint(context, rect);
}

void ScrollView::invalidateScrollCornerRect(const IntRect& rect)
{
    invalidateRect(rect);
}

void ScrollView::paintScrollbars(GraphicsContext* context, const IntRect& rect)
{
    if (m_horizontalScrollbar && !layerForHorizontalScrollbar())
        paintScrollbar(context, m_horizontalScrollbar.get(), rect);
    if (m_verticalScrollbar && !layerForVerticalScrollbar())
        paintScrollbar(context, m_verticalScrollbar.get(), rect);

    if (layerForScrollCorner())
        return;
    paintScrollCorner(context, scrollCornerRect());
}

void ScrollView::paint(GraphicsContext* context, const IntRect& rect)
{
    notifyPageThatContentAreaWillPaint();

    IntRect documentDirtyRect = rect;
    if (!paintsEntireContents()) {
        IntRect visibleAreaWithoutScrollbars(location(), visibleContentRect().size());
        documentDirtyRect.intersect(visibleAreaWithoutScrollbars);
    }

    if (!documentDirtyRect.isEmpty()) {
        GraphicsContextStateSaver stateSaver(*context);

        context->translate(x(), y());
        documentDirtyRect.moveBy(-location());

        if (!paintsEntireContents()) {
            context->translate(-scrollX(), -scrollY());
            documentDirtyRect.moveBy(scrollPosition());

            context->clip(visibleContentRect());
        }

        paintContents(context, documentDirtyRect);
    }

    calculateAndPaintOverhangAreas(context, rect);

    // Now paint the scrollbars.
    if (!m_scrollbarsSuppressed && (m_horizontalScrollbar || m_verticalScrollbar)) {
        GraphicsContextStateSaver stateSaver(*context);
        IntRect scrollViewDirtyRect = rect;
        IntRect visibleAreaWithScrollbars(location(), visibleContentRect(IncludeScrollbars).size());
        scrollViewDirtyRect.intersect(visibleAreaWithScrollbars);
        context->translate(x(), y());
        scrollViewDirtyRect.moveBy(-location());
        context->clip(IntRect(IntPoint(), visibleAreaWithScrollbars.size()));

        paintScrollbars(context, scrollViewDirtyRect);
    }
}

void ScrollView::calculateOverhangAreasForPainting(IntRect& horizontalOverhangRect, IntRect& verticalOverhangRect)
{
    int verticalScrollbarWidth = (verticalScrollbar() && !verticalScrollbar()->isOverlayScrollbar())
        ? verticalScrollbar()->width() : 0;
    int horizontalScrollbarHeight = (horizontalScrollbar() && !horizontalScrollbar()->isOverlayScrollbar())
        ? horizontalScrollbar()->height() : 0;

    int physicalScrollY = scrollPosition().y() + scrollOrigin().y();
    if (physicalScrollY < 0) {
        horizontalOverhangRect = frameRect();
        horizontalOverhangRect.setHeight(-physicalScrollY);
        horizontalOverhangRect.setWidth(horizontalOverhangRect.width() - verticalScrollbarWidth);
    } else if (contentsHeight() && physicalScrollY > contentsHeight() - visibleHeight()) {
        int height = physicalScrollY - (contentsHeight() - visibleHeight());
        horizontalOverhangRect = frameRect();
        horizontalOverhangRect.setY(frameRect().maxY() - height - horizontalScrollbarHeight);
        horizontalOverhangRect.setHeight(height);
        horizontalOverhangRect.setWidth(horizontalOverhangRect.width() - verticalScrollbarWidth);
    }

    int physicalScrollX = scrollPosition().x() + scrollOrigin().x();
    if (physicalScrollX < 0) {
        verticalOverhangRect.setWidth(-physicalScrollX);
        verticalOverhangRect.setHeight(frameRect().height() - horizontalOverhangRect.height() - horizontalScrollbarHeight);
        verticalOverhangRect.setX(frameRect().x());
        if (horizontalOverhangRect.y() == frameRect().y())
            verticalOverhangRect.setY(frameRect().y() + horizontalOverhangRect.height());
        else
            verticalOverhangRect.setY(frameRect().y());
    } else if (contentsWidth() && physicalScrollX > contentsWidth() - visibleWidth()) {
        int width = physicalScrollX - (contentsWidth() - visibleWidth());
        verticalOverhangRect.setWidth(width);
        verticalOverhangRect.setHeight(frameRect().height() - horizontalOverhangRect.height() - horizontalScrollbarHeight);
        verticalOverhangRect.setX(frameRect().maxX() - width - verticalScrollbarWidth);
        if (horizontalOverhangRect.y() == frameRect().y())
            verticalOverhangRect.setY(frameRect().y() + horizontalOverhangRect.height());
        else
            verticalOverhangRect.setY(frameRect().y());
    }
}

void ScrollView::updateOverhangAreas()
{
    HostWindow* window = hostWindow();
    if (!window)
        return;

    IntRect horizontalOverhangRect;
    IntRect verticalOverhangRect;
    calculateOverhangAreasForPainting(horizontalOverhangRect, verticalOverhangRect);
    if (!horizontalOverhangRect.isEmpty())
        window->invalidateContentsAndRootView(horizontalOverhangRect);
    if (!verticalOverhangRect.isEmpty())
        window->invalidateContentsAndRootView(verticalOverhangRect);
}

void ScrollView::paintOverhangAreas(GraphicsContext* context, const IntRect& horizontalOverhangRect, const IntRect& verticalOverhangRect, const IntRect& dirtyRect)
{
    Scrollbar::paintOverhangBackground(context, horizontalOverhangRect, verticalOverhangRect, dirtyRect);
}

void ScrollView::calculateAndPaintOverhangAreas(GraphicsContext* context, const IntRect& dirtyRect)
{
    IntRect horizontalOverhangRect;
    IntRect verticalOverhangRect;
    calculateOverhangAreasForPainting(horizontalOverhangRect, verticalOverhangRect);

    if (dirtyRect.intersects(horizontalOverhangRect) || dirtyRect.intersects(verticalOverhangRect))
        paintOverhangAreas(context, horizontalOverhangRect, verticalOverhangRect, dirtyRect);
}

void ScrollView::calculateAndPaintOverhangBackground(GraphicsContext* context, const IntRect& dirtyRect)
{
    IntRect horizontalOverhangRect;
    IntRect verticalOverhangRect;
    calculateOverhangAreasForPainting(horizontalOverhangRect, verticalOverhangRect);

    if (dirtyRect.intersects(horizontalOverhangRect) || dirtyRect.intersects(verticalOverhangRect))
        Scrollbar::paintOverhangBackground(context, horizontalOverhangRect, verticalOverhangRect, dirtyRect);
}

bool ScrollView::isPointInScrollbarCorner(const IntPoint& windowPoint)
{
    if (!scrollbarCornerPresent())
        return false;

    IntPoint viewPoint = convertFromContainingWindow(windowPoint);

    if (m_horizontalScrollbar) {
        int horizontalScrollbarYMin = m_horizontalScrollbar->frameRect().y();
        int horizontalScrollbarYMax = m_horizontalScrollbar->frameRect().y() + m_horizontalScrollbar->frameRect().height();
        int horizontalScrollbarXMin = m_horizontalScrollbar->frameRect().x() + m_horizontalScrollbar->frameRect().width();

        return viewPoint.y() > horizontalScrollbarYMin && viewPoint.y() < horizontalScrollbarYMax && viewPoint.x() > horizontalScrollbarXMin;
    }

    int verticalScrollbarXMin = m_verticalScrollbar->frameRect().x();
    int verticalScrollbarXMax = m_verticalScrollbar->frameRect().x() + m_verticalScrollbar->frameRect().width();
    int verticalScrollbarYMin = m_verticalScrollbar->frameRect().y() + m_verticalScrollbar->frameRect().height();

    return viewPoint.x() > verticalScrollbarXMin && viewPoint.x() < verticalScrollbarXMax && viewPoint.y() > verticalScrollbarYMin;
}

bool ScrollView::scrollbarCornerPresent() const
{
    return (m_horizontalScrollbar && width() - m_horizontalScrollbar->width() > 0)
        || (m_verticalScrollbar && height() - m_verticalScrollbar->height() > 0);
}

IntRect ScrollView::convertFromScrollbarToContainingView(const Scrollbar* scrollbar, const IntRect& localRect) const
{
    // Scrollbars won't be transformed within us
    IntRect newRect = localRect;
    newRect.moveBy(scrollbar->location());
    return newRect;
}

IntRect ScrollView::convertFromContainingViewToScrollbar(const Scrollbar* scrollbar, const IntRect& parentRect) const
{
    IntRect newRect = parentRect;
    // Scrollbars won't be transformed within us
    newRect.moveBy(-scrollbar->location());
    return newRect;
}

// FIXME: test these on windows
IntPoint ScrollView::convertFromScrollbarToContainingView(const Scrollbar* scrollbar, const IntPoint& localPoint) const
{
    // Scrollbars won't be transformed within us
    IntPoint newPoint = localPoint;
    newPoint.moveBy(scrollbar->location());
    return newPoint;
}

IntPoint ScrollView::convertFromContainingViewToScrollbar(const Scrollbar* scrollbar, const IntPoint& parentPoint) const
{
    IntPoint newPoint = parentPoint;
    // Scrollbars won't be transformed within us
    newPoint.moveBy(-scrollbar->location());
    return newPoint;
}

void ScrollView::setParentVisible(bool visible)
{
    if (isParentVisible() == visible)
        return;

    Widget::setParentVisible(visible);

    if (!isSelfVisible())
        return;

    HashSet<RefPtr<Widget> >::iterator end = m_children.end();
    for (HashSet<RefPtr<Widget> >::iterator it = m_children.begin(); it != end; ++it)
        (*it)->setParentVisible(visible);
}

void ScrollView::show()
{
    if (!isSelfVisible()) {
        setSelfVisible(true);
        if (isParentVisible()) {
            HashSet<RefPtr<Widget> >::iterator end = m_children.end();
            for (HashSet<RefPtr<Widget> >::iterator it = m_children.begin(); it != end; ++it)
                (*it)->setParentVisible(true);
        }
    }

    Widget::show();
}

void ScrollView::hide()
{
    if (isSelfVisible()) {
        if (isParentVisible()) {
            HashSet<RefPtr<Widget> >::iterator end = m_children.end();
            for (HashSet<RefPtr<Widget> >::iterator it = m_children.begin(); it != end; ++it)
                (*it)->setParentVisible(false);
        }
        setSelfVisible(false);
    }

    Widget::hide();
}

void ScrollView::setScrollOrigin(const IntPoint& origin, bool updatePositionAtAll, bool updatePositionSynchronously)
{
    if (scrollOrigin() == origin)
        return;

    ScrollableArea::setScrollOrigin(origin);

    // Update if the scroll origin changes, since our position will be different if the content size did not change.
    if (updatePositionAtAll && updatePositionSynchronously)
        updateScrollbars(scrollOffset());
}

} // namespace blink
