/*
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

#ifndef TreeNode_h
#define TreeNode_h

#include "wtf/Assertions.h"

namespace WTF {

//
// TreeNode is generic, ContainerNode-like linked tree data structure.
// There are a few notable difference between TreeNode and Node:
//
//  * Each TreeNode node is NOT ref counted. The user have to retain its lifetime somehow.
//    FIXME: lifetime management could be parameterized so that ref counted implementations can be used.
//  * It ASSERT()s invalid input. The callers have to ensure that given parameter is sound.
//  * There is no branch-leaf difference. Every node can be a parent of other node.
//
// FIXME: oilpan: Trace tree node edges to ensure we don't have dangling pointers.
// As it is used in HTMLImport it is safe since they all die together.
template <class T>
class TreeNode {
public:
    typedef T NodeType;

    TreeNode()
        : m_next(0)
        , m_previous(0)
        , m_parent(0)
        , m_firstChild(0)
        , m_lastChild(0)
    {
    }

    NodeType* next() const { return m_next; }
    NodeType* previous() const { return m_previous; }
    NodeType* parent() const { return m_parent; }
    NodeType* firstChild() const { return m_firstChild; }
    NodeType* lastChild() const { return m_lastChild; }
    NodeType* here() const { return static_cast<NodeType*>(const_cast<TreeNode*>(this)); }

    bool orphan() const { return !m_parent && !m_next && !m_previous && !m_firstChild && !m_lastChild; }
    bool hasChildren() const { return m_firstChild; }

    void insertBefore(NodeType* newChild, NodeType* refChild)
    {
        ASSERT(!newChild->parent());
        ASSERT(!newChild->next());
        ASSERT(!newChild->previous());

        ASSERT(!refChild || this == refChild->parent());

        if (!refChild) {
            appendChild(newChild);
            return;
        }

        NodeType* newPrevious = refChild->previous();
        newChild->m_parent = here();
        newChild->m_next = refChild;
        newChild->m_previous = newPrevious;
        refChild->m_previous = newChild;
        if (newPrevious)
            newPrevious->m_next = newChild;
        else
            m_firstChild = newChild;
    }

    void appendChild(NodeType* child)
    {
        ASSERT(!child->parent());
        ASSERT(!child->next());
        ASSERT(!child->previous());

        child->m_parent = here();

        if (!m_lastChild) {
            ASSERT(!m_firstChild);
            m_lastChild = m_firstChild = child;
            return;
        }

        ASSERT(!m_lastChild->m_next);
        NodeType* oldLast = m_lastChild;
        m_lastChild = child;

        child->m_previous = oldLast;
        oldLast->m_next = child;
    }

    NodeType* removeChild(NodeType* child)
    {
        ASSERT(child->parent() == this);

        if (m_firstChild == child)
            m_firstChild = child->next();
        if (m_lastChild == child)
            m_lastChild = child->previous();

        NodeType* oldNext = child->next();
        NodeType* oldPrevious = child->previous();
        child->m_parent = child->m_next = child->m_previous = 0;

        if (oldNext)
            oldNext->m_previous = oldPrevious;
        if (oldPrevious)
            oldPrevious->m_next = oldNext;

        return child;
    }

    void takeChildrenFrom(NodeType* oldParent)
    {
        ASSERT(oldParent != this);
        while (oldParent->hasChildren()) {
            NodeType* child = oldParent->firstChild();
            oldParent->removeChild(child);
            this->appendChild(child);
        }
    }

private:
    NodeType* m_next;
    NodeType* m_previous;
    NodeType* m_parent;
    NodeType* m_firstChild;
    NodeType* m_lastChild;
};

template<class T>
inline typename TreeNode<T>::NodeType* traverseNext(const TreeNode<T>* current, const TreeNode<T>* stayWithin = 0)
{
    if (typename TreeNode<T>::NodeType* next = current->firstChild())
        return next;
    if (current == stayWithin)
        return 0;
    if (typename TreeNode<T>::NodeType* next = current->next())
        return next;
    for (typename TreeNode<T>::NodeType* parent = current->parent(); parent; parent = parent->parent()) {
        if (parent == stayWithin)
            return 0;
        if (typename TreeNode<T>::NodeType* next = parent->next())
            return next;
    }

    return 0;
}

template<class T>
inline typename TreeNode<T>::NodeType* traverseFirstPostOrder(const TreeNode<T>* current)
{
    typename TreeNode<T>::NodeType* first = current->here();
    while (first->firstChild())
        first = first->firstChild();
    return first;
}

template<class T>
inline typename TreeNode<T>::NodeType* traverseNextPostOrder(const TreeNode<T>* current, const TreeNode<T>* stayWithin = 0)
{
    if (current == stayWithin)
        return 0;

    typename TreeNode<T>::NodeType* next = current->next();
    if (!next)
        return current->parent();
    while (next->firstChild())
        next = next->firstChild();
    return next;
}

}

using WTF::TreeNode;
using WTF::traverseNext;
using WTF::traverseNextPostOrder;

#endif
