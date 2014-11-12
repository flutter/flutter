/*
 * Copyright (C) 1998, 1999 Torben Weis <weis@kde.org>
 *                     1999 Lars Knoll <knoll@kde.org>
 *                     1999 Antti Koivisto <koivisto@kde.org>
 *                     2000 Simon Hausmann <hausmann@kde.org>
 *                     2000 Stefan Schimanski <1Stein@gmx.de>
 *                     2001 George Staikos <staikos@kde.org>
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011 Apple Inc. All rights reserved.
 * Copyright (C) 2005 Alexey Proskuryakov <ap@nypop.com>
 * Copyright (C) 2008 Nokia Corporation and/or its subsidiary(-ies)
 * Copyright (C) 2008 Eric Seidel <eric@webkit.org>
 * Copyright (C) 2008 Google Inc.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
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
#include "core/frame/LocalFrame.h"

#include "bindings/core/v8/ScriptController.h"
#include "core/editing/Editor.h"
#include "core/editing/FrameSelection.h"
#include "core/editing/InputMethodController.h"
#include "core/editing/SpellChecker.h"
#include "core/editing/htmlediting.h"
#include "core/editing/markup.h"
#include "core/events/Event.h"
#include "core/fetch/ResourceFetcher.h"
#include "core/frame/FrameConsole.h"
#include "core/frame/FrameDestructionObserver.h"
#include "core/frame/FrameHost.h"
#include "core/frame/FrameView.h"
#include "core/frame/LocalDOMWindow.h"
#include "core/frame/Settings.h"
#include "core/inspector/ConsoleMessageStorage.h"
#include "core/loader/FrameLoaderClient.h"
#include "core/loader/MojoLoader.h"
#include "core/page/Chrome.h"
#include "core/page/EventHandler.h"
#include "core/page/FocusController.h"
#include "core/page/Page.h"
#include "core/rendering/HitTestResult.h"
#include "core/rendering/RenderLayer.h"
#include "core/rendering/RenderView.h"
#include "core/rendering/compositing/RenderLayerCompositor.h"
#include "platform/RuntimeEnabledFeatures.h"
#include "platform/graphics/GraphicsContext.h"
#include "platform/graphics/ImageBuffer.h"
#include "platform/text/TextStream.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/StdLibExtras.h"

namespace blink {

inline LocalFrame::LocalFrame(FrameLoaderClient* client, FrameHost* host)
    : Frame(client, host)
    , m_deprecatedLoader(this)
    , m_mojoLoader(adoptPtr(new MojoLoader(*this)))
    , m_script(adoptPtr(new ScriptController(this)))
    , m_editor(Editor::create(*this))
    , m_spellChecker(SpellChecker::create(*this))
    , m_selection(FrameSelection::create(this))
    , m_eventHandler(adoptPtr(new EventHandler(this)))
    , m_console(FrameConsole::create(*this))
    , m_inputMethodController(InputMethodController::create(*this))
{
    page()->setMainFrame(this);
}

PassRefPtr<LocalFrame> LocalFrame::create(FrameLoaderClient* client, FrameHost* host)
{
    return adoptRef(new LocalFrame(client, host));
}

LocalFrame::~LocalFrame()
{
    setView(nullptr);
    m_deprecatedLoader.clear();
    setDOMWindow(nullptr);

    // FIXME: What to do here... some of this is redundant with ~Frame.
    HashSet<FrameDestructionObserver*>::iterator stop = m_destructionObservers.end();
    for (HashSet<FrameDestructionObserver*>::iterator it = m_destructionObservers.begin(); it != stop; ++it)
        (*it)->frameDestroyed();
}

FrameLoaderClient* LocalFrame::loaderClient() const
{
    return static_cast<FrameLoaderClient*>(client());
}

FetchContext& LocalFrame::fetchContext() const
{
    return m_deprecatedLoader.fetchContext();
}

void LocalFrame::detach()
{
    // A lot of the following steps can result in the current frame being
    // detached, so protect a reference to it.
    RefPtr<LocalFrame> protect(this);
    m_deprecatedLoader.stopAllLoaders();
    m_deprecatedLoader.closeURL();
    detachChildren();
    // stopAllLoaders() needs to be called after detachChildren(), because detachChildren()
    // will trigger the unload event handlers of any child frames, and those event
    // handlers might start a new subresource load in this frame.
    m_deprecatedLoader.stopAllLoaders();

    setView(nullptr);
    willDetachFrameHost();

    // Finish all cleanup work that might require talking to the embedder.
    // Notify ScriptController that the frame is closing, since its cleanup ends up calling
    // back to FrameLoaderClient via WindowProxy.
    script().clearForClose();
    // After this, we must no longer talk to the client since this clears
    // its owning reference back to our owning LocalFrame.
    loaderClient()->detachedFromParent();
    clearClient();
    detachFromFrameHost();
}

void LocalFrame::setView(PassRefPtr<FrameView> view)
{
    // We the custom scroll bars as early as possible to prevent m_doc->detach()
    // from messing with the view such that its scroll bars won't be torn down.
    // FIXME: We should revisit this.
    if (m_view)
        m_view->prepareForDetach();

    // Prepare for destruction now, so any unload event handlers get run and the LocalDOMWindow is
    // notified. If we wait until the view is destroyed, then things won't be hooked up enough for
    // these calls to work.
    if (!view && document() && document()->isActive()) {
        // FIXME: We don't call willRemove here. Why is that OK?
        document()->prepareForDestruction();
    }

    eventHandler().clear();

    m_view = view;
}

FloatSize LocalFrame::resizePageRectsKeepingRatio(const FloatSize& originalSize, const FloatSize& expectedSize)
{
    FloatSize resultSize;
    if (!contentRenderer())
        return FloatSize();

    ASSERT(fabs(originalSize.width()) > std::numeric_limits<float>::epsilon());
    float ratio = originalSize.height() / originalSize.width();
    resultSize.setWidth(floorf(expectedSize.width()));
    resultSize.setHeight(floorf(resultSize.width() * ratio));
    return resultSize;
}

void LocalFrame::setDOMWindow(PassRefPtr<LocalDOMWindow> domWindow)
{
    if (m_domWindow) {
        console().messageStorage()->frameWindowDiscarded(m_domWindow.get());
    }
    if (domWindow)
        script().clearWindowProxy();
    Frame::setDOMWindow(domWindow);
}

void LocalFrame::didChangeVisibilityState()
{
    if (document())
        document()->didChangeVisibilityState();
}

void LocalFrame::addDestructionObserver(FrameDestructionObserver* observer)
{
    m_destructionObservers.add(observer);
}

void LocalFrame::removeDestructionObserver(FrameDestructionObserver* observer)
{
    m_destructionObservers.remove(observer);
}

void LocalFrame::willDetachFrameHost()
{
    // We should never be detatching the page during a Layout.
    RELEASE_ASSERT(!m_view || !m_view->isInPerformLayout());

    HashSet<FrameDestructionObserver*>::iterator stop = m_destructionObservers.end();
    for (HashSet<FrameDestructionObserver*>::iterator it = m_destructionObservers.begin(); it != stop; ++it)
        (*it)->willDetachFrameHost();

    // FIXME: Page should take care of updating focus/scrolling instead of Frame.
    // FIXME: It's unclear as to why this is called more than once, but it is,
    // so page() could be null.
    if (page() && page()->focusController().focusedFrame() == this)
        page()->focusController().setFocusedFrame(nullptr);
}

void LocalFrame::detachFromFrameHost()
{
    // We should never be detatching the page during a Layout.
    RELEASE_ASSERT(!m_view || !m_view->isInPerformLayout());
    m_host = 0;
}

String LocalFrame::selectedText() const
{
    return selection().selectedText();
}

VisiblePosition LocalFrame::visiblePositionForPoint(const IntPoint& framePoint)
{
    HitTestResult result = eventHandler().hitTestResultAtPoint(framePoint);
    Node* node = result.innerNonSharedNode();
    if (!node)
        return VisiblePosition();
    RenderObject* renderer = node->renderer();
    if (!renderer)
        return VisiblePosition();
    VisiblePosition visiblePos = VisiblePosition(renderer->positionForPoint(result.localPoint()));
    if (visiblePos.isNull())
        visiblePos = VisiblePosition(firstPositionInOrBeforeNode(node));
    return visiblePos;
}

RenderView* LocalFrame::contentRenderer() const
{
    return document() ? document()->renderView() : 0;
}

Document* LocalFrame::document() const
{
    return m_domWindow ? m_domWindow->document() : 0;
}

Document* LocalFrame::documentAtPoint(const IntPoint& point)
{
    if (!view())
        return 0;

    IntPoint pt = view()->windowToContents(point);
    HitTestResult result = HitTestResult(pt);

    if (contentRenderer())
        result = eventHandler().hitTestResultAtPoint(pt, HitTestRequest::ReadOnly | HitTestRequest::Active);
    return result.innerNode() ? &result.innerNode()->document() : 0;
}

PassRefPtr<Range> LocalFrame::rangeForPoint(const IntPoint& framePoint)
{
    VisiblePosition position = visiblePositionForPoint(framePoint);
    if (position.isNull())
        return nullptr;

    VisiblePosition previous = position.previous();
    if (previous.isNotNull()) {
        RefPtr<Range> previousCharacterRange = makeRange(previous, position);
        LayoutRect rect = editor().firstRectForRange(previousCharacterRange.get());
        if (rect.contains(framePoint))
            return previousCharacterRange.release();
    }

    VisiblePosition next = position.next();
    if (RefPtr<Range> nextCharacterRange = makeRange(position, next)) {
        LayoutRect rect = editor().firstRectForRange(nextCharacterRange.get());
        if (rect.contains(framePoint))
            return nextCharacterRange.release();
    }

    return nullptr;
}

void LocalFrame::createView(const IntSize& viewportSize, const Color& backgroundColor, bool transparent,
    ScrollbarMode horizontalScrollbarMode, bool horizontalLock,
    ScrollbarMode verticalScrollbarMode, bool verticalLock)
{
    ASSERT(this);
    ASSERT(page());

    setView(nullptr);

    RefPtr<FrameView> frameView;
    frameView = FrameView::create(this, viewportSize);

    // The layout size is set by WebViewImpl to support @viewport
    frameView->setLayoutSizeFixedToFrameSize(false);

    setView(frameView);

    frameView->updateBackgroundRecursively(backgroundColor, transparent);
}


void LocalFrame::countObjectsNeedingLayout(unsigned& needsLayoutObjects, unsigned& totalObjects, bool& isPartial)
{
    RenderObject* root = view()->layoutRoot();
    isPartial = true;
    if (!root) {
        isPartial = false;
        root = contentRenderer();
    }

    needsLayoutObjects = 0;
    totalObjects = 0;

    for (RenderObject* o = root; o; o = o->nextInPreOrder(root)) {
        ++totalObjects;
        if (o->needsLayout())
            ++needsLayoutObjects;
    }
}

String LocalFrame::layerTreeAsText(LayerTreeFlags flags) const
{
    TextStream textStream;
    textStream << localLayerTreeAsText(flags);
    return textStream.release();
}

String LocalFrame::localLayerTreeAsText(unsigned flags) const
{
    if (!contentRenderer())
        return String();

    return contentRenderer()->compositor()->layerTreeAsText(static_cast<LayerTreeFlags>(flags));
}

void LocalFrame::deviceOrPageScaleFactorChanged()
{
    document()->mediaQueryAffectingValueChanged();
}

void LocalFrame::removeSpellingMarkersUnderWords(const Vector<String>& words)
{
    spellChecker().removeSpellingMarkersUnderWords(words);
}

struct ScopedFramePaintingState {
    ScopedFramePaintingState(LocalFrame* frame)
        : frame(frame)
        , paintBehavior(frame->view()->paintBehavior())
    {
    }

    ~ScopedFramePaintingState()
    {
        frame->view()->setPaintBehavior(paintBehavior);
        frame->view()->setNodeToDraw(0);
    }

    LocalFrame* frame;
    PaintBehavior paintBehavior;
};

double LocalFrame::devicePixelRatio() const
{
    if (!m_host)
        return 0;
    return m_host->deviceScaleFactor();
}

} // namespace blink
