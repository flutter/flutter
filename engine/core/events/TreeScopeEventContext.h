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

#ifndef TreeScopeEventContext_h
#define TreeScopeEventContext_h

#include "core/dom/Node.h"
#include "core/dom/TreeScope.h"
#include "core/events/EventTarget.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefPtr.h"
#include "wtf/Vector.h"

namespace blink {

class EventPath;
class EventTarget;
class Node;
template <typename NodeType> class StaticNodeTypeList;
typedef StaticNodeTypeList<Node> StaticNodeList;
class TouchEventContext;
class TreeScope;

class TreeScopeEventContext final : public RefCountedWillBeGarbageCollected<TreeScopeEventContext> {
    DECLARE_EMPTY_DESTRUCTOR_WILL_BE_REMOVED(TreeScopeEventContext);
public:
    static PassRefPtrWillBeRawPtr<TreeScopeEventContext> create(TreeScope&);
    void trace(Visitor*);

    TreeScope& treeScope() const { return *m_treeScope; }

    EventTarget* target() const { return m_target.get(); }
    void setTarget(PassRefPtrWillBeRawPtr<EventTarget>);

    EventTarget* relatedTarget() const { return m_relatedTarget.get(); }
    void setRelatedTarget(PassRefPtrWillBeRawPtr<EventTarget>);

    TouchEventContext* touchEventContext() const { return m_touchEventContext.get(); }
    TouchEventContext* ensureTouchEventContext();

    PassRefPtrWillBeRawPtr<StaticNodeList> ensureEventPath(EventPath&);

    bool isInclusiveAncestorOf(const TreeScopeEventContext&);
    void addChild(TreeScopeEventContext& child) { m_children.append(&child); }

    // For ancestor-descendant relationship check in Q(1).
    // Preprocessing takes O(N).
    int calculatePrePostOrderNumber(int orderNumber);

private:
    TreeScopeEventContext(TreeScope&);

#if ENABLE(ASSERT)
    bool isUnreachableNode(EventTarget&);
#endif

    RawPtrWillBeMember<TreeScope> m_treeScope;
    RefPtrWillBeMember<EventTarget> m_target;
    RefPtrWillBeMember<EventTarget> m_relatedTarget;
    RefPtrWillBeMember<StaticNodeList> m_eventPath;
    RefPtrWillBeMember<TouchEventContext> m_touchEventContext;

    WillBeHeapVector<RawPtrWillBeMember<TreeScopeEventContext> > m_children;
    int m_preOrder;
    int m_postOrder;
};

#if ENABLE(ASSERT)
inline bool TreeScopeEventContext::isUnreachableNode(EventTarget& target)
{
    // FIXME: Checks also for SVG elements.
    return target.toNode() && !target.toNode()->treeScope().isInclusiveOlderSiblingShadowRootOrAncestorTreeScopeOf(treeScope());
}
#endif

inline void TreeScopeEventContext::setTarget(PassRefPtrWillBeRawPtr<EventTarget> target)
{
    ASSERT(target);
    ASSERT(!isUnreachableNode(*target));
    m_target = target;
}

inline void TreeScopeEventContext::setRelatedTarget(PassRefPtrWillBeRawPtr<EventTarget> relatedTarget)
{
    ASSERT(relatedTarget);
    ASSERT(!isUnreachableNode(*relatedTarget));
    m_relatedTarget = relatedTarget;
}

inline bool TreeScopeEventContext::isInclusiveAncestorOf(const TreeScopeEventContext& other)
{
    ASSERT(m_preOrder != -1 && m_postOrder != -1 && other.m_preOrder != -1 && other.m_postOrder != -1);
    return m_preOrder <= other.m_preOrder && other.m_postOrder <= m_postOrder;
}

}

#endif // TreeScopeEventContext_h
