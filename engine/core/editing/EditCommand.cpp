/*
 * Copyright (C) 2005, 2006, 2007 Apple, Inc.  All rights reserved.
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
#include "core/editing/EditCommand.h"

#include "core/dom/Document.h"
#include "core/dom/NodeTraversal.h"
#include "core/editing/CompositeEditCommand.h"
#include "core/editing/FrameSelection.h"
#include "core/frame/LocalFrame.h"

namespace blink {

EditCommand::EditCommand(Document& document)
    : m_document(&document)
    , m_parent(nullptr)
{
    ASSERT(m_document);
    ASSERT(m_document->frame());
    setStartingSelection(m_document->frame()->selection().selection());
    setEndingSelection(m_startingSelection);
}

EditCommand::EditCommand(Document* document, const VisibleSelection& startingSelection, const VisibleSelection& endingSelection)
    : m_document(document)
    , m_parent(nullptr)
{
    ASSERT(m_document);
    ASSERT(m_document->frame());
    setStartingSelection(startingSelection);
    setEndingSelection(endingSelection);
}

EditCommand::~EditCommand()
{
}

EditAction EditCommand::editingAction() const
{
    return EditActionUnspecified;
}

static inline EditCommandComposition* compositionIfPossible(EditCommand* command)
{
    if (!command->isCompositeEditCommand())
        return 0;
    return toCompositeEditCommand(command)->composition();
}

void EditCommand::setStartingSelection(const VisibleSelection& selection)
{
    for (EditCommand* command = this; ; command = command->m_parent) {
        if (EditCommandComposition* composition = compositionIfPossible(command)) {
            ASSERT(command->isTopLevelCommand());
            composition->setStartingSelection(selection);
        }
        command->m_startingSelection = selection;
        if (!command->m_parent || command->m_parent->isFirstCommand(command))
            break;
    }
}

void EditCommand::setStartingSelection(const VisiblePosition& position)
{
    setStartingSelection(VisibleSelection(position));
}

void EditCommand::setEndingSelection(const VisibleSelection& selection)
{
    for (EditCommand* command = this; command; command = command->m_parent) {
        if (EditCommandComposition* composition = compositionIfPossible(command)) {
            ASSERT(command->isTopLevelCommand());
            composition->setEndingSelection(selection);
        }
        command->m_endingSelection = selection;
    }
}

void EditCommand::setEndingSelection(const VisiblePosition& position)
{
    setEndingSelection(VisibleSelection(position));
}

void EditCommand::setParent(CompositeEditCommand* parent)
{
    ASSERT((parent && !m_parent) || (!parent && m_parent));
    ASSERT(!parent || !isCompositeEditCommand() || !toCompositeEditCommand(this)->composition());
    m_parent = parent;
    if (parent) {
        m_startingSelection = parent->m_endingSelection;
        m_endingSelection = parent->m_endingSelection;
    }
}

void SimpleEditCommand::doReapply()
{
    doApply();
}

void EditCommand::trace(Visitor* visitor)
{
    visitor->trace(m_document);
    visitor->trace(m_startingSelection);
    visitor->trace(m_endingSelection);
    visitor->trace(m_parent);
}

} // namespace blink
