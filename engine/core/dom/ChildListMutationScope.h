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

#ifndef ChildListMutationScope_h
#define ChildListMutationScope_h

#include "core/dom/Document.h"
#include "core/dom/MutationObserver.h"
#include "core/dom/Node.h"
#include "platform/heap/Handle.h"
#include "wtf/Noncopyable.h"
#include "wtf/OwnPtr.h"
#include "wtf/RefCounted.h"

namespace blink {

class MutationObserverInterestGroup;

// ChildListMutationAccumulator is not meant to be used directly; ChildListMutationScope is the public interface.
//
// One ChildListMutationAccumulator for a given Node is shared between all the
// active ChildListMutationScopes for that Node. Once the last ChildListMutationScope
// is destructed the accumulator enqueues a mutation record for the recorded
// mutations and the accumulator can be garbage collected.
class ChildListMutationAccumulator FINAL : public RefCountedWillBeGarbageCollected<ChildListMutationAccumulator> {
    DECLARE_EMPTY_DESTRUCTOR_WILL_BE_REMOVED(ChildListMutationAccumulator);
public:
    static PassRefPtrWillBeRawPtr<ChildListMutationAccumulator> getOrCreate(Node&);

    void childAdded(PassRefPtrWillBeRawPtr<Node>);
    void willRemoveChild(PassRefPtrWillBeRawPtr<Node>);

    bool hasObservers() const { return m_observers; }

    // Register and unregister mutation scopes that are using this mutation
    // accumulator.
    void enterMutationScope() { m_mutationScopes++; }
    void leaveMutationScope();

    void trace(Visitor*);

private:
    ChildListMutationAccumulator(PassRefPtrWillBeRawPtr<Node>, PassOwnPtrWillBeRawPtr<MutationObserverInterestGroup>);

    void enqueueMutationRecord();
    bool isEmpty();
    bool isAddedNodeInOrder(Node*);
    bool isRemovedNodeInOrder(Node*);

    RefPtrWillBeMember<Node> m_target;

    WillBeHeapVector<RefPtrWillBeMember<Node> > m_removedNodes;
    WillBeHeapVector<RefPtrWillBeMember<Node> > m_addedNodes;
    RefPtrWillBeMember<Node> m_previousSibling;
    RefPtrWillBeMember<Node> m_nextSibling;
    RawPtrWillBeMember<Node> m_lastAdded;

    OwnPtrWillBeMember<MutationObserverInterestGroup> m_observers;

    unsigned m_mutationScopes;
};

class ChildListMutationScope FINAL {
    WTF_MAKE_NONCOPYABLE(ChildListMutationScope);
    STACK_ALLOCATED();
public:
    explicit ChildListMutationScope(Node& target)
    {
        if (target.document().hasMutationObserversOfType(MutationObserver::ChildList)) {
            m_accumulator = ChildListMutationAccumulator::getOrCreate(target);
            // Register another user of the accumulator.
            m_accumulator->enterMutationScope();
        }
    }

    ~ChildListMutationScope()
    {
        if (m_accumulator) {
            // Unregister a user of the accumulator. If this is the last user
            // the accumulator will enqueue a mutation record for the mutations.
            m_accumulator->leaveMutationScope();
        }
    }

    void childAdded(Node& child)
    {
        if (m_accumulator && m_accumulator->hasObservers())
            m_accumulator->childAdded(&child);
    }

    void willRemoveChild(Node& child)
    {
        if (m_accumulator && m_accumulator->hasObservers())
            m_accumulator->willRemoveChild(&child);
    }

private:
    RefPtrWillBeMember<ChildListMutationAccumulator> m_accumulator;
};

} // namespace blink

#endif // ChildListMutationScope_h
