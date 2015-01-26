/*
 * Copyright (C) 2011, 2012 Google Inc. All rights reserved.
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

#include "sky/engine/config.h"
#include "sky/engine/web/WebViewImpl.h"

#include "gen/sky/core/CSSValueKeywords.h"
#include "gen/sky/core/HTMLNames.h"
#include "gen/sky/platform/RuntimeEnabledFeatures.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/DocumentMarkerController.h"
#include "sky/engine/core/dom/NodeRenderingTraversal.h"
#include "sky/engine/core/dom/Text.h"
#include "sky/engine/core/editing/Editor.h"
#include "sky/engine/core/editing/FrameSelection.h"
#include "sky/engine/core/editing/HTMLInterchange.h"
#include "sky/engine/core/editing/InputMethodController.h"
#include "sky/engine/core/editing/TextIterator.h"
#include "sky/engine/core/events/KeyboardEvent.h"
#include "sky/engine/core/frame/FrameHost.h"
#include "sky/engine/core/frame/FrameView.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/frame/NewEventHandler.h"
#include "sky/engine/core/frame/Settings.h"
#include "sky/engine/core/html/HTMLImportElement.h"
#include "sky/engine/core/html/ime/InputMethodContext.h"
#include "sky/engine/core/loader/FrameLoader.h"
#include "sky/engine/core/loader/UniqueIdentifier.h"
#include "sky/engine/core/page/AutoscrollController.h"
#include "sky/engine/core/page/Chrome.h"
#include "sky/engine/core/page/EventHandler.h"
#include "sky/engine/core/page/EventWithHitTestResults.h"
#include "sky/engine/core/page/FocusController.h"
#include "sky/engine/core/page/Page.h"
#include "sky/engine/core/rendering/RenderView.h"
#include "sky/engine/platform/Cursor.h"
#include "sky/engine/platform/KeyboardCodes.h"
#include "sky/engine/platform/Logging.h"
#include "sky/engine/platform/NotImplemented.h"
#include "sky/engine/platform/TraceEvent.h"
#include "sky/engine/platform/fonts/FontCache.h"
#include "sky/engine/platform/graphics/Color.h"
#include "sky/engine/platform/graphics/GraphicsContext.h"
#include "sky/engine/platform/graphics/Image.h"
#include "sky/engine/platform/graphics/ImageBuffer.h"
#include "sky/engine/platform/scroll/Scrollbar.h"
#include "sky/engine/public/platform/Platform.h"
#include "sky/engine/public/platform/WebFloatPoint.h"
#include "sky/engine/public/platform/WebImage.h"
#include "sky/engine/public/platform/WebLayerTreeView.h"
#include "sky/engine/public/platform/WebURLRequest.h"
#include "sky/engine/public/platform/WebVector.h"
#include "sky/engine/public/web/WebBeginFrameArgs.h"
#include "sky/engine/public/web/WebFrameClient.h"
#include "sky/engine/public/web/WebHitTestResult.h"
#include "sky/engine/public/web/WebNode.h"
#include "sky/engine/public/web/WebRange.h"
#include "sky/engine/public/web/WebTextInputInfo.h"
#include "sky/engine/public/web/WebViewClient.h"
#include "sky/engine/web/CompositionUnderlineVectorBuilder.h"
#include "sky/engine/web/WebLocalFrameImpl.h"
#include "sky/engine/web/WebSettingsImpl.h"
#include "sky/engine/wtf/CurrentTime.h"
#include "sky/engine/wtf/RefPtr.h"
#include "sky/engine/wtf/TemporaryChange.h"

// Get rid of WTF's pow define so we can use std::pow.
#undef pow
#include <cmath> // for std::pow

namespace blink {

// WebView ----------------------------------------------------------------

WebView* WebView::create(WebViewClient* client)
{
    // Pass the WebViewImpl's self-reference to the caller.
    return WebViewImpl::create(client);
}

WebViewImpl* WebViewImpl::create(WebViewClient* client)
{
    // Pass the WebViewImpl's self-reference to the caller.
    return adoptRef(new WebViewImpl(client)).leakRef();
}

void WebViewImpl::setMainFrame(WebFrame* frame)
{
    toWebLocalFrameImpl(frame)->initializeCoreFrame(&page()->frameHost());
}

void WebViewImpl::setSpellCheckClient(WebSpellCheckClient* spellCheckClient)
{
    m_spellCheckClient = spellCheckClient;
}

WebViewImpl::WebViewImpl(WebViewClient* client)
    : m_client(client)
    , m_spellCheckClient(0)
    , m_chromeClientImpl(this)
    , m_editorClientImpl(this)
    , m_spellCheckerClientImpl(this)
    , m_fixedLayoutSizeLock(false)
    , m_rootLayerScale(1)
    , m_suppressNextKeypressEvent(false)
    , m_imeAcceptEvents(true)
    , m_isTransparent(false)
    , m_rootLayer(0)
    , m_matchesHeuristicsForGpuRasterization(false)
    , m_recreatingGraphicsContext(false)
    , m_flingModifier(0)
    , m_flingSourceDevice(false)
    , m_showPaintRects(false)
    , m_showDebugBorders(false)
    , m_showScrollBottleneckRects(false)
    , m_baseBackgroundColor(Color::white)
    , m_backgroundColorOverride(Color::transparent)
{
    Page::PageClients pageClients;
    pageClients.chromeClient = &m_chromeClientImpl;
    pageClients.editorClient = &m_editorClientImpl;
    pageClients.spellCheckerClient = &m_spellCheckerClientImpl;

    m_page = adoptPtr(new Page(pageClients, m_client->services()));

    setDeviceScaleFactor(m_client->screenInfo().deviceScaleFactor);
    setVisibilityState(m_client->visibilityState(), true);

    m_client->initializeLayerTreeView();
}

WebViewImpl::~WebViewImpl()
{
    ASSERT(!m_page);
}

WebLocalFrameImpl* WebViewImpl::mainFrameImpl()
{
    return m_page ? WebLocalFrameImpl::fromFrame(m_page->mainFrame()) : 0;
}

void WebViewImpl::setShowPaintRects(bool show)
{
    m_showPaintRects = show;
}

void WebViewImpl::setShowDebugBorders(bool show)
{
    m_showDebugBorders = show;
}

void WebViewImpl::setShowScrollBottleneckRects(bool show)
{
    m_showScrollBottleneckRects = show;
}

void WebViewImpl::acceptLanguagesChanged()
{
    if (!page())
        return;

    page()->acceptLanguagesChanged();
}

LocalFrame* WebViewImpl::focusedCoreFrame() const
{
    return m_page ? m_page->focusController().focusedOrMainFrame() : 0;
}

WebViewImpl* WebViewImpl::fromPage(Page* page)
{
    if (!page)
        return 0;
    return static_cast<WebViewImpl*>(page->chrome().client().webView());
}

// WebWidget ------------------------------------------------------------------

void WebViewImpl::close()
{
    if (m_page) {
        // Initiate shutdown for the entire frameset.  This will cause a lot of
        // notifications to be sent.
        m_page->willBeDestroyed();
        m_page.clear();
    }

    // Reset the delegate to prevent notifications being sent as we're being
    // deleted.
    m_client = 0;

    deref();  // Balances ref() acquired in WebView::create
}

WebSize WebViewImpl::size()
{
    return m_size;
}

void WebViewImpl::performResize()
{
    updateMainFrameLayoutSize();

    // If the virtual viewport pinch mode is enabled, the main frame will be resized
    // after layout so it can be sized to the contentsSize.
    if (FrameView* view = m_page->mainFrame()->view())
        view->resize(m_size);
}

void WebViewImpl::resize(const WebSize& newSize)
{
    if (m_size == newSize)
        return;

    FrameView* view = m_page->mainFrame()->view();
    if (!view)
        return;

    m_size = newSize;
    performResize();
    sendResizeEventAndRepaint();
}

void WebViewImpl::beginFrame(const WebBeginFrameArgs& frameTime)
{
    TRACE_EVENT0("blink", "WebViewImpl::beginFrame");

    WebBeginFrameArgs validFrameTime(frameTime);
    if (!validFrameTime.lastFrameTimeMonotonic)
        validFrameTime.lastFrameTimeMonotonic = monotonicallyIncreasingTime();

    WTF_LOG(ScriptedAnimationController, "WebViewImpl::beginFrame: page = %d", !m_page ? 0 : 1);
    if (!m_page)
        return;

    RefPtr<FrameView> view = m_page->mainFrame()->view();
    if (!view)
        return;
    m_page->autoscrollController().animate(validFrameTime.lastFrameTimeMonotonic);
    m_page->animator().serviceScriptedAnimations(validFrameTime.lastFrameTimeMonotonic);
}

void WebViewImpl::layout()
{
    TRACE_EVENT0("blink", "WebViewImpl::layout");
    if (!m_page)
        return;
    m_page->animator().updateLayoutAndStyleForPainting(m_page->mainFrame());
}

void WebViewImpl::paint(WebCanvas* canvas, const WebRect& rect)
{
    if (rect.isEmpty())
        return;
    GraphicsContext gc(canvas);
    gc.setCertainlyOpaque(!isTransparent());
    gc.applyDeviceScaleFactor(m_page->deviceScaleFactor());
    gc.setDeviceScaleFactor(m_page->deviceScaleFactor());
    IntRect dirtyRect(rect);
    gc.save(); // Needed to save the canvas, not the GraphicsContext.
    FrameView* view = m_page->mainFrame()->view();
    if (view) {
        gc.clip(dirtyRect);
        view->paint(&gc, dirtyRect);
    } else {
        gc.fillRect(dirtyRect, Color::white);
    }
    gc.restore();
}

// FIXME: autogenerate this kind of code, and use it throughout Blink rather than
// the one-offs for subsets of these values.
static String inputTypeToName(WebInputEvent::Type type)
{
    switch (type) {
    case WebInputEvent::KeyDown:
        return EventTypeNames::keydown;
    case WebInputEvent::KeyUp:
        return EventTypeNames::keyup;
    case WebInputEvent::GestureScrollBegin:
        return EventTypeNames::gesturescrollstart;
    case WebInputEvent::GestureScrollEnd:
        return EventTypeNames::gesturescrollend;
    case WebInputEvent::GestureScrollUpdate:
        return EventTypeNames::gesturescrollupdate;
    case WebInputEvent::GestureTapDown:
        return EventTypeNames::gesturetapdown;
    case WebInputEvent::GestureShowPress:
        return EventTypeNames::gestureshowpress;
    case WebInputEvent::GestureTap:
        return EventTypeNames::gesturetap;
    case WebInputEvent::GestureTapUnconfirmed:
        return EventTypeNames::gesturetapunconfirmed;
    default:
        return String("unknown");
    }
}

bool WebViewImpl::handleInputEvent(const WebInputEvent& inputEvent)
{
    TRACE_EVENT1("input", "WebViewImpl::handleInputEvent", "type", inputTypeToName(inputEvent.type).ascii().data());

    if (WebInputEvent::isPointerEventType(inputEvent.type)) {
        const WebPointerEvent& event = static_cast<const WebPointerEvent&>(inputEvent);
        return m_page->mainFrame()->newEventHandler().handlePointerEvent(event);
    }

    if (WebInputEvent::isGestureEventType(inputEvent.type)) {
        const WebGestureEvent& event = static_cast<const WebGestureEvent&>(inputEvent);
        return m_page->mainFrame()->newEventHandler().handleGestureEvent(event);
    }

    if (WebInputEvent::isKeyboardEventType(inputEvent.type)) {
        const WebKeyboardEvent& event = static_cast<const WebKeyboardEvent&>(inputEvent);
        return m_page->mainFrame()->newEventHandler().handleKeyboardEvent(event);
    }

    return false;
}

void WebViewImpl::setFocus(bool enable)
{
    m_page->focusController().setFocused(enable);
    if (enable) {
        m_page->focusController().setActive(true);
        RefPtr<LocalFrame> focusedFrame = m_page->focusController().focusedFrame();
        if (focusedFrame) {
            LocalFrame* localFrame = focusedFrame.get();
            Element* element = localFrame->document()->focusedElement();
            if (element && localFrame->selection().selection().isNone()) {
                // If the selection was cleared while the WebView was not
                // focused, then the focus element shows with a focus ring but
                // no caret and does respond to keyboard inputs.
                if (element->isContentEditable()) {
                    // updateFocusAppearance() selects all the text of
                    // contentseditable DIVs. So we set the selection explicitly
                    // instead. Note that this has the side effect of moving the
                    // caret back to the beginning of the text.
                    Position position(element, 0, Position::PositionIsOffsetInAnchor);
                    localFrame->selection().setSelection(VisibleSelection(position, SEL_DEFAULT_AFFINITY));
                }
            }
        }
        m_imeAcceptEvents = true;
    } else {
        // Clear focus on the currently focused frame if any.
        if (!m_page)
            return;

        RefPtr<LocalFrame> focusedFrame = m_page->focusController().focusedFrame();
        if (focusedFrame) {
            // Finish an ongoing composition to delete the composition node.
            if (focusedFrame->inputMethodController().hasComposition()) {
                focusedFrame->inputMethodController().confirmComposition();
            }
            m_imeAcceptEvents = false;
        }
    }
}

bool WebViewImpl::setComposition(
    const WebString& text,
    const WebVector<WebCompositionUnderline>& underlines,
    int selectionStart,
    int selectionEnd)
{
    LocalFrame* focused = focusedCoreFrame();
    if (!focused || !m_imeAcceptEvents)
        return false;

    // The input focus has been moved to another WebWidget object.
    // We should use this |editor| object only to complete the ongoing
    // composition.
    InputMethodController& inputMethodController = focused->inputMethodController();
    if (!focused->editor().canEdit() && !inputMethodController.hasComposition())
        return false;

    // We should verify the parent node of this IME composition node are
    // editable because JavaScript may delete a parent node of the composition
    // node. In this case, WebKit crashes while deleting texts from the parent
    // node, which doesn't exist any longer.
    RefPtr<Range> range = inputMethodController.compositionRange();
    if (range) {
        Node* node = range->startContainer();
        if (!node || !node->isContentEditable())
            return false;
    }

    // If we're not going to fire a keypress event, then the keydown event was
    // canceled.  In that case, cancel any existing composition.
    if (text.isEmpty() || m_suppressNextKeypressEvent) {
        // A browser process sent an IPC message which does not contain a valid
        // string, which means an ongoing composition has been canceled.
        // If the ongoing composition has been canceled, replace the ongoing
        // composition string with an empty string and complete it.
        String emptyString;
        Vector<CompositionUnderline> emptyUnderlines;
        inputMethodController.setComposition(emptyString, emptyUnderlines, 0, 0);
        return text.isEmpty();
    }

    // When the range of composition underlines overlap with the range between
    // selectionStart and selectionEnd, WebKit somehow won't paint the selection
    // at all (see InlineTextBox::paint() function in InlineTextBox.cpp).
    // But the selection range actually takes effect.
    inputMethodController.setComposition(String(text),
                           CompositionUnderlineVectorBuilder(underlines),
                           selectionStart, selectionEnd);

    return inputMethodController.hasComposition();
}

bool WebViewImpl::confirmComposition()
{
    return confirmComposition(DoNotKeepSelection);
}

bool WebViewImpl::confirmComposition(ConfirmCompositionBehavior selectionBehavior)
{
    return confirmComposition(WebString(), selectionBehavior);
}

bool WebViewImpl::confirmComposition(const WebString& text)
{
    return confirmComposition(text, DoNotKeepSelection);
}

bool WebViewImpl::confirmComposition(const WebString& text, ConfirmCompositionBehavior selectionBehavior)
{
    LocalFrame* focused = focusedCoreFrame();
    if (!focused || !m_imeAcceptEvents)
        return false;

    return focused->inputMethodController().confirmCompositionOrInsertText(text, selectionBehavior == KeepSelection ? InputMethodController::KeepSelection : InputMethodController::DoNotKeepSelection);
}

bool WebViewImpl::compositionRange(size_t* location, size_t* length)
{
    LocalFrame* focused = focusedCoreFrame();
    if (!focused || !m_imeAcceptEvents)
        return false;

    RefPtr<Range> range = focused->inputMethodController().compositionRange();
    if (!range)
        return false;

    Element* editable = focused->selection().rootEditableElementOrDocumentElement();
    ASSERT(editable);
    PlainTextRange plainTextRange(PlainTextRange::create(*editable, *range.get()));
    if (plainTextRange.isNull())
        return false;
    *location = plainTextRange.start();
    *length = plainTextRange.length();
    return true;
}

WebTextInputInfo WebViewImpl::textInputInfo()
{
    WebTextInputInfo info;

    LocalFrame* focused = focusedCoreFrame();
    if (!focused)
        return info;

    FrameSelection& selection = focused->selection();
    Element* element = selection.selection().rootEditableElement();
    if (!element)
        return info;

    info.inputMode = inputModeOfFocusedElement();

    info.type = textInputType();
    info.flags = textInputFlags();
    if (info.type == WebTextInputTypeNone)
        return info;

    if (!focused->editor().canEdit())
        return info;

    // Emits an object replacement character for each replaced element so that
    // it is exposed to IME and thus could be deleted by IME on android.
    info.value = plainText(rangeOfContents(element).get(), TextIteratorEmitsObjectReplacementCharacter);

    if (info.value.isEmpty())
        return info;

    if (RefPtr<Range> range = selection.selection().firstRange()) {
        PlainTextRange plainTextRange(PlainTextRange::create(*element, *range.get()));
        if (plainTextRange.isNotNull()) {
            info.selectionStart = plainTextRange.start();
            info.selectionEnd = plainTextRange.end();
        }
    }

    if (RefPtr<Range> range = focused->inputMethodController().compositionRange()) {
        PlainTextRange plainTextRange(PlainTextRange::create(*element, *range.get()));
        if (plainTextRange.isNotNull()) {
            info.compositionStart = plainTextRange.start();
            info.compositionEnd = plainTextRange.end();
        }
    }

    return info;
}

WebTextInputType WebViewImpl::textInputType()
{
    Element* element = focusedElement();
    if (!element)
        return WebTextInputTypeNone;

    if (element->isContentEditable(Node::UserSelectAllIsAlwaysNonEditable))
        return WebTextInputTypeContentEditable;

    return WebTextInputTypeNone;
}

int WebViewImpl::textInputFlags()
{
    Element* element = focusedElement();
    if (!element)
        return WebTextInputFlagNone;

    int flags = 0;

    const AtomicString& autocomplete = element->getAttribute("autocomplete");
    if (autocomplete == "on")
        flags |= WebTextInputFlagAutocompleteOn;
    else if (autocomplete == "off")
        flags |= WebTextInputFlagAutocompleteOff;

    const AtomicString& autocorrect = element->getAttribute("autocorrect");
    if (autocorrect == "on")
        flags |= WebTextInputFlagAutocorrectOn;
    else if (autocorrect == "off")
        flags |= WebTextInputFlagAutocorrectOff;

    const AtomicString& spellcheck = element->getAttribute("spellcheck");
    if (spellcheck == "on")
        flags |= WebTextInputFlagSpellcheckOn;
    else if (spellcheck == "off")
        flags |= WebTextInputFlagSpellcheckOff;

    return flags;
}

WebString WebViewImpl::inputModeOfFocusedElement()
{
    return WebString();
}

InputMethodContext* WebViewImpl::inputMethodContext()
{
    if (!m_imeAcceptEvents)
        return 0;

    LocalFrame* focusedFrame = focusedCoreFrame();
    if (!focusedFrame)
        return 0;

    Element* target = focusedFrame->document()->focusedElement();
    if (target && target->hasInputMethodContext())
        return &target->inputMethodContext();

    return 0;
}

void WebViewImpl::didShowCandidateWindow()
{
    if (InputMethodContext* context = inputMethodContext())
        context->dispatchCandidateWindowShowEvent();
}

void WebViewImpl::didUpdateCandidateWindow()
{
    if (InputMethodContext* context = inputMethodContext())
        context->dispatchCandidateWindowUpdateEvent();
}

void WebViewImpl::didHideCandidateWindow()
{
    if (InputMethodContext* context = inputMethodContext())
        context->dispatchCandidateWindowHideEvent();
}

WebVector<WebCompositionUnderline> WebViewImpl::compositionUnderlines() const
{
    const LocalFrame* focused = focusedCoreFrame();
    if (!focused)
        return WebVector<WebCompositionUnderline>();
    const Vector<CompositionUnderline>& underlines = focused->inputMethodController().customCompositionUnderlines();
    WebVector<WebCompositionUnderline> results(underlines.size());
    for (size_t index = 0; index < underlines.size(); ++index) {
        CompositionUnderline underline = underlines[index];
        results[index] = WebCompositionUnderline(underline.startOffset, underline.endOffset, static_cast<WebColor>(underline.color.rgb()), underline.thick, static_cast<WebColor>(underline.backgroundColor.rgb()));
    }
    return results;
}

WebColor WebViewImpl::backgroundColor() const
{
    if (isTransparent())
        return Color::transparent;
    if (!m_page)
        return m_baseBackgroundColor;
    if (!m_page->mainFrame())
        return m_baseBackgroundColor;
    FrameView* view = m_page->mainFrame()->view();
    return view->documentBackgroundColor().rgb();
}

// WebView --------------------------------------------------------------------

WebSettingsImpl* WebViewImpl::settingsImpl()
{
    if (!m_webSettings)
        m_webSettings = adoptPtr(new WebSettingsImpl(&m_page->settings()));
    ASSERT(m_webSettings);
    return m_webSettings.get();
}

WebSettings* WebViewImpl::settings()
{
    return settingsImpl();
}

WebFrame* WebViewImpl::mainFrame()
{
    return WebFrame::fromFrame(m_page ? m_page->mainFrame() : 0);
}

WebFrame* WebViewImpl::focusedFrame()
{
    return WebFrame::fromFrame(focusedCoreFrame());
}

void WebViewImpl::injectModule(const WebString& path)
{
    RefPtr<Document> document = m_page->mainFrame()->document();
    RefPtr<HTMLImportElement> import = HTMLImportElement::create(*document);
    import->setAttribute(HTMLNames::srcAttr, path);
    if (!document->documentElement())
        return;
    document->documentElement()->appendChild(import.release());
}

void WebViewImpl::setFocusedFrame(WebFrame* frame)
{
    if (!frame) {
        // Clears the focused frame if any.
        LocalFrame* focusedFrame = focusedCoreFrame();
        if (focusedFrame)
            focusedFrame->selection().setFocused(false);
        return;
    }
    LocalFrame* coreFrame = toWebLocalFrameImpl(frame)->frame();
    coreFrame->page()->focusController().setFocusedFrame(coreFrame);
}

void WebViewImpl::setInitialFocus(bool reverse)
{
    if (!m_page)
        return;
    LocalFrame* frame = page()->focusController().focusedOrMainFrame();
    if (Document* document = frame->document())
        document->setFocusedElement(nullptr);
    page()->focusController().setInitialFocus(reverse ? FocusTypeBackward : FocusTypeForward);
}

void WebViewImpl::clearFocusedElement()
{
    RefPtr<LocalFrame> localFrame = focusedCoreFrame();
    if (!localFrame)
        return;

    RefPtr<Document> document = localFrame->document();
    if (!document)
        return;

    RefPtr<Element> oldFocusedElement = document->focusedElement();

    // Clear the focused node.
    document->setFocusedElement(nullptr);

    if (!oldFocusedElement)
        return;

    // If a text field has focus, we need to make sure the selection controller
    // knows to remove selection from it. Otherwise, the text field is still
    // processing keyboard events even though focus has been moved to the page and
    // keystrokes get eaten as a result.
    if (oldFocusedElement->isContentEditable())
        localFrame->selection().clear();
}

void WebViewImpl::advanceFocus(bool reverse)
{
    page()->focusController().advanceFocus(reverse ? FocusTypeBackward : FocusTypeForward);
}

IntPoint WebViewImpl::clampOffsetAtScale(const IntPoint& offset, float scale)
{
    FrameView* view = mainFrameImpl()->frameView();
    if (!view)
        return offset;

    return view->clampOffsetAtScale(offset, scale);
}

float WebViewImpl::deviceScaleFactor() const
{
    if (!page())
        return 1;

    return page()->deviceScaleFactor();
}

void WebViewImpl::setDeviceScaleFactor(float scaleFactor)
{
    if (!page())
        return;

    page()->setDeviceScaleFactor(scaleFactor);
}

void WebViewImpl::updateMainFrameLayoutSize()
{
    if (m_fixedLayoutSizeLock || !mainFrameImpl())
        return;

    RefPtr<FrameView> view = mainFrameImpl()->frameView();
    if (!view)
        return;

    WebSize layoutSize = m_size;

    if (page()->settings().forceZeroLayoutHeight())
        layoutSize.height = 0;

    view->setLayoutSize(layoutSize);
}

IntSize WebViewImpl::contentsSize() const
{
    RenderView* root = page()->mainFrame()->contentRenderer();
    if (!root)
        return IntSize();
    return root->documentRect().size();
}

WebHitTestResult WebViewImpl::hitTestResultAt(const WebPoint& point)
{
    return coreHitTestResultAt(point);
}

HitTestResult WebViewImpl::coreHitTestResultAt(const WebPoint& point)
{
    IntPoint scaledPoint = point;
    return hitTestResultForWindowPos(scaledPoint);
}

void WebViewImpl::spellingMarkers(WebVector<uint32_t>* markers)
{
    Vector<uint32_t> result;
    LocalFrame* frame = m_page->mainFrame();
    const DocumentMarkerVector& documentMarkers = frame->document()->markers().markers();
    for (size_t i = 0; i < documentMarkers.size(); ++i)
        result.append(documentMarkers[i]->hash());
    markers->assign(result);
}

void WebViewImpl::removeSpellingMarkersUnderWords(const WebVector<WebString>& words)
{
    Vector<String> convertedWords;
    convertedWords.append(words.data(), words.size());

    LocalFrame* frame = m_page->mainFrame();
    frame->removeSpellingMarkersUnderWords(convertedWords);
}

void WebViewImpl::sendResizeEventAndRepaint()
{
    // FIXME: This is wrong. The FrameView is responsible sending a resizeEvent
    // as part of layout. Layout is also responsible for sending invalidations
    // to the embedder. This method and all callers may be wrong. -- eseidel.
    if (m_page->mainFrame()->view()) {
        // Enqueues the resize event.
        m_page->mainFrame()->document()->enqueueResizeEvent();
    }
}

void WebViewImpl::setIsTransparent(bool isTransparent)
{
    // Set any existing frames to be transparent.
    m_page->mainFrame()->view()->setTransparent(isTransparent);

    // Future frames check this to know whether to be transparent.
    m_isTransparent = isTransparent;
}

bool WebViewImpl::isTransparent() const
{
    return m_isTransparent;
}

// FIXME(sky): This is an android webview feature. Remove it.
void WebViewImpl::setBaseBackgroundColor(WebColor color)
{
    layout();

    if (m_baseBackgroundColor == color)
        return;

    m_baseBackgroundColor = color;

    if (m_page->mainFrame())
        m_page->mainFrame()->view()->setBaseBackgroundColor(color);
}

void WebViewImpl::setIsActive(bool active)
{
    if (page())
        page()->focusController().setActive(active);
}

bool WebViewImpl::isActive() const
{
    return page() ? page()->focusController().isActive() : false;
}

void WebViewImpl::didCommitLoad(bool isNewNavigation, bool isNavigationWithinPage)
{
}

void WebViewImpl::layoutUpdated(WebLocalFrameImpl* webframe)
{
    if (!m_client)
        return;
    m_client->didUpdateLayout();
}

void WebViewImpl::setBackgroundColorOverride(WebColor color)
{
    m_backgroundColorOverride = color;
}

Element* WebViewImpl::focusedElement() const
{
    LocalFrame* frame = m_page->focusController().focusedFrame();
    if (!frame)
        return 0;

    Document* document = frame->document();
    if (!document)
        return 0;

    return document->focusedElement();
}

HitTestResult WebViewImpl::hitTestResultForWindowPos(const IntPoint& pos)
{
    IntPoint docPoint(m_page->mainFrame()->view()->windowToContents(pos));
    HitTestResult result = m_page->mainFrame()->eventHandler().hitTestResultAtPoint(docPoint, HitTestRequest::ReadOnly | HitTestRequest::Active);
    return result;
}

void WebViewImpl::scheduleAnimation()
{
    m_client->scheduleAnimation();
}

void WebViewImpl::setVisibilityState(WebPageVisibilityState visibilityState,
                                     bool isInitialState) {
    if (!page())
        return;

    ASSERT(visibilityState == WebPageVisibilityStateVisible || visibilityState == WebPageVisibilityStateHidden);
    m_page->setVisibilityState(static_cast<PageVisibilityState>(static_cast<int>(visibilityState)), isInitialState);
}

} // namespace blink
