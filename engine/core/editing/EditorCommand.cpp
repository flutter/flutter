/*
 * Copyright (C) 2006, 2007, 2008 Apple Inc. All rights reserved.
 * Copyright (C) 2008 Nokia Corporation and/or its subsidiary(-ies)
 * Copyright (C) 2009 Igalia S.L.
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
#include "sky/engine/core/editing/Editor.h"

#include "gen/sky/core/CSSPropertyNames.h"
#include "gen/sky/core/CSSValueKeywords.h"
#include "sky/engine/bindings/exception_state.h"
#include "sky/engine/bindings/exception_state_placeholder.h"
#include "sky/engine/core/css/CSSValueList.h"
#include "sky/engine/core/css/StylePropertySet.h"
#include "sky/engine/core/dom/DocumentFragment.h"
#include "sky/engine/core/editing/FrameSelection.h"
#include "sky/engine/core/editing/ReplaceSelectionCommand.h"
#include "sky/engine/core/editing/SpellChecker.h"
#include "sky/engine/core/editing/TypingCommand.h"
#include "sky/engine/core/editing/htmlediting.h"
#include "sky/engine/core/events/Event.h"
#include "sky/engine/core/frame/FrameHost.h"
#include "sky/engine/core/frame/FrameView.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/frame/Settings.h"
#include "sky/engine/core/html/HTMLImageElement.h"
#include "sky/engine/core/page/EditorClient.h"
#include "sky/engine/core/page/EventHandler.h"
#include "sky/engine/core/rendering/RenderBox.h"
#include "sky/engine/public/platform/Platform.h"
#include "sky/engine/wtf/text/AtomicString.h"

namespace blink {

class EditorInternalCommand {
public:
    int idForUserMetrics;
    bool (*execute)(LocalFrame&, Event*, EditorCommandSource, const String&);
    bool (*isSupportedFromDOM)(LocalFrame*);
    bool (*isEnabled)(LocalFrame&, Event*, EditorCommandSource);
    TriState (*state)(LocalFrame&, Event*);
    String (*value)(LocalFrame&, Event*);
    bool isTextInsertion;
    bool allowExecutionWhenDisabled;
};

typedef HashMap<String, const EditorInternalCommand*, CaseFoldingHash> CommandMap;

static const bool notTextInsertion = false;
static const bool isTextInsertion = true;

static const bool allowExecutionWhenDisabled = true;
static const bool doNotAllowExecutionWhenDisabled = false;

static const float kMinFractionToStepWhenPaging = 0.875f;

// Related to Editor::selectionForCommand.
// Certain operations continue to use the target control's selection even if the event handler
// already moved the selection outside of the text control.
static LocalFrame* targetFrame(LocalFrame& frame, Event* event)
{
    if (!event)
        return &frame;
    Node* node = event->target()->toNode();
    if (!node)
        return &frame;
    return node->document().frame();
}

static unsigned verticalScrollDistance(LocalFrame& frame)
{
    Element* focusedElement = frame.document()->focusedElement();
    if (!focusedElement)
        return 0;
    RenderObject* renderer = focusedElement->renderer();
    if (!renderer || !renderer->isBox())
        return 0;
    RenderBox& renderBox = toRenderBox(*renderer);
    RenderStyle* style = renderBox.style();
    if (!style)
        return 0;
    if (!focusedElement->hasEditableStyle())
        return 0;
    int height = std::min<int>(renderBox.clientHeight(),
        frame.view()->height());
    return static_cast<unsigned>(max<int>(height * kMinFractionToStepWhenPaging, 1));
}

static bool executeCopy(LocalFrame& frame, Event*, EditorCommandSource, const String&)
{
    frame.editor().copy();
    return true;
}

static bool executeCut(LocalFrame& frame, Event*, EditorCommandSource, const String&)
{
    frame.editor().cut();
    return true;
}

static bool executeDeleteBackward(LocalFrame& frame, Event*, EditorCommandSource, const String&)
{
    frame.editor().deleteWithDirection(DirectionBackward, CharacterGranularity, true);
    return true;
}

static bool executeDeleteForward(LocalFrame& frame, Event*, EditorCommandSource, const String&)
{
    frame.editor().deleteWithDirection(DirectionForward, CharacterGranularity, true);
    return true;
}

static bool executeDeleteWordBackward(LocalFrame& frame, Event*, EditorCommandSource, const String&)
{
    frame.editor().deleteWithDirection(DirectionBackward, WordGranularity, false);
    return true;
}

static bool executeDeleteWordForward(LocalFrame& frame, Event*, EditorCommandSource, const String&)
{
    frame.editor().deleteWithDirection(DirectionForward, WordGranularity, false);
    return true;
}

static bool executeInsertNewline(LocalFrame& frame, Event* event, EditorCommandSource, const String&)
{
    LocalFrame* targetFrame = blink::targetFrame(frame, event);
    return targetFrame->eventHandler().handleTextInputEvent("\n", event, targetFrame->editor().canEditRichly() ? TextEventInputKeyboard : TextEventInputLineBreak);
}

static bool executeMoveDown(LocalFrame& frame, Event*, EditorCommandSource, const String&)
{
    return frame.selection().modify(FrameSelection::AlterationMove, DirectionForward, LineGranularity, UserTriggered);
}

static bool executeMoveDownAndModifySelection(LocalFrame& frame, Event*, EditorCommandSource, const String&)
{
    frame.selection().modify(FrameSelection::AlterationExtend, DirectionForward, LineGranularity, UserTriggered);
    return true;
}

static bool executeMoveLeft(LocalFrame& frame, Event*, EditorCommandSource, const String&)
{
    return frame.selection().modify(FrameSelection::AlterationMove, DirectionLeft, CharacterGranularity, UserTriggered);
}

static bool executeMoveLeftAndModifySelection(LocalFrame& frame, Event*, EditorCommandSource, const String&)
{
    frame.selection().modify(FrameSelection::AlterationExtend, DirectionLeft, CharacterGranularity, UserTriggered);
    return true;
}

static bool executeMovePageDown(LocalFrame& frame, Event*, EditorCommandSource, const String&)
{
    unsigned distance = verticalScrollDistance(frame);
    if (!distance)
        return false;
    return frame.selection().modify(FrameSelection::AlterationMove, distance, FrameSelection::DirectionDown,
        UserTriggered, FrameSelection::AlignCursorOnScrollAlways);
}

static bool executeMovePageDownAndModifySelection(LocalFrame& frame, Event*, EditorCommandSource, const String&)
{
    unsigned distance = verticalScrollDistance(frame);
    if (!distance)
        return false;
    return frame.selection().modify(FrameSelection::AlterationExtend, distance, FrameSelection::DirectionDown,
        UserTriggered, FrameSelection::AlignCursorOnScrollAlways);
}

static bool executeMovePageUp(LocalFrame& frame, Event*, EditorCommandSource, const String&)
{
    unsigned distance = verticalScrollDistance(frame);
    if (!distance)
        return false;
    return frame.selection().modify(FrameSelection::AlterationMove, distance, FrameSelection::DirectionUp,
        UserTriggered, FrameSelection::AlignCursorOnScrollAlways);
}

static bool executeMovePageUpAndModifySelection(LocalFrame& frame, Event*, EditorCommandSource, const String&)
{
    unsigned distance = verticalScrollDistance(frame);
    if (!distance)
        return false;
    return frame.selection().modify(FrameSelection::AlterationExtend, distance, FrameSelection::DirectionUp,
        UserTriggered, FrameSelection::AlignCursorOnScrollAlways);
}

static bool executeMoveRight(LocalFrame& frame, Event*, EditorCommandSource, const String&)
{
    return frame.selection().modify(FrameSelection::AlterationMove, DirectionRight, CharacterGranularity, UserTriggered);
}

static bool executeMoveRightAndModifySelection(LocalFrame& frame, Event*, EditorCommandSource, const String&)
{
    frame.selection().modify(FrameSelection::AlterationExtend, DirectionRight, CharacterGranularity, UserTriggered);
    return true;
}

static bool executeMoveToBeginningOfDocument(LocalFrame& frame, Event*, EditorCommandSource, const String&)
{
    frame.selection().modify(FrameSelection::AlterationMove, DirectionBackward, DocumentBoundary, UserTriggered);
    return true;
}

static bool executeMoveToBeginningOfDocumentAndModifySelection(LocalFrame& frame, Event*, EditorCommandSource, const String&)
{
    frame.selection().modify(FrameSelection::AlterationExtend, DirectionBackward, DocumentBoundary, UserTriggered);
    return true;
}

static bool executeMoveToBeginningOfLine(LocalFrame& frame, Event*, EditorCommandSource, const String&)
{
    frame.selection().modify(FrameSelection::AlterationMove, DirectionBackward, LineBoundary, UserTriggered);
    return true;
}

static bool executeMoveToBeginningOfLineAndModifySelection(LocalFrame& frame, Event*, EditorCommandSource, const String&)
{
    frame.selection().modify(FrameSelection::AlterationExtend, DirectionBackward, LineBoundary, UserTriggered);
    return true;
}

static bool executeMoveToEndOfDocument(LocalFrame& frame, Event*, EditorCommandSource, const String&)
{
    frame.selection().modify(FrameSelection::AlterationMove, DirectionForward, DocumentBoundary, UserTriggered);
    return true;
}

static bool executeMoveToEndOfDocumentAndModifySelection(LocalFrame& frame, Event*, EditorCommandSource, const String&)
{
    frame.selection().modify(FrameSelection::AlterationExtend, DirectionForward, DocumentBoundary, UserTriggered);
    return true;
}

static bool executeMoveToEndOfLine(LocalFrame& frame, Event*, EditorCommandSource, const String&)
{
    frame.selection().modify(FrameSelection::AlterationMove, DirectionForward, LineBoundary, UserTriggered);
    return true;
}

static bool executeMoveToEndOfLineAndModifySelection(LocalFrame& frame, Event*, EditorCommandSource, const String&)
{
    frame.selection().modify(FrameSelection::AlterationExtend, DirectionForward, LineBoundary, UserTriggered);
    return true;
}

static bool executeMoveParagraphBackward(LocalFrame& frame, Event*, EditorCommandSource, const String&)
{
    frame.selection().modify(FrameSelection::AlterationMove, DirectionBackward, ParagraphGranularity, UserTriggered);
    return true;
}

static bool executeMoveParagraphBackwardAndModifySelection(LocalFrame& frame, Event*, EditorCommandSource, const String&)
{
    frame.selection().modify(FrameSelection::AlterationExtend, DirectionBackward, ParagraphGranularity, UserTriggered);
    return true;
}

static bool executeMoveParagraphForward(LocalFrame& frame, Event*, EditorCommandSource, const String&)
{
    frame.selection().modify(FrameSelection::AlterationMove, DirectionForward, ParagraphGranularity, UserTriggered);
    return true;
}

static bool executeMoveParagraphForwardAndModifySelection(LocalFrame& frame, Event*, EditorCommandSource, const String&)
{
    frame.selection().modify(FrameSelection::AlterationExtend, DirectionForward, ParagraphGranularity, UserTriggered);
    return true;
}

static bool executeMoveUp(LocalFrame& frame, Event*, EditorCommandSource, const String&)
{
    return frame.selection().modify(FrameSelection::AlterationMove, DirectionBackward, LineGranularity, UserTriggered);
}

static bool executeMoveUpAndModifySelection(LocalFrame& frame, Event*, EditorCommandSource, const String&)
{
    frame.selection().modify(FrameSelection::AlterationExtend, DirectionBackward, LineGranularity, UserTriggered);
    return true;
}

static bool executeMoveWordLeft(LocalFrame& frame, Event*, EditorCommandSource, const String&)
{
    frame.selection().modify(FrameSelection::AlterationMove, DirectionLeft, WordGranularity, UserTriggered);
    return true;
}

static bool executeMoveWordLeftAndModifySelection(LocalFrame& frame, Event*, EditorCommandSource, const String&)
{
    frame.selection().modify(FrameSelection::AlterationExtend, DirectionLeft, WordGranularity, UserTriggered);
    return true;
}

static bool executeMoveWordRight(LocalFrame& frame, Event*, EditorCommandSource, const String&)
{
    frame.selection().modify(FrameSelection::AlterationMove, DirectionRight, WordGranularity, UserTriggered);
    return true;
}

static bool executeMoveWordRightAndModifySelection(LocalFrame& frame, Event*, EditorCommandSource, const String&)
{
    frame.selection().modify(FrameSelection::AlterationExtend, DirectionRight, WordGranularity, UserTriggered);
    return true;
}

static bool executeMoveToLeftEndOfLine(LocalFrame& frame, Event*, EditorCommandSource, const String&)
{
    frame.selection().modify(FrameSelection::AlterationMove, DirectionLeft, LineBoundary, UserTriggered);
    return true;
}

static bool executeMoveToLeftEndOfLineAndModifySelection(LocalFrame& frame, Event*, EditorCommandSource, const String&)
{
    frame.selection().modify(FrameSelection::AlterationExtend, DirectionLeft, LineBoundary, UserTriggered);
    return true;
}

static bool executeToggleOverwrite(LocalFrame& frame, Event*, EditorCommandSource, const String&)
{
    frame.editor().toggleOverwriteModeEnabled();
    return true;
}

static bool executePaste(LocalFrame& frame, Event*, EditorCommandSource, const String&)
{
    frame.editor().paste();
    return true;
}

static bool executePasteAndMatchStyle(LocalFrame& frame, Event*, EditorCommandSource, const String&)
{
    frame.editor().pasteAsPlainText();
    return true;
}

static bool executeSelectAll(LocalFrame& frame, Event*, EditorCommandSource, const String&)
{
    frame.selection().selectAll();
    return true;
}

static bool supported(LocalFrame*)
{
    return true;
}

static bool supportedFromMenuOrKeyBinding(LocalFrame*)
{
    return false;
}

static bool supportedCopyCut(LocalFrame* frame)
{
    if (!frame)
        return false;

    Settings* settings = frame->settings();
    bool defaultValue = settings && settings->javaScriptCanAccessClipboard();
    return frame->editor().client().canCopyCut(frame, defaultValue);
}

static bool supportedPaste(LocalFrame* frame)
{
    if (!frame)
        return false;

    Settings* settings = frame->settings();
    bool defaultValue = settings && settings->javaScriptCanAccessClipboard() && settings->DOMPasteAllowed();
    return frame->editor().client().canPaste(frame, defaultValue);
}

// Enabled functions

static bool enabled(LocalFrame&, Event*, EditorCommandSource)
{
    return true;
}

static bool enabledVisibleSelection(LocalFrame& frame, Event* event, EditorCommandSource)
{
    // The term "visible" here includes a caret in editable text or a range in any text.
    const VisibleSelection& selection = frame.editor().selectionForCommand(event);
    return (selection.isCaret() && selection.isContentEditable()) || selection.isRange();
}

static bool enabledCopy(LocalFrame& frame, Event*, EditorCommandSource)
{
    return frame.editor().canDHTMLCopy() || frame.editor().canCopy();
}

static bool enabledCut(LocalFrame& frame, Event*, EditorCommandSource)
{
    return frame.editor().canDHTMLCut() || frame.editor().canCut();
}

static bool enabledInEditableText(LocalFrame& frame, Event* event, EditorCommandSource)
{
    return frame.editor().selectionForCommand(event).rootEditableElement();
}

static bool enabledInRichlyEditableText(LocalFrame& frame, Event*, EditorCommandSource)
{
    return frame.selection().isCaretOrRange() && frame.selection().isContentRichlyEditable() && frame.selection().rootEditableElement();
}

static bool enabledPaste(LocalFrame& frame, Event*, EditorCommandSource)
{
    return frame.editor().canPaste();
}

static TriState stateNone(LocalFrame&, Event*)
{
    return FalseTriState;
}

static String valueNull(LocalFrame&, Event*)
{
    return String();
}

// Map of functions

struct CommandEntry {
    const char* name;
    EditorInternalCommand command;
};

static const CommandMap& createCommandMap()
{
    // If you add new commands, you should assign new Id to each idForUserMetrics and update MappedEditingCommands
    // in chrome/trunk/src/tools/metrics/histograms/histograms.xml.
    static const CommandEntry commands[] = {
        { "Copy", {7, executeCopy, supportedCopyCut, enabledCopy, stateNone, valueNull, notTextInsertion, allowExecutionWhenDisabled } },
        { "Cut", {9, executeCut, supportedCopyCut, enabledCut, stateNone, valueNull, notTextInsertion, allowExecutionWhenDisabled } },
        { "DeleteBackward", {12, executeDeleteBackward, supportedFromMenuOrKeyBinding, enabledInEditableText, stateNone, valueNull, notTextInsertion, doNotAllowExecutionWhenDisabled } },
        { "DeleteForward", {14, executeDeleteForward, supportedFromMenuOrKeyBinding, enabledInEditableText, stateNone, valueNull, notTextInsertion, doNotAllowExecutionWhenDisabled } },
        { "DeleteWordBackward", {20, executeDeleteWordBackward, supportedFromMenuOrKeyBinding, enabledInEditableText, stateNone, valueNull, notTextInsertion, doNotAllowExecutionWhenDisabled } },
        { "DeleteWordForward", {21, executeDeleteWordForward, supportedFromMenuOrKeyBinding, enabledInEditableText, stateNone, valueNull, notTextInsertion, doNotAllowExecutionWhenDisabled } },
        { "InsertNewline", {37, executeInsertNewline, supportedFromMenuOrKeyBinding, enabledInEditableText, stateNone, valueNull, isTextInsertion, doNotAllowExecutionWhenDisabled } },
        { "MoveDown", {55, executeMoveDown, supportedFromMenuOrKeyBinding, enabledInEditableText, stateNone, valueNull, notTextInsertion, doNotAllowExecutionWhenDisabled } },
        { "MoveDownAndModifySelection", {56, executeMoveDownAndModifySelection, supportedFromMenuOrKeyBinding, enabledVisibleSelection, stateNone, valueNull, notTextInsertion, doNotAllowExecutionWhenDisabled } },
        { "MoveLeft", {59, executeMoveLeft, supportedFromMenuOrKeyBinding, enabledInEditableText, stateNone, valueNull, notTextInsertion, doNotAllowExecutionWhenDisabled } },
        { "MoveLeftAndModifySelection", {60, executeMoveLeftAndModifySelection, supportedFromMenuOrKeyBinding, enabledVisibleSelection, stateNone, valueNull, notTextInsertion, doNotAllowExecutionWhenDisabled } },
        { "MovePageDown", {61, executeMovePageDown, supportedFromMenuOrKeyBinding, enabledInEditableText, stateNone, valueNull, notTextInsertion, doNotAllowExecutionWhenDisabled } },
        { "MovePageDownAndModifySelection", {62, executeMovePageDownAndModifySelection, supportedFromMenuOrKeyBinding, enabledVisibleSelection, stateNone, valueNull, notTextInsertion, doNotAllowExecutionWhenDisabled } },
        { "MovePageUp", {63, executeMovePageUp, supportedFromMenuOrKeyBinding, enabledInEditableText, stateNone, valueNull, notTextInsertion, doNotAllowExecutionWhenDisabled } },
        { "MovePageUpAndModifySelection", {64, executeMovePageUpAndModifySelection, supportedFromMenuOrKeyBinding, enabledVisibleSelection, stateNone, valueNull, notTextInsertion, doNotAllowExecutionWhenDisabled } },
        { "MoveParagraphBackward", {65, executeMoveParagraphBackward, supportedFromMenuOrKeyBinding, enabledInEditableText, stateNone, valueNull, notTextInsertion, doNotAllowExecutionWhenDisabled } },
        { "MoveParagraphBackwardAndModifySelection", {66, executeMoveParagraphBackwardAndModifySelection, supportedFromMenuOrKeyBinding, enabledVisibleSelection, stateNone, valueNull, notTextInsertion, doNotAllowExecutionWhenDisabled } },
        { "MoveParagraphForward", {67, executeMoveParagraphForward, supportedFromMenuOrKeyBinding, enabledInEditableText, stateNone, valueNull, notTextInsertion, doNotAllowExecutionWhenDisabled } },
        { "MoveParagraphForwardAndModifySelection", {68, executeMoveParagraphForwardAndModifySelection, supportedFromMenuOrKeyBinding, enabledVisibleSelection, stateNone, valueNull, notTextInsertion, doNotAllowExecutionWhenDisabled } },
        { "MoveRight", {69, executeMoveRight, supportedFromMenuOrKeyBinding, enabledInEditableText, stateNone, valueNull, notTextInsertion, doNotAllowExecutionWhenDisabled } },
        { "MoveRightAndModifySelection", {70, executeMoveRightAndModifySelection, supportedFromMenuOrKeyBinding, enabledVisibleSelection, stateNone, valueNull, notTextInsertion, doNotAllowExecutionWhenDisabled } },
        { "MoveToBeginningOfDocument", {71, executeMoveToBeginningOfDocument, supportedFromMenuOrKeyBinding, enabledInEditableText, stateNone, valueNull, notTextInsertion, doNotAllowExecutionWhenDisabled } },
        { "MoveToBeginningOfDocumentAndModifySelection", {72, executeMoveToBeginningOfDocumentAndModifySelection, supportedFromMenuOrKeyBinding, enabledVisibleSelection, stateNone, valueNull, notTextInsertion, doNotAllowExecutionWhenDisabled } },
        { "MoveToBeginningOfLine", {73, executeMoveToBeginningOfLine, supportedFromMenuOrKeyBinding, enabledInEditableText, stateNone, valueNull, notTextInsertion, doNotAllowExecutionWhenDisabled } },
        { "MoveToBeginningOfLineAndModifySelection", {74, executeMoveToBeginningOfLineAndModifySelection, supportedFromMenuOrKeyBinding, enabledVisibleSelection, stateNone, valueNull, notTextInsertion, doNotAllowExecutionWhenDisabled } },
        { "MoveToEndOfDocument", {79, executeMoveToEndOfDocument, supportedFromMenuOrKeyBinding, enabledInEditableText, stateNone, valueNull, notTextInsertion, doNotAllowExecutionWhenDisabled } },
        { "MoveToEndOfDocumentAndModifySelection", {80, executeMoveToEndOfDocumentAndModifySelection, supportedFromMenuOrKeyBinding, enabledVisibleSelection, stateNone, valueNull, notTextInsertion, doNotAllowExecutionWhenDisabled } },
        { "MoveToEndOfLine", {81, executeMoveToEndOfLine, supportedFromMenuOrKeyBinding, enabledInEditableText, stateNone, valueNull, notTextInsertion, doNotAllowExecutionWhenDisabled } },
        { "MoveToEndOfLineAndModifySelection", {82, executeMoveToEndOfLineAndModifySelection, supportedFromMenuOrKeyBinding, enabledVisibleSelection, stateNone, valueNull, notTextInsertion, doNotAllowExecutionWhenDisabled } },
        { "MoveToLeftEndOfLine", {87, executeMoveToLeftEndOfLine, supportedFromMenuOrKeyBinding, enabledInEditableText, stateNone, valueNull, notTextInsertion, doNotAllowExecutionWhenDisabled } },
        { "MoveToLeftEndOfLineAndModifySelection", {88, executeMoveToLeftEndOfLineAndModifySelection, supportedFromMenuOrKeyBinding, enabledInEditableText, stateNone, valueNull, notTextInsertion, doNotAllowExecutionWhenDisabled } },
        { "MoveUp", {91, executeMoveUp, supportedFromMenuOrKeyBinding, enabledInEditableText, stateNone, valueNull, notTextInsertion, doNotAllowExecutionWhenDisabled } },
        { "MoveUpAndModifySelection", {92, executeMoveUpAndModifySelection, supportedFromMenuOrKeyBinding, enabledVisibleSelection, stateNone, valueNull, notTextInsertion, doNotAllowExecutionWhenDisabled } },
        { "MoveWordLeft", {97, executeMoveWordLeft, supportedFromMenuOrKeyBinding, enabledInEditableText, stateNone, valueNull, notTextInsertion, doNotAllowExecutionWhenDisabled } },
        { "MoveWordLeftAndModifySelection", {98, executeMoveWordLeftAndModifySelection, supportedFromMenuOrKeyBinding, enabledVisibleSelection, stateNone, valueNull, notTextInsertion, doNotAllowExecutionWhenDisabled } },
        { "MoveWordRight", {99, executeMoveWordRight, supportedFromMenuOrKeyBinding, enabledInEditableText, stateNone, valueNull, notTextInsertion, doNotAllowExecutionWhenDisabled } },
        { "MoveWordRightAndModifySelection", {100, executeMoveWordRightAndModifySelection, supportedFromMenuOrKeyBinding, enabledVisibleSelection, stateNone, valueNull, notTextInsertion, doNotAllowExecutionWhenDisabled } },
        { "OverWrite", {102, executeToggleOverwrite, supportedFromMenuOrKeyBinding, enabledInRichlyEditableText, stateNone, valueNull, notTextInsertion, doNotAllowExecutionWhenDisabled } },
        { "Paste", {103, executePaste, supportedPaste, enabledPaste, stateNone, valueNull, notTextInsertion, allowExecutionWhenDisabled } },
        { "PasteAndMatchStyle", {104, executePasteAndMatchStyle, supportedPaste, enabledPaste, stateNone, valueNull, notTextInsertion, allowExecutionWhenDisabled } },
        { "SelectAll", {115, executeSelectAll, supported, enabled, stateNone, valueNull, notTextInsertion, doNotAllowExecutionWhenDisabled } },
    };

    CommandMap& commandMap = *new CommandMap;
#if ENABLE(ASSERT)
    HashSet<int> idSet;
#endif
    for (size_t i = 0; i < WTF_ARRAY_LENGTH(commands); ++i) {
        const CommandEntry& command = commands[i];
        ASSERT(!commandMap.get(command.name));
        commandMap.set(command.name, &command.command);
#if ENABLE(ASSERT)
        ASSERT(!idSet.contains(command.command.idForUserMetrics));
        idSet.add(command.command.idForUserMetrics);
#endif
    }

    return commandMap;
}

static const EditorInternalCommand* internalCommand(const String& commandName)
{
    static const CommandMap& commandMap = createCommandMap();
    return commandName.isEmpty() ? 0 : commandMap.get(commandName);
}

Editor::Command Editor::command(const String& commandName)
{
    return Command(internalCommand(commandName), CommandFromMenuOrKeyBinding, &m_frame);
}

Editor::Command Editor::command(const String& commandName, EditorCommandSource source)
{
    return Command(internalCommand(commandName), source, &m_frame);
}

bool Editor::executeCommand(const String& commandName)
{
    // Specially handling commands that Editor::execCommand does not directly
    // support.
    if (commandName == "DeleteToEndOfParagraph") {
        if (!deleteWithDirection(DirectionForward, ParagraphBoundary, false))
            deleteWithDirection(DirectionForward, CharacterGranularity, false);
        return true;
    }
    if (commandName == "DeleteBackward")
        return command(AtomicString("BackwardDelete")).execute();
    if (commandName == "DeleteForward")
        return command(AtomicString("ForwardDelete")).execute();
    if (commandName == "AdvanceToNextMisspelling") {
        // Wee need to pass false here or else the currently selected word will never be skipped.
        spellChecker().advanceToNextMisspelling(false);
        return true;
    }
    if (commandName == "ToggleSpellPanel") {
        spellChecker().showSpellingGuessPanel();
        return true;
    }
    return command(commandName).execute();
}

bool Editor::executeCommand(const String& commandName, const String& value)
{
    if (commandName == "showGuessPanel") {
        spellChecker().showSpellingGuessPanel();
        return true;
    }

    return command(commandName).execute(value);
}

Editor::Command::Command()
    : m_command(0)
{
}

Editor::Command::Command(const EditorInternalCommand* command, EditorCommandSource source, PassRefPtr<LocalFrame> frame)
    : m_command(command)
    , m_source(source)
    , m_frame(command ? frame : nullptr)
{
    // Use separate assertions so we can tell which bad thing happened.
    if (!command)
        ASSERT(!m_frame);
    else
        ASSERT(m_frame);
}

bool Editor::Command::execute(const String& parameter, Event* triggeringEvent) const
{
    if (!isEnabled(triggeringEvent)) {
        // Let certain commands be executed when performed explicitly even if they are disabled.
        if (!isSupported() || !m_frame || !m_command->allowExecutionWhenDisabled)
            return false;
    }
    m_frame->document()->updateLayout();
    blink::Platform::current()->histogramSparse("WebCore.Editing.Commands", m_command->idForUserMetrics);
    return m_command->execute(*m_frame, triggeringEvent, m_source, parameter);
}

bool Editor::Command::execute(Event* triggeringEvent) const
{
    return execute(String(), triggeringEvent);
}

bool Editor::Command::isSupported() const
{
    if (!m_command)
        return false;
    switch (m_source) {
    case CommandFromMenuOrKeyBinding:
        return true;
    case CommandFromDOM:
    case CommandFromDOMWithUserInterface:
        return m_command->isSupportedFromDOM(m_frame.get());
    }
    ASSERT_NOT_REACHED();
    return false;
}

bool Editor::Command::isEnabled(Event* triggeringEvent) const
{
    if (!isSupported() || !m_frame)
        return false;
    return m_command->isEnabled(*m_frame, triggeringEvent, m_source);
}

TriState Editor::Command::state(Event* triggeringEvent) const
{
    if (!isSupported() || !m_frame)
        return FalseTriState;
    return m_command->state(*m_frame, triggeringEvent);
}

String Editor::Command::value(Event* triggeringEvent) const
{
    if (!isSupported() || !m_frame)
        return String();
    if (m_command->value == valueNull && m_command->state != stateNone)
        return m_command->state(*m_frame, triggeringEvent) == TrueTriState ? "true" : "false";
    return m_command->value(*m_frame, triggeringEvent);
}

bool Editor::Command::isTextInsertion() const
{
    return m_command && m_command->isTextInsertion;
}

int Editor::Command::idForHistogram() const
{
    return isSupported() ? m_command->idForUserMetrics : 0;
}

} // namespace blink
