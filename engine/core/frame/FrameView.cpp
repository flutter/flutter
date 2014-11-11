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

#include "config.h"
#include "core/frame/FrameView.h"

#include "core/css/FontFaceSet.h"
#include "core/css/resolver/StyleResolver.h"
#include "core/dom/DocumentMarkerController.h"
#include "core/editing/FrameSelection.h"
#include "core/fetch/ResourceFetcher.h"
#include "core/fetch/ResourceLoadPriorityOptimizer.h"
#include "core/frame/FrameHost.h"
#include "core/frame/LocalFrame.h"
#include "core/frame/Settings.h"
#include "core/html/parser/TextResourceDecoder.h"
#include "core/inspector/InspectorTraceEvents.h"
#include "core/loader/FrameLoaderClient.h"
#include "core/page/Chrome.h"
#include "core/page/ChromeClient.h"
#include "core/page/EventHandler.h"
#include "core/page/FocusController.h"
#include "core/page/Page.h"
#include "core/page/scrolling/ScrollingCoordinator.h"
#include "core/rendering/RenderLayer.h"
#include "core/rendering/RenderView.h"
#include "core/rendering/compositing/CompositedLayerMapping.h"
#include "core/rendering/compositing/RenderLayerCompositor.h"
#include "core/rendering/style/RenderStyle.h"
#include "platform/RuntimeEnabledFeatures.h"
#include "platform/ScriptForbiddenScope.h"
#include "platform/TraceEvent.h"
#include "platform/fonts/FontCache.h"
#include "platform/geometry/FloatRect.h"
#include "platform/graphics/GraphicsContext.h"
#include "platform/graphics/GraphicsLayerDebugInfo.h"
#include "platform/scroll/ScrollAnimator.h"
#include "platform/scroll/Scrollbar.h"
#include "platform/text/TextStream.h"
#include "wtf/CurrentTime.h"
#include "wtf/TemporaryChange.h"

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
    , m_isTrackingPaintInvalidations(false)
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
    m_doFullPaintInvalidation = false;
    m_layoutSchedulingEnabled = true;
    m_inPerformLayout = false;
    m_canInvalidatePaintDuringPerformLayout = false;
    m_inSynchronousPostLayout = false;
    m_layoutCount = 0;
    m_nestedLayoutCount = 0;
    m_postLayoutTasksTimer.stop();
    m_firstLayout = true;
    m_firstLayoutCallbackPending = false;
    m_lastViewportSize = IntSize();
    m_isTrackingPaintInvalidations = false;
    m_trackedPaintInvalidationRects.clear();
    m_lastPaintTime = 0;
    m_paintBehavior = PaintBehaviorNormal;
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

void FrameView::invalidateRect(const IntRect& rect)
{
    // For querying RenderLayer::compositingState() when invalidating scrollbars.
    // FIXME: do all scrollbar invalidations after layout of all frames is complete. It's currently not recursively true.
    DisableCompositingQueryAsserts disabler;
    if (!parent()) {
        if (HostWindow* window = hostWindow())
            window->invalidateContentsAndRootView(rect);
        return;
    }
}

void FrameView::setFrameRect(const IntRect& newRect)
{
    IntRect oldRect = frameRect();
    if (newRect == oldRect)
        return;

    Widget::setFrameRect(newRect);

    if (RenderView* renderView = this->renderView()) {
        if (renderView->usesCompositing())
            renderView->compositor()->frameViewDidChangeSize();
    }
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

void FrameView::updateAcceleratedCompositingSettings()
{
    if (RenderView* renderView = this->renderView())
        renderView->compositor()->updateAcceleratedCompositingSettings();
}

void FrameView::recalcOverflowAfterStyleChange()
{
    RenderView* renderView = this->renderView();
    RELEASE_ASSERT(renderView);
    if (!renderView->needsOverflowRecalcAfterStyleChange())
        return;

    renderView->recalcOverflowAfterStyleChange();
}

bool FrameView::scheduleAnimation()
{
    if (HostWindow* window = hostWindow()) {
        window->scheduleAnimation();
        return true;
    }
    return false;
}

bool FrameView::isEnclosedInCompositingLayer() const
{
    return false;
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
    if (wasViewportResized())
        document->notifyResizeForViewportUnits();

    // Viewport-dependent media queries may cause us to need completely different style information.
    if (!document->styleResolver() || document->styleResolver()->mediaQueryAffectedByViewportChange()) {
        document->styleResolverChanged();
        document->mediaQueryAffectingValueChanged();
    } else {
        document->evaluateMediaQueryList();
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

    LayoutState layoutState(*rootForThisLayout);

    // FIXME (crbug.com/256657): Do not do two layouts for text autosizing.
    rootForThisLayout->layout();
    gatherDebugLayoutRects(rootForThisLayout);

    ResourceLoadPriorityOptimizer::resourceLoadPriorityOptimizer()->updateAllImageResourcePriorities();

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
    ASSERT(m_frame->page());

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

    TRACE_EVENT_BEGIN1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline"), "Layout", "beginData", InspectorLayoutEvent::beginData(this));
    TRACE_EVENT_INSTANT1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline.stack"), "CallStack", TRACE_EVENT_SCOPE_PROCESS, "stack", InspectorCallStackEvent::currentCallStack());

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
                m_doFullPaintInvalidation = true;
                m_firstLayout = false;
                m_firstLayoutCallbackPending = true;
                m_lastViewportSize = layoutSize(IncludeScrollbars);
            }

            m_size = LayoutSize(layoutSize().width(), layoutSize().height());

            // We need to set m_doFullPaintInvalidation before triggering layout as RenderObject::checkForPaintInvalidation
            // checks the boolean to disable local paint invalidations.
            m_doFullPaintInvalidation |= renderView()->shouldDoFullPaintInvalidationForNextLayout();
        }

        layer = rootForThisLayout->enclosingLayer();

        performLayout(rootForThisLayout, inSubtreeLayout);

        m_layoutSubtreeRoot = 0;
        // We need to ensure that we mark up all renderers up to the RenderView
        // for paint invalidation. This simplifies our code as we just always
        // do a full tree walk.
        if (RenderObject* container = rootForThisLayout->container())
            container->setMayNeedPaintInvalidation(true);
    } // Reset m_layoutSchedulingEnabled to its previous value.

    layer->updateLayerPositionsAfterLayout();

    if (m_doFullPaintInvalidation)
        renderView()->compositor()->fullyInvalidatePaint();
    renderView()->compositor()->didLayout();

    m_layoutCount++;

    ASSERT(!rootForThisLayout->needsLayout());

    scheduleOrPerformPostLayoutTasks();

    TRACE_EVENT_END1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline"), "Layout", "endData", InspectorLayoutEvent::endData(rootForThisLayout));

    m_nestedLayoutCount--;
    if (m_nestedLayoutCount)
        return;

#if ENABLE(ASSERT)
    // Post-layout assert that nobody was re-marked as needing layout during layout.
    document->renderView()->assertSubtreeIsLaidOut();
#endif

    // FIXME: It should be not possible to remove the FrameView from the frame/page during layout
    // however m_inPerformLayout is not set for most of this function, so none of our RELEASE_ASSERTS
    // in LocalFrame/Page will fire. One of the post-layout tasks is disconnecting the LocalFrame from
    // the page in fast/frames/crash-remove-iframe-during-object-beforeload-2.html
    // necessitating this check here.
    // ASSERT(frame()->page());
    if (frame().page())
        frame().page()->chrome().client().layoutUpdated(m_frame.get());
}

// The plan is to move to compositor-queried paint invalidation, in which case this
// method would setNeedsRedraw on the GraphicsLayers with invalidations and
// let the compositor pick which to actually draw.
// See http://crbug.com/306706
void FrameView::invalidateTreeIfNeeded()
{
    ASSERT(renderView());
    RenderView& rootForPaintInvalidation = *renderView();
    ASSERT(!rootForPaintInvalidation.needsLayout());

    TRACE_EVENT1("blink", "FrameView::invalidateTree", "root", rootForPaintInvalidation.debugName().ascii().data());

    PaintInvalidationState rootPaintInvalidationState(rootForPaintInvalidation);

    rootForPaintInvalidation.invalidateTreeIfNeeded(rootPaintInvalidationState);

    m_doFullPaintInvalidation = false;
#ifndef NDEBUG
    renderView()->assertSubtreeClearedPaintInvalidationState();
#endif

    if (m_frame->selection().isCaretBoundsDirty())
        m_frame->selection().invalidateCaretRect();
}

DocumentLifecycle& FrameView::lifecycle() const
{
    return m_frame->document()->lifecycle();
}

void FrameView::gatherDebugLayoutRects(RenderObject* layoutRoot)
{
    bool isTracing;
    TRACE_EVENT_CATEGORY_GROUP_ENABLED(TRACE_DISABLED_BY_DEFAULT("blink.debug.layout"), &isTracing);
    if (!isTracing)
        return;
    if (!layoutRoot->enclosingLayer()->hasCompositedLayerMapping())
        return;
    // For access to compositedLayerMapping().
    DisableCompositingQueryAsserts disabler;
    GraphicsLayer* graphicsLayer = layoutRoot->enclosingLayer()->compositedLayerMapping()->mainGraphicsLayer();
    if (!graphicsLayer)
        return;

    GraphicsLayerDebugInfo& debugInfo = graphicsLayer->debugInfo();

    debugInfo.currentLayoutRects().clear();
    for (RenderObject* renderer = layoutRoot; renderer; renderer = renderer->nextInPreOrder()) {
        if (renderer->layoutDidGetCalled()) {
            FloatQuad quad = renderer->localToAbsoluteQuad(FloatQuad(renderer->previousPaintInvalidationRect()));
            LayoutRect rect = quad.enclosingBoundingBox();
            debugInfo.currentLayoutRects().append(rect);
            renderer->setLayoutDidGetCalled(false);
        }
    }
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

bool FrameView::contentsInCompositedLayer() const
{
    RenderView* renderView = this->renderView();
    if (renderView && renderView->compositingState() == PaintsIntoOwnBacking) {
        GraphicsLayer* layer = renderView->layer()->compositedLayerMapping()->mainGraphicsLayer();
        if (layer && layer->drawsContent())
            return true;
    }

    return false;
}

bool FrameView::shouldSetCursor() const
{
    Page* page = frame().page();
    return page && page->visibilityState() != PageVisibilityStateHidden && page->focusController().isActive() && page->settings().deviceSupportsMouse();
}

// FIXME(sky): remove
IntSize FrameView::layoutSize(IncludeScrollbarsInRect) const
{
    return m_layoutSize;
}

void FrameView::setLayoutSize(const IntSize& size)
{
    ASSERT(!layoutSizeFixedToFrameSize());

    setLayoutSizeInternal(size);
}

void FrameView::updateCompositedSelectionBoundsIfNeeded()
{
    if (!RuntimeEnabledFeatures::compositedSelectionUpdatesEnabled())
        return;

    Page* page = frame().page();
    ASSERT(page);

    LocalFrame* frame = page->focusController().focusedOrMainFrame();
    if (!frame || !frame->selection().isCaretOrRange()) {
        page->chrome().client().clearCompositedSelectionBounds();
        return;
    }

    // TODO(jdduke): Compute and route selection bounds through ChromeClient.
}

HostWindow* FrameView::hostWindow() const
{
    Page* page = frame().page();
    if (!page)
        return 0;
    return &page->chrome();
}

void FrameView::contentRectangleForPaintInvalidation(const IntRect& r)
{
    ASSERT(paintInvalidationIsAllowed());

    if (m_isTrackingPaintInvalidations) {
        m_trackedPaintInvalidationRects.append(r);
        // FIXME: http://crbug.com/368518. Eventually, invalidateContentRectangleForPaint
        // is going away entirely once all layout tests are FCM. In the short
        // term, no code should be tracking non-composited FrameView paint invalidations.
        RELEASE_ASSERT_NOT_REACHED();
    }

    IntRect paintRect = r;
    if (clipsPaintInvalidations() && !paintsEntireContents())
        paintRect.intersect(visibleContentRect());
    if (paintRect.isEmpty())
        return;

    if (HostWindow* window = hostWindow())
        window->invalidateContentsAndRootView(contentsToWindow(paintRect));
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
    if (!m_frame->document()->shouldScheduleLayout())
        return;
    TRACE_EVENT_INSTANT1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline"), "InvalidateLayout", TRACE_EVENT_SCOPE_PROCESS, "frame", m_frame.get());
    TRACE_EVENT_INSTANT1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline.stack"), "CallStack", TRACE_EVENT_SCOPE_PROCESS, "stack", InspectorCallStackEvent::currentCallStack());

    if (m_hasPendingLayout)
        return;
    m_hasPendingLayout = true;

    page()->animator().scheduleVisualUpdate();
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

    // FIXME: Should this call shouldScheduleLayout instead?
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

        page()->animator().scheduleVisualUpdate();
        lifecycle().ensureStateAtMost(DocumentLifecycle::StyleClean);
    }
    TRACE_EVENT_INSTANT1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline"), "InvalidateLayout", TRACE_EVENT_SCOPE_PROCESS, "frame", m_frame.get());
    TRACE_EVENT_INSTANT1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline.stack"), "CallStack", TRACE_EVENT_SCOPE_PROCESS, "stack", InspectorCallStackEvent::currentCallStack());
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
    // This can return true in cases where the document does not have a body yet.
    // Document::shouldScheduleLayout takes care of preventing us from scheduling
    // layout in that case.

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
    DisableCompositingQueryAsserts disabler;
    if (renderView() && renderView()->layer()->hasCompositedLayerMapping())
        renderView()->layer()->compositedLayerMapping()->updateContentsOpaque();
}

bool FrameView::hasOpaqueBackground() const
{
    return !m_isTransparent && !m_baseBackgroundColor.hasAlpha();
}

Color FrameView::baseBackgroundColor() const
{
    return m_baseBackgroundColor;
}

void FrameView::setBaseBackgroundColor(const Color& backgroundColor)
{
    m_baseBackgroundColor = backgroundColor;

    if (renderView() && renderView()->layer()->hasCompositedLayerMapping()) {
        CompositedLayerMapping* compositedLayerMapping = renderView()->layer()->compositedLayerMapping();
        compositedLayerMapping->updateContentsOpaque();
        if (compositedLayerMapping->mainGraphicsLayer())
            compositedLayerMapping->mainGraphicsLayer()->setNeedsDisplay();
    }
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

    {
        // Hits in compositing/overflow/do-not-repaint-if-scrolling-composited-layers.html
        DisableCompositingQueryAsserts disabler;
        m_frame->selection().updateAppearance();
    }

    ASSERT(m_frame->document());
    if (m_nestedLayoutCount <= 1) {
        if (m_firstLayoutCallbackPending)
            m_firstLayoutCallbackPending = false;
    }

    FontFaceSet::didLayout(*m_frame->document());

    sendResizeEventIfNeeded();
}

bool FrameView::wasViewportResized()
{
    return layoutSize(IncludeScrollbars) != m_lastViewportSize;
}

void FrameView::sendResizeEventIfNeeded()
{
    if (!wasViewportResized())
        return;

    m_lastViewportSize = layoutSize(IncludeScrollbars);
    m_frame->document()->enqueueResizeEvent();
}

void FrameView::postLayoutTimerFired(Timer<FrameView>*)
{
    performPostLayoutTasks();
}

IntRect FrameView::windowClipRect(IncludeScrollbarsInRect scrollbarInclusion) const
{
    ASSERT(m_frame->view() == this);

    if (paintsEntireContents())
        return IntRect(IntPoint(), size());

    // Set our clip rect to be our contents.
    IntRect clipRect = contentsToWindow(visibleContentRect(scrollbarInclusion));
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

Color FrameView::documentBackgroundColor() const
{
    // <https://bugs.webkit.org/show_bug.cgi?id=59540> We blend the background color of
    // the document and the body against the base background color of the frame view.
    // Background images are unfortunately impractical to include.

    Color result = baseBackgroundColor();
    if (!frame().document())
        return result;

    Element* htmlElement = frame().document()->documentElement();

    // We take the aggregate of the base background color
    // the <html> background color, and the <body>
    // background color to find the document color. The
    // addition of the base background color is not
    // technically part of the document background, but it
    // otherwise poses problems when the aggregate is not
    // fully opaque.
    if (htmlElement && htmlElement->renderer())
        result = result.blend(htmlElement->renderer()->style()->colorIncludingFallback(CSSPropertyBackgroundColor));

    return result;
}

void FrameView::paintContents(GraphicsContext* p, const IntRect& rect)
{
    Document* document = m_frame->document();

#ifndef NDEBUG
    bool fillWithRed;
    if (isTransparent())
        fillWithRed = false; // Transparent, don't fill with red.
    else if (m_paintBehavior & PaintBehaviorSelectionOnly)
        fillWithRed = false; // Selections are transparent, don't fill with red.
    else if (m_nodeToDraw)
        fillWithRed = false; // Element images are transparent, don't fill with red.
    else
        fillWithRed = true;

    if (fillWithRed)
        p->fillRect(rect, Color(0xFF, 0, 0));
#endif

    RenderView* renderView = this->renderView();
    if (!renderView) {
        WTF_LOG_ERROR("called FrameView::paint with nil renderer");
        return;
    }

    RELEASE_ASSERT(!needsLayout());
    ASSERT(document->lifecycle().state() >= DocumentLifecycle::CompositingClean);

    TRACE_EVENT1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline"), "Paint", "data", InspectorPaintEvent::data(renderView, rect, 0));
    TRACE_EVENT_INSTANT1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline.stack"), "CallStack", TRACE_EVENT_SCOPE_PROCESS, "stack", InspectorCallStackEvent::currentCallStack());

    bool isTopLevelPainter = !s_inPaintContents;
    s_inPaintContents = true;

    FontCachePurgePreventer fontCachePurgePreventer;

    PaintBehavior oldPaintBehavior = m_paintBehavior; // FIXME(sky): is this needed?

    if (m_paintBehavior == PaintBehaviorNormal)
        document->markers().invalidateRenderedRectsForMarkersInRect(rect);

    ASSERT(!m_isPainting);
    m_isPainting = true;

    // m_nodeToDraw is used to draw only one element (and its descendants)
    RenderObject* renderer = m_nodeToDraw ? m_nodeToDraw->renderer() : 0;
    RenderLayer* rootLayer = renderView->layer();

#if ENABLE(ASSERT)
    renderView->assertSubtreeIsLaidOut();
    RenderObject::SetLayoutNeededForbiddenScope forbidSetNeedsLayout(*rootLayer->renderer());
#endif

    rootLayer->paint(p, rect, m_paintBehavior, renderer);

    if (rootLayer->containsDirtyOverlayScrollbars())
        rootLayer->paintOverlayScrollbars(p, rect, m_paintBehavior, renderer);

    m_isPainting = false;

    m_paintBehavior = oldPaintBehavior;
    m_lastPaintTime = currentTime();

    if (isTopLevelPainter) {
        // Everything that happens after paintContents completions is considered
        // to be part of the next frame.
        s_currentFrameTimeStamp = currentTime();
        s_inPaintContents = false;
    }
}

void FrameView::setPaintBehavior(PaintBehavior behavior)
{
    m_paintBehavior = behavior;
}

PaintBehavior FrameView::paintBehavior() const
{
    return m_paintBehavior;
}

bool FrameView::isPainting() const
{
    return m_isPainting;
}

void FrameView::setNodeToDraw(Node* node)
{
    m_nodeToDraw = node;
}

void FrameView::updateLayoutAndStyleForPainting()
{
    // Updating layout can run script, which can tear down the FrameView.
    RefPtr<FrameView> protector(this);

    updateLayoutAndStyleIfNeededRecursive();

    if (RenderView* view = renderView()) {
        TRACE_EVENT_INSTANT1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline"), "UpdateLayerTree", TRACE_EVENT_SCOPE_PROCESS, "frame", m_frame.get());
        view->compositor()->updateIfNeededRecursive();

        updateCompositedSelectionBoundsIfNeeded();

        invalidateTreeIfNeededRecursive();
    }

    ASSERT(lifecycle().state() == DocumentLifecycle::PaintInvalidationClean);
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

void FrameView::invalidateTreeIfNeededRecursive()
{
    // FIXME: We should be more aggressive at cutting tree traversals.
    lifecycle().advanceTo(DocumentLifecycle::InPaintInvalidation);
    invalidateTreeIfNeeded();
    lifecycle().advanceTo(DocumentLifecycle::PaintInvalidationClean);
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

void FrameView::setTracksPaintInvalidations(bool trackPaintInvalidations)
{
    if (trackPaintInvalidations == m_isTrackingPaintInvalidations)
        return;

    // FIXME(sky): simplify
    if (RenderView* renderView = m_frame->contentRenderer())
        renderView->compositor()->setTracksPaintInvalidations(trackPaintInvalidations);

    TRACE_EVENT_INSTANT1(TRACE_DISABLED_BY_DEFAULT("blink.invalidation"),
        "FrameView::setTracksPaintInvalidations", TRACE_EVENT_SCOPE_PROCESS, "enabled", trackPaintInvalidations);

    resetTrackedPaintInvalidations();
    m_isTrackingPaintInvalidations = trackPaintInvalidations;
}

void FrameView::resetTrackedPaintInvalidations()
{
    m_trackedPaintInvalidationRects.clear();
    if (RenderView* renderView = this->renderView())
        renderView->compositor()->resetTrackedPaintInvalidationRects();
}

String FrameView::trackedPaintInvalidationRectsAsText() const
{
    TextStream ts;
    if (!m_trackedPaintInvalidationRects.isEmpty()) {
        ts << "(repaint rects\n";
        for (size_t i = 0; i < m_trackedPaintInvalidationRects.size(); ++i)
            ts << "  (rect " << m_trackedPaintInvalidationRects[i].x() << " " << m_trackedPaintInvalidationRects[i].y() << " " << m_trackedPaintInvalidationRects[i].width() << " " << m_trackedPaintInvalidationRects[i].height() << ")\n";
        ts << ")\n";
    }
    return ts.release();
}

void FrameView::addScrollableArea(ScrollableArea* scrollableArea)
{
    ASSERT(scrollableArea);
    if (!m_scrollableAreas)
        m_scrollableAreas = adoptPtr(new ScrollableAreaSet);
    m_scrollableAreas->add(scrollableArea);
}

void FrameView::removeScrollableArea(ScrollableArea* scrollableArea)
{
    if (!m_scrollableAreas)
        return;
    m_scrollableAreas->remove(scrollableArea);
}

bool FrameView::wheelEvent(const PlatformWheelEvent& wheelEvent)
{
    // FIXME(sky): Remove
    return false;
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

void FrameView::setCursor(const Cursor& cursor)
{
    Page* page = frame().page();
    if (!page || !page->settings().deviceSupportsMouse())
        return;
    page->chrome().setCursor(cursor);
}

void FrameView::setLayoutSizeInternal(const IntSize& size)
{
    if (m_layoutSize == size)
        return;

    m_layoutSize = size;
    contentsResized();
}

} // namespace blink
