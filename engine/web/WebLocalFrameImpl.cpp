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

// How ownership works
// -------------------
//
// Big oh represents a refcounted relationship: owner O--- ownee
//
// WebView (for the toplevel frame only)
//    O
//    |           WebFrame
//    |              O
//    |              |
//   Page O------- LocalFrame (m_mainFrame) O-------O FrameView
//                   ||
//                   ||
//               FrameLoader
//
// FrameLoader and LocalFrame are formerly one object that was split apart because
// it got too big. They basically have the same lifetime, hence the double line.
//
// From the perspective of the embedder, WebFrame is simply an object that it
// allocates by calling WebFrame::create() and must be freed by calling close().
// Internally, WebFrame is actually refcounted and it holds a reference to its
// corresponding LocalFrame in WebCore.
//
// How frames are destroyed
// ------------------------
//
// The main frame is never destroyed and is re-used. The FrameLoader is re-used
// and a reference to the main frame is kept by the Page.
//
// When frame content is replaced, all subframes are destroyed. This happens
// in FrameLoader::detachFromParent for each subframe in a pre-order depth-first
// traversal. Note that child node order may not match DOM node order!
// detachFromParent() calls FrameLoaderClient::detachedFromParent(), which calls
// WebFrame::frameDetached(). This triggers WebFrame to clear its reference to
// LocalFrame, and also notifies the embedder via WebFrameClient that the frame is
// detached. Most embedders will invoke close() on the WebFrame at this point,
// triggering its deletion unless something else is still retaining a reference.
//
// Thie client is expected to be set whenever the WebLocalFrameImpl is attached to
// the DOM.

#include "config.h"
#include "web/WebLocalFrameImpl.h"

#include "bindings/core/v8/DOMWrapperWorld.h"
#include "bindings/core/v8/ExceptionState.h"
#include "bindings/core/v8/ExceptionStatePlaceholder.h"
#include "bindings/core/v8/ScriptController.h"
#include "bindings/core/v8/ScriptSourceCode.h"
#include "bindings/core/v8/ScriptValue.h"
#include "bindings/core/v8/V8GCController.h"
#include "bindings/core/v8/V8PerIsolateData.h"
#include "core/dom/Document.h"
#include "core/dom/Node.h"
#include "core/dom/NodeTraversal.h"
#include "core/dom/shadow/ShadowRoot.h"
#include "core/editing/Editor.h"
#include "core/editing/FrameSelection.h"
#include "core/editing/InputMethodController.h"
#include "core/editing/PlainTextRange.h"
#include "core/editing/SpellChecker.h"
#include "core/editing/TextAffinity.h"
#include "core/editing/TextIterator.h"
#include "core/editing/htmlediting.h"
#include "core/editing/markup.h"
#include "core/frame/Console.h"
#include "core/frame/FrameHost.h"
#include "core/frame/FrameView.h"
#include "core/frame/LocalDOMWindow.h"
#include "core/frame/Settings.h"
#include "core/html/HTMLAnchorElement.h"
#include "core/html/HTMLLinkElement.h"
#include "core/inspector/ConsoleMessage.h"
#include "core/inspector/ScriptCallStack.h"
#include "core/loader/MojoLoader.h"
#include "core/page/Chrome.h"
#include "core/page/EventHandler.h"
#include "core/page/FocusController.h"
#include "core/page/Page.h"
#include "core/rendering/HitTestResult.h"
#include "core/rendering/RenderBox.h"
#include "core/rendering/RenderLayer.h"
#include "core/rendering/RenderObject.h"
#include "core/rendering/RenderTreeAsText.h"
#include "core/rendering/RenderView.h"
#include "core/rendering/style/StyleInheritedData.h"
#include "mojo/public/cpp/system/data_pipe.h"
#include "platform/TraceEvent.h"
#include "platform/UserGestureIndicator.h"
#include "platform/clipboard/ClipboardUtilities.h"
#include "platform/fonts/FontCache.h"
#include "platform/graphics/GraphicsContext.h"
#include "platform/graphics/GraphicsLayerClient.h"
#include "platform/graphics/skia/SkiaUtils.h"
#include "platform/heap/Handle.h"
#include "platform/network/ResourceRequest.h"
#include "platform/scroll/ScrollTypes.h"
#include "platform/scroll/Scrollbar.h"
#include "platform/weborigin/KURL.h"
#include "platform/weborigin/SchemeRegistry.h"
#include "platform/weborigin/SecurityPolicy.h"
#include "public/platform/Platform.h"
#include "public/platform/WebFloatPoint.h"
#include "public/platform/WebFloatRect.h"
#include "public/platform/WebLayer.h"
#include "public/platform/WebPoint.h"
#include "public/platform/WebRect.h"
#include "public/platform/WebSize.h"
#include "public/platform/WebURLError.h"
#include "public/platform/WebVector.h"
#include "public/web/WebConsoleMessage.h"
#include "public/web/WebDOMEvent.h"
#include "public/web/WebDocument.h"
#include "public/web/WebElement.h"
#include "public/web/WebFindOptions.h"
#include "public/web/WebFrameClient.h"
#include "public/web/WebIconURL.h"
#include "public/web/WebNode.h"
#include "public/web/WebPerformance.h"
#include "public/web/WebRange.h"
#include "public/web/WebScriptSource.h"
#include "public/web/WebSerializedScriptValue.h"
#include "web/CompositionUnderlineVectorBuilder.h"
#include "web/PageOverlay.h"
#include "web/WebViewImpl.h"
#include "wtf/CurrentTime.h"
#include "wtf/HashMap.h"
#include <algorithm>

namespace blink {

static int frameCount = 0;

// Key for a StatsCounter tracking how many WebFrames are active.
static const char webFrameActiveCount[] = "WebFrameActiveCount";

static void frameContentAsPlainText(size_t maxChars, LocalFrame* frame, StringBuilder& output)
{
    Document* document = frame->document();
    if (!document)
        return;

    if (!frame->view())
        return;

    // Select the document body.
    RefPtrWillBeRawPtr<Range> range(document->createRange());
    TrackExceptionState exceptionState;
    range->selectNodeContents(document->documentElement(), exceptionState);

    if (!exceptionState.hadException()) {
        // The text iterator will walk nodes giving us text. This is similar to
        // the plainText() function in core/editing/TextIterator.h, but we implement the maximum
        // size and also copy the results directly into a wstring, avoiding the
        // string conversion.
        for (TextIterator it(range.get()); !it.atEnd(); it.advance()) {
            it.appendTextToStringBuilder(output, 0, maxChars - output.length());
            if (output.length() >= maxChars)
                return; // Filled up the buffer.
        }
    }
}

// WebFrame -------------------------------------------------------------------

int WebFrame::instanceCount()
{
    return frameCount;
}

WebLocalFrame* WebLocalFrame::frameForCurrentContext()
{
    v8::Handle<v8::Context> context = v8::Isolate::GetCurrent()->GetCurrentContext();
    if (context.IsEmpty())
        return 0;
    return frameForContext(context);
}

WebLocalFrame* WebLocalFrame::frameForContext(v8::Handle<v8::Context> context)
{
    return WebLocalFrameImpl::fromFrame(toFrameIfNotDetached(context));
}

bool WebLocalFrameImpl::isWebLocalFrame() const
{
    return true;
}

WebLocalFrame* WebLocalFrameImpl::toWebLocalFrame()
{
    return this;
}

void WebLocalFrameImpl::close()
{
    m_client = 0;

    deref(); // Balances ref() acquired in WebFrame::create
}

WebSize WebLocalFrameImpl::scrollOffset() const
{
    FrameView* view = frameView();
    if (!view)
        return WebSize();
    return view->scrollOffset();
}

WebSize WebLocalFrameImpl::minimumScrollOffset() const
{
    FrameView* view = frameView();
    if (!view)
        return WebSize();
    return toIntSize(view->minimumScrollPosition());
}

WebSize WebLocalFrameImpl::maximumScrollOffset() const
{
    FrameView* view = frameView();
    if (!view)
        return WebSize();
    return toIntSize(view->maximumScrollPosition());
}

WebSize WebLocalFrameImpl::contentsSize() const
{
    return frame()->view()->size();
}

bool WebLocalFrameImpl::hasVisibleContent() const
{
    return frame()->view()->width() > 0 && frame()->view()->height() > 0;
}

WebRect WebLocalFrameImpl::visibleContentRect() const
{
    return frame()->view()->frameRect();
}

bool WebLocalFrameImpl::hasHorizontalScrollbar() const
{
    // FIXME(sky): Remove
    return false;
}

bool WebLocalFrameImpl::hasVerticalScrollbar() const
{
    // FIXME(sky): Remove
    return false;
}

WebView* WebLocalFrameImpl::view() const
{
    return viewImpl();
}

WebDocument WebLocalFrameImpl::document() const
{
    if (!frame() || !frame()->document())
        return WebDocument();
    return WebDocument(frame()->document());
}

WebPerformance WebLocalFrameImpl::performance() const
{
    return WebPerformance();
}

void WebLocalFrameImpl::executeScript(const WebScriptSource& source)
{
    ASSERT(frame());
    TextPosition position(OrdinalNumber::fromOneBasedInt(source.startLine), OrdinalNumber::first());
    v8::HandleScope handleScope(toIsolate(frame()));
    frame()->script().executeScriptInMainWorld(ScriptSourceCode(source.code, source.url, position));
}

void WebLocalFrameImpl::executeScriptInIsolatedWorld(int worldID, const WebScriptSource* sourcesIn, unsigned numSources, int extensionGroup)
{
    ASSERT(frame());
    RELEASE_ASSERT(worldID > 0);
    RELEASE_ASSERT(worldID < EmbedderWorldIdLimit);

    Vector<ScriptSourceCode> sources;
    for (unsigned i = 0; i < numSources; ++i) {
        TextPosition position(OrdinalNumber::fromOneBasedInt(sourcesIn[i].startLine), OrdinalNumber::first());
        sources.append(ScriptSourceCode(sourcesIn[i].code, sourcesIn[i].url, position));
    }

    v8::HandleScope handleScope(toIsolate(frame()));
    frame()->script().executeScriptInIsolatedWorld(worldID, sources, extensionGroup, 0);
}

void WebLocalFrameImpl::setIsolatedWorldHumanReadableName(int worldID, const WebString& humanReadableName)
{
    ASSERT(frame());
    DOMWrapperWorld::setIsolatedWorldHumanReadableName(worldID, humanReadableName);
}

void WebLocalFrameImpl::addMessageToConsole(const WebConsoleMessage& message)
{
    ASSERT(frame());

    MessageLevel webCoreMessageLevel;
    switch (message.level) {
    case WebConsoleMessage::LevelDebug:
        webCoreMessageLevel = DebugMessageLevel;
        break;
    case WebConsoleMessage::LevelLog:
        webCoreMessageLevel = LogMessageLevel;
        break;
    case WebConsoleMessage::LevelWarning:
        webCoreMessageLevel = WarningMessageLevel;
        break;
    case WebConsoleMessage::LevelError:
        webCoreMessageLevel = ErrorMessageLevel;
        break;
    default:
        ASSERT_NOT_REACHED();
        return;
    }

    frame()->document()->addConsoleMessage(ConsoleMessage::create(OtherMessageSource, webCoreMessageLevel, message.text));
}

void WebLocalFrameImpl::collectGarbage()
{
    if (!frame())
        return;
    V8GCController::collectGarbage(v8::Isolate::GetCurrent());
}

v8::Handle<v8::Value> WebLocalFrameImpl::executeScriptAndReturnValue(const WebScriptSource& source)
{
    ASSERT(frame());

    // TODO: Remove this after blink has rolled and chromium change landed. (crrev.com/516753002)
    UserGestureIndicator gestureIndicator(DefinitelyProcessingNewUserGesture);

    TextPosition position(OrdinalNumber::fromOneBasedInt(source.startLine), OrdinalNumber::first());
    return frame()->script().executeScriptInMainWorldAndReturnValue(ScriptSourceCode(source.code, source.url, position));
}

void WebLocalFrameImpl::executeScriptInIsolatedWorld(int worldID, const WebScriptSource* sourcesIn, unsigned numSources, int extensionGroup, WebVector<v8::Local<v8::Value> >* results)
{
    ASSERT(frame());
    RELEASE_ASSERT(worldID > 0);
    RELEASE_ASSERT(worldID < EmbedderWorldIdLimit);

    Vector<ScriptSourceCode> sources;

    for (unsigned i = 0; i < numSources; ++i) {
        TextPosition position(OrdinalNumber::fromOneBasedInt(sourcesIn[i].startLine), OrdinalNumber::first());
        sources.append(ScriptSourceCode(sourcesIn[i].code, sourcesIn[i].url, position));
    }

    if (results) {
        Vector<v8::Local<v8::Value> > scriptResults;
        frame()->script().executeScriptInIsolatedWorld(worldID, sources, extensionGroup, &scriptResults);
        WebVector<v8::Local<v8::Value> > v8Results(scriptResults.size());
        for (unsigned i = 0; i < scriptResults.size(); i++)
            v8Results[i] = v8::Local<v8::Value>::New(toIsolate(frame()), scriptResults[i]);
        results->swap(v8Results);
    } else {
        v8::HandleScope handleScope(toIsolate(frame()));
        frame()->script().executeScriptInIsolatedWorld(worldID, sources, extensionGroup, 0);
    }
}

v8::Handle<v8::Value> WebLocalFrameImpl::callFunctionEvenIfScriptDisabled(v8::Handle<v8::Function> function, v8::Handle<v8::Value> receiver, int argc, v8::Handle<v8::Value> argv[])
{
    ASSERT(frame());
    return frame()->script().callFunction(function, receiver, argc, argv);
}

v8::Local<v8::Context> WebLocalFrameImpl::mainWorldScriptContext() const
{
    return toV8Context(frame(), DOMWrapperWorld::mainWorld());
}

void WebLocalFrameImpl::load(const WebURL& url, mojo::ScopedDataPipeConsumerHandle responseStream)
{
    frame()->mojoLoader().load(url, responseStream.Pass());
}

void WebLocalFrameImpl::setReferrerForRequest(WebURLRequest& request, const WebURL& referrerURL)
{
    String referrer = referrerURL.isEmpty() ? frame()->document()->outgoingReferrer() : String(referrerURL.spec().utf16());
    referrer = SecurityPolicy::generateReferrerHeader(frame()->document()->referrerPolicy(), request.url(), referrer);
    if (referrer.isEmpty())
        return;
    request.setHTTPReferrer(referrer, static_cast<WebReferrerPolicy>(frame()->document()->referrerPolicy()));
}

unsigned WebLocalFrameImpl::unloadListenerCount() const
{
    return frame()->domWindow()->pendingUnloadEventListeners();
}

void WebLocalFrameImpl::replaceSelection(const WebString& text)
{
    bool selectReplacement = false;
    bool smartReplace = true;
    frame()->editor().replaceSelectionWithText(text, selectReplacement, smartReplace);
}

void WebLocalFrameImpl::insertText(const WebString& text)
{
    if (frame()->inputMethodController().hasComposition())
        frame()->inputMethodController().confirmComposition(text);
    else
        frame()->editor().insertText(text, 0);
}

void WebLocalFrameImpl::setMarkedText(const WebString& text, unsigned location, unsigned length)
{
    Vector<CompositionUnderline> decorations;
    frame()->inputMethodController().setComposition(text, decorations, location, length);
}

void WebLocalFrameImpl::unmarkText()
{
    frame()->inputMethodController().cancelComposition();
}

bool WebLocalFrameImpl::hasMarkedText() const
{
    return frame()->inputMethodController().hasComposition();
}

WebRange WebLocalFrameImpl::markedRange() const
{
    return frame()->inputMethodController().compositionRange();
}

bool WebLocalFrameImpl::firstRectForCharacterRange(unsigned location, unsigned length, WebRect& rect) const
{
    if ((location + length < location) && (location + length))
        length = 0;

    Element* editable = frame()->selection().rootEditableElementOrDocumentElement();
    ASSERT(editable);
    RefPtrWillBeRawPtr<Range> range = PlainTextRange(location, location + length).createRange(*editable);
    if (!range)
        return false;
    IntRect intRect = frame()->editor().firstRectForRange(range.get());
    rect = WebRect(intRect);
    rect = frame()->view()->contentsToWindow(rect);
    return true;
}

size_t WebLocalFrameImpl::characterIndexForPoint(const WebPoint& webPoint) const
{
    if (!frame())
        return kNotFound;

    IntPoint point = frame()->view()->windowToContents(webPoint);
    HitTestResult result = frame()->eventHandler().hitTestResultAtPoint(point, HitTestRequest::ReadOnly | HitTestRequest::Active);
    RefPtrWillBeRawPtr<Range> range = frame()->rangeForPoint(result.roundedPointInInnerNodeFrame());
    if (!range)
        return kNotFound;
    Element* editable = frame()->selection().rootEditableElementOrDocumentElement();
    ASSERT(editable);
    return PlainTextRange::create(*editable, *range.get()).start();
}

bool WebLocalFrameImpl::executeCommand(const WebString& name, const WebNode& node)
{
    ASSERT(frame());

    if (name.length() <= 2)
        return false;

    // Since we don't have NSControl, we will convert the format of command
    // string and call the function on Editor directly.
    String command = name;

    // Make sure the first letter is upper case.
    command.replace(0, 1, command.substring(0, 1).upper());

    // Remove the trailing ':' if existing.
    if (command[command.length() - 1] == UChar(':'))
        command = command.substring(0, command.length() - 1);

    return frame()->editor().executeCommand(command);
}

bool WebLocalFrameImpl::executeCommand(const WebString& name, const WebString& value, const WebNode& node)
{
    ASSERT(frame());

    return frame()->editor().executeCommand(name, value);
}

bool WebLocalFrameImpl::isCommandEnabled(const WebString& name) const
{
    ASSERT(frame());
    return frame()->editor().command(name).isEnabled();
}

void WebLocalFrameImpl::enableContinuousSpellChecking(bool enable)
{
    if (enable == isContinuousSpellCheckingEnabled())
        return;
    frame()->spellChecker().toggleContinuousSpellChecking();
}

bool WebLocalFrameImpl::isContinuousSpellCheckingEnabled() const
{
    return frame()->spellChecker().isContinuousSpellCheckingEnabled();
}

void WebLocalFrameImpl::requestTextChecking(const WebElement& webElement)
{
    if (webElement.isNull())
        return;
    frame()->spellChecker().requestTextChecking(*webElement.constUnwrap<Element>());
}

void WebLocalFrameImpl::replaceMisspelledRange(const WebString& text)
{
    frame()->spellChecker().replaceMisspelledRange(text);
}

void WebLocalFrameImpl::removeSpellingMarkers()
{
    frame()->spellChecker().removeSpellingMarkers();
}

bool WebLocalFrameImpl::hasSelection() const
{
    // frame()->selection()->isNone() never returns true.
    return frame()->selection().start() != frame()->selection().end();
}

WebRange WebLocalFrameImpl::selectionRange() const
{
    return frame()->selection().toNormalizedRange();
}

WebString WebLocalFrameImpl::selectionAsText() const
{
    RefPtrWillBeRawPtr<Range> range = frame()->selection().toNormalizedRange();
    if (!range)
        return WebString();

    String text = range->text();
    replaceNBSPWithSpace(text);
    return text;
}

WebString WebLocalFrameImpl::selectionAsMarkup() const
{
    RefPtrWillBeRawPtr<Range> range = frame()->selection().toNormalizedRange();
    if (!range)
        return WebString();

    return createMarkup(range.get(), 0, AnnotateForInterchange, false, ResolveNonLocalURLs);
}

void WebLocalFrameImpl::selectWordAroundPosition(LocalFrame* frame, VisiblePosition position)
{
    VisibleSelection selection(position);
    selection.expandUsingGranularity(WordGranularity);

    TextGranularity granularity = selection.isRange() ? WordGranularity : CharacterGranularity;
    frame->selection().setSelection(selection, granularity);
}

bool WebLocalFrameImpl::selectWordAroundCaret()
{
    FrameSelection& selection = frame()->selection();
    if (selection.isNone() || selection.isRange())
        return false;
    selectWordAroundPosition(frame(), selection.selection().visibleStart());
    return true;
}

void WebLocalFrameImpl::selectRange(const WebPoint& base, const WebPoint& extent)
{
    moveRangeSelection(base, extent);
}

void WebLocalFrameImpl::selectRange(const WebRange& webRange)
{
    if (RefPtrWillBeRawPtr<Range> range = static_cast<PassRefPtrWillBeRawPtr<Range> >(webRange))
        frame()->selection().setSelectedRange(range.get(), VP_DEFAULT_AFFINITY, FrameSelection::NonDirectional, NotUserTriggered);
}

void WebLocalFrameImpl::moveRangeSelection(const WebPoint& base, const WebPoint& extent)
{
    VisiblePosition basePosition = visiblePositionForWindowPoint(base);
    VisiblePosition extentPosition = visiblePositionForWindowPoint(extent);
    VisibleSelection newSelection = VisibleSelection(basePosition, extentPosition);
    frame()->selection().setSelection(newSelection, CharacterGranularity);
}

void WebLocalFrameImpl::moveCaretSelection(const WebPoint& point)
{
    Element* editable = frame()->selection().rootEditableElement();
    if (!editable)
        return;

    VisiblePosition position = visiblePositionForWindowPoint(point);
    frame()->selection().moveTo(position, UserTriggered);
}

bool WebLocalFrameImpl::setEditableSelectionOffsets(int start, int end)
{
    return frame()->inputMethodController().setEditableSelectionOffsets(PlainTextRange(start, end));
}

bool WebLocalFrameImpl::setCompositionFromExistingText(int compositionStart, int compositionEnd, const WebVector<WebCompositionUnderline>& underlines)
{
    if (!frame()->editor().canEdit())
        return false;

    InputMethodController& inputMethodController = frame()->inputMethodController();
    inputMethodController.cancelComposition();

    if (compositionStart == compositionEnd)
        return true;

    inputMethodController.setCompositionFromExistingText(CompositionUnderlineVectorBuilder(underlines), compositionStart, compositionEnd);

    return true;
}

void WebLocalFrameImpl::extendSelectionAndDelete(int before, int after)
{
    frame()->inputMethodController().extendSelectionAndDelete(before, after);
}

void WebLocalFrameImpl::setCaretVisible(bool visible)
{
    frame()->selection().setCaretVisible(visible);
}

VisiblePosition WebLocalFrameImpl::visiblePositionForWindowPoint(const WebPoint& point)
{
    // FIXME(bokan): crbug.com/371902 - These scale/pinch transforms shouldn't
    // be ad hoc and explicit.
    PinchViewport& pinchViewport = frame()->page()->frameHost().pinchViewport();
    FloatPoint unscaledPoint(point);
    unscaledPoint.moveBy(pinchViewport.visibleRect().location());

    HitTestRequest request = HitTestRequest::Move | HitTestRequest::ReadOnly | HitTestRequest::Active | HitTestRequest::IgnoreClipping;
    HitTestResult result(frame()->view()->windowToContents(roundedIntPoint(unscaledPoint)));
    frame()->document()->renderView()->layer()->hitTest(request, result);

    if (Node* node = result.targetNode())
        return frame()->selection().selection().visiblePositionRespectingEditingBoundary(result.localPoint(), node);
    return VisiblePosition();
}

WebString WebLocalFrameImpl::contentAsText(size_t maxChars) const
{
    if (!frame())
        return WebString();
    StringBuilder text;
    frameContentAsPlainText(maxChars, frame(), text);
    return text.toString();
}

WebString WebLocalFrameImpl::contentAsMarkup() const
{
    if (!frame())
        return WebString();
    return createMarkup(frame()->document());
}

WebString WebLocalFrameImpl::renderTreeAsText(RenderAsTextControls toShow) const
{
    RenderAsTextBehavior behavior = RenderAsTextBehaviorNormal;

    if (toShow & RenderAsTextDebug)
        behavior |= RenderAsTextShowCompositedLayers | RenderAsTextShowAddresses | RenderAsTextShowIDAndClass | RenderAsTextShowLayerNesting;

    return externalRepresentation(frame(), behavior);
}

WebString WebLocalFrameImpl::markerTextForListItem(const WebElement& webElement) const
{
    return WebString();
}

WebRect WebLocalFrameImpl::selectionBoundsRect() const
{
    return hasSelection() ? WebRect(IntRect(frame()->selection().bounds(false))) : WebRect();
}

bool WebLocalFrameImpl::selectionStartHasSpellingMarkerFor(int from, int length) const
{
    if (!frame())
        return false;
    return frame()->spellChecker().selectionStartHasSpellingMarkerFor(from, length);
}

WebString WebLocalFrameImpl::layerTreeAsText(bool showDebugInfo) const
{
    if (!frame())
        return WebString();

    return WebString(frame()->layerTreeAsText(showDebugInfo ? LayerTreeIncludesDebugInfo : LayerTreeNormal));
}

// WebLocalFrameImpl public ---------------------------------------------------------

WebLocalFrame* WebLocalFrame::create(WebFrameClient* client)
{
    return WebLocalFrameImpl::create(client);
}

WebLocalFrameImpl* WebLocalFrameImpl::create(WebFrameClient* client)
{
    return adoptRef(new WebLocalFrameImpl(client)).leakRef();
}

WebLocalFrameImpl::WebLocalFrameImpl(WebFrameClient* client)
    : m_frameLoaderClientImpl(this)
    , m_client(client)
    , m_inputEventsScaleFactorForEmulation(1)
{
    Platform::current()->incrementStatsCounter(webFrameActiveCount);
    frameCount++;
}

WebLocalFrameImpl::~WebLocalFrameImpl()
{
    Platform::current()->decrementStatsCounter(webFrameActiveCount);
    frameCount--;
}

void WebLocalFrameImpl::setCoreFrame(PassRefPtr<LocalFrame> frame)
{
    m_frame = frame;
}

PassRefPtr<LocalFrame> WebLocalFrameImpl::initializeCoreFrame(FrameHost* host)
{
    RefPtr<LocalFrame> frame = LocalFrame::create(&m_frameLoaderClientImpl, host);
    setCoreFrame(frame);
    return frame;
}

void WebLocalFrameImpl::createFrameView()
{
    TRACE_EVENT0("blink", "WebLocalFrameImpl::createFrameView");

    ASSERT(frame()); // If frame() doesn't exist, we probably didn't init properly.

    WebViewImpl* webView = viewImpl();
    webView->suppressInvalidations(true);

    frame()->createView(webView->size(), webView->baseBackgroundColor(), webView->isTransparent());
    frame()->view()->setInputEventsTransformForEmulation(m_inputEventsOffsetForEmulation, m_inputEventsScaleFactorForEmulation);

    webView->suppressInvalidations(false);
}

WebLocalFrameImpl* WebLocalFrameImpl::fromFrame(LocalFrame* frame)
{
    if (!frame)
        return 0;
    return fromFrame(*frame);
}

WebLocalFrameImpl* WebLocalFrameImpl::fromFrame(LocalFrame& frame)
{
    FrameLoaderClient* client = frame.loaderClient();
    if (!client || !client->isFrameLoaderClientImpl())
        return 0;
    return toFrameLoaderClientImpl(client)->webFrame();
}

WebViewImpl* WebLocalFrameImpl::viewImpl() const
{
    if (!frame())
        return 0;
    return WebViewImpl::fromPage(frame()->page());
}

void WebLocalFrameImpl::didFail(const ResourceError& error)
{
    if (!client())
        return;
    client()->didFailLoad(this, error);
}

void WebLocalFrameImpl::setCanHaveScrollbars(bool canHaveScrollbars)
{
    frame()->view()->setCanHaveScrollbars(canHaveScrollbars);
}

void WebLocalFrameImpl::setInputEventsTransformForEmulation(const IntSize& offset, float contentScaleFactor)
{
    m_inputEventsOffsetForEmulation = offset;
    m_inputEventsScaleFactorForEmulation = contentScaleFactor;
    if (frame()->view())
        frame()->view()->setInputEventsTransformForEmulation(m_inputEventsOffsetForEmulation, m_inputEventsScaleFactorForEmulation);
}

void WebLocalFrameImpl::invalidateAll() const
{
    ASSERT(frame() && frame()->view());
    FrameView* view = frame()->view();
    view->invalidateRect(view->frameRect());
}

} // namespace blink
