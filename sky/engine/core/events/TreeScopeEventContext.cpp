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

#include "sky/engine/core/events/TreeScopeEventContext.h"

#include "sky/engine/core/dom/StaticNodeList.h"
#include "sky/engine/core/dom/shadow/ShadowRoot.h"
#include "sky/engine/core/events/EventPath.h"

namespace blink {

PassRefPtr<StaticNodeList> TreeScopeEventContext::ensureEventPath(EventPath& path)
{
    if (m_eventPath)
        return m_eventPath;

    Vector<RefPtr<Node> > nodes;
    nodes.reserveInitialCapacity(path.size());
    for (size_t i = 0; i < path.size(); ++i) {
        TreeScope& treeScope = path[i].treeScopeEventContext().treeScope();
        if (treeScope.rootNode().isShadowRoot())
            nodes.append(path[i].node());
        else if (path[i].treeScopeEventContext().isInclusiveAncestorOf(*this))
            nodes.append(path[i].node());
    }
    m_eventPath = StaticNodeList::adopt(nodes);
    return m_eventPath;
}

PassRefPtr<TreeScopeEventContext> TreeScopeEventContext::create(TreeScope& treeScope)
{
    return adoptRef(new TreeScopeEventContext(treeScope));
}

TreeScopeEventContext::TreeScopeEventContext(TreeScope& treeScope)
    : m_treeScope(treeScope)
    , m_preOrder(-1)
    , m_postOrder(-1)
{
}

DEFINE_EMPTY_DESTRUCTOR_WILL_BE_REMOVED(TreeScopeEventContext)

int TreeScopeEventContext::calculatePrePostOrderNumber(int orderNumber)
{
    m_preOrder = orderNumber;
    for (size_t i = 0; i < m_children.size(); ++i)
        orderNumber = m_children[i]->calculatePrePostOrderNumber(orderNumber + 1);
    m_postOrder = orderNumber + 1;
    return orderNumber + 1;
}

}
