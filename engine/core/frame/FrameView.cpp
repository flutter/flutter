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
#include "core/events/OverflowEvent.h"
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
#include "core/rendering/RenderPart.h"
#include "core/rendering/RenderView.h"
#include "core/rendering/RenderWidget.h"
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

static const double resourcePriorityUpdateDelayAfterScroll = 0.250;

FrameView::FrameView(LocalFrame* frame)
    : m_frame(frame)
    , m_canHaveScrollbars(true)
    , m_slowRepaintObjectCount(0)
    , m_hasPendingLayout(false)
    , m_layoutSubtreeRoot(0)
    , m_inSynchronousPostLayout(false)
    , m_postLayoutTasksTimer(this, &FrameView::postLayoutTimerFired)
    , m_isTransparent(false)
    , m_baseBackgroundColor(Color::white)
    , m_mediaType("screen")
    , m_overflowStatusDirty(true)
    , m_viewportRenderer(0)
    , m_wasScrolledByUser(false)
    , m_inProgrammaticScroll(false)
    , m_isTrackingPaintInvalidations(false)
    , m_hasSoftwareFilters(false)
    , m_visibleContentScaleFactor(1)
    , m_inputEventsScaleFactorForEmulation(1)
    , m_layoutSizeFixedToFrameSize(true)
    , m_didScrollTimer(this, &FrameView::didScrollTimerFired)
    , m_needsUpdateWidgetPositions(false)
{
    ASSERT(m_frame);
    init();

    ScrollableArea::setVerticalScrollElasticity(ScrollElasticityAllowed);
    ScrollableArea::setHorizontalScrollElasticity(ScrollElasticityAllowed);
}

PassRefPtr<FrameView> FrameView::create(LocalFrame* frame)
{
    RefPtr<FrameView> view = adoptRef(new FrameView(frame));
    view->show();
    return view.release();
}

PassRefPtr<FrameView> FrameView::create(LocalFrame* frame, const IntSize& initialSize)
{
    RefPtr<FrameView> view = adoptRef(new FrameView(frame));
    view->Widget::setFrameRect(IntRect(view->location(), initialSize));
    view->setLayoutSizeInternal(initialSize);

    view->show();
    return view.release();
}

FrameView::~FrameView()
{
    if (m_postLayoutTasksTimer.isActive())
        m_postLayoutTasksTimer.stop();

    if (m_didScrollTimer.isActive())
        m_didScrollTimer.stop();

    resetScrollbars();

    // Custom scrollbars should already be destroyed at this point
    ASSERT(!horizontalScrollbar() || !horizontalScrollbar()->isCustomScrollbar());
    ASSERT(!verticalScrollbar() || !verticalScrollbar()->isCustomScrollbar());

    setHasHorizontalScrollbar(false); // Remove native scrollbars now before we lose the connection to the HostWindow.
    setHasVerticalScrollbar(false);

    ASSERT(m_frame);
    ASSERT(m_frame->view() != this || !m_frame->contentRenderer());
    // FIXME: Do we need to do something here for OOPI?
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
    m_wasScrolledByUser = false;
    m_lastViewportSize = IntSize();
    m_lastZoomFactor = 1.0f;
    m_isTrackingPaintInvalidations = false;
    m_trackedPaintInvalidationRects.clear();
    m_lastPaintTime = 0;
    m_paintBehavior = PaintBehaviorNormal;
    m_isPainting = false;
    m_viewportConstrainedObjects.clear();
}

void FrameView::resetScrollbars()
{
    // Reset the document's scrollbars back to our defaults before we yield the floor.
    m_firstLayout = true;
    setScrollbarsSuppressed(true);
    if (m_canHaveScrollbars)
        setScrollbarModes(ScrollbarAuto, ScrollbarAuto);
    else
        setScrollbarModes(ScrollbarAlwaysOff, ScrollbarAlwaysOff);
    setScrollbarsSuppressed(false);
}

void FrameView::init()
{
    reset();

    m_size = LayoutSize();
}

void FrameView::prepareForDetach()
{
    RELEASE_ASSERT(!isInPerformLayout());

    if (ScrollAnimator* scrollAnimator = existingScrollAnimator())
        scrollAnimator->cancelAnimations();
    cancelProgrammaticScrollAnimation();

    if (m_frame->page()) {
        if (ScrollingCoordinator* scrollingCoordinator = m_frame->page()->scrollingCoordinator())
            scrollingCoordinator->willDestroyScrollableArea(this);
    }
}

void FrameView::recalculateScrollbarOverlayStyle()
{
    ScrollbarOverlayStyle oldOverlayStyle = scrollbarOverlayStyle();
    ScrollbarOverlayStyle overlayStyle = ScrollbarOverlayStyleDefault;

    Color backgroundColor = documentBackgroundColor();
    // Reduce the background color from RGB to a lightness value
    // and determine which scrollbar style to use based on a lightness
    // heuristic.
    double hue, saturation, lightness;
    backgroundColor.getHSL(hue, saturation, lightness);
    if (lightness <= .5)
        overlayStyle = ScrollbarOverlayStyleLight;

    if (oldOverlayStyle != overlayStyle)
        setScrollbarOverlayStyle(overlayStyle);
}

void FrameView::clear()
{
    reset();
    setScrollbarsSuppressed(true);
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

    ScrollView::setFrameRect(newRect);

    if (RenderView* renderView = this->renderView()) {
        if (renderView->usesCompositing())
            renderView->compositor()->frameViewDidChangeSize();
    }

    viewportConstrainedVisibleContentSizeChanged(newRect.width() != oldRect.width(), newRect.height() != oldRect.height());

    if (oldRect.size() != newRect.size()
        && m_frame->settings()->pinchVirtualViewportEnabled())
        page()->frameHost().pinchViewport().mainFrameDidChangeSize();
}

Page* FrameView::page() const
{
    return frame().page();
}

RenderView* FrameView::renderView() const
{
    return frame().contentRenderer();
}

void FrameView::setCanHaveScrollbars(bool canHaveScrollbars)
{
    m_canHaveScrollbars = canHaveScrollbars;
    ScrollView::setCanHaveScrollbars(canHaveScrollbars);
}

void FrameView::setContentsSize(const IntSize& size)
{
    if (size == contentsSize())
        return;

    ScrollView::setContentsSize(size);
    ScrollView::contentsResized();
}

IntPoint FrameView::clampOffsetAtScale(const IntPoint& offset, float scale) const
{
    IntPoint maxScrollExtent(contentsSize().width() - scrollOrigin().x(), contentsSize().height() - scrollOrigin().y());
    FloatSize scaledSize = unscaledVisibleContentSize();
    if (scale)
        scaledSize.scale(1 / scale);

    IntPoint clampedOffset = offset;
    clampedOffset = clampedOffset.shrunkTo(maxScrollExtent - expandedIntSize(scaledSize));
    clampedOffset = clampedOffset.expandedTo(-scrollOrigin());

    return clampedOffset;
}

void FrameView::adjustViewSize()
{
    RenderView* renderView = this->renderView();
    if (!renderView)
        return;

    ASSERT(m_frame->view() == this);

    const IntRect rect = renderView->documentRect();
    const IntSize& size = rect.size();
    ScrollView::setScrollOrigin(IntPoint(-rect.x(), -rect.y()), true, size == contentsSize());

    setContentsSize(size);
}

void FrameView::applyOverflowToViewportAndSetRenderer(RenderObject* o, ScrollbarMode& hMode, ScrollbarMode& vMode)
{
    // Handle the overflow:hidden/scroll case for the body/html elements.  WinIE treats
    // overflow:hidden and overflow:scroll on <body> as applying to the document's
    // scrollbars.  The CSS2.1 draft states that HTML UAs should use the <html> or <body> element and XML/XHTML UAs should
    // use the root element.

    EOverflow overflowX = o->style()->overflowX();
    EOverflow overflowY = o->style()->overflowY();

    switch (overflowX) {
        case OHIDDEN:
            hMode = ScrollbarAlwaysOff;
            break;
        case OSCROLL:
            hMode = ScrollbarAlwaysOn;
            break;
        case OAUTO:
            hMode = ScrollbarAuto;
            break;
        default:
            // Don't set it at all.
            ;
    }

     switch (overflowY) {
        case OHIDDEN:
            vMode = ScrollbarAlwaysOff;
            break;
        case OSCROLL:
            vMode = ScrollbarAlwaysOn;
            break;
        case OAUTO:
            vMode = ScrollbarAuto;
            break;
        default:
            // Don't set it at all.
            ;
    }

    m_viewportRenderer = o;
}

void FrameView::calculateScrollbarModesForLayoutAndSetViewportRenderer(ScrollbarMode& hMode, ScrollbarMode& vMode, ScrollbarModesCalculationStrategy strategy)
{
    m_viewportRenderer = 0;

    if (m_canHaveScrollbars || strategy == RulesFromWebContentOnly) {
        hMode = ScrollbarAuto;
        vMode = ScrollbarAuto;
    } else {
        hMode = ScrollbarAlwaysOff;
        vMode = ScrollbarAlwaysOff;
    }

    if (!isSubtreeLayout()) {
        Document* document = m_frame->document();
        if (Element* viewportElement = document->viewportDefiningElement()) {
            if (RenderObject* viewportRenderer = viewportElement->renderer()) {
                if (viewportRenderer->style())
                    applyOverflowToViewportAndSetRenderer(viewportRenderer, hMode, vMode);
            }
        }
    }
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

    IntRect documentRect = renderView->documentRect();
    if (scrollOrigin() == -documentRect.location() && contentsSize() == documentRect.size())
        return;

    if (needsLayout())
        return;

    InUpdateScrollbarsScope inUpdateScrollbarsScope(this);

    bool shouldHaveHorizontalScrollbar = false;
    bool shouldHaveVerticalScrollbar = false;
    computeScrollbarExistence(shouldHaveHorizontalScrollbar, shouldHaveVerticalScrollbar, documentRect.size());

    bool hasHorizontalScrollbar = horizontalScrollbar();
    bool hasVerticalScrollbar = verticalScrollbar();
    if (hasHorizontalScrollbar != shouldHaveHorizontalScrollbar
        || hasVerticalScrollbar != shouldHaveVerticalScrollbar) {
        setNeedsLayout();
        return;
    }

    adjustViewSize();
    updateScrollbarGeometry();
}

bool FrameView::usesCompositedScrolling() const
{
    RenderView* renderView = this->renderView();
    if (!renderView)
        return false;
    if (m_frame->settings() && m_frame->settings()->preferCompositingToLCDTextEnabled())
        return renderView->compositor()->inCompositingMode();
    return false;
}

GraphicsLayer* FrameView::layerForScrolling() const
{
    RenderView* renderView = this->renderView();
    if (!renderView)
        return 0;
    return renderView->compositor()->scrollLayer();
}

GraphicsLayer* FrameView::layerForHorizontalScrollbar() const
{
    RenderView* renderView = this->renderView();
    if (!renderView)
        return 0;
    return renderView->compositor()->layerForHorizontalScrollbar();
}

GraphicsLayer* FrameView::layerForVerticalScrollbar() const
{
    RenderView* renderView = this->renderView();
    if (!renderView)
        return 0;
    return renderView->compositor()->layerForVerticalScrollbar();
}

GraphicsLayer* FrameView::layerForScrollCorner() const
{
    RenderView* renderView = this->renderView();
    if (!renderView)
        return 0;
    return renderView->compositor()->layerForScrollCorner();
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

    // Every scroll that happens during layout is programmatic.
    TemporaryChange<bool> changeInProgrammaticScroll(m_inProgrammaticScroll, true);

    m_hasPendingLayout = false;
    DocumentLifecycle::Scope lifecycleScope(lifecycle(), DocumentLifecycle::LayoutClean);

    RELEASE_ASSERT(!isPainting());

    TRACE_EVENT_BEGIN1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline"), "Layout", "beginData", InspectorLayoutEvent::beginData(this));
    TRACE_EVENT_INSTANT1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline.stack"), "CallStack", "stack", InspectorCallStackEvent::currentCallStack());

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

        ScrollbarMode hMode;
        ScrollbarMode vMode;
        calculateScrollbarModesForLayoutAndSetViewportRenderer(hMode, vMode);

        if (!inSubtreeLayout) {
            // Now set our scrollbar state for the layout.
            ScrollbarMode currentHMode = horizontalScrollbarMode();
            ScrollbarMode currentVMode = verticalScrollbarMode();

            if (m_firstLayout) {
                setScrollbarsSuppressed(true);

                m_doFullPaintInvalidation = true;
                m_firstLayout = false;
                m_firstLayoutCallbackPending = true;
                m_lastViewportSize = layoutSize(IncludeScrollbars);
                m_lastZoomFactor = rootForThisLayout->style()->zoom();

                // Set the initial vMode to AlwaysOn if we're auto.
                if (vMode == ScrollbarAuto)
                    setVerticalScrollbarMode(ScrollbarAlwaysOn); // This causes a vertical scrollbar to appear.
                // Set the initial hMode to AlwaysOff if we're auto.
                if (hMode == ScrollbarAuto)
                    setHorizontalScrollbarMode(ScrollbarAlwaysOff); // This causes a horizontal scrollbar to disappear.

                setScrollbarModes(hMode, vMode);
                setScrollbarsSuppressed(false, true);
            } else if (hMode != currentHMode || vMode != currentVMode) {
                setScrollbarModes(hMode, vMode);
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

    if (!inSubtreeLayout)
        adjustViewSize();

    layer->updateLayerPositionsAfterLayout();

    if (m_doFullPaintInvalidation)
        renderView()->compositor()->fullyInvalidatePaint();
    renderView()->compositor()->didLayout();

    m_layoutCount++;

    ASSERT(!rootForThisLayout->needsLayout());

    if (document->hasListenerType(Document::OVERFLOWCHANGED_LISTENER))
        updateOverflowStatus(layoutSize().width() < contentsWidth(), layoutSize().height() < contentsHeight());

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

    TRACE_EVENT1("blink", "FrameView::invalidateTree", "root", rootForPaintInvalidation.debugName().ascii());

    PaintInvalidationState rootPaintInvalidationState(rootForPaintInvalidation);

    rootForPaintInvalidation.invalidateTreeIfNeeded(rootPaintInvalidationState);

    // Invalidate the paint of the frameviews scrollbars if needed
    if (hasVerticalBarDamage())
        invalidateRect(verticalBarDamage());
    if (hasHorizontalBarDamage())
        invalidateRect(horizontalBarDamage());
    resetScrollbarDamage();

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

void FrameView::addWidget(RenderWidget* object)
{
    m_widgets.add(object);
}

void FrameView::removeWidget(RenderWidget* object)
{
    m_widgets.remove(object);
}

void FrameView::updateWidgetPositions()
{
    WillBeHeapVector<RefPtrWillBeMember<RenderWidget> > widgets;
    copyToVector(m_widgets, widgets);

    // Script or plugins could detach the frame so abort processing if that happens.

    for (size_t i = 0; i < widgets.size() && renderView(); ++i)
        widgets[i]->updateWidgetPosition();

    for (size_t i = 0; i < widgets.size() && renderView(); ++i)
        widgets[i]->widgetPositionsUpdated();
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

void FrameView::addSlowRepaintObject()
{
    if (!m_slowRepaintObjectCount++) {
        if (Page* page = m_frame->page()) {
            if (ScrollingCoordinator* scrollingCoordinator = page->scrollingCoordinator())
                scrollingCoordinator->frameViewHasSlowRepaintObjectsDidChange(this);
        }
    }
}

void FrameView::removeSlowRepaintObject()
{
    ASSERT(m_slowRepaintObjectCount > 0);
    m_slowRepaintObjectCount--;
    if (!m_slowRepaintObjectCount) {
        if (Page* page = m_frame->page()) {
            if (ScrollingCoordinator* scrollingCoordinator = page->scrollingCoordinator())
                scrollingCoordinator->frameViewHasSlowRepaintObjectsDidChange(this);
        }
    }
}

void FrameView::addViewportConstrainedObject(RenderObject* object)
{
    if (!m_viewportConstrainedObjects)
        m_viewportConstrainedObjects = adoptPtr(new ViewportConstrainedObjectSet);

    if (!m_viewportConstrainedObjects->contains(object)) {
        m_viewportConstrainedObjects->add(object);

        if (Page* page = m_frame->page()) {
            if (ScrollingCoordinator* scrollingCoordinator = page->scrollingCoordinator())
                scrollingCoordinator->frameViewFixedObjectsDidChange(this);
        }
    }
}

void FrameView::removeViewportConstrainedObject(RenderObject* object)
{
    if (m_viewportConstrainedObjects && m_viewportConstrainedObjects->contains(object)) {
        m_viewportConstrainedObjects->remove(object);

        if (Page* page = m_frame->page()) {
            if (ScrollingCoordinator* scrollingCoordinator = page->scrollingCoordinator())
                scrollingCoordinator->frameViewFixedObjectsDidChange(this);
        }
    }
}

LayoutRect FrameView::viewportConstrainedVisibleContentRect() const
{
    LayoutRect viewportRect = visibleContentRect();
    // Ignore overhang. No-op when not using rubber banding.
    viewportRect.setLocation(clampScrollPosition(scrollPosition()));
    return viewportRect;
}

void FrameView::viewportConstrainedVisibleContentSizeChanged(bool widthChanged, bool heightChanged)
{
    if (!hasViewportConstrainedObjects())
        return;

    // If viewport is not enabled, frameRect change will cause layout size change and then layout.
    // Otherwise, viewport constrained objects need their layout flags set separately to ensure
    // they are positioned correctly. In the virtual-viewport pinch mode frame rect changes wont
    // necessarily cause a layout size change so only take this early-out if we're in old-style
    // pinch.
    if (m_frame->settings()
        && !m_frame->settings()->viewportEnabled()
        && !m_frame->settings()->pinchVirtualViewportEnabled())
        return;

    ViewportConstrainedObjectSet::const_iterator end = m_viewportConstrainedObjects->end();
    for (ViewportConstrainedObjectSet::const_iterator it = m_viewportConstrainedObjects->begin(); it != end; ++it) {
        RenderObject* renderer = *it;
        RenderStyle* style = renderer->style();
        if (widthChanged) {
            if (style->width().isFixed() && (style->left().isAuto() || style->right().isAuto()))
                renderer->setNeedsPositionedMovementLayout();
            else
                renderer->setNeedsLayoutAndFullPaintInvalidation();
        }
        if (heightChanged) {
            if (style->height().isFixed() && (style->top().isAuto() || style->bottom().isAuto()))
                renderer->setNeedsPositionedMovementLayout();
            else
                renderer->setNeedsLayoutAndFullPaintInvalidation();
        }
    }
}

IntSize FrameView::scrollOffsetForFixedPosition() const
{
    return toIntSize(clampScrollPosition(scrollPosition()));
}

IntPoint FrameView::lastKnownMousePosition() const
{
    return m_frame->eventHandler().lastKnownMousePosition();
}

bool FrameView::shouldSetCursor() const
{
    Page* page = frame().page();
    return page && page->visibilityState() != PageVisibilityStateHidden && page->focusController().isActive() && page->settings().deviceSupportsMouse();
}

void FrameView::scrollContentsIfNeededRecursive()
{
    scrollContentsIfNeeded();
}

void FrameView::scrollContentsIfNeeded()
{
    bool didScroll = !pendingScrollDelta().isZero();
    ScrollView::scrollContentsIfNeeded();
    if (didScroll)
        updateFixedElementPaintInvalidationRectsAfterScroll();
}

bool FrameView::scrollContentsFastPath(const IntSize& scrollDelta)
{
    if (!contentsInCompositedLayer() || hasSlowRepaintObjects())
        return false;

    if (!m_viewportConstrainedObjects || m_viewportConstrainedObjects->isEmpty())
        return true;

    Region regionToUpdate;
    ViewportConstrainedObjectSet::const_iterator end = m_viewportConstrainedObjects->end();
    for (ViewportConstrainedObjectSet::const_iterator it = m_viewportConstrainedObjects->begin(); it != end; ++it) {
        RenderObject* renderer = *it;
        ASSERT(renderer->style()->hasViewportConstrainedPosition());
        ASSERT(renderer->hasLayer());
        RenderLayer* layer = toRenderBoxModelObject(renderer)->layer();

        CompositingState state = layer->compositingState();
        if (state == PaintsIntoOwnBacking || state == PaintsIntoGroupedBacking)
            continue;

        // If the fixed layer has a blur/drop-shadow filter applied on at least one of its parents, we cannot
        // scroll using the fast path, otherwise the outsets of the filter will be moved around the page.
        if (layer->hasAncestorWithFilterOutsets())
            return false;

        IntRect updateRect = pixelSnappedIntRect(layer->paintInvalidator().paintInvalidationRectIncludingNonCompositingDescendants());

        const RenderLayerModelObject* repaintContainer = layer->renderer()->containerForPaintInvalidation();
        if (repaintContainer && !repaintContainer->isRenderView()) {
            // Invalidate the old and new locations of fixed position elements that are not drawn into the RenderView.
            updateRect.moveBy(scrollPosition());
            IntRect previousRect = updateRect;
            previousRect.move(scrollDelta);
            // FIXME: Rather than uniting the rects, we should just issue both invalidations.
            updateRect.unite(previousRect);
            layer->renderer()->invalidatePaintUsingContainer(repaintContainer, updateRect, InvalidationScroll);
        } else {
            // Coalesce the paint invalidations that will be issued to the renderView.
            updateRect = contentsToRootView(updateRect);
            if (!updateRect.isEmpty())
                regionToUpdate.unite(updateRect);
        }
    }

    // Invalidate the old and new locations of fixed position elements that are drawn into the RenderView.
    Vector<IntRect> subRectsToUpdate = regionToUpdate.rects();
    size_t viewportConstrainedObjectsCount = subRectsToUpdate.size();
    for (size_t i = 0; i < viewportConstrainedObjectsCount; ++i) {
        IntRect updateRect = subRectsToUpdate[i];
        IntRect scrolledRect = updateRect;
        scrolledRect.move(-scrollDelta);
        updateRect.unite(scrolledRect);
        // FIXME: We should be able to issue these invalidations separately and before we actually scroll.
        renderView()->layer()->paintInvalidator().setBackingNeedsPaintInvalidationInRect(rootViewToContents(updateRect));
    }

    return true;
}

void FrameView::scrollContentsSlowPath(const IntRect& updateRect)
{
    if (contentsInCompositedLayer()) {
        IntRect updateRect = visibleContentRect();
        ASSERT(renderView());
        renderView()->layer()->paintInvalidator().setBackingNeedsPaintInvalidationInRect(updateRect);
    }
    ScrollView::scrollContentsSlowPath(updateRect);
}

void FrameView::restoreScrollbar()
{
    setScrollbarsSuppressed(false);
}

void FrameView::scrollElementToRect(Element* element, const IntRect& rect)
{
    // FIXME(http://crbug.com/371896) - This method shouldn't be manually doing
    // coordinate transformations to the PinchViewport.
    IntRect targetRect(rect);

    m_frame->document()->updateLayoutIgnorePendingStylesheets();

    bool pinchVirtualViewportEnabled = m_frame->settings()->pinchVirtualViewportEnabled();

    if (pinchVirtualViewportEnabled) {
        PinchViewport& pinchViewport = m_frame->page()->frameHost().pinchViewport();

        IntSize pinchViewportSize = expandedIntSize(pinchViewport.visibleRect().size());
        targetRect.moveBy(ceiledIntPoint(pinchViewport.visibleRect().location()));
        targetRect.setSize(pinchViewportSize.shrunkTo(targetRect.size()));
    }

    LayoutRect bounds = element->boundingBox();
    int centeringOffsetX = (targetRect.width() - bounds.width()) / 2;
    int centeringOffsetY = (targetRect.height() - bounds.height()) / 2;

    IntPoint targetOffset(
        bounds.x() - centeringOffsetX - targetRect.x(),
        bounds.y() - centeringOffsetY - targetRect.y());

    setScrollPosition(targetOffset);

    if (pinchVirtualViewportEnabled) {
        IntPoint remainder = IntPoint(targetOffset - scrollPosition());
        m_frame->page()->frameHost().pinchViewport().move(remainder);
    }
}

void FrameView::setScrollPosition(const IntPoint& scrollPoint, ScrollBehavior scrollBehavior)
{
    cancelProgrammaticScrollAnimation();
    TemporaryChange<bool> changeInProgrammaticScroll(m_inProgrammaticScroll, true);

    IntPoint newScrollPosition = adjustScrollPositionWithinRange(scrollPoint);

    if (newScrollPosition == scrollPosition())
        return;

    if (scrollBehavior == ScrollBehaviorAuto) {
        RenderObject* renderer = m_frame->document()->documentElement() ? m_frame->document()->documentElement()->renderer() : 0;
        if (renderer)
            scrollBehavior = renderer->style()->scrollBehavior();
        else
            scrollBehavior = ScrollBehaviorInstant;
    }
    ScrollView::setScrollPosition(newScrollPosition, scrollBehavior);
}

void FrameView::setScrollPositionNonProgrammatically(const IntPoint& scrollPoint)
{
    IntPoint newScrollPosition = adjustScrollPositionWithinRange(scrollPoint);

    if (newScrollPosition == scrollPosition())
        return;

    TemporaryChange<bool> changeInProgrammaticScroll(m_inProgrammaticScroll, false);
    notifyScrollPositionChanged(newScrollPosition);
}

IntSize FrameView::layoutSize(IncludeScrollbarsInRect scrollbarInclusion) const
{
    return scrollbarInclusion == ExcludeScrollbars ? excludeScrollbars(m_layoutSize) : m_layoutSize;
}

void FrameView::setLayoutSize(const IntSize& size)
{
    ASSERT(!layoutSizeFixedToFrameSize());

    setLayoutSizeInternal(size);
}

void FrameView::scrollPositionChanged()
{
    setWasScrolledByUser(true);

    Document* document = m_frame->document();
    document->enqueueScrollEventForNode(document);

    m_frame->eventHandler().dispatchFakeMouseMoveEventSoon();

    if (RenderView* renderView = document->renderView()) {
        if (renderView->usesCompositing())
            renderView->compositor()->frameViewDidScroll();
    }

    if (m_didScrollTimer.isActive())
        m_didScrollTimer.stop();
    m_didScrollTimer.startOneShot(resourcePriorityUpdateDelayAfterScroll, FROM_HERE);
}

void FrameView::didScrollTimerFired(Timer<FrameView>*)
{
    if (m_frame->document() && m_frame->document()->renderView()) {
        ResourceLoadPriorityOptimizer::resourceLoadPriorityOptimizer()->updateAllImageResourcePriorities();
    }
}

void FrameView::updateLayersAndCompositingAfterScrollIfNeeded()
{
    // Nothing to do after scrolling if there are no fixed position elements.
    if (!hasViewportConstrainedObjects())
        return;

    RefPtr<FrameView> protect(this);

    // If there fixed position elements, scrolling may cause compositing layers to change.
    // Update widget and layer positions after scrolling, but only if we're not inside of
    // layout.
    if (!m_nestedLayoutCount) {
        updateWidgetPositions();
        if (RenderView* renderView = this->renderView())
            renderView->layer()->setNeedsCompositingInputsUpdate();
    }
}

void FrameView::updateFixedElementPaintInvalidationRectsAfterScroll()
{
    if (!hasViewportConstrainedObjects())
        return;

    // Update the paint invalidation rects for fixed elements after scrolling and invalidation to reflect
    // the new scroll position.
    ViewportConstrainedObjectSet::const_iterator end = m_viewportConstrainedObjects->end();
    for (ViewportConstrainedObjectSet::const_iterator it = m_viewportConstrainedObjects->begin(); it != end; ++it) {
        RenderObject* renderer = *it;
        // m_viewportConstrainedObjects should not contain non-viewport constrained objects.
        ASSERT(renderer->style()->hasViewportConstrainedPosition());

        // Fixed items should always have layers.
        ASSERT(renderer->hasLayer());

        RenderLayer* layer = toRenderBoxModelObject(renderer)->layer();

        // Don't need to do this for composited fixed items.
        if (layer->compositingState() == PaintsIntoOwnBacking)
            continue;

        layer->paintInvalidator().computePaintInvalidationRectsIncludingNonCompositingDescendants();
    }
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

bool FrameView::isRubberBandInProgress() const
{
    if (scrollbarsSuppressed())
        return false;

    // If the main thread updates the scroll position for this FrameView, we should return
    // ScrollAnimator::isRubberBandInProgress().
    if (ScrollAnimator* scrollAnimator = existingScrollAnimator())
        return scrollAnimator->isRubberBandInProgress();

    return false;
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
        IntRect paintInvalidationRect = r;
        paintInvalidationRect.move(-scrollOffset());
        m_trackedPaintInvalidationRects.append(paintInvalidationRect);
        // FIXME: http://crbug.com/368518. Eventually, invalidateContentRectangleForPaint
        // is going away entirely once all layout tests are FCM. In the short
        // term, no code should be tracking non-composited FrameView paint invalidations.
        RELEASE_ASSERT_NOT_REACHED();
    }

    ScrollView::contentRectangleForPaintInvalidation(r);
}

void FrameView::contentsResized()
{
    ScrollView::contentsResized();
    setNeedsLayout();
}

void FrameView::scrollbarExistenceDidChange()
{
    // We check to make sure the view is attached to a frame() as this method can
    // be triggered before the view is attached by LocalFrame::createView(...) setting
    // various values such as setScrollBarModes(...) for example.  An ASSERT is
    // triggered when a view is layout before being attached to a frame().
    if (!frame().view())
        return;

    if (renderView() && renderView()->usesCompositing())
        renderView()->compositor()->frameViewScrollbarsExistenceDidChange();
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
    TRACE_EVENT_INSTANT1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline"), "InvalidateLayout", "frame", m_frame.get());
    TRACE_EVENT_INSTANT1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline.stack"), "CallStack", "stack", InspectorCallStackEvent::currentCallStack());

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
    TRACE_EVENT_INSTANT1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline"), "InvalidateLayout", "frame", m_frame.get());
    TRACE_EVENT_INSTANT1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline.stack"), "CallStack", "stack", InspectorCallStackEvent::currentCallStack());
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
    recalculateScrollbarOverlayStyle();
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

    updateWidgetPositions();

    // Plugins could have torn down the page inside updateWidgetPositions().
    if (!renderView())
        return;

    if (Page* page = m_frame->page()) {
        if (ScrollingCoordinator* scrollingCoordinator = page->scrollingCoordinator())
            scrollingCoordinator->notifyLayoutUpdated();
    }

    sendResizeEventIfNeeded();
}

bool FrameView::wasViewportResized()
{
    ASSERT(m_frame);
    RenderView* renderView = this->renderView();
    if (!renderView)
        return false;
    return (layoutSize(IncludeScrollbars) != m_lastViewportSize || renderView->style()->zoom() != m_lastZoomFactor);
}

void FrameView::sendResizeEventIfNeeded()
{
    ASSERT(m_frame);

    RenderView* renderView = this->renderView();
    if (!renderView)
        return;

    if (!wasViewportResized())
        return;

    m_lastViewportSize = layoutSize(IncludeScrollbars);
    m_lastZoomFactor = renderView->style()->zoom();

    m_frame->document()->enqueueResizeEvent();
}

void FrameView::postLayoutTimerFired(Timer<FrameView>*)
{
    performPostLayoutTasks();
}

void FrameView::updateOverflowStatus(bool horizontalOverflow, bool verticalOverflow)
{
    if (!m_viewportRenderer)
        return;

    if (m_overflowStatusDirty) {
        m_horizontalOverflow = horizontalOverflow;
        m_verticalOverflow = verticalOverflow;
        m_overflowStatusDirty = false;
        return;
    }

    bool horizontalOverflowChanged = (m_horizontalOverflow != horizontalOverflow);
    bool verticalOverflowChanged = (m_verticalOverflow != verticalOverflow);

    if (horizontalOverflowChanged || verticalOverflowChanged) {
        m_horizontalOverflow = horizontalOverflow;
        m_verticalOverflow = verticalOverflow;

        RefPtrWillBeRawPtr<OverflowEvent> event = OverflowEvent::create(horizontalOverflowChanged, horizontalOverflow, verticalOverflowChanged, verticalOverflow);
        event->setTarget(m_viewportRenderer->node());
        m_frame->document()->enqueueAnimationFrameEvent(event.release());
    }

}

IntRect FrameView::windowClipRect(IncludeScrollbarsInRect scrollbarInclusion) const
{
    ASSERT(m_frame->view() == this);

    if (paintsEntireContents())
        return IntRect(IntPoint(), contentsSize());

    // Set our clip rect to be our contents.
    IntRect clipRect = contentsToWindow(visibleContentRect(scrollbarInclusion));
    return clipRect;
}

bool FrameView::isActive() const
{
    Page* page = frame().page();
    return page && page->focusController().isActive();
}

void FrameView::scrollTo(const IntSize& newOffset)
{
    LayoutSize offset = scrollOffset();
    ScrollView::scrollTo(newOffset);
    if (offset != scrollOffset()) {
        updateLayersAndCompositingAfterScrollIfNeeded();
        scrollPositionChanged();
    }
    frame().loaderClient()->didChangeScrollOffset();
}

void FrameView::invalidateScrollbarRect(Scrollbar* scrollbar, const IntRect& rect)
{
    // Add in our offset within the FrameView.
    IntRect dirtyRect = rect;
    dirtyRect.moveBy(scrollbar->location());

    if (isInPerformLayout())
        addScrollbarDamage(scrollbar, rect);
    else
        invalidateRect(dirtyRect);
}

void FrameView::getTickmarks(Vector<IntRect>& tickmarks) const
{
    if (!m_tickmarks.isEmpty())
        tickmarks = m_tickmarks;
    else
        tickmarks = frame().document()->markers().renderedRectsForMarkers(DocumentMarker::TextMatch);
}

void FrameView::setVisibleContentScaleFactor(float visibleContentScaleFactor)
{
    if (m_visibleContentScaleFactor == visibleContentScaleFactor)
        return;

    m_visibleContentScaleFactor = visibleContentScaleFactor;
    updateScrollbars(scrollOffset());
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
    float pageScale = m_frame->settings()->pinchVirtualViewportEnabled()
        ? m_frame->page()->frameHost().pinchViewport().scale()
        : visibleContentScaleFactor();
    return pageScale * m_inputEventsScaleFactorForEmulation;
}

bool FrameView::scrollbarsCanBeActive() const
{
    if (m_frame->view() != this)
        return false;

    return !!m_frame->document();
}

IntRect FrameView::scrollableAreaBoundingBox() const
{
    return frameRect();
}

bool FrameView::isScrollable()
{
    // Check for:
    // 1) If there an actual overflow.
    // 2) display:none or visibility:hidden set to self or inherited.
    // 3) overflow{-x,-y}: hidden;
    // 4) scrolling: no;

    // Covers #1
    IntSize contentsSize = this->contentsSize();
    IntSize visibleContentSize = visibleContentRect().size();
    if ((contentsSize.height() <= visibleContentSize.height() && contentsSize.width() <= visibleContentSize.width()))
        return false;


    // Cover #3 and #4.
    ScrollbarMode horizontalMode;
    ScrollbarMode verticalMode;
    calculateScrollbarModesForLayoutAndSetViewportRenderer(horizontalMode, verticalMode, RulesFromWebContentOnly);
    if (horizontalMode == ScrollbarAlwaysOff && verticalMode == ScrollbarAlwaysOff)
        return false;

    return true;
}

void FrameView::notifyPageThatContentAreaWillPaint() const
{
    Page* page = m_frame->page();
    if (!page)
        return;

    contentAreaWillPaint();

    if (!m_scrollableAreas)
        return;

    for (HashSet<ScrollableArea*>::const_iterator it = m_scrollableAreas->begin(), end = m_scrollableAreas->end(); it != end; ++it) {
        ScrollableArea* scrollableArea = *it;

        if (!scrollableArea->scrollbarsCanBeActive())
            continue;

        scrollableArea->contentAreaWillPaint();
    }
}

bool FrameView::scrollAnimatorEnabled() const
{
    return m_frame->settings() && m_frame->settings()->scrollAnimatorEnabled();
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
        result = result.blend(htmlElement->renderer()->style()->visitedDependentColor(CSSPropertyBackgroundColor));

    return result;
}

bool FrameView::wasScrolledByUser() const
{
    return m_wasScrolledByUser;
}

void FrameView::setWasScrolledByUser(bool wasScrolledByUser)
{
    if (m_inProgrammaticScroll)
        return;
    m_wasScrolledByUser = wasScrolledByUser;
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
    TRACE_EVENT_INSTANT1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline.stack"), "CallStack", "stack", InspectorCallStackEvent::currentCallStack());

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

void FrameView::paintOverhangAreas(GraphicsContext* context, const IntRect& horizontalOverhangArea, const IntRect& verticalOverhangArea, const IntRect& dirtyRect)
{
    if (m_frame->page()->chrome().client().paintCustomOverhangArea(context, horizontalOverhangArea, verticalOverhangArea, dirtyRect))
        return;

    ScrollView::paintOverhangAreas(context, horizontalOverhangArea, verticalOverhangArea, dirtyRect);
}

void FrameView::updateWidgetPositionsIfNeeded()
{
    if (!m_needsUpdateWidgetPositions)
        return;

    m_needsUpdateWidgetPositions = false;

    updateWidgetPositions();
}

void FrameView::updateLayoutAndStyleForPainting()
{
    // Updating layout can run script, which can tear down the FrameView.
    RefPtr<FrameView> protector(this);

    updateLayoutAndStyleIfNeededRecursive();

    updateWidgetPositionsIfNeeded();

    if (RenderView* view = renderView()) {
        TRACE_EVENT_INSTANT1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline"), "UpdateLayerTree", "frame", m_frame.get());
        view->compositor()->updateIfNeededRecursive();

        if (view->compositor()->inCompositingMode())
            m_frame->page()->scrollingCoordinator()->updateAfterCompositingChangeIfNeeded();

        updateCompositedSelectionBoundsIfNeeded();

        invalidateTreeIfNeededRecursive();
    }

    scrollContentsIfNeededRecursive();
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
    IntRect rect = pixelSnappedIntRect(enclosingLayoutRect(renderer.localToAbsoluteQuad(FloatRect(rendererRect)).boundingBox()));

    // Convert from page ("absolute") to FrameView coordinates.
    rect.moveBy(-scrollPosition());

    return rect;
}

IntRect FrameView::convertToRenderer(const RenderObject& renderer, const IntRect& viewRect) const
{
    IntRect rect = viewRect;

    // Convert from FrameView coords into page ("absolute") coordinates.
    rect.moveBy(scrollPosition());

    // FIXME: we don't have a way to map an absolute rect down to a local quad, so just
    // move the rect for now.
    rect.setLocation(roundedIntPoint(renderer.absoluteToLocal(rect.location(), UseTransforms)));
    return rect;
}

IntPoint FrameView::convertFromRenderer(const RenderObject& renderer, const IntPoint& rendererPoint) const
{
    IntPoint point = roundedIntPoint(renderer.localToAbsolute(rendererPoint, UseTransforms));

    // Convert from page ("absolute") to FrameView coordinates.
    point.moveBy(-scrollPosition());
    return point;
}

IntPoint FrameView::convertToRenderer(const RenderObject& renderer, const IntPoint& viewPoint) const
{
    IntPoint point = viewPoint;

    // Convert from FrameView coords into page ("absolute") coordinates.
    point += IntSize(scrollX(), scrollY());

    return roundedIntPoint(renderer.absoluteToLocal(point, UseTransforms));
}

IntRect FrameView::convertToContainingView(const IntRect& localRect) const
{
    return localRect;
}

IntRect FrameView::convertFromContainingView(const IntRect& parentRect) const
{
    return parentRect;
}

IntPoint FrameView::convertToContainingView(const IntPoint& localPoint) const
{
    return localPoint;
}

IntPoint FrameView::convertFromContainingView(const IntPoint& parentPoint) const
{
    return parentPoint;
}

void FrameView::setTracksPaintInvalidations(bool trackPaintInvalidations)
{
    if (trackPaintInvalidations == m_isTrackingPaintInvalidations)
        return;

    // FIXME(sky): simplify
    if (RenderView* renderView = m_frame->contentRenderer())
        renderView->compositor()->setTracksPaintInvalidations(trackPaintInvalidations);

    TRACE_EVENT_INSTANT1(TRACE_DISABLED_BY_DEFAULT("blink.invalidation"),
        "FrameView::setTracksPaintInvalidations", "enabled", trackPaintInvalidations);

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

void FrameView::addResizerArea(RenderBox& resizerBox)
{
    if (!m_resizerAreas)
        m_resizerAreas = adoptPtr(new ResizerAreaSet);
    m_resizerAreas->add(&resizerBox);
}

void FrameView::removeResizerArea(RenderBox& resizerBox)
{
    if (!m_resizerAreas)
        return;

    ResizerAreaSet::iterator it = m_resizerAreas->find(&resizerBox);
    if (it != m_resizerAreas->end())
        m_resizerAreas->remove(it);
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

void FrameView::removeChild(Widget* widget)
{
    if (widget->isFrameView())
        removeScrollableArea(toFrameView(widget));

    ScrollView::removeChild(widget);
}

bool FrameView::wheelEvent(const PlatformWheelEvent& wheelEvent)
{
    bool allowScrolling = userInputScrollable(HorizontalScrollbar) || userInputScrollable(VerticalScrollbar);

    if (!isScrollable())
        allowScrolling = false;

    if (allowScrolling && ScrollableArea::handleWheelEvent(wheelEvent))
        return true;

    // If the frame didn't handle the event, give the pinch-zoom viewport a chance to
    // process the scroll event.
    if (m_frame->settings()->pinchVirtualViewportEnabled())
        return page()->frameHost().pinchViewport().handleWheelEvent(wheelEvent);

    return false;
}

bool FrameView::isVerticalDocument() const
{
    RenderView* renderView = this->renderView();
    if (!renderView)
        return true;

    return renderView->style()->isHorizontalWritingMode();
}

bool FrameView::isFlippedDocument() const
{
    RenderView* renderView = this->renderView();
    if (!renderView)
        return false;

    return renderView->style()->isFlippedBlocksWritingMode();
}

void FrameView::setCursor(const Cursor& cursor)
{
    Page* page = frame().page();
    if (!page || !page->settings().deviceSupportsMouse())
        return;
    page->chrome().setCursor(cursor);
}

void FrameView::frameRectsChanged()
{
    if (layoutSizeFixedToFrameSize())
        setLayoutSizeInternal(frameRect().size());

    ScrollView::frameRectsChanged();
}

void FrameView::setLayoutSizeInternal(const IntSize& size)
{
    if (m_layoutSize == size)
        return;

    m_layoutSize = size;
    contentsResized();
}

} // namespace blink
