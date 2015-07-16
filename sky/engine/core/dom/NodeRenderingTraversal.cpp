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

#include "sky/engine/core/dom/NodeRenderingTraversal.h"

#include "sky/engine/core/dom/shadow/ComposedTreeWalker.h"
#include "sky/engine/core/rendering/RenderObject.h"

namespace blink {

namespace NodeRenderingTraversal {

void ParentDetails::didTraverseInsertionPoint(const InsertionPoint* insertionPoint)
{
    if (!m_insertionPoint) {
        m_insertionPoint = insertionPoint;
    }
}

ContainerNode* parent(const Node* node, ParentDetails* details)
{
    ASSERT(node);
    ASSERT(!node->document().childNeedsDistributionRecalc());
    if (isActiveInsertionPoint(*node))
        return 0;
    ComposedTreeWalker walker(node, ComposedTreeWalker::CanStartFromShadowBoundary);
    return toContainerNode(walker.traverseParent(walker.get(), details));
}

bool contains(const ContainerNode* container, const Node* node)
{
    while (node) {
        if (node == container)
            return true;
        node = NodeRenderingTraversal::parent(node);
    }
    return false;
}

Node* nextSibling(const Node* node)
{
    ComposedTreeWalker walker(node);
    walker.nextSibling();
    return walker.get();
}

Node* previousSibling(const Node* node)
{
    ComposedTreeWalker walker(node);
    walker.previousSibling();
    return walker.get();
}

static Node* lastChild(const Node* node)
{
    ComposedTreeWalker walker(node);
    walker.lastChild();
    return walker.get();
}

static Node* firstChild(const Node* node)
{
    ComposedTreeWalker walker(node);
    walker.firstChild();
    return walker.get();
}

Node* previous(const Node* node, const Node* stayWithin)
{
    if (node == stayWithin)
        return 0;

    if (Node* previousNode = previousSibling(node)) {
        while (Node* previousLastChild = lastChild(previousNode))
            previousNode = previousLastChild;
        return previousNode;
    }
    return parent(node);
}

Node* next(const Node* node, const Node* stayWithin)
{
    if (Node* child = firstChild(node))
        return child;
    if (node == stayWithin)
        return 0;
    if (Node* nextNode = nextSibling(node))
        return nextNode;
    for (Node* parentNode = parent(node); parentNode; parentNode = parent(parentNode)) {
        if (parentNode == stayWithin)
            return 0;
        if (Node* nextNode = nextSibling(parentNode))
            return nextNode;
    }
    return 0;
}

RenderObject* nextSiblingRenderer(const Node* node)
{
    for (Node* sibling = NodeRenderingTraversal::nextSibling(node); sibling; sibling = NodeRenderingTraversal::nextSibling(sibling)) {
        if (RenderObject* renderer = sibling->renderer())
            return renderer;
    }
    return 0;
}

RenderObject* previousSiblingRenderer(const Node* node)
{
    for (Node* sibling = NodeRenderingTraversal::previousSibling(node); sibling; sibling = NodeRenderingTraversal::previousSibling(sibling)) {
        if (RenderObject* renderer = sibling->renderer())
            return renderer;
    }
    return 0;
}

Node* commonAncestor(Node& a, Node& b)
{
    if (a == b)
        return &a;
    if (a.document() != b.document())
        return 0;
    int thisDepth = 0;
    for (Node* node = &a; node; node = parent(node)) {
        if (node == b)
            return node;
        thisDepth++;
    }
    int otherDepth = 0;
    for (const Node* node = &b; node; node = parent(node)) {
        if (node == a)
            return &a;
        otherDepth++;
    }
    Node* thisIterator = &a;
    const Node* otherIterator = &b;
    if (thisDepth > otherDepth) {
        for (int i = thisDepth; i > otherDepth; --i)
            thisIterator = parent(thisIterator);
    } else if (otherDepth > thisDepth) {
        for (int i = otherDepth; i > thisDepth; --i)
            otherIterator = parent(otherIterator);
    }
    while (thisIterator) {
        if (thisIterator == otherIterator)
            return thisIterator;
        thisIterator = parent(thisIterator);
        otherIterator = parent(otherIterator);
    }
    ASSERT(!otherIterator);
    return 0;
}

}

} // namespace
