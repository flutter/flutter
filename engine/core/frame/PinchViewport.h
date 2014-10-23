/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef PinchViewport_h
#define PinchViewport_h

#include "platform/geometry/FloatPoint.h"
#include "platform/geometry/FloatRect.h"
#include "platform/geometry/IntSize.h"
#include "platform/graphics/GraphicsLayerClient.h"
#include "platform/scroll/ScrollableArea.h"
#include "public/platform/WebScrollbar.h"
#include "public/platform/WebSize.h"
#include "wtf/OwnPtr.h"
#include "wtf/PassOwnPtr.h"

namespace blink {
class WebLayerTreeView;
class WebScrollbarLayer;
}

namespace blink {

class FrameHost;
class GraphicsContext;
class GraphicsLayer;
class GraphicsLayerFactory;
class IntRect;
class IntSize;
class LocalFrame;

// Represents the pinch-to-zoom viewport the user is currently seeing the page through. This
// class corresponds to the InnerViewport on the compositor. It is a ScrollableArea; it's
// offset is set through the GraphicsLayer <-> CC sync mechanisms. Its contents is the page's
// main FrameView, which corresponds to the outer viewport. The inner viewport is always contained
// in the outer viewport and can pan within it.
class PinchViewport FINAL : public GraphicsLayerClient, public ScrollableArea {
public:
    explicit PinchViewport(FrameHost&);
    virtual ~PinchViewport();

    void attachToLayerTree(GraphicsLayer*, GraphicsLayerFactory*);
    GraphicsLayer* rootGraphicsLayer()
    {
        return m_rootTransformLayer.get();
    }
    GraphicsLayer* containerLayer()
    {
        return m_innerViewportContainerLayer.get();
    }

    // Sets the location of the inner viewport relative to the outer viewport. The
    // coordinates are in partial CSS pixels.
    void setLocation(const FloatPoint&);
    void move(const FloatPoint&);

    // Sets the size of the inner viewport when unscaled in CSS pixels.
    // This will be clamped to the size of the outer viewport (the main frame).
    void setSize(const IntSize&);
    IntSize size() const { return m_size; }

    // Resets the viewport to initial state.
    void reset();

    // Let the viewport know that the main frame changed size (either through screen
    // rotation on Android or window resize elsewhere).
    void mainFrameDidChangeSize();

    void setScale(float);
    float scale() const { return m_scale; }

    void registerLayersWithTreeView(blink::WebLayerTreeView*) const;
    void clearLayersForTreeView(blink::WebLayerTreeView*) const;

    // The portion of the unzoomed frame visible in the inner "pinch" viewport,
    // in partial CSS pixels. Relative to the main frame.
    FloatRect visibleRect() const;

    // The viewport rect relative to the document origin, in partial CSS pixels.
    FloatRect visibleRectInDocument() const;

    // Scroll the main frame and pinch viewport so that the given rect in the
    // top-level document is centered in the viewport. This method will avoid
    // scrolling the pinch viewport unless necessary.
    void scrollIntoView(const FloatRect&);
private:
    // ScrollableArea implementation
    virtual bool isActive() const OVERRIDE { return false; }
    virtual int scrollSize(ScrollbarOrientation) const OVERRIDE;
    virtual bool isScrollCornerVisible() const OVERRIDE { return false; }
    virtual IntRect scrollCornerRect() const OVERRIDE { return IntRect(); }
    virtual IntPoint scrollPosition() const OVERRIDE { return flooredIntPoint(m_offset); }
    virtual IntPoint minimumScrollPosition() const OVERRIDE;
    virtual IntPoint maximumScrollPosition() const OVERRIDE;
    virtual int visibleHeight() const OVERRIDE { return visibleRect().height(); };
    virtual int visibleWidth() const OVERRIDE { return visibleRect().width(); };
    virtual IntSize contentsSize() const OVERRIDE;
    virtual bool scrollbarsCanBeActive() const OVERRIDE { return false; }
    virtual IntRect scrollableAreaBoundingBox() const OVERRIDE;
    virtual bool userInputScrollable(ScrollbarOrientation) const OVERRIDE { return true; }
    virtual bool shouldPlaceVerticalScrollbarOnLeft() const OVERRIDE { return false; }
    virtual void invalidateScrollbarRect(Scrollbar*, const IntRect&) OVERRIDE;
    virtual void invalidateScrollCornerRect(const IntRect&) OVERRIDE { }
    virtual void setScrollOffset(const IntPoint&) OVERRIDE;
    virtual GraphicsLayer* layerForContainer() const OVERRIDE;
    virtual GraphicsLayer* layerForScrolling() const OVERRIDE;
    virtual GraphicsLayer* layerForHorizontalScrollbar() const OVERRIDE;
    virtual GraphicsLayer* layerForVerticalScrollbar() const OVERRIDE;

    // GraphicsLayerClient implementation.
    virtual void notifyAnimationStarted(const GraphicsLayer*, double monotonicTime) OVERRIDE;
    virtual void paintContents(const GraphicsLayer*, GraphicsContext&, GraphicsLayerPaintingPhase, const IntRect& inClip) OVERRIDE;
    virtual String debugName(const GraphicsLayer*) OVERRIDE;

    void setupScrollbar(blink::WebScrollbar::Orientation);
    FloatPoint clampOffsetToBoundaries(const FloatPoint&);

    LocalFrame* mainFrame() const;

    FrameHost& m_frameHost;
    OwnPtr<GraphicsLayer> m_rootTransformLayer;
    OwnPtr<GraphicsLayer> m_innerViewportContainerLayer;
    OwnPtr<GraphicsLayer> m_pageScaleLayer;
    OwnPtr<GraphicsLayer> m_innerViewportScrollLayer;
    OwnPtr<GraphicsLayer> m_overlayScrollbarHorizontal;
    OwnPtr<GraphicsLayer> m_overlayScrollbarVertical;
    OwnPtr<blink::WebScrollbarLayer> m_webOverlayScrollbarHorizontal;
    OwnPtr<blink::WebScrollbarLayer> m_webOverlayScrollbarVertical;

    // Offset of the pinch viewport from the main frame's origin, in CSS pixels.
    FloatPoint m_offset;
    float m_scale;
    IntSize m_size;
};

} // namespace blink

#endif // PinchViewport_h
