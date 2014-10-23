/*
 * Copyright (C) 2004, 2006, 2007, 2008 Apple Inc. All rights reserved.
 * Copyright (C) 2009 Holger Hans Peter Freyther
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

#ifndef ScrollView_h
#define ScrollView_h

#include "platform/PlatformExport.h"
#include "platform/Widget.h"
#include "platform/geometry/IntRect.h"
#include "platform/scroll/ScrollTypes.h"
#include "platform/scroll/ScrollableArea.h"
#include "platform/scroll/Scrollbar.h"

#include "wtf/HashSet.h"
#include "wtf/TemporaryChange.h"

namespace blink {

class Scrollbar;

class PLATFORM_EXPORT ScrollView : public Widget, public ScrollableArea {
public:
    virtual ~ScrollView();

    // ScrollableArea functions.
    virtual int scrollSize(ScrollbarOrientation) const OVERRIDE;
    virtual void setScrollOffset(const IntPoint&) OVERRIDE;
    virtual bool isScrollCornerVisible() const OVERRIDE;
    virtual bool userInputScrollable(ScrollbarOrientation) const OVERRIDE;
    virtual bool shouldPlaceVerticalScrollbarOnLeft() const OVERRIDE;

    virtual void notifyPageThatContentAreaWillPaint() const;

    // NOTE: This should only be called by the overriden setScrollOffset from ScrollableArea.
    virtual void scrollTo(const IntSize& newOffset);

    // The window that hosts the ScrollView. The ScrollView will communicate scrolls and repaints to the
    // host window in the window's coordinate space.
    virtual HostWindow* hostWindow() const = 0;

    // Returns a clip rect in host window coordinates. Used to clip the blit on a scroll.
    virtual IntRect windowClipRect(IncludeScrollbarsInRect = ExcludeScrollbars) const = 0;

    // Functions for child manipulation and inspection.
    const HashSet<RefPtr<Widget> >* children() const { return &m_children; }
    virtual void addChild(PassRefPtr<Widget>);
    virtual void removeChild(Widget*);

    // If the scroll view does not use a native widget, then it will have cross-platform Scrollbars. These functions
    // can be used to obtain those scrollbars.
    virtual Scrollbar* horizontalScrollbar() const OVERRIDE { return m_horizontalScrollbar.get(); }
    virtual Scrollbar* verticalScrollbar() const OVERRIDE { return m_verticalScrollbar.get(); }
    bool isScrollViewScrollbar(const Widget* child) const { return horizontalScrollbar() == child || verticalScrollbar() == child; }

    void positionScrollbarLayers();

    // Functions for setting and retrieving the scrolling mode in each axis (horizontal/vertical). The mode has values of
    // AlwaysOff, AlwaysOn, and Auto. AlwaysOff means never show a scrollbar, AlwaysOn means always show a scrollbar.
    // Auto means show a scrollbar only when one is needed.
    // Note that for platforms with native widgets, these modes are considered advisory. In other words the underlying native
    // widget may choose not to honor the requested modes.
    void setScrollbarModes(ScrollbarMode horizontalMode, ScrollbarMode verticalMode, bool horizontalLock = false, bool verticalLock = false);
    void setHorizontalScrollbarMode(ScrollbarMode mode, bool lock = false) { setScrollbarModes(mode, verticalScrollbarMode(), lock, verticalScrollbarLock()); }
    void setVerticalScrollbarMode(ScrollbarMode mode, bool lock = false) { setScrollbarModes(horizontalScrollbarMode(), mode, horizontalScrollbarLock(), lock); };
    void scrollbarModes(ScrollbarMode& horizontalMode, ScrollbarMode& verticalMode) const;
    ScrollbarMode horizontalScrollbarMode() const { ScrollbarMode horizontal, vertical; scrollbarModes(horizontal, vertical); return horizontal; }
    ScrollbarMode verticalScrollbarMode() const { ScrollbarMode horizontal, vertical; scrollbarModes(horizontal, vertical); return vertical; }

    void setHorizontalScrollbarLock(bool lock = true) { m_horizontalScrollbarLock = lock; }
    bool horizontalScrollbarLock() const { return m_horizontalScrollbarLock; }
    void setVerticalScrollbarLock(bool lock = true) { m_verticalScrollbarLock = lock; }
    bool verticalScrollbarLock() const { return m_verticalScrollbarLock; }

    void setScrollingModesLock(bool lock = true) { m_horizontalScrollbarLock = m_verticalScrollbarLock = lock; }

    virtual void setCanHaveScrollbars(bool);
    bool canHaveScrollbars() const { return horizontalScrollbarMode() != ScrollbarAlwaysOff || verticalScrollbarMode() != ScrollbarAlwaysOff; }

    // By default you only receive paint events for the area that is visible. In the case of using a
    // tiled backing store, this function can be set, so that the view paints the entire contents.
    bool paintsEntireContents() const { return m_paintsEntireContents; }
    void setPaintsEntireContents(bool);

    // By default, paint events are clipped to the visible area.  If set to
    // false, paint events are no longer clipped.  paintsEntireContents() implies !clipsRepaints().
    bool clipsPaintInvalidations() const { return m_clipsRepaints; }
    void setClipsRepaints(bool);

    // Overridden by FrameView to create custom CSS scrollbars if applicable.
    virtual PassRefPtr<Scrollbar> createScrollbar(ScrollbarOrientation);

    // The visible content rect has a location that is the scrolled offset of the document. The width and height are the viewport width
    // and height. By default the scrollbars themselves are excluded from this rectangle, but an optional boolean argument allows them to be
    // included.
    virtual IntRect visibleContentRect(IncludeScrollbarsInRect = ExcludeScrollbars) const OVERRIDE;
    IntSize visibleSize() const { return visibleContentRect().size(); }
    virtual int visibleWidth() const OVERRIDE FINAL { return visibleContentRect().width(); }
    virtual int visibleHeight() const OVERRIDE FINAL { return visibleContentRect().height(); }

    // visibleContentRect().size() is computed from unscaledVisibleContentSize() divided by the value of visibleContentScaleFactor.
    // For the main frame, visibleContentScaleFactor is equal to the page's pageScaleFactor; it's 1 otherwise.
    IntSize unscaledVisibleContentSize(IncludeScrollbarsInRect = ExcludeScrollbars) const;
    virtual float visibleContentScaleFactor() const { return 1; }

    // Offset used to convert incoming input events while emulating device metics.
    virtual IntSize inputEventsOffsetForEmulation() const { return IntSize(); }

    // Scale used to convert incoming input events. Usually the same as visibleContentScaleFactor(), unless specifically changed.
    virtual float inputEventsScaleFactor() const { return visibleContentScaleFactor(); }

    // Functions for getting/setting the size of the document contained inside the ScrollView (as an IntSize or as individual width and height
    // values).
    virtual IntSize contentsSize() const OVERRIDE; // Always at least as big as the visibleWidth()/visibleHeight().
    int contentsWidth() const { return contentsSize().width(); }
    int contentsHeight() const { return contentsSize().height(); }
    virtual void setContentsSize(const IntSize&);

    // Functions for querying the current scrolled position (both as a point, a size, or as individual X and Y values).
    virtual IntPoint scrollPosition() const OVERRIDE { return visibleContentRect().location(); }
    IntSize scrollOffset() const { return toIntSize(visibleContentRect().location()); } // Gets the scrolled position as an IntSize. Convenient for adding to other sizes.
    IntSize pendingScrollDelta() const { return m_pendingScrollDelta; }
    virtual IntPoint maximumScrollPosition() const OVERRIDE; // The maximum position we can be scrolled to.
    virtual IntPoint minimumScrollPosition() const OVERRIDE; // The minimum position we can be scrolled to.
    // Adjust the passed in scroll position to keep it between the minimum and maximum positions.
    IntPoint adjustScrollPositionWithinRange(const IntPoint&) const;
    int scrollX() const { return scrollPosition().x(); }
    int scrollY() const { return scrollPosition().y(); }

    virtual IntSize overhangAmount() const OVERRIDE;

    void cacheCurrentScrollPosition() { m_cachedScrollPosition = scrollPosition(); }
    IntPoint cachedScrollPosition() const { return m_cachedScrollPosition; }

    // Functions for scrolling the view.
    virtual void setScrollPosition(const IntPoint&, ScrollBehavior = ScrollBehaviorInstant);
    void scrollBy(const IntSize& s, ScrollBehavior behavior = ScrollBehaviorInstant)
    {
        return setScrollPosition(scrollPosition() + s, behavior);
    }

    bool scroll(ScrollDirection, ScrollGranularity);

    // Scroll the actual contents of the view (either blitting or invalidating as needed).
    void scrollContents(const IntSize& scrollDelta);

    // This gives us a means of blocking painting on our scrollbars until the first layout has occurred.
    void setScrollbarsSuppressed(bool suppressed, bool repaintOnUnsuppress = false);
    bool scrollbarsSuppressed() const { return m_scrollbarsSuppressed; }

    IntPoint rootViewToContents(const IntPoint&) const;
    IntPoint contentsToRootView(const IntPoint&) const;
    IntRect rootViewToContents(const IntRect&) const;
    IntRect contentsToRootView(const IntRect&) const;

    // Event coordinates are assumed to be in the coordinate space of a window that contains
    // the entire widget hierarchy. It is up to the platform to decide what the precise definition
    // of containing window is. (For example on Mac it is the containing NSWindow.)
    IntPoint windowToContents(const IntPoint&) const;
    FloatPoint windowToContents(const FloatPoint&) const;
    IntPoint contentsToWindow(const IntPoint&) const;
    IntRect windowToContents(const IntRect&) const;
    IntRect contentsToWindow(const IntRect&) const;

    // Functions for converting to screen coordinates.
    IntRect contentsToScreen(const IntRect&) const;

    // Called when our frame rect changes (or the rect/scroll position of an ancestor changes).
    virtual void frameRectsChanged() OVERRIDE;

    // Widget override to update our scrollbars and notify our contents of the resize.
    virtual void setFrameRect(const IntRect&) OVERRIDE;

    // For platforms that need to hit test scrollbars from within the engine's event handlers (like Win32).
    Scrollbar* scrollbarAtPoint(const IntPoint& windowPoint);

    virtual IntPoint convertChildToSelf(const Widget* child, const IntPoint& point) const OVERRIDE
    {
        IntPoint newPoint = point;
        if (!isScrollViewScrollbar(child))
            newPoint = point - scrollOffset();
        newPoint.moveBy(child->location());
        return newPoint;
    }

    virtual IntPoint convertSelfToChild(const Widget* child, const IntPoint& point) const OVERRIDE
    {
        IntPoint newPoint = point;
        if (!isScrollViewScrollbar(child))
            newPoint = point + scrollOffset();
        newPoint.moveBy(-child->location());
        return newPoint;
    }

    // Widget override. Handles painting of the contents of the view as well as the scrollbars.
    virtual void paint(GraphicsContext*, const IntRect&) OVERRIDE;
    void paintScrollbars(GraphicsContext*, const IntRect&);

    // Widget overrides to ensure that our children's visibility status is kept up to date when we get shown and hidden.
    virtual void show() OVERRIDE;
    virtual void hide() OVERRIDE;
    virtual void setParentVisible(bool) OVERRIDE;

    virtual bool isPointInScrollbarCorner(const IntPoint&);
    virtual bool scrollbarCornerPresent() const;
    virtual IntRect scrollCornerRect() const OVERRIDE;
    virtual void paintScrollCorner(GraphicsContext*, const IntRect& cornerRect);
    virtual void paintScrollbar(GraphicsContext*, Scrollbar*, const IntRect&);

    virtual IntRect convertFromScrollbarToContainingView(const Scrollbar*, const IntRect&) const OVERRIDE;
    virtual IntRect convertFromContainingViewToScrollbar(const Scrollbar*, const IntRect&) const OVERRIDE;
    virtual IntPoint convertFromScrollbarToContainingView(const Scrollbar*, const IntPoint&) const OVERRIDE;
    virtual IntPoint convertFromContainingViewToScrollbar(const Scrollbar*, const IntPoint&) const OVERRIDE;

    void calculateAndPaintOverhangAreas(GraphicsContext*, const IntRect& dirtyRect);
    void calculateAndPaintOverhangBackground(GraphicsContext*, const IntRect& dirtyRect);

    virtual bool isScrollView() const OVERRIDE FINAL { return true; }

protected:
    ScrollView();

    virtual void contentRectangleForPaintInvalidation(const IntRect&);
    virtual void paintContents(GraphicsContext*, const IntRect& damageRect) = 0;

    virtual void paintOverhangAreas(GraphicsContext*, const IntRect& horizontalOverhangArea, const IntRect& verticalOverhangArea, const IntRect& dirtyRect);

    virtual void scrollbarExistenceDidChange() = 0;
    // These functions are used to create/destroy scrollbars.
    void setHasHorizontalScrollbar(bool);
    void setHasVerticalScrollbar(bool);

    virtual void updateScrollCorner();
    virtual void invalidateScrollCornerRect(const IntRect&) OVERRIDE;

    virtual void scrollContentsIfNeeded();
    // Scroll the content by via the compositor.
    virtual bool scrollContentsFastPath(const IntSize& scrollDelta) { return true; }
    // Scroll the content by invalidating everything.
    virtual void scrollContentsSlowPath(const IntRect& updateRect);

    void setScrollOrigin(const IntPoint&, bool updatePositionAtAll, bool updatePositionSynchronously);

    // Subclassed by FrameView to check the writing-mode of the document.
    virtual bool isVerticalDocument() const { return true; }
    virtual bool isFlippedDocument() const { return false; }

    enum ComputeScrollbarExistenceOption {
        FirstPass,
        Incremental
    };
    void computeScrollbarExistence(bool& newHasHorizontalScrollbar, bool& newHasVerticalScrollbar, const IntSize& docSize, ComputeScrollbarExistenceOption = FirstPass) const;
    void updateScrollbarGeometry();

    // Called to update the scrollbars to accurately reflect the state of the view.
    void updateScrollbars(const IntSize& desiredOffset);

    IntSize excludeScrollbars(const IntSize&) const;

    class InUpdateScrollbarsScope {
    public:
        explicit InUpdateScrollbarsScope(ScrollView* view)
            : m_scope(view->m_inUpdateScrollbars, true)
        { }
    private:
        TemporaryChange<bool> m_scope;
    };

private:
    bool adjustScrollbarExistence(ComputeScrollbarExistenceOption = FirstPass);
    void adjustScrollbarOpacity();

    RefPtr<Scrollbar> m_horizontalScrollbar;
    RefPtr<Scrollbar> m_verticalScrollbar;
    ScrollbarMode m_horizontalScrollbarMode;
    ScrollbarMode m_verticalScrollbarMode;

    bool m_horizontalScrollbarLock;
    bool m_verticalScrollbarLock;

    HashSet<RefPtr<Widget> > m_children;

    IntSize m_pendingScrollDelta;
    IntSize m_scrollOffset; // FIXME: Would rather store this as a position, but we will wait to make this change until more code is shared.
    IntPoint m_cachedScrollPosition;
    IntSize m_contentsSize;

    bool m_scrollbarsSuppressed;

    bool m_inUpdateScrollbars;

    bool m_paintsEntireContents;
    bool m_clipsRepaints;

    void init();
    void destroy();

    IntRect rectToCopyOnScroll() const;

    void calculateOverhangAreasForPainting(IntRect& horizontalOverhangRect, IntRect& verticalOverhangRect);
    void updateOverhangAreas();
}; // class ScrollView

DEFINE_TYPE_CASTS(ScrollView, Widget, widget, widget->isScrollView(), widget.isScrollView());

} // namespace blink

#endif // ScrollView_h
