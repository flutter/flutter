/*
 * Copyright (C) 2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013 Apple Inc. All Rights Reserved.
 * Copyright (C) 2008 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */

#include "config.h"
#include "core/page/Page.h"

#include "core/dom/ClientRectList.h"
#include "core/dom/DocumentMarkerController.h"
#include "core/dom/StyleEngine.h"
#include "core/editing/Caret.h"
#include "core/editing/UndoStack.h"
#include "core/events/Event.h"
#include "core/fetch/ResourceFetcher.h"
#include "core/frame/DOMTimer.h"
#include "core/frame/FrameConsole.h"
#include "core/frame/FrameHost.h"
#include "core/frame/FrameView.h"
#include "core/frame/LocalDOMWindow.h"
#include "core/frame/LocalFrame.h"
#include "core/frame/Settings.h"
#include "core/page/AutoscrollController.h"
#include "core/page/Chrome.h"
#include "core/page/ChromeClient.h"
#include "core/page/FocusController.h"
#include "core/page/PageLifecycleNotifier.h"
#include "core/rendering/RenderView.h"
#include "wtf/HashMap.h"
#include "wtf/RefCountedLeakCounter.h"
#include "wtf/StdLibExtras.h"
#include "wtf/text/Base64.h"

namespace blink {

DEFINE_DEBUG_ONLY_GLOBAL(WTF::RefCountedLeakCounter, pageCounter, ("Page"));

float deviceScaleFactor(LocalFrame* frame)
{
    if (!frame)
        return 1;
    Page* page = frame->page();
    if (!page)
        return 1;
    return page->deviceScaleFactor();
}

Page::Page(PageClients& pageClients, ServiceProvider& services)
    : SettingsDelegate(Settings::create())
    , m_animator(this)
    , m_autoscrollController(AutoscrollController::create(*this))
    , m_chrome(Chrome::create(this, pageClients.chromeClient))
    , m_dragCaretController(DragCaretController::create())
    , m_focusController(FocusController::create(this))
    , m_undoStack(UndoStack::create())
    , m_mainFrame(0)
    , m_editorClient(pageClients.editorClient)
    , m_spellCheckerClient(pageClients.spellCheckerClient)
    , m_tabKeyCyclesThroughElements(true)
    , m_deviceScaleFactor(1)
    , m_timerAlignmentInterval(DOMTimer::visiblePageAlignmentInterval())
    , m_visibilityState(PageVisibilityStateVisible)
    , m_isCursorVisible(true)
#if ENABLE(ASSERT)
    , m_isPainting(false)
#endif
    , m_frameHost(FrameHost::create(*this, services))
    , m_inspectorHost(0)
{
    ASSERT(m_editorClient);

#ifndef NDEBUG
    pageCounter.increment();
#endif
}

Page::~Page()
{
    // willBeDestroyed() must be called before Page destruction.
    ASSERT(!m_mainFrame);
}

void Page::setMainFrame(LocalFrame* mainFrame)
{
    // Should only be called during initialization or swaps between local and
    // remote frames.
    // FIXME: Unfortunately we can't assert on this at the moment, because this
    // is called in the base constructor for both LocalFrame and RemoteFrame,
    // when the vtables for the derived classes have not yet been setup.
    m_mainFrame = mainFrame;
}

void Page::documentDetached(Document* document)
{
    m_multisamplingChangedObservers.clear();
}

bool Page::openedByDOM() const
{
    return m_openedByDOM;
}

void Page::setOpenedByDOM()
{
    m_openedByDOM = true;
}

void Page::setNeedsRecalcStyleInAllFrames()
{
    LocalFrame* frame = mainFrame();
    if (frame && frame->document())
        frame->document()->styleResolverChanged();
}

void Page::setNeedsLayoutInAllFrames()
{
    LocalFrame* frame = mainFrame();
    if (FrameView* view = frame->view()) {
        view->setNeedsLayout();
        view->scheduleRelayout();
    }
}

void Page::unmarkAllTextMatches()
{
    if (!mainFrame())
        return;

    mainFrame()->document()->markers().removeMarkers(DocumentMarker::TextMatch);
}

void Page::setDeviceScaleFactor(float scaleFactor)
{
    if (m_deviceScaleFactor == scaleFactor)
        return;

    m_deviceScaleFactor = scaleFactor;
    setNeedsRecalcStyleInAllFrames();

    if (mainFrame())
        mainFrame()->deviceOrPageScaleFactorChanged();
}

void Page::setTimerAlignmentInterval(double interval)
{
    if (interval == m_timerAlignmentInterval)
        return;

    m_timerAlignmentInterval = interval;
    LocalFrame* frame = mainFrame();
    if (frame->document())
        frame->document()->didChangeTimerAlignmentInterval();
}

double Page::timerAlignmentInterval() const
{
    return m_timerAlignmentInterval;
}

void Page::setVisibilityState(PageVisibilityState visibilityState, bool isInitialState)
{
    if (m_visibilityState == visibilityState)
        return;
    m_visibilityState = visibilityState;

    if (visibilityState == blink::PageVisibilityStateVisible)
        setTimerAlignmentInterval(DOMTimer::visiblePageAlignmentInterval());
    else
        setTimerAlignmentInterval(DOMTimer::hiddenPageAlignmentInterval());

    if (!isInitialState)
        lifecycleNotifier().notifyPageVisibilityChanged();

    if (!isInitialState && m_mainFrame)
        mainFrame()->didChangeVisibilityState();
}

PageVisibilityState Page::visibilityState() const
{
    return m_visibilityState;
}

bool Page::isCursorVisible() const
{
    return m_isCursorVisible && settings().deviceSupportsMouse();
}

void Page::addMultisamplingChangedObserver(MultisamplingChangedObserver* observer)
{
    m_multisamplingChangedObservers.add(observer);
}

void Page::removeMultisamplingChangedObserver(MultisamplingChangedObserver* observer)
{
    m_multisamplingChangedObservers.remove(observer);
}

void Page::settingsChanged(SettingsDelegate::ChangeType changeType)
{
    switch (changeType) {
    case SettingsDelegate::StyleChange:
        setNeedsRecalcStyleInAllFrames();
        break;
    case SettingsDelegate::MediaTypeChange:
        if (mainFrame()) {
            mainFrame()->view()->setMediaType(AtomicString(settings().mediaTypeOverride()));
            setNeedsRecalcStyleInAllFrames();
        }
        break;
    case SettingsDelegate::MultisamplingChange: {
        HashSet<RawPtr<MultisamplingChangedObserver> >::iterator stop = m_multisamplingChangedObservers.end();
        for (HashSet<RawPtr<MultisamplingChangedObserver> >::iterator it = m_multisamplingChangedObservers.begin(); it != stop; ++it)
            (*it)->multisamplingChanged(m_settings->openGLMultisamplingEnabled());
        break;
    }
    case SettingsDelegate::ImageLoadingChange:
        if (mainFrame() && mainFrame()->document()) {
            mainFrame()->document()->fetcher()->setImagesEnabled(settings().imagesEnabled());
            mainFrame()->document()->fetcher()->setAutoLoadImages(settings().loadsImagesAutomatically());
        }
        break;
    case SettingsDelegate::FontFamilyChange:
        if (mainFrame()->document())
            mainFrame()->document()->styleEngine()->updateGenericFontFamilySettings();
        setNeedsRecalcStyleInAllFrames();
        break;
    case SettingsDelegate::AcceleratedCompositingChange:
        updateAcceleratedCompositingSettings();
        break;
    case SettingsDelegate::MediaQueryChange:
        if (mainFrame()->document())
            mainFrame()->document()->mediaQueryAffectingValueChanged();
        setNeedsRecalcStyleInAllFrames();
        break;
    }
}

void Page::updateAcceleratedCompositingSettings()
{
    if (FrameView* view = mainFrame()->view())
        view->updateAcceleratedCompositingSettings();
}

void Page::didCommitLoad(LocalFrame* frame)
{
    lifecycleNotifier().notifyDidCommitLoad(frame);
    if (m_mainFrame == frame) {
        frame->console().clearMessages();
        useCounter().didCommitLoad();
    }
}

void Page::acceptLanguagesChanged()
{
    mainFrame()->domWindow()->acceptLanguagesChanged();
}

PageLifecycleNotifier& Page::lifecycleNotifier()
{
    return static_cast<PageLifecycleNotifier&>(LifecycleContext<Page>::lifecycleNotifier());
}

PassOwnPtr<LifecycleNotifier<Page> > Page::createLifecycleNotifier()
{
    return PageLifecycleNotifier::create(this);
}

void Page::willBeDestroyed()
{
    RefPtr<LocalFrame> mainFrame = m_mainFrame;

    mainFrame->detach();
    mainFrame->setView(nullptr);

#ifndef NDEBUG
    pageCounter.decrement();
#endif

    m_chrome->willBeDestroyed();
    m_mainFrame = 0;
}

Page::PageClients::PageClients()
    : chromeClient(0)
    , editorClient(0)
    , spellCheckerClient(0)
{
}

Page::PageClients::~PageClients()
{
}

} // namespace blink
