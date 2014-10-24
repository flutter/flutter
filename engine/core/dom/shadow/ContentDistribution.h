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

#ifndef ContentDistribution_h
#define ContentDistribution_h

#include "core/dom/Node.h"
#include "wtf/HashMap.h"
#include "wtf/Vector.h"

namespace blink {

class ContentDistribution final {
    DISALLOW_ALLOCATION();
public:
    ContentDistribution() { m_nodes.reserveInitialCapacity(32); }

    PassRefPtrWillBeRawPtr<Node> first() const { return m_nodes.first(); }
    PassRefPtrWillBeRawPtr<Node> last() const { return m_nodes.last(); }
    PassRefPtrWillBeRawPtr<Node> at(size_t index) const { return m_nodes.at(index); }

    size_t size() const { return m_nodes.size(); }
    bool isEmpty() const { return m_nodes.isEmpty(); }

    void append(PassRefPtrWillBeRawPtr<Node>);
    void clear() { m_nodes.clear(); m_indices.clear(); }
    void shrinkToFit() { m_nodes.shrinkToFit(); }

    bool contains(const Node* node) const { return m_indices.contains(node); }
    size_t find(const Node*) const;
    Node* nextTo(const Node*) const;
    Node* previousTo(const Node*) const;

    void swap(ContentDistribution& other);

    const WillBeHeapVector<RefPtrWillBeMember<Node> >& nodes() const { return m_nodes; }

    void trace(Visitor*);

private:
    WillBeHeapVector<RefPtrWillBeMember<Node> > m_nodes;
    WillBeHeapHashMap<RawPtrWillBeMember<const Node>, size_t> m_indices;
};

}

#endif
