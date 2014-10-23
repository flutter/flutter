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

#ifndef DocumentLifecycle_h
#define DocumentLifecycle_h

#include "wtf/Assertions.h"
#include "wtf/Noncopyable.h"

namespace blink {

class DocumentLifecycle {
    WTF_MAKE_NONCOPYABLE(DocumentLifecycle);
public:
    enum State {
        Uninitialized,
        Inactive,

        // When the document is active, it traverses these states.

        VisualUpdatePending,

        InStyleRecalc,
        StyleClean,

        InPreLayout,
        InPerformLayout,
        AfterPerformLayout,
        LayoutClean,

        InCompositingUpdate,
        CompositingClean,

        InPaintInvalidation,
        PaintInvalidationClean,

        // Once the document starts shuting down, we cannot return
        // to the style/layout/rendering states.
        Stopping,
        Stopped,
        Disposed,
    };

    class Scope {
        WTF_MAKE_NONCOPYABLE(Scope);
    public:
        Scope(DocumentLifecycle&, State finalState);
        ~Scope();

        void setFinalState(State finalState) { m_finalState = finalState; }

    private:
        DocumentLifecycle& m_lifecycle;
        State m_finalState;
    };

    class DeprecatedTransition {
        WTF_MAKE_NONCOPYABLE(DeprecatedTransition);
    public:
        DeprecatedTransition(State from, State to);
        ~DeprecatedTransition();

        State from() const { return m_from; }
        State to() const { return m_to; }

    private:
        DeprecatedTransition* m_previous;
        State m_from;
        State m_to;
    };

    class DetachScope {
        WTF_MAKE_NONCOPYABLE(DetachScope);
    public:
        explicit DetachScope(DocumentLifecycle& documentLifecycle)
            : m_documentLifecycle(documentLifecycle)
        {
            m_documentLifecycle.incrementDetachCount();
        }

        ~DetachScope()
        {
            m_documentLifecycle.decrementDetachCount();
        }

    private:
        DocumentLifecycle& m_documentLifecycle;
    };

    DocumentLifecycle();
    ~DocumentLifecycle();

    bool isActive() const { return m_state > Inactive && m_state < Stopping; }
    State state() const { return m_state; }

    bool stateAllowsTreeMutations() const;
    bool stateAllowsRenderTreeMutations() const;
    bool stateAllowsDetach() const;

    void advanceTo(State);
    void ensureStateAtMost(State);

    void incrementDetachCount() { m_detachCount++; }
    void decrementDetachCount()
    {
        ASSERT(m_detachCount > 0);
        m_detachCount--;
    }

private:
#if ENABLE(ASSERT)
    bool canAdvanceTo(State) const;
    bool canRewindTo(State) const;
#endif

    State m_state;
    int m_detachCount;
};

inline bool DocumentLifecycle::stateAllowsTreeMutations() const
{
    // FIXME: We should not allow mutations in InPreLayout or AfterPerformLayout either,
    // but we need to fix MediaList listeners and plugins first.
    return m_state != InStyleRecalc
        && m_state != InPerformLayout
        && m_state != InCompositingUpdate;
}

inline bool DocumentLifecycle::stateAllowsRenderTreeMutations() const
{
    return m_detachCount || m_state == InStyleRecalc;
}

inline bool DocumentLifecycle::stateAllowsDetach() const
{
    return m_state == VisualUpdatePending
        || m_state == InStyleRecalc
        || m_state == StyleClean
        || m_state == InPreLayout
        || m_state == LayoutClean
        || m_state == CompositingClean
        || m_state == PaintInvalidationClean
        || m_state == Stopping;
}

}

#endif
