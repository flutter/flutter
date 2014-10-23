/*
 * Copyright (C) 2008 Apple Inc. All Rights Reserved.
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

#ifndef NodeWithIndex_h
#define NodeWithIndex_h

#include "core/dom/Node.h"
#include "platform/heap/Handle.h"

namespace blink {

// For use when you want to get the index for a node repeatedly and
// only want to walk the child list to figure out the index once.
class NodeWithIndex {
    STACK_ALLOCATED();
public:
    explicit NodeWithIndex(Node& node)
        : m_node(node)
        , m_index(-1)
    {
    }

    Node& node() const { return *m_node; }

    int index() const
    {
        if (!hasIndex())
            m_index = node().nodeIndex();
        ASSERT(hasIndex());
        ASSERT(m_index == static_cast<int>(node().nodeIndex()));
        return m_index;
    }

private:
    bool hasIndex() const { return m_index >= 0; }

    RawPtrWillBeMember<Node> m_node;
    mutable int m_index;
};

}

#endif
