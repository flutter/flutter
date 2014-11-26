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

#ifndef SKY_ENGINE_WEB_WEBLOCALFRAMEIMPL_H_
#define SKY_ENGINE_WEB_WEBLOCALFRAMEIMPL_H_

#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/platform/geometry/FloatRect.h"
#include "sky/engine/public/web/WebLocalFrame.h"
#include "sky/engine/web/FrameLoaderClientImpl.h"
#include "sky/engine/wtf/Compiler.h"
#include "sky/engine/wtf/OwnPtr.h"
#include "sky/engine/wtf/RefCounted.h"
#include "sky/engine/wtf/text/WTFString.h"

namespace blink {

class GraphicsContext;
class IntSize;
class KURL;
class Node;
class Range;
class WebFrameClient;
class WebView;
class WebViewImpl;

template <typename T> class WebVector;

// Implementation of WebFrame, note that this is a reference counted object.
class WebLocalFrameImpl final
    : public WebLocalFrame
    , public RefCounted<WebLocalFrameImpl> {
public:
    // WebFrame methods:
    virtual bool isWebLocalFrame() const override;
    virtual WebLocalFrame* toWebLocalFrame() override;
    virtual void close() override;
    virtual WebSize contentsSize() const override;
    virtual bool hasVisibleContent() const override;
    virtual WebRect visibleContentRect() const override;
    virtual bool hasHorizontalScrollbar() const override;
    virtual bool hasVerticalScrollbar() const override;
    virtual WebView* view() const override;
    virtual WebDocument document() const override;
    virtual void executeScript(const WebScriptSource&) override;
    virtual void executeScriptInIsolatedWorld(
        int worldID, const WebScriptSource* sources, unsigned numSources,
        int extensionGroup) override;
    virtual void setIsolatedWorldHumanReadableName(int worldID, const WebString&) override;
    virtual void addMessageToConsole(const WebConsoleMessage&) override;
    virtual void collectGarbage() override;
    virtual v8::Handle<v8::Value> executeScriptAndReturnValue(
        const WebScriptSource&) override;
    virtual void executeScriptInIsolatedWorld(
        int worldID, const WebScriptSource* sourcesIn, unsigned numSources,
        int extensionGroup, WebVector<v8::Local<v8::Value> >* results) override;
    virtual v8::Handle<v8::Value> callFunctionEvenIfScriptDisabled(
        v8::Handle<v8::Function>,
        v8::Handle<v8::Value>,
        int argc,
        v8::Handle<v8::Value> argv[]) override;
    virtual v8::Local<v8::Context> mainWorldScriptContext() const override;
    virtual void load(const WebURL&, mojo::ScopedDataPipeConsumerHandle);
    virtual void setReferrerForRequest(WebURLRequest&, const WebURL& referrer) override;
    virtual unsigned unloadListenerCount() const override;
    virtual void replaceSelection(const WebString&) override;
    virtual void insertText(const WebString&) override;
    virtual void setMarkedText(const WebString&, unsigned location, unsigned length) override;
    virtual void unmarkText() override;
    virtual bool hasMarkedText() const override;
    virtual WebRange markedRange() const override;
    virtual bool firstRectForCharacterRange(unsigned location, unsigned length, WebRect&) const override;
    virtual size_t characterIndexForPoint(const WebPoint&) const override;
    virtual bool executeCommand(const WebString&, const WebNode& = WebNode()) override;
    virtual bool executeCommand(const WebString&, const WebString& value, const WebNode& = WebNode()) override;
    virtual bool isCommandEnabled(const WebString&) const override;
    virtual void enableContinuousSpellChecking(bool) override;
    virtual bool isContinuousSpellCheckingEnabled() const override;
    virtual void requestTextChecking(const WebElement&) override;
    virtual void replaceMisspelledRange(const WebString&) override;
    virtual void removeSpellingMarkers() override;
    virtual bool hasSelection() const override;
    virtual WebRange selectionRange() const override;
    virtual WebString selectionAsText() const override;
    virtual WebString selectionAsMarkup() const override;
    virtual bool selectWordAroundCaret() override;
    virtual void selectRange(const WebPoint& base, const WebPoint& extent) override;
    virtual void selectRange(const WebRange&) override;
    virtual void moveRangeSelection(const WebPoint& base, const WebPoint& extent) override;
    virtual void moveCaretSelection(const WebPoint&) override;
    virtual bool setEditableSelectionOffsets(int start, int end) override;
    virtual bool setCompositionFromExistingText(int compositionStart, int compositionEnd, const WebVector<WebCompositionUnderline>& underlines) override;
    virtual void extendSelectionAndDelete(int before, int after) override;
    virtual void setCaretVisible(bool) override;

    virtual WebString contentAsText(size_t maxChars) const override;
    virtual WebString contentAsMarkup() const override;
    virtual WebString renderTreeAsText(RenderAsTextControls toShow = RenderAsTextNormal) const override;
    virtual WebString markerTextForListItem(const WebElement&) const override;
    virtual WebRect selectionBoundsRect() const override;

    virtual bool selectionStartHasSpellingMarkerFor(int from, int length) const override;

    static WebLocalFrameImpl* create(WebFrameClient*);
    virtual ~WebLocalFrameImpl();

    PassRefPtr<LocalFrame> initializeCoreFrame(FrameHost*);

    void createFrameView();

    static WebLocalFrameImpl* fromFrame(LocalFrame*);
    static WebLocalFrameImpl* fromFrame(LocalFrame&);

    WebViewImpl* viewImpl() const;

    FrameView* frameView() const { return frame() ? frame()->view() : 0; }

    void didFail(const ResourceError&);

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

#endif  // SKY_ENGINE_WEB_WEBLOCALFRAMEIMPL_H_
