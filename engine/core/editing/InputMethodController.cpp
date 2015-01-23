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

#include "sky/engine/config.h"
#include "sky/engine/core/editing/InputMethodController.h"

#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/Element.h"
#include "sky/engine/core/dom/Range.h"
#include "sky/engine/core/dom/Text.h"
#include "sky/engine/core/editing/Editor.h"
#include "sky/engine/core/editing/TypingCommand.h"
#include "sky/engine/core/events/CompositionEvent.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/page/Chrome.h"
#include "sky/engine/core/page/ChromeClient.h"
#include "sky/engine/core/page/EventHandler.h"
#include "sky/engine/core/rendering/RenderObject.h"

namespace blink {

InputMethodController::SelectionOffsetsScope::SelectionOffsetsScope(InputMethodController* inputMethodController)
    : m_inputMethodController(inputMethodController)
    , m_offsets(inputMethodController->getSelectionOffsets())
{
}

InputMethodController::SelectionOffsetsScope::~SelectionOffsetsScope()
{
    m_inputMethodController->setSelectionOffsets(m_offsets);
}

// ----------------------------

PassOwnPtr<InputMethodController> InputMethodController::create(LocalFrame& frame)
{
    return adoptPtr(new InputMethodController(frame));
}

InputMethodController::InputMethodController(LocalFrame& frame)
    : m_frame(frame)
    , m_compositionStart(0)
    , m_compositionEnd(0)
{
}

InputMethodController::~InputMethodController()
{
}

bool InputMethodController::hasComposition() const
{
    return m_compositionNode && m_compositionNode->isContentEditable();
}

inline Editor& InputMethodController::editor() const
{
    return m_frame.editor();
}

void InputMethodController::clear()
{
    m_compositionNode = nullptr;
    m_customCompositionUnderlines.clear();
}

bool InputMethodController::insertTextForConfirmedComposition(const String& text)
{
    return m_frame.eventHandler().handleTextInputEvent(text, 0, TextEventInputComposition);
}

void InputMethodController::selectComposition() const
{
    RefPtr<Range> range = compositionRange();
    if (!range)
        return;

    // The composition can start inside a composed character sequence, so we have to override checks.
    // See <http://bugs.webkit.org/show_bug.cgi?id=15781>
    VisibleSelection selection;
    selection.setWithoutValidation(range->startPosition(), range->endPosition());
    m_frame.selection().setSelection(selection, 0);
}

bool InputMethodController::confirmComposition()
{
    if (!hasComposition())
        return false;
    return finishComposition(m_compositionNode->data().substring(m_compositionStart, m_compositionEnd - m_compositionStart), ConfirmComposition);
}

bool InputMethodController::confirmComposition(const String& text)
{
    return finishComposition(text, ConfirmComposition);
}

bool InputMethodController::confirmCompositionOrInsertText(const String& text, ConfirmCompositionBehavior confirmBehavior)
{
    if (!hasComposition()) {
        if (!text.length())
            return false;
        editor().insertText(text, 0);
        return true;
    }

    if (text.length()) {
        confirmComposition(text);
        return true;
    }

    if (confirmBehavior != KeepSelection)
        return confirmComposition();

    SelectionOffsetsScope selectionOffsetsScope(this);
    return confirmComposition();
}

void InputMethodController::confirmCompositionAndResetState()
{
    if (!hasComposition())
        return;

    // ChromeClient::willSetInputMethodState() resets input method and the composition string is committed.
    m_frame.chromeClient().willSetInputMethodState();
}

void InputMethodController::cancelComposition()
{
    finishComposition(emptyString(), CancelComposition);
}

void InputMethodController::cancelCompositionIfSelectionIsInvalid()
{
    if (!hasComposition() || editor().preventRevealSelection())
        return;

    // Check if selection start and selection end are valid.
    Position start = m_frame.selection().start();
    Position end = m_frame.selection().end();
    if (start.containerNode() == m_compositionNode
        && end.containerNode() == m_compositionNode
        && static_cast<unsigned>(start.computeOffsetInContainerNode()) >= m_compositionStart
        && static_cast<unsigned>(end.computeOffsetInContainerNode()) <= m_compositionEnd)
        return;

    cancelComposition();
}

bool InputMethodController::finishComposition(const String& text, FinishCompositionMode mode)
{
    if (!hasComposition())
        return false;

    ASSERT(mode == ConfirmComposition || mode == CancelComposition);

    Editor::RevealSelectionScope revealSelectionScope(&editor());

    if (mode == CancelComposition)
        ASSERT(text == emptyString());
    else
        selectComposition();

    if (m_frame.selection().isNone())
        return false;

    // Dispatch a compositionend event to the focused node.
    // We should send this event before sending a TextEvent as written in Section 6.2.2 and 6.2.3 of
    // the DOM Event specification.
    if (Element* target = m_frame.document()->focusedElement()) {
        unsigned baseOffset = m_frame.selection().base().downstream().deprecatedEditingOffset();
        Vector<CompositionUnderline> underlines;
        for (size_t i = 0; i < m_customCompositionUnderlines.size(); ++i) {
            CompositionUnderline underline = m_customCompositionUnderlines[i];
            underline.startOffset -= baseOffset;
            underline.endOffset -= baseOffset;
            underlines.append(underline);
        }
        RefPtr<CompositionEvent> event = CompositionEvent::create(EventTypeNames::compositionend, m_frame.domWindow(), text, underlines);
        target->dispatchEvent(event, IGNORE_EXCEPTION);
    }

    // If text is empty, then delete the old composition here. If text is non-empty, InsertTextCommand::input
    // will delete the old composition with an optimized replace operation.
    if (text.isEmpty() && mode != CancelComposition) {
        ASSERT(m_frame.document());
        TypingCommand::deleteSelection(*m_frame.document(), 0);
    }

    m_compositionNode = nullptr;
    m_customCompositionUnderlines.clear();

    insertTextForConfirmedComposition(text);

    if (mode == CancelComposition) {
        // An open typing command that disagrees about current selection would cause issues with typing later on.
        TypingCommand::closeTyping(&m_frame);
    }

    return true;
}

void InputMethodController::setComposition(const String& text, const Vector<CompositionUnderline>& underlines, unsigned selectionStart, unsigned selectionEnd)
{
    Editor::RevealSelectionScope revealSelectionScope(&editor());

    // Updates styles before setting selection for composition to prevent
    // inserting the previous composition text into text nodes oddly.
    // See https://bugs.webkit.org/show_bug.cgi?id=46868
    m_frame.document()->updateRenderTreeIfNeeded();

    selectComposition();

    if (m_frame.selection().isNone())
        return;

    if (Element* target = m_frame.document()->focusedElement()) {
        // Dispatch an appropriate composition event to the focused node.
        // We check the composition status and choose an appropriate composition event since this
        // function is used for three purposes:
        // 1. Starting a new composition.
        //    Send a compositionstart and a compositionupdate event when this function creates
        //    a new composition node, i.e.
        //    m_compositionNode == 0 && !text.isEmpty().
        //    Sending a compositionupdate event at this time ensures that at least one
        //    compositionupdate event is dispatched.
        // 2. Updating the existing composition node.
        //    Send a compositionupdate event when this function updates the existing composition
        //    node, i.e. m_compositionNode != 0 && !text.isEmpty().
        // 3. Canceling the ongoing composition.
        //    Send a compositionend event when function deletes the existing composition node, i.e.
        //    m_compositionNode != 0 && test.isEmpty().
        RefPtr<CompositionEvent> event = nullptr;
        if (!hasComposition()) {
            // We should send a compositionstart event only when the given text is not empty because this
            // function doesn't create a composition node when the text is empty.
            if (!text.isEmpty()) {
                target->dispatchEvent(CompositionEvent::create(EventTypeNames::compositionstart, m_frame.domWindow(), m_frame.selectedText(), underlines));
                event = CompositionEvent::create(EventTypeNames::compositionupdate, m_frame.domWindow(), text, underlines);
            }
        } else {
            if (!text.isEmpty())
                event = CompositionEvent::create(EventTypeNames::compositionupdate, m_frame.domWindow(), text, underlines);
            else
                event = CompositionEvent::create(EventTypeNames::compositionend, m_frame.domWindow(), text, underlines);
        }
        if (event.get())
            target->dispatchEvent(event, IGNORE_EXCEPTION);
    }

    // If text is empty, then delete the old composition here. If text is non-empty, InsertTextCommand::input
    // will delete the old composition with an optimized replace operation.
    if (text.isEmpty()) {
        ASSERT(m_frame.document());
        TypingCommand::deleteSelection(*m_frame.document(), TypingCommand::PreventSpellChecking);
    }

    m_compositionNode = nullptr;
    m_customCompositionUnderlines.clear();

    if (!text.isEmpty()) {
        ASSERT(m_frame.document());
        TypingCommand::insertText(*m_frame.document(), text, TypingCommand::SelectInsertedText | TypingCommand::PreventSpellChecking, TypingCommand::TextCompositionUpdate);

        // Find out what node has the composition now.
        Position base = m_frame.selection().base().downstream();
        Position extent = m_frame.selection().extent();
        Node* baseNode = base.deprecatedNode();
        unsigned baseOffset = base.deprecatedEditingOffset();
        Node* extentNode = extent.deprecatedNode();
        unsigned extentOffset = extent.deprecatedEditingOffset();

        if (baseNode && baseNode == extentNode && baseNode->isTextNode() && baseOffset + text.length() == extentOffset) {
            m_compositionNode = toText(baseNode);
            m_compositionStart = baseOffset;
            m_compositionEnd = extentOffset;
            m_customCompositionUnderlines = underlines;
            size_t numUnderlines = m_customCompositionUnderlines.size();
            for (size_t i = 0; i < numUnderlines; ++i) {
                m_customCompositionUnderlines[i].startOffset += baseOffset;
                m_customCompositionUnderlines[i].endOffset += baseOffset;
            }

            // TODO(ojan): What was this for? Do we need it in sky since we
            // don't need to support legacy IMEs?
            if (baseNode->renderer())
                baseNode->document().scheduleVisualUpdate();

            unsigned start = std::min(baseOffset + selectionStart, extentOffset);
            unsigned end = std::min(std::max(start, baseOffset + selectionEnd), extentOffset);
            RefPtr<Range> selectedRange = Range::create(baseNode->document(), baseNode, start, baseNode, end);
            m_frame.selection().setSelectedRange(selectedRange.get(), DOWNSTREAM, FrameSelection::NonDirectional, NotUserTriggered);
        }
    }
}

void InputMethodController::setCompositionFromExistingText(const Vector<CompositionUnderline>& underlines, unsigned compositionStart, unsigned compositionEnd)
{
    Element* editable = m_frame.selection().rootEditableElement();
    Position base = m_frame.selection().base().downstream();
    Node* baseNode = base.anchorNode();
    if (editable->firstChild() == baseNode && editable->lastChild() == baseNode && baseNode->isTextNode()) {
        m_compositionNode = nullptr;
        m_customCompositionUnderlines.clear();

        if (base.anchorType() != Position::PositionIsOffsetInAnchor)
            return;
        if (!baseNode || baseNode != m_frame.selection().extent().anchorNode())
            return;

        m_compositionNode = toText(baseNode);
        RefPtr<Range> range = PlainTextRange(compositionStart, compositionEnd).createRange(*editable);
        m_compositionStart = range->startOffset();
        m_compositionEnd = range->endOffset();
        m_customCompositionUnderlines = underlines;
        size_t numUnderlines = m_customCompositionUnderlines.size();
        for (size_t i = 0; i < numUnderlines; ++i) {
            m_customCompositionUnderlines[i].startOffset += m_compositionStart;
            m_customCompositionUnderlines[i].endOffset += m_compositionStart;
        }

        // TODO(ojan): What was this for? Do we need it in sky since we
        // don't need to support legacy IMEs?
        if (baseNode->renderer())
            baseNode->document().scheduleVisualUpdate();

        return;
    }

    Editor::RevealSelectionScope revealSelectionScope(&editor());
    SelectionOffsetsScope selectionOffsetsScope(this);
    setSelectionOffsets(PlainTextRange(compositionStart, compositionEnd));
    setComposition(m_frame.selectedText(), underlines, 0, 0);
}

PassRefPtr<Range> InputMethodController::compositionRange() const
{
    if (!hasComposition())
        return nullptr;
    unsigned length = m_compositionNode->length();
    unsigned start = std::min(m_compositionStart, length);
    unsigned end = std::min(std::max(start, m_compositionEnd), length);
    if (start >= end)
        return nullptr;
    return Range::create(m_compositionNode->document(), m_compositionNode.get(), start, m_compositionNode.get(), end);
}

PlainTextRange InputMethodController::getSelectionOffsets() const
{
    RefPtr<Range> range = m_frame.selection().selection().firstRange();
    if (!range)
        return PlainTextRange();
    ContainerNode* editable = m_frame.selection().rootEditableElementOrTreeScopeRootNode();
    ASSERT(editable);
    return PlainTextRange::create(*editable, *range.get());
}

bool InputMethodController::setSelectionOffsets(const PlainTextRange& selectionOffsets)
{
    if (selectionOffsets.isNull())
        return false;
    Element* rootEditableElement = m_frame.selection().rootEditableElement();
    if (!rootEditableElement)
        return false;

    RefPtr<Range> range = selectionOffsets.createRange(*rootEditableElement);
    if (!range)
        return false;

    return m_frame.selection().setSelectedRange(range.get(), VP_DEFAULT_AFFINITY, FrameSelection::NonDirectional, FrameSelection::CloseTyping);
}

bool InputMethodController::setEditableSelectionOffsets(const PlainTextRange& selectionOffsets)
{
    if (!editor().canEdit())
        return false;
    return setSelectionOffsets(selectionOffsets);
}

void InputMethodController::extendSelectionAndDelete(int before, int after)
{
    if (!editor().canEdit())
        return;
    PlainTextRange selectionOffsets(getSelectionOffsets());
    if (selectionOffsets.isNull())
        return;

    // A common call of before=1 and after=0 will fail if the last character
    // is multi-code-word UTF-16, including both multi-16bit code-points and
    // Unicode combining character sequences of multiple single-16bit code-
    // points (officially called "compositions"). Try more until success.
    // http://crbug.com/355995
    //
    // FIXME: Note that this is not an ideal solution when this function is
    // called to implement "backspace". In that case, there should be some call
    // that will not delete a full multi-code-point composition but rather
    // only the last code-point so that it's possible for a user to correct
    // a composition without starting it from the beginning.
    // http://crbug.com/37993
    do {
        if (!setSelectionOffsets(PlainTextRange(std::max(static_cast<int>(selectionOffsets.start()) - before, 0), selectionOffsets.end() + after)))
            return;
        if (before == 0)
            break;
        ++before;
    } while (m_frame.selection().start() == m_frame.selection().end() && before <= static_cast<int>(selectionOffsets.start()));
    TypingCommand::deleteSelection(*m_frame.document());
}

} // namespace blink
