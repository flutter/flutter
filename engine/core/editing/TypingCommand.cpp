/*
 * Copyright (C) 2005, 2006, 2007, 2008 Apple Inc.  All rights reserved.
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

#include "sky/engine/core/editing/TypingCommand.h"

#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/Element.h"
#include "sky/engine/core/dom/ElementTraversal.h"
#include "sky/engine/core/editing/Editor.h"
#include "sky/engine/core/editing/FrameSelection.h"
#include "sky/engine/core/editing/InsertLineBreakCommand.h"
#include "sky/engine/core/editing/InsertParagraphSeparatorCommand.h"
#include "sky/engine/core/editing/InsertTextCommand.h"
#include "sky/engine/core/editing/SpellChecker.h"
#include "sky/engine/core/editing/VisiblePosition.h"
#include "sky/engine/core/editing/VisibleUnits.h"
#include "sky/engine/core/editing/htmlediting.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/rendering/RenderObject.h"

namespace blink {

class TypingCommandLineOperation
{
public:
    TypingCommandLineOperation(TypingCommand* typingCommand, bool selectInsertedText, const String& text)
    : m_typingCommand(typingCommand)
    , m_selectInsertedText(selectInsertedText)
    , m_text(text)
    { }

    void operator()(size_t lineOffset, size_t lineLength, bool isLastLine) const
    {
        if (isLastLine) {
            if (!lineOffset || lineLength > 0)
                m_typingCommand->insertTextRunWithoutNewlines(m_text.substring(lineOffset, lineLength), m_selectInsertedText);
        } else {
            if (lineLength > 0)
                m_typingCommand->insertTextRunWithoutNewlines(m_text.substring(lineOffset, lineLength), false);
            m_typingCommand->insertParagraphSeparator();
        }
    }

private:
    TypingCommand* m_typingCommand;
    bool m_selectInsertedText;
    const String& m_text;
};

TypingCommand::TypingCommand(Document& document, ETypingCommand commandType, const String &textToInsert, Options options, TextGranularity granularity, TextCompositionType compositionType)
    : TextInsertionBaseCommand(document)
    , m_commandType(commandType)
    , m_textToInsert(textToInsert)
    , m_openForMoreTyping(true)
    , m_selectInsertedText(options & SelectInsertedText)
    , m_smartDelete(options & SmartDelete)
    , m_granularity(granularity)
    , m_compositionType(compositionType)
    , m_openedByBackwardDelete(false)
    , m_shouldRetainAutocorrectionIndicator(options & RetainAutocorrectionIndicator)
    , m_shouldPreventSpellChecking(options & PreventSpellChecking)
{
    updatePreservesTypingStyle(m_commandType);
}

void TypingCommand::deleteSelection(Document& document, Options options)
{
    LocalFrame* frame = document.frame();
    ASSERT(frame);

    if (!frame->selection().isRange())
        return;

    if (RefPtr<TypingCommand> lastTypingCommand = lastTypingCommandIfStillOpenForTyping(frame)) {
        lastTypingCommand->setShouldPreventSpellChecking(options & PreventSpellChecking);
        lastTypingCommand->deleteSelection(options & SmartDelete);
        return;
    }

    TypingCommand::create(document, DeleteSelection, "", options)->apply();
}

void TypingCommand::deleteKeyPressed(Document& document, Options options, TextGranularity granularity)
{
    if (granularity == CharacterGranularity) {
        LocalFrame* frame = document.frame();
        if (RefPtr<TypingCommand> lastTypingCommand = lastTypingCommandIfStillOpenForTyping(frame)) {
            // If the last typing command is not Delete, open a new typing command.
            // We need to group continuous delete commands alone in a single typing command.
            if (lastTypingCommand->commandTypeOfOpenCommand() == DeleteKey) {
                updateSelectionIfDifferentFromCurrentSelection(lastTypingCommand.get(), frame);
                lastTypingCommand->setShouldPreventSpellChecking(options & PreventSpellChecking);
                lastTypingCommand->deleteKeyPressed(granularity);
                return;
            }
        }
    }

    TypingCommand::create(document, DeleteKey, "", options, granularity)->apply();
}

void TypingCommand::forwardDeleteKeyPressed(Document& document, Options options, TextGranularity granularity)
{
    // FIXME: Forward delete in TextEdit appears to open and close a new typing command.
    if (granularity == CharacterGranularity) {
        LocalFrame* frame = document.frame();
        if (RefPtr<TypingCommand> lastTypingCommand = lastTypingCommandIfStillOpenForTyping(frame)) {
            updateSelectionIfDifferentFromCurrentSelection(lastTypingCommand.get(), frame);
            lastTypingCommand->setShouldPreventSpellChecking(options & PreventSpellChecking);
            lastTypingCommand->forwardDeleteKeyPressed(granularity);
            return;
        }
    }

    TypingCommand::create(document, ForwardDeleteKey, "", options, granularity)->apply();
}

void TypingCommand::updateSelectionIfDifferentFromCurrentSelection(TypingCommand* typingCommand, LocalFrame* frame)
{
    ASSERT(frame);
    VisibleSelection currentSelection = frame->selection().selection();
    if (currentSelection == typingCommand->endingSelection())
        return;

    typingCommand->setStartingSelection(currentSelection);
    typingCommand->setEndingSelection(currentSelection);
}

void TypingCommand::insertText(Document& document, const String& text, Options options, TextCompositionType composition)
{
    LocalFrame* frame = document.frame();
    ASSERT(frame);

    if (!text.isEmpty())
        document.frame()->spellChecker().updateMarkersForWordsAffectedByEditing(isSpaceOrNewline(text[0]));

    insertText(document, text, frame->selection().selection(), options, composition);
}

// FIXME: We shouldn't need to take selectionForInsertion. It should be identical to FrameSelection's current selection.
void TypingCommand::insertText(Document& document, const String& text, const VisibleSelection& selectionForInsertion, Options options, TextCompositionType compositionType)
{
    RefPtr<LocalFrame> frame = document.frame();
    ASSERT(frame);

    VisibleSelection currentSelection = frame->selection().selection();

    String newText = dispatchBeforeTextInsertedEvent(text, selectionForInsertion, compositionType == TextCompositionUpdate);

    // Set the starting and ending selection appropriately if we are using a selection
    // that is different from the current selection.  In the future, we should change EditCommand
    // to deal with custom selections in a general way that can be used by all of the commands.
    if (RefPtr<TypingCommand> lastTypingCommand = lastTypingCommandIfStillOpenForTyping(frame.get())) {
        if (lastTypingCommand->endingSelection() != selectionForInsertion) {
            lastTypingCommand->setStartingSelection(selectionForInsertion);
            lastTypingCommand->setEndingSelection(selectionForInsertion);
        }

        lastTypingCommand->setCompositionType(compositionType);
        lastTypingCommand->setShouldRetainAutocorrectionIndicator(options & RetainAutocorrectionIndicator);
        lastTypingCommand->setShouldPreventSpellChecking(options & PreventSpellChecking);
        lastTypingCommand->insertText(newText, options & SelectInsertedText);
        return;
    }

    RefPtr<TypingCommand> cmd = TypingCommand::create(document, InsertText, newText, options, compositionType);
    applyTextInsertionCommand(frame.get(), cmd, selectionForInsertion, currentSelection);
}

void TypingCommand::insertLineBreak(Document& document, Options options)
{
    if (RefPtr<TypingCommand> lastTypingCommand = lastTypingCommandIfStillOpenForTyping(document.frame())) {
        lastTypingCommand->setShouldRetainAutocorrectionIndicator(options & RetainAutocorrectionIndicator);
        lastTypingCommand->insertLineBreak();
        return;
    }

    TypingCommand::create(document, InsertLineBreak, "", options)->apply();
}

void TypingCommand::insertParagraphSeparatorInQuotedContent(Document& document)
{
    if (RefPtr<TypingCommand> lastTypingCommand = lastTypingCommandIfStillOpenForTyping(document.frame())) {
        lastTypingCommand->insertParagraphSeparatorInQuotedContent();
        return;
    }

    TypingCommand::create(document, InsertParagraphSeparatorInQuotedContent)->apply();
}

void TypingCommand::insertParagraphSeparator(Document& document, Options options)
{
    if (RefPtr<TypingCommand> lastTypingCommand = lastTypingCommandIfStillOpenForTyping(document.frame())) {
        lastTypingCommand->setShouldRetainAutocorrectionIndicator(options & RetainAutocorrectionIndicator);
        lastTypingCommand->insertParagraphSeparator();
        return;
    }

    TypingCommand::create(document, InsertParagraphSeparator, "", options)->apply();
}

PassRefPtr<TypingCommand> TypingCommand::lastTypingCommandIfStillOpenForTyping(LocalFrame* frame)
{
    ASSERT(frame);

    RefPtr<CompositeEditCommand> lastEditCommand = frame->editor().lastEditCommand();
    if (!lastEditCommand || !lastEditCommand->isTypingCommand() || !static_cast<TypingCommand*>(lastEditCommand.get())->isOpenForMoreTyping())
        return nullptr;

    return static_cast<TypingCommand*>(lastEditCommand.get());
}

void TypingCommand::closeTyping(LocalFrame* frame)
{
    if (RefPtr<TypingCommand> lastTypingCommand = lastTypingCommandIfStillOpenForTyping(frame))
        lastTypingCommand->closeTyping();
}

void TypingCommand::doApply()
{
    if (!endingSelection().isNonOrphanedCaretOrRange())
        return;

    if (m_commandType == DeleteKey)
        if (m_commands.isEmpty())
            m_openedByBackwardDelete = true;

    switch (m_commandType) {
    case DeleteSelection:
        deleteSelection(m_smartDelete);
        return;
    case DeleteKey:
        deleteKeyPressed(m_granularity);
        return;
    case ForwardDeleteKey:
        forwardDeleteKeyPressed(m_granularity);
        return;
    case InsertLineBreak:
        insertLineBreak();
        return;
    case InsertParagraphSeparator:
        insertParagraphSeparator();
        return;
    case InsertParagraphSeparatorInQuotedContent:
        insertParagraphSeparatorInQuotedContent();
        return;
    case InsertText:
        insertText(m_textToInsert, m_selectInsertedText);
        return;
    }

    ASSERT_NOT_REACHED();
}

EditAction TypingCommand::editingAction() const
{
    return EditActionTyping;
}

void TypingCommand::markMisspellingsAfterTyping(ETypingCommand commandType)
{
    LocalFrame* frame = document().frame();
    if (!frame)
        return;

    if (!frame->spellChecker().isContinuousSpellCheckingEnabled())
        return;

    frame->spellChecker().cancelCheck();

    // Take a look at the selection that results after typing and determine whether we need to spellcheck.
    // Since the word containing the current selection is never marked, this does a check to
    // see if typing made a new word that is not in the current selection. Basically, you
    // get this by being at the end of a word and typing a space.
    VisiblePosition start(endingSelection().start(), endingSelection().affinity());
    VisiblePosition previous = start.previous();

    VisiblePosition p1 = startOfWord(previous, LeftWordIfOnBoundary);

    if (commandType == InsertParagraphSeparator) {
        VisiblePosition p2 = nextWordPosition(start);
        VisibleSelection words(p1, endOfWord(p2));
        frame->spellChecker().markMisspellingsAfterLineBreak(words);
    } else if (previous.isNotNull()) {
        VisiblePosition p2 = startOfWord(start, LeftWordIfOnBoundary);
        if (p1 != p2)
            frame->spellChecker().markMisspellingsAfterTypingToWord(p1, endingSelection());
    }
}

void TypingCommand::typingAddedToOpenCommand(ETypingCommand commandTypeForAddedTyping)
{
    LocalFrame* frame = document().frame();
    if (!frame)
        return;

    updatePreservesTypingStyle(commandTypeForAddedTyping);
    updateCommandTypeOfOpenCommand(commandTypeForAddedTyping);

    // The old spellchecking code requires that checking be done first, to prevent issues like that in 6864072, where <doesn't> is marked as misspelled.
    markMisspellingsAfterTyping(commandTypeForAddedTyping);
    frame->editor().appliedEditing(this);
}

void TypingCommand::insertText(const String &text, bool selectInsertedText)
{
    // FIXME: Need to implement selectInsertedText for cases where more than one insert is involved.
    // This requires support from insertTextRunWithoutNewlines and insertParagraphSeparator for extending
    // an existing selection; at the moment they can either put the caret after what's inserted or
    // select what's inserted, but there's no way to "extend selection" to include both an old selection
    // that ends just before where we want to insert text and the newly inserted text.
    TypingCommandLineOperation operation(this, selectInsertedText, text);
    forEachLineInString(text, operation);
}

void TypingCommand::insertTextRunWithoutNewlines(const String &text, bool selectInsertedText)
{
    RefPtr<InsertTextCommand> command = InsertTextCommand::create(document(), text, selectInsertedText,
        m_compositionType == TextCompositionNone ? InsertTextCommand::RebalanceLeadingAndTrailingWhitespaces : InsertTextCommand::RebalanceAllWhitespaces);

    applyCommandToComposite(command, endingSelection());

    typingAddedToOpenCommand(InsertText);
}

void TypingCommand::insertLineBreak()
{
    if (!canAppendNewLineFeedToSelection(endingSelection()))
        return;

    applyCommandToComposite(InsertLineBreakCommand::create(document()));
    typingAddedToOpenCommand(InsertLineBreak);
}

void TypingCommand::insertParagraphSeparator()
{
    if (!canAppendNewLineFeedToSelection(endingSelection()))
        return;

    applyCommandToComposite(InsertParagraphSeparatorCommand::create(document()));
    typingAddedToOpenCommand(InsertParagraphSeparator);
}

void TypingCommand::insertParagraphSeparatorInQuotedContent()
{
}

bool TypingCommand::makeEditableRootEmpty()
{
    Element* root = endingSelection().rootEditableElement();
    if (!root || !root->hasChildren())
        return false;

    while (Node* child = root->firstChild())
        removeNode(child);

    setEndingSelection(VisibleSelection(firstPositionInNode(root), DOWNSTREAM, endingSelection().isDirectional()));

    return true;
}

void TypingCommand::deleteKeyPressed(TextGranularity granularity)
{
    LocalFrame* frame = document().frame();
    if (!frame)
        return;

    frame->spellChecker().updateMarkersForWordsAffectedByEditing(false);

    VisibleSelection selectionToDelete;
    VisibleSelection selectionAfterUndo;

    switch (endingSelection().selectionType()) {
    case RangeSelection:
        selectionToDelete = endingSelection();
        selectionAfterUndo = selectionToDelete;
        break;
    case CaretSelection: {
        m_smartDelete = false;

        OwnPtr<FrameSelection> selection = FrameSelection::create();
        selection->setSelection(endingSelection());
        selection->modify(FrameSelection::AlterationExtend, DirectionBackward, granularity);

        VisiblePosition visibleStart(endingSelection().visibleStart());
        if (visibleStart.previous(CannotCrossEditingBoundary).isNull()) {
            // When there are no visible positions in the editing root, delete its entire contents.
            if (visibleStart.next(CannotCrossEditingBoundary).isNull() && makeEditableRootEmpty()) {
                typingAddedToOpenCommand(DeleteKey);
                return;
            }
        }

        // If the caret is at the start of a paragraph after a table, move content into the last table cell.
        if (isStartOfParagraph(visibleStart) && isFirstPositionAfterTable(visibleStart.previous(CannotCrossEditingBoundary))) {
            // Unless the caret is just before a table.  We don't want to move a table into the last table cell.
            if (isLastPositionBeforeTable(visibleStart))
                return;
            // Extend the selection backward into the last cell, then deletion will handle the move.
            selection->modify(FrameSelection::AlterationExtend, DirectionBackward, granularity);
        // If the caret is just after a table, select the table and don't delete anything.
        } else if (Element* table = isFirstPositionAfterTable(visibleStart)) {
            setEndingSelection(VisibleSelection(positionBeforeNode(table), endingSelection().start(), DOWNSTREAM, endingSelection().isDirectional()));
            typingAddedToOpenCommand(DeleteKey);
            return;
        }

        selectionToDelete = selection->selection();

        if (granularity == CharacterGranularity && selectionToDelete.end().containerNode() == selectionToDelete.start().containerNode()
            && selectionToDelete.end().computeOffsetInContainerNode() - selectionToDelete.start().computeOffsetInContainerNode() > 1) {
            // If there are multiple Unicode code points to be deleted, adjust the range to match platform conventions.
            selectionToDelete.setWithoutValidation(selectionToDelete.end(), selectionToDelete.end().previous(BackwardDeletion));
        }

        if (!startingSelection().isRange() || selectionToDelete.base() != startingSelection().start())
            selectionAfterUndo = selectionToDelete;
        else
            // It's a little tricky to compute what the starting selection would have been in the original document.
            // We can't let the VisibleSelection class's validation kick in or it'll adjust for us based on
            // the current state of the document and we'll get the wrong result.
            selectionAfterUndo.setWithoutValidation(startingSelection().end(), selectionToDelete.extent());
        break;
    }
    case NoSelection:
        ASSERT_NOT_REACHED();
        break;
    }

    ASSERT(!selectionToDelete.isNone());
    if (selectionToDelete.isNone())
        return;

    if (selectionToDelete.isCaret())
        return;

    // On Mac, make undo select everything that has been deleted, unless an undo will undo more than just this deletion.
    // FIXME: This behaves like TextEdit except for the case where you open with text insertion and then delete
    // more text than you insert.  In that case all of the text that was around originally should be selected.
    if (frame->editor().behavior().shouldUndoOfDeleteSelectText() && m_openedByBackwardDelete)
        setStartingSelection(selectionAfterUndo);
    CompositeEditCommand::deleteSelection(selectionToDelete, m_smartDelete);
    setSmartDelete(false);
    typingAddedToOpenCommand(DeleteKey);
}

void TypingCommand::forwardDeleteKeyPressed(TextGranularity granularity)
{
    LocalFrame* frame = document().frame();
    if (!frame)
        return;

    frame->spellChecker().updateMarkersForWordsAffectedByEditing(false);

    VisibleSelection selectionToDelete;
    VisibleSelection selectionAfterUndo;

    switch (endingSelection().selectionType()) {
    case RangeSelection:
        selectionToDelete = endingSelection();
        selectionAfterUndo = selectionToDelete;
        break;
    case CaretSelection: {
        m_smartDelete = false;

        // Handle delete at beginning-of-block case.
        // Do nothing in the case that the caret is at the start of a
        // root editable element or at the start of a document.
        OwnPtr<FrameSelection> selection = FrameSelection::create();
        selection->setSelection(endingSelection());
        selection->modify(FrameSelection::AlterationExtend, DirectionForward, granularity);

        Position downstreamEnd = endingSelection().end().downstream();
        VisiblePosition visibleEnd = endingSelection().visibleEnd();
        if (visibleEnd == endOfParagraph(visibleEnd))
            downstreamEnd = visibleEnd.next(CannotCrossEditingBoundary).deepEquivalent().downstream();
        // When deleting tables: Select the table first, then perform the deletion
        if (isRenderedTableElement(downstreamEnd.containerNode()) && downstreamEnd.computeOffsetInContainerNode() <= caretMinOffset(downstreamEnd.containerNode())) {
            setEndingSelection(VisibleSelection(endingSelection().end(), positionAfterNode(downstreamEnd.containerNode()), DOWNSTREAM, endingSelection().isDirectional()));
            typingAddedToOpenCommand(ForwardDeleteKey);
            return;
        }

        // deleting to end of paragraph when at end of paragraph needs to merge the next paragraph (if any)
        if (granularity == ParagraphBoundary && selection->selection().isCaret() && isEndOfParagraph(selection->selection().visibleEnd()))
            selection->modify(FrameSelection::AlterationExtend, DirectionForward, CharacterGranularity);

        selectionToDelete = selection->selection();
        if (!startingSelection().isRange() || selectionToDelete.base() != startingSelection().start())
            selectionAfterUndo = selectionToDelete;
        else {
            // It's a little tricky to compute what the starting selection would have been in the original document.
            // We can't let the VisibleSelection class's validation kick in or it'll adjust for us based on
            // the current state of the document and we'll get the wrong result.
            Position extent = startingSelection().end();
            if (extent.containerNode() != selectionToDelete.end().containerNode())
                extent = selectionToDelete.extent();
            else {
                int extraCharacters;
                if (selectionToDelete.start().containerNode() == selectionToDelete.end().containerNode())
                    extraCharacters = selectionToDelete.end().computeOffsetInContainerNode() - selectionToDelete.start().computeOffsetInContainerNode();
                else
                    extraCharacters = selectionToDelete.end().computeOffsetInContainerNode();
                extent = Position(extent.containerNode(), extent.computeOffsetInContainerNode() + extraCharacters, Position::PositionIsOffsetInAnchor);
            }
            selectionAfterUndo.setWithoutValidation(startingSelection().start(), extent);
        }
        break;
    }
    case NoSelection:
        ASSERT_NOT_REACHED();
        break;
    }

    ASSERT(!selectionToDelete.isNone());
    if (selectionToDelete.isNone())
        return;

    if (selectionToDelete.isCaret())
        return;

    // Make undo select what was deleted on Mac alone
    if (frame->editor().behavior().shouldUndoOfDeleteSelectText())
        setStartingSelection(selectionAfterUndo);
    CompositeEditCommand::deleteSelection(selectionToDelete, m_smartDelete);
    setSmartDelete(false);
    typingAddedToOpenCommand(ForwardDeleteKey);
}

void TypingCommand::deleteSelection(bool smartDelete)
{
    CompositeEditCommand::deleteSelection(smartDelete);
    typingAddedToOpenCommand(DeleteSelection);
}

void TypingCommand::updatePreservesTypingStyle(ETypingCommand commandType)
{
    switch (commandType) {
    case DeleteSelection:
    case DeleteKey:
    case ForwardDeleteKey:
    case InsertParagraphSeparator:
    case InsertLineBreak:
        m_preservesTypingStyle = true;
        return;
    case InsertParagraphSeparatorInQuotedContent:
    case InsertText:
        m_preservesTypingStyle = false;
        return;
    }
    ASSERT_NOT_REACHED();
    m_preservesTypingStyle = false;
}

bool TypingCommand::isTypingCommand() const
{
    return true;
}

} // namespace blink
