/*
 * Copyright (C) 2009 Google Inc. All rights reserved.
 * Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies).
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

#include "config.h"
#include "web/ChromeClientImpl.h"

#include "bindings/core/v8/ScriptController.h"
#include "core/dom/Document.h"
#include "core/dom/Node.h"
#include "core/events/KeyboardEvent.h"
#include "core/events/MouseEvent.h"
#include "core/events/WheelEvent.h"
#include "core/frame/Console.h"
#include "core/frame/FrameView.h"
#include "core/frame/Settings.h"
#include "core/page/Page.h"
#include "core/rendering/HitTestResult.h"
#include "core/rendering/RenderPart.h"
#include "core/rendering/RenderWidget.h"
#include "platform/Cursor.h"
#include "platform/NotImplemented.h"
#include "platform/PlatformScreen.h"
#include "platform/RuntimeEnabledFeatures.h"
#include "platform/exported/WrappedResourceRequest.h"
#include "platform/geometry/FloatRect.h"
#include "platform/geometry/IntRect.h"
#include "platform/graphics/GraphicsLayer.h"
#include "public/platform/Platform.h"
#include "public/platform/WebCursorInfo.h"
#include "public/platform/WebRect.h"
#include "public/platform/WebURLRequest.h"
#include "public/web/WebAXObject.h"
#include "public/web/WebColorSuggestion.h"
#include "public/web/WebConsoleMessage.h"
#include "public/web/WebFrameClient.h"
#include "public/web/WebInputEvent.h"
#include "public/web/WebKit.h"
#include "public/web/WebNode.h"
#include "public/web/WebSettings.h"
#include "public/web/WebTextDirection.h"
#include "public/web/WebTouchAction.h"
#include "public/web/WebUserGestureIndicator.h"
#include "public/web/WebUserGestureToken.h"
#include "public/web/WebViewClient.h"
#include "web/WebInputEventConversion.h"
#include "web/WebLocalFrameImpl.h"
#include "web/WebSettingsImpl.h"
#include "web/WebViewImpl.h"
#include "wtf/text/CString.h"
#include "wtf/text/StringBuilder.h"
#include "wtf/text/StringConcatenate.h"
#include "wtf/unicode/CharacterNames.h"

namespace blink {

ChromeClientImpl::ChromeClientImpl(WebViewImpl* webView)
    : m_webView(webView)
{
}

ChromeClientImpl::~ChromeClientImpl()
{
}

void* ChromeClientImpl::webView() const
{
    return static_cast<void*>(m_webView);
}

void ChromeClientImpl::chromeDestroyed()
{
    // Our lifetime is bound to the WebViewImpl.
}

void ChromeClientImpl::setWindowRect(const FloatRect& r)
{
    if (m_webView->client())
        m_webView->client()->setWindowRect(IntRect(r));
}

FloatRect ChromeClientImpl::windowRect()
{
    WebRect rect;
    if (m_webView->client())
        rect = m_webView->client()->rootWindowRect();
    else {
        // These numbers will be fairly wrong. The window's x/y coordinates will
        // be the top left corner of the screen and the size will be the content
        // size instead of the window size.
        rect.width = m_webView->size().width;
        rect.height = m_webView->size().height;
    }
    return FloatRect(rect);
}

FloatRect ChromeClientImpl::pageRect()
{
    // We hide the details of the window's border thickness from the web page by
    // simple re-using the window position here.  So, from the point-of-view of
    // the web page, the window has no border.
    return windowRect();
}

void ChromeClientImpl::focus()
{
    if (m_webView->client())
        m_webView->client()->didFocus();
}

bool ChromeClientImpl::canTakeFocus(FocusType)
{
    // For now the browser can always take focus if we're not running layout
    // tests.
    return !layoutTestMode();
}

void ChromeClientImpl::takeFocus(FocusType type)
{
    if (!m_webView->client())
        return;
    if (type == FocusTypeBackward)
        m_webView->client()->focusPrevious();
    else
        m_webView->client()->focusNext();
}

void ChromeClientImpl::focusedNodeChanged(Node* node)
{
    m_webView->client()->focusedNodeChanged(WebNode(node));

    WebURL focusURL;
    if (node && node->isElementNode() && toElement(node)->isLiveLink())
        focusURL = toElement(node)->hrefURL();
    m_webView->client()->setKeyboardFocusURL(focusURL);
}

void ChromeClientImpl::focusedFrameChanged(LocalFrame* frame)
{
    WebLocalFrameImpl* webframe = WebLocalFrameImpl::fromFrame(frame);
    if (webframe && webframe->client())
        webframe->client()->frameFocused();
}

static inline void updatePolicyForEvent(const WebInputEvent* inputEvent, NavigationPolicy* policy)
{
    if (!inputEvent || inputEvent->type != WebInputEvent::MouseUp)
        return;

    const WebMouseEvent* mouseEvent = static_cast<const WebMouseEvent*>(inputEvent);

    unsigned short buttonNumber;
    switch (mouseEvent->button) {
    case WebMouseEvent::ButtonLeft:
        buttonNumber = 0;
        break;
    case WebMouseEvent::ButtonMiddle:
        buttonNumber = 1;
        break;
    case WebMouseEvent::ButtonRight:
        buttonNumber = 2;
        break;
    default:
        return;
    }
    bool ctrl = mouseEvent->modifiers & WebMouseEvent::ControlKey;
    bool shift = mouseEvent->modifiers & WebMouseEvent::ShiftKey;
    bool alt = mouseEvent->modifiers & WebMouseEvent::AltKey;
    bool meta = mouseEvent->modifiers & WebMouseEvent::MetaKey;

    NavigationPolicy userPolicy = *policy;
    navigationPolicyFromMouseEvent(buttonNumber, ctrl, shift, alt, meta, &userPolicy);
    // User and app agree that we want a new window; let the app override the decorations.
    if (userPolicy == NavigationPolicyNewWindow && *policy == NavigationPolicyNewPopup)
        return;
    *policy = userPolicy;
}

WebNavigationPolicy ChromeClientImpl::getNavigationPolicy()
{
    NavigationPolicy policy = NavigationPolicyNewForegroundTab;
    updatePolicyForEvent(WebViewImpl::currentInputEvent(), &policy);

    return static_cast<WebNavigationPolicy>(policy);
}

void ChromeClientImpl::show(NavigationPolicy navigationPolicy)
{
    if (!m_webView->client())
        return;

    WebNavigationPolicy policy = static_cast<WebNavigationPolicy>(navigationPolicy);
    if (policy == WebNavigationPolicyIgnore)
        policy = getNavigationPolicy();
    m_webView->client()->show(policy);
}

bool ChromeClientImpl::shouldReportDetailedMessageForSource(const String& url)
{
    WebLocalFrameImpl* webframe = m_webView->localFrameRootTemporary();
    return webframe->client() && webframe->client()->shouldReportDetailedMessageForSource(url);
}

inline static String messageLevelAsString(MessageLevel level)
{
    switch(level) {
        case DebugMessageLevel:
            return "DEBUG";
        case LogMessageLevel:
            return "LOG";
        case WarningMessageLevel:
            return "WARNING";
        case ErrorMessageLevel:
            return "ERROR";
        case InfoMessageLevel:
            return "INFO";
    }
    return "MESSAGE:";
}


void ChromeClientImpl::addMessageToConsole(LocalFrame* localFrame, MessageSource source, MessageLevel level, const String& message, unsigned lineNumber, const String& sourceID, const String& stackTrace)
{

    if (level == ErrorMessageLevel)
        printf("ERROR: %s \nSOURCE: %s:%u\n", message.utf8().data(), sourceID.utf8().data(), lineNumber);
    else
        printf("CONSOLE: %s: %s\n", messageLevelAsString(level).utf8().data(), message.utf8().data());

    WebLocalFrameImpl* frame = WebLocalFrameImpl::fromFrame(localFrame);
    if (frame && frame->client()) {
        frame->client()->didAddMessageToConsole(
            WebConsoleMessage(static_cast<WebConsoleMessage::Level>(level), message),
            sourceID,
            lineNumber,
            stackTrace);
    }
}

bool ChromeClientImpl::tabsToLinks()
{
    return m_webView->tabsToLinks();
}

void ChromeClientImpl::invalidateContentsAndRootView(const IntRect& updateRect)
{
    if (updateRect.isEmpty())
        return;
    m_webView->invalidateRect(updateRect);
}

void ChromeClientImpl::invalidateContentsForSlowScroll(const IntRect& updateRect)
{
    invalidateContentsAndRootView(updateRect);
}

void ChromeClientImpl::scheduleAnimation()
{
    m_webView->scheduleAnimation();
}

IntRect ChromeClientImpl::rootViewToScreen(const IntRect& rect) const
{
    IntRect screenRect(rect);

    if (m_webView->client()) {
        WebRect windowRect = m_webView->client()->windowRect();
        screenRect.move(windowRect.x, windowRect.y);
    }

    return screenRect;
}

WebScreenInfo ChromeClientImpl::screenInfo() const
{
    return m_webView->client() ? m_webView->client()->screenInfo() : WebScreenInfo();
}

void ChromeClientImpl::layoutUpdated(LocalFrame* frame) const
{
    m_webView->layoutUpdated(WebLocalFrameImpl::fromFrame(frame));
}

void ChromeClientImpl::mouseDidMoveOverElement(
    const HitTestResult& result, unsigned modifierFlags)
{
    if (!m_webView->client())
        return;

    WebURL url;
    // Find out if the mouse is over a link, and if so, let our UI know...
    if (result.isLiveLink() && !result.absoluteLinkURL().string().isEmpty())
        url = result.absoluteLinkURL();

    m_webView->client()->setMouseOverURL(url);
}

void ChromeClientImpl::setToolTip(const String& tooltipText, TextDirection dir)
{
    if (m_webView->client())
        m_webView->client()->setToolTipText(tooltipText, toWebTextDirection(dir));
}

void ChromeClientImpl::dispatchViewportPropertiesDidChange(const ViewportDescription& description) const
{
    m_webView->updatePageDefinedViewportConstraints(description);
}

void ChromeClientImpl::setCursor(const Cursor& cursor)
{
    setCursor(WebCursorInfo(cursor));
}

void ChromeClientImpl::setCursor(const WebCursorInfo& cursor)
{
    if (m_webView->client())
        m_webView->client()->didChangeCursor(cursor);
}

String ChromeClientImpl::acceptLanguages()
{
    return m_webView->client()->acceptLanguages();
}

bool ChromeClientImpl::paintCustomOverhangArea(GraphicsContext* context, const IntRect& horizontalOverhangArea, const IntRect& verticalOverhangArea, const IntRect& dirtyRect)
{
    return false;
}

GraphicsLayerFactory* ChromeClientImpl::graphicsLayerFactory() const
{
    return m_webView->graphicsLayerFactory();
}

void ChromeClientImpl::attachRootGraphicsLayer(GraphicsLayer* rootLayer)
{
    m_webView->setRootGraphicsLayer(rootLayer);
}

void ChromeClientImpl::clearCompositedSelectionBounds()
{
    m_webView->clearCompositedSelectionBounds();
}

void ChromeClientImpl::needTouchEvents(bool needsTouchEvents)
{
    m_webView->hasTouchEventHandlers(needsTouchEvents);
}

void ChromeClientImpl::setTouchAction(TouchAction touchAction)
{
    if (WebViewClient* client = m_webView->client()) {
        WebTouchAction webTouchAction = static_cast<WebTouchAction>(touchAction);
        client->setTouchAction(webTouchAction);
    }
}

void ChromeClientImpl::willSetInputMethodState()
{
    if (m_webView->client())
        m_webView->client()->resetInputMethod();
}

void ChromeClientImpl::didUpdateTextOfFocusedElementByNonUserInput()
{
    if (m_webView->client())
        m_webView->client()->didUpdateTextOfFocusedElementByNonUserInput();
}

void ChromeClientImpl::showImeIfNeeded()
{
    if (m_webView->client())
        m_webView->client()->showImeIfNeeded();
}

// FIXME: Remove this code once we have input routing in the browser
// process. See http://crbug.com/339659.
void ChromeClientImpl::forwardInputEvent(
    Frame* frame, Event* event)
{
    WebLocalFrameImpl* webFrame = WebLocalFrameImpl::fromFrame(toLocalFrame(frame));

    // This is only called when we have out-of-process iframes, which
    // need to forward input events across processes.
    // FIXME: Add a check for out-of-process iframes enabled.
    if (event->isKeyboardEvent()) {
        WebKeyboardEventBuilder webEvent(*static_cast<KeyboardEvent*>(event));
        webFrame->client()->forwardInputEvent(&webEvent);
    } else if (event->isMouseEvent()) {
        WebMouseEventBuilder webEvent(webFrame->frameView(), 0, *static_cast<MouseEvent*>(event));
        // Internal Blink events should not be forwarded.
        if (webEvent.type == WebInputEvent::Undefined)
            return;

        webFrame->client()->forwardInputEvent(&webEvent);
    } else if (event->isWheelEvent()) {
        WebMouseWheelEventBuilder webEvent(webFrame->frameView(), 0, *static_cast<WheelEvent*>(event));
        if (webEvent.type == WebInputEvent::Undefined)
            return;
        webFrame->client()->forwardInputEvent(&webEvent);
    }
}

} // namespace blink
