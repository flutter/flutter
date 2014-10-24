/*
 * Copyright (C) 2009 Google Inc. All rights reserved.
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

#ifndef WebLocalFrameImpl_h
#define WebLocalFrameImpl_h

#include "core/frame/LocalFrame.h"
#include "platform/geometry/FloatRect.h"
#include "public/web/WebLocalFrame.h"
#include "web/FrameLoaderClientImpl.h"
#include "wtf/Compiler.h"
#include "wtf/OwnPtr.h"
#include "wtf/RefCounted.h"
#include "wtf/text/WTFString.h"

namespace blink {

class GraphicsContext;
class IntSize;
class KURL;
class Node;
class Range;
class WebFrameClient;
class WebPerformance;
class WebView;
class WebViewImpl;

template <typename T> class WebVector;

// Implementation of WebFrame, note that this is a reference counted object.
class WebLocalFrameImpl FINAL
    : public WebLocalFrame
    , public RefCounted<WebLocalFrameImpl> {
public:
    // WebFrame methods:
    virtual bool isWebLocalFrame() const OVERRIDE;
    virtual WebLocalFrame* toWebLocalFrame() OVERRIDE;
    virtual void close() OVERRIDE;
    virtual WebSize scrollOffset() const OVERRIDE;
    virtual void setScrollOffset(const WebSize&) OVERRIDE;
    virtual WebSize minimumScrollOffset() const OVERRIDE;
    virtual WebSize maximumScrollOffset() const OVERRIDE;
    virtual WebSize contentsSize() const OVERRIDE;
    virtual bool hasVisibleContent() const OVERRIDE;
    virtual WebRect visibleContentRect() const OVERRIDE;
    virtual bool hasHorizontalScrollbar() const OVERRIDE;
    virtual bool hasVerticalScrollbar() const OVERRIDE;
    virtual WebView* view() const OVERRIDE;
    virtual WebDocument document() const OVERRIDE;
    virtual WebPerformance performance() const OVERRIDE;
    virtual void executeScript(const WebScriptSource&) OVERRIDE;
    virtual void executeScriptInIsolatedWorld(
        int worldID, const WebScriptSource* sources, unsigned numSources,
        int extensionGroup) OVERRIDE;
    virtual void setIsolatedWorldHumanReadableName(int worldID, const WebString&) OVERRIDE;
    virtual void addMessageToConsole(const WebConsoleMessage&) OVERRIDE;
    virtual void collectGarbage() OVERRIDE;
    virtual v8::Handle<v8::Value> executeScriptAndReturnValue(
        const WebScriptSource&) OVERRIDE;
    virtual void executeScriptInIsolatedWorld(
        int worldID, const WebScriptSource* sourcesIn, unsigned numSources,
        int extensionGroup, WebVector<v8::Local<v8::Value> >* results) OVERRIDE;
    virtual v8::Handle<v8::Value> callFunctionEvenIfScriptDisabled(
        v8::Handle<v8::Function>,
        v8::Handle<v8::Value>,
        int argc,
        v8::Handle<v8::Value> argv[]) OVERRIDE;
    virtual v8::Local<v8::Context> mainWorldScriptContext() const OVERRIDE;
    virtual void load(const WebURL&, mojo::ScopedDataPipeConsumerHandle);
    virtual void setReferrerForRequest(WebURLRequest&, const WebURL& referrer) OVERRIDE;
    virtual unsigned unloadListenerCount() const OVERRIDE;
    virtual void replaceSelection(const WebString&) OVERRIDE;
    virtual void insertText(const WebString&) OVERRIDE;
    virtual void setMarkedText(const WebString&, unsigned location, unsigned length) OVERRIDE;
    virtual void unmarkText() OVERRIDE;
    virtual bool hasMarkedText() const OVERRIDE;
    virtual WebRange markedRange() const OVERRIDE;
    virtual bool firstRectForCharacterRange(unsigned location, unsigned length, WebRect&) const OVERRIDE;
    virtual size_t characterIndexForPoint(const WebPoint&) const OVERRIDE;
    virtual bool executeCommand(const WebString&, const WebNode& = WebNode()) OVERRIDE;
    virtual bool executeCommand(const WebString&, const WebString& value, const WebNode& = WebNode()) OVERRIDE;
    virtual bool isCommandEnabled(const WebString&) const OVERRIDE;
    virtual void enableContinuousSpellChecking(bool) OVERRIDE;
    virtual bool isContinuousSpellCheckingEnabled() const OVERRIDE;
    virtual void requestTextChecking(const WebElement&) OVERRIDE;
    virtual void replaceMisspelledRange(const WebString&) OVERRIDE;
    virtual void removeSpellingMarkers() OVERRIDE;
    virtual bool hasSelection() const OVERRIDE;
    virtual WebRange selectionRange() const OVERRIDE;
    virtual WebString selectionAsText() const OVERRIDE;
    virtual WebString selectionAsMarkup() const OVERRIDE;
    virtual bool selectWordAroundCaret() OVERRIDE;
    virtual void selectRange(const WebPoint& base, const WebPoint& extent) OVERRIDE;
    virtual void selectRange(const WebRange&) OVERRIDE;
    virtual void moveRangeSelection(const WebPoint& base, const WebPoint& extent) OVERRIDE;
    virtual void moveCaretSelection(const WebPoint&) OVERRIDE;
    virtual bool setEditableSelectionOffsets(int start, int end) OVERRIDE;
    virtual bool setCompositionFromExistingText(int compositionStart, int compositionEnd, const WebVector<WebCompositionUnderline>& underlines) OVERRIDE;
    virtual void extendSelectionAndDelete(int before, int after) OVERRIDE;
    virtual void setCaretVisible(bool) OVERRIDE;

    virtual WebString contentAsText(size_t maxChars) const OVERRIDE;
    virtual WebString contentAsMarkup() const OVERRIDE;
    virtual WebString renderTreeAsText(RenderAsTextControls toShow = RenderAsTextNormal) const OVERRIDE;
    virtual WebString markerTextForListItem(const WebElement&) const OVERRIDE;
    virtual WebRect selectionBoundsRect() const OVERRIDE;

    virtual bool selectionStartHasSpellingMarkerFor(int from, int length) const OVERRIDE;
    virtual WebString layerTreeAsText(bool showDebugInfo = false) const OVERRIDE;

    static WebLocalFrameImpl* create(WebFrameClient*);
    virtual ~WebLocalFrameImpl();

    PassRefPtr<LocalFrame> initializeCoreFrame(FrameHost*);

    void createFrameView();

    static WebLocalFrameImpl* fromFrame(LocalFrame*);
    static WebLocalFrameImpl* fromFrame(LocalFrame&);

    WebViewImpl* viewImpl() const;

    FrameView* frameView() const { return frame() ? frame()->view() : 0; }

    void didFail(const ResourceError&);

    // Sets whether the WebLocalFrameImpl allows its document to be scrolled.
    // If the parameter is true, allow the document to be scrolled.
    // Otherwise, disallow scrolling.
    virtual void setCanHaveScrollbars(bool) OVERRIDE;

    LocalFrame* frame() const { return m_frame.get(); }
    WebFrameClient* client() const { return m_client; }
    void setClient(WebFrameClient* client) { m_client = client; }

    void setInputEventsTransformForEmulation(const IntSize&, float);

    static void selectWordAroundPosition(LocalFrame*, VisiblePosition);

    // Invalidates both content area and the scrollbar.
    void invalidateAll() const;

    // Returns a hit-tested VisiblePosition for the given point
    VisiblePosition visiblePositionForWindowPoint(const WebPoint&);

private:
    friend class FrameLoaderClientImpl;

    explicit WebLocalFrameImpl(WebFrameClient*);

    // Sets the local core frame and registers destruction observers.
    void setCoreFrame(PassRefPtr<LocalFrame>);

    FrameLoaderClientImpl m_frameLoaderClientImpl;

    // The embedder retains a reference to the WebCore LocalFrame while it is active in the DOM. This
    // reference is released when the frame is removed from the DOM or the entire page is closed.
    // FIXME: These will need to change to WebFrame when we introduce WebFrameProxy.
    RefPtr<LocalFrame> m_frame;

    WebFrameClient* m_client;

    // Stores the additional input events offset and scale when device metrics emulation is enabled.
    IntSize m_inputEventsOffsetForEmulation;
    float m_inputEventsScaleFactorForEmulation;
};

DEFINE_TYPE_CASTS(WebLocalFrameImpl, WebFrame, frame, frame->isWebLocalFrame(), frame.isWebLocalFrame());

} // namespace blink

#endif
