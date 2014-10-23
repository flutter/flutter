/*
 * Copyright (C) 2014 Google Inc. All rights reserved.
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
#include "core/html/imports/HTMLImportStateResolver.h"

#include "core/html/imports/HTMLImport.h"
#include "core/html/imports/HTMLImportChild.h"
#include "core/html/imports/HTMLImportLoader.h"

namespace blink {

inline bool HTMLImportStateResolver::isBlockingFollowers(HTMLImport* import)
{
    if (!import->isSync())
        return false;
    HTMLImportChild* child = toHTMLImportChild(import);
    if (!child->loader()->isFirstImport(child))
        return false;
    return !import->state().isReady();
}

inline bool HTMLImportStateResolver::shouldBlockScriptExecution() const
{
    // FIXME: Memoize to make this faster.
    for (HTMLImport* ancestor = m_import; ancestor; ancestor = ancestor->parent()) {
        for (HTMLImport* predecessor = ancestor->previous(); predecessor; predecessor = predecessor->previous()) {
            if (isBlockingFollowers(predecessor))
                return true;
        }
    }

    for (HTMLImport* child = m_import->firstChild(); child; child = child->next()) {
        if (isBlockingFollowers(child))
            return true;
    }

    return false;
}

inline bool HTMLImportStateResolver::isActive() const
{
    return !m_import->isDone();
}

HTMLImportState HTMLImportStateResolver::resolve() const
{
    if (shouldBlockScriptExecution())
        return HTMLImportState(HTMLImportState::BlockingScriptExecution);
    if (isActive())
        return HTMLImportState(HTMLImportState::Active);
    return HTMLImportState(HTMLImportState::Ready);
}

}

