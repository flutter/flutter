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

#ifndef SKY_ENGINE_CORE_FRAME_FRAMEVIEW_H_
#define SKY_ENGINE_CORE_FRAME_FRAMEVIEW_H_

#include "gen/sky/platform/RuntimeEnabledFeatures.h"
#include "sky/engine/core/rendering/PaintPhase.h"
#include "sky/engine/platform/HostWindow.h"
#include "sky/engine/platform/Widget.h"
#include "sky/engine/platform/geometry/LayoutRect.h"
#include "sky/engine/platform/graphics/Color.h"
#include "sky/engine/platform/scroll/ScrollableArea.h"
#include "sky/engine/wtf/Forward.h"
#include "sky/engine/wtf/HashSet.h"
#include "sky/engine/wtf/OwnPtr.h"
#include "sky/engine/wtf/text/WTFString.h"

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

typedef unsigned long long DOMTimeStamp;

class FrameView final : public Widget {
public:
    friend class RenderView;

    static PassRefPtr<FrameView> create(LocalFrame*);
    static PassRefPtr<FrameView> create(LocalFrame*, const IntSize& initialSize);

    virtual ~FrameView();

    virtual HostWindow* hostWindow() const override;
    virtual void invalidateRect(const IntRect&) override;
    virtual void setFrameRect(const IntRect&) override;

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

    // Methods for getting/setting the size Blink should use to layout the contents.
    // FIXME(sky): Remove the scrollbars argument now that FrameView doesn't scroll.
    IntSize layoutSize(IncludeScrollbarsInRect = ExcludeScrollbars) const;
    void setLayoutSize(const IntSize&);

    // If this is set to false, the layout size will need to be explicitly set by the owner.
    // E.g. WebViewImpl sets its mainFrame's layout size manually
    void setLayoutSizeFixedToFrameSize(bool isFixed) { m_layoutSizeFixedToFrameSize = isFixed; }
    bool layoutSizeFixedToFrameSize() { return m_layoutSizeFixedToFrameSize; }

    bool needsFullPaintInvalidation() const { return m_doFullPaintInvalidation; }

    void recalcOverflowAfterStyleChange();

    bool isEnclosedInCompositingLayer() const;

    void prepareForDetach();

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

    AtomicString mediaType() const;
    void setMediaType(const AtomicString&);

    void postLayoutTimerFired(Timer<FrameView>*);

    void paint(GraphicsContext* context, const IntRect& rect) override;

    void paintContents(GraphicsContext*, const IntRect& damageRect);
    bool isPainting() const;
    bool hasEverPainted() const { return m_lastPaintTime; }
    void setNodeToDraw(Node*);

    Color documentBackgroundColor() const;

    static double currentFrameTimeStamp() { return s_currentFrameTimeStamp; }

    void updateLayoutAndStyleForPainting();
    void updateLayoutAndStyleIfNeededRecursive();

    void forceLayout(bool allowSubtree = false);

    // Methods to convert points and rects between the coordinate space of the renderer, and this view.
    IntRect convertFromRenderer(const RenderObject&, const IntRect&) const;
    IntRect convertToRenderer(const RenderObject&, const IntRect&) const;
    IntPoint convertFromRenderer(const RenderObject&, const IntPoint&) const;
    IntPoint convertToRenderer(const RenderObject&, const IntPoint&) const;

    bool shouldSetCursor() const;

    void setCursor(const Cursor&);

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

    // This function exists for ports that need to handle wheel events manually.
    // On Mac WebKit1 the underlying NSScrollView just does the scrolling, but on most other platforms
    // we need this function in order to do the scroll ourselves.
    bool wheelEvent(const PlatformWheelEvent&);

    void setHasSoftwareFilters(bool hasSoftwareFilters) { m_hasSoftwareFilters = hasSoftwareFilters; }
    bool hasSoftwareFilters() const { return m_hasSoftwareFilters; }

    bool isActive() const;

    // FIXME: This should probably be renamed as the 'inSubtreeLayout' parameter
    // passed around the FrameView layout methods can be true while this returns
    // false.
    bool isSubtreeLayout() const { return !!m_layoutSubtreeRoot; }

    // FIXME(sky): remove
    IntPoint windowToContents(const IntPoint& windowPoint) const { return windowPoint; }
    IntPoint contentsToWindow(const IntPoint& contentsPoint) const { return contentsPoint; }
    IntRect windowToContents(const IntRect& windowRect) const { return windowRect; }
    IntRect contentsToWindow(const IntRect& contentsRect) const { return contentsRect; }

    bool scheduleAnimation();
    IntRect visibleContentRect(IncludeScrollbarsInRect = ExcludeScrollbars) const { return IntRect(IntPoint(), expandedIntSize(frameRect().size())); }
    IntSize unscaledVisibleContentSize(IncludeScrollbarsInRect = ExcludeScrollbars) const { return frameRect().size(); }
    // FIXME(sky): Not clear what values these should return. This is just what they happen to be
    // returning today.
    bool paintsEntireContents() const { return false; }
    bool clipsPaintInvalidations() const { return true; }

    // For inspector reporting:
    void countObjectsNeedingLayout(unsigned& needsLayoutObjects, unsigned& totalObjects, bool& isPartial);

protected:
    bool isVerticalDocument() const;
    bool isFlippedDocument() const;

private:
    explicit FrameView(LocalFrame*);

    void reset();
    void init();

    virtual bool isFrameView() const override { return true; }

    void forceLayoutParentViewIfNeeded();
    void performPreLayoutTasks();
    void performLayout(RenderObject* rootForThisLayout, bool inSubtreeLayout);
    void scheduleOrPerformPostLayoutTasks();
    void performPostLayoutTasks();

    void invalidateTreeIfNeeded();

    DocumentLifecycle& lifecycle() const;

    // FIXME(sky): Remove now that we're not a ScrollView?
    void contentRectangleForPaintInvalidation(const IntRect&);
    void contentsResized();

    bool wasViewportResized();
    void sendResizeEventIfNeeded();

    void setLayoutSizeInternal(const IntSize&);

    bool paintInvalidationIsAllowed() const
    {
        return !isInPerformLayout() || canInvalidatePaintDuringPerformLayout();
    }

    static double s_currentFrameTimeStamp; // used for detecting decoded resource thrash in the cache
    static bool s_inPaintContents;

    LayoutSize m_size;

    RefPtr<LocalFrame> m_frame;

    bool m_doFullPaintInvalidation;

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

    AtomicString m_mediaType;

    bool m_overflowStatusDirty;
    bool m_horizontalOverflow;
    bool m_verticalOverflow;
    RenderObject* m_viewportRenderer;

    double m_lastPaintTime;

    bool m_isTrackingPaintInvalidations; // Used for testing.
    Vector<IntRect> m_trackedPaintInvalidationRects;

    RefPtr<Node> m_nodeToDraw;
    bool m_isPainting;

    OwnPtr<ScrollableAreaSet> m_scrollableAreas;

    bool m_hasSoftwareFilters;

    float m_visibleContentScaleFactor;
    IntSize m_inputEventsOffsetForEmulation;
    float m_inputEventsScaleFactorForEmulation;

    IntSize m_layoutSize;
    bool m_layoutSizeFixedToFrameSize;

    Vector<IntRect> m_tickmarks;
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

#endif  // SKY_ENGINE_CORE_FRAME_FRAMEVIEW_H_
