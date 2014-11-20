/*
 * Copyright (C) 2010 Google Inc. All rights reserved.
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

#ifndef WebViewImpl_h
#define WebViewImpl_h

#include "core/html/ime/InputMethodContext.h"
#include "platform/geometry/IntPoint.h"
#include "platform/geometry/IntRect.h"
#include "platform/graphics/GraphicsLayer.h"
#include "public/platform/WebGestureCurveTarget.h"
#include "public/platform/WebLayer.h"
#include "public/platform/WebPoint.h"
#include "public/platform/WebRect.h"
#include "public/platform/WebSize.h"
#include "public/platform/WebString.h"
#include "public/web/WebInputEvent.h"
#include "public/web/WebNavigationPolicy.h"
#include "public/web/WebView.h"
#include "web/ChromeClientImpl.h"
#include "web/EditorClientImpl.h"
#include "web/PageWidgetDelegate.h"
#include "web/SpellCheckerClientImpl.h"
#include "wtf/OwnPtr.h"
#include "wtf/RefCounted.h"
#include "wtf/Vector.h"

namespace blink {

class Frame;
class LinkHighlight;
class RenderLayerCompositor;
class UserGestureToken;
class WebActiveGestureAnimation;
class WebLocalFrameImpl;
class WebImage;
class WebSettingsImpl;

class WebViewImpl final : public WebView
    , public RefCounted<WebViewImpl>
    , public WebGestureCurveTarget
    , public PageWidgetEventHandler {
public:
    static WebViewImpl* create(WebViewClient*);

    // WebWidget methods:
    virtual void close() override;
    virtual WebSize size() override;
    virtual void willStartLiveResize() override;
    virtual void resize(const WebSize&) override;
    virtual void willEndLiveResize() override;

    virtual void beginFrame(const WebBeginFrameArgs&) override;
    virtual void didCommitFrameToCompositor() override;

    virtual void layout() override;
    virtual void paint(WebCanvas*, const WebRect&) override;
#if OS(ANDROID)
    virtual void paintCompositedDeprecated(WebCanvas*, const WebRect&) override;
#endif
    virtual void compositeAndReadbackAsync(WebCompositeAndReadbackAsyncCallback*) override;
    virtual bool isTrackingRepaints() const override;
    virtual void themeChanged() override;
    virtual bool handleInputEvent(const WebInputEvent&) override;
    virtual void setCursorVisibilityState(bool isVisible) override;
    virtual void mouseCaptureLost() override;
    virtual void setFocus(bool enable) override;
    virtual bool setComposition(
        const WebString& text,
        const WebVector<WebCompositionUnderline>& underlines,
        int selectionStart,
        int selectionEnd) override;
    virtual bool confirmComposition() override;
    virtual bool confirmComposition(ConfirmCompositionBehavior selectionBehavior) override;
    virtual bool confirmComposition(const WebString& text) override;
    virtual bool compositionRange(size_t* location, size_t* length) override;
    virtual WebTextInputInfo textInputInfo() override;
    virtual WebColor backgroundColor() const override;
    virtual bool selectionBounds(WebRect& anchor, WebRect& focus) const override;
    virtual void didShowCandidateWindow() override;
    virtual void didUpdateCandidateWindow() override;
    virtual void didHideCandidateWindow() override;
    virtual bool selectionTextDirection(WebTextDirection& start, WebTextDirection& end) const override;
    virtual bool isSelectionAnchorFirst() const override;
    virtual bool caretOrSelectionRange(size_t* location, size_t* length) override;
    virtual void setTextDirection(WebTextDirection) override;
    virtual bool isAcceleratedCompositingActive() const override;
    virtual void willCloseLayerTreeView() override;

    // WebView methods:
    virtual void setMainFrame(WebFrame*) override;
    virtual void injectModule(const WebString&) override;
    virtual void setSpellCheckClient(WebSpellCheckClient*) override;
    virtual WebSettings* settings() override;
    virtual WebString pageEncoding() const override;
    virtual void setPageEncoding(const WebString&) override;
    virtual bool isTransparent() const override;
    virtual void setIsTransparent(bool value) override;
    virtual void setBaseBackgroundColor(WebColor) override;
    virtual bool tabsToLinks() const override;
    virtual void setTabsToLinks(bool value) override;
    virtual bool tabKeyCyclesThroughElements() const override;
    virtual void setTabKeyCyclesThroughElements(bool value) override;
    virtual bool isActive() const override;
    virtual void setIsActive(bool value) override;
    virtual void setDomainRelaxationForbidden(bool, const WebString& scheme) override;
    virtual void setOpenedByDOM() override;
    virtual WebFrame* mainFrame() override;
    virtual WebFrame* focusedFrame() override;
    virtual void setFocusedFrame(WebFrame*) override;
    virtual void setInitialFocus(bool reverse) override;
    virtual void clearFocusedElement() override;
    virtual void scrollFocusedNodeIntoRect(const WebRect&) override;
    virtual void advanceFocus(bool reverse) override;
    virtual void setMainFrameScrollOffset(const WebPoint&) override;
    virtual void resetScrollAndScaleState() override;
    virtual WebSize contentsPreferredMinimumSize() override;

    virtual float deviceScaleFactor() const override;
    virtual void setDeviceScaleFactor(float) override;

    virtual void setFixedLayoutSize(const WebSize&) override;

    virtual WebHitTestResult hitTestResultAt(const WebPoint&) override;
    virtual void copyImageAt(const WebPoint&) override;
    virtual void saveImageAt(const WebPoint&) override;
    virtual void dragSourceSystemDragEnded() override;
    virtual void spellingMarkers(WebVector<uint32_t>* markers) override;
    virtual void removeSpellingMarkersUnderWords(const WebVector<WebString>& words) override;
    virtual void setCompositorDeviceScaleFactorOverride(float) override;
    virtual void setRootLayerTransform(const WebSize& offset, float scale) override;
    virtual void setSelectionColors(unsigned activeBackgroundColor,
                                    unsigned activeForegroundColor,
                                    unsigned inactiveBackgroundColor,
                                    unsigned inactiveForegroundColor) override;
    virtual void extractSmartClipData(WebRect, WebString&, WebString&, WebRect&) override;
    virtual void transferActiveWheelFlingAnimation(const WebActiveWheelFlingParameters&) override;
    virtual bool endActiveFlingAnimation() override;
    virtual void setShowPaintRects(bool) override;
    void setShowDebugBorders(bool);
    virtual void setShowFPSCounter(bool) override;
    virtual void setContinuousPaintingEnabled(bool) override;
    virtual void setShowScrollBottleneckRects(bool) override;
    virtual void getSelectionRootBounds(WebRect& bounds) const override;
    virtual void acceptLanguagesChanged() override;

    // WebViewImpl

    HitTestResult coreHitTestResultAt(const WebPoint&);
    void suppressInvalidations(bool enable);
    void invalidateRect(const IntRect&);

    void setIgnoreInputEvents(bool newValue);
    void setBackgroundColorOverride(WebColor);

    Color baseBackgroundColor() const { return m_baseBackgroundColor; }

    void setOverlayLayer(GraphicsLayer*);

    const WebPoint& lastMouseDownPoint() const
    {
        return m_lastMouseDownPoint;
    }

    LocalFrame* focusedCoreFrame() const;

    // Returns the currently focused Element or null if no element has focus.
    Element* focusedElement() const;

    static WebViewImpl* fromPage(Page*);

    WebViewClient* client()
    {
        return m_client;
    }

    WebSpellCheckClient* spellCheckClient()
    {
        return m_spellCheckClient;
    }

    // Returns the page object associated with this view. This may be null when
    // the page is shutting down, but will be valid at all other times.
    Page* page() const
    {
        return m_page.get();
    }

    // Returns the main frame associated with this view. This may be null when
    // the page is shutting down, but will be valid at all other times.
    WebLocalFrameImpl* mainFrameImpl();

    // FIXME: Temporary method to accommodate out-of-process frame ancestors;
    // will be removed when there can be multiple WebWidgets for a single page.
    WebLocalFrameImpl* localFrameRootTemporary() const;

    // Event related methods:
    void mouseDoubleClick(const WebMouseEvent&);

    bool detectContentOnTouch(const WebPoint&);

    // WebGestureCurveTarget implementation for fling.
    virtual bool scrollBy(const WebFloatSize& delta, const WebFloatSize& velocity) override;

    // Notifies the WebView that a load has been committed. isNewNavigation
    // will be true if a new session history item should be created for that
    // load. isNavigationWithinPage will be true if the navigation does
    // not take the user away from the current page.
    void didCommitLoad(bool isNewNavigation, bool isNavigationWithinPage);

    // Indicates two things:
    //   1) This view may have a new layout now.
    //   2) Calling layout() is a no-op.
    // After calling WebWidget::layout(), expect to get this notification
    // unless the view did not need a layout.
    void layoutUpdated(WebLocalFrameImpl*);

    void didRemoveAllPendingStylesheet(WebLocalFrameImpl*);

    void updateMainFrameLayoutSize();

    // Returns the input event we're currently processing. This is used in some
    // cases where the WebCore DOM event doesn't have the information we need.
    static const WebInputEvent* currentInputEvent()
    {
        return m_currentInputEvent;
    }

    GraphicsLayer* rootGraphicsLayer();
    void setRootGraphicsLayer(GraphicsLayer*);
    void scheduleCompositingLayerSync();
    GraphicsLayerFactory* graphicsLayerFactory() const;
    RenderLayerCompositor* compositor() const;
    void registerForAnimations(WebLayer*);
    void scheduleAnimation();

    virtual void setVisibilityState(WebPageVisibilityState, bool) override;

    // Returns true if the event leads to scrolling.
    static bool mapKeyCodeForScroll(
        int keyCode,
        ScrollDirection*,
        ScrollGranularity*);

    void computeScaleAndScrollForBlockRect(const WebPoint& hitPoint, const WebRect& blockRect, float padding, float defaultScaleWhenAlreadyLegible, float& scale, WebPoint& scroll);
    Node* bestTapNode(const PlatformGestureEvent& tapEvent);
    void enableTapHighlightAtPoint(const PlatformGestureEvent& tapEvent);
    void enableTapHighlights(Vector<RawPtr<Node> >&);
    void computeScaleAndScrollForFocusedNode(Node* focusedNode, float& scale, IntPoint& scroll, bool& needAnimation);

    void clearCompositedSelectionBounds();

    // Exposed for the purpose of overriding device metrics.
    void sendResizeEventAndRepaint();

    // Exposed for testing purposes.
    bool hasHorizontalScrollbar();
    bool hasVerticalScrollbar();

    // Heuristic-based function for determining if we should disable workarounds
    // for viewing websites that are not optimized for mobile devices.
    bool shouldDisableDesktopWorkarounds();

    // Exposed for tests.
    unsigned numLinkHighlights() { return m_linkHighlights.size(); }
    LinkHighlight* linkHighlight(int i) { return m_linkHighlights[i].get(); }

    WebSettingsImpl* settingsImpl();

    // Returns the bounding box of the block type node touched by the WebRect.
    WebRect computeBlockBounds(const WebRect&, bool ignoreClipping);

    IntPoint clampOffsetAtScale(const IntPoint& offset, float scale);

    // Exposed for tests.
    WebVector<WebCompositionUnderline> compositionUnderlines() const;

    bool matchesHeuristicsForGpuRasterizationForTesting() const { return m_matchesHeuristicsForGpuRasterization; }

private:
    void resumeTreeViewCommits();
    IntSize contentsSize() const;

    void resetSavedScrollAndScaleState();

    void updateMainFrameScrollPosition(const IntPoint& scrollPosition, bool programmaticScroll);

    void performResize();

    friend class WebView;  // So WebView::Create can call our constructor
    friend class WTF::RefCounted<WebViewImpl>;
    friend void setCurrentInputEventForTest(const WebInputEvent*);

    enum DragAction {
      DragEnter,
      DragOver
    };

    explicit WebViewImpl(WebViewClient*);
    virtual ~WebViewImpl();

    WebTextInputType textInputType();
    int textInputFlags();

    WebString inputModeOfFocusedElement();

    // Returns true if the event was actually processed.
    bool keyEventDefault(const WebKeyboardEvent&);

    bool confirmComposition(const WebString& text, ConfirmCompositionBehavior);

    // Returns true if the view was scrolled.
    bool scrollViewWithKeyboard(int keyCode, int modifiers);

    // Converts |pos| from window coordinates to contents coordinates and gets
    // the HitTestResult for it.
    HitTestResult hitTestResultForWindowPos(const IntPoint&);

    void setIsAcceleratedCompositingActive(bool);
    void doComposite();
    void reallocateRenderer();
    void updateLayerTreeBackgroundColor();
    void updateRootLayerTransform();
    void updateLayerTreeDeviceScaleFactor();

    // Helper function: Widens the width of |source| by the specified margins
    // while keeping it smaller than page width.
    WebRect widenRectWithinPageBounds(const WebRect& source, int targetMargin, int minimumMargin);

    // PageWidgetEventHandler functions
    virtual void handleMouseLeave(LocalFrame&, const WebMouseEvent&) override;
    virtual void handleMouseDown(LocalFrame&, const WebMouseEvent&) override;
    virtual void handleMouseUp(LocalFrame&, const WebMouseEvent&) override;
    virtual bool handleMouseWheel(LocalFrame&, const WebMouseWheelEvent&) override;
    virtual bool handleGestureEvent(const WebGestureEvent&) override;
    virtual bool handleKeyEvent(const WebKeyboardEvent&) override;
    virtual bool handleCharEvent(const WebKeyboardEvent&) override;

    InputMethodContext* inputMethodContext();

    WebViewClient* m_client; // Can be 0 (e.g. unittests, shared workers, etc.)
    WebSpellCheckClient* m_spellCheckClient;

    ChromeClientImpl m_chromeClientImpl;
    EditorClientImpl m_editorClientImpl;
    SpellCheckerClientImpl m_spellCheckerClientImpl;

    WebSize m_size;
    bool m_fixedLayoutSizeLock;

    OwnPtr<Page> m_page;

    // An object that can be used to manipulate m_page->settings() without linking
    // against WebCore. This is lazily allocated the first time GetWebSettings()
    // is called.
    OwnPtr<WebSettingsImpl> m_webSettings;

    // The point relative to the client area where the mouse was last pressed
    // down. This is used by the drag client to determine what was under the
    // mouse when the drag was initiated. We need to track this here in
    // WebViewImpl since DragClient::startDrag does not pass the position the
    // mouse was at when the drag was initiated, only the current point, which
    // can be misleading as it is usually not over the element the user actually
    // dragged by the time a drag is initiated.
    WebPoint m_lastMouseDownPoint;

    bool m_doingDragAndDrop;

    bool m_ignoreInputEvents;

    float m_compositorDeviceScaleFactorOverride;
    WebSize m_rootLayerOffset;
    float m_rootLayerScale;

    // Webkit expects keyPress events to be suppressed if the associated keyDown
    // event was handled. Safari implements this behavior by peeking out the
    // associated WM_CHAR event if the keydown was handled. We emulate
    // this behavior by setting this flag if the keyDown was handled.
    bool m_suppressNextKeypressEvent;

    // Represents whether or not this object should process incoming IME events.
    bool m_imeAcceptEvents;

    // Whether the webview is rendering transparently.
    bool m_isTransparent;

    // Whether the user can press tab to focus links.
    bool m_tabsToLinks;

    // If set, the (plugin) node which has mouse capture.
    RefPtr<Node> m_mouseCaptureNode;
    RefPtr<UserGestureToken> m_mouseCaptureGestureToken;

    IntRect m_rootLayerScrollDamage;
    WebLayerTreeView* m_layerTreeView;
    WebLayer* m_rootLayer;
    GraphicsLayer* m_rootGraphicsLayer;
    GraphicsLayer* m_rootTransformLayer;
    OwnPtr<GraphicsLayerFactory> m_graphicsLayerFactory;
    bool m_isAcceleratedCompositingActive;
    bool m_layerTreeViewCommitsDeferred;
    bool m_layerTreeViewClosed;
    bool m_matchesHeuristicsForGpuRasterization;
    // If true, the graphics context is being restored.
    bool m_recreatingGraphicsContext;
    static const WebInputEvent* m_currentInputEvent;

    OwnPtr<WebActiveGestureAnimation> m_gestureAnimation;
    WebPoint m_positionOnFlingStart;
    WebPoint m_globalPositionOnFlingStart;
    int m_flingModifier;
    bool m_flingSourceDevice;
    Vector<OwnPtr<LinkHighlight> > m_linkHighlights;

    bool m_showFPSCounter;
    bool m_showPaintRects;
    bool m_showDebugBorders;
    bool m_continuousPaintingEnabled;
    bool m_showScrollBottleneckRects;
    WebColor m_baseBackgroundColor;
    WebColor m_backgroundColorOverride;

    bool m_userGestureObserved;
};

// We have no ways to check if the specified WebView is an instance of
// WebViewImpl because WebViewImpl is the only implementation of WebView.
DEFINE_TYPE_CASTS(WebViewImpl, WebView, webView, true, true);

} // namespace blink

#endif
