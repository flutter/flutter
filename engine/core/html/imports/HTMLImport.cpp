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
#include "core/html/imports/HTMLImport.h"

#include "core/dom/Document.h"
#include "core/html/imports/HTMLImportStateResolver.h"
#include "wtf/Vector.h"

namespace blink {

HTMLImport* HTMLImport::root()
{
    HTMLImport* i = this;
    while (i->parent())
        i = i->parent();
    return i;
}

bool HTMLImport::precedes(HTMLImport* import)
{
    for (HTMLImport* i = this; i; i = traverseNext(i)) {
        if (i == import)
            return true;
    }

    return false;
}

bool HTMLImport::formsCycle() const
{
    for (const HTMLImport* i = this->parent(); i; i = i->parent()) {
        if (i->document() == this->document())
            return true;
    }

    return false;

}

void HTMLImport::appendImport(HTMLImport* child)
{
    appendChild(child);

    // This prevents HTML parser from going beyond the
    // blockage line before the precise state is computed by recalcState().
    if (child->isSync())
        m_state = HTMLImportState::blockedState();

    stateWillChange();
}

void HTMLImport::stateDidChange()
{
    if (!state().shouldBlockScriptExecution()) {
        if (Document* document = this->document())
            document->didLoadAllImports();
    }
}

void HTMLImport::recalcTreeState(HTMLImport* root)
{
    WillBeHeapHashMap<RawPtrWillBeMember<HTMLImport>, HTMLImportState> snapshot;
    WillBeHeapVector<RawPtrWillBeMember<HTMLImport> > updated;

    for (HTMLImport* i = root; i; i = traverseNext(i)) {
        snapshot.add(i, i->state());
        i->m_state = HTMLImportState::invalidState();
    }

    // The post-visit DFS order matters here because
    // HTMLImportStateResolver in recalcState() Depends on
    // |m_state| of its children and precedents of ancestors.
    // Accidental cycle dependency of state computation is prevented
    // by invalidateCachedState() and isStateCacheValid() check.
    for (HTMLImport* i = traverseFirstPostOrder(root); i; i = traverseNextPostOrder(i)) {
        ASSERT(!i->m_state.isValid());
        i->m_state = HTMLImportStateResolver(i).resolve();

        HTMLImportState newState = i->state();
        HTMLImportState oldState = snapshot.get(i);
        // Once the state reaches Ready, it shouldn't go back.
        ASSERT(!oldState.isReady() || oldState <= newState);
        if (newState != oldState)
            updated.append(i);
    }

    for (size_t i = 0; i < updated.size(); ++i)
        updated[i]->stateDidChange();
}

#if !defined(NDEBUG)
void HTMLImport::show()
{
    root()->showTree(this, 0);
}

void HTMLImport::showTree(HTMLImport* highlight, unsigned depth)
{
    for (unsigned i = 0; i < depth*4; ++i)
        fprintf(stderr, " ");

    fprintf(stderr, "%s", this == highlight ? "*" : " ");
    showThis();
    fprintf(stderr, "\n");
    for (HTMLImport* child = firstChild(); child; child = child->next())
        child->showTree(highlight, depth + 1);
}

void HTMLImport::showThis()
{
    fprintf(stderr, "%p state=%d", this, m_state.peekValueForDebug());
}
#endif

} // namespace blink
