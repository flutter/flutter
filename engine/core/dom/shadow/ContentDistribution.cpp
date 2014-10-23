/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
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
#include "core/dom/shadow/ContentDistribution.h"

#include "core/dom/shadow/InsertionPoint.h"

namespace blink {

void ContentDistribution::swap(ContentDistribution& other)
{
    m_nodes.swap(other.m_nodes);
    m_indices.swap(other.m_indices);
}

void ContentDistribution::append(PassRefPtrWillBeRawPtr<Node> node)
{
    ASSERT(node);
    ASSERT(!isActiveInsertionPoint(*node));
    size_t size = m_nodes.size();
    m_indices.set(node.get(), size);
    m_nodes.append(node);
}

size_t ContentDistribution::find(const Node* node) const
{
    WillBeHeapHashMap<RawPtrWillBeMember<const Node>, size_t>::const_iterator it = m_indices.find(node);
    if (it == m_indices.end())
        return kNotFound;

    return it.get()->value;
}

Node* ContentDistribution::nextTo(const Node* node) const
{
    size_t index = find(node);
    if (index == kNotFound || index + 1 == size())
        return 0;
    return at(index + 1).get();
}

Node* ContentDistribution::previousTo(const Node* node) const
{
    size_t index = find(node);
    if (index == kNotFound || !index)
        return 0;
    return at(index - 1).get();
}

void ContentDistribution::trace(Visitor* visitor)
{
#if ENABLE(OILPAN)
    visitor->trace(m_nodes);
    visitor->trace(m_indices);
#endif
}

} // namespace blink
