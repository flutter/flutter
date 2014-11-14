/*
 * Copyright (C) 2006, 2007, 2008, 2011 Apple Inc. All rights reserved.
 * Copyright (C) 2008 Nokia Corporation and/or its subsidiary(-ies)
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
#include "core/editing/Editor.h"

#include "bindings/core/v8/ExceptionStatePlaceholder.h"
#include "core/CSSPropertyNames.h"
#include "core/EventNames.h"
#include "core/css/CSSComputedStyleDeclaration.h"
#include "core/css/StylePropertySet.h"
#include "core/dom/DocumentFragment.h"
#include "core/dom/DocumentMarkerController.h"
#include "core/dom/NodeTraversal.h"
#include "core/dom/Text.h"
#include "core/editing/DeleteSelectionCommand.h"
#include "core/editing/InputMethodController.h"
#include "core/editing/RenderedPosition.h"
#include "core/editing/ReplaceSelectionCommand.h"
#include "core/editing/SpellChecker.h"
#include "core/editing/TypingCommand.h"
#include "core/editing/UndoStack.h"
#include "core/editing/VisibleUnits.h"
#include "core/editing/htmlediting.h"
#include "core/editing/markup.h"
#include "core/events/KeyboardEvent.h"
#include "core/events/ScopedEventQueue.h"
#include "core/events/TextEvent.h"
#include "core/fetch/ImageResource.h"
#include "core/fetch/ResourceFetcher.h"
#include "core/frame/FrameView.h"
#include "core/frame/LocalFrame.h"
#include "core/frame/Settings.h"
#include "core/frame/UseCounter.h"
#include "core/html/HTMLCanvasElement.h"
#include "core/html/HTMLImageElement.h"
#include "core/html/parser/HTMLParserIdioms.h"
#include "core/loader/EmptyClients.h"
#include "core/page/EditorClient.h"
#include "core/page/EventHandler.h"
#include "core/page/FocusController.h"
#include "core/page/Page.h"
#include "core/rendering/HitTestResult.h"
#include "core/rendering/RenderImage.h"
#include "platform/weborigin/KURL.h"
#include "wtf/unicode/CharacterNames.h"

namespace blink {

using namespace WTF::Unicode;

Editor::RevealSelectionScope::RevealSelectionScope(Editor* editor)
    : m_editor(editor)
{
    ++m_editor->m_preventRevealSelection;
}

Editor::RevealSelectionScope::~RevealSelectionScope()
{
    ASSERT(m_editor->m_preventRevealSelection);
    --m_editor->m_preventRevealSelection;
    if (!m_editor->m_preventRevealSelection)
        m_editor->m_frame.selection().revealSelection(ScrollAlignment::alignToEdgeIfNeeded, RevealExtent);
}

// When an event handler has moved the selection outside of a text control
// we should use the target control's selection for this editing operation.
VisibleSelection Editor::selectionForCommand(Event* event)
{
    return m_frame.selection().selection();
}

// Function considers Mac editing behavior a fallback when Page or Settings is not available.
EditingBehavior Editor::behavior() const
{
    return EditingBehavior();
}

static EditorClient& emptyEditorClient()
{
    DEFINE_STATIC_LOCAL(EmptyEditorClient, client, ());
    return client;
}

EditorClient& Editor::client() const
{
    if (Page* page = m_frame.page())
        return page->editorClient();
    return emptyEditorClient();
}

UndoStack* Editor::undoStack() const
{
    if (Page* page = m_frame.page())
        return &page->undoStack();
    return 0;
}

bool Editor::handleTextEvent(TextEvent* event)
{
    // Default event handling for Drag and Drop will be handled by DragController
    // so we leave the event for it.
    if (event->isDrop())
        return false;

    if (event->isPaste()) {
        if (event->pastingFragment())
            replaceSelectionWithFragment(event->pastingFragment(), false, event->shouldSmartReplace(), event->shouldMatchStyle());
        else
            replaceSelectionWithText(event->data(), false, event->shouldSmartReplace());
        return true;
    }

    String data = event->data();
    if (data == "\n") {
        if (event->isLineBreak())
            return insertLineBreak();
        return insertParagraphSeparator();
    }

    return insertTextWithoutSendingTextEvent(data, false, event);
}

bool Editor::canEdit() const
{
    return m_frame.selection().rootEditableElement();
}

bool Editor::canEditRichly() const
{
    return m_frame.selection().isContentRichlyEditable();
}

// WinIE uses onbeforecut and onbeforepaste to enables the cut and paste menu items. They
// also send onbeforecopy, apparently for symmetry, but it doesn't affect the menu items.
// We need to use onbeforecopy as a real menu enabler because we allow elements that are not
// normally selectable to implement copy/paste (like divs, or a document body).

bool Editor::canDHTMLCut()
{
    return false;
}

bool Editor::canDHTMLCopy()
{
    return false;
}

bool Editor::canDHTMLPaste()
{
    return false;
}

bool Editor::canCut() const
{
    return canCopy() && canDelete();
}

bool Editor::canCopy() const
{
    FrameSelection& selection = m_frame.selection();
    return selection.isRange() && !selection.isInPasswordField();
}

bool Editor::canPaste() const
{
    return canEdit();
}

bool Editor::canDelete() const
{
    FrameSelection& selection = m_frame.selection();
    return selection.isRange() && selection.rootEditableElement();
}

bool Editor::canDeleteRange(Range* range) const
{
    Node* startContainer = range->startContainer();
    Node* endContainer = range->endContainer();
    if (!startContainer || !endContainer)
        return false;

    if (!startContainer->hasEditableStyle() || !endContainer->hasEditableStyle())
        return false;

    if (range->collapsed()) {
        VisiblePosition start(range->startPosition(), DOWNSTREAM);
        VisiblePosition previous = start.previous();
        // FIXME: We sometimes allow deletions at the start of editable roots, like when the caret is in an empty list item.
        if (previous.isNull() || previous.deepEquivalent().deprecatedNode()->rootEditableElement() != startContainer->rootEditableElement())
            return false;
    }
    return true;
}

bool Editor::smartInsertDeleteEnabled() const
{
    if (Settings* settings = m_frame.settings())
        return settings->smartInsertDeleteEnabled();
    return false;
}

bool Editor::canSmartCopyOrDelete() const
{
    return smartInsertDeleteEnabled() && m_frame.selection().granularity() == WordGranularity;
}

bool Editor::deleteWithDirection(SelectionDirection direction, TextGranularity granularity, bool isTypingAction)
{
    if (!canEdit())
        return false;

    if (m_frame.selection().isRange()) {
        if (isTypingAction) {
            ASSERT(m_frame.document());
            TypingCommand::deleteKeyPressed(*m_frame.document(), canSmartCopyOrDelete() ? TypingCommand::SmartDelete : 0, granularity);
            revealSelectionAfterEditingOperation();
        } else {
            deleteSelectionWithSmartDelete(canSmartCopyOrDelete());
            // Implicitly calls revealSelectionAfterEditingOperation().
        }
    } else {
        TypingCommand::Options options = 0;
        if (canSmartCopyOrDelete())
            options |= TypingCommand::SmartDelete;
        switch (direction) {
        case DirectionForward:
        case DirectionRight:
            ASSERT(m_frame.document());
            TypingCommand::forwardDeleteKeyPressed(*m_frame.document(), options, granularity);
            break;
        case DirectionBackward:
        case DirectionLeft:
            ASSERT(m_frame.document());
            TypingCommand::deleteKeyPressed(*m_frame.document(), options, granularity);
            break;
        }
        revealSelectionAfterEditingOperation();
    }

    return true;
}

void Editor::deleteSelectionWithSmartDelete(bool smartDelete)
{
    if (m_frame.selection().isNone())
        return;

    ASSERT(m_frame.document());
    DeleteSelectionCommand::create(*m_frame.document(), smartDelete)->apply();
}

void Editor::pasteAsPlainText(const String& pastingText, bool smartReplace)
{
    Element* target = findEventTargetFromSelection();
    if (!target)
        return;
    target->dispatchEvent(TextEvent::createForPlainTextPaste(m_frame.domWindow(), pastingText, smartReplace), IGNORE_EXCEPTION);
}

void Editor::pasteAsFragment(PassRefPtr<DocumentFragment> pastingFragment, bool smartReplace, bool matchStyle)
{
    Element* target = findEventTargetFromSelection();
    if (!target)
        return;
    target->dispatchEvent(TextEvent::createForFragmentPaste(m_frame.domWindow(), pastingFragment, smartReplace, matchStyle), IGNORE_EXCEPTION);
}

bool Editor::tryDHTMLCopy()
{
    return false;
}

bool Editor::tryDHTMLCut()
{
    return false;
}

void Editor::replaceSelectionWithFragment(PassRefPtr<DocumentFragment> fragment, bool selectReplacement, bool smartReplace, bool matchStyle)
{
    if (m_frame.selection().isNone() || !m_frame.selection().isContentEditable() || !fragment)
        return;

    ReplaceSelectionCommand::CommandOptions options = ReplaceSelectionCommand::PreventNesting;
    if (selectReplacement)
        options |= ReplaceSelectionCommand::SelectReplacement;
    if (smartReplace)
        options |= ReplaceSelectionCommand::SmartReplace;
    if (matchStyle)
        options |= ReplaceSelectionCommand::MatchStyle;
    ASSERT(m_frame.document());
    ReplaceSelectionCommand::create(*m_frame.document(), fragment, options, EditActionPaste)->apply();
    revealSelectionAfterEditingOperation();

    if (m_frame.selection().isInPasswordField() || !spellChecker().isContinuousSpellCheckingEnabled())
        return;
    spellChecker().chunkAndMarkAllMisspellingsAndBadGrammar(m_frame.selection().rootEditableElement());
}

void Editor::replaceSelectionWithText(const String& text, bool selectReplacement, bool smartReplace)
{
    replaceSelectionWithFragment(nullptr, selectReplacement, smartReplace, true);
}

PassRefPtr<Range> Editor::selectedRange()
{
    return m_frame.selection().toNormalizedRange();
}

bool Editor::shouldDeleteRange(Range* range) const
{
    if (!range || range->collapsed())
        return false;

    return canDeleteRange(range);
}

void Editor::notifyComponentsOnChangedSelection(const VisibleSelection& oldSelection, FrameSelection::SetSelectionOptions options)
{
    client().respondToChangedSelection(&m_frame, m_frame.selection().selectionType());
}

void Editor::respondToChangedContents(const VisibleSelection& endingSelection)
{
    spellChecker().updateMarkersForWordsAffectedByEditing(true);
    client().respondToChangedContents();
}

void Editor::clearLastEditCommand()
{
    m_lastEditCommand.clear();
}

Element* Editor::findEventTargetFrom(const VisibleSelection& selection) const
{
    Element* target = selection.start().element();
    if (!target)
        target = m_frame.document()->documentElement();

    return target;
}

Element* Editor::findEventTargetFromSelection() const
{
    return findEventTargetFrom(m_frame.selection().selection());
}

bool Editor::selectionStartHasStyle(CSSPropertyID propertyID, const String& value) const
{
    return EditingStyle::create(propertyID, value)->triStateOfStyle(
        EditingStyle::styleAtSelectionStart(m_frame.selection().selection(), propertyID == CSSPropertyBackgroundColor).get());
}

TriState Editor::selectionHasStyle(CSSPropertyID propertyID, const String& value) const
{
    return EditingStyle::create(propertyID, value)->triStateOfStyle(m_frame.selection().selection());
}

String Editor::selectionStartCSSPropertyValue(CSSPropertyID propertyID)
{
    RefPtr<EditingStyle> selectionStyle = EditingStyle::styleAtSelectionStart(m_frame.selection().selection(),
        propertyID == CSSPropertyBackgroundColor);
    if (!selectionStyle || !selectionStyle->style())
        return String();

    if (propertyID == CSSPropertyFontSize)
        return String::number(selectionStyle->legacyFontSize(m_frame.document()));
    return selectionStyle->style()->getPropertyValue(propertyID);
}

static void dispatchEditableContentChangedEvents(PassRefPtr<Element> startRoot, PassRefPtr<Element> endRoot)
{
    if (startRoot)
        startRoot->dispatchEvent(Event::create(EventTypeNames::webkitEditableContentChanged), IGNORE_EXCEPTION);
    if (endRoot && endRoot != startRoot)
        endRoot->dispatchEvent(Event::create(EventTypeNames::webkitEditableContentChanged), IGNORE_EXCEPTION);
}

void Editor::appliedEditing(PassRefPtr<CompositeEditCommand> cmd)
{
    EventQueueScope scope;
    m_frame.document()->updateLayout();

    EditCommandComposition* composition = cmd->composition();
    ASSERT(composition);
    dispatchEditableContentChangedEvents(composition->startingRootEditableElement(), composition->endingRootEditableElement());
    VisibleSelection newSelection(cmd->endingSelection());

    // Don't clear the typing style with this selection change. We do those things elsewhere if necessary.
    changeSelectionAfterCommand(newSelection, 0);

    if (!cmd->preservesTypingStyle())
        m_frame.selection().clearTypingStyle();

    // Command will be equal to last edit command only in the case of typing
    if (m_lastEditCommand.get() == cmd) {
        ASSERT(cmd->isTypingCommand());
    } else {
        // Only register a new undo command if the command passed in is
        // different from the last command
        m_lastEditCommand = cmd;
        if (UndoStack* undoStack = this->undoStack())
            undoStack->registerUndoStep(m_lastEditCommand->ensureComposition());
    }

    respondToChangedContents(newSelection);
}

void Editor::unappliedEditing(PassRefPtr<EditCommandComposition> cmd)
{
    EventQueueScope scope;
    m_frame.document()->updateLayout();

    dispatchEditableContentChangedEvents(cmd->startingRootEditableElement(), cmd->endingRootEditableElement());

    VisibleSelection newSelection(cmd->startingSelection());
    newSelection.validatePositionsIfNeeded();
    if (newSelection.start().document() == m_frame.document() && newSelection.end().document() == m_frame.document())
        changeSelectionAfterCommand(newSelection, FrameSelection::CloseTyping | FrameSelection::ClearTypingStyle);

    m_lastEditCommand = nullptr;
    if (UndoStack* undoStack = this->undoStack())
        undoStack->registerRedoStep(cmd);
    respondToChangedContents(newSelection);
}

void Editor::reappliedEditing(PassRefPtr<EditCommandComposition> cmd)
{
    EventQueueScope scope;
    m_frame.document()->updateLayout();

    dispatchEditableContentChangedEvents(cmd->startingRootEditableElement(), cmd->endingRootEditableElement());

    VisibleSelection newSelection(cmd->endingSelection());
    changeSelectionAfterCommand(newSelection, FrameSelection::CloseTyping | FrameSelection::ClearTypingStyle);

    m_lastEditCommand = nullptr;
    if (UndoStack* undoStack = this->undoStack())
        undoStack->registerUndoStep(cmd);
    respondToChangedContents(newSelection);
}

PassOwnPtr<Editor> Editor::create(LocalFrame& frame)
{
    return adoptPtr(new Editor(frame));
}

Editor::Editor(LocalFrame& frame)
    : m_frame(frame)
    , m_preventRevealSelection(0)
    // This is off by default, since most editors want this behavior (this matches IE but not FF).
    , m_shouldStyleWithCSS(false)
    , m_areMarkedTextMatchesHighlighted(false)
    , m_defaultParagraphSeparator(EditorParagraphSeparatorIsDiv)
    , m_overwriteModeEnabled(false)
{
}

Editor::~Editor()
{
}

void Editor::clear()
{
    m_frame.inputMethodController().clear();
    m_shouldStyleWithCSS = false;
    m_defaultParagraphSeparator = EditorParagraphSeparatorIsDiv;
}

bool Editor::insertText(const String& text, KeyboardEvent* triggeringEvent)
{
    return m_frame.eventHandler().handleTextInputEvent(text, triggeringEvent);
}

bool Editor::insertTextWithoutSendingTextEvent(const String& text, bool selectInsertedText, TextEvent* triggeringEvent)
{
    if (text.isEmpty())
        return false;

    VisibleSelection selection = selectionForCommand(triggeringEvent);
    if (!selection.isContentEditable())
        return false;

    spellChecker().updateMarkersForWordsAffectedByEditing(isSpaceOrNewline(text[0]));

    // Get the selection to use for the event that triggered this insertText.
    // If the event handler changed the selection, we may want to use a different selection
    // that is contained in the event target.
    selection = selectionForCommand(triggeringEvent);
    if (selection.isContentEditable()) {
        if (Node* selectionStart = selection.start().deprecatedNode()) {
            RefPtr<Document> document(selectionStart->document());

            // Insert the text
            TypingCommand::Options options = 0;
            if (selectInsertedText)
                options |= TypingCommand::SelectInsertedText;
            TypingCommand::insertText(*document.get(), text, selection, options, triggeringEvent && triggeringEvent->isComposition() ? TypingCommand::TextCompositionConfirm : TypingCommand::TextCompositionNone);

            // Reveal the current selection
            if (LocalFrame* editedFrame = document->frame()) {
                if (Page* page = editedFrame->page())
                    page->focusController().focusedOrMainFrame()->selection().revealSelection(ScrollAlignment::alignCenterIfNeeded);
            }
        }
    }

    return true;
}

bool Editor::insertLineBreak()
{
    if (!canEdit())
        return false;

    VisiblePosition caret = m_frame.selection().selection().visibleStart();
    bool alignToEdge = isEndOfEditableOrNonEditableContent(caret);
    ASSERT(m_frame.document());
    TypingCommand::insertLineBreak(*m_frame.document(), 0);
    revealSelectionAfterEditingOperation(alignToEdge ? ScrollAlignment::alignToEdgeIfNeeded : ScrollAlignment::alignCenterIfNeeded);

    return true;
}

bool Editor::insertParagraphSeparator()
{
    if (!canEdit())
        return false;

    if (!canEditRichly())
        return insertLineBreak();

    VisiblePosition caret = m_frame.selection().selection().visibleStart();
    bool alignToEdge = isEndOfEditableOrNonEditableContent(caret);
    ASSERT(m_frame.document());
    TypingCommand::insertParagraphSeparator(*m_frame.document(), 0);
    revealSelectionAfterEditingOperation(alignToEdge ? ScrollAlignment::alignToEdgeIfNeeded : ScrollAlignment::alignCenterIfNeeded);

    return true;
}

void Editor::cut()
{
}

void Editor::copy()
{
}

void Editor::paste()
{
}

void Editor::pasteAsPlainText()
{
}

void Editor::performDelete()
{
    if (!canDelete())
        return;
    deleteSelectionWithSmartDelete(canSmartCopyOrDelete());
}

void Editor::countEvent(ExecutionContext* executionContext, const Event* event)
{
}

void Editor::copyImage(const HitTestResult& result)
{
}

bool Editor::canUndo()
{
    if (UndoStack* undoStack = this->undoStack())
        return undoStack->canUndo();
    return false;
}

void Editor::undo()
{
    if (UndoStack* undoStack = this->undoStack())
        undoStack->undo();
}

bool Editor::canRedo()
{
    if (UndoStack* undoStack = this->undoStack())
        return undoStack->canRedo();
    return false;
}

void Editor::redo()
{
    if (UndoStack* undoStack = this->undoStack())
        undoStack->redo();
}

void Editor::setBaseWritingDirection(WritingDirection direction)
{
    RefPtr<MutableStylePropertySet> style = MutableStylePropertySet::create();
    style->setProperty(CSSPropertyDirection, direction == LeftToRightWritingDirection ? "ltr" : direction == RightToLeftWritingDirection ? "rtl" : "inherit", false);
}

void Editor::revealSelectionAfterEditingOperation(const ScrollAlignment& alignment, RevealExtentOption revealExtentOption)
{
    if (m_preventRevealSelection)
        return;

    m_frame.selection().revealSelection(alignment, revealExtentOption);
}

void Editor::transpose()
{
    if (!canEdit())
        return;

    VisibleSelection selection = m_frame.selection().selection();
    if (!selection.isCaret())
        return;

    // Make a selection that goes back one character and forward two characters.
    VisiblePosition caret = selection.visibleStart();
    VisiblePosition next = isEndOfParagraph(caret) ? caret : caret.next();
    VisiblePosition previous = next.previous();
    if (next == previous)
        return;
    previous = previous.previous();
    if (!inSameParagraph(next, previous))
        return;
    RefPtr<Range> range = makeRange(previous, next);
    if (!range)
        return;
    VisibleSelection newSelection(range.get(), DOWNSTREAM);

    // Transpose the two characters.
    String text = plainText(range.get());
    if (text.length() != 2)
        return;
    String transposed = text.right(1) + text.left(1);

    // Select the two characters.
    if (newSelection != m_frame.selection().selection())
        m_frame.selection().setSelection(newSelection);

    // Insert the transposed characters.
    replaceSelectionWithText(transposed, false, false);
}

void Editor::changeSelectionAfterCommand(const VisibleSelection& newSelection,  FrameSelection::SetSelectionOptions options)
{
    // If the new selection is orphaned, then don't update the selection.
    if (newSelection.start().isOrphan() || newSelection.end().isOrphan())
        return;

    // See <rdar://problem/5729315> Some shouldChangeSelectedDOMRange contain Ranges for selections that are no longer valid
    bool selectionDidNotChangeDOMPosition = newSelection == m_frame.selection().selection();
    m_frame.selection().setSelection(newSelection, options);

    // Some editing operations change the selection visually without affecting its position within the DOM.
    // For example when you press return in the following (the caret is marked by ^):
    // <div contentEditable="true"><div>^Hello</div></div>
    // WebCore inserts <div><br></div> *before* the current block, which correctly moves the paragraph down but which doesn't
    // change the caret's DOM position (["hello", 0]). In these situations the above FrameSelection::setSelection call
    // does not call EditorClient::respondToChangedSelection(), which, on the Mac, sends selection change notifications and
    // starts a new kill ring sequence, but we want to do these things (matches AppKit).
    if (selectionDidNotChangeDOMPosition)
        client().respondToChangedSelection(&m_frame, m_frame.selection().selectionType());
}

IntRect Editor::firstRectForRange(Range* range) const
{
    LayoutUnit extraWidthToEndOfLine = 0;
    ASSERT(range->startContainer());
    ASSERT(range->endContainer());

    IntRect startCaretRect = RenderedPosition(VisiblePosition(range->startPosition()).deepEquivalent(), DOWNSTREAM).absoluteRect(&extraWidthToEndOfLine);
    if (startCaretRect == LayoutRect())
        return IntRect();

    IntRect endCaretRect = RenderedPosition(VisiblePosition(range->endPosition()).deepEquivalent(), UPSTREAM).absoluteRect();
    if (endCaretRect == LayoutRect())
        return IntRect();

    if (startCaretRect.y() == endCaretRect.y()) {
        // start and end are on the same line
        return IntRect(std::min(startCaretRect.x(), endCaretRect.x()),
            startCaretRect.y(),
            abs(endCaretRect.x() - startCaretRect.x()),
            std::max(startCaretRect.height(), endCaretRect.height()));
    }

    // start and end aren't on the same line, so go from start to the end of its line
    return IntRect(startCaretRect.x(),
        startCaretRect.y(),
        startCaretRect.width() + extraWidthToEndOfLine,
        startCaretRect.height());
}

bool Editor::findString(const String& target, bool forward, bool caseFlag, bool wrapFlag, bool startInSelection)
{
    FindOptions options = (forward ? 0 : Backwards) | (caseFlag ? 0 : CaseInsensitive) | (wrapFlag ? WrapAround : 0) | (startInSelection ? StartInSelection : 0);
    return findString(target, options);
}

bool Editor::findString(const String& target, FindOptions options)
{
    VisibleSelection selection = m_frame.selection().selection();

    RefPtr<Range> resultRange = rangeOfString(target, selection.firstRange().get(), options);

    if (!resultRange)
        return false;

    m_frame.selection().setSelection(VisibleSelection(resultRange.get(), DOWNSTREAM));
    m_frame.selection().revealSelection();
    return true;
}

PassRefPtr<Range> Editor::findStringAndScrollToVisible(const String& target, Range* previousMatch, FindOptions options)
{
    RefPtr<Range> nextMatch = rangeOfString(target, previousMatch, options);
    if (!nextMatch)
        return nullptr;

    nextMatch->firstNode()->renderer()->scrollRectToVisible(nextMatch->boundingBox(),
        ScrollAlignment::alignCenterIfNeeded, ScrollAlignment::alignCenterIfNeeded);

    return nextMatch.release();
}

static PassRefPtr<Range> findStringBetweenPositions(const String& target, const Position& start, const Position& end, FindOptions options)
{
    Position searchStart(start);
    Position searchEnd(end);

    bool forward = !(options & Backwards);

    while (true) {
        Position resultStart;
        Position resultEnd;
        findPlainText(searchStart, searchEnd, target, options, resultStart, resultEnd);
        if (resultStart == resultEnd)
            return nullptr;

        RefPtr<Range> resultRange = Range::create(*resultStart.document(), resultStart, resultEnd);
        if (!resultRange->collapsed())
            return resultRange.release();

        // Found text spans over multiple TreeScopes. Since it's impossible to return such section as a Range,
        // we skip this match and seek for the next occurrence.
        // FIXME: Handle this case.
        if (forward)
            searchStart = resultStart.next();
        else
            searchEnd = resultEnd.previous();
    }

    ASSERT_NOT_REACHED();
    return nullptr;
}

PassRefPtr<Range> Editor::rangeOfString(const String& target, Range* referenceRange, FindOptions options)
{
    if (target.isEmpty())
        return nullptr;

    // Start from an edge of the reference range. Which edge is used depends on whether we're searching forward or
    // backward, and whether startInSelection is set.
    Position searchStart = firstPositionInNode(m_frame.document());
    Position searchEnd = lastPositionInNode(m_frame.document());

    bool forward = !(options & Backwards);
    bool startInReferenceRange = referenceRange && (options & StartInSelection);
    if (referenceRange) {
        if (forward)
            searchStart = startInReferenceRange ? referenceRange->startPosition() : referenceRange->endPosition();
        else
            searchEnd = startInReferenceRange ? referenceRange->endPosition() : referenceRange->startPosition();
    }

    RefPtr<Range> resultRange = findStringBetweenPositions(target, searchStart, searchEnd, options);

    // If we started in the reference range and the found range exactly matches the reference range, find again.
    // Build a selection with the found range to remove collapsed whitespace.
    // Compare ranges instead of selection objects to ignore the way that the current selection was made.
    if (resultRange && startInReferenceRange && areRangesEqual(VisibleSelection(resultRange.get()).toNormalizedRange().get(), referenceRange)) {
        if (forward)
            searchStart = resultRange->endPosition();
        else
            searchEnd = resultRange->startPosition();
        resultRange = findStringBetweenPositions(target, searchStart, searchEnd, options);
    }

    if (!resultRange && options & WrapAround) {
        searchStart = firstPositionInNode(m_frame.document());
        searchEnd = lastPositionInNode(m_frame.document());
        resultRange = findStringBetweenPositions(target, searchStart, searchEnd, options);
    }

    return resultRange.release();
}

void Editor::setMarkedTextMatchesAreHighlighted(bool flag)
{
    if (flag == m_areMarkedTextMatchesHighlighted)
        return;

    m_areMarkedTextMatchesHighlighted = flag;
    m_frame.document()->markers().repaintMarkers(DocumentMarker::TextMatch);
}

void Editor::respondToChangedSelection(const VisibleSelection& oldSelection, FrameSelection::SetSelectionOptions options)
{
    spellChecker().respondToChangedSelection(oldSelection, options);
    m_frame.inputMethodController().cancelCompositionIfSelectionIsInvalid();
    notifyComponentsOnChangedSelection(oldSelection, options);
}

SpellChecker& Editor::spellChecker() const
{
    return m_frame.spellChecker();
}

void Editor::toggleOverwriteModeEnabled()
{
    m_overwriteModeEnabled = !m_overwriteModeEnabled;
    frame().selection().setShouldShowBlockCursor(m_overwriteModeEnabled);
}

} // namespace blink
