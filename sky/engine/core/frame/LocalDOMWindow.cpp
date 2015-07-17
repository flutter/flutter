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

#include "sky/engine/core/frame/LocalDOMWindow.h"

#include <algorithm>
#include "gen/sky/platform/RuntimeEnabledFeatures.h"
#include "gen/sky/core/EventTypeNames.h"
#include "mojo/services/navigation/public/interfaces/navigation.mojom.h"
#include "sky/engine/bindings/exception_messages.h"
#include "sky/engine/bindings/exception_state.h"
#include "sky/engine/bindings/exception_state_placeholder.h"
#include "sky/engine/core/css/CSSComputedStyleDeclaration.h"
#include "sky/engine/core/css/DOMWindowCSS.h"
#include "sky/engine/core/css/MediaQueryList.h"
#include "sky/engine/core/css/MediaQueryMatcher.h"
#include "sky/engine/core/css/resolver/StyleResolver.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/Element.h"
#include "sky/engine/core/dom/ExceptionCode.h"
#include "sky/engine/core/dom/RequestAnimationFrameCallback.h"
#include "sky/engine/core/events/PageTransitionEvent.h"
#include "sky/engine/core/frame/FrameHost.h"
#include "sky/engine/core/frame/FrameView.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/frame/Location.h"
#include "sky/engine/core/frame/Screen.h"
#include "sky/engine/core/frame/Settings.h"
#include "sky/engine/core/frame/Tracing.h"
#include "sky/engine/core/inspector/ConsoleMessage.h"
#include "sky/engine/core/loader/FrameLoaderClient.h"
#include "sky/engine/core/page/ChromeClient.h"
#include "sky/engine/core/page/Page.h"
#include "sky/engine/core/rendering/style/RenderStyle.h"
#include "sky/engine/core/script/dart_controller.h"
#include "sky/engine/core/script/dom_dart_state.h"
#include "sky/engine/platform/EventDispatchForbiddenScope.h"
#include "sky/engine/platform/PlatformScreen.h"
#include "sky/engine/platform/geometry/FloatRect.h"
#include "sky/engine/platform/weborigin/KURL.h"
#include "sky/engine/platform/weborigin/SecurityPolicy.h"
#include "sky/engine/public/platform/Platform.h"
#include "sky/engine/public/platform/ServiceProvider.h"
#include "sky/engine/tonic/dart_gc_visitor.h"
#include "sky/engine/wtf/HashCountedSet.h"
#include "sky/engine/wtf/MainThread.h"
#include "sky/engine/wtf/MathExtras.h"
#include "sky/engine/wtf/text/WTFString.h"

// The focus logic in this file is just disconnected cables now.
// TODO(ianh): Remove the concept of focus.

using std::min;
using std::max;

namespace blink {

typedef HashCountedSet<LocalDOMWindow*> DOMWindowSet;


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
    FloatRect window = host->page().windowRect();

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

    // TODO(esprehn): What?
    FloatSize minimumSize = FloatSize(100, 100);
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
}

void LocalDOMWindow::clearDocument()
{
    if (!m_document)
        return;

    m_document->clearDOMWindow();
    m_document = nullptr;
}

PassRefPtr<Document> LocalDOMWindow::installNewDocument(const DocumentInit& init)
{
    ASSERT(init.frame() == m_frame);

    clearDocument();

    m_document = Document::create(init);
    m_document->attach();
    return m_document;
}

LocalDOMWindow::~LocalDOMWindow()
{
    ASSERT(m_hasBeenReset);
    reset();

    ASSERT(m_document->isStopped());
    clearDocument();

}

void LocalDOMWindow::AcceptDartGCVisitor(DartGCVisitor& visitor) const {
    visitor.AddToSetForRoot(document(), dart_wrapper());
}

PassRefPtr<MediaQueryList> LocalDOMWindow::matchMedia(const String& media)
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
    // FIXME(sky): remove
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
    m_location = nullptr;
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

Location& LocalDOMWindow::location() const
{
    if (!m_location)
        m_location = Location::create(m_frame);
    return *m_location;
}

Tracing& LocalDOMWindow::tracing() const
{
    if (!m_tracing)
        m_tracing = Tracing::create();
    return *m_tracing;
}

void LocalDOMWindow::focus()
{
    if (!m_frame)
        return;

    FrameHost* host = m_frame->host();
    if (!host)
        return;

    host->page().focus();

    if (!m_frame)
        return;
}

int LocalDOMWindow::outerHeight() const
{
    if (!m_frame)
        return 0;

    FrameHost* host = m_frame->host();
    if (!host)
        return 0;

    return static_cast<int>(host->page().windowRect().height());
}

int LocalDOMWindow::outerWidth() const
{
    if (!m_frame)
        return 0;

    FrameHost* host = m_frame->host();
    if (!host)
        return 0;

    return static_cast<int>(host->page().windowRect().width());
}

int LocalDOMWindow::innerHeight() const
{
    if (!m_frame)
        return 0;

    FrameView* view = m_frame->view();
    if (!view)
        return 0;

    return view->visibleContentRect().height();
}

int LocalDOMWindow::innerWidth() const
{
    if (!m_frame)
        return 0;

    FrameView* view = m_frame->view();
    if (!view)
        return 0;

    return view->visibleContentRect().width();
}

int LocalDOMWindow::screenX() const
{
    if (!m_frame)
        return 0;

    FrameHost* host = m_frame->host();
    if (!host)
        return 0;

    return static_cast<int>(host->page().windowRect().x());
}

int LocalDOMWindow::screenY() const
{
    if (!m_frame)
        return 0;

    FrameHost* host = m_frame->host();
    if (!host)
        return 0;

    return static_cast<int>(host->page().windowRect().y());
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

PassRefPtr<CSSStyleDeclaration> LocalDOMWindow::getComputedStyle(Element* elt) const
{
    if (!elt)
        return nullptr;

    return CSSComputedStyleDeclaration::create(elt, false);
}

double LocalDOMWindow::devicePixelRatio() const
{
    if (!m_frame)
        return 0.0;

    return m_frame->devicePixelRatio();
}

void LocalDOMWindow::moveBy(float x, float y) const
{
    if (!m_frame)
        return;

    FrameHost* host = m_frame->host();
    if (!host)
        return;

    FloatRect windowRect = host->page().windowRect();
    windowRect.move(x, y);
    // Security check (the spec talks about UniversalBrowserWrite to disable this check...)
    host->page().setWindowRect(adjustWindowRect(*m_frame, windowRect));
}

void LocalDOMWindow::moveTo(float x, float y) const
{
    if (!m_frame)
        return;

    FrameHost* host = m_frame->host();
    if (!host)
        return;

    FloatRect windowRect = host->page().windowRect();
    windowRect.setLocation(FloatPoint(x, y));
    // Security check (the spec talks about UniversalBrowserWrite to disable this check...)
    host->page().setWindowRect(adjustWindowRect(*m_frame, windowRect));
}

void LocalDOMWindow::resizeBy(float x, float y) const
{
    if (!m_frame)
        return;

    FrameHost* host = m_frame->host();
    if (!host)
        return;

    FloatRect fr = host->page().windowRect();
    FloatSize dest = fr.size() + FloatSize(x, y);
    FloatRect update(fr.location(), dest);
    host->page().setWindowRect(adjustWindowRect(*m_frame, update));
}

void LocalDOMWindow::resizeTo(float width, float height) const
{
    if (!m_frame)
        return;

    FrameHost* host = m_frame->host();
    if (!host)
        return;

    FloatRect fr = host->page().windowRect();
    FloatSize dest = FloatSize(width, height);
    FloatRect update(fr.location(), dest);
    host->page().setWindowRect(adjustWindowRect(*m_frame, update));
}

int LocalDOMWindow::requestAnimationFrame(PassOwnPtr<RequestAnimationFrameCallback> callback)
{
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

void LocalDOMWindow::setLocation(const String& urlString, SetLocationLocking locking)
{
    if (!m_frame)
        return;
    FrameHost* host = m_frame->host();
    if (!host)
        return;
    mojo::URLRequestPtr request = mojo::URLRequest::New();
    request->url = document()->completeURL(urlString).string().toUTF8();
    host->services()->NavigatorHost()->RequestNavigate(
        mojo::TARGET_SOURCE_NODE, request.Pass());
}

void LocalDOMWindow::printErrorMessage(const String& message)
{
    if (message.isEmpty())
        return;
}


bool LocalDOMWindow::isInsecureScriptAccess(LocalDOMWindow& callingWindow, const String& urlString)
{
    // FIXME(sky): remove.
    return false;
}

} // namespace blink
