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

#ifndef SKY_ENGINE_CORE_RENDERING_RENDERVIEW_H_
#define SKY_ENGINE_CORE_RENDERING_RENDERVIEW_H_

#include "sky/engine/core/frame/FrameView.h"
#include "sky/engine/core/rendering/LayoutState.h"
#include "sky/engine/core/rendering/RenderBlockFlow.h"
#include "sky/engine/core/rendering/RenderIFrame.h"
#include "sky/engine/platform/scroll/ScrollableArea.h"
#include "sky/engine/wtf/OwnPtr.h"

namespace blink {

// The root of the render tree, corresponding to the CSS initial containing block.
// It's dimensions match that of the logical viewport (which may be different from
// the visible viewport in fixed-layout mode), and it is always at position (0,0)
// relative to the document (and so isn't necessarily in view).
class RenderView final : public RenderBlockFlow {
public:
    explicit RenderView(Document*);
    virtual ~RenderView();

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
        return viewWidth(ExcludeScrollbars);
    }
    int viewLogicalHeight() const;
    LayoutUnit viewLogicalHeightForPercentages() const;

    FrameView* frameView() const { return m_frameView; }

    virtual void paint(PaintInfo&, const LayoutPoint&) override;
    virtual void paintBoxDecorationBackground(PaintInfo&, const LayoutPoint&) override;

    void setSelection(RenderObject* start, int startPos, RenderObject*, int endPos);
    void getSelection(RenderObject*& startRenderer, int& startOffset, RenderObject*& endRenderer, int& endOffset) const;
    void clearSelection();
    RenderObject* selectionStart() const { return m_selectionStart; }
    RenderObject* selectionEnd() const { return m_selectionEnd; }
    void selectionStartEnd(int& startPos, int& endPos) const;

    virtual void absoluteRects(Vector<IntRect>&, const LayoutPoint& accumulatedOffset) const override;
    virtual void absoluteQuads(Vector<FloatQuad>&) const override;

    virtual LayoutRect viewRect() const override;

    LayoutState* layoutState() const { return m_layoutState; }

    virtual void updateHitTestResult(HitTestResult&, const LayoutPoint&) override;

    IntRect unscaledDocumentRect() const;
    LayoutRect backgroundRect(RenderBox* backgroundRenderer) const;

    IntRect documentRect() const;

    // Renderer that paints the root background has background-images which all have background-attachment: fixed.
    bool rootBackgroundIsEntirelyFixed() const;

    double layoutViewportWidth() const;
    double layoutViewportHeight() const;

    void pushLayoutState(LayoutState&);
    void popLayoutState();

    void addIFrame(RenderIFrame* iframe);
    void removeIFrame(RenderIFrame* iframe);
    void updateIFramesAfterLayout();

private:
    virtual void mapLocalToContainer(const RenderLayerModelObject* paintInvalidationContainer, TransformState&, MapCoordinatesFlags = ApplyContainerFlip) const override;
    virtual const RenderObject* pushMappingToContainer(const RenderLayerModelObject* ancestorToStopAt, RenderGeometryMap&) const override;
    virtual void mapAbsoluteToLocalPoint(MapCoordinatesFlags, TransformState&) const override;

    void layoutContent();
#if ENABLE(ASSERT)
    void checkLayoutState();
#endif

    void positionDialog(RenderBox*);
    void positionDialogs();

    RenderObject* backgroundRenderer() const;

    FrameView* m_frameView;

    RawPtr<RenderObject> m_selectionStart;
    RawPtr<RenderObject> m_selectionEnd;

    int m_selectionStartPos;
    int m_selectionEndPos;

    LayoutState* m_layoutState;

    unsigned m_renderCounterCount;

    unsigned m_hitTestCount;

    WTF::HashSet<RenderIFrame*> m_iframes;
};

DEFINE_RENDER_OBJECT_TYPE_CASTS(RenderView, isRenderView());

} // namespace blink

#endif  // SKY_ENGINE_CORE_RENDERING_RENDERVIEW_H_
