/*
 * Copyright (C) 2006, 2007, 2008, 2010 Apple Inc. All rights reserved.
 * Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies)
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "core/frame/LocalDOMWindow.h"

#include "bindings/core/v8/Dictionary.h"
#include "bindings/core/v8/ExceptionMessages.h"
#include "bindings/core/v8/ExceptionState.h"
#include "bindings/core/v8/ExceptionStatePlaceholder.h"
#include "bindings/core/v8/ScriptCallStackFactory.h"
#include "bindings/core/v8/ScriptController.h"
#include "bindings/core/v8/SerializedScriptValue.h"
#include "core/css/CSSComputedStyleDeclaration.h"
#include "core/css/CSSRuleList.h"
#include "core/css/DOMWindowCSS.h"
#include "core/css/MediaQueryList.h"
#include "core/css/MediaQueryMatcher.h"
#include "core/css/StyleMedia.h"
#include "core/css/resolver/StyleResolver.h"
#include "core/dom/Document.h"
#include "core/dom/Element.h"
#include "core/dom/ExceptionCode.h"
#include "core/dom/ExecutionContext.h"
#include "core/dom/RequestAnimationFrameCallback.h"
#include "core/editing/Editor.h"
#include "core/events/DOMWindowEventQueue.h"
#include "core/events/EventListener.h"
#include "core/events/HashChangeEvent.h"
#include "core/events/PageTransitionEvent.h"
#include "core/events/PopStateEvent.h"
#include "core/frame/Console.h"
#include "core/frame/DOMWindowLifecycleNotifier.h"
#include "core/frame/EventHandlerRegistry.h"
#include "core/frame/FrameConsole.h"
#include "core/frame/FrameHost.h"
#include "core/frame/FrameView.h"
#include "core/frame/History.h"
#include "core/frame/LocalFrame.h"
#include "core/frame/Location.h"
#include "core/frame/Screen.h"
#include "core/frame/Settings.h"
#include "core/html/HTMLDocument.h"
#include "core/inspector/ConsoleMessage.h"
#include "core/inspector/ConsoleMessageStorage.h"
#include "core/inspector/InspectorTraceEvents.h"
#include "core/inspector/ScriptCallStack.h"
#include "core/loader/FrameLoaderClient.h"
#include "core/page/Chrome.h"
#include "core/page/ChromeClient.h"
#include "core/page/EventHandler.h"
#include "core/page/Page.h"
#include "core/page/WindowFocusAllowedIndicator.h"
#include "core/page/scrolling/ScrollingCoordinator.h"
#include "platform/EventDispatchForbiddenScope.h"
#include "platform/PlatformScreen.h"
#include "platform/RuntimeEnabledFeatures.h"
#include "platform/UserGestureIndicator.h"
#include "platform/geometry/FloatRect.h"
#include "platform/graphics/media/MediaPlayer.h"
#include "platform/weborigin/KURL.h"
#include "platform/weborigin/SecurityPolicy.h"
#include "public/platform/Platform.h"
#include "wtf/MainThread.h"
#include "wtf/MathExtras.h"
#include "wtf/text/WTFString.h"
#include <algorithm>

using std::min;
using std::max;

namespace blink {

static void disableSuddenTermination()
{
    blink::Platform::current()->suddenTerminationChanged(false);
}

static void enableSuddenTermination()
{
    blink::Platform::current()->suddenTerminationChanged(true);
}

typedef HashCountedSet<LocalDOMWindow*> DOMWindowSet;

static DOMWindowSet& windowsWithUnloadEventListeners()
{
    DEFINE_STATIC_LOCAL(DOMWindowSet, windowsWithUnloadEventListeners, ());
    return windowsWithUnloadEventListeners;
}

static void addUnloadEventListener(LocalDOMWindow* domWindow)
{
    DOMWindowSet& set = windowsWithUnloadEventListeners();
    if (set.isEmpty())
        disableSuddenTermination();
    set.add(domWindow);
}

static void removeUnloadEventListener(LocalDOMWindow* domWindow)
{
    DOMWindowSet& set = windowsWithUnloadEventListeners();
    DOMWindowSet::iterator it = set.find(domWindow);
    if (it == set.end())
        return;
    set.remove(it);
    if (set.isEmpty())
        enableSuddenTermination();
}

static void removeAllUnloadEventListeners(LocalDOMWindow* domWindow)
{
    DOMWindowSet& set = windowsWithUnloadEventListeners();
    DOMWindowSet::iterator it = set.find(domWindow);
    if (it == set.end())
        return;
    set.removeAll(it);
    if (set.isEmpty())
        enableSuddenTermination();
}

unsigned LocalDOMWindow::pendingUnloadEventListeners() const
{
    return windowsWithUnloadEventListeners().count(const_cast<LocalDOMWindow*>(this));
}

// This function:
// 1) Validates the pending changes are not changing any value to NaN; in that case keep original value.
// 2) Constrains the window rect to the minimum window size and no bigger than the float rect's dimensions.
// 3) Constrains the window rect to within the top and left boundaries of the available screen rect.
// 4) Constrains the window rect to within the bottom and right boundaries of the available screen rect.
// 5) Translate the window rect coordinates to be within the coordinate space of the screen.
FloatRect LocalDOMWindow::adjustWindowRect(LocalFrame& frame, const FloatRect& pendingChanges)
{
    FrameHost* host = frame.host();
    ASSERT(host);

    FloatRect screen = screenAvailableRect(frame.view());
    FloatRect window = host->chrome().windowRect();

    // Make sure we're in a valid state before adjusting dimensions.
    ASSERT(std::isfinite(screen.x()));
    ASSERT(std::isfinite(screen.y()));
    ASSERT(std::isfinite(screen.width()));
    ASSERT(std::isfinite(screen.height()));
    ASSERT(std::isfinite(window.x()));
    ASSERT(std::isfinite(window.y()));
    ASSERT(std::isfinite(window.width()));
    ASSERT(std::isfinite(window.height()));

    // Update window values if new requested values are not NaN.
    if (!std::isnan(pendingChanges.x()))
        window.setX(pendingChanges.x());
    if (!std::isnan(pendingChanges.y()))
        window.setY(pendingChanges.y());
    if (!std::isnan(pendingChanges.width()))
        window.setWidth(pendingChanges.width());
    if (!std::isnan(pendingChanges.height()))
        window.setHeight(pendingChanges.height());

    FloatSize minimumSize = host->chrome().client().minimumWindowSize();
    // Let size 0 pass through, since that indicates default size, not minimum size.
    if (window.width())
        window.setWidth(min(max(minimumSize.width(), window.width()), screen.width()));
    if (window.height())
        window.setHeight(min(max(minimumSize.height(), window.height()), screen.height()));

    // Constrain the window position within the valid screen area.
    window.setX(max(screen.x(), min(window.x(), screen.maxX() - window.width())));
    window.setY(max(screen.y(), min(window.y(), screen.maxY() - window.height())));

    return window;
}

LocalDOMWindow::LocalDOMWindow(LocalFrame& frame)
    : FrameDestructionObserver(&frame)
#if ENABLE(ASSERT)
    , m_hasBeenReset(false)
#endif
{
    ScriptWrappable::init(this);
}

void LocalDOMWindow::clearDocument()
{
    if (!m_document)
        return;

    // FIXME: This should be part of ActiveDOMObject shutdown
    clearEventQueue();

    m_document->clearDOMWindow();
    m_document = nullptr;
}

void LocalDOMWindow::clearEventQueue()
{
    if (!m_eventQueue)
        return;
    m_eventQueue->close();
    m_eventQueue.clear();
}

void LocalDOMWindow::acceptLanguagesChanged()
{
    dispatchEvent(Event::create(EventTypeNames::languagechange));
}

PassRefPtrWillBeRawPtr<Document> LocalDOMWindow::installNewDocument(const DocumentInit& init)
{
    ASSERT(init.frame() == m_frame);

    clearDocument();

    m_document = HTMLDocument::create(init);
    m_eventQueue = DOMWindowEventQueue::create(m_document.get());
    m_document->attach();

    m_frame->script().updateDocument();
    m_document->updateViewportDescription();

    if (m_frame->page() && m_frame->view()) {
        if (ScrollingCoordinator* scrollingCoordinator = m_frame->page()->scrollingCoordinator()) {
            scrollingCoordinator->scrollableAreaScrollbarLayerDidChange(m_frame->view(), HorizontalScrollbar);
            scrollingCoordinator->scrollableAreaScrollbarLayerDidChange(m_frame->view(), VerticalScrollbar);
            scrollingCoordinator->scrollableAreaScrollLayerDidChange(m_frame->view());
        }
    }

    return m_document;
}

EventQueue* LocalDOMWindow::eventQueue() const
{
    return m_eventQueue.get();
}

void LocalDOMWindow::enqueueWindowEvent(PassRefPtrWillBeRawPtr<Event> event)
{
    if (!m_eventQueue)
        return;
    event->setTarget(this);
    m_eventQueue->enqueueEvent(event);
}

void LocalDOMWindow::enqueueDocumentEvent(PassRefPtrWillBeRawPtr<Event> event)
{
    if (!m_eventQueue)
        return;
    event->setTarget(m_document.get());
    m_eventQueue->enqueueEvent(event);
}

void LocalDOMWindow::dispatchWindowLoadEvent()
{
    ASSERT(!EventDispatchForbiddenScope::isEventDispatchForbidden());
    dispatchLoadEvent();
}

void LocalDOMWindow::documentWasClosed()
{
    dispatchWindowLoadEvent();
    enqueuePageshowEvent(PageshowEventNotPersisted);
    if (m_pendingStateObject)
        enqueuePopstateEvent(m_pendingStateObject.release());
}

void LocalDOMWindow::enqueuePageshowEvent(PageshowEventPersistence persisted)
{
    // FIXME: https://bugs.webkit.org/show_bug.cgi?id=36334 Pageshow event needs to fire asynchronously.
    // As per spec pageshow must be triggered asynchronously.
    // However to be compatible with other browsers blink fires pageshow synchronously.
    dispatchEvent(PageTransitionEvent::create(EventTypeNames::pageshow, persisted), m_document.get());
}

void LocalDOMWindow::enqueueHashchangeEvent(const String& oldURL, const String& newURL)
{
    enqueueWindowEvent(HashChangeEvent::create(oldURL, newURL));
}

void LocalDOMWindow::enqueuePopstateEvent(PassRefPtr<SerializedScriptValue> stateObject)
{
    // FIXME: https://bugs.webkit.org/show_bug.cgi?id=36202 Popstate event needs to fire asynchronously
    dispatchEvent(PopStateEvent::create(stateObject, &history()));
}

void LocalDOMWindow::statePopped(PassRefPtr<SerializedScriptValue> stateObject)
{
    if (!frame())
        return;

    // Per step 11 of section 6.5.9 (history traversal) of the HTML5 spec, we
    // defer firing of popstate until we're in the complete state.
    if (document()->isLoadCompleted())
        enqueuePopstateEvent(stateObject);
    else
        m_pendingStateObject = stateObject;
}

LocalDOMWindow::~LocalDOMWindow()
{
    ASSERT(m_hasBeenReset);
    reset();

#if ENABLE(OILPAN)
    // Oilpan: the frame host and document objects are
    // also garbage collected; cannot notify these
    // when removing event listeners.
    removeAllEventListenersInternal(DoNotBroadcastListenerRemoval);

    // Cleared when detaching document.
    ASSERT(!m_eventQueue);
#else
    removeAllEventListenersInternal(DoBroadcastListenerRemoval);

    ASSERT(m_document->isStopped());
    clearDocument();
#endif
}

const AtomicString& LocalDOMWindow::interfaceName() const
{
    return EventTargetNames::LocalDOMWindow;
}

ExecutionContext* LocalDOMWindow::executionContext() const
{
    return m_document.get();
}

LocalDOMWindow* LocalDOMWindow::toDOMWindow()
{
    return this;
}

PassRefPtrWillBeRawPtr<MediaQueryList> LocalDOMWindow::matchMedia(const String& media)
{
    return document() ? document()->mediaQueryMatcher().matchMedia(media) : nullptr;
}

Page* LocalDOMWindow::page()
{
    return frame() ? frame()->page() : 0;
}

void LocalDOMWindow::frameDestroyed()
{
    FrameDestructionObserver::frameDestroyed();
    reset();
}

void LocalDOMWindow::willDetachFrameHost()
{
    m_frame->host()->eventHandlerRegistry().didRemoveAllEventHandlers(*this);
    m_frame->console().messageStorage()->frameWindowDiscarded(this);
}

void LocalDOMWindow::willDestroyDocumentInFrame()
{
    // It is necessary to copy m_properties to a separate vector because the DOMWindowProperties may
    // unregister themselves from the LocalDOMWindow as a result of the call to willDestroyGlobalObjectInFrame.
    Vector<DOMWindowProperty*> properties;
    copyToVector(m_properties, properties);
    for (size_t i = 0; i < properties.size(); ++i)
        properties[i]->willDestroyGlobalObjectInFrame();
}

void LocalDOMWindow::willDetachDocumentFromFrame()
{
    // It is necessary to copy m_properties to a separate vector because the DOMWindowProperties may
    // unregister themselves from the LocalDOMWindow as a result of the call to willDetachGlobalObjectFromFrame.
    Vector<DOMWindowProperty*> properties;
    copyToVector(m_properties, properties);
    for (size_t i = 0; i < properties.size(); ++i)
        properties[i]->willDetachGlobalObjectFromFrame();
}

void LocalDOMWindow::registerProperty(DOMWindowProperty* property)
{
    m_properties.add(property);
}

void LocalDOMWindow::unregisterProperty(DOMWindowProperty* property)
{
    m_properties.remove(property);
}

void LocalDOMWindow::reset()
{
    willDestroyDocumentInFrame();
    resetDOMWindowProperties();
}

void LocalDOMWindow::resetDOMWindowProperties()
{
    m_properties.clear();

    m_screen = nullptr;
    m_history = nullptr;
    m_console = nullptr;
    m_location = nullptr;
    m_media = nullptr;
#if ENABLE(ASSERT)
    m_hasBeenReset = true;
#endif
}

int LocalDOMWindow::orientation() const
{
    ASSERT(RuntimeEnabledFeatures::orientationEventEnabled());

    int orientation = screenOrientationAngle(m_frame->view());
    // For backward compatibility, we want to return a value in the range of
    // [-90; 180] instead of [0; 360[ because window.orientation used to behave
    // like that in WebKit (this is a WebKit proprietary API).
    if (orientation == 270)
        return -90;
    return orientation;
}

Screen& LocalDOMWindow::screen() const
{
    if (!m_screen)
        m_screen = Screen::create(m_frame);
    return *m_screen;
}

History& LocalDOMWindow::history() const
{
    if (!m_history)
        m_history = History::create(m_frame);
    return *m_history;
}

Console& LocalDOMWindow::console() const
{
    if (!m_console)
        m_console = Console::create(m_frame);
    return *m_console;
}

FrameConsole* LocalDOMWindow::frameConsole() const
{
    return &m_frame->console();
}

Location& LocalDOMWindow::location() const
{
    if (!m_location)
        m_location = Location::create(m_frame);
    return *m_location;
}

DOMSelection* LocalDOMWindow::getSelection()
{
    return m_frame->document()->getSelection();
}

void LocalDOMWindow::focus(ExecutionContext* context)
{
    if (!m_frame)
        return;

    FrameHost* host = m_frame->host();
    if (!host)
        return;

    bool allowFocus = WindowFocusAllowedIndicator::windowFocusAllowed();

    // If we're a top level window, bring the window to the front.
    if (allowFocus)
        host->chrome().focus();

    if (!m_frame)
        return;

    m_frame->eventHandler().focusDocumentView();
}

bool LocalDOMWindow::find(const String& string, bool caseSensitive, bool backwards, bool wrap, bool /*wholeWord*/, bool /*searchInFrames*/, bool /*showDialog*/) const
{
    // |m_frame| can be destructed during |Editor::findString()| via
    // |Document::updateLayou()|, e.g. event handler removes a frame.
    RefPtr<LocalFrame> protectFrame(m_frame);

    // FIXME (13016): Support wholeWord, searchInFrames and showDialog
    return m_frame->editor().findString(string, !backwards, caseSensitive, wrap, false);
}

int LocalDOMWindow::outerHeight() const
{
    if (!m_frame)
        return 0;

    FrameHost* host = m_frame->host();
    if (!host)
        return 0;

    return static_cast<int>(host->chrome().windowRect().height());
}

int LocalDOMWindow::outerWidth() const
{
    if (!m_frame)
        return 0;

    FrameHost* host = m_frame->host();
    if (!host)
        return 0;

    return static_cast<int>(host->chrome().windowRect().width());
}

int LocalDOMWindow::innerHeight() const
{
    if (!m_frame)
        return 0;

    FrameView* view = m_frame->view();
    if (!view)
        return 0;

    return adjustForAbsoluteZoom(view->visibleContentRect(IncludeScrollbars).height(), m_frame->pageZoomFactor());
}

int LocalDOMWindow::innerWidth() const
{
    if (!m_frame)
        return 0;

    FrameView* view = m_frame->view();
    if (!view)
        return 0;

    return adjustForAbsoluteZoom(view->visibleContentRect(IncludeScrollbars).width(), m_frame->pageZoomFactor());
}

int LocalDOMWindow::screenX() const
{
    if (!m_frame)
        return 0;

    FrameHost* host = m_frame->host();
    if (!host)
        return 0;

    return static_cast<int>(host->chrome().windowRect().x());
}

int LocalDOMWindow::screenY() const
{
    if (!m_frame)
        return 0;

    FrameHost* host = m_frame->host();
    if (!host)
        return 0;

    return static_cast<int>(host->chrome().windowRect().y());
}

int LocalDOMWindow::scrollX() const
{
    if (!m_frame)
        return 0;

    FrameView* view = m_frame->view();
    if (!view)
        return 0;

    m_frame->document()->updateLayoutIgnorePendingStylesheets();

    return adjustForAbsoluteZoom(view->scrollX(), m_frame->pageZoomFactor());
}

int LocalDOMWindow::scrollY() const
{
    if (!m_frame)
        return 0;

    FrameView* view = m_frame->view();
    if (!view)
        return 0;

    m_frame->document()->updateLayoutIgnorePendingStylesheets();

    return adjustForAbsoluteZoom(view->scrollY(), m_frame->pageZoomFactor());
}

LocalDOMWindow* LocalDOMWindow::window() const
{
    if (!m_frame)
        return 0;

    return m_frame->domWindow();
}

Document* LocalDOMWindow::document() const
{
    return m_document.get();
}

StyleMedia& LocalDOMWindow::styleMedia() const
{
    if (!m_media)
        m_media = StyleMedia::create(m_frame);
    return *m_media;
}

PassRefPtrWillBeRawPtr<CSSStyleDeclaration> LocalDOMWindow::getComputedStyle(Element* elt, const String& pseudoElt) const
{
    if (!elt)
        return nullptr;

    return CSSComputedStyleDeclaration::create(elt, false, pseudoElt);
}

PassRefPtrWillBeRawPtr<CSSRuleList> LocalDOMWindow::getMatchedCSSRules(Element* element, const String& pseudoElement) const
{
    if (!element)
        return nullptr;

    unsigned colonStart = pseudoElement[0] == ':' ? (pseudoElement[1] == ':' ? 2 : 1) : 0;
    CSSSelector::PseudoType pseudoType = CSSSelector::parsePseudoType(AtomicString(pseudoElement.substring(colonStart)));
    if (pseudoType == CSSSelector::PseudoUnknown && !pseudoElement.isEmpty())
        return nullptr;

    unsigned rulesToInclude = StyleResolver::AuthorCSSRules;
    PseudoId pseudoId = CSSSelector::pseudoId(pseudoType);
    return m_frame->document()->ensureStyleResolver().pseudoCSSRulesForElement(element, pseudoId, rulesToInclude);
}

double LocalDOMWindow::devicePixelRatio() const
{
    if (!m_frame)
        return 0.0;

    return m_frame->devicePixelRatio();
}

static bool scrollBehaviorFromScrollOptions(const Dictionary& scrollOptions, ScrollBehavior& scrollBehavior, ExceptionState& exceptionState)
{
    String scrollBehaviorString;
    if (!DictionaryHelper::get(scrollOptions, "behavior", scrollBehaviorString)) {
        scrollBehavior = ScrollBehaviorAuto;
        return true;
    }

    if (ScrollableArea::scrollBehaviorFromString(scrollBehaviorString, scrollBehavior))
        return true;

    exceptionState.throwTypeError("The ScrollBehavior provided is invalid.");
    return false;
}

void LocalDOMWindow::scrollBy(int x, int y, ScrollBehavior scrollBehavior) const
{
    document()->updateLayoutIgnorePendingStylesheets();

    FrameView* view = m_frame->view();
    if (!view)
        return;

    IntSize scaledOffset(x * m_frame->pageZoomFactor(), y * m_frame->pageZoomFactor());
    view->scrollBy(scaledOffset, scrollBehavior);
}

void LocalDOMWindow::scrollBy(int x, int y, const Dictionary& scrollOptions, ExceptionState &exceptionState) const
{
    ScrollBehavior scrollBehavior = ScrollBehaviorAuto;
    if (!scrollBehaviorFromScrollOptions(scrollOptions, scrollBehavior, exceptionState))
        return;
    scrollBy(x, y, scrollBehavior);
}

void LocalDOMWindow::scrollTo(int x, int y, ScrollBehavior scrollBehavior) const
{
    document()->updateLayoutIgnorePendingStylesheets();

    RefPtr<FrameView> view = m_frame->view();
    if (!view)
        return;

    IntPoint layoutPos(x * m_frame->pageZoomFactor(), y * m_frame->pageZoomFactor());
    view->setScrollPosition(layoutPos, scrollBehavior);
}

void LocalDOMWindow::scrollTo(int x, int y, const Dictionary& scrollOptions, ExceptionState& exceptionState) const
{
    ScrollBehavior scrollBehavior = ScrollBehaviorAuto;
    if (!scrollBehaviorFromScrollOptions(scrollOptions, scrollBehavior, exceptionState))
        return;
    scrollTo(x, y, scrollBehavior);
}

void LocalDOMWindow::moveBy(float x, float y) const
{
    if (!m_frame)
        return;

    FrameHost* host = m_frame->host();
    if (!host)
        return;

    FloatRect windowRect = host->chrome().windowRect();
    windowRect.move(x, y);
    // Security check (the spec talks about UniversalBrowserWrite to disable this check...)
    host->chrome().setWindowRect(adjustWindowRect(*m_frame, windowRect));
}

void LocalDOMWindow::moveTo(float x, float y) const
{
    if (!m_frame)
        return;

    FrameHost* host = m_frame->host();
    if (!host)
        return;

    FloatRect windowRect = host->chrome().windowRect();
    windowRect.setLocation(FloatPoint(x, y));
    // Security check (the spec talks about UniversalBrowserWrite to disable this check...)
    host->chrome().setWindowRect(adjustWindowRect(*m_frame, windowRect));
}

void LocalDOMWindow::resizeBy(float x, float y) const
{
    if (!m_frame)
        return;

    FrameHost* host = m_frame->host();
    if (!host)
        return;

    FloatRect fr = host->chrome().windowRect();
    FloatSize dest = fr.size() + FloatSize(x, y);
    FloatRect update(fr.location(), dest);
    host->chrome().setWindowRect(adjustWindowRect(*m_frame, update));
}

void LocalDOMWindow::resizeTo(float width, float height) const
{
    if (!m_frame)
        return;

    FrameHost* host = m_frame->host();
    if (!host)
        return;

    FloatRect fr = host->chrome().windowRect();
    FloatSize dest = FloatSize(width, height);
    FloatRect update(fr.location(), dest);
    host->chrome().setWindowRect(adjustWindowRect(*m_frame, update));
}

int LocalDOMWindow::requestAnimationFrame(PassOwnPtrWillBeRawPtr<RequestAnimationFrameCallback> callback)
{
    callback->m_useLegacyTimeBase = false;
    if (Document* d = document())
        return d->requestAnimationFrame(callback);
    return 0;
}

void LocalDOMWindow::cancelAnimationFrame(int id)
{
    if (Document* d = document())
        d->cancelAnimationFrame(id);
}

DOMWindowCSS& LocalDOMWindow::css() const
{
    if (!m_css)
        m_css = DOMWindowCSS::create();
    return *m_css;
}

bool LocalDOMWindow::addEventListener(const AtomicString& eventType, PassRefPtr<EventListener> listener, bool useCapture)
{
    if (!EventTarget::addEventListener(eventType, listener, useCapture))
        return false;

    if (m_frame && m_frame->host())
        m_frame->host()->eventHandlerRegistry().didAddEventHandler(*this, eventType);

    if (Document* document = this->document())
        document->addListenerTypeIfNeeded(eventType);

    lifecycleNotifier().notifyAddEventListener(this, eventType);

    if (eventType == EventTypeNames::unload) {
        UseCounter::count(document(), UseCounter::DocumentUnloadRegistered);
        addUnloadEventListener(this);
    }
    return true;
}

bool LocalDOMWindow::removeEventListener(const AtomicString& eventType, PassRefPtr<EventListener> listener, bool useCapture)
{
    if (!EventTarget::removeEventListener(eventType, listener, useCapture))
        return false;

    if (m_frame && m_frame->host())
        m_frame->host()->eventHandlerRegistry().didRemoveEventHandler(*this, eventType);

    lifecycleNotifier().notifyRemoveEventListener(this, eventType);

    if (eventType == EventTypeNames::unload) {
        removeUnloadEventListener(this);
    }

    return true;
}

void LocalDOMWindow::dispatchLoadEvent()
{
    RefPtrWillBeRawPtr<Event> loadEvent(Event::create(EventTypeNames::load));
    dispatchEvent(loadEvent, document());

    TRACE_EVENT_INSTANT1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline"), "MarkLoad", "data", InspectorMarkLoadEvent::data(frame()));
}

bool LocalDOMWindow::dispatchEvent(PassRefPtrWillBeRawPtr<Event> prpEvent, PassRefPtrWillBeRawPtr<EventTarget> prpTarget)
{
    ASSERT(!EventDispatchForbiddenScope::isEventDispatchForbidden());

    RefPtrWillBeRawPtr<EventTarget> protect(this);
    RefPtrWillBeRawPtr<Event> event = prpEvent;

    event->setTarget(prpTarget ? prpTarget : this);
    event->setCurrentTarget(this);
    event->setEventPhase(Event::AT_TARGET);

    TRACE_EVENT1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline"), "EventDispatch", "data", InspectorEventDispatchEvent::data(*event));

    bool result = fireEventListeners(event.get());

    return result;
}

void LocalDOMWindow::removeAllEventListenersInternal(BroadcastListenerRemoval mode)
{
    EventTarget::removeAllEventListeners();

    lifecycleNotifier().notifyRemoveAllEventListeners(this);

    if (mode == DoBroadcastListenerRemoval) {
        if (m_frame && m_frame->host())
            m_frame->host()->eventHandlerRegistry().didRemoveAllEventHandlers(*this);
    }

    removeAllUnloadEventListeners(this);
}

void LocalDOMWindow::removeAllEventListeners()
{
    removeAllEventListenersInternal(DoBroadcastListenerRemoval);
}

void LocalDOMWindow::setLocation(const String& urlString, LocalDOMWindow* callingWindow, LocalDOMWindow* enteredWindow, SetLocationLocking locking)
{
    // FIXME(sky): remove.
}

void LocalDOMWindow::printErrorMessage(const String& message)
{
    if (message.isEmpty())
        return;

    frameConsole()->addMessage(ConsoleMessage::create(JSMessageSource, ErrorMessageLevel, message));
}


bool LocalDOMWindow::isInsecureScriptAccess(LocalDOMWindow& callingWindow, const String& urlString)
{
    // FIXME(sky): remove.
    return false;
}

DOMWindowLifecycleNotifier& LocalDOMWindow::lifecycleNotifier()
{
    return static_cast<DOMWindowLifecycleNotifier&>(LifecycleContext<LocalDOMWindow>::lifecycleNotifier());
}

PassOwnPtr<LifecycleNotifier<LocalDOMWindow> > LocalDOMWindow::createLifecycleNotifier()
{
    return DOMWindowLifecycleNotifier::create(this);
}

void LocalDOMWindow::trace(Visitor* visitor)
{
    visitor->trace(m_document);
    visitor->trace(m_screen);
    visitor->trace(m_history);
    visitor->trace(m_console);
    visitor->trace(m_location);
    visitor->trace(m_media);
    visitor->trace(m_css);
    visitor->trace(m_eventQueue);
    WillBeHeapSupplementable<LocalDOMWindow>::trace(visitor);
    EventTargetWithInlineData::trace(visitor);
    LifecycleContext<LocalDOMWindow>::trace(visitor);
}

} // namespace blink
