/*
 * Copyright (C) 1998, 1999 Torben Weis <weis@kde.org>
 *                     1999 Lars Knoll <knoll@kde.org>
 *                     1999 Antti Koivisto <koivisto@kde.org>
 *                     2000 Dirk Mueller <mueller@kde.org>
 * Copyright (C) 2004, 2005, 2006, 2007, 2008 Apple Inc. All rights reserved.
 *           (C) 2006 Graham Dennis (graham.dennis@gmail.com)
 *           (C) 2006 Alexey Proskuryakov (ap@nypop.com)
 * Copyright (C) 2009 Google Inc. All rights reserved.
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

#include "sky/engine/core/frame/FrameView.h"

#include "gen/sky/platform/RuntimeEnabledFeatures.h"
#include "sky/engine/core/animation/DocumentAnimations.h"
#include "sky/engine/core/css/resolver/StyleResolver.h"
#include "sky/engine/core/dom/DocumentMarkerController.h"
#include "sky/engine/core/editing/FrameSelection.h"
#include "sky/engine/core/fetch/ResourceFetcher.h"
#include "sky/engine/core/frame/FrameHost.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/frame/Settings.h"
#include "sky/engine/core/loader/FrameLoaderClient.h"
#include "sky/engine/core/page/ChromeClient.h"
#include "sky/engine/core/page/EventHandler.h"
#include "sky/engine/core/page/FocusController.h"
#include "sky/engine/core/page/Page.h"
#include "sky/engine/core/rendering/RenderLayer.h"
#include "sky/engine/core/rendering/RenderView.h"
#include "sky/engine/core/rendering/style/RenderStyle.h"
#include "sky/engine/platform/ScriptForbiddenScope.h"
#include "sky/engine/platform/TraceEvent.h"
#include "sky/engine/platform/fonts/FontCache.h"
#include "sky/engine/platform/geometry/FloatRect.h"
#include "sky/engine/platform/graphics/GraphicsContext.h"
#include "sky/engine/platform/text/TextStream.h"
#include "sky/engine/wtf/CurrentTime.h"
#include "sky/engine/wtf/TemporaryChange.h"

namespace blink {

double FrameView::s_currentFrameTimeStamp = 0.0;
bool FrameView::s_inPaintContents = false;

FrameView::FrameView(LocalFrame* frame)
    : m_frame(frame)
    , m_hasPendingLayout(false)
    , m_layoutSubtreeRoot(0)
    , m_inSynchronousPostLayout(false)
    , m_postLayoutTasksTimer(this, &FrameView::postLayoutTimerFired)
    , m_isTransparent(false)
    , m_baseBackgroundColor(Color::white)
    , m_mediaType("screen")
    , m_overflowStatusDirty(true)
    , m_viewportRenderer(0)
    , m_hasSoftwareFilters(false)
    , m_visibleContentScaleFactor(1)
    , m_inputEventsScaleFactorForEmulation(1)
    , m_layoutSizeFixedToFrameSize(true)
{
    ASSERT(m_frame);
    init();
}

PassRefPtr<FrameView> FrameView::create(LocalFrame* frame)
{
    RefPtr<FrameView> view = adoptRef(new FrameView(frame));
    return view.release();
}

PassRefPtr<FrameView> FrameView::create(LocalFrame* frame, const IntSize& initialSize)
{
    RefPtr<FrameView> view = adoptRef(new FrameView(frame));
    view->Widget::setFrameRect(IntRect(view->location(), initialSize));
    view->setLayoutSizeInternal(initialSize);
    return view.release();
}

FrameView::~FrameView()
{
    if (m_postLayoutTasksTimer.isActive())
        m_postLayoutTasksTimer.stop();

    ASSERT(m_frame);
    ASSERT(m_frame->view() != this || !m_frame->contentRenderer());
}

void FrameView::reset()
{
    m_hasPendingLayout = false;
    m_layoutSubtreeRoot = 0;
    m_layoutSchedulingEnabled = true;
    m_inPerformLayout = false;
    m_inSynchronousPostLayout = false;
    m_layoutCount = 0;
    m_nestedLayoutCount = 0;
    m_postLayoutTasksTimer.stop();
    m_firstLayout = true;
    m_firstLayoutCallbackPending = false;
    m_lastViewportSize = IntSize();
    m_lastPaintTime = 0;
    m_isPainting = false;
}

void FrameView::init()
{
    reset();

    m_size = LayoutSize();
}

void FrameView::prepareForDetach()
{
    // FIXME(sky): Remove
}

void FrameView::clear()
{
    reset();
}

bool FrameView::didFirstLayout() const
{
    return !m_firstLayout;
}

void FrameView::setFrameRect(const IntRect& newRect)
{
    IntRect oldRect = frameRect();
    if (newRect == oldRect)
        return;

    Widget::setFrameRect(newRect);
}

Page* FrameView::page() const
{
    return frame().page();
}

RenderView* FrameView::renderView() const
{
    return frame().contentRenderer();
}

IntPoint FrameView::clampOffsetAtScale(const IntPoint& offset, float scale) const
{
    FloatSize scaledSize = unscaledVisibleContentSize();
    if (scale)
        scaledSize.scale(1 / scale);

    IntPoint clampedOffset = offset;
    clampedOffset = clampedOffset.shrunkTo(
        IntPoint(size()) - expandedIntSize(scaledSize));
    return clampedOffset;
}

void FrameView::recalcOverflowAfterStyleChange()
{
    RenderView* renderView = this->renderView();
    RELEASE_ASSERT(renderView);
    if (!renderView->needsOverflowRecalcAfterStyleChange())
        return;

    renderView->recalcOverflowAfterStyleChange();
}

RenderObject* FrameView::layoutRoot(bool onlyDuringLayout) const
{
    return onlyDuringLayout && layoutPending() ? 0 : m_layoutSubtreeRoot;
}

void FrameView::performPreLayoutTasks()
{
    TRACE_EVENT0("blink", "FrameView::performPreLayoutTasks");
    lifecycle().advanceTo(DocumentLifecycle::InPreLayout);

    // Don't schedule more layouts, we're in one.
    TemporaryChange<bool> changeSchedulingEnabled(m_layoutSchedulingEnabled, false);

    if (!m_nestedLayoutCount && !m_inSynchronousPostLayout && m_postLayoutTasksTimer.isActive()) {
        // This is a new top-level layout. If there are any remaining tasks from the previous layout, finish them now.
        m_inSynchronousPostLayout = true;
        performPostLayoutTasks();
        m_inSynchronousPostLayout = false;
    }

    Document* document = m_frame->document();
    if (wasViewportResized()) {
        document->notifyResizeForViewportUnits();
        document->mediaQueryAffectingValueChanged();

        // TODO(esprehn): This is way too much work, it rebuilds the entire sheet list
        // and does a full document recalc.
        document->styleResolverChanged();
    }

    document->updateRenderTreeIfNeeded();
    lifecycle().advanceTo(DocumentLifecycle::StyleClean);
}

void FrameView::performLayout(RenderObject* rootForThisLayout, bool inSubtreeLayout)
{
    TRACE_EVENT0("blink", "FrameView::performLayout");

    ScriptForbiddenScope forbidScript;

    ASSERT(!isInPerformLayout());
    lifecycle().advanceTo(DocumentLifecycle::InPerformLayout);

    TemporaryChange<bool> changeInPerformLayout(m_inPerformLayout, true);

    // performLayout is the actual guts of layout().
    // FIXME: The 300 other lines in layout() probably belong in other helper functions
    // so that a single human could understand what layout() is actually doing.
    rootForThisLayout->layout();

    lifecycle().advanceTo(DocumentLifecycle::AfterPerformLayout);
}

void FrameView::scheduleOrPerformPostLayoutTasks()
{
    if (m_postLayoutTasksTimer.isActive())
        return;

    if (!m_inSynchronousPostLayout) {
        m_inSynchronousPostLayout = true;
        // Calls resumeScheduledEvents()
        performPostLayoutTasks();
        m_inSynchronousPostLayout = false;
    }

    if (!m_postLayoutTasksTimer.isActive() && (needsLayout() || m_inSynchronousPostLayout)) {
        // If we need layout or are already in a synchronous call to postLayoutTasks(),
        // defer widget updates and event dispatch until after we return. postLayoutTasks()
        // can make us need to update again, and we can get stuck in a nasty cycle unless
        // we call it through the timer here.
        m_postLayoutTasksTimer.startOneShot(0, FROM_HERE);
        if (needsLayout())
            layout();
    }
}

void FrameView::layout(bool allowSubtree)
{
    // We should never layout a Document which is not in a LocalFrame.
    ASSERT(m_frame);
    ASSERT(m_frame->view() == this);

    ScriptForbiddenScope forbidScript;

    if (isInPerformLayout() || !m_frame->document()->isActive())
        return;

    TRACE_EVENT0("blink", "FrameView::layout");
    TRACE_EVENT_SCOPED_SAMPLING_STATE("blink", "Layout");

    // Protect the view from being deleted during layout (in recalcStyle)
    RefPtr<FrameView> protector(this);

    m_hasPendingLayout = false;
    DocumentLifecycle::Scope lifecycleScope(lifecycle(), DocumentLifecycle::LayoutClean);

    RELEASE_ASSERT(!isPainting());

    if (!allowSubtree && isSubtreeLayout()) {
        m_layoutSubtreeRoot->markContainingBlocksForLayout(false);
        m_layoutSubtreeRoot = 0;
    }

    performPreLayoutTasks();

    // If there is only one ref to this view left, then its going to be destroyed as soon as we exit,
    // so there's no point to continuing to layout
    if (protector->hasOneRef())
        return;

    Document* document = m_frame->document();
    bool inSubtreeLayout = isSubtreeLayout();
    RenderObject* rootForThisLayout = inSubtreeLayout ? m_layoutSubtreeRoot : document->renderView();
    if (!rootForThisLayout) {
        // FIXME: Do we need to set m_size here?
        ASSERT_NOT_REACHED();
        return;
    }

    FontCachePurgePreventer fontCachePurgePreventer;
    RenderLayer* layer;
    {
        TemporaryChange<bool> changeSchedulingEnabled(m_layoutSchedulingEnabled, false);

        m_nestedLayoutCount++;

        if (!inSubtreeLayout) {
            if (m_firstLayout) {
                m_firstLayout = false;
                m_firstLayoutCallbackPending = true;
                m_lastViewportSize = layoutSize();
            }

            m_size = LayoutSize(layoutSize());
        }

        layer = rootForThisLayout->enclosingLayer();

        performLayout(rootForThisLayout, inSubtreeLayout);

        m_layoutSubtreeRoot = 0;
    } // Reset m_layoutSchedulingEnabled to its previous value.

    layer->updateLayerPositionsAfterLayout();

    m_layoutCount++;

    ASSERT(!rootForThisLayout->needsLayout());

    scheduleOrPerformPostLayoutTasks();

    m_nestedLayoutCount--;
    if (m_nestedLayoutCount)
        return;

#if ENABLE(ASSERT)
    // Post-layout assert that nobody was re-marked as needing layout during layout.
    document->renderView()->assertSubtreeIsLaidOut();
#endif
}

DocumentLifecycle& FrameView::lifecycle() const
{
    return m_frame->document()->lifecycle();
}

void FrameView::setMediaType(const AtomicString& mediaType)
{
    ASSERT(m_frame->document());
    m_frame->document()->mediaQueryAffectingValueChanged();
    m_mediaType = mediaType;
}

AtomicString FrameView::mediaType() const
{
    // See if we have an override type.
    String overrideType;
    if (!overrideType.isNull())
        return AtomicString(overrideType);
    return m_mediaType;
}

// FIXME(sky): remove
IntSize FrameView::layoutSize() const
{
    return m_layoutSize;
}

void FrameView::setLayoutSize(const IntSize& size)
{
    ASSERT(!layoutSizeFixedToFrameSize());

    setLayoutSizeInternal(size);
}

HostWindow* FrameView::hostWindow() const
{
    return frame().page();
}

void FrameView::contentsResized()
{
    setNeedsLayout();
}

void FrameView::scheduleRelayout()
{
    ASSERT(m_frame->view() == this);

    if (isSubtreeLayout()) {
        m_layoutSubtreeRoot->markContainingBlocksForLayout(false);
        m_layoutSubtreeRoot = 0;
    }
    if (!m_layoutSchedulingEnabled)
        return;
    if (!needsLayout())
        return;
    if (!m_frame->document()->isActive())
        return;

    if (m_hasPendingLayout)
        return;
    m_hasPendingLayout = true;

    m_frame->document()->scheduleVisualUpdate();
    lifecycle().ensureStateAtMost(DocumentLifecycle::StyleClean);
}

static bool isObjectAncestorContainerOf(RenderObject* ancestor, RenderObject* descendant)
{
    for (RenderObject* r = descendant; r; r = r->container()) {
        if (r == ancestor)
            return true;
    }
    return false;
}

void FrameView::scheduleRelayoutOfSubtree(RenderObject* relayoutRoot)
{
    ASSERT(m_frame->view() == this);

    if (!m_frame->document()->isActive())
        return;

    RenderView* renderView = this->renderView();
    if (renderView && renderView->needsLayout()) {
        if (relayoutRoot)
            relayoutRoot->markContainingBlocksForLayout(false);
        return;
    }

    if (layoutPending() || !m_layoutSchedulingEnabled) {
        if (m_layoutSubtreeRoot != relayoutRoot) {
            if (isObjectAncestorContainerOf(m_layoutSubtreeRoot, relayoutRoot)) {
                // Keep the current root
                relayoutRoot->markContainingBlocksForLayout(false, m_layoutSubtreeRoot);
                ASSERT(!m_layoutSubtreeRoot->container() || !m_layoutSubtreeRoot->container()->needsLayout());
            } else if (isSubtreeLayout() && isObjectAncestorContainerOf(relayoutRoot, m_layoutSubtreeRoot)) {
                // Re-root at relayoutRoot
                m_layoutSubtreeRoot->markContainingBlocksForLayout(false, relayoutRoot);
                m_layoutSubtreeRoot = relayoutRoot;
                ASSERT(!m_layoutSubtreeRoot->container() || !m_layoutSubtreeRoot->container()->needsLayout());
            } else {
                // Just do a full relayout
                if (isSubtreeLayout())
                    m_layoutSubtreeRoot->markContainingBlocksForLayout(false);
                m_layoutSubtreeRoot = 0;
                relayoutRoot->markContainingBlocksForLayout(false);
            }
        }
    } else if (m_layoutSchedulingEnabled) {
        m_layoutSubtreeRoot = relayoutRoot;
        ASSERT(!m_layoutSubtreeRoot->container() || !m_layoutSubtreeRoot->container()->needsLayout());
        m_hasPendingLayout = true;

        m_frame->document()->scheduleVisualUpdate();
        lifecycle().ensureStateAtMost(DocumentLifecycle::StyleClean);
    }
}

bool FrameView::layoutPending() const
{
    // FIXME: This should check Document::lifecycle instead.
    return m_hasPendingLayout;
}

bool FrameView::isInPerformLayout() const
{
    ASSERT(m_inPerformLayout == (lifecycle().state() == DocumentLifecycle::InPerformLayout));
    return m_inPerformLayout;
}

bool FrameView::needsLayout() const
{
    RenderView* renderView = this->renderView();
    return layoutPending()
        || (renderView && renderView->needsLayout())
        || isSubtreeLayout();
}

void FrameView::setNeedsLayout()
{
    if (RenderView* renderView = this->renderView())
        renderView->setNeedsLayout();
}

bool FrameView::isTransparent() const
{
    return m_isTransparent;
}

void FrameView::setTransparent(bool isTransparent)
{
    m_isTransparent = isTransparent;
}

Color FrameView::baseBackgroundColor() const
{
    return m_baseBackgroundColor;
}

void FrameView::setBaseBackgroundColor(const Color& backgroundColor)
{
    m_baseBackgroundColor = backgroundColor;
}

void FrameView::updateBackgroundRecursively(const Color& backgroundColor, bool transparent)
{
    // FIXME(sky): simplify
    setTransparent(transparent);
    setBaseBackgroundColor(backgroundColor);
}

void FrameView::flushAnyPendingPostLayoutTasks()
{
    ASSERT(!isInPerformLayout());
    if (m_postLayoutTasksTimer.isActive())
        performPostLayoutTasks();
}

void FrameView::performPostLayoutTasks()
{
    // FIXME: We can reach here, even when the page is not active!
    // http/tests/inspector/elements/html-link-import.html and many other
    // tests hit that case.
    // We should ASSERT(isActive()); or at least return early if we can!
    ASSERT(!isInPerformLayout()); // Always before or after performLayout(), part of the highest-level layout() call.
    TRACE_EVENT0("blink", "FrameView::performPostLayoutTasks");
    RefPtr<FrameView> protect(this);

    m_postLayoutTasksTimer.stop();

    m_frame->selection().setCaretRectNeedsUpdate();
    m_frame->selection().updateAppearance();

    ASSERT(m_frame->document());
    if (m_nestedLayoutCount <= 1) {
        if (m_firstLayoutCallbackPending)
            m_firstLayoutCallbackPending = false;
    }

    sendResizeEventIfNeeded();
}

bool FrameView::wasViewportResized()
{
    return layoutSize() != m_lastViewportSize;
}

void FrameView::sendResizeEventIfNeeded()
{
    if (!wasViewportResized())
        return;

    m_lastViewportSize = layoutSize();
    m_frame->document()->enqueueResizeEvent();
}

void FrameView::postLayoutTimerFired(Timer<FrameView>*)
{
    performPostLayoutTasks();
}

IntRect FrameView::windowClipRect() const
{
    ASSERT(m_frame->view() == this);

    if (paintsEntireContents())
        return IntRect(IntPoint(), size());

    // Set our clip rect to be our contents.
    IntRect clipRect = contentsToWindow(visibleContentRect());
    return clipRect;
}

bool FrameView::isActive() const
{
    Page* page = frame().page();
    return page && page->focusController().isActive();
}

void FrameView::setVisibleContentScaleFactor(float visibleContentScaleFactor)
{
    if (m_visibleContentScaleFactor == visibleContentScaleFactor)
        return;
    m_visibleContentScaleFactor = visibleContentScaleFactor;
}

void FrameView::setInputEventsTransformForEmulation(const IntSize& offset, float contentScaleFactor)
{
    m_inputEventsOffsetForEmulation = offset;
    m_inputEventsScaleFactorForEmulation = contentScaleFactor;
}

IntSize FrameView::inputEventsOffsetForEmulation() const
{
    return m_inputEventsOffsetForEmulation;
}

float FrameView::inputEventsScaleFactor() const
{
    float pageScale = visibleContentScaleFactor();
    return pageScale * m_inputEventsScaleFactorForEmulation;
}

void FrameView::paint(GraphicsContext* context, const IntRect& rect)
{
#ifndef NDEBUG
    bool fillWithRed;
    if (isTransparent())
        fillWithRed = false; // Transparent, don't fill with red.
    else
        fillWithRed = true;

    if (fillWithRed)
        context->fillRect(rect, Color(0xFF, 0, 0));
#endif

    RenderView* renderView = this->renderView();
    if (!renderView) {
        WTF_LOG_ERROR("called FrameView::paint with nil renderer");
        return;
    }

    RELEASE_ASSERT(!needsLayout());
    ASSERT(m_frame->document()->lifecycle().state() >= DocumentLifecycle::StyleAndLayoutClean);

    bool isTopLevelPainter = !s_inPaintContents;
    s_inPaintContents = true;

    FontCachePurgePreventer fontCachePurgePreventer;

    ASSERT(!m_isPainting);
    m_isPainting = true;

#if ENABLE(ASSERT)
    renderView->assertSubtreeIsLaidOut();
    RenderObject::SetLayoutNeededForbiddenScope forbidSetNeedsLayout(*renderView);
#endif

    LayerPaintingInfo paintingInfo(renderView->layer(),
        pixelSnappedIntRect(renderView->viewRect()), LayoutSize());
    renderView->paintLayer(context, paintingInfo);

    m_isPainting = false;
    m_lastPaintTime = currentTime();

    if (isTopLevelPainter) {
        // Everything that happens after paintContents completions is considered
        // to be part of the next frame.
        s_currentFrameTimeStamp = currentTime();
        s_inPaintContents = false;
    }
}

bool FrameView::isPainting() const
{
    return m_isPainting;
}

void FrameView::updateLayoutAndStyleForPainting()
{
    // Updating layout can run script, which can tear down the FrameView.
    RefPtr<FrameView> protector(this);

    updateLayoutAndStyleIfNeededRecursive();

    // TODO(ojan): Get rid of this and just have the LayoutClean state.
    lifecycle().advanceTo(DocumentLifecycle::StyleAndLayoutClean);

    DocumentAnimations::startPendingAnimations(*m_frame->document());
}

void FrameView::updateLayoutAndStyleIfNeededRecursive()
{
    // We have to crawl our entire tree looking for any FrameViews that need
    // layout and make sure they are up to date.
    // Mac actually tests for intersection with the dirty region and tries not to
    // update layout for frames that are outside the dirty region.  Not only does this seem
    // pointless (since those frames will have set a zero timer to layout anyway), but
    // it is also incorrect, since if two frames overlap, the first could be excluded from the dirty
    // region but then become included later by the second frame adding rects to the dirty region
    // when it lays out.

    m_frame->document()->updateRenderTreeIfNeeded();

    if (needsLayout())
        layout();

    // These asserts ensure that parent frames are clean, when child frames finished updating layout and style.
    ASSERT(!needsLayout());

#if ENABLE(ASSERT)
    m_frame->document()->renderView()->assertRendererLaidOut();
#endif

}

void FrameView::forceLayout(bool allowSubtree)
{
    layout(allowSubtree);
}

IntRect FrameView::convertFromRenderer(const RenderObject& renderer, const IntRect& rendererRect) const
{
    return pixelSnappedIntRect(enclosingLayoutRect(renderer.localToAbsoluteQuad(FloatRect(rendererRect)).boundingBox()));
}

IntRect FrameView::convertToRenderer(const RenderObject& renderer, const IntRect& viewRect) const
{
    IntRect rect = viewRect;
    // FIXME: we don't have a way to map an absolute rect down to a local quad, so just
    // move the rect for now.
    rect.setLocation(roundedIntPoint(renderer.absoluteToLocal(rect.location(), UseTransforms)));
    return rect;
}

IntPoint FrameView::convertFromRenderer(const RenderObject& renderer, const IntPoint& rendererPoint) const
{
    return roundedIntPoint(renderer.localToAbsolute(rendererPoint, UseTransforms));
}

IntPoint FrameView::convertToRenderer(const RenderObject& renderer, const IntPoint& viewPoint) const
{
    return roundedIntPoint(renderer.absoluteToLocal(viewPoint, UseTransforms));
}

bool FrameView::isVerticalDocument() const
{
    // FIXME(sky): Remove
    return true;
}

bool FrameView::isFlippedDocument() const
{
    // FIXME(sky): Remove
    return false;
}

void FrameView::setLayoutSizeInternal(const IntSize& size)
{
    if (m_layoutSize == size)
        return;

    m_layoutSize = size;
    contentsResized();
}

void FrameView::countObjectsNeedingLayout(unsigned& needsLayoutObjects, unsigned& totalObjects, bool& isPartial)
{
    RenderObject* root = layoutRoot();
    isPartial = true;
    if (!root) {
        isPartial = false;
        root = m_frame->contentRenderer();
    }

    needsLayoutObjects = 0;
    totalObjects = 0;

    for (RenderObject* o = root; o; o = o->nextInPreOrder(root)) {
        ++totalObjects;
        if (o->needsLayout())
            ++needsLayoutObjects;
    }
}

} // namespace blink
