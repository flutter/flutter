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

#ifndef SKY_ENGINE_WEB_WEBVIEWIMPL_H_
#define SKY_ENGINE_WEB_WEBVIEWIMPL_H_

#include "sky/engine/platform/geometry/IntPoint.h"
#include "sky/engine/platform/geometry/IntRect.h"
#include "sky/engine/public/platform/WebInputEvent.h"
#include "sky/engine/public/platform/WebLayer.h"
#include "sky/engine/public/platform/WebPoint.h"
#include "sky/engine/public/platform/WebRect.h"
#include "sky/engine/public/platform/WebSize.h"
#include "sky/engine/public/platform/WebString.h"
#include "sky/engine/public/web/WebNavigationPolicy.h"
#include "sky/engine/public/web/WebView.h"
#include "sky/engine/web/ChromeClientImpl.h"
#include "sky/engine/web/EditorClientImpl.h"
#include "sky/engine/web/SpellCheckerClientImpl.h"
#include "sky/engine/wtf/OwnPtr.h"
#include "sky/engine/wtf/RefCounted.h"
#include "sky/engine/wtf/Vector.h"

namespace blink {

class Frame;
class WebLocalFrameImpl;
class WebImage;
class WebSettingsImpl;

class WebViewImpl final : public WebView, public RefCounted<WebViewImpl> {
public:
    static WebViewImpl* create(WebViewClient*);

    // WebWidget methods:
    virtual void close() override;
    virtual WebSize size() override;

    virtual void resize(const WebSize&) override;

    virtual void beginFrame(const WebBeginFrameArgs&) override;

    virtual void layout() override;
    virtual void paint(WebCanvas*, const WebRect&) override;
    virtual bool handleInputEvent(const WebInputEvent&) override;
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

    // WebView methods:
    virtual void setMainFrame(WebFrame*) override;
    virtual void injectModule(const WebString&) override;
    virtual void setSpellCheckClient(WebSpellCheckClient*) override;
    virtual WebSettings* settings() override;
    virtual bool isTransparent() const override;
    virtual void setIsTransparent(bool value) override;
    virtual void setBaseBackgroundColor(WebColor) override;
    virtual bool isActive() const override;
    virtual void setIsActive(bool value) override;
    virtual WebFrame* mainFrame() override;
    virtual WebFrame* focusedFrame() override;
    virtual void setFocusedFrame(WebFrame*) override;
    virtual void setInitialFocus(bool reverse) override;
    virtual void clearFocusedElement() override;
    virtual void advanceFocus(bool reverse) override;

    virtual float deviceScaleFactor() const override;
    virtual void setDeviceScaleFactor(float) override;

    virtual WebHitTestResult hitTestResultAt(const WebPoint&) override;
    virtual void spellingMarkers(WebVector<uint32_t>* markers) override;
    virtual void removeSpellingMarkersUnderWords(const WebVector<WebString>& words) override;

    virtual void setShowPaintRects(bool) override;
    void setShowDebugBorders(bool);
    virtual void setShowScrollBottleneckRects(bool) override;

    virtual void acceptLanguagesChanged() override;

    // WebViewImpl
    HitTestResult coreHitTestResultAt(const WebPoint&);

    void setBackgroundColorOverride(WebColor);

    Color baseBackgroundColor() const { return m_baseBackgroundColor; }

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

    void updateMainFrameLayoutSize();

    void scheduleVisualUpdate();

    virtual void setVisibilityState(WebPageVisibilityState, bool) override;

    // Exposed for the purpose of overriding device metrics.
    void sendResizeEventAndRepaint();

    WebSettingsImpl* settingsImpl();

    IntPoint clampOffsetAtScale(const IntPoint& offset, float scale);

    // Exposed for tests.
    WebVector<WebCompositionUnderline> compositionUnderlines() const;

    bool matchesHeuristicsForGpuRasterizationForTesting() const { return m_matchesHeuristicsForGpuRasterization; }

private:
    IntSize contentsSize() const;

    void resetSavedScrollAndScaleState();

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

    bool confirmComposition(const WebString& text, ConfirmCompositionBehavior);

    // Converts |pos| from window coordinates to contents coordinates and gets
    // the HitTestResult for it.
    HitTestResult hitTestResultForWindowPos(const IntPoint&);

    void doComposite();
    void reallocateRenderer();

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

    IntRect m_rootLayerScrollDamage;
    WebLayer* m_rootLayer;
    bool m_matchesHeuristicsForGpuRasterization;
    // If true, the graphics context is being restored.
    bool m_recreatingGraphicsContext;
    static const WebInputEvent* m_currentInputEvent;

    WebPoint m_positionOnFlingStart;
    WebPoint m_globalPositionOnFlingStart;
    int m_flingModifier;
    bool m_flingSourceDevice;

    bool m_showPaintRects;
    bool m_showDebugBorders;
    bool m_showScrollBottleneckRects;
    WebColor m_baseBackgroundColor;
    WebColor m_backgroundColorOverride;
};

// We have no ways to check if the specified WebView is an instance of
// WebViewImpl because WebViewImpl is the only implementation of WebView.
DEFINE_TYPE_CASTS(WebViewImpl, WebView, webView, true, true);

} // namespace blink

#endif  // SKY_ENGINE_WEB_WEBVIEWIMPL_H_
