/*
 * Copyright (C) 2012 Apple Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "core/editing/TextInsertionBaseCommand.h"

#include "bindings/core/v8/ExceptionStatePlaceholder.h"
#include "core/events/BeforeTextInsertedEvent.h"
#include "core/dom/Element.h"
#include "core/dom/Node.h"
#include "core/editing/FrameSelection.h"
#include "core/frame/LocalFrame.h"

namespace blink {

TextInsertionBaseCommand::TextInsertionBaseCommand(Document& document)
    : CompositeEditCommand(document)
{
}

void TextInsertionBaseCommand::applyTextInsertionCommand(LocalFrame* frame, PassRefPtrWillBeRawPtr<TextInsertionBaseCommand> command, const VisibleSelection& selectionForInsertion, const VisibleSelection& endingSelection)
{
    bool changeSelection = selectionForInsertion != endingSelection;
    if (changeSelection) {
        command->setStartingSelection(selectionForInsertion);
        command->setEndingSelection(selectionForInsertion);
    }
    command->apply();
    if (changeSelection) {
        command->setEndingSelection(endingSelection);
        frame->selection().setSelection(endingSelection);
    }
}

String dispatchBeforeTextInsertedEvent(const String& text, const VisibleSelection& selectionForInsertion, bool insertionIsForUpdatingComposition)
{
    if (insertionIsForUpdatingComposition)
        return text;

    String newText = text;
    if (Node* startNode = selectionForInsertion.start().containerNode()) {
        if (startNode->rootEditableElement()) {
            // Send BeforeTextInsertedEvent. The event handler will update text if necessary.
            RefPtrWillBeRawPtr<BeforeTextInsertedEvent> evt = BeforeTextInsertedEvent::create(text);
            startNode->rootEditableElement()->dispatchEvent(evt, IGNORE_EXCEPTION);
            newText = evt->text();
        }
    }
    return newText;
}

bool canAppendNewLineFeedToSelection(const VisibleSelection& selection)
{
    Element* element = selection.rootEditableElement();
    if (!element)
        return false;

    RefPtrWillBeRawPtr<BeforeTextInsertedEvent> event = BeforeTextInsertedEvent::create(String("\n"));
    element->dispatchEvent(event, IGNORE_EXCEPTION);
    return event->text().length();
}

}
