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

#include "config.h"
#include "core/dom/DocumentLifecycle.h"

#include "wtf/Assertions.h"

namespace blink {

static DocumentLifecycle::DeprecatedTransition* s_deprecatedTransitionStack = 0;

DocumentLifecycle::Scope::Scope(DocumentLifecycle& lifecycle, State finalState)
    : m_lifecycle(lifecycle)
    , m_finalState(finalState)
{
}

DocumentLifecycle::Scope::~Scope()
{
    m_lifecycle.advanceTo(m_finalState);
}

DocumentLifecycle::DeprecatedTransition::DeprecatedTransition(State from, State to)
    : m_previous(s_deprecatedTransitionStack)
    , m_from(from)
    , m_to(to)
{
    s_deprecatedTransitionStack = this;
}

DocumentLifecycle::DeprecatedTransition::~DeprecatedTransition()
{
    s_deprecatedTransitionStack = m_previous;
}

DocumentLifecycle::DocumentLifecycle()
    : m_state(Uninitialized)
    , m_detachCount(0)
{
}

DocumentLifecycle::~DocumentLifecycle()
{
}

#if ENABLE(ASSERT)

bool DocumentLifecycle::canAdvanceTo(State state) const
{
    if (state > m_state)
        return true;
    if (m_state == Disposed) {
        // FIXME: We can dispose a document multiple times. This seems wrong.
        // See https://code.google.com/p/chromium/issues/detail?id=301668.
        return state == Disposed;
    }
    if (m_state == StyleClean) {
        // We can synchronously recalc style.
        if (state == InStyleRecalc)
            return true;
        // We can synchronously perform layout.
        if (state == InPreLayout)
            return true;
        if (state == InPerformLayout)
            return true;
        // We can redundant arrive in the style clean state.
        if (state == StyleClean)
            return true;
        return false;
    }
    if (m_state == InPreLayout) {
        if (state == InStyleRecalc)
            return true;
        if (state == StyleClean)
            return true;
        if (state == InPreLayout)
            return true;
        return false;
    }
    if (m_state == AfterPerformLayout) {
        // We can synchronously recompute layout in AfterPerformLayout.
        // FIXME: Ideally, we would unnest this recursion into a loop.
        return state == InPreLayout;
    }
    if (m_state == LayoutClean) {
        // We can synchronously recalc style.
        if (state == InStyleRecalc)
            return true;
        // We can synchronously perform layout.
        if (state == InPreLayout)
            return true;
        if (state == InPerformLayout)
            return true;
        // We can redundant arrive in the layout clean state. This situation
        // can happen when we call layout recursively and we unwind the stack.
        if (state == LayoutClean)
            return true;
        if (state == StyleClean)
            return true;
        return false;
    }
    if (m_state == CompositingClean) {
        if (state == InStyleRecalc)
            return true;
        if (state == InCompositingUpdate)
            return true;
        if (state == InPaintInvalidation)
            return true;
        return false;
    }
    if (m_state == InPaintInvalidation) {
        if (state == PaintInvalidationClean)
            return true;
        return false;
    }
    if (m_state == PaintInvalidationClean) {
        if (state == InStyleRecalc)
            return true;
        if (state == InPreLayout)
            return true;
        if (state == InCompositingUpdate)
            return true;
        return false;
    }
    return false;
}

bool DocumentLifecycle::canRewindTo(State state) const
{
    // This transition is bogus, but we've whitelisted it anyway.
    if (s_deprecatedTransitionStack && m_state == s_deprecatedTransitionStack->from() && state == s_deprecatedTransitionStack->to())
        return true;
    return m_state == StyleClean || m_state == AfterPerformLayout || m_state == LayoutClean || m_state == CompositingClean || m_state == PaintInvalidationClean;
}

#endif

void DocumentLifecycle::advanceTo(State state)
{
    ASSERT(canAdvanceTo(state));
    m_state = state;
}

void DocumentLifecycle::ensureStateAtMost(State state)
{
    ASSERT(state == VisualUpdatePending || state == StyleClean || state == LayoutClean);
    if (m_state <= state)
        return;
    ASSERT(canRewindTo(state));
    m_state = state;
}

}
