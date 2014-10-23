/*
 * Copyright (C) 2014 Google Inc. All Rights Reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

#ifndef NodeEventContext_h
#define NodeEventContext_h

#include "core/events/TreeScopeEventContext.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefPtr.h"

namespace blink {

class EventTarget;
class Node;
class TouchEventContext;

class NodeEventContext {
    ALLOW_ONLY_INLINE_ALLOCATION();
    DECLARE_EMPTY_DESTRUCTOR_WILL_BE_REMOVED(NodeEventContext);
public:
    // FIXME: Use ContainerNode instead of Node.
    NodeEventContext(PassRefPtrWillBeRawPtr<Node>, PassRefPtrWillBeRawPtr<EventTarget> currentTarget);
    void trace(Visitor*);

    Node* node() const { return m_node.get(); }

    void setTreeScopeEventContext(PassRefPtrWillBeRawPtr<TreeScopeEventContext> prpTreeScopeEventContext) { m_treeScopeEventContext = prpTreeScopeEventContext; }
    TreeScopeEventContext& treeScopeEventContext() { ASSERT(m_treeScopeEventContext); return *m_treeScopeEventContext; }

    EventTarget* target() const { return m_treeScopeEventContext->target(); }
    EventTarget* relatedTarget() const { return m_treeScopeEventContext->relatedTarget(); }
    TouchEventContext* touchEventContext() const { return m_treeScopeEventContext->touchEventContext(); }

    bool currentTargetSameAsTarget() const { return m_currentTarget.get() == target(); }
    void handleLocalEvents(Event*) const;

private:
    RefPtrWillBeMember<Node> m_node;
    RefPtrWillBeMember<EventTarget> m_currentTarget;
    RefPtrWillBeMember<TreeScopeEventContext> m_treeScopeEventContext;
};

} // namespace blink

#if !ENABLE(OILPAN)
WTF_ALLOW_MOVE_INIT_AND_COMPARE_WITH_MEM_FUNCTIONS(blink::NodeEventContext);
#else
namespace WTF {
template <> struct VectorTraits<blink::NodeEventContext> : SimpleClassVectorTraits<blink::NodeEventContext> {
    static const bool needsDestruction = false;
};
}
#endif

#endif // NodeEventContext_h
