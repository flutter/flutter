/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2007 David Smith (catfish.man@gmail.com)
 * Copyright (C) 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011 Apple Inc. All rights reserved.
 * Copyright (C) Research In Motion Limited 2010. All rights reserved.
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
#include "core/rendering/RenderBlock.h"

#include "core/dom/Document.h"
#include "core/dom/Element.h"
#include "core/dom/StyleEngine.h"
#include "core/dom/shadow/ShadowRoot.h"
#include "core/editing/Editor.h"
#include "core/editing/FrameSelection.h"
#include "core/fetch/ResourceLoadPriorityOptimizer.h"
#include "core/frame/FrameView.h"
#include "core/frame/LocalFrame.h"
#include "core/page/Page.h"
#include "core/frame/Settings.h"
#include "core/rendering/GraphicsContextAnnotator.h"
#include "core/rendering/HitTestLocation.h"
#include "core/rendering/HitTestResult.h"
#include "core/rendering/InlineIterator.h"
#include "core/rendering/InlineTextBox.h"
#include "core/rendering/PaintInfo.h"
#include "core/rendering/RenderFlexibleBox.h"
#include "core/rendering/RenderInline.h"
#include "core/rendering/RenderLayer.h"
#include "core/rendering/RenderObjectInlines.h"
#include "core/rendering/RenderView.h"
#include "core/rendering/shapes/ShapeOutsideInfo.h"
#include "core/rendering/style/ContentData.h"
#include "core/rendering/style/RenderStyle.h"
#include "platform/geometry/FloatQuad.h"
#include "platform/geometry/TransformState.h"
#include "platform/graphics/GraphicsContextCullSaver.h"
#include "platform/graphics/GraphicsContextStateSaver.h"
#include "wtf/StdLibExtras.h"
#include "wtf/TemporaryChange.h"

using namespace WTF;
using namespace Unicode;

namespace blink {

struct SameSizeAsRenderBlock : public RenderBox {
    RenderObjectChildList children;
    RenderLineBoxList lineBoxes;
    int pageLogicalOffset;
    uint32_t bitfields;
};

COMPILE_ASSERT(sizeof(RenderBlock) == sizeof(SameSizeAsRenderBlock), RenderBlock_should_stay_small);

static TrackedDescendantsMap* gPositionedDescendantsMap = 0;
static TrackedDescendantsMap* gPercentHeightDescendantsMap = 0;

static TrackedContainerMap* gPositionedContainerMap = 0;
static TrackedContainerMap* gPercentHeightContainerMap = 0;

typedef WTF::HashMap<RenderBlock*, OwnPtr<ListHashSet<RenderInline*> > > ContinuationOutlineTableMap;

typedef WTF::HashSet<RenderBlock*> DelayedUpdateScrollInfoSet;
static int gDelayUpdateScrollInfo = 0;
static DelayedUpdateScrollInfoSet* gDelayedUpdateScrollInfoSet = 0;

RenderBlock::RenderBlock(ContainerNode* node)
    : RenderBox(node)
    , m_hasMarginBeforeQuirk(false)
    , m_hasMarginAfterQuirk(false)
    , m_beingDestroyed(false)
    , m_hasMarkupTruncation(false)
    , m_hasBorderOrPaddingLogicalWidthChanged(false)
    , m_hasOnlySelfCollapsingChildren(false)
    , m_descendantsWithFloatsMarkedForLayout(false)
{
    // RenderBlockFlow calls setChildrenInline(true).
    // By default, subclasses do not have inline children.
}

void RenderBlock::trace(Visitor* visitor)
{
    visitor->trace(m_children);
    RenderBox::trace(visitor);
}

static void removeBlockFromDescendantAndContainerMaps(RenderBlock* block, TrackedDescendantsMap*& descendantMap, TrackedContainerMap*& containerMap)
{
    if (OwnPtr<TrackedRendererListHashSet> descendantSet = descendantMap->take(block)) {
        TrackedRendererListHashSet::iterator end = descendantSet->end();
        for (TrackedRendererListHashSet::iterator descendant = descendantSet->begin(); descendant != end; ++descendant) {
            TrackedContainerMap::iterator it = containerMap->find(*descendant);
            ASSERT(it != containerMap->end());
            if (it == containerMap->end())
                continue;
            HashSet<RenderBlock*>* containerSet = it->value.get();
            ASSERT(containerSet->contains(block));
            containerSet->remove(block);
            if (containerSet->isEmpty())
                containerMap->remove(it);
        }
    }
}

static void appendImageIfNotNull(Vector<ImageResource*>& imageResources, const StyleImage* styleImage)
{
    if (styleImage && styleImage->cachedImage()) {
        ImageResource* imageResource = styleImage->cachedImage();
        if (imageResource && !imageResource->isLoaded())
            imageResources.append(styleImage->cachedImage());
    }
}

static void appendLayers(Vector<ImageResource*>& images, const FillLayer& styleLayer)
{
    for (const FillLayer* layer = &styleLayer; layer; layer = layer->next())
        appendImageIfNotNull(images, layer->image());
}

static void appendImagesFromStyle(Vector<ImageResource*>& images, RenderStyle& blockStyle)
{
    appendLayers(images, blockStyle.backgroundLayers());
    appendLayers(images, blockStyle.maskLayers());

    const ContentData* contentData = blockStyle.contentData();
    if (contentData && contentData->isImage())
        appendImageIfNotNull(images, toImageContentData(contentData)->image());
    appendImageIfNotNull(images, blockStyle.listStyleImage());
    appendImageIfNotNull(images, blockStyle.borderImageSource());
    appendImageIfNotNull(images, blockStyle.maskBoxImageSource());
    if (blockStyle.shapeOutside())
        appendImageIfNotNull(images, blockStyle.shapeOutside()->image());
}

void RenderBlock::removeFromGlobalMaps()
{
    if (gPercentHeightDescendantsMap)
        removeBlockFromDescendantAndContainerMaps(this, gPercentHeightDescendantsMap, gPercentHeightContainerMap);
    if (gPositionedDescendantsMap)
        removeBlockFromDescendantAndContainerMaps(this, gPositionedDescendantsMap, gPositionedContainerMap);
}

RenderBlock::~RenderBlock()
{
#if !ENABLE(OILPAN)
    removeFromGlobalMaps();
#endif
}

void RenderBlock::destroy()
{
    RenderBox::destroy();
#if ENABLE(OILPAN)
    removeFromGlobalMaps();
#endif
}

void RenderBlock::willBeDestroyed()
{
    // Mark as being destroyed to avoid trouble with merges in removeChild().
    m_beingDestroyed = true;

    // Make sure to destroy anonymous children first while they are still connected to the rest of the tree, so that they will
    // properly dirty line boxes that they are removed from. Effects that do :before/:after only on hover could crash otherwise.
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
            // We can't wait for RenderBox::destroy to clear the selection,
            // because by then we will have nuked the line boxes.
            // FIXME: The FrameSelection should be responsible for this when it
            // is notified of DOM mutations.
            if (isSelectionBorder())
                view()->clearSelection();

            // If we are an anonymous block, then our line boxes might have children
            // that will outlast this block. In the non-anonymous block case those
            // children will be destroyed by the time we return from this function.
            if (isAnonymousBlock()) {
                for (InlineFlowBox* box = firstLineBox(); box; box = box->nextLineBox()) {
                    while (InlineBox* childBox = box->firstChild())
                        childBox->remove();
                }
            }
        } else if (parent())
            parent()->dirtyLinesFromChangedChild(this);
    }

    m_lineBoxes.deleteLineBoxes();

    if (UNLIKELY(gDelayedUpdateScrollInfoSet != 0))
        gDelayedUpdateScrollInfoSet->remove(this);

    RenderBox::willBeDestroyed();
}

void RenderBlock::styleWillChange(StyleDifference diff, const RenderStyle& newStyle)
{
    RenderStyle* oldStyle = style();

    setReplaced(newStyle.isDisplayInlineType());

    if (oldStyle && parent()) {
        bool oldStyleIsContainer = oldStyle->position() != StaticPosition || oldStyle->hasTransformRelatedProperty();
        bool newStyleIsContainer = newStyle.position() != StaticPosition || newStyle.hasTransformRelatedProperty();

        if (oldStyleIsContainer && !newStyleIsContainer) {
            // Clear our positioned objects list. Our absolutely positioned descendants will be
            // inserted into our containing block's positioned objects list during layout.
            removePositionedObjects(0, NewContainingBlock);
        } else if (!oldStyleIsContainer && newStyleIsContainer) {
            // Remove our absolutely positioned descendants from their current containing block.
            // They will be inserted into our positioned objects list during layout.
            RenderObject* cb = parent();
            while (cb && (cb->style()->position() == StaticPosition || (cb->isInline() && !cb->isReplaced())) && !cb->isRenderView()) {
                if (cb->style()->position() == RelativePosition && cb->isInline() && !cb->isReplaced()) {
                    cb = cb->containingBlock();
                    break;
                }
                cb = cb->parent();
            }

            if (cb->isRenderBlock())
                toRenderBlock(cb)->removePositionedObjects(this, NewContainingBlock);
        }
    }

    RenderBox::styleWillChange(diff, newStyle);
}

static bool borderOrPaddingLogicalWidthChanged(const RenderStyle* oldStyle, const RenderStyle* newStyle)
{
    return oldStyle->borderLeftWidth() != newStyle->borderLeftWidth()
        || oldStyle->borderRightWidth() != newStyle->borderRightWidth()
        || oldStyle->paddingLeft() != newStyle->paddingLeft()
        || oldStyle->paddingRight() != newStyle->paddingRight();
}

void RenderBlock::styleDidChange(StyleDifference diff, const RenderStyle* oldStyle)
{
    RenderBox::styleDidChange(diff, oldStyle);

    RenderStyle* newStyle = style();

    if (!isAnonymousBlock()) {
        // Ensure that all of our continuation blocks pick up the new style.
        for (RenderBlock* currCont = blockElementContinuation(); currCont; currCont = currCont->blockElementContinuation()) {
            RenderBoxModelObject* nextCont = currCont->continuation();
            currCont->setContinuation(0);
            currCont->setStyle(newStyle);
            currCont->setContinuation(nextCont);
        }
    }

    propagateStyleToAnonymousChildren(true);

    // It's possible for our border/padding to change, but for the overall logical width of the block to
    // end up being the same. We keep track of this change so in layoutBlock, we can know to set relayoutChildren=true.
    m_hasBorderOrPaddingLogicalWidthChanged = oldStyle && diff.needsFullLayout() && needsLayout() && borderOrPaddingLogicalWidthChanged(oldStyle, newStyle);

    // If the style has unloaded images, want to notify the ResourceLoadPriorityOptimizer so that
    // network priorities can be set.
    Vector<ImageResource*> images;
    appendImagesFromStyle(images, *newStyle);
    if (images.isEmpty())
        ResourceLoadPriorityOptimizer::resourceLoadPriorityOptimizer()->removeRenderObject(this);
    else
        ResourceLoadPriorityOptimizer::resourceLoadPriorityOptimizer()->addRenderObject(this);
}

void RenderBlock::invalidateTreeIfNeeded(const PaintInvalidationState& paintInvalidationState)
{
    // Note, we don't want to early out here using shouldCheckForInvalidationAfterLayout as
    // we have to make sure we go through any positioned objects as they won't be seen in
    // the normal tree walk.

    RenderBox::invalidateTreeIfNeeded(paintInvalidationState);

    // Take care of positioned objects. This is required as PaintInvalidationState keeps a single clip rect.
    if (TrackedRendererListHashSet* positionedObjects = this->positionedObjects()) {
        TrackedRendererListHashSet::iterator end = positionedObjects->end();
        bool establishesNewPaintInvalidationContainer = isPaintInvalidationContainer();
        const RenderLayerModelObject& newPaintInvalidationContainer = *adjustCompositedContainerForSpecialAncestors(establishesNewPaintInvalidationContainer ? this : &paintInvalidationState.paintInvalidationContainer());
        PaintInvalidationState childPaintInvalidationState(paintInvalidationState, *this, newPaintInvalidationContainer);
        for (TrackedRendererListHashSet::iterator it = positionedObjects->begin(); it != end; ++it) {
            RenderBox* box = *it;

            // One of the renderers we're skipping over here may be the child's paint invalidation container,
            // so we can't pass our own paint invalidation container along.
            const RenderLayerModelObject& paintInvalidationContainerForChild = *box->containerForPaintInvalidation();

            // If it's a new paint invalidation container, we won't have properly accumulated the offset into the
            // PaintInvalidationState.
            // FIXME: Teach PaintInvalidationState to handle this case. crbug.com/371485
            if (&paintInvalidationContainerForChild != newPaintInvalidationContainer) {
                ForceHorriblySlowRectMapping slowRectMapping(&childPaintInvalidationState);
                PaintInvalidationState disabledPaintInvalidationState(childPaintInvalidationState, *this, paintInvalidationContainerForChild);
                box->invalidateTreeIfNeeded(disabledPaintInvalidationState);
                continue;
            }

            // If the positioned renderer is absolutely positioned and it is inside
            // a relatively positioned inline element, we need to account for
            // the inline elements position in PaintInvalidationState.
            if (box->style()->position() == AbsolutePosition) {
                RenderObject* container = box->container(&paintInvalidationContainerForChild, 0);
                if (container->isRelPositioned() && container->isRenderInline()) {
                    // FIXME: We should be able to use PaintInvalidationState for this.
                    // Currently, we will place absolutely positioned elements inside
                    // relatively positioned inline blocks in the wrong location. crbug.com/371485
                    ForceHorriblySlowRectMapping slowRectMapping(&childPaintInvalidationState);
                    PaintInvalidationState disabledPaintInvalidationState(childPaintInvalidationState, *this, paintInvalidationContainerForChild);
                    box->invalidateTreeIfNeeded(disabledPaintInvalidationState);
                    continue;
                }
            }

            box->invalidateTreeIfNeeded(childPaintInvalidationState);
        }
    }
}

RenderBlock* RenderBlock::continuationBefore(RenderObject* beforeChild)
{
    if (beforeChild && beforeChild->parent() == this)
        return this;

    RenderBlock* curr = toRenderBlock(continuation());
    RenderBlock* nextToLast = this;
    RenderBlock* last = this;
    while (curr) {
        if (beforeChild && beforeChild->parent() == curr) {
            if (curr->firstChild() == beforeChild)
                return last;
            return curr;
        }

        nextToLast = last;
        last = curr;
        curr = toRenderBlock(curr->continuation());
    }

    if (!beforeChild && !last->firstChild())
        return nextToLast;
    return last;
}

void RenderBlock::addChildToContinuation(RenderObject* newChild, RenderObject* beforeChild)
{
    RenderBlock* flow = continuationBefore(beforeChild);
    ASSERT(!beforeChild || beforeChild->parent()->isRenderBlock());
    RenderBoxModelObject* beforeChildParent = 0;
    if (beforeChild)
        beforeChildParent = toRenderBoxModelObject(beforeChild->parent());
    else {
        RenderBoxModelObject* cont = flow->continuation();
        if (cont)
            beforeChildParent = cont;
        else
            beforeChildParent = flow;
    }

    if (newChild->isFloatingOrOutOfFlowPositioned()) {
        beforeChildParent->addChildIgnoringContinuation(newChild, beforeChild);
        return;
    }

    if (flow == beforeChildParent) {
        flow->addChildIgnoringContinuation(newChild, beforeChild);
        return;
    }

    beforeChildParent->addChildIgnoringContinuation(newChild, beforeChild);
}

RenderBlock* RenderBlock::clone() const
{
    RenderBlock* cloneBlock;
    if (isAnonymousBlock()) {
        cloneBlock = createAnonymousBlock();
        cloneBlock->setChildrenInline(childrenInline());
    } else {
        RenderObject* cloneRenderer = toElement(node())->createRenderer(style());
        cloneBlock = toRenderBlock(cloneRenderer);
        cloneBlock->setStyle(style());

        // This takes care of setting the right value of childrenInline in case
        // generated content is added to cloneBlock and 'this' does not have
        // generated content added yet.
        cloneBlock->setChildrenInline(cloneBlock->firstChild() ? cloneBlock->firstChild()->isInline() : childrenInline());
    }
    return cloneBlock;
}

void RenderBlock::splitBlocks(RenderBlock* fromBlock, RenderBlock* toBlock,
                              RenderBlock* middleBlock,
                              RenderObject* beforeChild, RenderBoxModelObject* oldCont)
{
    // Create a clone of this inline.
    RenderBlock* cloneBlock = clone();
    if (!isAnonymousBlock())
        cloneBlock->setContinuation(oldCont);

    // If we are moving inline children from |this| to cloneBlock, then we need
    // to clear our line box tree.
    if (beforeChild && childrenInline())
        deleteLineBoxTree();

    // Now take all of the children from beforeChild to the end and remove
    // them from |this| and place them in the clone.
    moveChildrenTo(cloneBlock, beforeChild, 0, true);

    // Hook |clone| up as the continuation of the middle block.
    if (!cloneBlock->isAnonymousBlock())
        middleBlock->setContinuation(cloneBlock);

    // We have been reparented and are now under the fromBlock.  We need
    // to walk up our block parent chain until we hit the containing anonymous columns block.
    // Once we hit the anonymous columns block we're done.
    RenderBoxModelObject* curr = toRenderBoxModelObject(parent());
    RenderBoxModelObject* currChild = this;
    RenderObject* currChildNextSibling = currChild->nextSibling();

    while (curr && curr->isDescendantOf(fromBlock) && curr != fromBlock) {
        ASSERT_WITH_SECURITY_IMPLICATION(curr->isRenderBlock());

        RenderBlock* blockCurr = toRenderBlock(curr);

        // Create a new clone.
        RenderBlock* cloneChild = cloneBlock;
        cloneBlock = blockCurr->clone();

        // Insert our child clone as the first child.
        cloneBlock->addChildIgnoringContinuation(cloneChild, 0);

        // Hook the clone up as a continuation of |curr|.  Note we do encounter
        // anonymous blocks possibly as we walk up the block chain.  When we split an
        // anonymous block, there's no need to do any continuation hookup, since we haven't
        // actually split a real element.
        if (!blockCurr->isAnonymousBlock()) {
            oldCont = blockCurr->continuation();
            blockCurr->setContinuation(cloneBlock);
            cloneBlock->setContinuation(oldCont);
        }

        // Now we need to take all of the children starting from the first child
        // *after* currChild and append them all to the clone.
        blockCurr->moveChildrenTo(cloneBlock, currChildNextSibling, 0, true);

        // Keep walking up the chain.
        currChild = curr;
        currChildNextSibling = currChild->nextSibling();
        curr = toRenderBoxModelObject(curr->parent());
    }

    // Now we are at the columns block level. We need to put the clone into the toBlock.
    toBlock->children()->appendChildNode(toBlock, cloneBlock);

    // Now take all the children after currChild and remove them from the fromBlock
    // and put them in the toBlock.
    fromBlock->moveChildrenTo(toBlock, currChildNextSibling, 0, true);
}

void RenderBlock::addChildIgnoringAnonymousColumnBlocks(RenderObject* newChild, RenderObject* beforeChild)
{
    if (beforeChild && beforeChild->parent() != this) {
        RenderObject* beforeChildContainer = beforeChild->parent();
        while (beforeChildContainer->parent() != this)
            beforeChildContainer = beforeChildContainer->parent();
        ASSERT(beforeChildContainer);

        if (beforeChildContainer->isAnonymous()) {
            // If the requested beforeChild is not one of our children, then this is because
            // there is an anonymous container within this object that contains the beforeChild.
            RenderObject* beforeChildAnonymousContainer = beforeChildContainer;
            if (beforeChildAnonymousContainer->isAnonymousBlock()
                // Full screen renderers and full screen placeholders act as anonymous blocks, not tables:
                ) {
                // Insert the child into the anonymous block box instead of here.
                if (newChild->isInline() || newChild->isFloatingOrOutOfFlowPositioned() || beforeChild->parent()->slowFirstChild() != beforeChild)
                    beforeChild->parent()->addChild(newChild, beforeChild);
                else
                    addChild(newChild, beforeChild->parent());
                return;
            }

            // This used to ASSERT(beforeChildAnonymousContainer->isTable());
            ASSERT_NOT_REACHED();
        }
    }

    bool madeBoxesNonInline = false;

    // A block has to either have all of its children inline, or all of its children as blocks.
    // So, if our children are currently inline and a block child has to be inserted, we move all our
    // inline children into anonymous block boxes.
    if (childrenInline() && !newChild->isInline() && !newChild->isFloatingOrOutOfFlowPositioned()) {
        // This is a block with inline content. Wrap the inline content in anonymous blocks.
        makeChildrenNonInline(beforeChild);
        madeBoxesNonInline = true;

        if (beforeChild && beforeChild->parent() != this) {
            beforeChild = beforeChild->parent();
            ASSERT(beforeChild->isAnonymousBlock());
            ASSERT(beforeChild->parent() == this);
        }
    } else if (!childrenInline() && (newChild->isFloatingOrOutOfFlowPositioned() || newChild->isInline())) {
        // If we're inserting an inline child but all of our children are blocks, then we have to make sure
        // it is put into an anomyous block box. We try to use an existing anonymous box if possible, otherwise
        // a new one is created and inserted into our list of children in the appropriate position.
        RenderObject* afterChild = beforeChild ? beforeChild->previousSibling() : lastChild();

        if (afterChild && afterChild->isAnonymousBlock()) {
            afterChild->addChild(newChild);
            return;
        }

        if (newChild->isInline()) {
            // No suitable existing anonymous box - create a new one.
            RenderBlock* newBox = createAnonymousBlock();
            RenderBox::addChild(newBox, beforeChild);
            newBox->addChild(newChild);
            return;
        }
    }

    RenderBox::addChild(newChild, beforeChild);

    if (madeBoxesNonInline && parent() && isAnonymousBlock() && parent()->isRenderBlock())
        toRenderBlock(parent())->removeLeftoverAnonymousBlock(this);
    // this object may be dead here
}

void RenderBlock::addChild(RenderObject* newChild, RenderObject* beforeChild)
{
    if (continuation() && !isAnonymousBlock())
        addChildToContinuation(newChild, beforeChild);
    else
        addChildIgnoringContinuation(newChild, beforeChild);
}

void RenderBlock::addChildIgnoringContinuation(RenderObject* newChild, RenderObject* beforeChild)
{
    addChildIgnoringAnonymousColumnBlocks(newChild, beforeChild);
}

static void getInlineRun(RenderObject* start, RenderObject* boundary,
                         RenderObject*& inlineRunStart,
                         RenderObject*& inlineRunEnd)
{
    // Beginning at |start| we find the largest contiguous run of inlines that
    // we can.  We denote the run with start and end points, |inlineRunStart|
    // and |inlineRunEnd|.  Note that these two values may be the same if
    // we encounter only one inline.
    //
    // We skip any non-inlines we encounter as long as we haven't found any
    // inlines yet.
    //
    // |boundary| indicates a non-inclusive boundary point.  Regardless of whether |boundary|
    // is inline or not, we will not include it in a run with inlines before it.  It's as though we encountered
    // a non-inline.

    // Start by skipping as many non-inlines as we can.
    RenderObject * curr = start;
    bool sawInline;
    do {
        while (curr && !(curr->isInline() || curr->isFloatingOrOutOfFlowPositioned()))
            curr = curr->nextSibling();

        inlineRunStart = inlineRunEnd = curr;

        if (!curr)
            return; // No more inline children to be found.

        sawInline = curr->isInline();

        curr = curr->nextSibling();
        while (curr && (curr->isInline() || curr->isFloatingOrOutOfFlowPositioned()) && (curr != boundary)) {
            inlineRunEnd = curr;
            if (curr->isInline())
                sawInline = true;
            curr = curr->nextSibling();
        }
    } while (!sawInline);
}

void RenderBlock::deleteLineBoxTree()
{
    ASSERT(!m_lineBoxes.firstLineBox());
}

void RenderBlock::makeChildrenNonInline(RenderObject *insertionPoint)
{
    // makeChildrenNonInline takes a block whose children are *all* inline and it
    // makes sure that inline children are coalesced under anonymous
    // blocks.  If |insertionPoint| is defined, then it represents the insertion point for
    // the new block child that is causing us to have to wrap all the inlines.  This
    // means that we cannot coalesce inlines before |insertionPoint| with inlines following
    // |insertionPoint|, because the new child is going to be inserted in between the inlines,
    // splitting them.
    ASSERT(isInlineBlock() || !isInline());
    ASSERT(!insertionPoint || insertionPoint->parent() == this);

    setChildrenInline(false);

    RenderObject *child = firstChild();
    if (!child)
        return;

    deleteLineBoxTree();

    while (child) {
        RenderObject *inlineRunStart, *inlineRunEnd;
        getInlineRun(child, insertionPoint, inlineRunStart, inlineRunEnd);

        if (!inlineRunStart)
            break;

        child = inlineRunEnd->nextSibling();

        RenderBlock* block = createAnonymousBlock();
        children()->insertChildNode(this, block, inlineRunStart);
        moveChildrenTo(block, inlineRunStart, child);
    }

#if ENABLE(ASSERT)
    for (RenderObject *c = firstChild(); c; c = c->nextSibling())
        ASSERT(!c->isInline());
#endif

    setShouldDoFullPaintInvalidation(true);
}

void RenderBlock::removeLeftoverAnonymousBlock(RenderBlock* child)
{
    ASSERT(child->isAnonymousBlock());
    ASSERT(!child->childrenInline());

    if (child->continuation())
        return;

    RenderObject* firstAnChild = child->m_children.firstChild();
    RenderObject* lastAnChild = child->m_children.lastChild();
    if (firstAnChild) {
        RenderObject* o = firstAnChild;
        while (o) {
            o->setParent(this);
            o = o->nextSibling();
        }
        firstAnChild->setPreviousSibling(child->previousSibling());
        lastAnChild->setNextSibling(child->nextSibling());
        if (child->previousSibling())
            child->previousSibling()->setNextSibling(firstAnChild);
        if (child->nextSibling())
            child->nextSibling()->setPreviousSibling(lastAnChild);

        if (child == m_children.firstChild())
            m_children.setFirstChild(firstAnChild);
        if (child == m_children.lastChild())
            m_children.setLastChild(lastAnChild);
    } else {
        if (child == m_children.firstChild())
            m_children.setFirstChild(child->nextSibling());
        if (child == m_children.lastChild())
            m_children.setLastChild(child->previousSibling());

        if (child->previousSibling())
            child->previousSibling()->setNextSibling(child->nextSibling());
        if (child->nextSibling())
            child->nextSibling()->setPreviousSibling(child->previousSibling());
    }

    child->children()->setFirstChild(0);
    child->m_next = nullptr;

    child->setParent(0);
    child->setPreviousSibling(0);
    child->setNextSibling(0);

    child->destroy();
}

static bool canMergeContiguousAnonymousBlocks(RenderObject* oldChild, RenderObject* prev, RenderObject* next)
{
    if (oldChild->documentBeingDestroyed() || oldChild->isInline() || oldChild->virtualContinuation())
        return false;

    if ((prev && (!prev->isAnonymousBlock() || toRenderBlock(prev)->continuation() || toRenderBlock(prev)->beingDestroyed()))
        || (next && (!next->isAnonymousBlock() || toRenderBlock(next)->continuation() || toRenderBlock(next)->beingDestroyed())))
        return false;

    if (!prev || !next)
        return true;

    return true;
}

void RenderBlock::collapseAnonymousBlockChild(RenderBlock* parent, RenderBlock* child)
{
    // It's possible that this block's destruction may have been triggered by the
    // child's removal. Just bail if the anonymous child block is already being
    // destroyed. See crbug.com/282088
    if (child->beingDestroyed())
        return;
    parent->setNeedsLayoutAndPrefWidthsRecalcAndFullPaintInvalidation();
    parent->setChildrenInline(child->childrenInline());
    RenderObject* nextSibling = child->nextSibling();

    parent->children()->removeChildNode(parent, child, child->hasLayer());
    child->moveAllChildrenTo(parent, nextSibling, child->hasLayer());
    // Explicitly delete the child's line box tree, or the special anonymous
    // block handling in willBeDestroyed will cause problems.
    child->deleteLineBoxTree();
    child->destroy();
}

void RenderBlock::removeChild(RenderObject* oldChild)
{
    // No need to waste time in merging or removing empty anonymous blocks.
    // We can just bail out if our document is getting destroyed.
    if (documentBeingDestroyed()) {
        RenderBox::removeChild(oldChild);
        return;
    }

    // If this child is a block, and if our previous and next siblings are
    // both anonymous blocks with inline content, then we can go ahead and
    // fold the inline content back together.
    RenderObject* prev = oldChild->previousSibling();
    RenderObject* next = oldChild->nextSibling();
    bool canMergeAnonymousBlocks = canMergeContiguousAnonymousBlocks(oldChild, prev, next);
    if (canMergeAnonymousBlocks && prev && next) {
        prev->setNeedsLayoutAndPrefWidthsRecalcAndFullPaintInvalidation();
        RenderBlockFlow* nextBlock = toRenderBlockFlow(next);
        RenderBlockFlow* prevBlock = toRenderBlockFlow(prev);

        if (prev->childrenInline() != next->childrenInline()) {
            RenderBlock* inlineChildrenBlock = prev->childrenInline() ? prevBlock : nextBlock;
            RenderBlock* blockChildrenBlock = prev->childrenInline() ? nextBlock : prevBlock;

            // Place the inline children block inside of the block children block instead of deleting it.
            // In order to reuse it, we have to reset it to just be a generic anonymous block.  Make sure
            // to clear out inherited column properties by just making a new style, and to also clear the
            // column span flag if it is set.
            ASSERT(!inlineChildrenBlock->continuation());
            RefPtr<RenderStyle> newStyle = RenderStyle::createAnonymousStyleWithDisplay(style(), BLOCK);
            // Cache this value as it might get changed in setStyle() call.
            bool inlineChildrenBlockHasLayer = inlineChildrenBlock->hasLayer();
            inlineChildrenBlock->setStyle(newStyle);
            children()->removeChildNode(this, inlineChildrenBlock, inlineChildrenBlockHasLayer);

            // Now just put the inlineChildrenBlock inside the blockChildrenBlock.
            blockChildrenBlock->children()->insertChildNode(blockChildrenBlock, inlineChildrenBlock, prev == inlineChildrenBlock ? blockChildrenBlock->firstChild() : 0,
                                                            inlineChildrenBlockHasLayer || blockChildrenBlock->hasLayer());
            next->setNeedsLayoutAndPrefWidthsRecalcAndFullPaintInvalidation();

            // inlineChildrenBlock got reparented to blockChildrenBlock, so it is no longer a child
            // of "this". we null out prev or next so that is not used later in the function.
            if (inlineChildrenBlock == prevBlock)
                prev = 0;
            else
                next = 0;
        } else {
            // Take all the children out of the |next| block and put them in
            // the |prev| block.
            nextBlock->moveAllChildrenIncludingFloatsTo(prevBlock, nextBlock->hasLayer() || prevBlock->hasLayer());

            // Delete the now-empty block's lines and nuke it.
            nextBlock->deleteLineBoxTree();
            nextBlock->destroy();
            next = 0;
        }
    }

    RenderBox::removeChild(oldChild);

    RenderObject* child = prev ? prev : next;
    if (canMergeAnonymousBlocks && child && !child->previousSibling() && !child->nextSibling() && canCollapseAnonymousBlockChild()) {
        // The removal has knocked us down to containing only a single anonymous
        // box.  We can go ahead and pull the content right back up into our
        // box.
        collapseAnonymousBlockChild(this, toRenderBlock(child));
    } else if (((prev && prev->isAnonymousBlock()) || (next && next->isAnonymousBlock())) && canCollapseAnonymousBlockChild()) {
        // It's possible that the removal has knocked us down to a single anonymous
        // block with pseudo-style element siblings (e.g. first-letter). If these
        // are floating, then we need to pull the content up also.
        RenderBlock* anonymousBlock = toRenderBlock((prev && prev->isAnonymousBlock()) ? prev : next);
        if ((anonymousBlock->previousSibling() || anonymousBlock->nextSibling())
            && (!anonymousBlock->previousSibling() || (anonymousBlock->previousSibling()->style()->styleType() != NOPSEUDO && anonymousBlock->previousSibling()->isFloating() && !anonymousBlock->previousSibling()->previousSibling()))
            && (!anonymousBlock->nextSibling() || (anonymousBlock->nextSibling()->style()->styleType() != NOPSEUDO && anonymousBlock->nextSibling()->isFloating() && !anonymousBlock->nextSibling()->nextSibling()))) {
            collapseAnonymousBlockChild(this, anonymousBlock);
        }
    }

    if (!firstChild()) {
        // If this was our last child be sure to clear out our line boxes.
        if (childrenInline())
            deleteLineBoxTree();

        // If we are an empty anonymous block in the continuation chain,
        // we need to remove ourself and fix the continuation chain.
        if (!beingDestroyed() && isAnonymousBlockContinuation()) {
            RenderObject* containingBlockIgnoringAnonymous = containingBlock();
            while (containingBlockIgnoringAnonymous && containingBlockIgnoringAnonymous->isAnonymous())
                containingBlockIgnoringAnonymous = containingBlockIgnoringAnonymous->containingBlock();
            for (RenderObject* curr = this; curr; curr = curr->previousInPreOrder(containingBlockIgnoringAnonymous)) {
                if (curr->virtualContinuation() != this)
                    continue;

                // Found our previous continuation. We just need to point it to
                // |this|'s next continuation.
                RenderBoxModelObject* nextContinuation = continuation();
                if (curr->isRenderInline())
                    toRenderInline(curr)->setContinuation(nextContinuation);
                else if (curr->isRenderBlock())
                    toRenderBlock(curr)->setContinuation(nextContinuation);
                else
                    ASSERT_NOT_REACHED();

                break;
            }
            setContinuation(0);
            destroy();
        }
    }
}

bool RenderBlock::isSelfCollapsingBlock() const
{
    // We are not self-collapsing if we
    // (a) have a non-zero height according to layout (an optimization to avoid wasting time)
    // (b) are a table,
    // (c) have border/padding,
    // (d) have a min-height
    // (e) have specified that one of our margins can't collapse using a CSS extension
    // (f) establish a new block formatting context.

    // The early exit must be done before we check for clean layout.
    // We should be able to give a quick answer if the box is a relayout boundary.
    // Being a relayout boundary implies a block formatting context, and also
    // our internal layout shouldn't affect our container in any way.
    if (createsBlockFormattingContext())
        return false;

    ASSERT(!needsLayout());

    if (logicalHeight() > 0
        || borderAndPaddingLogicalHeight()
        || style()->logicalMinHeight().isPositive()
        || style()->marginBeforeCollapse() == MSEPARATE || style()->marginAfterCollapse() == MSEPARATE)
        return false;

    Length logicalHeightLength = style()->logicalHeight();
    bool hasAutoHeight = logicalHeightLength.isAuto();
    if (logicalHeightLength.isPercent()) {
        hasAutoHeight = true;
        for (RenderBlock* cb = containingBlock(); !cb->isRenderView(); cb = cb->containingBlock()) {
            if (cb->style()->logicalHeight().isFixed())
                hasAutoHeight = false;
        }
    }

    // If the height is 0 or auto, then whether or not we are a self-collapsing block depends
    // on whether we have content that is all self-collapsing or not.
    if (hasAutoHeight || ((logicalHeightLength.isFixed() || logicalHeightLength.isPercent()) && logicalHeightLength.isZero())) {
        // If the block has inline children, see if we generated any line boxes.  If we have any
        // line boxes, then we can't be self-collapsing, since we have content.
        if (childrenInline())
            return !firstLineBox();

        // Whether or not we collapse is dependent on whether all our normal flow children
        // are also self-collapsing.
        if (m_hasOnlySelfCollapsingChildren)
            return true;
        for (RenderBox* child = firstChildBox(); child; child = child->nextSiblingBox()) {
            if (child->isFloatingOrOutOfFlowPositioned())
                continue;
            if (!child->isSelfCollapsingBlock())
                return false;
        }
        return true;
    }
    return false;
}

void RenderBlock::startDelayUpdateScrollInfo()
{
    if (gDelayUpdateScrollInfo == 0) {
        ASSERT(!gDelayedUpdateScrollInfoSet);
        gDelayedUpdateScrollInfoSet = new DelayedUpdateScrollInfoSet;
    }
    ASSERT(gDelayedUpdateScrollInfoSet);
    ++gDelayUpdateScrollInfo;
}

void RenderBlock::finishDelayUpdateScrollInfo()
{
    --gDelayUpdateScrollInfo;
    ASSERT(gDelayUpdateScrollInfo >= 0);
    if (gDelayUpdateScrollInfo == 0) {
        ASSERT(gDelayedUpdateScrollInfoSet);

        OwnPtr<DelayedUpdateScrollInfoSet> infoSet(adoptPtr(gDelayedUpdateScrollInfoSet));
        gDelayedUpdateScrollInfoSet = 0;

        for (DelayedUpdateScrollInfoSet::iterator it = infoSet->begin(); it != infoSet->end(); ++it) {
            RenderBlock* block = *it;
            if (block->hasOverflowClip()) {
                block->layer()->scrollableArea()->updateAfterLayout();
            }
        }
    }
}

void RenderBlock::updateScrollInfoAfterLayout()
{
    if (hasOverflowClip()) {
        if (gDelayUpdateScrollInfo)
            gDelayedUpdateScrollInfoSet->add(this);
        else
            layer()->scrollableArea()->updateAfterLayout();
    }
}

void RenderBlock::layout()
{
    // Table cells call layoutBlock directly, so don't add any logic here.  Put code into
    // layoutBlock().
    layoutBlock(false);

    // It's safe to check for control clip here, since controls can never be table cells.
    // If we have a lightweight clip, there can never be any overflow from children.
    if (hasControlClip() && m_overflow)
        clearLayoutOverflow();

    invalidateBackgroundObscurationStatus();
}

bool RenderBlock::updateImageLoadingPriorities()
{
    Vector<ImageResource*> images;
    appendImagesFromStyle(images, *style());

    if (images.isEmpty())
        return false;

    LayoutRect viewBounds = viewRect();
    LayoutRect objectBounds = absoluteContentBox();
    // The object bounds might be empty right now, so intersects will fail since it doesn't deal
    // with empty rects. Use LayoutRect::contains in that case.
    bool isVisible;
    if (!objectBounds.isEmpty())
        isVisible =  viewBounds.intersects(objectBounds);
    else
        isVisible = viewBounds.contains(objectBounds);

    ResourceLoadPriorityOptimizer::VisibilityStatus status = isVisible ?
        ResourceLoadPriorityOptimizer::Visible : ResourceLoadPriorityOptimizer::NotVisible;

    LayoutRect screenArea;
    if (!objectBounds.isEmpty()) {
        screenArea = viewBounds;
        screenArea.intersect(objectBounds);
    }

    for (Vector<ImageResource*>::iterator it = images.begin(), end = images.end(); it != end; ++it)
        ResourceLoadPriorityOptimizer::resourceLoadPriorityOptimizer()->notifyImageResourceVisibility(*it, status, screenArea);

    return true;
}

bool RenderBlock::widthAvailableToChildrenHasChanged()
{
    bool widthAvailableToChildrenHasChanged = m_hasBorderOrPaddingLogicalWidthChanged;
    m_hasBorderOrPaddingLogicalWidthChanged = false;

    // If we use border-box sizing, have percentage padding, and our parent has changed width then the width available to our children has changed even
    // though our own width has remained the same.
    widthAvailableToChildrenHasChanged |= style()->boxSizing() == BORDER_BOX && needsPreferredWidthsRecalculation() && view()->layoutState()->containingBlockLogicalWidthChanged();

    return widthAvailableToChildrenHasChanged;
}

bool RenderBlock::updateLogicalWidthAndColumnWidth()
{
    LayoutUnit oldWidth = logicalWidth();
    updateLogicalWidth();
    return oldWidth != logicalWidth() || widthAvailableToChildrenHasChanged();
}

void RenderBlock::layoutBlock(bool)
{
    ASSERT_NOT_REACHED();
    clearNeedsLayout();
}

void RenderBlock::addOverflowFromChildren()
{
    if (childrenInline())
        toRenderBlockFlow(this)->addOverflowFromInlineChildren();
    else
        addOverflowFromBlockChildren();
}

void RenderBlock::computeOverflow(LayoutUnit oldClientAfterEdge, bool)
{
    m_overflow.clear();

    // Add overflow from children.
    addOverflowFromChildren();

    // Add in the overflow from positioned objects.
    addOverflowFromPositionedObjects();

    if (hasOverflowClip()) {
        // When we have overflow clip, propagate the original spillout since it will include collapsed bottom margins
        // and bottom padding.  Set the axis we don't care about to be 1, since we want this overflow to always
        // be considered reachable.
        LayoutRect clientRect(noOverflowRect());
        LayoutRect rectToApply;
        rectToApply = LayoutRect(clientRect.x(), clientRect.y(), 1, std::max<LayoutUnit>(0, oldClientAfterEdge - clientRect.y()));
        addLayoutOverflow(rectToApply);
        if (hasRenderOverflow())
            m_overflow->setLayoutClientAfterEdge(oldClientAfterEdge);
    }

    addVisualEffectOverflow();
}

void RenderBlock::addOverflowFromBlockChildren()
{
    for (RenderBox* child = firstChildBox(); child; child = child->nextSiblingBox()) {
        if (!child->isFloatingOrOutOfFlowPositioned())
            addOverflowFromChild(child);
    }
}

void RenderBlock::addOverflowFromPositionedObjects()
{
    TrackedRendererListHashSet* positionedDescendants = positionedObjects();
    if (!positionedDescendants)
        return;

    RenderBox* positionedObject;
    TrackedRendererListHashSet::iterator end = positionedDescendants->end();
    for (TrackedRendererListHashSet::iterator it = positionedDescendants->begin(); it != end; ++it) {
        positionedObject = *it;
        addOverflowFromChild(positionedObject, LayoutSize(positionedObject->x(), positionedObject->y()));
    }
}

bool RenderBlock::createsBlockFormattingContext() const
{
    return isInlineBlock() || isFloatingOrOutOfFlowPositioned() || hasOverflowClip() || isFlexItemIncludingDeprecated() || isDocumentElement();
}

void RenderBlock::updateBlockChildDirtyBitsBeforeLayout(bool relayoutChildren, RenderBox* child)
{
    // FIXME: Technically percentage height objects only need a relayout if their percentage isn't going to be turned into
    // an auto value. Add a method to determine this, so that we can avoid the relayout.
    if (relayoutChildren || (child->hasRelativeLogicalHeight() && !isRenderView()))
        child->setChildNeedsLayout(MarkOnlyThis);

    // If relayoutChildren is set and the child has percentage padding or an embedded content box, we also need to invalidate the childs pref widths.
    if (relayoutChildren && child->needsPreferredWidthsRecalculation())
        child->setPreferredLogicalWidthsDirty(MarkOnlyThis);
}

void RenderBlock::simplifiedNormalFlowLayout()
{
    if (childrenInline()) {
        ListHashSet<RootInlineBox*> lineBoxes;
        for (InlineWalker walker(this); !walker.atEnd(); walker.advance()) {
            RenderObject* o = walker.current();
            if (!o->isOutOfFlowPositioned() && (o->isReplaced() || o->isFloating())) {
                o->layoutIfNeeded();
                if (toRenderBox(o)->inlineBoxWrapper()) {
                    RootInlineBox& box = toRenderBox(o)->inlineBoxWrapper()->root();
                    lineBoxes.add(&box);
                }
            } else if (o->isText() || (o->isRenderInline() && !walker.atEndOfInline())) {
                o->clearNeedsLayout();
            }
        }

        // FIXME: Glyph overflow will get lost in this case, but not really a big deal.
        GlyphOverflowAndFallbackFontsMap textBoxDataMap;
        for (ListHashSet<RootInlineBox*>::const_iterator it = lineBoxes.begin(); it != lineBoxes.end(); ++it) {
            RootInlineBox* box = *it;
            box->computeOverflow(box->lineTop(), box->lineBottom(), textBoxDataMap);
        }
    } else {
        for (RenderBox* box = firstChildBox(); box; box = box->nextSiblingBox()) {
            if (!box->isOutOfFlowPositioned())
                box->layoutIfNeeded();
        }
    }
}

bool RenderBlock::simplifiedLayout()
{
    // Check if we need to do a full layout.
    if (normalChildNeedsLayout() || selfNeedsLayout())
        return false;

    // Check that we actually need to do a simplified layout.
    if (!posChildNeedsLayout() && !(needsSimplifiedNormalFlowLayout() || needsPositionedMovementLayout()))
        return false;


    {
        // LayoutState needs this deliberate scope to pop before paint invalidation.
        LayoutState state(*this, locationOffset());

        if (needsPositionedMovementLayout() && !tryLayoutDoingPositionedMovementOnly())
            return false;

        // Lay out positioned descendants or objects that just need to recompute overflow.
        if (needsSimplifiedNormalFlowLayout())
            simplifiedNormalFlowLayout();

        if (posChildNeedsLayout() || needsPositionedMovementLayout())
            layoutPositionedObjects(false, needsPositionedMovementLayout() ? ForcedLayoutAfterContainingBlockMoved : DefaultLayout);

        // Recompute our overflow information.
        // FIXME: We could do better here by computing a temporary overflow object from layoutPositionedObjects and only
        // updating our overflow if we either used to have overflow or if the new temporary object has overflow.
        // For now just always recompute overflow. This is no worse performance-wise than the old code that called rightmostPosition and
        // lowestPosition on every relayout so it's not a regression.
        // computeOverflow expects the bottom edge before we clamp our height. Since this information isn't available during
        // simplifiedLayout, we cache the value in m_overflow.
        LayoutUnit oldClientAfterEdge = hasRenderOverflow() ? m_overflow->layoutClientAfterEdge() : clientLogicalBottom();
        computeOverflow(oldClientAfterEdge, true);
    }

    updateLayerTransformAfterLayout();

    updateScrollInfoAfterLayout();

    clearNeedsLayout();
    return true;
}

LayoutUnit RenderBlock::marginIntrinsicLogicalWidthForChild(RenderBox* child) const
{
    // A margin has three types: fixed, percentage, and auto (variable).
    // Auto and percentage margins become 0 when computing min/max width.
    // Fixed margins can be added in as is.
    Length marginLeft = child->style()->marginStartUsing(style());
    Length marginRight = child->style()->marginEndUsing(style());
    LayoutUnit margin = 0;
    if (marginLeft.isFixed())
        margin += marginLeft.value();
    if (marginRight.isFixed())
        margin += marginRight.value();
    return margin;
}

void RenderBlock::layoutPositionedObjects(bool relayoutChildren, PositionedLayoutBehavior info)
{
    TrackedRendererListHashSet* positionedDescendants = positionedObjects();
    if (!positionedDescendants)
        return;

    RenderBox* r;
    TrackedRendererListHashSet::iterator end = positionedDescendants->end();
    for (TrackedRendererListHashSet::iterator it = positionedDescendants->begin(); it != end; ++it) {
        r = *it;

        // FIXME: this should only be set from clearNeedsLayout crbug.com/361250
        r->setLayoutDidGetCalled(true);

        SubtreeLayoutScope layoutScope(*r);

        // When a non-positioned block element moves, it may have positioned children that are implicitly positioned relative to the
        // non-positioned block.  Rather than trying to detect all of these movement cases, we just always lay out positioned
        // objects that are positioned implicitly like this.  Such objects are rare, and so in typical DHTML menu usage (where everything is
        // positioned explicitly) this should not incur a performance penalty.
        if (relayoutChildren || (r->style()->hasStaticBlockPosition() && r->parent() != this))
            layoutScope.setChildNeedsLayout(r);

        // If relayoutChildren is set and the child has percentage padding or an embedded content box, we also need to invalidate the childs pref widths.
        if (relayoutChildren && r->needsPreferredWidthsRecalculation())
            r->setPreferredLogicalWidthsDirty(MarkOnlyThis);

        if (info == ForcedLayoutAfterContainingBlockMoved)
            r->setNeedsPositionedMovementLayout();

        r->layoutIfNeeded();
    }
}

void RenderBlock::markPositionedObjectsForLayout()
{
    if (TrackedRendererListHashSet* positionedDescendants = positionedObjects()) {
        TrackedRendererListHashSet::iterator end = positionedDescendants->end();
        for (TrackedRendererListHashSet::iterator it = positionedDescendants->begin(); it != end; ++it)
            (*it)->setChildNeedsLayout();
    }
}

void RenderBlock::paint(PaintInfo& paintInfo, const LayoutPoint& paintOffset)
{
    ANNOTATE_GRAPHICS_CONTEXT(paintInfo, this);

    LayoutPoint adjustedPaintOffset = paintOffset + location();

    PaintPhase phase = paintInfo.phase;

    LayoutRect overflowBox;
    // Check if we need to do anything at all.
    // FIXME: Could eliminate the isDocumentElement() check if we fix background painting so that the RenderView
    // paints the root's background.
    if (!isDocumentElement()) {
        overflowBox = overflowRectForPaintRejection();
        overflowBox.moveBy(adjustedPaintOffset);
        if (!overflowBox.intersects(paintInfo.rect))
            return;
    }

    // There are some cases where not all clipped visual overflow is accounted for.
    // FIXME: reduce the number of such cases.
    ContentsClipBehavior contentsClipBehavior = ForceContentsClip;
    if (hasOverflowClip() && !hasControlClip() && !(shouldPaintSelectionGaps() && phase == PaintPhaseForeground) && !hasCaret())
        contentsClipBehavior = SkipContentsClipIfPossible;

    bool pushedClip = pushContentsClip(paintInfo, adjustedPaintOffset, contentsClipBehavior);
    {
        GraphicsContextCullSaver cullSaver(*paintInfo.context);
        // Cull if we have more than one child and we didn't already clip.
        bool shouldCull = document().settings()->containerCullingEnabled() && !pushedClip && !isDocumentElement()
            && firstChild() && lastChild() && firstChild() != lastChild();
        if (shouldCull)
            cullSaver.cull(overflowBox);

        paintObject(paintInfo, adjustedPaintOffset);
    }
    if (pushedClip)
        popContentsClip(paintInfo, phase, adjustedPaintOffset);

    // Our scrollbar widgets paint exactly when we tell them to, so that they work properly with
    // z-index.  We paint after we painted the background/border, so that the scrollbars will
    // sit above the background/border.
    if (hasOverflowClip() && (phase == PaintPhaseBlockBackground || phase == PaintPhaseChildBlockBackground) && paintInfo.shouldPaintWithinRoot(this) && !paintInfo.paintRootBackgroundOnly())
        layer()->scrollableArea()->paintOverflowControls(paintInfo.context, roundedIntPoint(adjustedPaintOffset), paintInfo.rect, false /* paintingOverlayControls */);
}

void RenderBlock::paintContents(PaintInfo& paintInfo, const LayoutPoint& paintOffset)
{
    // Avoid painting descendants of the root element when stylesheets haven't loaded.  This eliminates FOUC.
    // It's ok not to draw, because later on, when all the stylesheets do load, styleResolverChanged() on the Document
    // will do a full paint invalidation.
    if (document().didLayoutWithPendingStylesheets() && !isRenderView())
        return;

    if (childrenInline())
        m_lineBoxes.paint(this, paintInfo, paintOffset);
    else {
        PaintPhase newPhase = (paintInfo.phase == PaintPhaseChildOutlines) ? PaintPhaseOutline : paintInfo.phase;
        newPhase = (newPhase == PaintPhaseChildBlockBackgrounds) ? PaintPhaseChildBlockBackground : newPhase;

        // We don't paint our own background, but we do let the kids paint their backgrounds.
        PaintInfo paintInfoForChild(paintInfo);
        paintInfoForChild.phase = newPhase;
        paintInfoForChild.updatePaintingRootForChildren(this);
        paintChildren(paintInfoForChild, paintOffset);
    }
}

void RenderBlock::paintChildren(PaintInfo& paintInfo, const LayoutPoint& paintOffset)
{
    for (RenderBox* child = firstChildBox(); child; child = child->nextSiblingBox())
        paintChild(child, paintInfo, paintOffset);
}

void RenderBlock::paintChild(RenderBox* child, PaintInfo& paintInfo, const LayoutPoint& paintOffset)
{
    if (!child->hasSelfPaintingLayer() && !child->isFloating())
        child->paint(paintInfo, paintOffset);
}

void RenderBlock::paintChildAsInlineBlock(RenderBox* child, PaintInfo& paintInfo, const LayoutPoint& paintOffset)
{
    if (!child->hasSelfPaintingLayer() && !child->isFloating())
        paintAsInlineBlock(child, paintInfo, paintOffset);
}

void RenderBlock::paintAsInlineBlock(RenderObject* renderer, PaintInfo& paintInfo, const LayoutPoint& childPoint)
{
    if (paintInfo.phase != PaintPhaseForeground && paintInfo.phase != PaintPhaseSelection)
        return;

    // Paint all phases atomically, as though the element established its own
    // stacking context.  (See Appendix E.2, section 7.2.1.4 on
    // inline block/table/replaced elements in the CSS2.1 specification.)
    // This is also used by other elements (e.g. flex items).
    bool preservePhase = paintInfo.phase == PaintPhaseSelection || paintInfo.phase == PaintPhaseTextClip;
    PaintInfo info(paintInfo);
    info.phase = preservePhase ? paintInfo.phase : PaintPhaseBlockBackground;
    renderer->paint(info, childPoint);
    if (!preservePhase) {
        info.phase = PaintPhaseChildBlockBackgrounds;
        renderer->paint(info, childPoint);
        info.phase = PaintPhaseFloat;
        renderer->paint(info, childPoint);
        info.phase = PaintPhaseForeground;
        renderer->paint(info, childPoint);
        info.phase = PaintPhaseOutline;
        renderer->paint(info, childPoint);
    }
}

static inline bool hasCursorCaret(const FrameSelection& selection, const RenderBlock* block)
{
    return selection.caretRenderer() == block && selection.hasEditableStyle();
}

static inline bool hasDragCaret(const DragCaretController& dragCaretController, const RenderBlock* block)
{
    return dragCaretController.caretRenderer() == block && dragCaretController.isContentEditable();
}

bool RenderBlock::hasCaret() const
{
    return hasCursorCaret(frame()->selection(), this)
        || hasDragCaret(frame()->page()->dragCaretController(), this);
}

void RenderBlock::paintCarets(PaintInfo& paintInfo, const LayoutPoint& paintOffset)
{
    FrameSelection& selection = frame()->selection();
    if (hasCursorCaret(selection, this)) {
        selection.paintCaret(paintInfo.context, paintOffset, paintInfo.rect);
    }

    DragCaretController& dragCaretController = frame()->page()->dragCaretController();
    if (hasDragCaret(dragCaretController, this)) {
        dragCaretController.paintDragCaret(frame(), paintInfo.context, paintOffset, paintInfo.rect);
    }
}

void RenderBlock::paintObject(PaintInfo& paintInfo, const LayoutPoint& paintOffset)
{
    PaintPhase paintPhase = paintInfo.phase;

    // Adjust our painting position if we're inside a scrolled layer (e.g., an overflow:auto div).
    LayoutPoint scrolledOffset = paintOffset;
    if (hasOverflowClip())
        scrolledOffset.move(-scrolledContentOffset());

    // 1. paint background, borders etc
    if (paintPhase == PaintPhaseBlockBackground || paintPhase == PaintPhaseChildBlockBackground) {
        if (hasBoxDecorationBackground())
            paintBoxDecorationBackground(paintInfo, paintOffset);
    }

    if (paintPhase == PaintPhaseMask) {
        paintMask(paintInfo, paintOffset);
        return;
    }

    if (paintPhase == PaintPhaseClippingMask) {
        paintClippingMask(paintInfo, paintOffset);
        return;
    }

    // We're done.  We don't bother painting any children.
    if (paintPhase == PaintPhaseBlockBackground || paintInfo.paintRootBackgroundOnly())
        return;

    // 2. paint contents
    if (paintPhase != PaintPhaseSelfOutline)
        paintContents(paintInfo, scrolledOffset);

    // 3. paint selection
    // FIXME: Make this work with multi column layouts.  For now don't fill gaps.
    paintSelection(paintInfo, scrolledOffset); // Fill in gaps in selection on lines and between blocks.

    // 4. paint floats.
    if (paintPhase == PaintPhaseFloat || paintPhase == PaintPhaseSelection || paintPhase == PaintPhaseTextClip)
        paintFloats(paintInfo, scrolledOffset, paintPhase == PaintPhaseSelection || paintPhase == PaintPhaseTextClip);

    // 5. paint outline.
    if ((paintPhase == PaintPhaseOutline || paintPhase == PaintPhaseSelfOutline) && style()->hasOutline()) {
        // Don't paint focus ring for anonymous block continuation because the
        // inline element having outline-style:auto paints the whole focus ring.
        if (!style()->outlineStyleIsAuto() || !isAnonymousBlockContinuation())
            paintOutline(paintInfo, LayoutRect(paintOffset, size()));
    }

    // 6. paint continuation outlines.
    if ((paintPhase == PaintPhaseOutline || paintPhase == PaintPhaseChildOutlines))
        paintContinuationOutlines(paintInfo, paintOffset);

    // 7. paint caret.
    // If the caret's node's render object's containing block is this block, and the paint action is PaintPhaseForeground,
    // then paint the caret.
    if (paintPhase == PaintPhaseForeground)
        paintCarets(paintInfo, paintOffset);
}

RenderInline* RenderBlock::inlineElementContinuation() const
{
    RenderBoxModelObject* continuation = this->continuation();
    return continuation && continuation->isInline() ? toRenderInline(continuation) : 0;
}

RenderBlock* RenderBlock::blockElementContinuation() const
{
    RenderBoxModelObject* currentContinuation = continuation();
    if (!currentContinuation || currentContinuation->isInline())
        return 0;
    RenderBlock* nextContinuation = toRenderBlock(currentContinuation);
    if (nextContinuation->isAnonymousBlock())
        return nextContinuation->blockElementContinuation();
    return nextContinuation;
}

static ContinuationOutlineTableMap* continuationOutlineTable()
{
    DEFINE_STATIC_LOCAL(ContinuationOutlineTableMap, table, ());
    return &table;
}

void RenderBlock::addContinuationWithOutline(RenderInline* flow)
{
    // We can't make this work if the inline is in a layer.  We'll just rely on the broken
    // way of painting.
    ASSERT(!flow->layer() && !flow->isInlineElementContinuation());

    ContinuationOutlineTableMap* table = continuationOutlineTable();
    ListHashSet<RenderInline*>* continuations = table->get(this);
    if (!continuations) {
        continuations = new ListHashSet<RenderInline*>;
        table->set(this, adoptPtr(continuations));
    }

    continuations->add(flow);
}

bool RenderBlock::paintsContinuationOutline(RenderInline* flow)
{
    ContinuationOutlineTableMap* table = continuationOutlineTable();
    if (table->isEmpty())
        return false;

    ListHashSet<RenderInline*>* continuations = table->get(this);
    if (!continuations)
        return false;

    return continuations->contains(flow);
}

void RenderBlock::paintContinuationOutlines(PaintInfo& info, const LayoutPoint& paintOffset)
{
    RenderInline* inlineCont = inlineElementContinuation();
    if (inlineCont && inlineCont->style()->hasOutline()) {
        RenderInline* inlineRenderer = toRenderInline(inlineCont->node()->renderer());
        RenderBlock* cb = containingBlock();

        bool inlineEnclosedInSelfPaintingLayer = false;
        for (RenderBoxModelObject* box = inlineRenderer; box != cb; box = box->parent()->enclosingBoxModelObject()) {
            if (box->hasSelfPaintingLayer()) {
                inlineEnclosedInSelfPaintingLayer = true;
                break;
            }
        }

        // Do not add continuations for outline painting by our containing block if we are a relative positioned
        // anonymous block (i.e. have our own layer), paint them straightaway instead. This is because a block depends on renderers in its continuation table being
        // in the same layer.
        if (!inlineEnclosedInSelfPaintingLayer && !hasLayer())
            cb->addContinuationWithOutline(inlineRenderer);
        else if (!inlineRenderer->firstLineBox() || (!inlineEnclosedInSelfPaintingLayer && hasLayer()))
            inlineRenderer->paintOutline(info, paintOffset - locationOffset() + inlineRenderer->containingBlock()->location());
    }

    ContinuationOutlineTableMap* table = continuationOutlineTable();
    if (table->isEmpty())
        return;

    OwnPtr<ListHashSet<RenderInline*> > continuations = table->take(this);
    if (!continuations)
        return;

    LayoutPoint accumulatedPaintOffset = paintOffset;
    // Paint each continuation outline.
    ListHashSet<RenderInline*>::iterator end = continuations->end();
    for (ListHashSet<RenderInline*>::iterator it = continuations->begin(); it != end; ++it) {
        // Need to add in the coordinates of the intervening blocks.
        RenderInline* flow = *it;
        RenderBlock* block = flow->containingBlock();
        for ( ; block && block != this; block = block->containingBlock())
            accumulatedPaintOffset.moveBy(block->location());
        ASSERT(block);
        flow->paintOutline(info, accumulatedPaintOffset);
    }
}

bool RenderBlock::shouldPaintSelectionGaps() const
{
    return selectionState() != SelectionNone && isSelectionRoot();
}

bool RenderBlock::isSelectionRoot() const
{
    ASSERT(node() || isAnonymous());

    if (isDocumentElement() || hasOverflowClip()
        || isPositioned() || isFloating()
        || isInlineBlock()
        || hasTransform() || hasMask()
        || isFlexItemIncludingDeprecated())
        return true;

    if (view() && view()->selectionStart()) {
        Node* startElement = view()->selectionStart()->node();
        if (startElement && startElement->rootEditableElement() == node())
            return true;
    }

    return false;
}

GapRects RenderBlock::selectionGapRectsForPaintInvalidation(const RenderLayerModelObject* paintInvalidationContainer)
{
    ASSERT(!needsLayout());

    if (!shouldPaintSelectionGaps())
        return GapRects();

    TransformState transformState(TransformState::ApplyTransformDirection, FloatPoint());
    mapLocalToContainer(paintInvalidationContainer, transformState, ApplyContainerFlip | UseTransforms);
    LayoutPoint offsetFromPaintInvalidationContainer = roundedLayoutPoint(transformState.mappedPoint());

    if (hasOverflowClip())
        offsetFromPaintInvalidationContainer -= scrolledContentOffset();

    LayoutUnit lastTop = 0;
    LayoutUnit lastLeft = logicalLeftSelectionOffset(this, lastTop);
    LayoutUnit lastRight = logicalRightSelectionOffset(this, lastTop);

    return selectionGaps(this, offsetFromPaintInvalidationContainer, IntSize(), lastTop, lastLeft, lastRight);
}

void RenderBlock::paintSelection(PaintInfo& paintInfo, const LayoutPoint& paintOffset)
{
    if (shouldPaintSelectionGaps() && paintInfo.phase == PaintPhaseForeground) {
        LayoutUnit lastTop = 0;
        LayoutUnit lastLeft = logicalLeftSelectionOffset(this, lastTop);
        LayoutUnit lastRight = logicalRightSelectionOffset(this, lastTop);
        GraphicsContextStateSaver stateSaver(*paintInfo.context);

        LayoutRect gapRectsBounds = selectionGaps(this, paintOffset, LayoutSize(), lastTop, lastLeft, lastRight, &paintInfo);
        if (!gapRectsBounds.isEmpty()) {
            RenderLayer* layer = enclosingLayer();
            gapRectsBounds.moveBy(-paintOffset);
            if (!hasLayer()) {
                LayoutRect localBounds(gapRectsBounds);
                gapRectsBounds = localToContainerQuad(FloatRect(localBounds), layer->renderer()).enclosingBoundingBox();
                if (layer->renderer()->hasOverflowClip())
                    gapRectsBounds.move(layer->renderBox()->scrolledContentOffset());
            }
            layer->addBlockSelectionGapsBounds(gapRectsBounds);
        }
    }
}

static void clipOutPositionedObjects(const PaintInfo* paintInfo, const LayoutPoint& offset, TrackedRendererListHashSet* positionedObjects)
{
    if (!positionedObjects)
        return;

    TrackedRendererListHashSet::const_iterator end = positionedObjects->end();
    for (TrackedRendererListHashSet::const_iterator it = positionedObjects->begin(); it != end; ++it) {
        RenderBox* r = *it;
        paintInfo->context->clipOut(IntRect(offset.x() + r->x(), offset.y() + r->y(), r->width(), r->height()));
    }
}

LayoutUnit RenderBlock::blockDirectionOffset(const LayoutSize& offsetFromBlock) const
{
    // FIXME(sky): Remove
    return offsetFromBlock.height();
}

LayoutUnit RenderBlock::inlineDirectionOffset(const LayoutSize& offsetFromBlock) const
{
    // FIXME(sky): Remove
    return offsetFromBlock.width();
}

LayoutRect RenderBlock::logicalRectToPhysicalRect(const LayoutPoint& rootBlockPhysicalPosition, const LayoutRect& logicalRect)
{
    LayoutRect result = logicalRect;
    result.moveBy(rootBlockPhysicalPosition);
    return result;
}

GapRects RenderBlock::selectionGaps(RenderBlock* rootBlock, const LayoutPoint& rootBlockPhysicalPosition, const LayoutSize& offsetFromRootBlock,
                                    LayoutUnit& lastLogicalTop, LayoutUnit& lastLogicalLeft, LayoutUnit& lastLogicalRight, const PaintInfo* paintInfo)
{
    // IMPORTANT: Callers of this method that intend for painting to happen need to do a save/restore.
    // Clip out floating and positioned objects when painting selection gaps.
    if (paintInfo) {
        // Note that we don't clip out overflow for positioned objects.  We just stick to the border box.
        LayoutRect blockRect(offsetFromRootBlock.width(), offsetFromRootBlock.height(), width(), height());
        blockRect.moveBy(rootBlockPhysicalPosition);
        clipOutPositionedObjects(paintInfo, blockRect.location(), positionedObjects());
        if (isDocumentElement()) // The <body> must make sure to examine its containingBlock's positioned objects.
            for (RenderBlock* cb = containingBlock(); cb && !cb->isRenderView(); cb = cb->containingBlock())
                clipOutPositionedObjects(paintInfo, LayoutPoint(cb->x(), cb->y()), cb->positionedObjects());
    }

    // FIXME: overflow: auto/scroll regions need more math here, since painting in the border box is different from painting in the padding box (one is scrolled, the other is
    // fixed).
    GapRects result;
    if (!isRenderBlockFlow()) // FIXME: Make multi-column selection gap filling work someday.
        return result;

    if (hasTransform()) {
        // FIXME: We should learn how to gap fill multiple columns and transforms eventually.
        lastLogicalTop = rootBlock->blockDirectionOffset(offsetFromRootBlock) + logicalHeight();
        lastLogicalLeft = logicalLeftSelectionOffset(rootBlock, logicalHeight());
        lastLogicalRight = logicalRightSelectionOffset(rootBlock, logicalHeight());
        return result;
    }

    if (childrenInline())
        result = toRenderBlockFlow(this)->inlineSelectionGaps(rootBlock, rootBlockPhysicalPosition, offsetFromRootBlock, lastLogicalTop, lastLogicalLeft, lastLogicalRight, paintInfo);
    else
        result = blockSelectionGaps(rootBlock, rootBlockPhysicalPosition, offsetFromRootBlock, lastLogicalTop, lastLogicalLeft, lastLogicalRight, paintInfo);

    // Go ahead and fill the vertical gap all the way to the bottom of our block if the selection extends past our block.
    if (rootBlock == this && (selectionState() != SelectionBoth && selectionState() != SelectionEnd))
        result.uniteCenter(blockSelectionGap(rootBlock, rootBlockPhysicalPosition, offsetFromRootBlock, lastLogicalTop, lastLogicalLeft, lastLogicalRight,
                                             logicalHeight(), paintInfo));
    return result;
}

GapRects RenderBlock::blockSelectionGaps(RenderBlock* rootBlock, const LayoutPoint& rootBlockPhysicalPosition, const LayoutSize& offsetFromRootBlock,
                                         LayoutUnit& lastLogicalTop, LayoutUnit& lastLogicalLeft, LayoutUnit& lastLogicalRight, const PaintInfo* paintInfo)
{
    GapRects result;

    // Go ahead and jump right to the first block child that contains some selected objects.
    RenderBox* curr;
    for (curr = firstChildBox(); curr && curr->selectionState() == SelectionNone; curr = curr->nextSiblingBox()) { }

    for (bool sawSelectionEnd = false; curr && !sawSelectionEnd; curr = curr->nextSiblingBox()) {
        SelectionState childState = curr->selectionState();
        if (childState == SelectionBoth || childState == SelectionEnd)
            sawSelectionEnd = true;

        if (curr->isFloatingOrOutOfFlowPositioned())
            continue; // We must be a normal flow object in order to even be considered.

        if (curr->isRelPositioned() && curr->hasLayer()) {
            // If the relposition offset is anything other than 0, then treat this just like an absolute positioned element.
            // Just disregard it completely.
            LayoutSize relOffset = curr->layer()->offsetForInFlowPosition();
            if (relOffset.width() || relOffset.height())
                continue;
        }

        bool paintsOwnSelection = curr->shouldPaintSelectionGaps();
        bool fillBlockGaps = paintsOwnSelection || (curr->canBeSelectionLeaf() && childState != SelectionNone);
        if (fillBlockGaps) {
            // We need to fill the vertical gap above this object.
            if (childState == SelectionEnd || childState == SelectionInside)
                // Fill the gap above the object.
                result.uniteCenter(blockSelectionGap(rootBlock, rootBlockPhysicalPosition, offsetFromRootBlock, lastLogicalTop, lastLogicalLeft, lastLogicalRight,
                                                     curr->logicalTop(), paintInfo));

            // Only fill side gaps for objects that paint their own selection if we know for sure the selection is going to extend all the way *past*
            // our object.  We know this if the selection did not end inside our object.
            if (paintsOwnSelection && (childState == SelectionStart || sawSelectionEnd))
                childState = SelectionNone;

            // Fill side gaps on this object based off its state.
            bool leftGap, rightGap;
            getSelectionGapInfo(childState, leftGap, rightGap);

            if (leftGap)
                result.uniteLeft(logicalLeftSelectionGap(rootBlock, rootBlockPhysicalPosition, offsetFromRootBlock, this, curr->logicalLeft(), curr->logicalTop(), curr->logicalHeight(), paintInfo));
            if (rightGap)
                result.uniteRight(logicalRightSelectionGap(rootBlock, rootBlockPhysicalPosition, offsetFromRootBlock, this, curr->logicalRight(), curr->logicalTop(), curr->logicalHeight(), paintInfo));

            // Update lastLogicalTop to be just underneath the object.  lastLogicalLeft and lastLogicalRight extend as far as
            // they can without bumping into floating or positioned objects.  Ideally they will go right up
            // to the border of the root selection block.
            lastLogicalTop = rootBlock->blockDirectionOffset(offsetFromRootBlock) + curr->logicalBottom();
            lastLogicalLeft = logicalLeftSelectionOffset(rootBlock, curr->logicalBottom());
            lastLogicalRight = logicalRightSelectionOffset(rootBlock, curr->logicalBottom());
        } else if (childState != SelectionNone)
            // We must be a block that has some selected object inside it.  Go ahead and recur.
            result.unite(toRenderBlock(curr)->selectionGaps(rootBlock, rootBlockPhysicalPosition, LayoutSize(offsetFromRootBlock.width() + curr->x(), offsetFromRootBlock.height() + curr->y()),
                                                            lastLogicalTop, lastLogicalLeft, lastLogicalRight, paintInfo));
    }
    return result;
}

IntRect alignSelectionRectToDevicePixels(LayoutRect& rect)
{
    LayoutUnit roundedX = rect.x().round();
    return IntRect(roundedX, rect.y().round(),
        (rect.maxX() - roundedX).round(),
        snapSizeToPixel(rect.height(), rect.y()));
}

LayoutRect RenderBlock::blockSelectionGap(RenderBlock* rootBlock, const LayoutPoint& rootBlockPhysicalPosition, const LayoutSize& offsetFromRootBlock,
                                          LayoutUnit lastLogicalTop, LayoutUnit lastLogicalLeft, LayoutUnit lastLogicalRight, LayoutUnit logicalBottom, const PaintInfo* paintInfo)
{
    LayoutUnit logicalTop = lastLogicalTop;
    LayoutUnit logicalHeight = rootBlock->blockDirectionOffset(offsetFromRootBlock) + logicalBottom - logicalTop;
    if (logicalHeight <= 0)
        return LayoutRect();

    // Get the selection offsets for the bottom of the gap
    LayoutUnit logicalLeft = std::max(lastLogicalLeft, logicalLeftSelectionOffset(rootBlock, logicalBottom));
    LayoutUnit logicalRight = std::min(lastLogicalRight, logicalRightSelectionOffset(rootBlock, logicalBottom));
    LayoutUnit logicalWidth = logicalRight - logicalLeft;
    if (logicalWidth <= 0)
        return LayoutRect();

    LayoutRect gapRect = rootBlock->logicalRectToPhysicalRect(rootBlockPhysicalPosition, LayoutRect(logicalLeft, logicalTop, logicalWidth, logicalHeight));
    if (paintInfo)
        paintInfo->context->fillRect(alignSelectionRectToDevicePixels(gapRect), selectionBackgroundColor());
    return gapRect;
}

LayoutRect RenderBlock::logicalLeftSelectionGap(RenderBlock* rootBlock, const LayoutPoint& rootBlockPhysicalPosition, const LayoutSize& offsetFromRootBlock,
                                                RenderObject* selObj, LayoutUnit logicalLeft, LayoutUnit logicalTop, LayoutUnit logicalHeight, const PaintInfo* paintInfo)
{
    LayoutUnit rootBlockLogicalTop = rootBlock->blockDirectionOffset(offsetFromRootBlock) + logicalTop;
    LayoutUnit rootBlockLogicalLeft = std::max(logicalLeftSelectionOffset(rootBlock, logicalTop), logicalLeftSelectionOffset(rootBlock, logicalTop + logicalHeight));
    LayoutUnit rootBlockLogicalRight = std::min(rootBlock->inlineDirectionOffset(offsetFromRootBlock) + logicalLeft, std::min(logicalRightSelectionOffset(rootBlock, logicalTop), logicalRightSelectionOffset(rootBlock, logicalTop + logicalHeight)));
    LayoutUnit rootBlockLogicalWidth = rootBlockLogicalRight - rootBlockLogicalLeft;
    if (rootBlockLogicalWidth <= 0)
        return LayoutRect();

    LayoutRect gapRect = rootBlock->logicalRectToPhysicalRect(rootBlockPhysicalPosition, LayoutRect(rootBlockLogicalLeft, rootBlockLogicalTop, rootBlockLogicalWidth, logicalHeight));
    if (paintInfo)
        paintInfo->context->fillRect(alignSelectionRectToDevicePixels(gapRect), selObj->selectionBackgroundColor());
    return gapRect;
}

LayoutRect RenderBlock::logicalRightSelectionGap(RenderBlock* rootBlock, const LayoutPoint& rootBlockPhysicalPosition, const LayoutSize& offsetFromRootBlock,
                                                 RenderObject* selObj, LayoutUnit logicalRight, LayoutUnit logicalTop, LayoutUnit logicalHeight, const PaintInfo* paintInfo)
{
    LayoutUnit rootBlockLogicalTop = rootBlock->blockDirectionOffset(offsetFromRootBlock) + logicalTop;
    LayoutUnit rootBlockLogicalLeft = std::max(rootBlock->inlineDirectionOffset(offsetFromRootBlock) + logicalRight, max(logicalLeftSelectionOffset(rootBlock, logicalTop), logicalLeftSelectionOffset(rootBlock, logicalTop + logicalHeight)));
    LayoutUnit rootBlockLogicalRight = std::min(logicalRightSelectionOffset(rootBlock, logicalTop), logicalRightSelectionOffset(rootBlock, logicalTop + logicalHeight));
    LayoutUnit rootBlockLogicalWidth = rootBlockLogicalRight - rootBlockLogicalLeft;
    if (rootBlockLogicalWidth <= 0)
        return LayoutRect();

    LayoutRect gapRect = rootBlock->logicalRectToPhysicalRect(rootBlockPhysicalPosition, LayoutRect(rootBlockLogicalLeft, rootBlockLogicalTop, rootBlockLogicalWidth, logicalHeight));
    if (paintInfo)
        paintInfo->context->fillRect(alignSelectionRectToDevicePixels(gapRect), selObj->selectionBackgroundColor());
    return gapRect;
}

void RenderBlock::getSelectionGapInfo(SelectionState state, bool& leftGap, bool& rightGap)
{
    bool ltr = style()->isLeftToRightDirection();
    leftGap = (state == RenderObject::SelectionInside) ||
              (state == RenderObject::SelectionEnd && ltr) ||
              (state == RenderObject::SelectionStart && !ltr);
    rightGap = (state == RenderObject::SelectionInside) ||
               (state == RenderObject::SelectionStart && ltr) ||
               (state == RenderObject::SelectionEnd && !ltr);
}

LayoutUnit RenderBlock::logicalLeftSelectionOffset(RenderBlock* rootBlock, LayoutUnit position)
{
    // The border can potentially be further extended by our containingBlock().
    if (rootBlock != this)
        return containingBlock()->logicalLeftSelectionOffset(rootBlock, position + logicalTop());
    return logicalLeftOffsetForContent();
}

LayoutUnit RenderBlock::logicalRightSelectionOffset(RenderBlock* rootBlock, LayoutUnit position)
{
    // The border can potentially be further extended by our containingBlock().
    if (rootBlock != this)
        return containingBlock()->logicalRightSelectionOffset(rootBlock, position + logicalTop());
    return logicalRightOffsetForContent();
}

RenderBlock* RenderBlock::blockBeforeWithinSelectionRoot(LayoutSize& offset) const
{
    if (isSelectionRoot())
        return 0;

    const RenderObject* object = this;
    RenderObject* sibling;
    do {
        sibling = object->previousSibling();
        while (sibling && (!sibling->isRenderBlock() || toRenderBlock(sibling)->isSelectionRoot()))
            sibling = sibling->previousSibling();

        offset -= LayoutSize(toRenderBlock(object)->logicalLeft(), toRenderBlock(object)->logicalTop());
        object = object->parent();
    } while (!sibling && object && object->isRenderBlock() && !toRenderBlock(object)->isSelectionRoot());

    if (!sibling)
        return 0;

    RenderBlock* beforeBlock = toRenderBlock(sibling);

    offset += LayoutSize(beforeBlock->logicalLeft(), beforeBlock->logicalTop());

    RenderObject* child = beforeBlock->lastChild();
    while (child && child->isRenderBlock()) {
        beforeBlock = toRenderBlock(child);
        offset += LayoutSize(beforeBlock->logicalLeft(), beforeBlock->logicalTop());
        child = beforeBlock->lastChild();
    }
    return beforeBlock;
}

void RenderBlock::setSelectionState(SelectionState state)
{
    RenderBox::setSelectionState(state);

    if (inlineBoxWrapper() && canUpdateSelectionOnRootLineBoxes())
        inlineBoxWrapper()->root().setHasSelectedChildren(state != SelectionNone);
}

void RenderBlock::insertIntoTrackedRendererMaps(RenderBox* descendant, TrackedDescendantsMap*& descendantsMap, TrackedContainerMap*& containerMap)
{
    if (!descendantsMap) {
        descendantsMap = new TrackedDescendantsMap;
        containerMap = new TrackedContainerMap;
    }

    TrackedRendererListHashSet* descendantSet = descendantsMap->get(this);
    if (!descendantSet) {
        descendantSet = new TrackedRendererListHashSet;
        descendantsMap->set(this, adoptPtr(descendantSet));
    }
    bool added = descendantSet->add(descendant).isNewEntry;
    if (!added) {
        ASSERT(containerMap->get(descendant));
        ASSERT(containerMap->get(descendant)->contains(this));
        return;
    }

    HashSet<RenderBlock*>* containerSet = containerMap->get(descendant);
    if (!containerSet) {
        containerSet = new HashSet<RenderBlock*>;
        containerMap->set(descendant, adoptPtr(containerSet));
    }
    ASSERT(!containerSet->contains(this));
    containerSet->add(this);
}

void RenderBlock::removeFromTrackedRendererMaps(RenderBox* descendant, TrackedDescendantsMap*& descendantsMap, TrackedContainerMap*& containerMap)
{
    if (!descendantsMap)
        return;

    OwnPtr<HashSet<RenderBlock*> > containerSet = containerMap->take(descendant);
    if (!containerSet)
        return;

    HashSet<RenderBlock*>::iterator end = containerSet->end();
    for (HashSet<RenderBlock*>::iterator it = containerSet->begin(); it != end; ++it) {
        RenderBlock* container = *it;

        // FIXME: Disabling this assert temporarily until we fix the layout
        // bugs associated with positioned objects not properly cleared from
        // their ancestor chain before being moved. See webkit bug 93766.
        // ASSERT(descendant->isDescendantOf(container));

        TrackedDescendantsMap::iterator descendantsMapIterator = descendantsMap->find(container);
        ASSERT(descendantsMapIterator != descendantsMap->end());
        if (descendantsMapIterator == descendantsMap->end())
            continue;
        TrackedRendererListHashSet* descendantSet = descendantsMapIterator->value.get();
        ASSERT(descendantSet->contains(descendant));
        descendantSet->remove(descendant);
        if (descendantSet->isEmpty())
            descendantsMap->remove(descendantsMapIterator);
    }
}

TrackedRendererListHashSet* RenderBlock::positionedObjects() const
{
    if (gPositionedDescendantsMap)
        return gPositionedDescendantsMap->get(this);
    return 0;
}

void RenderBlock::insertPositionedObject(RenderBox* o)
{
    ASSERT(!isAnonymousBlock());
    insertIntoTrackedRendererMaps(o, gPositionedDescendantsMap, gPositionedContainerMap);
}

void RenderBlock::removePositionedObject(RenderBox* o)
{
    removeFromTrackedRendererMaps(o, gPositionedDescendantsMap, gPositionedContainerMap);
}

void RenderBlock::removePositionedObjects(RenderBlock* o, ContainingBlockState containingBlockState)
{
    TrackedRendererListHashSet* positionedDescendants = positionedObjects();
    if (!positionedDescendants)
        return;

    RenderBox* r;

    TrackedRendererListHashSet::iterator end = positionedDescendants->end();

    Vector<RenderBox*, 16> deadObjects;

    for (TrackedRendererListHashSet::iterator it = positionedDescendants->begin(); it != end; ++it) {
        r = *it;
        if (!o || r->isDescendantOf(o)) {
            if (containingBlockState == NewContainingBlock)
                r->setChildNeedsLayout(MarkOnlyThis);

            // It is parent blocks job to add positioned child to positioned objects list of its containing block
            // Parent layout needs to be invalidated to ensure this happens.
            RenderObject* p = r->parent();
            while (p && !p->isRenderBlock())
                p = p->parent();
            if (p)
                p->setChildNeedsLayout();

            deadObjects.append(r);
        }
    }

    for (unsigned i = 0; i < deadObjects.size(); i++)
        removePositionedObject(deadObjects.at(i));
}

void RenderBlock::addPercentHeightDescendant(RenderBox* descendant)
{
    insertIntoTrackedRendererMaps(descendant, gPercentHeightDescendantsMap, gPercentHeightContainerMap);
}

void RenderBlock::removePercentHeightDescendant(RenderBox* descendant)
{
    removeFromTrackedRendererMaps(descendant, gPercentHeightDescendantsMap, gPercentHeightContainerMap);
}

TrackedRendererListHashSet* RenderBlock::percentHeightDescendants() const
{
    return gPercentHeightDescendantsMap ? gPercentHeightDescendantsMap->get(this) : 0;
}

bool RenderBlock::hasPercentHeightContainerMap()
{
    return gPercentHeightContainerMap;
}

bool RenderBlock::hasPercentHeightDescendant(RenderBox* descendant)
{
    // We don't null check gPercentHeightContainerMap since the caller
    // already ensures this and we need to call this function on every
    // descendant in clearPercentHeightDescendantsFrom().
    ASSERT(gPercentHeightContainerMap);
    return gPercentHeightContainerMap->contains(descendant);
}

void RenderBlock::dirtyForLayoutFromPercentageHeightDescendants(SubtreeLayoutScope& layoutScope)
{
    if (!gPercentHeightDescendantsMap)
        return;

    TrackedRendererListHashSet* descendants = gPercentHeightDescendantsMap->get(this);
    if (!descendants)
        return;

    TrackedRendererListHashSet::iterator end = descendants->end();
    for (TrackedRendererListHashSet::iterator it = descendants->begin(); it != end; ++it) {
        RenderBox* box = *it;
        while (box != this) {
            if (box->normalChildNeedsLayout())
                break;
            layoutScope.setChildNeedsLayout(box);
            box = box->containingBlock();
            ASSERT(box);
            if (!box)
                break;
        }
    }
}

void RenderBlock::removePercentHeightDescendantIfNeeded(RenderBox* descendant)
{
    // We query the map directly, rather than looking at style's
    // logicalHeight()/logicalMinHeight()/logicalMaxHeight() since those
    // can change with writing mode/directional changes.
    if (!hasPercentHeightContainerMap())
        return;

    if (!hasPercentHeightDescendant(descendant))
        return;

    removePercentHeightDescendant(descendant);
}

void RenderBlock::clearPercentHeightDescendantsFrom(RenderBox* parent)
{
    ASSERT(gPercentHeightContainerMap);
    for (RenderObject* curr = parent->slowFirstChild(); curr; curr = curr->nextInPreOrder(parent)) {
        if (!curr->isBox())
            continue;

        RenderBox* box = toRenderBox(curr);
        if (!hasPercentHeightDescendant(box))
            continue;

        removePercentHeightDescendant(box);
    }
}

LayoutUnit RenderBlock::textIndentOffset() const
{
    LayoutUnit cw = 0;
    if (style()->textIndent().isPercent())
        cw = containingBlock()->availableLogicalWidth();
    return minimumValueForLength(style()->textIndent(), cw);
}

void RenderBlock::markLinesDirtyInBlockRange(LayoutUnit logicalTop, LayoutUnit logicalBottom, RootInlineBox* highest)
{
    if (logicalTop >= logicalBottom)
        return;

    RootInlineBox* lowestDirtyLine = lastRootBox();
    RootInlineBox* afterLowest = lowestDirtyLine;
    while (lowestDirtyLine && lowestDirtyLine->lineBottomWithLeading() >= logicalBottom && logicalBottom < LayoutUnit::max()) {
        afterLowest = lowestDirtyLine;
        lowestDirtyLine = lowestDirtyLine->prevRootBox();
    }

    while (afterLowest && afterLowest != highest && (afterLowest->lineBottomWithLeading() >= logicalTop || afterLowest->lineBottomWithLeading() < 0)) {
        afterLowest->markDirty();
        afterLowest = afterLowest->prevRootBox();
    }
}

bool RenderBlock::isPointInOverflowControl(HitTestResult& result, const LayoutPoint& locationInContainer, const LayoutPoint& accumulatedOffset)
{
    if (!scrollsOverflow())
        return false;

    return layer()->scrollableArea()->hitTestOverflowControls(result, roundedIntPoint(locationInContainer - toLayoutSize(accumulatedOffset)));
}

Node* RenderBlock::nodeForHitTest() const
{
    // If we are in the margins of block elements that are part of a
    // continuation we're actually still inside the enclosing element
    // that was split. Use the appropriate inner node.
    return isAnonymousBlockContinuation() ? continuation()->node() : node();
}

bool RenderBlock::nodeAtPoint(const HitTestRequest& request, HitTestResult& result, const HitTestLocation& locationInContainer, const LayoutPoint& accumulatedOffset, HitTestAction hitTestAction)
{
    LayoutPoint adjustedLocation(accumulatedOffset + location());
    LayoutSize localOffset = toLayoutSize(adjustedLocation);

    if (!isRenderView()) {
        // Check if we need to do anything at all.
        // If we have clipping, then we can't have any spillout.
        LayoutRect overflowBox = hasOverflowClip() ? borderBoxRect() : visualOverflowRect();
        overflowBox.moveBy(adjustedLocation);
        if (!locationInContainer.intersects(overflowBox))
            return false;
    }

    if ((hitTestAction == HitTestBlockBackground || hitTestAction == HitTestChildBlockBackground)
        && visibleToHitTestRequest(request)
        && isPointInOverflowControl(result, locationInContainer.point(), adjustedLocation)) {
        updateHitTestResult(result, locationInContainer.point() - localOffset);
        // FIXME: isPointInOverflowControl() doesn't handle rect-based tests yet.
        if (!result.addNodeToRectBasedTestResult(nodeForHitTest(), request, locationInContainer))
           return true;
    }

    if (style()->clipPath()) {
        switch (style()->clipPath()->type()) {
        case ClipPathOperation::SHAPE: {
            ShapeClipPathOperation* clipPath = toShapeClipPathOperation(style()->clipPath());
            // FIXME: handle marginBox etc.
            if (!clipPath->path(borderBoxRect()).contains(locationInContainer.point() - localOffset, clipPath->windRule()))
                return false;
            break;
        }
        case ClipPathOperation::REFERENCE:
            break;
        }
    }

    // If we have clipping, then we can't have any spillout.
    bool useOverflowClip = hasOverflowClip() && !hasSelfPaintingLayer();
    bool useClip = (hasControlClip() || useOverflowClip);
    bool checkChildren = !useClip;
    if (!checkChildren) {
        if (hasControlClip()) {
            checkChildren = locationInContainer.intersects(controlClipRect(adjustedLocation));
        } else {
            LayoutRect clipRect = overflowClipRect(adjustedLocation, IncludeOverlayScrollbarSize);
            if (style()->hasBorderRadius())
                checkChildren = locationInContainer.intersects(style()->getRoundedBorderFor(clipRect));
            else
                checkChildren = locationInContainer.intersects(clipRect);
        }
    }
    if (checkChildren) {
        // Hit test descendants first.
        LayoutSize scrolledOffset(localOffset);
        if (hasOverflowClip())
            scrolledOffset -= scrolledContentOffset();

        if (hitTestContents(request, result, locationInContainer, toLayoutPoint(scrolledOffset), hitTestAction)) {
            updateHitTestResult(result, locationInContainer.point() - localOffset);
            return true;
        }
        if (hitTestAction == HitTestFloat && hitTestFloats(request, result, locationInContainer, toLayoutPoint(scrolledOffset)))
            return true;
    }

    // Check if the point is outside radii.
    if (style()->hasBorderRadius()) {
        LayoutRect borderRect = borderBoxRect();
        borderRect.moveBy(adjustedLocation);
        RoundedRect border = style()->getRoundedBorderFor(borderRect);
        if (!locationInContainer.intersects(border))
            return false;
    }

    // Now hit test our background
    if (hitTestAction == HitTestBlockBackground || hitTestAction == HitTestChildBlockBackground) {
        LayoutRect boundsRect(adjustedLocation, size());
        if (visibleToHitTestRequest(request) && locationInContainer.intersects(boundsRect)) {
            updateHitTestResult(result, locationInContainer.point() - localOffset);
            if (!result.addNodeToRectBasedTestResult(nodeForHitTest(), request, locationInContainer, boundsRect))
                return true;
        }
    }

    return false;
}

bool RenderBlock::hitTestContents(const HitTestRequest& request, HitTestResult& result, const HitTestLocation& locationInContainer, const LayoutPoint& accumulatedOffset, HitTestAction hitTestAction)
{
    if (childrenInline()) {
        // We have to hit-test our line boxes.
        if (m_lineBoxes.hitTest(this, request, result, locationInContainer, accumulatedOffset, hitTestAction))
            return true;
    } else {
        // Hit test our children.
        HitTestAction childHitTest = hitTestAction;
        if (hitTestAction == HitTestChildBlockBackgrounds)
            childHitTest = HitTestChildBlockBackground;
        for (RenderBox* child = lastChildBox(); child; child = child->previousSiblingBox()) {
            if (!child->hasSelfPaintingLayer() && !child->isFloating() && child->nodeAtPoint(request, result, locationInContainer, accumulatedOffset, childHitTest))
                return true;
        }
    }

    return false;
}

Position RenderBlock::positionForBox(InlineBox *box, bool start) const
{
    if (!box)
        return Position();

    if (!box->renderer().nonPseudoNode())
        return createLegacyEditingPosition(nonPseudoNode(), start ? caretMinOffset() : caretMaxOffset());

    if (!box->isInlineTextBox())
        return createLegacyEditingPosition(box->renderer().nonPseudoNode(), start ? box->renderer().caretMinOffset() : box->renderer().caretMaxOffset());

    InlineTextBox* textBox = toInlineTextBox(box);
    return createLegacyEditingPosition(box->renderer().nonPseudoNode(), start ? textBox->start() : textBox->start() + textBox->len());
}

static inline bool isEditingBoundary(RenderObject* ancestor, RenderObject* child)
{
    ASSERT(!ancestor || ancestor->nonPseudoNode());
    ASSERT(child && child->nonPseudoNode());
    return !ancestor || !ancestor->parent() || (ancestor->hasLayer() && ancestor->parent()->isRenderView())
        || ancestor->nonPseudoNode()->hasEditableStyle() == child->nonPseudoNode()->hasEditableStyle();
}

// FIXME: This function should go on RenderObject as an instance method. Then
// all cases in which positionForPoint recurs could call this instead to
// prevent crossing editable boundaries. This would require many tests.
static PositionWithAffinity positionForPointRespectingEditingBoundaries(RenderBlock* parent, RenderBox* child, const LayoutPoint& pointInParentCoordinates)
{
    LayoutPoint childLocation = child->location();
    if (child->isRelPositioned())
        childLocation += child->offsetForInFlowPosition();

    // FIXME: This is wrong if the child's writing-mode is different from the parent's.
    LayoutPoint pointInChildCoordinates(toLayoutPoint(pointInParentCoordinates - childLocation));

    // If this is an anonymous renderer, we just recur normally
    Node* childNode = child->nonPseudoNode();
    if (!childNode)
        return child->positionForPoint(pointInChildCoordinates);

    // Otherwise, first make sure that the editability of the parent and child agree.
    // If they don't agree, then we return a visible position just before or after the child
    RenderObject* ancestor = parent;
    while (ancestor && !ancestor->nonPseudoNode())
        ancestor = ancestor->parent();

    // If we can't find an ancestor to check editability on, or editability is unchanged, we recur like normal
    if (isEditingBoundary(ancestor, child))
        return child->positionForPoint(pointInChildCoordinates);

    // Otherwise return before or after the child, depending on if the click was to the logical left or logical right of the child
    LayoutUnit childMiddle = parent->logicalWidthForChild(child) / 2;
    LayoutUnit logicalLeft = pointInChildCoordinates.x();
    if (logicalLeft < childMiddle)
        return ancestor->createPositionWithAffinity(childNode->nodeIndex(), DOWNSTREAM);
    return ancestor->createPositionWithAffinity(childNode->nodeIndex() + 1, UPSTREAM);
}

PositionWithAffinity RenderBlock::positionForPointWithInlineChildren(const LayoutPoint& pointInLogicalContents)
{
    ASSERT(childrenInline());

    if (!firstRootBox())
        return createPositionWithAffinity(0, DOWNSTREAM);

    // look for the closest line box in the root box which is at the passed-in y coordinate
    InlineBox* closestBox = 0;
    RootInlineBox* firstRootBoxWithChildren = 0;
    RootInlineBox* lastRootBoxWithChildren = 0;
    for (RootInlineBox* root = firstRootBox(); root; root = root->nextRootBox()) {
        if (!root->firstLeafChild())
            continue;
        if (!firstRootBoxWithChildren)
            firstRootBoxWithChildren = root;

        if (root->isFirstAfterPageBreak() && (pointInLogicalContents.y() < root->lineTopWithLeading()))
            break;

        lastRootBoxWithChildren = root;

        // check if this root line box is located at this y coordinate
        if (pointInLogicalContents.y() < root->selectionBottom()) {
            closestBox = root->closestLeafChildForLogicalLeftPosition(pointInLogicalContents.x());
            if (closestBox)
                break;
        }
    }

    bool moveCaretToBoundary = document().frame()->editor().behavior().shouldMoveCaretToHorizontalBoundaryWhenPastTopOrBottom();

    if (!moveCaretToBoundary && !closestBox && lastRootBoxWithChildren) {
        // y coordinate is below last root line box, pretend we hit it
        closestBox = lastRootBoxWithChildren->closestLeafChildForLogicalLeftPosition(pointInLogicalContents.x());
    }

    if (closestBox) {
        if (moveCaretToBoundary) {
            LayoutUnit firstRootBoxWithChildrenTop = std::min<LayoutUnit>(firstRootBoxWithChildren->selectionTop(), firstRootBoxWithChildren->logicalTop());
            if (pointInLogicalContents.y() < firstRootBoxWithChildrenTop) {
                InlineBox* box = firstRootBoxWithChildren->firstLeafChild();
                if (box->isLineBreak()) {
                    if (InlineBox* newBox = box->nextLeafChildIgnoringLineBreak())
                        box = newBox;
                }
                // y coordinate is above first root line box, so return the start of the first
                return PositionWithAffinity(positionForBox(box, true), DOWNSTREAM);
            }
        }

        // pass the box a top position that is inside it
        LayoutPoint point(pointInLogicalContents.x(), closestBox->root().blockDirectionPointInLine());
        if (closestBox->renderer().isReplaced())
            return positionForPointRespectingEditingBoundaries(this, &toRenderBox(closestBox->renderer()), point);
        return closestBox->renderer().positionForPoint(point);
    }

    if (lastRootBoxWithChildren) {
        // We hit this case for Mac behavior when the Y coordinate is below the last box.
        ASSERT(moveCaretToBoundary);
        InlineBox* logicallyLastBox;
        if (lastRootBoxWithChildren->getLogicalEndBoxWithNode(logicallyLastBox))
            return PositionWithAffinity(positionForBox(logicallyLastBox, false), DOWNSTREAM);
    }

    // Can't reach this. We have a root line box, but it has no kids.
    // FIXME: This should ASSERT_NOT_REACHED(), but clicking on placeholder text
    // seems to hit this code path.
    return createPositionWithAffinity(0, DOWNSTREAM);
}

static inline bool isChildHitTestCandidate(RenderBox* box)
{
    return box->height() && !box->isFloatingOrOutOfFlowPositioned();
}

PositionWithAffinity RenderBlock::positionForPoint(const LayoutPoint& point)
{
    if (isReplaced()) {
        // FIXME: This seems wrong when the object's writing-mode doesn't match the line's writing-mode.
        LayoutUnit pointLogicalLeft = point.x();
        LayoutUnit pointLogicalTop = point.y();

        if (pointLogicalLeft < 0)
            return createPositionWithAffinity(caretMinOffset(), DOWNSTREAM);
        if (pointLogicalLeft >= logicalWidth())
            return createPositionWithAffinity(caretMaxOffset(), DOWNSTREAM);
        if (pointLogicalTop < 0)
            return createPositionWithAffinity(caretMinOffset(), DOWNSTREAM);
        if (pointLogicalTop >= logicalHeight())
            return createPositionWithAffinity(caretMaxOffset(), DOWNSTREAM);
    }

    LayoutPoint pointInContents = point;
    offsetForContents(pointInContents);
    LayoutPoint pointInLogicalContents(pointInContents);

    if (childrenInline())
        return positionForPointWithInlineChildren(pointInLogicalContents);

    RenderBox* lastCandidateBox = lastChildBox();
    while (lastCandidateBox && !isChildHitTestCandidate(lastCandidateBox))
        lastCandidateBox = lastCandidateBox->previousSiblingBox();

    if (lastCandidateBox) {
        if (pointInLogicalContents.y() > logicalTopForChild(lastCandidateBox)
            || (pointInLogicalContents.y() == logicalTopForChild(lastCandidateBox)))
            return positionForPointRespectingEditingBoundaries(this, lastCandidateBox, pointInContents);

        for (RenderBox* childBox = firstChildBox(); childBox; childBox = childBox->nextSiblingBox()) {
            if (!isChildHitTestCandidate(childBox))
                continue;
            LayoutUnit childLogicalBottom = logicalTopForChild(childBox) + logicalHeightForChild(childBox);
            // We hit child if our click is above the bottom of its padding box (like IE6/7 and FF3).
            if (isChildHitTestCandidate(childBox) && (pointInLogicalContents.y() < childLogicalBottom))
                return positionForPointRespectingEditingBoundaries(this, childBox, pointInContents);
        }
    }

    // We only get here if there are no hit test candidate children below the click.
    return RenderBox::positionForPoint(point);
}

void RenderBlock::offsetForContents(LayoutPoint& offset) const
{
    if (hasOverflowClip())
        offset += scrolledContentOffset();
}

LayoutUnit RenderBlock::availableLogicalWidth() const
{
    return RenderBox::availableLogicalWidth();
}

void RenderBlock::computeIntrinsicLogicalWidths(LayoutUnit& minLogicalWidth, LayoutUnit& maxLogicalWidth) const
{
    if (childrenInline()) {
        // FIXME: Remove this const_cast.
        toRenderBlockFlow(const_cast<RenderBlock*>(this))->computeInlinePreferredLogicalWidths(minLogicalWidth, maxLogicalWidth);
    } else {
        computeBlockPreferredLogicalWidths(minLogicalWidth, maxLogicalWidth);
    }

    maxLogicalWidth = std::max(minLogicalWidth, maxLogicalWidth);

    int scrollbarWidth = instrinsicScrollbarLogicalWidth();
    maxLogicalWidth += scrollbarWidth;
    minLogicalWidth += scrollbarWidth;
}

void RenderBlock::computePreferredLogicalWidths()
{
    ASSERT(preferredLogicalWidthsDirty());

    m_minPreferredLogicalWidth = 0;
    m_maxPreferredLogicalWidth = 0;

    // FIXME: The isFixed() calls here should probably be checking for isSpecified since you
    // should be able to use percentage, calc or viewport relative values for width.
    RenderStyle* styleToUse = style();
    if (styleToUse->logicalWidth().isFixed() && styleToUse->logicalWidth().value() >= 0)
        m_minPreferredLogicalWidth = m_maxPreferredLogicalWidth = adjustContentBoxLogicalWidthForBoxSizing(styleToUse->logicalWidth().value());
    else
        computeIntrinsicLogicalWidths(m_minPreferredLogicalWidth, m_maxPreferredLogicalWidth);

    if (styleToUse->logicalMinWidth().isFixed() && styleToUse->logicalMinWidth().value() > 0) {
        m_maxPreferredLogicalWidth = std::max(m_maxPreferredLogicalWidth, adjustContentBoxLogicalWidthForBoxSizing(styleToUse->logicalMinWidth().value()));
        m_minPreferredLogicalWidth = std::max(m_minPreferredLogicalWidth, adjustContentBoxLogicalWidthForBoxSizing(styleToUse->logicalMinWidth().value()));
    }

    if (styleToUse->logicalMaxWidth().isFixed()) {
        m_maxPreferredLogicalWidth = std::min(m_maxPreferredLogicalWidth, adjustContentBoxLogicalWidthForBoxSizing(styleToUse->logicalMaxWidth().value()));
        m_minPreferredLogicalWidth = std::min(m_minPreferredLogicalWidth, adjustContentBoxLogicalWidthForBoxSizing(styleToUse->logicalMaxWidth().value()));
    }

    LayoutUnit borderAndPadding = borderAndPaddingLogicalWidth();
    m_minPreferredLogicalWidth += borderAndPadding;
    m_maxPreferredLogicalWidth += borderAndPadding;

    clearPreferredLogicalWidthsDirty();
}

void RenderBlock::computeBlockPreferredLogicalWidths(LayoutUnit& minLogicalWidth, LayoutUnit& maxLogicalWidth) const
{
    RenderStyle* styleToUse = style();
    bool nowrap = styleToUse->whiteSpace() == NOWRAP;

    RenderObject* child = firstChild();
    RenderBlock* containingBlock = this->containingBlock();
    LayoutUnit floatLeftWidth = 0, floatRightWidth = 0;
    while (child) {
        // Positioned children don't affect the min/max width
        if (child->isOutOfFlowPositioned()) {
            child = child->nextSibling();
            continue;
        }

        RefPtr<RenderStyle> childStyle = child->style();
        if (child->isFloating() || (child->isBox() && toRenderBox(child)->avoidsFloats())) {
            LayoutUnit floatTotalWidth = floatLeftWidth + floatRightWidth;
            if (childStyle->clear() & CLEFT) {
                maxLogicalWidth = std::max(floatTotalWidth, maxLogicalWidth);
                floatLeftWidth = 0;
            }
            if (childStyle->clear() & CRIGHT) {
                maxLogicalWidth = std::max(floatTotalWidth, maxLogicalWidth);
                floatRightWidth = 0;
            }
        }

        // A margin basically has three types: fixed, percentage, and auto (variable).
        // Auto and percentage margins simply become 0 when computing min/max width.
        // Fixed margins can be added in as is.
        Length startMarginLength = childStyle->marginStartUsing(styleToUse);
        Length endMarginLength = childStyle->marginEndUsing(styleToUse);
        LayoutUnit margin = 0;
        LayoutUnit marginStart = 0;
        LayoutUnit marginEnd = 0;
        if (startMarginLength.isFixed())
            marginStart += startMarginLength.value();
        if (endMarginLength.isFixed())
            marginEnd += endMarginLength.value();
        margin = marginStart + marginEnd;

        LayoutUnit childMinPreferredLogicalWidth = child->minPreferredLogicalWidth();
        LayoutUnit childMaxPreferredLogicalWidth = child->maxPreferredLogicalWidth();

        LayoutUnit w = childMinPreferredLogicalWidth + margin;
        minLogicalWidth = std::max(w, minLogicalWidth);

        // IE ignores tables for calculation of nowrap. Makes some sense.
        if (nowrap)
            maxLogicalWidth = std::max(w, maxLogicalWidth);

        w = childMaxPreferredLogicalWidth + margin;

        if (!child->isFloating()) {
            if (child->isBox() && toRenderBox(child)->avoidsFloats()) {
                // Determine a left and right max value based off whether or not the floats can fit in the
                // margins of the object.  For negative margins, we will attempt to overlap the float if the negative margin
                // is smaller than the float width.
                bool ltr = containingBlock ? containingBlock->style()->isLeftToRightDirection() : styleToUse->isLeftToRightDirection();
                LayoutUnit marginLogicalLeft = ltr ? marginStart : marginEnd;
                LayoutUnit marginLogicalRight = ltr ? marginEnd : marginStart;
                LayoutUnit maxLeft = marginLogicalLeft > 0 ? std::max(floatLeftWidth, marginLogicalLeft) : floatLeftWidth + marginLogicalLeft;
                LayoutUnit maxRight = marginLogicalRight > 0 ? std::max(floatRightWidth, marginLogicalRight) : floatRightWidth + marginLogicalRight;
                w = childMaxPreferredLogicalWidth + maxLeft + maxRight;
                w = std::max(w, floatLeftWidth + floatRightWidth);
            } else {
                maxLogicalWidth = std::max(floatLeftWidth + floatRightWidth, maxLogicalWidth);
            }
            floatLeftWidth = floatRightWidth = 0;
        }

        if (child->isFloating()) {
            if (childStyle->floating() == LeftFloat)
                floatLeftWidth += w;
            else
                floatRightWidth += w;
        } else {
            maxLogicalWidth = std::max(w, maxLogicalWidth);
        }

        child = child->nextSibling();
    }

    // Always make sure these values are non-negative.
    minLogicalWidth = std::max<LayoutUnit>(0, minLogicalWidth);
    maxLogicalWidth = std::max<LayoutUnit>(0, maxLogicalWidth);

    maxLogicalWidth = std::max(floatLeftWidth + floatRightWidth, maxLogicalWidth);
}

bool RenderBlock::hasLineIfEmpty() const
{
    return node() && node()->isRootEditableElement();
}

LayoutUnit RenderBlock::lineHeight(bool firstLine, LineDirectionMode direction, LinePositionMode linePositionMode) const
{
    // Inline blocks are replaced elements. Otherwise, just pass off to
    // the base class.  If we're being queried as though we're the root line
    // box, then the fact that we're an inline-block is irrelevant, and we behave
    // just like a block.
    if (isReplaced() && linePositionMode == PositionOnContainingLine)
        return RenderBox::lineHeight(firstLine, direction, linePositionMode);

    RenderStyle* s = style(firstLine && document().styleEngine()->usesFirstLineRules());
    return s->computedLineHeight();
}

int RenderBlock::beforeMarginInLineDirection(LineDirectionMode direction) const
{
    return direction == HorizontalLine ? marginTop() : marginRight();
}

int RenderBlock::baselinePosition(FontBaseline baselineType, bool firstLine, LineDirectionMode direction, LinePositionMode linePositionMode) const
{
    // Inline blocks are replaced elements. Otherwise, just pass off to
    // the base class.  If we're being queried as though we're the root line
    // box, then the fact that we're an inline-block is irrelevant, and we behave
    // just like a block.
    if (isInline() && linePositionMode == PositionOnContainingLine) {
        // CSS2.1 states that the baseline of an inline block is the baseline of the last line box in
        // the normal flow.  We make an exception for marquees, since their baselines are meaningless
        // (the content inside them moves).  This matches WinIE as well, which just bottom-aligns them.
        // We also give up on finding a baseline if we have a vertical scrollbar, or if we are scrolled
        // vertically (e.g., an overflow:hidden block that has had scrollTop moved).
        bool ignoreBaseline = (layer() && layer()->scrollableArea() && ((direction == HorizontalLine ? (layer()->scrollableArea()->verticalScrollbar() || layer()->scrollableArea()->scrollYOffset())
            : (layer()->scrollableArea()->horizontalScrollbar() || layer()->scrollableArea()->scrollXOffset()))));

        int baselinePos = ignoreBaseline ? -1 : inlineBlockBaseline(direction);

        if (baselinePos != -1)
            return beforeMarginInLineDirection(direction) + baselinePos;

        return RenderBox::baselinePosition(baselineType, firstLine, direction, linePositionMode);
    }

    // If we're not replaced, we'll only get called with PositionOfInteriorLineBoxes.
    // Note that inline-block counts as replaced here.
    ASSERT(linePositionMode == PositionOfInteriorLineBoxes);

    const FontMetrics& fontMetrics = style(firstLine)->fontMetrics();
    return fontMetrics.ascent(baselineType) + (lineHeight(firstLine, direction, linePositionMode) - fontMetrics.height()) / 2;
}

LayoutUnit RenderBlock::minLineHeightForReplacedRenderer(bool isFirstLine, LayoutUnit replacedHeight) const
{
    if (!(style(isFirstLine)->lineBoxContain() & LineBoxContainBlock))
        return 0;

    return std::max<LayoutUnit>(replacedHeight, lineHeight(isFirstLine, HorizontalLine, PositionOfInteriorLineBoxes));
}

int RenderBlock::firstLineBoxBaseline() const
{
    if (childrenInline()) {
        if (firstLineBox())
            return firstLineBox()->logicalTop() + style(true)->fontMetrics().ascent(firstRootBox()->baselineType());
        else
            return -1;
    }
    else {
        for (RenderBox* curr = firstChildBox(); curr; curr = curr->nextSiblingBox()) {
            if (!curr->isFloatingOrOutOfFlowPositioned()) {
                int result = curr->firstLineBoxBaseline();
                if (result != -1)
                    return curr->logicalTop() + result; // Translate to our coordinate space.
            }
        }
    }

    return -1;
}

int RenderBlock::inlineBlockBaseline(LineDirectionMode direction) const
{
    if (!style()->isOverflowVisible()) {
        // We are not calling RenderBox::baselinePosition here because the caller should add the margin-top/margin-right, not us.
        return direction == HorizontalLine ? height() + m_marginBox.bottom() : width() + m_marginBox.left();
    }

    return lastLineBoxBaseline(direction);
}

int RenderBlock::lastLineBoxBaseline(LineDirectionMode lineDirection) const
{
    if (childrenInline()) {
        if (!firstLineBox() && hasLineIfEmpty()) {
            const FontMetrics& fontMetrics = firstLineStyle()->fontMetrics();
            return fontMetrics.ascent()
                 + (lineHeight(true, lineDirection, PositionOfInteriorLineBoxes) - fontMetrics.height()) / 2
                 + (lineDirection == HorizontalLine ? borderTop() + paddingTop() : borderRight() + paddingRight());
        }
        if (lastLineBox())
            return lastLineBox()->logicalTop() + style(lastLineBox() == firstLineBox())->fontMetrics().ascent(lastRootBox()->baselineType());
        return -1;
    } else {
        bool haveNormalFlowChild = false;
        for (RenderBox* curr = lastChildBox(); curr; curr = curr->previousSiblingBox()) {
            if (!curr->isFloatingOrOutOfFlowPositioned()) {
                haveNormalFlowChild = true;
                int result = curr->inlineBlockBaseline(lineDirection);
                if (result != -1)
                    return curr->logicalTop() + result; // Translate to our coordinate space.
            }
        }
        if (!haveNormalFlowChild && hasLineIfEmpty()) {
            const FontMetrics& fontMetrics = firstLineStyle()->fontMetrics();
            return fontMetrics.ascent()
                 + (lineHeight(true, lineDirection, PositionOfInteriorLineBoxes) - fontMetrics.height()) / 2
                 + (lineDirection == HorizontalLine ? borderTop() + paddingTop() : borderRight() + paddingRight());
        }
    }

    return -1;
}

RenderBlock* RenderBlock::firstLineBlock() const
{
    RenderBlock* firstLineBlock = const_cast<RenderBlock*>(this);
    bool hasPseudo = false;
    while (true) {
        // FIXME(sky): Remove all this.
        hasPseudo = false;
        if (hasPseudo)
            break;
        RenderObject* parentBlock = firstLineBlock->parent();
        if (firstLineBlock->isReplaced() || firstLineBlock->isFloating()
            || !parentBlock
            || !parentBlock->isRenderBlockFlow())
            break;
        ASSERT_WITH_SECURITY_IMPLICATION(parentBlock->isRenderBlock());
        if (toRenderBlock(parentBlock)->firstChild() != firstLineBlock)
            break;
        firstLineBlock = toRenderBlock(parentBlock);
    }

    if (!hasPseudo)
        return 0;

    return firstLineBlock;
}

// Helper methods for obtaining the last line, computing line counts and heights for line counts
// (crawling into blocks).
static bool shouldCheckLines(RenderObject* obj)
{
    return !obj->isFloatingOrOutOfFlowPositioned()
        && obj->isRenderBlock() && obj->style()->height().isAuto();
}

static int getHeightForLineCount(RenderBlock* block, int l, bool includeBottom, int& count)
{
    if (block->isRenderBlockFlow() && block->childrenInline()) {
        for (RootInlineBox* box = toRenderBlockFlow(block)->firstRootBox(); box; box = box->nextRootBox()) {
            if (++count == l)
                return box->lineBottom() + (includeBottom ? (block->borderBottom() + block->paddingBottom()) : LayoutUnit());
        }
    } else {
        RenderBox* normalFlowChildWithoutLines = 0;
        for (RenderBox* obj = block->firstChildBox(); obj; obj = obj->nextSiblingBox()) {
            if (shouldCheckLines(obj)) {
                int result = getHeightForLineCount(toRenderBlock(obj), l, false, count);
                if (result != -1)
                    return result + obj->y() + (includeBottom ? (block->borderBottom() + block->paddingBottom()) : LayoutUnit());
            } else if (!obj->isFloatingOrOutOfFlowPositioned()) {
                normalFlowChildWithoutLines = obj;
            }
        }
        if (normalFlowChildWithoutLines && l == 0)
            return normalFlowChildWithoutLines->y() + normalFlowChildWithoutLines->height();
    }

    return -1;
}

RootInlineBox* RenderBlock::lineAtIndex(int i) const
{
    ASSERT(i >= 0);

    if (childrenInline()) {
        for (RootInlineBox* box = firstRootBox(); box; box = box->nextRootBox())
            if (!i--)
                return box;
    } else {
        for (RenderObject* child = firstChild(); child; child = child->nextSibling()) {
            if (!shouldCheckLines(child))
                continue;
            if (RootInlineBox* box = toRenderBlock(child)->lineAtIndex(i))
                return box;
        }
    }

    return 0;
}

int RenderBlock::lineCount(const RootInlineBox* stopRootInlineBox, bool* found) const
{
    int count = 0;
    if (childrenInline()) {
        for (RootInlineBox* box = firstRootBox(); box; box = box->nextRootBox()) {
            count++;
            if (box == stopRootInlineBox) {
                if (found)
                    *found = true;
                break;
            }
        }
    } else {
        for (RenderObject* obj = firstChild(); obj; obj = obj->nextSibling())
            if (shouldCheckLines(obj)) {
                bool recursiveFound = false;
                count += toRenderBlock(obj)->lineCount(stopRootInlineBox, &recursiveFound);
                if (recursiveFound) {
                    if (found)
                        *found = true;
                    break;
                }
            }
    }
    return count;
}

int RenderBlock::heightForLineCount(int l)
{
    int count = 0;
    return getHeightForLineCount(this, l, true, count);
}

void RenderBlock::clearTruncation()
{
    if (childrenInline() && hasMarkupTruncation()) {
        setHasMarkupTruncation(false);
        for (RootInlineBox* box = firstRootBox(); box; box = box->nextRootBox())
            box->clearTruncation();
    } else {
        for (RenderObject* obj = firstChild(); obj; obj = obj->nextSibling()) {
            if (shouldCheckLines(obj))
                toRenderBlock(obj)->clearTruncation();
        }
    }
}

void RenderBlock::absoluteRects(Vector<IntRect>& rects, const LayoutPoint& accumulatedOffset) const
{
    // For blocks inside inlines, we go ahead and include margins so that we run right up to the
    // inline boxes above and below us (thus getting merged with them to form a single irregular
    // shape).
    if (isAnonymousBlockContinuation()) {
        // FIXME: This is wrong for block-flows that are horizontal.
        // https://bugs.webkit.org/show_bug.cgi?id=46781
        rects.append(pixelSnappedIntRect(accumulatedOffset.x(), accumulatedOffset.y() - collapsedMarginBefore(),
                                width(), height() + collapsedMarginBefore() + collapsedMarginAfter()));
        continuation()->absoluteRects(rects, accumulatedOffset - toLayoutSize(location() +
                inlineElementContinuation()->containingBlock()->location()));
    } else
        rects.append(pixelSnappedIntRect(accumulatedOffset, size()));
}

void RenderBlock::absoluteQuads(Vector<FloatQuad>& quads) const
{
    // For blocks inside inlines, we go ahead and include margins so that we run right up to the
    // inline boxes above and below us (thus getting merged with them to form a single irregular
    // shape).
    if (isAnonymousBlockContinuation()) {
        // FIXME: This is wrong for block-flows that are horizontal.
        // https://bugs.webkit.org/show_bug.cgi?id=46781
        FloatRect localRect(0, -collapsedMarginBefore().toFloat(),
            width().toFloat(), (height() + collapsedMarginBefore() + collapsedMarginAfter()).toFloat());
        quads.append(localToAbsoluteQuad(localRect, 0 /* mode */));
        continuation()->absoluteQuads(quads);
    } else {
        quads.append(RenderBox::localToAbsoluteQuad(FloatRect(0, 0, width().toFloat(), height().toFloat()), 0 /* mode */));
    }
}

LayoutRect RenderBlock::rectWithOutlineForPaintInvalidation(const RenderLayerModelObject* paintInvalidationContainer, LayoutUnit outlineWidth, const PaintInvalidationState* paintInvalidationState) const
{
    LayoutRect r(RenderBox::rectWithOutlineForPaintInvalidation(paintInvalidationContainer, outlineWidth, paintInvalidationState));
    if (isAnonymousBlockContinuation())
        r.inflateY(collapsedMarginBefore()); // FIXME: This is wrong for block-flows that are horizontal.
    return r;
}

RenderObject* RenderBlock::hoverAncestor() const
{
    return isAnonymousBlockContinuation() ? continuation() : RenderBox::hoverAncestor();
}

void RenderBlock::childBecameNonInline(RenderObject*)
{
    makeChildrenNonInline();
    if (isAnonymousBlock() && parent() && parent()->isRenderBlock())
        toRenderBlock(parent())->removeLeftoverAnonymousBlock(this);
    // |this| may be dead here
}

void RenderBlock::updateHitTestResult(HitTestResult& result, const LayoutPoint& point)
{
    if (result.innerNode())
        return;

    if (Node* n = nodeForHitTest()) {
        result.setInnerNode(n);
        if (!result.innerNonSharedNode())
            result.setInnerNonSharedNode(n);
        result.setLocalPoint(point);
    }
}

LayoutRect RenderBlock::localCaretRect(InlineBox* inlineBox, int caretOffset, LayoutUnit* extraWidthToEndOfLine)
{
    // Do the normal calculation in most cases.
    if (firstChild())
        return RenderBox::localCaretRect(inlineBox, caretOffset, extraWidthToEndOfLine);

    LayoutRect caretRect = localCaretRectForEmptyElement(width(), textIndentOffset());

    if (extraWidthToEndOfLine)
        *extraWidthToEndOfLine = width() - caretRect.maxX();

    return caretRect;
}

void RenderBlock::addFocusRingRects(Vector<IntRect>& rects, const LayoutPoint& additionalOffset, const RenderLayerModelObject* paintContainer) const
{
    // For blocks inside inlines, we go ahead and include margins so that we run right up to the
    // inline boxes above and below us (thus getting merged with them to form a single irregular
    // shape).
    if (inlineElementContinuation()) {
        // FIXME: This check really isn't accurate.
        bool nextInlineHasLineBox = inlineElementContinuation()->firstLineBox();
        // FIXME: This is wrong. The principal renderer may not be the continuation preceding this block.
        // FIXME: This is wrong for block-flows that are horizontal.
        // https://bugs.webkit.org/show_bug.cgi?id=46781
        bool prevInlineHasLineBox = toRenderInline(inlineElementContinuation()->node()->renderer())->firstLineBox();
        LayoutUnit topMargin = prevInlineHasLineBox ? collapsedMarginBefore() : LayoutUnit();
        LayoutUnit bottomMargin = nextInlineHasLineBox ? collapsedMarginAfter() : LayoutUnit();
        LayoutRect rect(additionalOffset.x(), additionalOffset.y() - topMargin, width(), height() + topMargin + bottomMargin);
        if (!rect.isEmpty())
            rects.append(pixelSnappedIntRect(rect));
    } else if (width() && height()) {
        rects.append(pixelSnappedIntRect(additionalOffset, size()));
    }

    if (!hasOverflowClip() && !hasControlClip()) {
        for (RootInlineBox* curr = firstRootBox(); curr; curr = curr->nextRootBox()) {
            LayoutUnit top = std::max<LayoutUnit>(curr->lineTop(), curr->top());
            LayoutUnit bottom = std::min<LayoutUnit>(curr->lineBottom(), curr->top() + curr->height());
            LayoutRect rect(additionalOffset.x() + curr->x(), additionalOffset.y() + top, curr->width(), bottom - top);
            if (!rect.isEmpty())
                rects.append(pixelSnappedIntRect(rect));
        }

        addChildFocusRingRects(rects, additionalOffset, paintContainer);
    }

    if (inlineElementContinuation())
        inlineElementContinuation()->addFocusRingRects(rects, flooredLayoutPoint(additionalOffset + inlineElementContinuation()->containingBlock()->location() - location()), paintContainer);
}

void RenderBlock::computeSelfHitTestRects(Vector<LayoutRect>& rects, const LayoutPoint& layerOffset) const
{
    RenderBox::computeSelfHitTestRects(rects, layerOffset);

    if (hasHorizontalLayoutOverflow() || hasVerticalLayoutOverflow()) {
        for (RootInlineBox* curr = firstRootBox(); curr; curr = curr->nextRootBox()) {
            LayoutUnit top = std::max<LayoutUnit>(curr->lineTop(), curr->top());
            LayoutUnit bottom = std::min<LayoutUnit>(curr->lineBottom(), curr->top() + curr->height());
            LayoutRect rect(layerOffset.x() + curr->x(), layerOffset.y() + top, curr->width(), bottom - top);
            // It's common for this rect to be entirely contained in our box, so exclude that simple case.
            if (!rect.isEmpty() && (rects.isEmpty() || !rects[0].contains(rect)))
                rects.append(rect);
        }
    }
}

RenderBox* RenderBlock::createAnonymousBoxWithSameTypeAs(const RenderObject* parent) const
{
    return createAnonymousWithParentRendererAndDisplay(parent, style()->display());
}

LayoutUnit RenderBlock::collapsedMarginBeforeForChild(const RenderBox* child) const
{
    // FIXME(sky): Remove
    return child->collapsedMarginBefore();
}

LayoutUnit RenderBlock::collapsedMarginAfterForChild(const  RenderBox* child) const
{
    // FIXME(sky): Remove
    return child->collapsedMarginAfter();
}

bool RenderBlock::hasMarginBeforeQuirk(const RenderBox* child) const
{
    return child->isRenderBlock() ? toRenderBlock(child)->hasMarginBeforeQuirk() : child->style()->hasMarginBeforeQuirk();
}

bool RenderBlock::hasMarginAfterQuirk(const RenderBox* child) const
{
    return child->isRenderBlock() ? toRenderBlock(child)->hasMarginAfterQuirk() : child->style()->hasMarginAfterQuirk();
}

const char* RenderBlock::renderName() const
{
    if (isFloating())
        return "RenderBlock (floating)";
    if (isOutOfFlowPositioned())
        return "RenderBlock (positioned)";
    if (isAnonymousBlock())
        return "RenderBlock (anonymous)";
    if (isAnonymous())
        return "RenderBlock (generated)";
    if (isRelPositioned())
        return "RenderBlock (relative positioned)";
    return "RenderBlock";
}

RenderBlock* RenderBlock::createAnonymousWithParentRendererAndDisplay(const RenderObject* parent, EDisplay display)
{
    // FIXME: Do we need to convert all our inline displays to block-type in the anonymous logic ?
    EDisplay newDisplay;
    RenderBlock* newBox = 0;
    if (display == FLEX || display == INLINE_FLEX) {
        newBox = RenderFlexibleBox::createAnonymous(&parent->document());
        newDisplay = FLEX;
    } else {
        newBox = RenderBlockFlow::createAnonymous(&parent->document());
        newDisplay = BLOCK;
    }

    RefPtr<RenderStyle> newStyle = RenderStyle::createAnonymousStyleWithDisplay(parent->style(), newDisplay);
    parent->updateAnonymousChildStyle(newBox, newStyle.get());
    newBox->setStyle(newStyle.release());
    return newBox;
}

static bool recalcNormalFlowChildOverflowIfNeeded(RenderObject* renderer)
{
    if (renderer->isOutOfFlowPositioned() || !renderer->needsOverflowRecalcAfterStyleChange())
        return false;

    ASSERT(renderer->isRenderBlock());
    return toRenderBlock(renderer)->recalcOverflowAfterStyleChange();
}

bool RenderBlock::recalcChildOverflowAfterStyleChange()
{
    ASSERT(childNeedsOverflowRecalcAfterStyleChange());
    setChildNeedsOverflowRecalcAfterStyleChange(false);

    bool childrenOverflowChanged = false;

    if (childrenInline()) {
        ListHashSet<RootInlineBox*> lineBoxes;
        for (InlineWalker walker(this); !walker.atEnd(); walker.advance()) {
            RenderObject* renderer = walker.current();
            if (recalcNormalFlowChildOverflowIfNeeded(renderer)) {
                childrenOverflowChanged = true;
                if (InlineBox* inlineBoxWrapper = toRenderBlock(renderer)->inlineBoxWrapper())
                    lineBoxes.add(&inlineBoxWrapper->root());
            }
        }

        // FIXME: Glyph overflow will get lost in this case, but not really a big deal.
        GlyphOverflowAndFallbackFontsMap textBoxDataMap;
        for (ListHashSet<RootInlineBox*>::const_iterator it = lineBoxes.begin(); it != lineBoxes.end(); ++it) {
            RootInlineBox* box = *it;
            box->computeOverflow(box->lineTop(), box->lineBottom(), textBoxDataMap);
        }
    } else {
        for (RenderBox* box = firstChildBox(); box; box = box->nextSiblingBox()) {
            if (recalcNormalFlowChildOverflowIfNeeded(box))
                childrenOverflowChanged = true;
        }
    }

    TrackedRendererListHashSet* positionedDescendants = positionedObjects();
    if (!positionedDescendants)
        return childrenOverflowChanged;

    TrackedRendererListHashSet::iterator end = positionedDescendants->end();
    for (TrackedRendererListHashSet::iterator it = positionedDescendants->begin(); it != end; ++it) {
        RenderBox* box = *it;

        if (!box->needsOverflowRecalcAfterStyleChange())
            continue;
        RenderBlock* block = toRenderBlock(box);
        if (!block->recalcOverflowAfterStyleChange())
            continue;

        childrenOverflowChanged = true;
    }
    return childrenOverflowChanged;
}

bool RenderBlock::recalcOverflowAfterStyleChange()
{
    ASSERT(needsOverflowRecalcAfterStyleChange());

    bool childrenOverflowChanged = false;
    if (childNeedsOverflowRecalcAfterStyleChange())
        childrenOverflowChanged = recalcChildOverflowAfterStyleChange();

    if (!selfNeedsOverflowRecalcAfterStyleChange() && !childrenOverflowChanged)
        return false;

    setSelfNeedsOverflowRecalcAfterStyleChange(false);
    // If the current block needs layout, overflow will be recalculated during
    // layout time anyway. We can safely exit here.
    if (needsLayout())
        return false;

    LayoutUnit oldClientAfterEdge = hasRenderOverflow() ? m_overflow->layoutClientAfterEdge() : clientLogicalBottom();
    computeOverflow(oldClientAfterEdge, true);

    if (hasOverflowClip())
        layer()->scrollableArea()->updateAfterOverflowRecalc();

    return !hasOverflowClip();
}

#if ENABLE(ASSERT)
void RenderBlock::checkPositionedObjectsNeedLayout()
{
    if (!gPositionedDescendantsMap)
        return;

    if (TrackedRendererListHashSet* positionedDescendantSet = positionedObjects()) {
        TrackedRendererListHashSet::const_iterator end = positionedDescendantSet->end();
        for (TrackedRendererListHashSet::const_iterator it = positionedDescendantSet->begin(); it != end; ++it) {
            RenderBox* currBox = *it;
            ASSERT(!currBox->needsLayout());
        }
    }
}

#endif

#ifndef NDEBUG

void RenderBlock::showLineTreeAndMark(const InlineBox* markedBox1, const char* markedLabel1, const InlineBox* markedBox2, const char* markedLabel2, const RenderObject* obj) const
{
    showRenderObject();
    for (const RootInlineBox* root = firstRootBox(); root; root = root->nextRootBox())
        root->showLineTreeAndMark(markedBox1, markedLabel1, markedBox2, markedLabel2, obj, 1);
}

#endif

} // namespace blink
