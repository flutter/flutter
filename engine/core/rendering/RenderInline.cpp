/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2003, 2004, 2005, 2006, 2007, 2008, 2009 Apple Inc. All rights reserved.
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

#include "config.h"
#include "core/rendering/RenderInline.h"

#include "core/dom/StyleEngine.h"
#include "core/page/Chrome.h"
#include "core/page/Page.h"
#include "core/rendering/GraphicsContextAnnotator.h"
#include "core/rendering/HitTestResult.h"
#include "core/rendering/InlineTextBox.h"
#include "core/rendering/RenderBlock.h"
#include "core/rendering/RenderGeometryMap.h"
#include "core/rendering/RenderLayer.h"
#include "core/rendering/RenderView.h"
#include "core/rendering/style/StyleInheritedData.h"
#include "platform/geometry/FloatQuad.h"
#include "platform/geometry/TransformState.h"
#include "platform/graphics/GraphicsContext.h"

namespace blink {

struct SameSizeAsRenderInline : public RenderBoxModelObject {
    virtual ~SameSizeAsRenderInline() { }
    RenderObjectChildList m_children;
    RenderLineBoxList m_lineBoxes;
};

COMPILE_ASSERT(sizeof(RenderInline) == sizeof(SameSizeAsRenderInline), RenderInline_should_stay_small);

RenderInline::RenderInline(Element* element)
    : RenderBoxModelObject(element)
{
    setChildrenInline(true);
}

void RenderInline::trace(Visitor* visitor)
{
    visitor->trace(m_children);
    RenderBoxModelObject::trace(visitor);
}

RenderInline* RenderInline::createAnonymous(Document* document)
{
    RenderInline* renderer = new RenderInline(0);
    renderer->setDocumentForAnonymous(document);
    return renderer;
}

void RenderInline::willBeDestroyed()
{
#if ENABLE(ASSERT)
    // Make sure we do not retain "this" in the continuation outline table map of our containing blocks.
    if (parent() && style()->hasOutline()) {
        bool containingBlockPaintsContinuationOutline = continuation() || isInlineElementContinuation();
        if (containingBlockPaintsContinuationOutline) {
            if (RenderBlock* cb = containingBlock()) {
                if (RenderBlock* cbCb = cb->containingBlock())
                    ASSERT(!cbCb->paintsContinuationOutline(this));
            }
        }
    }
#endif

    // Make sure to destroy anonymous children first while they are still connected to the rest of the tree, so that they will
    // properly dirty line boxes that they are removed from.  Effects that do :before/:after only on hover could crash otherwise.
    children()->destroyLeftoverChildren();

    // Destroy our continuation before anything other than anonymous children.
    // The reason we don't destroy it before anonymous children is that they may
    // have continuations of their own that are anonymous children of our continuation.
    RenderBoxModelObject* continuation = this->continuation();
    if (continuation) {
        continuation->destroy();
        setContinuation(0);
    }

    if (!documentBeingDestroyed()) {
        if (firstLineBox()) {
            // We can't wait for RenderBoxModelObject::destroy to clear the selection,
            // because by then we will have nuked the line boxes.
            // FIXME: The FrameSelection should be responsible for this when it
            // is notified of DOM mutations.
            if (isSelectionBorder())
                view()->clearSelection();

            // If line boxes are contained inside a root, that means we're an inline.
            // In that case, we need to remove all the line boxes so that the parent
            // lines aren't pointing to deleted children. If the first line box does
            // not have a parent that means they are either already disconnected or
            // root lines that can just be destroyed without disconnecting.
            if (firstLineBox()->parent()) {
                for (InlineFlowBox* box = firstLineBox(); box; box = box->nextLineBox())
                    box->remove();
            }
        } else if (parent())
            parent()->dirtyLinesFromChangedChild(this);
    }

    m_lineBoxes.deleteLineBoxes();

    RenderBoxModelObject::willBeDestroyed();
}

RenderInline* RenderInline::inlineElementContinuation() const
{
    RenderBoxModelObject* continuation = this->continuation();
    if (!continuation || continuation->isInline())
        return toRenderInline(continuation);
    return toRenderBlock(continuation)->inlineElementContinuation();
}

void RenderInline::updateFromStyle()
{
    RenderBoxModelObject::updateFromStyle();

    // FIXME: Is this still needed. Was needed for run-ins, since run-in is considered a block display type.
    setInline(true);

    // FIXME: Support transforms and reflections on inline flows someday.
    setHasTransform(false);
}

static RenderObject* inFlowPositionedInlineAncestor(RenderObject* p)
{
    while (p && p->isRenderInline()) {
        if (p->isRelPositioned())
            return p;
        p = p->parent();
    }
    return 0;
}

static void updateStyleOfAnonymousBlockContinuations(RenderObject* block, const RenderStyle* newStyle, const RenderStyle* oldStyle)
{
    for (;block && block->isAnonymousBlock(); block = block->nextSibling()) {
        if (!toRenderBlock(block)->isAnonymousBlockContinuation())
            continue;

        if (!block->style()->isOutlineEquivalent(newStyle)) {
            RefPtr<RenderStyle> blockStyle = RenderStyle::clone(block->style());
            blockStyle->setOutlineFromStyle(*newStyle);
            block->setStyle(blockStyle);
        }

        if (block->style()->position() != newStyle->position()) {
            // If we are no longer in-flow positioned but our descendant block(s) still have an in-flow positioned ancestor then
            // their containing anonymous block should keep its in-flow positioning.
            if (oldStyle->hasInFlowPosition()
                && inFlowPositionedInlineAncestor(toRenderBlock(block)->inlineElementContinuation()))
                continue;
            // FIXME: We should share blockStyle with the outline case, but it fails layout tests
            // for dynamic position change of inlines containing block continuations. crbug.com/405222.
            RefPtr<RenderStyle> blockStyle = RenderStyle::createAnonymousStyleWithDisplay(block->style(), BLOCK);
            blockStyle->setPosition(newStyle->position());
            block->setStyle(blockStyle);
        }
    }
}

void RenderInline::styleDidChange(StyleDifference diff, const RenderStyle* oldStyle)
{
    RenderBoxModelObject::styleDidChange(diff, oldStyle);

    // Ensure that all of the split inlines pick up the new style. We
    // only do this if we're an inline, since we don't want to propagate
    // a block's style to the other inlines.
    // e.g., <font>foo <h4>goo</h4> moo</font>.  The <font> inlines before
    // and after the block share the same style, but the block doesn't
    // need to pass its style on to anyone else.
    RenderStyle* newStyle = style();
    RenderInline* continuation = inlineElementContinuation();
    for (RenderInline* currCont = continuation; currCont; currCont = currCont->inlineElementContinuation()) {
        RenderBoxModelObject* nextCont = currCont->continuation();
        currCont->setContinuation(0);
        currCont->setStyle(newStyle);
        currCont->setContinuation(nextCont);
    }

    // If an inline's in-flow positioning has changed then any descendant blocks will need to change their in-flow positioning accordingly.
    // Do this by updating the position of the descendant blocks' containing anonymous blocks - there may be more than one.
    if (continuation && oldStyle
        && (!newStyle->isOutlineEquivalent(oldStyle)
            || (newStyle->position() != oldStyle->position() && (newStyle->hasInFlowPosition() || oldStyle->hasInFlowPosition())))) {
        // If any descendant blocks exist then they will be in the next anonymous block and its siblings.
        RenderObject* block = containingBlock()->nextSibling();
        if (block && block->isAnonymousBlock())
            updateStyleOfAnonymousBlockContinuations(block, newStyle, oldStyle);
    }

    if (!alwaysCreateLineBoxes()) {
        bool alwaysCreateLineBoxesNew = hasSelfPaintingLayer() || hasBoxDecorationBackground() || newStyle->hasPadding() || newStyle->hasMargin() || newStyle->hasOutline();
        if (oldStyle && alwaysCreateLineBoxesNew) {
            dirtyLineBoxes(false);
            setNeedsLayoutAndFullPaintInvalidation();
        }
        setAlwaysCreateLineBoxes(alwaysCreateLineBoxesNew);
    }
}

void RenderInline::setContinuation(RenderBoxModelObject* continuation)
{
    RenderBoxModelObject::setContinuation(continuation);
    if (continuation && continuation->isAnonymousBlock() && !continuation->style()->isOutlineEquivalent(style())) {
        // Push outline style to the block continuation.
        RefPtr<RenderStyle> blockStyle = RenderStyle::clone(continuation->style());
        blockStyle->setOutlineFromStyle(*style());
        continuation->setStyle(blockStyle);
    }
    // FIXME: What if continuation is added when the inline has relative position? crbug.com/405222.
}

void RenderInline::updateAlwaysCreateLineBoxes(bool fullLayout)
{
    // Once we have been tainted once, just assume it will happen again. This way effects like hover highlighting that change the
    // background color will only cause a layout on the first rollover.
    if (alwaysCreateLineBoxes())
        return;

    RenderStyle* parentStyle = parent()->style();
    RenderInline* parentRenderInline = parent()->isRenderInline() ? toRenderInline(parent()) : 0;
    bool alwaysCreateLineBoxesNew = (parentRenderInline && parentRenderInline->alwaysCreateLineBoxes())
        || (parentRenderInline && parentStyle->verticalAlign() != BASELINE)
        || style()->verticalAlign() != BASELINE
        || style()->textEmphasisMark() != TextEmphasisMarkNone
        || !parentStyle->font().fontMetrics().hasIdenticalAscentDescentAndLineGap(style()->font().fontMetrics())
        || parentStyle->lineHeight() != style()->lineHeight();

    if (!alwaysCreateLineBoxesNew && document().styleEngine()->usesFirstLineRules()) {
        // Have to check the first line style as well.
        parentStyle = parent()->style(true);
        RenderStyle* childStyle = style(true);
        alwaysCreateLineBoxesNew = !parentStyle->font().fontMetrics().hasIdenticalAscentDescentAndLineGap(childStyle->font().fontMetrics())
        || childStyle->verticalAlign() != BASELINE
        || parentStyle->lineHeight() != childStyle->lineHeight();
    }

    if (alwaysCreateLineBoxesNew) {
        if (!fullLayout)
            dirtyLineBoxes(false);
        setAlwaysCreateLineBoxes();
    }
}

LayoutRect RenderInline::localCaretRect(InlineBox* inlineBox, int, LayoutUnit* extraWidthToEndOfLine)
{
    if (firstChild()) {
        // This condition is possible if the RenderInline is at an editing boundary,
        // i.e. the VisiblePosition is:
        //   <RenderInline editingBoundary=true>|<RenderText> </RenderText></RenderInline>
        // FIXME: need to figure out how to make this return a valid rect, note that
        // there are no line boxes created in the above case.
        return LayoutRect();
    }

    ASSERT_UNUSED(inlineBox, !inlineBox);

    if (extraWidthToEndOfLine)
        *extraWidthToEndOfLine = 0;

    LayoutRect caretRect = localCaretRectForEmptyElement(borderAndPaddingWidth(), 0);

    if (InlineBox* firstBox = firstLineBox())
        caretRect.moveBy(roundedLayoutPoint(firstBox->topLeft()));

    return caretRect;
}

void RenderInline::addChild(RenderObject* newChild, RenderObject* beforeChild)
{
    if (continuation())
        return addChildToContinuation(newChild, beforeChild);
    return addChildIgnoringContinuation(newChild, beforeChild);
}

static RenderBoxModelObject* nextContinuation(RenderObject* renderer)
{
    if (renderer->isInline() && !renderer->isReplaced())
        return toRenderInline(renderer)->continuation();
    return toRenderBlock(renderer)->inlineElementContinuation();
}

RenderBoxModelObject* RenderInline::continuationBefore(RenderObject* beforeChild)
{
    if (beforeChild && beforeChild->parent() == this)
        return this;

    RenderBoxModelObject* curr = nextContinuation(this);
    RenderBoxModelObject* nextToLast = this;
    RenderBoxModelObject* last = this;
    while (curr) {
        if (beforeChild && beforeChild->parent() == curr) {
            if (curr->slowFirstChild() == beforeChild)
                return last;
            return curr;
        }

        nextToLast = last;
        last = curr;
        curr = nextContinuation(curr);
    }

    if (!beforeChild && !last->slowFirstChild())
        return nextToLast;
    return last;
}

void RenderInline::addChildIgnoringContinuation(RenderObject* newChild, RenderObject* beforeChild)
{
    if (!newChild->isInline() && !newChild->isFloatingOrOutOfFlowPositioned()) {
        // We are placing a block inside an inline. We have to perform a split of this
        // inline into continuations.  This involves creating an anonymous block box to hold
        // |newChild|.  We then make that block box a continuation of this inline.  We take all of
        // the children after |beforeChild| and put them in a clone of this object.
        RefPtr<RenderStyle> newStyle = RenderStyle::createAnonymousStyleWithDisplay(style(), BLOCK);

        // If inside an inline affected by in-flow positioning the block needs to be affected by it too.
        // Giving the block a layer like this allows it to collect the x/y offsets from inline parents later.
        if (RenderObject* positionedAncestor = inFlowPositionedInlineAncestor(this))
            newStyle->setPosition(positionedAncestor->style()->position());

        RenderBlockFlow* newBox = RenderBlockFlow::createAnonymous(&document());
        newBox->setStyle(newStyle.release());
        RenderBoxModelObject* oldContinuation = continuation();
        setContinuation(newBox);

        splitFlow(beforeChild, newBox, newChild, oldContinuation);
        return;
    }

    RenderBoxModelObject::addChild(newChild, beforeChild);

    newChild->setNeedsLayoutAndPrefWidthsRecalcAndFullPaintInvalidation();
}

RenderInline* RenderInline::clone() const
{
    RenderInline* cloneInline = new RenderInline(node());
    cloneInline->setStyle(style());
    return cloneInline;
}

void RenderInline::splitInlines(RenderBlock* fromBlock, RenderBlock* toBlock,
                                RenderBlock* middleBlock,
                                RenderObject* beforeChild, RenderBoxModelObject* oldCont)
{
    // Create a clone of this inline.
    RenderInline* cloneInline = clone();
    cloneInline->setContinuation(oldCont);

    // Now take all of the children from beforeChild to the end and remove
    // them from |this| and place them in the clone.
    RenderObject* o = beforeChild;
    while (o) {
        RenderObject* tmp = o;
        o = tmp->nextSibling();
        cloneInline->addChildIgnoringContinuation(children()->removeChildNode(this, tmp), 0);
        tmp->setNeedsLayoutAndPrefWidthsRecalcAndFullPaintInvalidation();
    }

    // Hook |clone| up as the continuation of the middle block.
    middleBlock->setContinuation(cloneInline);

    // We have been reparented and are now under the fromBlock.  We need
    // to walk up our inline parent chain until we hit the containing block.
    // Once we hit the containing block we're done.
    RenderBoxModelObject* curr = toRenderBoxModelObject(parent());
    RenderBoxModelObject* currChild = this;

    // FIXME: Because splitting is O(n^2) as tags nest pathologically, we cap the depth at which we're willing to clone.
    // There will eventually be a better approach to this problem that will let us nest to a much
    // greater depth (see bugzilla bug 13430) but for now we have a limit.  This *will* result in
    // incorrect rendering, but the alternative is to hang forever.
    unsigned splitDepth = 1;
    const unsigned cMaxSplitDepth = 200;
    while (curr && curr != fromBlock) {
        ASSERT(curr->isRenderInline());
        if (splitDepth < cMaxSplitDepth) {
            // Create a new clone.
            RenderInline* cloneChild = cloneInline;
            cloneInline = toRenderInline(curr)->clone();

            // Insert our child clone as the first child.
            cloneInline->addChildIgnoringContinuation(cloneChild, 0);

            // Hook the clone up as a continuation of |curr|.
            RenderInline* inlineCurr = toRenderInline(curr);
            oldCont = inlineCurr->continuation();
            inlineCurr->setContinuation(cloneInline);
            cloneInline->setContinuation(oldCont);

            // Now we need to take all of the children starting from the first child
            // *after* currChild and append them all to the clone.
            o = currChild->nextSibling();
            while (o) {
                RenderObject* tmp = o;
                o = tmp->nextSibling();
                cloneInline->addChildIgnoringContinuation(inlineCurr->children()->removeChildNode(curr, tmp), 0);
                tmp->setNeedsLayoutAndPrefWidthsRecalcAndFullPaintInvalidation();
            }
        }

        // Keep walking up the chain.
        currChild = curr;
        curr = toRenderBoxModelObject(curr->parent());
        splitDepth++;
    }

    // Now we are at the block level. We need to put the clone into the toBlock.
    toBlock->children()->appendChildNode(toBlock, cloneInline);

    // Now take all the children after currChild and remove them from the fromBlock
    // and put them in the toBlock.
    o = currChild->nextSibling();
    while (o) {
        RenderObject* tmp = o;
        o = tmp->nextSibling();
        toBlock->children()->appendChildNode(toBlock, fromBlock->children()->removeChildNode(fromBlock, tmp));
    }
}

void RenderInline::splitFlow(RenderObject* beforeChild, RenderBlock* newBlockBox,
                             RenderObject* newChild, RenderBoxModelObject* oldCont)
{
    RenderBlock* pre = 0;
    RenderBlock* block = containingBlock();

    // Delete our line boxes before we do the inline split into continuations.
    block->deleteLineBoxTree();

    bool madeNewBeforeBlock = false;
    if (block->isAnonymousBlock()) {
        // We can reuse this block and make it the preBlock of the next continuation.
        pre = block;
        pre->removePositionedObjects(0);
        block = block->containingBlock();
    } else {
        // No anonymous block available for use.  Make one.
        pre = block->createAnonymousBlock();
        madeNewBeforeBlock = true;
    }

    RenderBlock* post = toRenderBlock(pre->createAnonymousBoxWithSameTypeAs(block));

    RenderObject* boxFirst = madeNewBeforeBlock ? block->firstChild() : pre->nextSibling();
    if (madeNewBeforeBlock)
        block->children()->insertChildNode(block, pre, boxFirst);
    block->children()->insertChildNode(block, newBlockBox, boxFirst);
    block->children()->insertChildNode(block, post, boxFirst);
    block->setChildrenInline(false);

    if (madeNewBeforeBlock) {
        RenderObject* o = boxFirst;
        while (o) {
            RenderObject* no = o;
            o = no->nextSibling();
            pre->children()->appendChildNode(pre, block->children()->removeChildNode(block, no));
            no->setNeedsLayoutAndPrefWidthsRecalcAndFullPaintInvalidation();
        }
    }

    splitInlines(pre, post, newBlockBox, beforeChild, oldCont);

    // We already know the newBlockBox isn't going to contain inline kids, so avoid wasting
    // time in makeChildrenNonInline by just setting this explicitly up front.
    newBlockBox->setChildrenInline(false);

    newBlockBox->addChild(newChild);

    // Always just do a full layout in order to ensure that line boxes (especially wrappers for images)
    // get deleted properly.  Because objects moves from the pre block into the post block, we want to
    // make new line boxes instead of leaving the old line boxes around.
    pre->setNeedsLayoutAndPrefWidthsRecalcAndFullPaintInvalidation();
    block->setNeedsLayoutAndPrefWidthsRecalcAndFullPaintInvalidation();
    post->setNeedsLayoutAndPrefWidthsRecalcAndFullPaintInvalidation();
}

void RenderInline::addChildToContinuation(RenderObject* newChild, RenderObject* beforeChild)
{
    RenderBoxModelObject* flow = continuationBefore(beforeChild);
    ASSERT(!beforeChild || beforeChild->parent()->isRenderBlock() || beforeChild->parent()->isRenderInline());
    RenderBoxModelObject* beforeChildParent = 0;
    if (beforeChild)
        beforeChildParent = toRenderBoxModelObject(beforeChild->parent());
    else {
        RenderBoxModelObject* cont = nextContinuation(flow);
        if (cont)
            beforeChildParent = cont;
        else
            beforeChildParent = flow;
    }

    if (newChild->isFloatingOrOutOfFlowPositioned())
        return beforeChildParent->addChildIgnoringContinuation(newChild, beforeChild);

    // A continuation always consists of two potential candidates: an inline or an anonymous
    // block box holding block children.
    bool childInline = newChild->isInline();
    bool bcpInline = beforeChildParent->isInline();
    bool flowInline = flow->isInline();

    if (flow == beforeChildParent)
        return flow->addChildIgnoringContinuation(newChild, beforeChild);
    else {
        // The goal here is to match up if we can, so that we can coalesce and create the
        // minimal # of continuations needed for the inline.
        if (childInline == bcpInline || (beforeChild && beforeChild->isInline()))
            return beforeChildParent->addChildIgnoringContinuation(newChild, beforeChild);
        if (flowInline == childInline)
            return flow->addChildIgnoringContinuation(newChild, 0); // Just treat like an append.
        return beforeChildParent->addChildIgnoringContinuation(newChild, beforeChild);
    }
}

void RenderInline::paint(PaintInfo& paintInfo, const LayoutPoint& paintOffset)
{
    ANNOTATE_GRAPHICS_CONTEXT(paintInfo, this);
    m_lineBoxes.paint(this, paintInfo, paintOffset);
}

template<typename GeneratorContext>
void RenderInline::generateLineBoxRects(GeneratorContext& yield) const
{
    if (!alwaysCreateLineBoxes())
        generateCulledLineBoxRects(yield, this);
    else if (InlineFlowBox* curr = firstLineBox()) {
        for (; curr; curr = curr->nextLineBox())
            yield(FloatRect(curr->topLeft(), curr->size()));
    } else
        yield(FloatRect());
}

template<typename GeneratorContext>
void RenderInline::generateCulledLineBoxRects(GeneratorContext& yield, const RenderInline* container) const
{
    if (!culledInlineFirstLineBox()) {
        yield(FloatRect());
        return;
    }

    for (RenderObject* curr = firstChild(); curr; curr = curr->nextSibling()) {
        if (curr->isFloatingOrOutOfFlowPositioned())
            continue;

        // We want to get the margin box in the inline direction, and then use our font ascent/descent in the block
        // direction (aligned to the root box's baseline).
        if (curr->isBox()) {
            RenderBox* currBox = toRenderBox(curr);
            if (currBox->inlineBoxWrapper()) {
                RootInlineBox& rootBox = currBox->inlineBoxWrapper()->root();
                int logicalTop = rootBox.logicalTop() + (rootBox.renderer().style(rootBox.isFirstLineStyle())->font().fontMetrics().ascent() - container->style(rootBox.isFirstLineStyle())->font().fontMetrics().ascent());
                int logicalHeight = container->style(rootBox.isFirstLineStyle())->font().fontMetrics().height();
                yield(FloatRect(currBox->inlineBoxWrapper()->x() - currBox->marginLeft(), logicalTop, (currBox->width() + currBox->marginWidth()).toFloat(), logicalHeight));
            }
        } else if (curr->isRenderInline()) {
            // If the child doesn't need line boxes either, then we can recur.
            RenderInline* currInline = toRenderInline(curr);
            if (!currInline->alwaysCreateLineBoxes())
                currInline->generateCulledLineBoxRects(yield, container);
            else {
                for (InlineFlowBox* childLine = currInline->firstLineBox(); childLine; childLine = childLine->nextLineBox()) {
                    RootInlineBox& rootBox = childLine->root();
                    int logicalTop = rootBox.logicalTop() + (rootBox.renderer().style(rootBox.isFirstLineStyle())->font().fontMetrics().ascent() - container->style(rootBox.isFirstLineStyle())->font().fontMetrics().ascent());
                    int logicalHeight = container->style(rootBox.isFirstLineStyle())->font().fontMetrics().height();
                    yield(FloatRect(childLine->x() - childLine->marginLogicalLeft(),
                        logicalTop,
                        childLine->logicalWidth() + childLine->marginLogicalLeft() + childLine->marginLogicalRight(),
                        logicalHeight));
                }
            }
        } else if (curr->isText()) {
            RenderText* currText = toRenderText(curr);
            for (InlineTextBox* childText = currText->firstTextBox(); childText; childText = childText->nextTextBox()) {
                RootInlineBox& rootBox = childText->root();
                int logicalTop = rootBox.logicalTop() + (rootBox.renderer().style(rootBox.isFirstLineStyle())->font().fontMetrics().ascent() - container->style(rootBox.isFirstLineStyle())->font().fontMetrics().ascent());
                int logicalHeight = container->style(rootBox.isFirstLineStyle())->font().fontMetrics().height();
                yield(FloatRect(childText->x(), logicalTop, childText->logicalWidth(), logicalHeight));
            }
        }
    }
}

namespace {

class AbsoluteRectsGeneratorContext {
public:
    AbsoluteRectsGeneratorContext(Vector<IntRect>& rects, const LayoutPoint& accumulatedOffset)
        : m_rects(rects)
        , m_accumulatedOffset(accumulatedOffset) { }

    void operator()(const FloatRect& rect)
    {
        IntRect intRect = enclosingIntRect(rect);
        intRect.move(m_accumulatedOffset.x(), m_accumulatedOffset.y());
        m_rects.append(intRect);
    }
private:
    Vector<IntRect>& m_rects;
    const LayoutPoint& m_accumulatedOffset;
};

} // unnamed namespace

void RenderInline::absoluteRects(Vector<IntRect>& rects, const LayoutPoint& accumulatedOffset) const
{
    AbsoluteRectsGeneratorContext context(rects, accumulatedOffset);
    generateLineBoxRects(context);

    if (continuation()) {
        if (continuation()->isBox()) {
            RenderBox* box = toRenderBox(continuation());
            continuation()->absoluteRects(rects, toLayoutPoint(accumulatedOffset - containingBlock()->location() + box->locationOffset()));
        } else
            continuation()->absoluteRects(rects, toLayoutPoint(accumulatedOffset - containingBlock()->location()));
    }
}


namespace {

class AbsoluteQuadsGeneratorContext {
public:
    AbsoluteQuadsGeneratorContext(const RenderInline* renderer, Vector<FloatQuad>& quads)
        : m_quads(quads)
        , m_geometryMap()
    {
        m_geometryMap.pushMappingsToAncestor(renderer, 0);
    }

    void operator()(const FloatRect& rect)
    {
        m_quads.append(m_geometryMap.absoluteRect(rect));
    }
private:
    Vector<FloatQuad>& m_quads;
    RenderGeometryMap m_geometryMap;
};

} // unnamed namespace

void RenderInline::absoluteQuads(Vector<FloatQuad>& quads) const
{
    AbsoluteQuadsGeneratorContext context(this, quads);
    generateLineBoxRects(context);

    if (continuation())
        continuation()->absoluteQuads(quads);
}

LayoutUnit RenderInline::offsetLeft() const
{
    LayoutPoint topLeft;
    if (InlineBox* firstBox = firstLineBoxIncludingCulling())
        topLeft = flooredLayoutPoint(firstBox->topLeft());
    return adjustedPositionRelativeToOffsetParent(topLeft).x();
}

LayoutUnit RenderInline::offsetTop() const
{
    LayoutPoint topLeft;
    if (InlineBox* firstBox = firstLineBoxIncludingCulling())
        topLeft = flooredLayoutPoint(firstBox->topLeft());
    return adjustedPositionRelativeToOffsetParent(topLeft).y();
}

static LayoutUnit computeMargin(const RenderInline* renderer, const Length& margin)
{
    if (margin.isAuto())
        return 0;
    if (margin.isFixed())
        return margin.value();
    if (margin.isPercent())
        return minimumValueForLength(margin, std::max<LayoutUnit>(0, renderer->containingBlock()->availableLogicalWidth()));
    return 0;
}

LayoutUnit RenderInline::marginLeft() const
{
    return computeMargin(this, style()->marginLeft());
}

LayoutUnit RenderInline::marginRight() const
{
    return computeMargin(this, style()->marginRight());
}

LayoutUnit RenderInline::marginTop() const
{
    return computeMargin(this, style()->marginTop());
}

LayoutUnit RenderInline::marginBottom() const
{
    return computeMargin(this, style()->marginBottom());
}

LayoutUnit RenderInline::marginStart(const RenderStyle* otherStyle) const
{
    return computeMargin(this, style()->marginStartUsing(otherStyle ? otherStyle : style()));
}

LayoutUnit RenderInline::marginEnd(const RenderStyle* otherStyle) const
{
    return computeMargin(this, style()->marginEndUsing(otherStyle ? otherStyle : style()));
}

LayoutUnit RenderInline::marginBefore(const RenderStyle* otherStyle) const
{
    return computeMargin(this, style()->marginBeforeUsing(otherStyle ? otherStyle : style()));
}

LayoutUnit RenderInline::marginAfter(const RenderStyle* otherStyle) const
{
    return computeMargin(this, style()->marginAfterUsing(otherStyle ? otherStyle : style()));
}

const char* RenderInline::renderName() const
{
    if (isRelPositioned())
        return "RenderInline (relative positioned)";
    if (isAnonymous())
        return "RenderInline (generated)";
    return "RenderInline";
}

bool RenderInline::nodeAtPoint(const HitTestRequest& request, HitTestResult& result,
                                const HitTestLocation& locationInContainer, const LayoutPoint& accumulatedOffset, HitTestAction hitTestAction)
{
    return m_lineBoxes.hitTest(this, request, result, locationInContainer, accumulatedOffset, hitTestAction);
}

namespace {

class HitTestCulledInlinesGeneratorContext {
public:
    HitTestCulledInlinesGeneratorContext(Region& region, const HitTestLocation& location) : m_intersected(false), m_region(region), m_location(location) { }
    void operator()(const FloatRect& rect)
    {
        m_intersected = m_intersected || m_location.intersects(rect);
        m_region.unite(enclosingIntRect(rect));
    }
    bool intersected() const { return m_intersected; }
private:
    bool m_intersected;
    Region& m_region;
    const HitTestLocation& m_location;
};

} // unnamed namespace

bool RenderInline::hitTestCulledInline(const HitTestRequest& request, HitTestResult& result, const HitTestLocation& locationInContainer, const LayoutPoint& accumulatedOffset)
{
    ASSERT(result.isRectBasedTest() && !alwaysCreateLineBoxes());
    if (!visibleToHitTestRequest(request))
        return false;

    HitTestLocation tmpLocation(locationInContainer, -toLayoutSize(accumulatedOffset));

    Region regionResult;
    HitTestCulledInlinesGeneratorContext context(regionResult, tmpLocation);
    generateCulledLineBoxRects(context, this);

    if (context.intersected()) {
        updateHitTestResult(result, tmpLocation.point());
        // We can not use addNodeToRectBasedTestResult to determine if we fully enclose the hit-test area
        // because it can only handle rectangular targets.
        result.addNodeToRectBasedTestResult(node(), request, locationInContainer);
        return regionResult.contains(tmpLocation.boundingBox());
    }
    return false;
}

PositionWithAffinity RenderInline::positionForPoint(const LayoutPoint& point)
{
    // FIXME: Does not deal with relative positioned inlines (should it?)
    RenderBlock* cb = containingBlock();
    if (firstLineBox()) {
        // This inline actually has a line box.  We must have clicked in the border/padding of one of these boxes.  We
        // should try to find a result by asking our containing block.
        return cb->positionForPoint(point);
    }

    // Translate the coords from the pre-anonymous block to the post-anonymous block.
    LayoutPoint parentBlockPoint = cb->location() + point;
    RenderBoxModelObject* c = continuation();
    while (c) {
        RenderBox* contBlock = c->isInline() ? c->containingBlock() : toRenderBlock(c);
        if (c->isInline() || c->slowFirstChild())
            return c->positionForPoint(parentBlockPoint - contBlock->locationOffset());
        c = toRenderBlock(c)->inlineElementContinuation();
    }

    return RenderBoxModelObject::positionForPoint(point);
}

namespace {

class LinesBoundingBoxGeneratorContext {
public:
    LinesBoundingBoxGeneratorContext(FloatRect& rect) : m_rect(rect) { }
    void operator()(const FloatRect& rect)
    {
        m_rect.uniteIfNonZero(rect);
    }
private:
    FloatRect& m_rect;
};

} // unnamed namespace

IntRect RenderInline::linesBoundingBox() const
{
    if (!alwaysCreateLineBoxes()) {
        ASSERT(!firstLineBox());
        FloatRect floatResult;
        LinesBoundingBoxGeneratorContext context(floatResult);
        generateCulledLineBoxRects(context, this);
        return enclosingIntRect(floatResult);
    }

    IntRect result;

    // See <rdar://problem/5289721>, for an unknown reason the linked list here is sometimes inconsistent, first is non-zero and last is zero.  We have been
    // unable to reproduce this at all (and consequently unable to figure ot why this is happening).  The assert will hopefully catch the problem in debug
    // builds and help us someday figure out why.  We also put in a redundant check of lastLineBox() to avoid the crash for now.
    ASSERT(!firstLineBox() == !lastLineBox());  // Either both are null or both exist.
    if (firstLineBox() && lastLineBox()) {
        // Return the width of the minimal left side and the maximal right side.
        float logicalLeftSide = 0;
        float logicalRightSide = 0;
        for (InlineFlowBox* curr = firstLineBox(); curr; curr = curr->nextLineBox()) {
            if (curr == firstLineBox() || curr->logicalLeft() < logicalLeftSide)
                logicalLeftSide = curr->logicalLeft();
            if (curr == firstLineBox() || curr->logicalRight() > logicalRightSide)
                logicalRightSide = curr->logicalRight();
        }

        float x = logicalLeftSide;
        float y = firstLineBox()->y();
        float width = logicalRightSide - logicalLeftSide;
        float height = lastLineBox()->logicalBottom() - y;
        result = enclosingIntRect(FloatRect(x, y, width, height));
    }

    return result;
}

InlineBox* RenderInline::culledInlineFirstLineBox() const
{
    for (RenderObject* curr = firstChild(); curr; curr = curr->nextSibling()) {
        if (curr->isFloatingOrOutOfFlowPositioned())
            continue;

        // We want to get the margin box in the inline direction, and then use our font ascent/descent in the block
        // direction (aligned to the root box's baseline).
        if (curr->isBox())
            return toRenderBox(curr)->inlineBoxWrapper();
        if (curr->isRenderInline()) {
            RenderInline* currInline = toRenderInline(curr);
            InlineBox* result = currInline->firstLineBoxIncludingCulling();
            if (result)
                return result;
        } else if (curr->isText()) {
            RenderText* currText = toRenderText(curr);
            if (currText->firstTextBox())
                return currText->firstTextBox();
        }
    }
    return 0;
}

InlineBox* RenderInline::culledInlineLastLineBox() const
{
    for (RenderObject* curr = lastChild(); curr; curr = curr->previousSibling()) {
        if (curr->isFloatingOrOutOfFlowPositioned())
            continue;

        // We want to get the margin box in the inline direction, and then use our font ascent/descent in the block
        // direction (aligned to the root box's baseline).
        if (curr->isBox())
            return toRenderBox(curr)->inlineBoxWrapper();
        if (curr->isRenderInline()) {
            RenderInline* currInline = toRenderInline(curr);
            InlineBox* result = currInline->lastLineBoxIncludingCulling();
            if (result)
                return result;
        } else if (curr->isText()) {
            RenderText* currText = toRenderText(curr);
            if (currText->lastTextBox())
                return currText->lastTextBox();
        }
    }
    return 0;
}

LayoutRect RenderInline::culledInlineVisualOverflowBoundingBox() const
{
    FloatRect floatResult;
    LinesBoundingBoxGeneratorContext context(floatResult);
    generateCulledLineBoxRects(context, this);
    LayoutRect result(enclosingLayoutRect(floatResult));
    for (RenderObject* curr = firstChild(); curr; curr = curr->nextSibling()) {
        if (curr->isFloatingOrOutOfFlowPositioned())
            continue;

        // For overflow we just have to propagate by hand and recompute it all.
        if (curr->isBox()) {
            RenderBox* currBox = toRenderBox(curr);
            if (!currBox->hasSelfPaintingLayer() && currBox->inlineBoxWrapper()) {
                LayoutRect logicalRect = currBox->logicalVisualOverflowRectForPropagation(style());
                logicalRect.moveBy(currBox->location());
                result.uniteIfNonZero(logicalRect);
            }
        } else if (curr->isRenderInline()) {
            // If the child doesn't need line boxes either, then we can recur.
            RenderInline* currInline = toRenderInline(curr);
            if (!currInline->alwaysCreateLineBoxes())
                result.uniteIfNonZero(currInline->culledInlineVisualOverflowBoundingBox());
            else if (!currInline->hasSelfPaintingLayer())
                result.uniteIfNonZero(currInline->linesVisualOverflowBoundingBox());
        } else if (curr->isText()) {
            // FIXME; Overflow from text boxes is lost. We will need to cache this information in
            // InlineTextBoxes.
            RenderText* currText = toRenderText(curr);
            result.uniteIfNonZero(currText->linesVisualOverflowBoundingBox());
        }
    }
    return result;
}

LayoutRect RenderInline::linesVisualOverflowBoundingBox() const
{
    if (!alwaysCreateLineBoxes())
        return culledInlineVisualOverflowBoundingBox();

    if (!firstLineBox() || !lastLineBox())
        return LayoutRect();

    // Return the width of the minimal left side and the maximal right side.
    LayoutUnit logicalLeftSide = LayoutUnit::max();
    LayoutUnit logicalRightSide = LayoutUnit::min();
    for (InlineFlowBox* curr = firstLineBox(); curr; curr = curr->nextLineBox()) {
        logicalLeftSide = std::min(logicalLeftSide, curr->logicalLeftVisualOverflow());
        logicalRightSide = std::max(logicalRightSide, curr->logicalRightVisualOverflow());
    }

    RootInlineBox& firstRootBox = firstLineBox()->root();
    RootInlineBox& lastRootBox = lastLineBox()->root();

    LayoutUnit logicalTop = firstLineBox()->logicalTopVisualOverflow(firstRootBox.lineTop());
    LayoutUnit logicalWidth = logicalRightSide - logicalLeftSide;
    LayoutUnit logicalHeight = lastLineBox()->logicalBottomVisualOverflow(lastRootBox.lineBottom()) - logicalTop;

    LayoutRect rect(logicalLeftSide, logicalTop, logicalWidth, logicalHeight);
    return rect;
}

LayoutRect RenderInline::clippedOverflowRectForPaintInvalidation(const RenderLayerModelObject* paintInvalidationContainer, const PaintInvalidationState* paintInvalidationState) const
{
    if (!firstLineBoxIncludingCulling() && !continuation())
        return LayoutRect();

    LayoutRect paintInvalidationRect(linesVisualOverflowBoundingBox());
    bool hitPaintInvalidationContainer = false;

    // We need to add in the in-flow position offsets of any inlines (including us) up to our
    // containing block.
    RenderBlock* cb = containingBlock();
    for (const RenderObject* inlineFlow = this; inlineFlow && inlineFlow->isRenderInline() && inlineFlow != cb;
         inlineFlow = inlineFlow->parent()) {
        if (inlineFlow == paintInvalidationContainer) {
            hitPaintInvalidationContainer = true;
            break;
        }
        if (inlineFlow->style()->hasInFlowPosition() && inlineFlow->hasLayer())
            paintInvalidationRect.move(toRenderInline(inlineFlow)->layer()->offsetForInFlowPosition());
    }

    LayoutUnit outlineSize = style()->outlineSize();
    paintInvalidationRect.inflate(outlineSize);

    if (hitPaintInvalidationContainer || !cb)
        return paintInvalidationRect;

    if (cb->hasOverflowClip())
        cb->applyCachedClipAndScrollOffsetForPaintInvalidation(paintInvalidationRect);

    // FIXME: Passing paintInvalidationState directly to mapRectToPaintInvalidationBacking causes incorrect invalidations.
    // Should avoid slowRectMapping by properly adjusting paintInvalidationState. crbug.com/402994.
    ForceHorriblySlowRectMapping slowRectMapping(paintInvalidationState);
    cb->mapRectToPaintInvalidationBacking(paintInvalidationContainer, paintInvalidationRect, paintInvalidationState);

    if (outlineSize) {
        for (RenderObject* curr = firstChild(); curr; curr = curr->nextSibling()) {
            if (!curr->isText())
                paintInvalidationRect.unite(curr->rectWithOutlineForPaintInvalidation(paintInvalidationContainer, outlineSize));
        }

        if (continuation() && !continuation()->isInline() && continuation()->parent())
            paintInvalidationRect.unite(continuation()->rectWithOutlineForPaintInvalidation(paintInvalidationContainer, outlineSize));
    }

    return paintInvalidationRect;
}

LayoutRect RenderInline::rectWithOutlineForPaintInvalidation(const RenderLayerModelObject* paintInvalidationContainer, LayoutUnit outlineWidth, const PaintInvalidationState* paintInvalidationState) const
{
    LayoutRect r(RenderBoxModelObject::rectWithOutlineForPaintInvalidation(paintInvalidationContainer, outlineWidth, paintInvalidationState));
    for (RenderObject* curr = firstChild(); curr; curr = curr->nextSibling()) {
        if (!curr->isText())
            r.unite(curr->rectWithOutlineForPaintInvalidation(paintInvalidationContainer, outlineWidth, paintInvalidationState));
    }
    return r;
}

void RenderInline::mapRectToPaintInvalidationBacking(const RenderLayerModelObject* paintInvalidationContainer, LayoutRect& rect, const PaintInvalidationState* paintInvalidationState) const
{
    if (paintInvalidationState && paintInvalidationState->canMapToContainer(paintInvalidationContainer)) {
        if (style()->hasInFlowPosition() && layer())
            rect.move(layer()->offsetForInFlowPosition());
        rect.move(paintInvalidationState->paintOffset());
        if (paintInvalidationState->isClipped())
            rect.intersect(paintInvalidationState->clipRect());
        return;
    }

    if (paintInvalidationContainer == this)
        return;

    bool containerSkipped;
    RenderObject* o = container(paintInvalidationContainer, &containerSkipped);
    if (!o)
        return;

    LayoutPoint topLeft = rect.location();

    if (style()->hasInFlowPosition() && layer()) {
        // Apply the in-flow position offset when invalidating a rectangle. The layer
        // is translated, but the render box isn't, so we need to do this to get the
        // right dirty rect. Since this is called from RenderObject::setStyle, the relative position
        // flag on the RenderObject has been cleared, so use the one on the style().
        topLeft += layer()->offsetForInFlowPosition();
    }

    // FIXME: We ignore the lightweight clipping rect that controls use, since if |o| is in mid-layout,
    // its controlClipRect will be wrong. For overflow clip we use the values cached by the layer.
    rect.setLocation(topLeft);
    if (o->hasOverflowClip()) {
        RenderBox* containerBox = toRenderBox(o);
        containerBox->applyCachedClipAndScrollOffsetForPaintInvalidation(rect);
        if (rect.isEmpty())
            return;
    }

    if (containerSkipped) {
        // If the paintInvalidationContainer is below o, then we need to map the rect into paintInvalidationContainer's coordinates.
        LayoutSize containerOffset = paintInvalidationContainer->offsetFromAncestorContainer(o);
        rect.move(-containerOffset);
        return;
    }

    o->mapRectToPaintInvalidationBacking(paintInvalidationContainer, rect, paintInvalidationState);
}

LayoutSize RenderInline::offsetFromContainer(const RenderObject* container, const LayoutPoint& point, bool* offsetDependsOnPoint) const
{
    ASSERT(container == this->container());

    LayoutSize offset;
    if (isRelPositioned())
        offset += offsetForInFlowPosition();

    if (container->hasOverflowClip())
        offset -= toRenderBox(container)->scrolledContentOffset();

    // FIXME(sky): Remove now that it's always false?
    if (offsetDependsOnPoint)
        *offsetDependsOnPoint = false;

    return offset;
}

void RenderInline::mapLocalToContainer(const RenderLayerModelObject* paintInvalidationContainer, TransformState& transformState, MapCoordinatesFlags mode, const PaintInvalidationState* paintInvalidationState) const
{
    if (paintInvalidationContainer == this)
        return;

    if (paintInvalidationState && paintInvalidationState->canMapToContainer(paintInvalidationContainer)) {
        LayoutSize offset = paintInvalidationState->paintOffset();
        if (style()->hasInFlowPosition() && layer())
            offset += layer()->offsetForInFlowPosition();
        transformState.move(offset);
        return;
    }

    bool containerSkipped;
    RenderObject* o = container(paintInvalidationContainer, &containerSkipped);
    if (!o)
        return;

    if (mode & ApplyContainerFlip && o->isBox()) {
        mode &= ~ApplyContainerFlip;
    }

    LayoutSize containerOffset = offsetFromContainer(o, roundedLayoutPoint(transformState.mappedPoint()));

    bool preserve3D = mode & UseTransforms && (o->style()->preserves3D() || style()->preserves3D());
    if (mode & UseTransforms && shouldUseTransformFromContainer(o)) {
        TransformationMatrix t;
        getTransformFromContainer(o, containerOffset, t);
        transformState.applyTransform(t, preserve3D ? TransformState::AccumulateTransform : TransformState::FlattenTransform);
    } else
        transformState.move(containerOffset.width(), containerOffset.height(), preserve3D ? TransformState::AccumulateTransform : TransformState::FlattenTransform);

    if (containerSkipped) {
        // There can't be a transform between paintInvalidationContainer and o, because transforms create containers, so it should be safe
        // to just subtract the delta between the paintInvalidationContainer and o.
        LayoutSize containerOffset = paintInvalidationContainer->offsetFromAncestorContainer(o);
        transformState.move(-containerOffset.width(), -containerOffset.height(), preserve3D ? TransformState::AccumulateTransform : TransformState::FlattenTransform);
        return;
    }

    o->mapLocalToContainer(paintInvalidationContainer, transformState, mode, paintInvalidationState);
}

void RenderInline::childBecameNonInline(RenderObject* child)
{
    // We have to split the parent flow.
    RenderBlock* newBox = containingBlock()->createAnonymousBlock();
    RenderBoxModelObject* oldContinuation = continuation();
    setContinuation(newBox);
    RenderObject* beforeChild = child->nextSibling();
    children()->removeChildNode(this, child);
    splitFlow(beforeChild, newBox, child, oldContinuation);
}

void RenderInline::updateHitTestResult(HitTestResult& result, const LayoutPoint& point)
{
    if (result.innerNode())
        return;

    Node* n = node();
    LayoutPoint localPoint(point);
    if (n) {
        if (isInlineElementContinuation()) {
            // We're in the continuation of a split inline.  Adjust our local point to be in the coordinate space
            // of the principal renderer's containing block.  This will end up being the innerNonSharedNode.
            RenderBlock* firstBlock = n->renderer()->containingBlock();

            // Get our containing block.
            RenderBox* block = containingBlock();
            localPoint.moveBy(block->location() - firstBlock->locationOffset());
        }

        result.setInnerNode(n);
        if (!result.innerNonSharedNode())
            result.setInnerNonSharedNode(n);
        result.setLocalPoint(localPoint);
    }
}

void RenderInline::dirtyLineBoxes(bool fullLayout)
{
    if (fullLayout) {
        m_lineBoxes.deleteLineBoxes();
        return;
    }

    if (!alwaysCreateLineBoxes()) {
        // We have to grovel into our children in order to dirty the appropriate lines.
        for (RenderObject* curr = firstChild(); curr; curr = curr->nextSibling()) {
            if (curr->isFloatingOrOutOfFlowPositioned())
                continue;
            if (curr->isBox() && !curr->needsLayout()) {
                RenderBox* currBox = toRenderBox(curr);
                if (currBox->inlineBoxWrapper())
                    currBox->inlineBoxWrapper()->root().markDirty();
            } else if (!curr->selfNeedsLayout()) {
                if (curr->isRenderInline()) {
                    RenderInline* currInline = toRenderInline(curr);
                    for (InlineFlowBox* childLine = currInline->firstLineBox(); childLine; childLine = childLine->nextLineBox())
                        childLine->root().markDirty();
                } else if (curr->isText()) {
                    RenderText* currText = toRenderText(curr);
                    for (InlineTextBox* childText = currText->firstTextBox(); childText; childText = childText->nextTextBox())
                        childText->root().markDirty();
                }
            }
        }
    } else
        m_lineBoxes.dirtyLineBoxes();
}

void RenderInline::deleteLineBoxTree()
{
    m_lineBoxes.deleteLineBoxTree();
}

InlineFlowBox* RenderInline::createInlineFlowBox()
{
    return new InlineFlowBox(*this);
}

InlineFlowBox* RenderInline::createAndAppendInlineFlowBox()
{
    setAlwaysCreateLineBoxes();
    InlineFlowBox* flowBox = createInlineFlowBox();
    m_lineBoxes.appendLineBox(flowBox);
    return flowBox;
}

LayoutUnit RenderInline::lineHeight(bool firstLine, LineDirectionMode /*direction*/, LinePositionMode /*linePositionMode*/) const
{
    if (firstLine && document().styleEngine()->usesFirstLineRules()) {
        RenderStyle* s = style(firstLine);
        if (s != style())
            return s->computedLineHeight();
    }

    return style()->computedLineHeight();
}

int RenderInline::baselinePosition(FontBaseline baselineType, bool firstLine, LineDirectionMode direction, LinePositionMode linePositionMode) const
{
    ASSERT(linePositionMode == PositionOnContainingLine);
    const FontMetrics& fontMetrics = style(firstLine)->fontMetrics();
    return fontMetrics.ascent(baselineType) + (lineHeight(firstLine, direction, linePositionMode) - fontMetrics.height()) / 2;
}

LayoutSize RenderInline::offsetForInFlowPositionedInline(const RenderBox& child) const
{
    // FIXME: This function isn't right with mixed writing modes.

    ASSERT(isRelPositioned());
    if (!isRelPositioned())
        return LayoutSize();

    // When we have an enclosing relpositioned inline, we need to add in the offset of the first line
    // box from the rest of the content, but only in the cases where we know we're positioned
    // relative to the inline itself.

    LayoutSize logicalOffset;
    LayoutUnit inlinePosition;
    LayoutUnit blockPosition;
    if (firstLineBox()) {
        inlinePosition = LayoutUnit::fromFloatRound(firstLineBox()->logicalLeft());
        blockPosition = firstLineBox()->logicalTop();
    } else {
        inlinePosition = layer()->staticInlinePosition();
        blockPosition = layer()->staticBlockPosition();
    }

    // Per http://www.w3.org/TR/CSS2/visudet.html#abs-non-replaced-width an absolute positioned box
    // with a static position should locate itself as though it is a normal flow box in relation to
    // its containing block. If this relative-positioned inline has a negative offset we need to
    // compensate for it so that we align the positioned object with the edge of its containing block.
    if (child.style()->hasStaticInlinePosition())
        logicalOffset.setWidth(std::max(LayoutUnit(), -offsetForInFlowPosition().width()));
    else
        logicalOffset.setWidth(inlinePosition);

    if (!child.style()->hasStaticBlockPosition())
        logicalOffset.setHeight(blockPosition);

    return logicalOffset;
}

void RenderInline::imageChanged(WrappedImagePtr, const IntRect*)
{
    if (!parent())
        return;

    // FIXME: We can do better.
    setShouldDoFullPaintInvalidation(true);
}

namespace {

class AbsoluteRectsIgnoringEmptyRectsGeneratorContext : public AbsoluteRectsGeneratorContext {
public:
    AbsoluteRectsIgnoringEmptyRectsGeneratorContext(Vector<IntRect>& rects, const LayoutPoint& accumulatedOffset)
        : AbsoluteRectsGeneratorContext(rects, accumulatedOffset) { }

    void operator()(const FloatRect& rect)
    {
        if (!rect.isEmpty())
            AbsoluteRectsGeneratorContext::operator()(rect);
    }
};

} // unnamed namespace

void RenderInline::addFocusRingRects(Vector<IntRect>& rects, const LayoutPoint& additionalOffset, const RenderLayerModelObject* paintContainer) const
{
    AbsoluteRectsIgnoringEmptyRectsGeneratorContext context(rects, additionalOffset);
    generateLineBoxRects(context);

    addChildFocusRingRects(rects, additionalOffset, paintContainer);

    if (continuation()) {
        // If the continuation doesn't paint into the same container, let its paint invalidation container handle it.
        if (paintContainer != continuation()->containerForPaintInvalidation())
            return;
        if (continuation()->isInline())
            continuation()->addFocusRingRects(rects, flooredLayoutPoint(additionalOffset + continuation()->containingBlock()->location() - containingBlock()->location()), paintContainer);
        else
            continuation()->addFocusRingRects(rects, flooredLayoutPoint(additionalOffset + toRenderBox(continuation())->location() - containingBlock()->location()), paintContainer);
    }
}

namespace {

class AbsoluteLayoutRectsGeneratorContext {
public:
    AbsoluteLayoutRectsGeneratorContext(Vector<LayoutRect>& rects, const LayoutPoint& accumulatedOffset)
        : m_rects(rects)
        , m_accumulatedOffset(accumulatedOffset) { }

    void operator()(const FloatRect& rect)
    {
        LayoutRect layoutRect(rect);
        layoutRect.move(m_accumulatedOffset.x(), m_accumulatedOffset.y());
        m_rects.append(layoutRect);
    }
private:
    Vector<LayoutRect>& m_rects;
    const LayoutPoint& m_accumulatedOffset;
};

}

void RenderInline::computeSelfHitTestRects(Vector<LayoutRect>& rects, const LayoutPoint& layerOffset) const
{
    AbsoluteLayoutRectsGeneratorContext context(rects, layerOffset);
    generateLineBoxRects(context);
}

void RenderInline::paintOutline(PaintInfo& paintInfo, const LayoutPoint& paintOffset)
{
    RenderStyle* styleToUse = style();
    if (!styleToUse->hasOutline())
        return;

    if (styleToUse->outlineStyleIsAuto())
        return;

    if (styleToUse->outlineStyle() == BNONE)
        return;

    Vector<LayoutRect> rects;

    rects.append(LayoutRect());
    for (InlineFlowBox* curr = firstLineBox(); curr; curr = curr->nextLineBox()) {
        RootInlineBox& root = curr->root();
        LayoutUnit top = std::max<LayoutUnit>(root.lineTop(), curr->logicalTop());
        LayoutUnit bottom = std::min<LayoutUnit>(root.lineBottom(), curr->logicalBottom());
        rects.append(LayoutRect(curr->x(), top, curr->logicalWidth(), bottom - top));
    }
    rects.append(LayoutRect());

    Color outlineColor = resolveColor(styleToUse, CSSPropertyOutlineColor);
    bool useTransparencyLayer = outlineColor.hasAlpha();

    GraphicsContext* graphicsContext = paintInfo.context;
    if (useTransparencyLayer) {
        graphicsContext->beginTransparencyLayer(static_cast<float>(outlineColor.alpha()) / 255);
        outlineColor = Color(outlineColor.red(), outlineColor.green(), outlineColor.blue());
    }

    for (unsigned i = 1; i < rects.size() - 1; i++)
        paintOutlineForLine(graphicsContext, paintOffset, rects.at(i - 1), rects.at(i), rects.at(i + 1), outlineColor);

    if (useTransparencyLayer)
        graphicsContext->endLayer();
}

void RenderInline::paintOutlineForLine(GraphicsContext* graphicsContext, const LayoutPoint& paintOffset,
                                       const LayoutRect& lastline, const LayoutRect& thisline, const LayoutRect& nextline,
                                       const Color outlineColor)
{
    RenderStyle* styleToUse = style();
    int outlineWidth = styleToUse->outlineWidth();
    EBorderStyle outlineStyle = styleToUse->outlineStyle();

    bool antialias = shouldAntialiasLines(graphicsContext);

    int offset = style()->outlineOffset();

    LayoutRect box(LayoutPoint(paintOffset.x() + thisline.x() - offset, paintOffset.y() + thisline.y() - offset),
        LayoutSize(thisline.width() + offset, thisline.height() + offset));

    IntRect pixelSnappedBox = pixelSnappedIntRect(box);
    if (pixelSnappedBox.width() < 0 || pixelSnappedBox.height() < 0)
        return;
    IntRect pixelSnappedLastLine = pixelSnappedIntRect(paintOffset.x() + lastline.x(), 0, lastline.width(), 0);
    IntRect pixelSnappedNextLine = pixelSnappedIntRect(paintOffset.x() + nextline.x(), 0, nextline.width(), 0);

    // left edge
    drawLineForBoxSide(graphicsContext,
        pixelSnappedBox.x() - outlineWidth,
        pixelSnappedBox.y() - (lastline.isEmpty() || thisline.x() < lastline.x() || (lastline.maxX() - 1) <= thisline.x() ? outlineWidth : 0),
        pixelSnappedBox.x(),
        pixelSnappedBox.maxY() + (nextline.isEmpty() || thisline.x() <= nextline.x() || (nextline.maxX() - 1) <= thisline.x() ? outlineWidth : 0),
        BSLeft,
        outlineColor, outlineStyle,
        (lastline.isEmpty() || thisline.x() < lastline.x() || (lastline.maxX() - 1) <= thisline.x() ? outlineWidth : -outlineWidth),
        (nextline.isEmpty() || thisline.x() <= nextline.x() || (nextline.maxX() - 1) <= thisline.x() ? outlineWidth : -outlineWidth),
        antialias);

    // right edge
    drawLineForBoxSide(graphicsContext,
        pixelSnappedBox.maxX(),
        pixelSnappedBox.y() - (lastline.isEmpty() || lastline.maxX() < thisline.maxX() || (thisline.maxX() - 1) <= lastline.x() ? outlineWidth : 0),
        pixelSnappedBox.maxX() + outlineWidth,
        pixelSnappedBox.maxY() + (nextline.isEmpty() || nextline.maxX() <= thisline.maxX() || (thisline.maxX() - 1) <= nextline.x() ? outlineWidth : 0),
        BSRight,
        outlineColor, outlineStyle,
        (lastline.isEmpty() || lastline.maxX() < thisline.maxX() || (thisline.maxX() - 1) <= lastline.x() ? outlineWidth : -outlineWidth),
        (nextline.isEmpty() || nextline.maxX() <= thisline.maxX() || (thisline.maxX() - 1) <= nextline.x() ? outlineWidth : -outlineWidth),
        antialias);
    // upper edge
    if (thisline.x() < lastline.x())
        drawLineForBoxSide(graphicsContext,
            pixelSnappedBox.x() - outlineWidth,
            pixelSnappedBox.y() - outlineWidth,
            std::min(pixelSnappedBox.maxX() + outlineWidth, (lastline.isEmpty() ? 1000000 : pixelSnappedLastLine.x())),
            pixelSnappedBox.y(),
            BSTop, outlineColor, outlineStyle,
            outlineWidth,
            (!lastline.isEmpty() && paintOffset.x() + lastline.x() + 1 < pixelSnappedBox.maxX() + outlineWidth) ? -outlineWidth : outlineWidth,
            antialias);

    if (lastline.maxX() < thisline.maxX())
        drawLineForBoxSide(graphicsContext,
            std::max(lastline.isEmpty() ? -1000000 : pixelSnappedLastLine.maxX(), pixelSnappedBox.x() - outlineWidth),
            pixelSnappedBox.y() - outlineWidth,
            pixelSnappedBox.maxX() + outlineWidth,
            pixelSnappedBox.y(),
            BSTop, outlineColor, outlineStyle,
            (!lastline.isEmpty() && pixelSnappedBox.x() - outlineWidth < paintOffset.x() + lastline.maxX()) ? -outlineWidth : outlineWidth,
            outlineWidth, antialias);

    if (thisline.x() == thisline.maxX())
          drawLineForBoxSide(graphicsContext,
            pixelSnappedBox.x() - outlineWidth,
            pixelSnappedBox.y() - outlineWidth,
            pixelSnappedBox.maxX() + outlineWidth,
            pixelSnappedBox.y(),
            BSTop, outlineColor, outlineStyle,
            outlineWidth,
            outlineWidth,
            antialias);

    // lower edge
    if (thisline.x() < nextline.x())
        drawLineForBoxSide(graphicsContext,
            pixelSnappedBox.x() - outlineWidth,
            pixelSnappedBox.maxY(),
            std::min(pixelSnappedBox.maxX() + outlineWidth, !nextline.isEmpty() ? pixelSnappedNextLine.x() + 1 : 1000000),
            pixelSnappedBox.maxY() + outlineWidth,
            BSBottom, outlineColor, outlineStyle,
            outlineWidth,
            (!nextline.isEmpty() && paintOffset.x() + nextline.x() + 1 < pixelSnappedBox.maxX() + outlineWidth) ? -outlineWidth : outlineWidth,
            antialias);

    if (nextline.maxX() < thisline.maxX())
        drawLineForBoxSide(graphicsContext,
            std::max(!nextline.isEmpty() ? pixelSnappedNextLine.maxX() : -1000000, pixelSnappedBox.x() - outlineWidth),
            pixelSnappedBox.maxY(),
            pixelSnappedBox.maxX() + outlineWidth,
            pixelSnappedBox.maxY() + outlineWidth,
            BSBottom, outlineColor, outlineStyle,
            (!nextline.isEmpty() && pixelSnappedBox.x() - outlineWidth < paintOffset.x() + nextline.maxX()) ? -outlineWidth : outlineWidth,
            outlineWidth, antialias);

    if (thisline.x() == thisline.maxX())
          drawLineForBoxSide(graphicsContext,
            pixelSnappedBox.x() - outlineWidth,
            pixelSnappedBox.maxY(),
            pixelSnappedBox.maxX() + outlineWidth,
            pixelSnappedBox.maxY() + outlineWidth,
            BSBottom, outlineColor, outlineStyle,
            outlineWidth,
            outlineWidth,
            antialias);
}

} // namespace blink
