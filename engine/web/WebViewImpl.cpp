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

#include "config.h"
#include "web/WebViewImpl.h"

#include "core/CSSValueKeywords.h"
#include "core/HTMLNames.h"
#include "core/dom/Document.h"
#include "core/dom/DocumentMarkerController.h"
#include "core/dom/NodeRenderingTraversal.h"
#include "core/dom/Text.h"
#include "core/editing/Editor.h"
#include "core/editing/FrameSelection.h"
#include "core/editing/HTMLInterchange.h"
#include "core/editing/InputMethodController.h"
#include "core/editing/TextIterator.h"
#include "core/editing/markup.h"
#include "core/events/KeyboardEvent.h"
#include "core/events/WheelEvent.h"
#include "core/frame/EventHandlerRegistry.h"
#include "core/frame/FrameHost.h"
#include "core/frame/FrameView.h"
#include "core/frame/LocalFrame.h"
#include "core/frame/Settings.h"
#include "core/html/HTMLMediaElement.h"
#include "core/html/ime/InputMethodContext.h"
#include "core/loader/FrameLoader.h"
#include "core/loader/UniqueIdentifier.h"
#include "core/page/Chrome.h"
#include "core/page/EventHandler.h"
#include "core/page/EventWithHitTestResults.h"
#include "core/page/FocusController.h"
#include "core/page/Page.h"
#include "core/page/TouchDisambiguation.h"
#include "core/rendering/RenderView.h"
#include "core/rendering/compositing/RenderLayerCompositor.h"
#include "platform/Cursor.h"
#include "platform/KeyboardCodes.h"
#include "platform/Logging.h"
#include "platform/NotImplemented.h"
#include "platform/PlatformGestureEvent.h"
#include "platform/PlatformKeyboardEvent.h"
#include "platform/PlatformMouseEvent.h"
#include "platform/PlatformWheelEvent.h"
#include "platform/RuntimeEnabledFeatures.h"
#include "platform/TraceEvent.h"
#include "platform/UserGestureIndicator.h"
#include "platform/exported/WebActiveGestureAnimation.h"
#include "platform/fonts/FontCache.h"
#include "platform/graphics/Color.h"
#include "platform/graphics/Image.h"
#include "platform/graphics/ImageBuffer.h"
#include "platform/scroll/Scrollbar.h"
#include "platform/weborigin/SchemeRegistry.h"
#include "public/platform/Platform.h"
#include "public/platform/WebFloatPoint.h"
#include "public/platform/WebGestureCurve.h"
#include "public/platform/WebImage.h"
#include "public/platform/WebLayerTreeView.h"
#include "public/platform/WebURLRequest.h"
#include "public/platform/WebVector.h"
#include "public/web/WebActiveWheelFlingParameters.h"
#include "public/web/WebBeginFrameArgs.h"
#include "public/web/WebFrameClient.h"
#include "public/web/WebHitTestResult.h"
#include "public/web/WebMediaPlayerAction.h"
#include "public/web/WebNode.h"
#include "public/web/WebRange.h"
#include "public/web/WebTextInputInfo.h"
#include "public/web/WebViewClient.h"
#include "web/CompositionUnderlineVectorBuilder.h"
#include "web/GraphicsLayerFactoryChromium.h"
#include "web/LinkHighlight.h"
#include "web/ViewportAnchor.h"
#include "web/WebInputEventConversion.h"
#include "web/WebLocalFrameImpl.h"
#include "web/WebSettingsImpl.h"
#include "web/painting/ContinuousPainter.h"
#include "wtf/CurrentTime.h"
#include "wtf/RefPtr.h"
#include "wtf/TemporaryChange.h"

// Get rid of WTF's pow define so we can use std::pow.
#undef pow
#include <cmath> // for std::pow

namespace blink {

// Change the text zoom level by kTextSizeMultiplierRatio each time the user
// zooms text in or out (ie., change by 20%).  The min and max values limit
// text zoom to half and 3x the original text size.  These three values match
// those in Apple's port in WebKit/WebKit/WebView/WebView.mm
const double WebView::textSizeMultiplierRatio = 1.2;
const double WebView::minTextSizeMultiplier = 0.5;
const double WebView::maxTextSizeMultiplier = 3.0;

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
    , m_zoomLevel(0)
    , m_minimumZoomLevel(zoomFactorToZoomLevel(minTextSizeMultiplier))
    , m_maximumZoomLevel(zoomFactorToZoomLevel(maxTextSizeMultiplier))
    , m_doingDragAndDrop(false)
    , m_ignoreInputEvents(false)
    , m_compositorDeviceScaleFactorOverride(0)
    , m_rootLayerScale(1)
    , m_suppressNextKeypressEvent(false)
    , m_imeAcceptEvents(true)
    , m_operationsAllowed(WebDragOperationNone)
    , m_dragOperation(WebDragOperationNone)
    , m_isTransparent(false)
    , m_tabsToLinks(false)
    , m_layerTreeView(0)
    , m_rootLayer(0)
    , m_rootGraphicsLayer(0)
    , m_rootTransformLayer(0)
    , m_graphicsLayerFactory(adoptPtr(new GraphicsLayerFactoryChromium(this)))
    , m_isAcceleratedCompositingActive(false)
    , m_layerTreeViewCommitsDeferred(false)
    , m_layerTreeViewClosed(false)
    , m_matchesHeuristicsForGpuRasterization(false)
    , m_recreatingGraphicsContext(false)
    , m_flingModifier(0)
    , m_flingSourceDevice(false)
    , m_showFPSCounter(false)
    , m_showPaintRects(false)
    , m_showDebugBorders(false)
    , m_continuousPaintingEnabled(false)
    , m_showScrollBottleneckRects(false)
    , m_baseBackgroundColor(Color::white)
    , m_backgroundColorOverride(Color::transparent)
    , m_zoomFactorOverride(0)
    , m_userGestureObserved(false)
{
    Page::PageClients pageClients;
    pageClients.chromeClient = &m_chromeClientImpl;
    pageClients.editorClient = &m_editorClientImpl;
    pageClients.spellCheckerClient = &m_spellCheckerClientImpl;

    m_page = adoptPtr(new Page(pageClients));
    m_page->makeOrdinary();

    setDeviceScaleFactor(m_client->screenInfo().deviceScaleFactor);
    setVisibilityState(m_client->visibilityState(), true);

    m_layerTreeView = m_client->initializeLayerTreeView();
}

WebViewImpl::~WebViewImpl()
{
    ASSERT(!m_page);
}

WebLocalFrameImpl* WebViewImpl::mainFrameImpl()
{
    return m_page ? WebLocalFrameImpl::fromFrame(m_page->mainFrame()) : 0;
}

bool WebViewImpl::tabKeyCyclesThroughElements() const
{
    ASSERT(m_page);
    return m_page->tabKeyCyclesThroughElements();
}

void WebViewImpl::setTabKeyCyclesThroughElements(bool value)
{
    if (m_page)
        m_page->setTabKeyCyclesThroughElements(value);
}

void WebViewImpl::handleMouseLeave(LocalFrame& mainFrame, const WebMouseEvent& event)
{
    m_client->setMouseOverURL(WebURL());
    PageWidgetEventHandler::handleMouseLeave(mainFrame, event);
}

void WebViewImpl::handleMouseDown(LocalFrame& mainFrame, const WebMouseEvent& event)
{
    m_lastMouseDownPoint = WebPoint(event.x, event.y);

    PageWidgetEventHandler::handleMouseDown(mainFrame, event);

    if (event.button == WebMouseEvent::ButtonLeft && m_mouseCaptureNode)
        m_mouseCaptureGestureToken = mainFrame.eventHandler().takeLastMouseDownGestureToken();
}

void WebViewImpl::handleMouseUp(LocalFrame& mainFrame, const WebMouseEvent& event)
{
    PageWidgetEventHandler::handleMouseUp(mainFrame, event);
}

bool WebViewImpl::handleMouseWheel(LocalFrame& mainFrame, const WebMouseWheelEvent& event)
{
    return PageWidgetEventHandler::handleMouseWheel(mainFrame, event);
}

// FIXME(sky): This appears to be unused.
bool WebViewImpl::scrollBy(const WebFloatSize& delta, const WebFloatSize& velocity)
{
    if (m_flingSourceDevice == WebGestureDeviceTouchpad) {
        WebMouseWheelEvent syntheticWheel;
        const float tickDivisor = WheelEvent::TickMultiplier;

        syntheticWheel.deltaX = delta.width;
        syntheticWheel.deltaY = delta.height;
        syntheticWheel.wheelTicksX = delta.width / tickDivisor;
        syntheticWheel.wheelTicksY = delta.height / tickDivisor;
        syntheticWheel.hasPreciseScrollingDeltas = true;
        syntheticWheel.x = m_positionOnFlingStart.x;
        syntheticWheel.y = m_positionOnFlingStart.y;
        syntheticWheel.globalX = m_globalPositionOnFlingStart.x;
        syntheticWheel.globalY = m_globalPositionOnFlingStart.y;
        syntheticWheel.modifiers = m_flingModifier;

        if (m_page && m_page->mainFrame() && m_page->mainFrame()->view())
            return handleMouseWheel(*m_page->mainFrame(), syntheticWheel);
    } else {
        WebGestureEvent syntheticGestureEvent;

        syntheticGestureEvent.type = WebInputEvent::GestureScrollUpdateWithoutPropagation;
        syntheticGestureEvent.data.scrollUpdate.deltaX = delta.width;
        syntheticGestureEvent.data.scrollUpdate.deltaY = delta.height;
        syntheticGestureEvent.x = m_positionOnFlingStart.x;
        syntheticGestureEvent.y = m_positionOnFlingStart.y;
        syntheticGestureEvent.globalX = m_globalPositionOnFlingStart.x;
        syntheticGestureEvent.globalY = m_globalPositionOnFlingStart.y;
        syntheticGestureEvent.modifiers = m_flingModifier;
        syntheticGestureEvent.sourceDevice = WebGestureDeviceTouchscreen;

        if (m_page && m_page->mainFrame() && m_page->mainFrame()->view())
            return handleGestureEvent(syntheticGestureEvent);
    }
    return false;
}

bool WebViewImpl::handleGestureEvent(const WebGestureEvent& event)
{
    bool eventSwallowed = false;
    bool eventCancelled = false; // for disambiguation

    // Special handling for slow-path fling gestures.
    switch (event.type) {
    case WebInputEvent::GestureFlingStart: {
        if (mainFrameImpl()->frame()->eventHandler().isScrollbarHandlingGestures())
            break;
        m_client->cancelScheduledContentIntents();
        m_positionOnFlingStart = WebPoint(event.x, event.y);
        m_globalPositionOnFlingStart = WebPoint(event.globalX, event.globalY);
        m_flingModifier = event.modifiers;
        m_flingSourceDevice = event.sourceDevice;
        OwnPtr<WebGestureCurve> flingCurve = adoptPtr(Platform::current()->createFlingAnimationCurve(event.sourceDevice, WebFloatPoint(event.data.flingStart.velocityX, event.data.flingStart.velocityY), WebSize()));
        ASSERT(flingCurve);
        m_gestureAnimation = WebActiveGestureAnimation::createAtAnimationStart(flingCurve.release(), this);
        scheduleAnimation();
        eventSwallowed = true;

        m_client->didHandleGestureEvent(event, eventCancelled);
        return eventSwallowed;
    }
    case WebInputEvent::GestureFlingCancel:
        if (endActiveFlingAnimation())
            eventSwallowed = true;

        m_client->didHandleGestureEvent(event, eventCancelled);
        return eventSwallowed;
    default:
        break;
    }

    PlatformGestureEventBuilder platformEvent(mainFrameImpl()->frameView(), event);

    // FIXME: Remove redundant hit tests by pushing the call to EventHandler::targetGestureEvent
    // up to this point and pass GestureEventWithHitTestResults around.

    // Handle link highlighting outside the main switch to avoid getting lost in the
    // complicated set of cases handled below.
    switch (event.type) {
    case WebInputEvent::GestureShowPress:
        // Queue a highlight animation, then hand off to regular handler.
        enableTapHighlightAtPoint(platformEvent);
        break;
    case WebInputEvent::GestureTapCancel:
    case WebInputEvent::GestureTap:
    case WebInputEvent::GestureLongPress:
        for (size_t i = 0; i < m_linkHighlights.size(); ++i)
            m_linkHighlights[i]->startHighlightAnimationIfNeeded();
        break;
    default:
        break;
    }

    switch (event.type) {
    case WebInputEvent::GestureTap: {
        m_client->cancelScheduledContentIntents();
        if (detectContentOnTouch(platformEvent.position())) {
            eventSwallowed = true;
            break;
        }

        // Don't trigger a disambiguation popup on sites designed for mobile devices.
        // Instead, assume that the page has been designed with big enough buttons and links.
        if (event.data.tap.width > 0 && !shouldDisableDesktopWorkarounds()) {
            // FIXME: didTapMultipleTargets should just take a rect instead of
            // an event.
            WebGestureEvent scaledEvent = event;
            IntRect boundingBox(scaledEvent.x - scaledEvent.data.tap.width / 2, scaledEvent.y - scaledEvent.data.tap.height / 2, scaledEvent.data.tap.width, scaledEvent.data.tap.height);
            Vector<IntRect> goodTargets;
            Vector<RawPtr<Node> > highlightNodes;
            findGoodTouchTargets(boundingBox, mainFrameImpl()->frame(), goodTargets, highlightNodes);
            // FIXME: replace touch adjustment code when numberOfGoodTargets == 1?
            // Single candidate case is currently handled by: https://bugs.webkit.org/show_bug.cgi?id=85101
            if (goodTargets.size() >= 2 && m_client && m_client->didTapMultipleTargets(scaledEvent, goodTargets)) {
                enableTapHighlights(highlightNodes);
                for (size_t i = 0; i < m_linkHighlights.size(); ++i)
                    m_linkHighlights[i]->startHighlightAnimationIfNeeded();
                eventSwallowed = true;
                eventCancelled = true;
                break;
            }
        }

        eventSwallowed = mainFrameImpl()->frame()->eventHandler().handleGestureEvent(platformEvent);
        break;
    }
    case WebInputEvent::GestureTwoFingerTap:
    case WebInputEvent::GestureLongPress:
    case WebInputEvent::GestureLongTap: {
        if (!mainFrameImpl() || !mainFrameImpl()->frameView())
            break;

        m_client->cancelScheduledContentIntents();
        eventSwallowed = mainFrameImpl()->frame()->eventHandler().handleGestureEvent(platformEvent);
        break;
    }
    case WebInputEvent::GestureShowPress: {
        m_client->cancelScheduledContentIntents();
        eventSwallowed = mainFrameImpl()->frame()->eventHandler().handleGestureEvent(platformEvent);
        break;
    }
    case WebInputEvent::GestureDoubleTap:
        // GestureDoubleTap is currently only used by Android for zooming. For WebCore,
        // GestureTap with tap count = 2 is used instead. So we drop GestureDoubleTap here.
        eventSwallowed = true;
        break;
    case WebInputEvent::GestureScrollBegin:
    case WebInputEvent::GesturePinchBegin:
        m_client->cancelScheduledContentIntents();
    case WebInputEvent::GestureTapDown:
    case WebInputEvent::GestureScrollEnd:
    case WebInputEvent::GestureScrollUpdate:
    case WebInputEvent::GestureScrollUpdateWithoutPropagation:
    case WebInputEvent::GestureTapCancel:
    case WebInputEvent::GestureTapUnconfirmed:
    case WebInputEvent::GesturePinchEnd:
    case WebInputEvent::GesturePinchUpdate:
    case WebInputEvent::GestureFlingStart: {
        eventSwallowed = mainFrameImpl()->frame()->eventHandler().handleGestureEvent(platformEvent);
        break;
    }
    default:
        ASSERT_NOT_REACHED();
    }
    m_client->didHandleGestureEvent(event, eventCancelled);
    return eventSwallowed;
}

void WebViewImpl::transferActiveWheelFlingAnimation(const WebActiveWheelFlingParameters& parameters)
{
    TRACE_EVENT0("blink", "WebViewImpl::transferActiveWheelFlingAnimation");
    ASSERT(!m_gestureAnimation);
    m_positionOnFlingStart = parameters.point;
    m_globalPositionOnFlingStart = parameters.globalPoint;
    m_flingModifier = parameters.modifiers;
    OwnPtr<WebGestureCurve> curve = adoptPtr(Platform::current()->createFlingAnimationCurve(parameters.sourceDevice, WebFloatPoint(parameters.delta), parameters.cumulativeScroll));
    ASSERT(curve);
    m_gestureAnimation = WebActiveGestureAnimation::createWithTimeOffset(curve.release(), this, parameters.startTime);
    scheduleAnimation();
}

bool WebViewImpl::endActiveFlingAnimation()
{
    if (m_gestureAnimation) {
        m_gestureAnimation.clear();
        if (m_layerTreeView)
            m_layerTreeView->didStopFlinging();
        return true;
    }
    return false;
}

void WebViewImpl::setShowFPSCounter(bool show)
{
    if (m_layerTreeView) {
        TRACE_EVENT0("blink", "WebViewImpl::setShowFPSCounter");
        m_layerTreeView->setShowFPSCounter(show);
    }
    m_showFPSCounter = show;
}

void WebViewImpl::setShowPaintRects(bool show)
{
    if (m_layerTreeView) {
        TRACE_EVENT0("blink", "WebViewImpl::setShowPaintRects");
        m_layerTreeView->setShowPaintRects(show);
    }
    m_showPaintRects = show;
}

void WebViewImpl::setShowDebugBorders(bool show)
{
    if (m_layerTreeView)
        m_layerTreeView->setShowDebugBorders(show);
    m_showDebugBorders = show;
}

void WebViewImpl::setContinuousPaintingEnabled(bool enabled)
{
    if (m_layerTreeView) {
        TRACE_EVENT0("blink", "WebViewImpl::setContinuousPaintingEnabled");
        m_layerTreeView->setContinuousPaintingEnabled(enabled);
    }
    m_continuousPaintingEnabled = enabled;
    m_client->scheduleAnimation();
}

void WebViewImpl::setShowScrollBottleneckRects(bool show)
{
    if (m_layerTreeView)
        m_layerTreeView->setShowScrollBottleneckRects(show);
    m_showScrollBottleneckRects = show;
}

void WebViewImpl::getSelectionRootBounds(WebRect& bounds) const
{
    const LocalFrame* frame = focusedCoreFrame();
    if (!frame)
        return;

    Element* root = frame->selection().rootEditableElementOrDocumentElement();
    if (!root)
        return;

    IntRect boundingBox = root->pixelSnappedBoundingBox();
    boundingBox = root->document().frame()->view()->contentsToWindow(boundingBox);
    bounds = boundingBox;
}

void WebViewImpl::acceptLanguagesChanged()
{
    if (!page())
        return;

    page()->acceptLanguagesChanged();
}

bool WebViewImpl::handleKeyEvent(const WebKeyboardEvent& event)
{
    ASSERT((event.type == WebInputEvent::RawKeyDown)
        || (event.type == WebInputEvent::KeyDown)
        || (event.type == WebInputEvent::KeyUp));

    // Halt an in-progress fling on a key event.
    endActiveFlingAnimation();

    // Please refer to the comments explaining the m_suppressNextKeypressEvent
    // member.
    // The m_suppressNextKeypressEvent is set if the KeyDown is handled by
    // Webkit. A keyDown event is typically associated with a keyPress(char)
    // event and a keyUp event. We reset this flag here as this is a new keyDown
    // event.
    m_suppressNextKeypressEvent = false;

    RefPtr<LocalFrame> focusedFrame = focusedCoreFrame();
    if (!focusedFrame)
        return false;

    RefPtr<LocalFrame> frame = focusedFrame.get();

    PlatformKeyboardEventBuilder evt(event);

    if (frame->eventHandler().keyEvent(evt)) {
        if (WebInputEvent::RawKeyDown == event.type) {
            // Suppress the next keypress event unless the focused node is a plug-in node.
            // (Flash needs these keypress events to handle non-US keyboards.)
            m_suppressNextKeypressEvent = true;
        }
        return true;
    }

    return keyEventDefault(event);
}

bool WebViewImpl::handleCharEvent(const WebKeyboardEvent& event)
{
    ASSERT(event.type == WebInputEvent::Char);

    // Please refer to the comments explaining the m_suppressNextKeypressEvent
    // member.  The m_suppressNextKeypressEvent is set if the KeyDown is
    // handled by Webkit. A keyDown event is typically associated with a
    // keyPress(char) event and a keyUp event. We reset this flag here as it
    // only applies to the current keyPress event.
    bool suppress = m_suppressNextKeypressEvent;
    m_suppressNextKeypressEvent = false;

    LocalFrame* frame = focusedCoreFrame();
    if (!frame)
        return suppress;

    EventHandler& handler = frame->eventHandler();

    PlatformKeyboardEventBuilder evt(event);
    if (!evt.isCharacterKey())
        return true;

    // Accesskeys are triggered by char events and can't be suppressed.
    if (handler.handleAccessKey(evt))
        return true;

    // Safari 3.1 does not pass off windows system key messages (WM_SYSCHAR) to
    // the eventHandler::keyEvent. We mimic this behavior on all platforms since
    // for now we are converting other platform's key events to windows key
    // events.
    if (evt.isSystemKey())
        return false;

    if (!suppress && !handler.keyEvent(evt))
        return keyEventDefault(event);

    return true;
}

WebRect WebViewImpl::computeBlockBounds(const WebRect& rect, bool ignoreClipping)
{
    if (!mainFrameImpl())
        return WebRect();

    // Use the rect-based hit test to find the node.
    IntPoint point = mainFrameImpl()->frameView()->windowToContents(IntPoint(rect.x, rect.y));
    HitTestRequest::HitTestRequestType hitType = HitTestRequest::ReadOnly | HitTestRequest::Active | (ignoreClipping ? HitTestRequest::IgnoreClipping : 0);
    HitTestResult result = mainFrameImpl()->frame()->eventHandler().hitTestResultAtPoint(point, hitType, IntSize(rect.width, rect.height));

    Node* node = result.innerNonSharedNode();
    if (!node)
        return WebRect();

    // Find the block type node based on the hit node.
    // FIXME: This wants to walk composed tree with NodeRenderingTraversal::parent().
    while (node && (!node->renderer() || node->renderer()->isInline()))
        node = NodeRenderingTraversal::parent(node);

    // Return the bounding box in the window coordinate system.
    if (node) {
        IntRect rect = node->Node::pixelSnappedBoundingBox();
        LocalFrame* frame = node->document().frame();
        return frame->view()->contentsToWindow(rect);
    }
    return WebRect();
}

WebRect WebViewImpl::widenRectWithinPageBounds(const WebRect& source, int targetMargin, int minimumMargin)
{
    WebSize maxSize;
    if (mainFrame())
        maxSize = mainFrame()->contentsSize();
    IntSize scrollOffset;
    if (mainFrame())
        scrollOffset = mainFrame()->scrollOffset();
    int leftMargin = targetMargin;
    int rightMargin = targetMargin;

    const int absoluteSourceX = source.x + scrollOffset.width();
    if (leftMargin > absoluteSourceX) {
        leftMargin = absoluteSourceX;
        rightMargin = std::max(leftMargin, minimumMargin);
    }

    const int maximumRightMargin = maxSize.width - (source.width + absoluteSourceX);
    if (rightMargin > maximumRightMargin) {
        rightMargin = maximumRightMargin;
        leftMargin = std::min(leftMargin, std::max(rightMargin, minimumMargin));
    }

    const int newWidth = source.width + leftMargin + rightMargin;
    const int newX = source.x - leftMargin;

    ASSERT(newWidth >= 0);
    ASSERT(scrollOffset.width() + newX + newWidth <= maxSize.width);

    return WebRect(newX, source.y, newWidth, source.height);
}

void WebViewImpl::computeScaleAndScrollForBlockRect(const WebPoint& hitPoint, const WebRect& blockRect, float padding, float defaultScaleWhenAlreadyLegible, float& scale, WebPoint& scroll)
{
    //FIXME(sky)
}

static Node* findCursorDefiningAncestor(Node* node, LocalFrame* frame)
{
    // Go up the tree to find the node that defines a mouse cursor style
    while (node) {
        if (node->renderer()) {
            ECursor cursor = node->renderer()->style()->cursor();
            if (cursor != CURSOR_AUTO || frame->eventHandler().useHandCursor(node, node->isLink()))
                break;
        }
        node = NodeRenderingTraversal::parent(node);
    }

    return node;
}

static bool showsHandCursor(Node* node, LocalFrame* frame)
{
    if (!node || !node->renderer())
        return false;

    ECursor cursor = node->renderer()->style()->cursor();
    return cursor == CURSOR_POINTER
        || (cursor == CURSOR_AUTO && frame->eventHandler().useHandCursor(node, node->isLink()));
}

Node* WebViewImpl::bestTapNode(const PlatformGestureEvent& tapEvent)
{
    TRACE_EVENT0("input", "WebViewImpl::bestTapNode");

    if (!m_page || !m_page->mainFrame())
        return 0;

    // FIXME: Rely on earlier hit test instead of hit testing again.
    GestureEventWithHitTestResults targetedEvent =
        m_page->mainFrame()->eventHandler().targetGestureEvent(tapEvent, true);
    Node* bestTouchNode = targetedEvent.hitTestResult().targetNode();

    // We might hit something like an image map that has no renderer on it
    // Walk up the tree until we have a node with an attached renderer
    // FIXME: This wants to walk composed tree with NodeRenderingTraversal::parent().
    while (bestTouchNode && !bestTouchNode->renderer())
        bestTouchNode = NodeRenderingTraversal::parent(bestTouchNode);

    Node* cursorDefiningAncestor =
        findCursorDefiningAncestor(bestTouchNode, m_page->mainFrame());
    // We show a highlight on tap only when the current node shows a hand cursor
    if (!cursorDefiningAncestor || !showsHandCursor(cursorDefiningAncestor, m_page->mainFrame())) {
        return 0;
    }

    // We should pick the largest enclosing node with hand cursor set. We do this by first jumping
    // up to cursorDefiningAncestor (which is already known to have hand cursor set). Then we locate
    // the next cursor-defining ancestor up in the the tree and repeat the jumps as long as the node
    // has hand cursor set.
    do {
        bestTouchNode = cursorDefiningAncestor;
        cursorDefiningAncestor = findCursorDefiningAncestor(NodeRenderingTraversal::parent(bestTouchNode),
            m_page->mainFrame());
    } while (cursorDefiningAncestor && showsHandCursor(cursorDefiningAncestor, m_page->mainFrame()));

    return bestTouchNode;
}

void WebViewImpl::enableTapHighlightAtPoint(const PlatformGestureEvent& tapEvent)
{
    Node* touchNode = bestTapNode(tapEvent);

    Vector<RawPtr<Node> > highlightNodes;
    highlightNodes.append(touchNode);

    enableTapHighlights(highlightNodes);
}

void WebViewImpl::enableTapHighlights(Vector<RawPtr<Node> >& highlightNodes)
{
    if (highlightNodes.isEmpty())
        return;

    // Always clear any existing highlight when this is invoked, even if we
    // don't get a new target to highlight.
    m_linkHighlights.clear();

    // LinkHighlight reads out layout and compositing state, so we need to make sure that's all up to date.
    layout();

    for (size_t i = 0; i < highlightNodes.size(); ++i) {
        Node* node = highlightNodes[i];

        if (!node || !node->renderer())
            continue;

        Color highlightColor = node->renderer()->style()->tapHighlightColor();
        // Safari documentation for -webkit-tap-highlight-color says if the specified color has 0 alpha,
        // then tap highlighting is disabled.
        // http://developer.apple.com/library/safari/#documentation/appleapplications/reference/safaricssref/articles/standardcssproperties.html
        if (!highlightColor.alpha())
            continue;

        m_linkHighlights.append(LinkHighlight::create(node, this));
    }
}

void WebViewImpl::animateDoubleTapZoom(const IntPoint& point)
{
    //FIXME(sky)
}

void WebViewImpl::zoomToFindInPageRect(const WebRect& rect)
{
    //FIXME(sky)
}

bool WebViewImpl::zoomToMultipleTargetsRect(const WebRect& rect)
{
    return false;
}

void WebViewImpl::hasTouchEventHandlers(bool hasTouchHandlers)
{
    m_client->hasTouchEventHandlers(hasTouchHandlers);
}

bool WebViewImpl::hasTouchEventHandlersAt(const WebPoint& point)
{
    // FIXME: Implement this. Note that the point must be divided by pageScaleFactor.
    return true;
}

bool WebViewImpl::keyEventDefault(const WebKeyboardEvent& event)
{
    LocalFrame* frame = focusedCoreFrame();
    if (!frame)
        return false;

    switch (event.type) {
    case WebInputEvent::Char:
        if (event.windowsKeyCode == VKEY_SPACE) {
            int keyCode = ((event.modifiers & WebInputEvent::ShiftKey) ? VKEY_PRIOR : VKEY_NEXT);
            return scrollViewWithKeyboard(keyCode, event.modifiers);
        }
        break;
    case WebInputEvent::RawKeyDown:
        if (event.modifiers == WebInputEvent::ControlKey) {
            switch (event.windowsKeyCode) {
#if !OS(MACOSX)
            case 'A':
                focusedFrame()->executeCommand(WebString::fromUTF8("SelectAll"));
                return true;
            case VKEY_INSERT:
            case 'C':
                focusedFrame()->executeCommand(WebString::fromUTF8("Copy"));
                return true;
#endif
            // Match FF behavior in the sense that Ctrl+home/end are the only Ctrl
            // key combinations which affect scrolling. Safari is buggy in the
            // sense that it scrolls the page for all Ctrl+scrolling key
            // combinations. For e.g. Ctrl+pgup/pgdn/up/down, etc.
            case VKEY_HOME:
            case VKEY_END:
                break;
            default:
                return false;
            }
        }
        if (!event.isSystemKey && !(event.modifiers & WebInputEvent::ShiftKey))
            return scrollViewWithKeyboard(event.windowsKeyCode, event.modifiers);
        break;
    default:
        break;
    }
    return false;
}

bool WebViewImpl::scrollViewWithKeyboard(int keyCode, int modifiers)
{
    ScrollDirection scrollDirection;
    ScrollGranularity scrollGranularity;
#if OS(MACOSX)
    // Control-Up/Down should be PageUp/Down on Mac.
    if (modifiers & WebMouseEvent::ControlKey) {
      if (keyCode == VKEY_UP)
        keyCode = VKEY_PRIOR;
      else if (keyCode == VKEY_DOWN)
        keyCode = VKEY_NEXT;
    }
#endif
    if (!mapKeyCodeForScroll(keyCode, &scrollDirection, &scrollGranularity))
        return false;

    if (LocalFrame* frame = focusedCoreFrame())
        return frame->eventHandler().bubblingScroll(scrollDirection, scrollGranularity);
    return false;
}

bool WebViewImpl::mapKeyCodeForScroll(
    int keyCode,
    ScrollDirection* scrollDirection,
    ScrollGranularity* scrollGranularity)
{
    switch (keyCode) {
    case VKEY_LEFT:
        *scrollDirection = ScrollLeft;
        *scrollGranularity = ScrollByLine;
        break;
    case VKEY_RIGHT:
        *scrollDirection = ScrollRight;
        *scrollGranularity = ScrollByLine;
        break;
    case VKEY_UP:
        *scrollDirection = ScrollUp;
        *scrollGranularity = ScrollByLine;
        break;
    case VKEY_DOWN:
        *scrollDirection = ScrollDown;
        *scrollGranularity = ScrollByLine;
        break;
    case VKEY_HOME:
        *scrollDirection = ScrollUp;
        *scrollGranularity = ScrollByDocument;
        break;
    case VKEY_END:
        *scrollDirection = ScrollDown;
        *scrollGranularity = ScrollByDocument;
        break;
    case VKEY_PRIOR:  // page up
        *scrollDirection = ScrollUp;
        *scrollGranularity = ScrollByPage;
        break;
    case VKEY_NEXT:  // page down
        *scrollDirection = ScrollDown;
        *scrollGranularity = ScrollByPage;
        break;
    default:
        return false;
    }

    return true;
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

void WebViewImpl::willStartLiveResize()
{
    // FIXME(sky): Remove
}

WebSize WebViewImpl::size()
{
    return m_size;
}

WebLocalFrameImpl* WebViewImpl::localFrameRootTemporary() const
{
    // FIXME(sky): remove
    return WebLocalFrameImpl::fromFrame(page()->mainFrame());
}

void WebViewImpl::performResize()
{
    updateMainFrameLayoutSize();

    // If the virtual viewport pinch mode is enabled, the main frame will be resized
    // after layout so it can be sized to the contentsSize.
    if (localFrameRootTemporary()->frameView())
        localFrameRootTemporary()->frameView()->resize(m_size);
}

void WebViewImpl::resize(const WebSize& newSize)
{
    if (m_size == newSize)
        return;

    FrameView* view = localFrameRootTemporary()->frameView();
    if (!view)
        return;

    m_size = newSize;
    performResize();
    sendResizeEventAndRepaint();
}

void WebViewImpl::willEndLiveResize()
{
    // FIXME(sky): Remove
}

void WebViewImpl::beginFrame(const WebBeginFrameArgs& frameTime)
{
    TRACE_EVENT0("blink", "WebViewImpl::beginFrame");

    WebBeginFrameArgs validFrameTime(frameTime);
    if (!validFrameTime.lastFrameTimeMonotonic)
        validFrameTime.lastFrameTimeMonotonic = monotonicallyIncreasingTime();

    // Create synthetic wheel events as necessary for fling.
    if (m_gestureAnimation) {
        if (m_gestureAnimation->animate(validFrameTime.lastFrameTimeMonotonic))
            scheduleAnimation();
        else {
            endActiveFlingAnimation();

            PlatformGestureEvent endScrollEvent(PlatformEvent::GestureScrollEnd,
                m_positionOnFlingStart, m_globalPositionOnFlingStart,
                IntSize(), 0, false, false, false, false,
                0, 0, 0, 0);

            mainFrameImpl()->frame()->eventHandler().handleGestureScrollEnd(endScrollEvent);
        }
    }

    WTF_LOG(ScriptedAnimationController, "WebViewImpl::beginFrame: page = %d", !m_page ? 0 : 1);
    if (!m_page)
        return;

    PageWidgetDelegate::animate(m_page.get(), validFrameTime.lastFrameTimeMonotonic);

    if (m_continuousPaintingEnabled) {
        ContinuousPainter::setNeedsDisplayRecursive(m_rootGraphicsLayer);
        m_client->scheduleAnimation();
    }
}

void WebViewImpl::didCommitFrameToCompositor()
{
}

void WebViewImpl::layout()
{
    TRACE_EVENT0("blink", "WebViewImpl::layout");
    if (!localFrameRootTemporary())
        return;

    PageWidgetDelegate::layout(m_page.get(), localFrameRootTemporary()->frame());
    updateLayerTreeBackgroundColor();

    for (size_t i = 0; i < m_linkHighlights.size(); ++i)
        m_linkHighlights[i]->updateGeometry();
}

void WebViewImpl::paint(WebCanvas* canvas, const WebRect& rect)
{
    // This should only be used when compositing is not being used for this
    // WebView, and it is painting into the recording of its parent.
    ASSERT(!isAcceleratedCompositingActive());

    double paintStart = currentTime();
    PageWidgetDelegate::paint(m_page.get(), canvas, rect, isTransparent() ? PageWidgetDelegate::Translucent : PageWidgetDelegate::Opaque);
    double paintEnd = currentTime();
    double pixelsPerSec = (rect.width * rect.height) / (paintEnd - paintStart);
    Platform::current()->histogramCustomCounts("Renderer4.SoftwarePaintDurationMS", (paintEnd - paintStart) * 1000, 0, 120, 30);
    Platform::current()->histogramCustomCounts("Renderer4.SoftwarePaintMegapixPerSecond", pixelsPerSec / 1000000, 10, 210, 30);
}

#if OS(ANDROID)
void WebViewImpl::paintCompositedDeprecated(WebCanvas* canvas, const WebRect& rect)
{
    // Note: This method exists on OS(ANDROID) and will hopefully be
    //       removed once the link disambiguation feature renders using
    //       the compositor.
    ASSERT(isAcceleratedCompositingActive());

    FrameView* view = page()->mainFrame()->view();
    PaintBehavior oldPaintBehavior = view->paintBehavior();
    view->setPaintBehavior(oldPaintBehavior | PaintBehaviorFlattenCompositingLayers);

    PageWidgetDelegate::paint(m_page.get(), canvas, rect, isTransparent() ? PageWidgetDelegate::Translucent : PageWidgetDelegate::Opaque);

    view->setPaintBehavior(oldPaintBehavior);
}
#endif

void WebViewImpl::compositeAndReadbackAsync(WebCompositeAndReadbackAsyncCallback* callback)
{
    ASSERT(isAcceleratedCompositingActive());
    m_layerTreeView->compositeAndReadbackAsync(callback);
}

bool WebViewImpl::isTrackingRepaints() const
{
    if (!page())
        return false;
    FrameView* view = page()->mainFrame()->view();
    return view->isTrackingPaintInvalidations();
}

void WebViewImpl::themeChanged()
{
    if (!page())
        return;
    FrameView* view = page()->mainFrame()->view();

    WebRect damagedRect(0, 0, m_size.width, m_size.height);
    view->invalidateRect(damagedRect);
}

void WebViewImpl::clearCompositedSelectionBounds()
{
    if (m_layerTreeView)
        m_layerTreeView->clearSelection();
}

bool WebViewImpl::hasHorizontalScrollbar()
{
    // FIXME(sky): Remove
    return false;
}

bool WebViewImpl::hasVerticalScrollbar()
{
    // FIXME(sky): Remove
    return false;
}

const WebInputEvent* WebViewImpl::m_currentInputEvent = 0;

// FIXME: autogenerate this kind of code, and use it throughout Blink rather than
// the one-offs for subsets of these values.
static String inputTypeToName(WebInputEvent::Type type)
{
    switch (type) {
    case WebInputEvent::MouseDown:
        return EventTypeNames::mousedown;
    case WebInputEvent::MouseUp:
        return EventTypeNames::mouseup;
    case WebInputEvent::MouseMove:
        return EventTypeNames::mousemove;
    case WebInputEvent::MouseEnter:
        return EventTypeNames::mouseenter;
    case WebInputEvent::MouseLeave:
        return EventTypeNames::mouseleave;
    case WebInputEvent::MouseWheel:
        return EventTypeNames::mousewheel;
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
    case WebInputEvent::TouchStart:
        return EventTypeNames::touchstart;
    case WebInputEvent::TouchMove:
        return EventTypeNames::touchmove;
    case WebInputEvent::TouchEnd:
        return EventTypeNames::touchend;
    case WebInputEvent::TouchCancel:
        return EventTypeNames::touchcancel;
    default:
        return String("unknown");
    }
}

bool WebViewImpl::handleInputEvent(const WebInputEvent& inputEvent)
{
    TRACE_EVENT1("input", "WebViewImpl::handleInputEvent", "type", inputTypeToName(inputEvent.type).ascii());
    // If we've started a drag and drop operation, ignore input events until
    // we're done.
    if (m_doingDragAndDrop)
        return true;

    // Report the event to be NOT processed by WebKit, so that the browser can handle it appropriately.
    if (m_ignoreInputEvents)
        return false;

    TemporaryChange<const WebInputEvent*> currentEventChange(m_currentInputEvent, &inputEvent);

    if (m_mouseCaptureNode && WebInputEvent::isMouseEventType(inputEvent.type)) {
        TRACE_EVENT1("input", "captured mouse event", "type", inputEvent.type);
        // Save m_mouseCaptureNode since mouseCaptureLost() will clear it.
        RefPtr<Node> node = m_mouseCaptureNode;

        // Not all platforms call mouseCaptureLost() directly.
        if (inputEvent.type == WebInputEvent::MouseUp)
            mouseCaptureLost();

        OwnPtr<UserGestureIndicator> gestureIndicator;

        AtomicString eventType;
        switch (inputEvent.type) {
        case WebInputEvent::MouseMove:
            eventType = EventTypeNames::mousemove;
            break;
        case WebInputEvent::MouseLeave:
            eventType = EventTypeNames::mouseout;
            break;
        case WebInputEvent::MouseDown:
            eventType = EventTypeNames::mousedown;
            gestureIndicator = adoptPtr(new UserGestureIndicator(DefinitelyProcessingNewUserGesture));
            m_mouseCaptureGestureToken = gestureIndicator->currentToken();
            break;
        case WebInputEvent::MouseUp:
            eventType = EventTypeNames::mouseup;
            gestureIndicator = adoptPtr(new UserGestureIndicator(m_mouseCaptureGestureToken.release()));
            break;
        default:
            ASSERT_NOT_REACHED();
        }

        node->dispatchMouseEvent(
            PlatformMouseEventBuilder(mainFrameImpl()->frameView(), static_cast<const WebMouseEvent&>(inputEvent)),
            eventType, static_cast<const WebMouseEvent&>(inputEvent).clickCount);
        return true;
    }

    return PageWidgetDelegate::handleInputEvent(m_page.get(), *this, inputEvent);
}

void WebViewImpl::setCursorVisibilityState(bool isVisible)
{
    if (m_page)
        m_page->setIsCursorVisible(isVisible);
}

void WebViewImpl::mouseCaptureLost()
{
    TRACE_EVENT_ASYNC_END0("input", "capturing mouse", this);
    m_mouseCaptureNode = nullptr;
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

bool WebViewImpl::selectionBounds(WebRect& anchor, WebRect& focus) const
{
    const LocalFrame* localFrame = focusedCoreFrame();
    if (!localFrame)
        return false;

    FrameSelection& selection = localFrame->selection();

    if (selection.isCaret()) {
        anchor = focus = selection.absoluteCaretBounds();
    } else {
        RefPtr<Range> selectedRange = selection.toNormalizedRange();
        if (!selectedRange)
            return false;

        RefPtr<Range> range(Range::create(selectedRange->startContainer()->document(),
            selectedRange->startContainer(),
            selectedRange->startOffset(),
            selectedRange->startContainer(),
            selectedRange->startOffset()));
        anchor = localFrame->editor().firstRectForRange(range.get());

        range = Range::create(selectedRange->endContainer()->document(),
            selectedRange->endContainer(),
            selectedRange->endOffset(),
            selectedRange->endContainer(),
            selectedRange->endOffset());
        focus = localFrame->editor().firstRectForRange(range.get());
    }

    IntRect scaledAnchor(localFrame->view()->contentsToWindow(anchor));
    IntRect scaledFocus(localFrame->view()->contentsToWindow(focus));

    anchor = scaledAnchor;
    focus = scaledFocus;

    if (!selection.selection().isBaseFirst())
        std::swap(anchor, focus);
    return true;
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

bool WebViewImpl::selectionTextDirection(WebTextDirection& start, WebTextDirection& end) const
{
    const LocalFrame* frame = focusedCoreFrame();
    if (!frame)
        return false;
    FrameSelection& selection = frame->selection();
    if (!selection.toNormalizedRange())
        return false;
    start = toWebTextDirection(selection.start().primaryDirection());
    end = toWebTextDirection(selection.end().primaryDirection());
    return true;
}

bool WebViewImpl::isSelectionAnchorFirst() const
{
    if (const LocalFrame* frame = focusedCoreFrame())
        return frame->selection().selection().isBaseFirst();
    return false;
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

bool WebViewImpl::caretOrSelectionRange(size_t* location, size_t* length)
{
    const LocalFrame* focused = focusedCoreFrame();
    if (!focused)
        return false;

    PlainTextRange selectionOffsets = focused->inputMethodController().getSelectionOffsets();
    if (selectionOffsets.isNull())
        return false;

    *location = selectionOffsets.start();
    *length = selectionOffsets.length();
    return true;
}

void WebViewImpl::setTextDirection(WebTextDirection direction)
{
    // The Editor::setBaseWritingDirection() function checks if we can change
    // the text direction of the selected node and updates its DOM "dir"
    // attribute and its CSS "direction" property.
    // So, we just call the function as Safari does.
    const LocalFrame* focused = focusedCoreFrame();
    if (!focused)
        return;

    Editor& editor = focused->editor();
    if (!editor.canEdit())
        return;

    switch (direction) {
    case WebTextDirectionDefault:
        editor.setBaseWritingDirection(NaturalWritingDirection);
        break;

    case WebTextDirectionLeftToRight:
        editor.setBaseWritingDirection(LeftToRightWritingDirection);
        break;

    case WebTextDirectionRightToLeft:
        editor.setBaseWritingDirection(RightToLeftWritingDirection);
        break;

    default:
        notImplemented();
        break;
    }
}

bool WebViewImpl::isAcceleratedCompositingActive() const
{
    return m_isAcceleratedCompositingActive;
}

void WebViewImpl::willCloseLayerTreeView()
{
    setIsAcceleratedCompositingActive(false);
    m_layerTreeView = 0;
    m_layerTreeViewClosed = true;
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

WebString WebViewImpl::pageEncoding() const
{
    // FIXME(sky): remove.
    if (!m_page)
        return WebString();

    return m_page->mainFrame()->document()->encodingName();
}

void WebViewImpl::setPageEncoding(const WebString& encodingName)
{
    // FIXME(sky): remove
}

WebFrame* WebViewImpl::mainFrame()
{
    return WebFrame::fromFrame(m_page ? m_page->mainFrame() : 0);
}

WebFrame* WebViewImpl::focusedFrame()
{
    return WebFrame::fromFrame(focusedCoreFrame());
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

void WebViewImpl::scrollFocusedNodeIntoRect(const WebRect& rect)
{
    LocalFrame* frame = page()->mainFrame();
    Element* element = focusedElement();
    if (!frame || !frame->view() || !element)
        return;

    float scale;
    IntPoint scroll;
    bool needAnimation;
    computeScaleAndScrollForFocusedNode(element, scale, scroll, needAnimation);
}

void WebViewImpl::computeScaleAndScrollForFocusedNode(Node* focusedNode, float& newScale, IntPoint& newScroll, bool& needAnimation)
{
    //FIXME(sky)
}

void WebViewImpl::advanceFocus(bool reverse)
{
    page()->focusController().advanceFocus(reverse ? FocusTypeBackward : FocusTypeForward);
}

double WebViewImpl::zoomLevel()
{
    return m_zoomLevel;
}

double WebViewImpl::setZoomLevel(double zoomLevel)
{
    if (zoomLevel < m_minimumZoomLevel)
        m_zoomLevel = m_minimumZoomLevel;
    else if (zoomLevel > m_maximumZoomLevel)
        m_zoomLevel = m_maximumZoomLevel;
    else
        m_zoomLevel = zoomLevel;

    LocalFrame* frame = mainFrameImpl()->frame();
    float zoomFactor = m_zoomFactorOverride ? m_zoomFactorOverride : static_cast<float>(zoomLevelToZoomFactor(m_zoomLevel));
    frame->setPageZoomFactor(zoomFactor);

    return m_zoomLevel;
}

void WebViewImpl::zoomLimitsChanged(double minimumZoomLevel,
                                    double maximumZoomLevel)
{
    m_minimumZoomLevel = minimumZoomLevel;
    m_maximumZoomLevel = maximumZoomLevel;
    m_client->zoomLimitsChanged(m_minimumZoomLevel, m_maximumZoomLevel);
}

float WebViewImpl::textZoomFactor()
{
    return mainFrameImpl()->frame()->textZoomFactor();
}

float WebViewImpl::setTextZoomFactor(float textZoomFactor)
{
    LocalFrame* frame = mainFrameImpl()->frame();
    frame->setTextZoomFactor(textZoomFactor);
    return textZoomFactor;
}

double WebView::zoomLevelToZoomFactor(double zoomLevel)
{
    return pow(textSizeMultiplierRatio, zoomLevel);
}

double WebView::zoomFactorToZoomLevel(double factor)
{
    // Since factor = 1.2^level, level = log(factor) / log(1.2)
    return log(factor) / log(textSizeMultiplierRatio);
}

IntPoint WebViewImpl::clampOffsetAtScale(const IntPoint& offset, float scale)
{
    FrameView* view = mainFrameImpl()->frameView();
    if (!view)
        return offset;

    return view->clampOffsetAtScale(offset, scale);
}

void WebViewImpl::setMainFrameScrollOffset(const WebPoint& origin)
{
    updateMainFrameScrollPosition(origin, false);
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

    if (m_layerTreeView)
        updateLayerTreeDeviceScaleFactor();
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

WebSize WebViewImpl::contentsPreferredMinimumSize()
{
    Document* document = m_page->mainFrame()->document();
    if (!document || !document->renderView() || !document->documentElement())
        return WebSize();

    layout();
    FontCachePurgePreventer fontCachePurgePreventer; // Required by minPreferredLogicalWidth().
    IntSize preferredMinimumSize(document->renderView()->minPreferredLogicalWidth(), document->documentElement()->scrollHeight());
    preferredMinimumSize.scale(zoomLevelToZoomFactor(zoomLevel()));
    return preferredMinimumSize;
}

void WebViewImpl::resetScrollAndScaleState()
{
    // FIXME(sky): Remove
}

void WebViewImpl::setFixedLayoutSize(const WebSize& layoutSize)
{
    if (!page())
        return;

    LocalFrame* frame = page()->mainFrame();
    if (!frame)
        return;

    RefPtr<FrameView> view = frame->view();
    if (!view)
        return;

    m_fixedLayoutSizeLock = layoutSize.width || layoutSize.height;

    if (m_fixedLayoutSizeLock)
        view->setLayoutSize(layoutSize);
    else
        updateMainFrameLayoutSize();
}

void WebViewImpl::performMediaPlayerAction(const WebMediaPlayerAction& action,
                                           const WebPoint& location)
{
    HitTestResult result = hitTestResultForWindowPos(location);
    RefPtr<Node> node = result.innerNonSharedNode();
    if (!isHTMLVideoElement(*node) && !isHTMLAudioElement(*node))
        return;

    RefPtr<HTMLMediaElement> mediaElement = static_pointer_cast<HTMLMediaElement>(node);
    switch (action.type) {
    case WebMediaPlayerAction::Play:
        if (action.enable)
            mediaElement->play();
        else
            mediaElement->pause();
        break;
    case WebMediaPlayerAction::Mute:
        mediaElement->setMuted(action.enable);
        break;
    case WebMediaPlayerAction::Loop:
        mediaElement->setLoop(action.enable);
        break;
    case WebMediaPlayerAction::Controls:
        mediaElement->setBooleanAttribute(HTMLNames::controlsAttr, action.enable);
        break;
    default:
        ASSERT_NOT_REACHED();
    }
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

void WebViewImpl::copyImageAt(const WebPoint& point)
{
    if (!m_page)
        return;

    HitTestResult result = hitTestResultForWindowPos(point);

    if (result.absoluteImageURLIncludingCanvasDataURL().isEmpty()) {
        // There isn't actually an image at these coordinates.  Might be because
        // the window scrolled while the context menu was open or because the page
        // changed itself between when we thought there was an image here and when
        // we actually tried to retreive the image.
        //
        // FIXME: implement a cache of the most recent HitTestResult to avoid having
        //        to do two hit tests.
        return;
    }

    m_page->mainFrame()->editor().copyImage(result);
}

void WebViewImpl::saveImageAt(const WebPoint& point)
{
    if (!m_page)
        return;

    KURL url = hitTestResultForWindowPos(point).absoluteImageURLIncludingCanvasDataURL();

    if (url.isEmpty())
        return;

    ResourceRequest request(url);
    request.setRequestContext(WebURLRequest::RequestContextDownload);
    m_page->mainFrame()->loaderClient()->loadURLExternally(
        request, NavigationPolicyDownloadTo, WebString());
}

void WebViewImpl::dragSourceSystemDragEnded()
{
    // FIXME(sky): Remove
    // It's possible for us to get this callback while not doing a drag if
    // it's from a previous page that got unloaded.
    if (m_doingDragAndDrop)
        m_doingDragAndDrop = false;
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
    if (localFrameRootTemporary()->frameView()) {
        // Enqueues the resize event.
        localFrameRootTemporary()->frame()->document()->enqueueResizeEvent();
    }

    if (!isAcceleratedCompositingActive()) {
        WebRect damagedRect(0, 0, m_size.width, m_size.height);
        m_client->didInvalidateRect(damagedRect);
    }
}

void WebViewImpl::setCompositorDeviceScaleFactorOverride(float deviceScaleFactor)
{
    if (m_compositorDeviceScaleFactorOverride == deviceScaleFactor)
        return;
    m_compositorDeviceScaleFactorOverride = deviceScaleFactor;
    if (page() && m_layerTreeView)
        updateLayerTreeDeviceScaleFactor();
}

void WebViewImpl::setRootLayerTransform(const WebSize& rootLayerOffset, float rootLayerScale)
{
    if (m_rootLayerScale == rootLayerScale && m_rootLayerOffset == rootLayerOffset)
        return;
    m_rootLayerScale = rootLayerScale;
    m_rootLayerOffset = rootLayerOffset;
    if (mainFrameImpl())
        mainFrameImpl()->setInputEventsTransformForEmulation(m_rootLayerOffset, m_rootLayerScale);
    updateRootLayerTransform();
}

void WebViewImpl::extractSmartClipData(WebRect rect, WebString& clipText, WebString& clipHtml, WebRect& clipRect)
{
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

void WebViewImpl::setBaseBackgroundColor(WebColor color)
{
    layout();

    if (m_baseBackgroundColor == color)
        return;

    m_baseBackgroundColor = color;

    if (m_page->mainFrame())
        m_page->mainFrame()->view()->setBaseBackgroundColor(color);

    updateLayerTreeBackgroundColor();
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

void WebViewImpl::setDomainRelaxationForbidden(bool forbidden, const WebString& scheme)
{
    SchemeRegistry::setDomainRelaxationForbiddenForURLScheme(forbidden, String(scheme));
}

void WebViewImpl::setOpenedByDOM()
{
    m_page->setOpenedByDOM();
}

void WebViewImpl::setSelectionColors(unsigned activeBackgroundColor,
                                     unsigned activeForegroundColor,
                                     unsigned inactiveBackgroundColor,
                                     unsigned inactiveForegroundColor) {
}

void WebViewImpl::didCommitLoad(bool isNewNavigation, bool isNavigationWithinPage)
{
    // Make sure link highlight from previous page is cleared.
    m_linkHighlights.clear();
    endActiveFlingAnimation();
    m_userGestureObserved = false;
    if (!isNavigationWithinPage)
        UserGestureIndicator::clearProcessedUserGestureSinceLoad();
}

void WebViewImpl::didRemoveAllPendingStylesheet(WebLocalFrameImpl* webframe)
{
    if (webframe != mainFrameImpl())
        return;

    // If we have no more stylesheets to load and we're past the body tag,
    // we should have something to paint and should start as soon as possible.
    // FIXME(sky): This logic is probably wrong now.
    resumeTreeViewCommits();
}

void WebViewImpl::resumeTreeViewCommits()
{
    if (m_layerTreeViewCommitsDeferred) {
        if (m_layerTreeView)
            m_layerTreeView->setDeferCommits(false);
        m_layerTreeViewCommitsDeferred = false;
    }
}

void WebViewImpl::layoutUpdated(WebLocalFrameImpl* webframe)
{
    if (!m_client)
        return;

    // If we finished a layout while in deferred commit mode,
    // that means it's time to start producing frames again so un-defer.
    resumeTreeViewCommits();

    m_client->didUpdateLayout();
}

void WebViewImpl::setIgnoreInputEvents(bool newValue)
{
    ASSERT(m_ignoreInputEvents != newValue);
    m_ignoreInputEvents = newValue;
}

void WebViewImpl::setBackgroundColorOverride(WebColor color)
{
    m_backgroundColorOverride = color;
    updateLayerTreeBackgroundColor();
}

void WebViewImpl::setZoomFactorOverride(float zoomFactor)
{
    m_zoomFactorOverride = zoomFactor;
    setZoomLevel(zoomLevel());
}

void WebViewImpl::setOverlayLayer(GraphicsLayer* layer)
{
    if (!m_rootGraphicsLayer)
        return;

    // FIXME(bokan): This path goes away after virtual viewport pinch is enabled everywhere.
    if (!m_rootTransformLayer)
        m_rootTransformLayer = m_page->mainFrame()->view()->renderView()->compositor()->ensureRootTransformLayer();

    if (m_rootTransformLayer) {
        if (layer->parent() != m_rootTransformLayer)
            m_rootTransformLayer->addChild(layer);
    }
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

void WebViewImpl::setTabsToLinks(bool enable)
{
    m_tabsToLinks = enable;
}

bool WebViewImpl::tabsToLinks() const
{
    return m_tabsToLinks;
}

void WebViewImpl::suppressInvalidations(bool enable)
{
    m_client->suppressCompositorScheduling(enable);
}

void WebViewImpl::setRootGraphicsLayer(GraphicsLayer* layer)
{
    suppressInvalidations(true);

    m_rootGraphicsLayer = layer;
    m_rootLayer = layer ? layer->platformLayer() : 0;
    m_rootTransformLayer = 0;

    setIsAcceleratedCompositingActive(layer != 0);

    updateRootLayerTransform();

    if (m_layerTreeView) {
        if (m_rootLayer) {
            m_layerTreeView->setRootLayer(*m_rootLayer);
            // We register viewport layers here since there may not be a layer
            // tree view prior to this point.
            GraphicsLayer* rootScrollLayer = compositor()->scrollLayer();
            ASSERT(rootScrollLayer);
            WebLayer* pageScaleLayer = rootScrollLayer->parent() ? rootScrollLayer->parent()->platformLayer() : 0;
            m_layerTreeView->registerViewportLayers(pageScaleLayer, rootScrollLayer->platformLayer(), 0);
        } else {
            m_layerTreeView->clearRootLayer();
            m_layerTreeView->clearViewportLayers();
        }
    }

    suppressInvalidations(false);
}

void WebViewImpl::scheduleCompositingLayerSync()
{
    m_layerTreeView->setNeedsAnimate();
}

void WebViewImpl::invalidateRect(const IntRect& rect)
{
    if (!m_isAcceleratedCompositingActive) {
        m_client->didInvalidateRect(rect);
    }
}

GraphicsLayerFactory* WebViewImpl::graphicsLayerFactory() const
{
    return m_graphicsLayerFactory.get();
}

RenderLayerCompositor* WebViewImpl::compositor() const
{
    if (!page() || !page()->mainFrame())
        return 0;

    if (!page()->mainFrame()->document() || !page()->mainFrame()->document()->renderView())
        return 0;

    return page()->mainFrame()->document()->renderView()->compositor();
}

void WebViewImpl::registerForAnimations(WebLayer* layer)
{
    if (m_layerTreeView)
        m_layerTreeView->registerForAnimations(layer);
}

GraphicsLayer* WebViewImpl::rootGraphicsLayer()
{
    return m_rootGraphicsLayer;
}

void WebViewImpl::scheduleAnimation()
{
    if (isAcceleratedCompositingActive()) {
        ASSERT(m_layerTreeView);
        m_layerTreeView->setNeedsAnimate();
        return;
    }
    m_client->scheduleAnimation();
}

void WebViewImpl::setIsAcceleratedCompositingActive(bool active)
{
    // In the middle of shutting down; don't try to spin back up a compositor.
    // FIXME: compositing startup/shutdown should be refactored so that it
    // turns on explicitly rather than lazily, which causes this awkwardness.
    if (m_layerTreeViewClosed)
        return;

    ASSERT(!active || m_layerTreeView);
    Platform::current()->histogramEnumeration("GPU.setIsAcceleratedCompositingActive", active * 2 + m_isAcceleratedCompositingActive, 4);

    if (m_isAcceleratedCompositingActive == active)
        return;

    if (!m_client)
        return;

    if (!active) {
        m_isAcceleratedCompositingActive = false;
        if (!m_layerTreeViewCommitsDeferred) {
            ASSERT(m_layerTreeView);
            // This means that we're transitioning to a new page. Suppress commits until WebKit generates invalidations so
            // we don't attempt to paint too early in the next page load.
            m_layerTreeView->setDeferCommits(true);
            m_layerTreeViewCommitsDeferred = true;
        }
    } else {
        TRACE_EVENT0("blink", "WebViewImpl::setIsAcceleratedCompositingActive(true)");
        m_layerTreeView->setRootLayer(*m_rootLayer);

        bool visible = page()->visibilityState() == PageVisibilityStateVisible;
        m_layerTreeView->setVisible(visible);
        updateLayerTreeDeviceScaleFactor();
        updateLayerTreeBackgroundColor();
        m_layerTreeView->setHasTransparentBackground(isTransparent());
        m_isAcceleratedCompositingActive = true;
        m_layerTreeView->setShowFPSCounter(m_showFPSCounter);
        m_layerTreeView->setShowPaintRects(m_showPaintRects);
        m_layerTreeView->setShowDebugBorders(m_showDebugBorders);
        m_layerTreeView->setContinuousPaintingEnabled(m_continuousPaintingEnabled);
        m_layerTreeView->setShowScrollBottleneckRects(m_showScrollBottleneckRects);
        m_layerTreeView->heuristicsForGpuRasterizationUpdated(m_matchesHeuristicsForGpuRasterization);
    }
}

void WebViewImpl::updateMainFrameScrollPosition(const IntPoint& scrollPosition, bool programmaticScroll)
{
    // FIXME(sky): Remove
}

void WebViewImpl::applyScrollAndScale(const WebSize& scrollDelta, float pageScaleDelta)
{
    if (!mainFrameImpl() || !mainFrameImpl()->frameView())
        return;

    // TODO(bokan): Old pinch path only - virtual viewport pinch scrolls are automatically updated via GraphicsLayer::DidScroll.
    // this should be removed once old pinch is removed.
        TRACE_EVENT_INSTANT2("blink", "WebViewImpl::applyScrollAndScale::scrollBy", "x", scrollDelta.width, "y", scrollDelta.height);
        WebSize webScrollOffset = mainFrame()->scrollOffset();
        IntPoint scrollOffset(webScrollOffset.width + scrollDelta.width, webScrollOffset.height + scrollDelta.height);
        updateMainFrameScrollPosition(scrollOffset, false);
}

void WebViewImpl::updateLayerTreeBackgroundColor()
{
    if (!m_layerTreeView)
        return;

    m_layerTreeView->setBackgroundColor(alphaChannel(m_backgroundColorOverride) ? m_backgroundColorOverride : backgroundColor());
}

void WebViewImpl::updateLayerTreeDeviceScaleFactor()
{
    ASSERT(page());
    ASSERT(m_layerTreeView);

    float deviceScaleFactor = m_compositorDeviceScaleFactorOverride ? m_compositorDeviceScaleFactorOverride : page()->deviceScaleFactor();
    m_layerTreeView->setDeviceScaleFactor(deviceScaleFactor);
}

void WebViewImpl::updateRootLayerTransform()
{
    // If we don't have a root graphics layer, we won't bother trying to find
    // or update the transform layer.
    if (!m_rootGraphicsLayer)
        return;

    // FIXME(bokan): m_rootTransformLayer is always set here in pinch virtual viewport. This can go away once
    // that's default everywhere.
    if (!m_rootTransformLayer)
        m_rootTransformLayer = m_page->mainFrame()->view()->renderView()->compositor()->ensureRootTransformLayer();

    if (m_rootTransformLayer) {
        TransformationMatrix transform;
        transform.translate(m_rootLayerOffset.width, m_rootLayerOffset.height);
        transform = transform.scale(m_rootLayerScale);
        m_rootTransformLayer->setTransform(transform);
    }
}

bool WebViewImpl::detectContentOnTouch(const WebPoint& position)
{
    HitTestResult touchHit = hitTestResultForWindowPos(position);

    if (touchHit.isContentEditable())
        return false;

    Node* node = touchHit.innerNode();
    if (!node || !node->isTextNode())
        return false;

    // Ignore when tapping on links or nodes listening to click events.
    for (; node; node = NodeRenderingTraversal::parent(node)) {
        if (node->isLink() || node->willRespondToTouchEvents() || node->willRespondToMouseClickEvents())
            return false;
    }

    WebContentDetectionResult content = m_client->detectContentAround(touchHit);
    if (!content.isValid())
        return false;

    m_client->scheduleContentIntent(content.intent());
    return true;
}

void WebViewImpl::setVisibilityState(WebPageVisibilityState visibilityState,
                                     bool isInitialState) {
    if (!page())
        return;

    ASSERT(visibilityState == WebPageVisibilityStateVisible || visibilityState == WebPageVisibilityStateHidden);
    m_page->setVisibilityState(static_cast<PageVisibilityState>(static_cast<int>(visibilityState)), isInitialState);

    if (m_layerTreeView) {
        bool visible = visibilityState == WebPageVisibilityStateVisible;
        m_layerTreeView->setVisible(visible);
    }
}

bool WebViewImpl::shouldDisableDesktopWorkarounds()
{
    return true;
}

} // namespace blink
