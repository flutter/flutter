/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2007 David Smith (catfish.man@gmail.com)
 * Copyright (C) 2003-2013 Apple Inc. All rights reserved.
 * Copyright (C) Research In Motion Limited 2010. All rights reserved.
 * Copyright (C) 2013 Google Inc. All rights reserved.
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

#ifndef SKY_ENGINE_CORE_RENDERING_RENDERBLOCKFLOW_H_
#define SKY_ENGINE_CORE_RENDERING_RENDERBLOCKFLOW_H_

#include "sky/engine/core/rendering/RenderBlock.h"
#include "sky/engine/core/rendering/line/TrailingObjects.h"
#include "sky/engine/core/rendering/style/RenderStyleConstants.h"

namespace blink {

class LineBreaker;
class LineWidth;
class FloatingObject;

class RenderBlockFlow : public RenderBlock {
public:
    explicit RenderBlockFlow(ContainerNode*);
    virtual ~RenderBlockFlow();

    static RenderBlockFlow* createAnonymous(Document*);

    virtual bool isRenderBlockFlow() const override final { return true; }

    void layout() override;

    virtual void deleteLineBoxTree() override final;

    LayoutUnit availableLogicalWidthForLine(bool shouldIndentText) const
    {
        return max<LayoutUnit>(0, logicalRightOffsetForLine(shouldIndentText) - logicalLeftOffsetForLine(shouldIndentText));
    }
    LayoutUnit logicalRightOffsetForLine(bool shouldIndentText) const
    {
        LayoutUnit right = logicalRightOffsetForContent();
        if (shouldIndentText && !style()->isLeftToRightDirection())
            right -= textIndentOffset();
        return right;
    }
    LayoutUnit logicalLeftOffsetForLine(bool shouldIndentText) const
    {
        LayoutUnit left = logicalLeftOffsetForContent();
        if (shouldIndentText && style()->isLeftToRightDirection())
            left += textIndentOffset();
        return left;
    }
    LayoutUnit startOffsetForLine(bool shouldIndentText) const
    {
        return style()->isLeftToRightDirection() ? logicalLeftOffsetForLine(shouldIndentText)
            : logicalWidth() - logicalRightOffsetForLine(shouldIndentText);
    }
    LayoutUnit endOffsetForLine(bool shouldIndentText) const
    {
        return !style()->isLeftToRightDirection() ? logicalLeftOffsetForLine(shouldIndentText)
            : logicalWidth() - logicalRightOffsetForLine(shouldIndentText);
    }

    // FIXME-BLOCKFLOW: Move this into RenderBlockFlow once there are no calls
    // in RenderBlock. http://crbug.com/393945, http://crbug.com/302024
    using RenderBlock::lineBoxes;
    using RenderBlock::firstLineBox;
    using RenderBlock::lastLineBox;
    using RenderBlock::firstRootBox;
    using RenderBlock::lastRootBox;

    virtual LayoutUnit logicalLeftSelectionOffset(RenderBlock* rootBlock, LayoutUnit position) override;
    virtual LayoutUnit logicalRightSelectionOffset(RenderBlock* rootBlock, LayoutUnit position) override;

    RootInlineBox* createAndAppendRootInlineBox();

    virtual void addChild(RenderObject* newChild, RenderObject* beforeChild = 0) override;

    LayoutUnit startAlignedOffsetForLine(bool shouldIndentText);
    void updateLogicalWidthForAlignment(const ETextAlign&, const RootInlineBox*, BidiRun* trailingSpaceRun, float& logicalLeft, float& totalLogicalWidth, float& availableLogicalWidth, unsigned expansionOpportunityCount);

    void setStaticInlinePositionForChild(RenderBox*, LayoutUnit inlinePosition);
    void updateStaticInlinePositionForChild(RenderBox*);

    static bool shouldSkipCreatingRunsForObject(RenderObject* obj)
    {
        return obj->isOutOfFlowPositioned() && !obj->style()->isOriginalDisplayInlineType() && !obj->container()->isRenderInline();
    }

protected:
    virtual void layoutChildren(bool relayoutChildren, SubtreeLayoutScope&, LayoutUnit beforeEdge, LayoutUnit afterEdge);

    void determineLogicalLeftPositionForChild(RenderBox* child);

private:
    void layoutBlockFlow(SubtreeLayoutScope&);

    void layoutBlockChild(RenderBox* child);
    void adjustPositionedBlock(RenderBox* child);

    RootInlineBox* createRootInlineBox();

public:
    struct FloatWithRect {
        FloatWithRect(RenderBox* f)
            : object(f)
            , rect(LayoutRect(f->x() - f->marginLeft(), f->y() - f->marginTop(), f->width() + f->marginWidth(), f->height() + f->marginHeight()))
            , everHadLayout(f->everHadLayout())
        {
        }

        RenderBox* object;
        LayoutRect rect;
        bool everHadLayout;
    };

protected:
    friend class BreakingContext; // FIXME: It uses insertFloatingObject and positionNewFloatOnLine, if we move those out from the private scope/add a helper to LineBreaker, we can remove this friend
    friend class LineBreaker;
};

DEFINE_RENDER_OBJECT_TYPE_CASTS(RenderBlockFlow, isRenderBlockFlow());

} // namespace blink

#endif  // SKY_ENGINE_CORE_RENDERING_RENDERBLOCKFLOW_H_
