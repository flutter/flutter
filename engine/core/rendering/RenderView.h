/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2006 Apple Computer, Inc.
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
 *
 */

#ifndef RenderView_h
#define RenderView_h

#include "core/frame/FrameView.h"
#include "core/rendering/LayoutState.h"
#include "core/rendering/PaintInvalidationState.h"
#include "core/rendering/RenderBlockFlow.h"
#include "platform/PODFreeListArena.h"
#include "platform/scroll/ScrollableArea.h"
#include "wtf/OwnPtr.h"

namespace blink {

class RenderLayerCompositor;

// The root of the render tree, corresponding to the CSS initial containing block.
// It's dimensions match that of the logical viewport (which may be different from
// the visible viewport in fixed-layout mode), and it is always at position (0,0)
// relative to the document (and so isn't necessarily in view).
class RenderView final : public RenderBlockFlow {
public:
    explicit RenderView(Document*);
    virtual ~RenderView();
    virtual void trace(Visitor*) override;

    bool hitTest(const HitTestRequest&, HitTestResult&);
    bool hitTest(const HitTestRequest&, const HitTestLocation&, HitTestResult&);

    // Returns the total count of calls to HitTest, for testing.
    unsigned hitTestCount() const { return m_hitTestCount; }

    virtual const char* renderName() const override { return "RenderView"; }

    virtual bool isRenderView() const override { return true; }

    virtual LayerType layerTypeRequired() const override { return NormalLayer; }

    virtual bool isChildAllowed(RenderObject*, RenderStyle*) const override;

    virtual void layout() override;
    virtual void updateLogicalWidth() override;
    virtual void computeLogicalHeight(LayoutUnit logicalHeight, LayoutUnit logicalTop, LogicalExtentComputedValues&) const override;

    virtual LayoutUnit availableLogicalHeight(AvailableLogicalHeightType) const override;

    // The same as the FrameView's layoutHeight/layoutWidth but with null check guards.
    int viewHeight(IncludeScrollbarsInRect = ExcludeScrollbars) const;
    int viewWidth(IncludeScrollbarsInRect = ExcludeScrollbars) const;
    int viewLogicalWidth() const
    {
        return style()->isHorizontalWritingMode() ? viewWidth(ExcludeScrollbars) : viewHeight(ExcludeScrollbars);
    }
    int viewLogicalHeight() const;
    LayoutUnit viewLogicalHeightForPercentages() const;

    float zoomFactor() const;

    FrameView* frameView() const { return m_frameView; }

    virtual void mapRectToPaintInvalidationBacking(const RenderLayerModelObject* paintInvalidationContainer, LayoutRect&, const PaintInvalidationState*) const override;

    void invalidatePaintForRectangle(const LayoutRect&) const;

    void invalidatePaintForViewAndCompositedLayers();

    virtual void paint(PaintInfo&, const LayoutPoint&) override;
    virtual void paintBoxDecorationBackground(PaintInfo&, const LayoutPoint&) override;

    enum SelectionPaintInvalidationMode { PaintInvalidationNewXOROld, PaintInvalidationNewMinusOld, PaintInvalidationNothing };
    void setSelection(RenderObject* start, int startPos, RenderObject*, int endPos, SelectionPaintInvalidationMode = PaintInvalidationNewXOROld);
    void getSelection(RenderObject*& startRenderer, int& startOffset, RenderObject*& endRenderer, int& endOffset) const;
    void clearSelection();
    RenderObject* selectionStart() const { return m_selectionStart; }
    RenderObject* selectionEnd() const { return m_selectionEnd; }
    IntRect selectionBounds(bool clipToVisibleContent = true) const;
    void selectionStartEnd(int& startPos, int& endPos) const;
    void invalidatePaintForSelection() const;

    virtual void absoluteRects(Vector<IntRect>&, const LayoutPoint& accumulatedOffset) const override;
    virtual void absoluteQuads(Vector<FloatQuad>&) const override;

    virtual LayoutRect viewRect() const override;

    bool shouldDoFullPaintInvalidationForNextLayout() const;
    bool doingFullPaintInvalidation() const { return m_frameView->needsFullPaintInvalidation(); }

    LayoutState* layoutState() const { return m_layoutState; }

    virtual void updateHitTestResult(HitTestResult&, const LayoutPoint&) override;

    // Notification that this view moved into or out of a native window.
    void setIsInWindow(bool);

    RenderLayerCompositor* compositor();
    bool usesCompositing() const;

    IntRect unscaledDocumentRect() const;
    LayoutRect backgroundRect(RenderBox* backgroundRenderer) const;

    IntRect documentRect() const;

    // Renderer that paints the root background has background-images which all have background-attachment: fixed.
    bool rootBackgroundIsEntirelyFixed() const;

    IntervalArena* intervalArena();

    virtual bool backgroundIsKnownToBeOpaqueInRect(const LayoutRect& localRect) const override;

    double layoutViewportWidth() const;
    double layoutViewportHeight() const;

    void pushLayoutState(LayoutState&);
    void popLayoutState();
    virtual void invalidateTreeIfNeeded(const PaintInvalidationState&) override final;

private:
    virtual void mapLocalToContainer(const RenderLayerModelObject* paintInvalidationContainer, TransformState&, MapCoordinatesFlags = ApplyContainerFlip, const PaintInvalidationState* = 0) const override;
    virtual const RenderObject* pushMappingToContainer(const RenderLayerModelObject* ancestorToStopAt, RenderGeometryMap&) const override;
    virtual void mapAbsoluteToLocalPoint(MapCoordinatesFlags, TransformState&) const override;
    virtual void computeSelfHitTestRects(Vector<LayoutRect>&, const LayoutPoint& layerOffset) const override;


    bool shouldInvalidatePaint(const LayoutRect&) const;

    void layoutContent();
#if ENABLE(ASSERT)
    void checkLayoutState();
#endif

    void positionDialog(RenderBox*);
    void positionDialogs();

    friend class ForceHorriblySlowRectMapping;

    RenderObject* backgroundRenderer() const;

    FrameView* m_frameView;

    RawPtr<RenderObject> m_selectionStart;
    RawPtr<RenderObject> m_selectionEnd;

    int m_selectionStartPos;
    int m_selectionEndPos;

    LayoutState* m_layoutState;
    OwnPtr<RenderLayerCompositor> m_compositor;
    RefPtr<IntervalArena> m_intervalArena;

    unsigned m_renderCounterCount;

    unsigned m_hitTestCount;
};

DEFINE_RENDER_OBJECT_TYPE_CASTS(RenderView, isRenderView());

// Suspends the LayoutState cached offset and clipRect optimization. Used under transforms
// that cannot be represented by LayoutState (common in SVG) and when manipulating the render
// tree during layout in ways that can trigger paint invalidation of a non-child (e.g. when a list item
// moves its list marker around). Note that even when disabled, LayoutState is still used to
// store layoutDelta.
class ForceHorriblySlowRectMapping {
    WTF_MAKE_NONCOPYABLE(ForceHorriblySlowRectMapping);
public:
    ForceHorriblySlowRectMapping(const PaintInvalidationState* paintInvalidationState)
        : m_paintInvalidationState(paintInvalidationState)
        , m_didDisable(m_paintInvalidationState && m_paintInvalidationState->cachedOffsetsEnabled())
    {
        if (m_paintInvalidationState)
            m_paintInvalidationState->m_cachedOffsetsEnabled = false;
    }

    ~ForceHorriblySlowRectMapping()
    {
        if (m_didDisable)
            m_paintInvalidationState->m_cachedOffsetsEnabled = true;
    }
private:
    const PaintInvalidationState* m_paintInvalidationState;
    bool m_didDisable;
};

} // namespace blink

#endif // RenderView_h
