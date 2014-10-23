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

#ifndef ComposedTreeWalker_h
#define ComposedTreeWalker_h

#include "core/dom/NodeRenderingTraversal.h"
#include "core/dom/shadow/InsertionPoint.h"
#include "core/dom/shadow/ShadowRoot.h"

namespace blink {

class Node;

// FIXME: Make some functions inline to optimise the performance.
// https://bugs.webkit.org/show_bug.cgi?id=82702
class ComposedTreeWalker {
    STACK_ALLOCATED();
public:
    typedef NodeRenderingTraversal::ParentDetails ParentTraversalDetails;

    enum StartPolicy {
        CanStartFromShadowBoundary,
        CannotStartFromShadowBoundary
    };

    ComposedTreeWalker(const Node*, StartPolicy = CannotStartFromShadowBoundary);

    Node* get() const { return const_cast<Node*>(m_node.get()); }

    void firstChild();
    void lastChild();

    void nextSibling();
    void previousSibling();

    void parent();

    void next();
    void previous();

    Node* traverseParent(const Node*, ParentTraversalDetails* = 0) const;

private:
    ComposedTreeWalker(const Node*, ParentTraversalDetails*);

    enum TraversalDirection {
        TraversalDirectionForward,
        TraversalDirectionBackward
    };

    void assertPrecondition() const
    {
#if ENABLE(ASSERT)
        ASSERT(m_node);
        ASSERT(!m_node->isShadowRoot());
        ASSERT(!isActiveInsertionPoint(*m_node));
#endif
    }

    void assertPostcondition() const
    {
#if ENABLE(ASSERT)
        if (m_node)
            assertPrecondition();
#endif
    }

    static Node* traverseNode(const Node*, TraversalDirection);
    static Node* traverseLightChildren(const Node*, TraversalDirection);

    Node* traverseFirstChild(const Node*) const;
    Node* traverseLastChild(const Node*) const;
    Node* traverseChild(const Node*, TraversalDirection) const;

    static Node* traverseNextSibling(const Node*);
    static Node* traversePreviousSibling(const Node*);

    static Node* traverseSiblingOrBackToInsertionPoint(const Node*, TraversalDirection);
    static Node* traverseSiblingInCurrentTree(const Node*, TraversalDirection);

    static Node* traverseSiblings(const Node*, TraversalDirection);
    static Node* traverseDistributedNodes(const Node*, const InsertionPoint*, TraversalDirection);

    static Node* traverseBackToYoungerShadowRoot(const Node*, TraversalDirection);

    Node* traverseParentOrHost(const Node*) const;

    RawPtrWillBeMember<const Node> m_node;
};

inline ComposedTreeWalker::ComposedTreeWalker(const Node* node, StartPolicy startPolicy)
    : m_node(node)
{
#if ENABLE(ASSERT)
    if (m_node && startPolicy == CannotStartFromShadowBoundary)
        assertPrecondition();
#endif
}

inline void ComposedTreeWalker::parent()
{
    assertPrecondition();
    m_node = traverseParent(m_node);
    assertPostcondition();
}

inline void ComposedTreeWalker::nextSibling()
{
    assertPrecondition();
    m_node = traverseSiblingOrBackToInsertionPoint(m_node, TraversalDirectionForward);
    assertPostcondition();
}

inline void ComposedTreeWalker::previousSibling()
{
    assertPrecondition();
    m_node = traverseSiblingOrBackToInsertionPoint(m_node, TraversalDirectionBackward);
    assertPostcondition();
}

inline void ComposedTreeWalker::next()
{
    assertPrecondition();
    if (Node* next = traverseFirstChild(m_node)) {
        m_node = next;
    } else {
        while (m_node) {
            if (Node* sibling = traverseNextSibling(m_node)) {
                m_node = sibling;
                break;
            }
            m_node = traverseParent(m_node);
        }
    }
    assertPostcondition();
}

inline void ComposedTreeWalker::previous()
{
    assertPrecondition();
    if (Node* previous = traversePreviousSibling(m_node)) {
        while (Node* child = traverseLastChild(previous))
            previous = child;
        m_node = previous;
    } else {
        parent();
    }
    assertPostcondition();
}

inline void ComposedTreeWalker::firstChild()
{
    assertPrecondition();
    m_node = traverseChild(m_node, TraversalDirectionForward);
    assertPostcondition();
}

inline void ComposedTreeWalker::lastChild()
{
    assertPrecondition();
    m_node = traverseLastChild(m_node);
    assertPostcondition();
}

inline Node* ComposedTreeWalker::traverseNextSibling(const Node* node)
{
    ASSERT(node);
    return traverseSiblingOrBackToInsertionPoint(node, TraversalDirectionForward);
}

inline Node* ComposedTreeWalker::traversePreviousSibling(const Node* node)
{
    ASSERT(node);
    return traverseSiblingOrBackToInsertionPoint(node, TraversalDirectionBackward);
}

inline Node* ComposedTreeWalker::traverseFirstChild(const Node* node) const
{
    ASSERT(node);
    return traverseChild(node, TraversalDirectionForward);
}

inline Node* ComposedTreeWalker::traverseLastChild(const Node* node) const
{
    ASSERT(node);
    return traverseChild(node, TraversalDirectionBackward);
}

} // namespace

#endif
