/*
 * Copyright (C) 2005, 2008 Apple Inc. All rights reserved.
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
 */

#include "config.h"
#include "core/editing/RemoveNodeCommand.h"

#include "bindings/core/v8/ExceptionStatePlaceholder.h"
#include "core/dom/Node.h"
#include "wtf/Assertions.h"

namespace blink {

RemoveNodeCommand::RemoveNodeCommand(PassRefPtrWillBeRawPtr<Node> node, ShouldAssumeContentIsAlwaysEditable shouldAssumeContentIsAlwaysEditable)
    : SimpleEditCommand(node->document())
    , m_node(node)
    , m_shouldAssumeContentIsAlwaysEditable(shouldAssumeContentIsAlwaysEditable)
{
    ASSERT(m_node);
    ASSERT(m_node->parentNode());
}

void RemoveNodeCommand::doApply()
{
    ContainerNode* parent = m_node->parentNode();
    if (!parent || (m_shouldAssumeContentIsAlwaysEditable == DoNotAssumeContentIsAlwaysEditable
        && !parent->isContentEditable(Node::UserSelectAllIsAlwaysNonEditable) && parent->inActiveDocument()))
        return;
    ASSERT(parent->isContentEditable(Node::UserSelectAllIsAlwaysNonEditable) || !parent->inActiveDocument());

    m_parent = parent;
    m_refChild = m_node->nextSibling();

    m_node->remove(IGNORE_EXCEPTION);
}

void RemoveNodeCommand::doUnapply()
{
    RefPtrWillBeRawPtr<ContainerNode> parent = m_parent.release();
    RefPtrWillBeRawPtr<Node> refChild = m_refChild.release();
    if (!parent || !parent->hasEditableStyle())
        return;

    parent->insertBefore(m_node.get(), refChild.get(), IGNORE_EXCEPTION);
}

void RemoveNodeCommand::trace(Visitor* visitor)
{
    visitor->trace(m_node);
    visitor->trace(m_parent);
    visitor->trace(m_refChild);
    SimpleEditCommand::trace(visitor);
}

}
