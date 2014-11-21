/*
 * Copyright (C) 2003, 2009, 2012 Apple Inc. All rights reserved.
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

#ifndef SKY_ENGINE_CORE_RENDERING_RENDERLAYERSCROLLABLEAREA_H_
#define SKY_ENGINE_CORE_RENDERING_RENDERLAYERSCROLLABLEAREA_H_

#include "sky/engine/platform/scroll/ScrollableArea.h"

namespace blink {

class PlatformEvent;
class RenderBox;
class RenderLayer;

class RenderLayerScrollableArea final : public ScrollableArea {
public:
    // FIXME: We should pass in the RenderBox but this opens a window
    // for crashers during RenderLayer setup (see crbug.com/368062).
    RenderLayerScrollableArea(RenderLayer&);
    virtual ~RenderLayerScrollableArea();

    bool hasHorizontalScrollbar() const { return horizontalScrollbar(); }
    bool hasVerticalScrollbar() const { return verticalScrollbar(); }

    Scrollbar* horizontalScrollbar() const override { return m_hBar.get(); }
    Scrollbar* verticalScrollbar() const override { return m_vBar.get(); }

    HostWindow* hostWindow() const override;

    void invalidateScrollbarRect(Scrollbar*, const IntRect&) override;
    bool isActive() const override;
    IntRect scrollCornerRect() const;
    IntRect convertFromScrollbarToContainingView(const Scrollbar*, const IntRect&) const override;
    IntRect convertFromContainingViewToScrollbar(const Scrollbar*, const IntRect&) const override;
    IntPoint convertFromScrollbarToContainingView(const Scrollbar*, const IntPoint&) const override;
    IntPoint convertFromContainingViewToScrollbar(const Scrollbar*, const IntPoint&) const override;
    int scrollSize(ScrollbarOrientation) const override;
    void setScrollOffset(const IntPoint&) override;
    IntPoint scrollPosition() const override;
    IntPoint minimumScrollPosition() const override;
    IntPoint maximumScrollPosition() const override;
    IntRect visibleContentRect(IncludeScrollbarsInRect) const;
    int visibleHeight() const;
    int visibleWidth() const;
    IntSize contentsSize() const override;
    IntSize overhangAmount() const;
    IntPoint lastKnownMousePosition() const;
    IntRect scrollableAreaBoundingBox() const;
    bool userInputScrollable(ScrollbarOrientation) const override;
    bool shouldPlaceVerticalScrollbarOnLeft() const override;
    int pageStep(ScrollbarOrientation) const override;

    int scrollXOffset() const { return m_scrollOffset.width() + scrollOrigin().x(); }
    int scrollYOffset() const { return m_scrollOffset.height() + scrollOrigin().y(); }

    IntSize scrollOffset() const { return m_scrollOffset; }

    // FIXME: We shouldn't allow access to m_overflowRect outside this class.
    LayoutRect overflowRect() const { return m_overflowRect; }

    void scrollToOffset(const IntSize& scrollOffset, ScrollOffsetClamping = ScrollOffsetUnclamped);
    void scrollToXOffset(int x, ScrollOffsetClamping clamp = ScrollOffsetUnclamped) { scrollToOffset(IntSize(x, scrollYOffset()), clamp); }
    void scrollToYOffset(int y, ScrollOffsetClamping clamp = ScrollOffsetUnclamped) { scrollToOffset(IntSize(scrollXOffset(), y), clamp); }

    void updateAfterLayout();
    void updateAfterStyleChange(const RenderStyle*);
    void updateAfterOverflowRecalc();

    bool updateAfterCompositingChange() override;

    bool hasScrollbar() const { return m_hBar || m_vBar; }

    LayoutUnit scrollWidth() const;
    LayoutUnit scrollHeight() const;
    int pixelSnappedScrollWidth() const;
    int pixelSnappedScrollHeight() const;

    IntSize adjustedScrollOffset() const { return IntSize(scrollXOffset(), scrollYOffset()); }

    void paintOverflowControls(GraphicsContext*, const IntPoint& paintOffset, const IntRect& damageRect, bool paintingOverlayControls);
    void positionOverflowControls(const IntSize& offsetFromRoot);

    LayoutRect exposeRect(const LayoutRect&, const ScrollAlignment& alignX, const ScrollAlignment& alignY);

    // Returns true our scrollable area is in the FrameView's collection of scrollable areas. This can
    // only happen if we're both scrollable, and we do in fact overflow. This means that overflow: hidden
    // layers never get added to the FrameView's collection.
    bool scrollsOverflow() const { return m_scrollsOverflow; }

    void updateNeedsCompositedScrolling();
    bool needsCompositedScrolling() const { return m_needsCompositedScrolling; }

    // These are used during compositing updates to determine if the overflow
    // controls need to be repositioned in the GraphicsLayer tree.
    void setTopmostScrollChild(RenderLayer*);
    RenderLayer* topmostScrollChild() const { ASSERT(!m_nextTopmostScrollChild); return m_topmostScrollChild; }

private:
    bool hasHorizontalOverflow() const;
    bool hasVerticalOverflow() const;
    bool hasScrollableHorizontalOverflow() const;
    bool hasScrollableVerticalOverflow() const;

    void computeScrollDimensions();

    IntSize clampScrollOffset(const IntSize&) const;

    void setScrollOffset(const IntSize& scrollOffset) { m_scrollOffset = scrollOffset; }

    IntRect rectForHorizontalScrollbar(const IntRect& borderBoxRect) const;
    IntRect rectForVerticalScrollbar(const IntRect& borderBoxRect) const;
    LayoutUnit verticalScrollbarStart(int minX, int maxX) const;
    LayoutUnit horizontalScrollbarStart(int minX) const;
    IntSize scrollbarOffset(const Scrollbar*) const;

    PassRefPtr<Scrollbar> createScrollbar(ScrollbarOrientation);
    void destroyScrollbar(ScrollbarOrientation);

    void setHasHorizontalScrollbar(bool hasScrollbar);
    void setHasVerticalScrollbar(bool hasScrollbar);

    bool overflowControlsIntersectRect(const IntRect& localRect) const;

    RenderBox& box() const;
    RenderLayer* layer() const;

    void updateScrollableAreaSet(bool hasOverflow);

    void updateCompositingLayersAfterScroll();

    RenderLayer& m_layer;

    unsigned m_scrollsOverflow : 1;

    unsigned m_scrollDimensionsDirty : 1;
    unsigned m_inOverflowRelayout : 1;

    RenderLayer* m_nextTopmostScrollChild;
    RenderLayer* m_topmostScrollChild;

    // FIXME: once cc can handle composited scrolling with clip paths, we will
    // no longer need this bit.
    unsigned m_needsCompositedScrolling : 1;

    // The width/height of our scrolled area.
    LayoutRect m_overflowRect;

    // This is the (scroll) offset from scrollOrigin().
    IntSize m_scrollOffset;

    IntPoint m_cachedOverlayScrollbarOffset;

    // For areas with overflow, we have a pair of scrollbars.
    RefPtr<Scrollbar> m_hBar;
    RefPtr<Scrollbar> m_vBar;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_RENDERING_RENDERLAYERSCROLLABLEAREA_H_
