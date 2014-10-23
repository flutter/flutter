/*
 * Copyright (C) 2011 Google Inc. All rights reserved.
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

#include "config.h"
#include "bindings/core/v8/RetainedDOMInfo.h"

#include "core/dom/ContainerNode.h"
#include "core/dom/NodeTraversal.h"

namespace blink {

RetainedDOMInfo::RetainedDOMInfo(Node* root)
    : m_root(root)
{
    ASSERT(m_root);
}

RetainedDOMInfo::~RetainedDOMInfo()
{
}

void RetainedDOMInfo::Dispose()
{
    delete this;
}

bool RetainedDOMInfo::IsEquivalent(v8::RetainedObjectInfo* other)
{
    ASSERT(other);
    if (other == this)
        return true;
    if (strcmp(GetLabel(), other->GetLabel()))
        return false;
    return static_cast<blink::RetainedObjectInfo*>(other)->GetEquivalenceClass() == this->GetEquivalenceClass();
}

intptr_t RetainedDOMInfo::GetHash()
{
    return PtrHash<void*>::hash(m_root);
}

const char* RetainedDOMInfo::GetGroupLabel()
{
    return m_root->inDocument() ? "(Document DOM trees)" : "(Detached DOM trees)";
}

const char* RetainedDOMInfo::GetLabel()
{
    return m_root->inDocument() ? "Document DOM tree" : "Detached DOM tree";
}

intptr_t RetainedDOMInfo::GetElementCount()
{
    intptr_t count = 1;
    Node* current = m_root;
    while (current) {
        current = NodeTraversal::next(*current, m_root);
        ++count;
    }
    return count;
}

intptr_t RetainedDOMInfo::GetEquivalenceClass()
{
    return reinterpret_cast<intptr_t>(m_root);
}

} // namespace blink
