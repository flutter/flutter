
/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
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

#include "config.h"
#include "core/dom/shadow/ComposedTreeWalker.h"

#include "core/dom/Element.h"
#include "core/dom/shadow/ElementShadow.h"

namespace blink {

static inline ElementShadow* shadowFor(const Node* node)
{
    if (node && node->isElementNode())
        return toElement(node)->shadow();
    return 0;
}

Node* ComposedTreeWalker::traverseChild(const Node* node, TraversalDirection direction) const
{
    ASSERT(node);
    ElementShadow* shadow = shadowFor(node);
    return shadow ? traverseLightChildren(shadow->youngestShadowRoot(), direction)
            : traverseLightChildren(node, direction);
}

Node* ComposedTreeWalker::traverseLightChildren(const Node* node, TraversalDirection direction)
{
    ASSERT(node);
    return traverseSiblings(direction == TraversalDirectionForward ? node->firstChild() : node->lastChild(), direction);
}

Node* ComposedTreeWalker::traverseSiblings(const Node* node, TraversalDirection direction)
{
    for (const Node* sibling = node; sibling; sibling = (direction == TraversalDirectionForward ? sibling->nextSibling() : sibling->previousSibling())) {
        if (Node* found = traverseNode(sibling, direction))
            return found;
    }
    return 0;
}

Node* ComposedTreeWalker::traverseNode(const Node* node, TraversalDirection direction)
{
    ASSERT(node);
    if (!isActiveInsertionPoint(*node))
        return const_cast<Node*>(node);
    const InsertionPoint* insertionPoint = toInsertionPoint(node);
    if (Node* found = traverseDistributedNodes(direction == TraversalDirectionForward ? insertionPoint->first() : insertionPoint->last(), insertionPoint, direction))
        return found;
    ASSERT(isHTMLContentElement(node) && !node->hasChildren());
    return 0;
}

Node* ComposedTreeWalker::traverseDistributedNodes(const Node* node, const InsertionPoint* insertionPoint, TraversalDirection direction)
{
    for (const Node* next = node; next; next = (direction == TraversalDirectionForward ? insertionPoint->nextTo(next) : insertionPoint->previousTo(next))) {
        if (Node* found = traverseNode(next, direction))
            return found;
    }
    return 0;
}

Node* ComposedTreeWalker::traverseSiblingOrBackToInsertionPoint(const Node* node, TraversalDirection direction)
{
    ASSERT(node);

    if (!shadowWhereNodeCanBeDistributed(*node))
        return traverseSiblingInCurrentTree(node, direction);

    const InsertionPoint* insertionPoint = resolveReprojection(node);
    if (!insertionPoint)
        return traverseSiblingInCurrentTree(node, direction);

    if (Node* found = traverseDistributedNodes(direction == TraversalDirectionForward ? insertionPoint->nextTo(node) : insertionPoint->previousTo(node), insertionPoint, direction))
        return found;
    return traverseSiblingOrBackToInsertionPoint(insertionPoint, direction);
}

Node* ComposedTreeWalker::traverseSiblingInCurrentTree(const Node* node, TraversalDirection direction)
{
    ASSERT(node);
    if (Node* found = traverseSiblings(direction == TraversalDirectionForward ? node->nextSibling() : node->previousSibling(), direction))
        return found;
    if (Node* next = traverseBackToYoungerShadowRoot(node, direction))
        return next;
    return 0;
}

Node* ComposedTreeWalker::traverseBackToYoungerShadowRoot(const Node* node, TraversalDirection direction)
{
    // FIXME(sky): Remove this.
    return 0;
}

// FIXME: Use an iterative algorithm so that it can be inlined.
// https://bugs.webkit.org/show_bug.cgi?id=90415
Node* ComposedTreeWalker::traverseParent(const Node* node, ParentTraversalDetails* details) const
{
    if (shadowWhereNodeCanBeDistributed(*node)) {
        if (const InsertionPoint* insertionPoint = resolveReprojection(node)) {
            if (details)
                details->didTraverseInsertionPoint(insertionPoint);
            // The node is distributed. But the distribution was stopped at this insertion point.
            if (shadowWhereNodeCanBeDistributed(*insertionPoint))
                return 0;
            return traverseParentOrHost(insertionPoint);
        }
        return 0;
    }
    return traverseParentOrHost(node);
}

inline Node* ComposedTreeWalker::traverseParentOrHost(const Node* node) const
{
    Node* parent = node->parentNode();
    if (!parent)
        return 0;
    if (!parent->isShadowRoot())
        return parent;
    ShadowRoot* shadowRoot = toShadowRoot(parent);
    if (!shadowRoot->isYoungest())
        return 0;
    return shadowRoot->host();
}

} // namespace
