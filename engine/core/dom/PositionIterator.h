/*
 * Copyright (C) 2007, 2008 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef PositionIterator_h
#define PositionIterator_h

#include "core/dom/Node.h"
#include "core/dom/NodeTraversal.h"
#include "core/dom/Position.h"

namespace blink {

// A Position iterator with constant-time
// increment, decrement, and several predicates on the Position it is at.
// Conversion to/from Position is O(n) in the offset.
class PositionIterator {
    STACK_ALLOCATED();
public:
    PositionIterator()
        : m_anchorNode(nullptr)
        , m_nodeAfterPositionInAnchor(nullptr)
        , m_offsetInAnchor(0)
    {
    }

    PositionIterator(const Position& pos)
        : m_anchorNode(pos.anchorNode())
        , m_nodeAfterPositionInAnchor(NodeTraversal::childAt(*m_anchorNode, pos.deprecatedEditingOffset()))
        , m_offsetInAnchor(m_nodeAfterPositionInAnchor ? 0 : pos.deprecatedEditingOffset())
    {
    }
    operator Position() const;

    void increment();
    void decrement();

    Node* node() const { return m_anchorNode; }
    int offsetInLeafNode() const { return m_offsetInAnchor; }

    bool atStart() const;
    bool atEnd() const;
    bool atStartOfNode() const;
    bool atEndOfNode() const;
    bool isCandidate() const;

private:
    RawPtrWillBeMember<Node> m_anchorNode;
    RawPtrWillBeMember<Node> m_nodeAfterPositionInAnchor; // If this is non-null, m_nodeAfterPositionInAnchor->parentNode() == m_anchorNode;
    int m_offsetInAnchor;
};

} // namespace blink

#endif // PositionIterator_h
