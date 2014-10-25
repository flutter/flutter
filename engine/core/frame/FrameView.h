/*
   Copyright (C) 1997 Martin Jones (mjones@kde.org)
             (C) 1998 Waldo Bastian (bastian@kde.org)
             (C) 1998, 1999 Torben Weis (weis@kde.org)
             (C) 1999 Lars Knoll (knoll@kde.org)
             (C) 1999 Antti Koivisto (koivisto@kde.org)
   Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009 Apple Inc. All rights reserved.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public License
   along with this library; see the file COPYING.LIB.  If not, write to
   the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.
*/

#ifndef FrameView_h
#define FrameView_h

#include "core/rendering/PaintPhase.h"
#include "platform/FrameWidget.h"
#include "platform/HostWindow.h"
#include "platform/RuntimeEnabledFeatures.h"
#include "platform/Widget.h"
#include "platform/Widget.h"
#include "platform/geometry/LayoutRect.h"
#include "platform/graphics/Color.h"
#include "platform/scroll/ScrollableArea.h"
#include "wtf/Forward.h"
#include "wtf/OwnPtr.h"
#include "wtf/text/WTFString.h"

namespace blink {

class DocumentLifecycle;
class Cursor;
class Element;
class FloatSize;
class LocalFrame;
class KURL;
class Node;
class Page;
class RenderBox;
class RenderObject;
class RenderStyle;
class RenderView;
class RenderWidget;

typedef unsigned long long DOMTimeStamp;

class FrameView final : public FrameWidget {
public:
    friend class RenderView;

    static PassRefPtr<FrameView> create(LocalFrame*);
    static PassRefPtr<FrameView> create(LocalFrame*, const IntSize& initialSize);

    virtual ~FrameView();

    HostWindow* hostWindow() const;

    void invalidateRect(const IntRect&);
    void setFrameRect(const IntRect&);

    LocalFrame& frame() const { return *m_frame; }
    Page* page() const;

    RenderView* renderView() const;

    IntPoint clampOffsetAtScale(const IntPoint& offset, float scale) const;

    void layout(bool allowSubtree = true);
    bool didFirstLayout() const;
    void scheduleRelayout();
    void scheduleRelayoutOfSubtree(RenderObject*);
    bool layoutPending() const;
    bool isInPerformLayout() const;

    void setCanInvalidatePaintDuringPerformLayout(bool b) { m_canInvalidatePaintDuringPerformLayout = b; }
    bool canInvalidatePaintDuringPerformLayout() const { return m_canInvalidatePaintDuringPerformLayout; }

    RenderObject* layoutRoot(bool onlyDuringLayout = false) const;
    void clearLayoutSubtreeRoot() { m_layoutSubtreeRoot = 0; }
    int layoutCount() const { return m_layoutCount; }

    bool needsLayout() const;
    void setNeedsLayout();

    void setNeedsUpdateWidgetPositions() { m_needsUpdateWidgetPositions = true; }

    // Methods for getting/setting the size Blink should use to layout the contents.
    IntSize layoutSize(IncludeScrollbarsInRect = ExcludeScrollbars) const;
    void setLayoutSize(const IntSize&);

    // If this is set to false, the layout size will need to be explicitly set by the owner.
    // E.g. WebViewImpl sets its mainFrame's layout size manually
    void setLayoutSizeFixedToFrameSize(bool isFixed) { m_layoutSizeFixedToFrameSize = isFixed; }
    bool layoutSizeFixedToFrameSize() { return m_layoutSizeFixedToFrameSize; }

    bool needsFullPaintInvalidation() const { return m_doFullPaintInvalidation; }

    void updateAcceleratedCompositingSettings();

    void recalcOverflowAfterStyleChange();

    bool isEnclosedInCompositingLayer() const;

    void prepareForDetach();
    virtual void recalculateScrollbarOverlayStyle();

    void clear();

    bool isTransparent() const;
    void setTransparent(bool isTransparent);

    // True if the FrameView is not transparent, and the base background color is opaque.
    bool hasOpaqueBackground() const;

    Color baseBackgroundColor() const;
    void setBaseBackgroundColor(const Color&);
    void updateBackgroundRecursively(const Color&, bool);

    IntRect windowClipRect(IncludeScrollbarsInRect = ExcludeScrollbars) const;

    float visibleContentScaleFactor() const { return m_visibleContentScaleFactor; }
    void setVisibleContentScaleFactor(float);

    float inputEventsScaleFactor() const;
    IntSize inputEventsOffsetForEmulation() const;
    void setInputEventsTransformForEmulation(const IntSize&, float);

    // This is different than visibleContentRect() in that it ignores negative (or overly positive)
    // offsets from rubber-banding, and it takes zooming into account.
    LayoutRect viewportConstrainedVisibleContentRect() const;
    void viewportConstrainedVisibleContentSizeChanged(bool widthChanged, bool heightChanged);

    AtomicString mediaType() const;
    void setMediaType(const AtomicString&);

    void addSlowRepaintObject();
    void removeSlowRepaintObject();
    bool hasSlowRepaintObjects() const { return m_slowRepaintObjectCount; }

    // Fixed-position objects.
    typedef HashSet<RenderObject*> ViewportConstrainedObjectSet;
    void addViewportConstrainedObject(RenderObject*);
    void removeViewportConstrainedObject(RenderObject*);
    const ViewportConstrainedObjectSet* viewportConstrainedObjects() const { return m_viewportConstrainedObjects.get(); }
    bool hasViewportConstrainedObjects() const { return m_viewportConstrainedObjects && m_viewportConstrainedObjects->size() > 0; }

    void restoreScrollbar();

    void postLayoutTimerFired(Timer<FrameView>*);

    bool wasScrolledByUser() const;
    void setWasScrolledByUser(bool);

    void addWidget(RenderWidget*);
    void removeWidget(RenderWidget*);
    void updateWidgetPositions();

    void paintContents(GraphicsContext*, const IntRect& damageRect);
    void setPaintBehavior(PaintBehavior);
    PaintBehavior paintBehavior() const;
    bool isPainting() const;
    bool hasEverPainted() const { return m_lastPaintTime; }
    void setNodeToDraw(Node*);

    // FIXME(sky): Remove
    void paintOverhangAreas(GraphicsContext*, const IntRect& horizontalOverhangArea, const IntRect& verticalOverhangArea, const IntRect& dirtyRect);

    Color documentBackgroundColor() const;

    static double currentFrameTimeStamp() { return s_currentFrameTimeStamp; }

    void updateLayoutAndStyleForPainting();
    void updateLayoutAndStyleIfNeededRecursive();

    void invalidateTreeIfNeededRecursive();

    void forceLayout(bool allowSubtree = false);

    void scrollContentsIfNeededRecursive();

    // Methods to convert points and rects between the coordinate space of the renderer, and this view.
    IntRect convertFromRenderer(const RenderObject&, const IntRect&) const;
    IntRect convertToRenderer(const RenderObject&, const IntRect&) const;
    IntPoint convertFromRenderer(const RenderObject&, const IntPoint&) const;
    IntPoint convertToRenderer(const RenderObject&, const IntPoint&) const;

    bool isScrollable();

    enum ScrollbarModesCalculationStrategy { RulesFromWebContentOnly, AnyRule };
    void calculateScrollbarModesForLayoutAndSetViewportRenderer(ScrollbarMode& hMode, ScrollbarMode& vMode, ScrollbarModesCalculationStrategy = AnyRule);

    // FIXME(sky): Maybe remove now that we're not a ScrollView?
    IntPoint lastKnownMousePosition() const;
    bool shouldSetCursor() const;

    void setCursor(const Cursor&);

    // FIXME(sky): Remove
    bool scrollbarsCanBeActive() const;

    // FIXME: Remove this method once plugin loading is decoupled from layout.
    void flushAnyPendingPostLayoutTasks();

    void setTracksPaintInvalidations(bool);
    bool isTrackingPaintInvalidations() const { return m_isTrackingPaintInvalidations; }
    void resetTrackedPaintInvalidations();

    String trackedPaintInvalidationRectsAsText() const;

    typedef HashSet<ScrollableArea*> ScrollableAreaSet;
    void addScrollableArea(ScrollableArea*);
    void removeScrollableArea(ScrollableArea*);
    const ScrollableAreaSet* scrollableAreas() const { return m_scrollableAreas.get(); }

    // With CSS style "resize:" enabled, a little resizer handle will appear at the bottom
    // right of the object. We keep track of these resizer areas for checking if touches
    // (implemented using Scroll gesture) are targeting the resizer.
    typedef HashSet<RenderBox*> ResizerAreaSet;
    void addResizerArea(RenderBox&);
    void removeResizerArea(RenderBox&);
    const ResizerAreaSet* resizerAreas() const { return m_resizerAreas.get(); }

    void addChild(PassRefPtr<Widget>);
    void removeChild(Widget*) final;

    // This function exists for ports that need to handle wheel events manually.
    // On Mac WebKit1 the underlying NSScrollView just does the scrolling, but on most other platforms
    // we need this function in order to do the scroll ourselves.
    bool wheelEvent(const PlatformWheelEvent&);

    bool inProgrammaticScroll() const { return m_inProgrammaticScroll; }
    void setInProgrammaticScroll(bool programmaticScroll) { m_inProgrammaticScroll = programmaticScroll; }

    void setHasSoftwareFilters(bool hasSoftwareFilters) { m_hasSoftwareFilters = hasSoftwareFilters; }
    bool hasSoftwareFilters() const { return m_hasSoftwareFilters; }

    bool isActive() const;

    // DEPRECATED: Use viewportConstrainedVisibleContentRect() instead.
    IntSize scrollOffsetForFixedPosition() const;

    // FIXME: This should probably be renamed as the 'inSubtreeLayout' parameter
    // passed around the FrameView layout methods can be true while this returns
    // false.
    bool isSubtreeLayout() const { return !!m_layoutSubtreeRoot; }

    // Sets the tickmarks for the FrameView, overriding the default behavior
    // which is to display the tickmarks corresponding to find results.
    // If |m_tickmarks| is empty, the default behavior is restored.
    void setTickmarks(const Vector<IntRect>& tickmarks) { m_tickmarks = tickmarks; }

    // ScrollableArea interface
    // FIXME(sky): Remove
    void invalidateScrollbarRect(Scrollbar*, const IntRect&);
    void getTickmarks(Vector<IntRect>&) const;
    IntRect scrollableAreaBoundingBox() const;
    bool scrollAnimatorEnabled() const;
    bool usesCompositedScrolling() const;
    GraphicsLayer* layerForScrolling() const;
    GraphicsLayer* layerForHorizontalScrollbar() const;
    GraphicsLayer* layerForVerticalScrollbar() const;
    GraphicsLayer* layerForScrollCorner() const;

    // FIXME(sky): remove
    IntRect contentsToScreen(const IntRect& rect) const;
    IntPoint contentsToRootView(const IntPoint& contentsPoint) const { return convertToRootView(contentsPoint); }
    IntRect contentsToRootView(const IntRect& contentsRect) const { return convertToRootView(contentsRect); }
    IntRect rootViewToContents(const IntRect& rootViewRect) const { return convertFromRootView(rootViewRect); }
    IntPoint windowToContents(const IntPoint& windowPoint) const { return convertFromContainingWindow(windowPoint); }
    FloatPoint windowToContents(const FloatPoint& windowPoint) const { return convertFromContainingWindow(windowPoint); }
    IntPoint contentsToWindow(const IntPoint& contentsPoint) const { return contentsToWindow(contentsPoint); }
    IntRect windowToContents(const IntRect& windowRect) const { return convertFromContainingWindow(windowRect); }
    IntRect contentsToWindow(const IntRect& contentsRect) const { return contentsToWindow(contentsRect); }
    IntSize scrollOffset() const { return IntSize(); }
    IntPoint minimumScrollPosition() const { return IntPoint(); }
    IntPoint maximumScrollPosition() const { return IntPoint(); }
    IntPoint scrollPosition() const { return IntPoint(); }
    bool scheduleAnimation();
    IntRect visibleContentRect(IncludeScrollbarsInRect = ExcludeScrollbars) const { return IntRect(IntPoint(), expandedIntSize(frameRect().size())); }
    IntSize unscaledVisibleContentSize(IncludeScrollbarsInRect = ExcludeScrollbars) const { return frameRect().size(); }
    IntPoint clampScrollPosition(const IntPoint& scrollPosition) const { return scrollPosition; }
    const IntPoint scrollOrigin() const { return IntPoint(); }
    // FIXME(sky): Not clear what values these should return. This is just what they happen to be
    // returning today.
    bool paintsEntireContents() const { return false; }
    bool clipsPaintInvalidations() const { return true; }

protected:
    virtual void scrollContentsIfNeeded();
    bool scrollContentsFastPath(const IntSize& scrollDelta);
    void scrollContentsSlowPath(const IntRect& updateRect);

    bool isVerticalDocument() const;
    bool isFlippedDocument() const;

private:
    explicit FrameView(LocalFrame*);

    void reset();
    void init();

    virtual void frameRectsChanged() override;
    virtual bool isFrameView() const override { return true; }

    friend class RenderWidget;

    bool contentsInCompositedLayer() const;

    void applyOverflowToViewportAndSetRenderer(RenderObject*, ScrollbarMode& hMode, ScrollbarMode& vMode);
    void updateOverflowStatus(bool horizontalOverflow, bool verticalOverflow);

    void forceLayoutParentViewIfNeeded();
    void performPreLayoutTasks();
    void performLayout(RenderObject* rootForThisLayout, bool inSubtreeLayout);
    void scheduleOrPerformPostLayoutTasks();
    void performPostLayoutTasks();

    void invalidateTreeIfNeeded();

    void gatherDebugLayoutRects(RenderObject* layoutRoot);

    DocumentLifecycle& lifecycle() const;

    // FIXME(sky): Remove now that we're not a ScrollView?
    void contentRectangleForPaintInvalidation(const IntRect&);
    void contentsResized();
    void scrollbarExistenceDidChange();

    // Override ScrollView methods to do point conversion via renderers, in order to
    // take transforms into account.
    virtual IntRect convertToContainingView(const IntRect&) const override;
    virtual IntRect convertFromContainingView(const IntRect&) const override;
    virtual IntPoint convertToContainingView(const IntPoint&) const override;
    virtual IntPoint convertFromContainingView(const IntPoint&) const override;

    void updateWidgetPositionsIfNeeded();

    bool wasViewportResized();
    void sendResizeEventIfNeeded();

    // FIXME(sky): Remove now that we're not a ScrollView?
    void notifyPageThatContentAreaWillPaint() const;

    void scrollPositionChanged();
    void didScrollTimerFired(Timer<FrameView>*);

    void updateLayersAndCompositingAfterScrollIfNeeded();
    void updateFixedElementPaintInvalidationRectsAfterScroll();
    void updateCompositedSelectionBoundsIfNeeded();

    void setLayoutSizeInternal(const IntSize&);

    bool paintInvalidationIsAllowed() const
    {
        return !isInPerformLayout() || canInvalidatePaintDuringPerformLayout();
    }

    static double s_currentFrameTimeStamp; // used for detecting decoded resource thrash in the cache
    static bool s_inPaintContents;

    LayoutSize m_size;

    // FIXME: These are just "children" of the FrameView and should be RefPtr<Widget> instead.
    WillBePersistentHeapHashSet<RefPtrWillBeMember<RenderWidget> > m_widgets;

    RefPtr<LocalFrame> m_frame;
    HashSet<RefPtr<Widget> > m_children;

    bool m_doFullPaintInvalidation;

    // FIXME(sky): Remove
    bool m_canHaveScrollbars;
    unsigned m_slowRepaintObjectCount;

    bool m_hasPendingLayout;
    RenderObject* m_layoutSubtreeRoot;

    bool m_layoutSchedulingEnabled;
    bool m_inPerformLayout;
    bool m_canInvalidatePaintDuringPerformLayout;
    bool m_inSynchronousPostLayout;
    int m_layoutCount;
    unsigned m_nestedLayoutCount;
    Timer<FrameView> m_postLayoutTasksTimer;
    bool m_firstLayoutCallbackPending;

    bool m_firstLayout;
    bool m_isTransparent;
    Color m_baseBackgroundColor;
    IntSize m_lastViewportSize;
    float m_lastZoomFactor;

    AtomicString m_mediaType;

    bool m_overflowStatusDirty;
    bool m_horizontalOverflow;
    bool m_verticalOverflow;
    RenderObject* m_viewportRenderer;

    bool m_wasScrolledByUser;
    bool m_inProgrammaticScroll;

    double m_lastPaintTime;

    bool m_isTrackingPaintInvalidations; // Used for testing.
    Vector<IntRect> m_trackedPaintInvalidationRects;

    RefPtrWillBePersistent<Node> m_nodeToDraw;
    PaintBehavior m_paintBehavior;
    bool m_isPainting;

    OwnPtr<ScrollableAreaSet> m_scrollableAreas;
    OwnPtr<ResizerAreaSet> m_resizerAreas;
    OwnPtr<ViewportConstrainedObjectSet> m_viewportConstrainedObjects;

    bool m_hasSoftwareFilters;

    float m_visibleContentScaleFactor;
    IntSize m_inputEventsOffsetForEmulation;
    float m_inputEventsScaleFactorForEmulation;

    IntSize m_layoutSize;
    bool m_layoutSizeFixedToFrameSize;

    Timer<FrameView> m_didScrollTimer;

    Vector<IntRect> m_tickmarks;

    bool m_needsUpdateWidgetPositions;
};

DEFINE_TYPE_CASTS(FrameView, Widget, widget, widget->isFrameView(), widget.isFrameView());

class AllowPaintInvalidationScope {
public:
    explicit AllowPaintInvalidationScope(FrameView* view)
        : m_view(view)
        , m_originalValue(view ? view->canInvalidatePaintDuringPerformLayout() : false)
    {
        if (!m_view)
            return;

        m_view->setCanInvalidatePaintDuringPerformLayout(true);
    }

    ~AllowPaintInvalidationScope()
    {
        if (!m_view)
            return;

        m_view->setCanInvalidatePaintDuringPerformLayout(m_originalValue);
    }
private:
    FrameView* m_view;
    bool m_originalValue;
};

} // namespace blink

#endif // FrameView_h
