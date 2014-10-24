/*
 * Copyright (C) 2006, 2007, 2008 Apple Inc. All rights reserved.
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

#ifndef Editor_h
#define Editor_h

#include "core/dom/DocumentMarker.h"
#include "core/editing/EditAction.h"
#include "core/editing/EditingBehavior.h"
#include "core/editing/FindOptions.h"
#include "core/editing/FrameSelection.h"
#include "core/editing/TextIterator.h"
#include "core/editing/VisibleSelection.h"
#include "core/editing/WritingDirection.h"
#include "core/frame/FrameDestructionObserver.h"
#include "platform/heap/Handle.h"

namespace blink {

class CompositeEditCommand;
class EditCommand;
class EditCommandComposition;
class EditorClient;
class EditorInternalCommand;
class LocalFrame;
class HTMLElement;
class HitTestResult;
class SharedBuffer;
class SimpleFontData;
class SpellChecker;
class StylePropertySet;
class Text;
class TextEvent;
class UndoStack;

enum EditorCommandSource { CommandFromMenuOrKeyBinding, CommandFromDOM, CommandFromDOMWithUserInterface };
enum EditorParagraphSeparator { EditorParagraphSeparatorIsDiv, EditorParagraphSeparatorIsP };

class Editor final : public NoBaseWillBeGarbageCollectedFinalized<Editor> {
    WTF_MAKE_NONCOPYABLE(Editor);
public:
    static PassOwnPtrWillBeRawPtr<Editor> create(LocalFrame&);
    ~Editor();

    EditorClient& client() const;

    LocalFrame& frame() const { return m_frame; }

    CompositeEditCommand* lastEditCommand() { return m_lastEditCommand.get(); }

    void handleKeyboardEvent(KeyboardEvent*);
    bool handleTextEvent(TextEvent*);

    bool canEdit() const;
    bool canEditRichly() const;

    bool canDHTMLCut();
    bool canDHTMLCopy();
    bool canDHTMLPaste();

    bool canCut() const;
    bool canCopy() const;
    bool canPaste() const;
    bool canDelete() const;
    bool canSmartCopyOrDelete() const;

    void cut();
    void copy();
    void paste();
    void pasteAsPlainText();
    void performDelete();

    static void countEvent(ExecutionContext*, const Event*);
    void copyImage(const HitTestResult&);

    void transpose();

    bool shouldDeleteRange(Range*) const;

    void respondToChangedContents(const VisibleSelection& endingSelection);

    bool selectionStartHasStyle(CSSPropertyID, const String& value) const;
    TriState selectionHasStyle(CSSPropertyID, const String& value) const;
    String selectionStartCSSPropertyValue(CSSPropertyID);

    void clearLastEditCommand();

    bool deleteWithDirection(SelectionDirection, TextGranularity, bool isTypingAction);
    void deleteSelectionWithSmartDelete(bool smartDelete);

    void appliedEditing(PassRefPtrWillBeRawPtr<CompositeEditCommand>);
    void unappliedEditing(PassRefPtrWillBeRawPtr<EditCommandComposition>);
    void reappliedEditing(PassRefPtrWillBeRawPtr<EditCommandComposition>);

    void setShouldStyleWithCSS(bool flag) { m_shouldStyleWithCSS = flag; }
    bool shouldStyleWithCSS() const { return m_shouldStyleWithCSS; }

    class Command {
    public:
        Command();
        Command(const EditorInternalCommand*, EditorCommandSource, PassRefPtr<LocalFrame>);

        bool execute(const String& parameter = String(), Event* triggeringEvent = 0) const;
        bool execute(Event* triggeringEvent) const;

        bool isSupported() const;
        bool isEnabled(Event* triggeringEvent = 0) const;

        TriState state(Event* triggeringEvent = 0) const;
        String value(Event* triggeringEvent = 0) const;

        bool isTextInsertion() const;

        // Returns 0 if this Command is not supported.
        int idForHistogram() const;
    private:
        const EditorInternalCommand* m_command;
        EditorCommandSource m_source;
        RefPtr<LocalFrame> m_frame;
    };
    Command command(const String& commandName); // Command source is CommandFromMenuOrKeyBinding.
    Command command(const String& commandName, EditorCommandSource);

    // |Editor::executeCommand| is implementation of |WebFrame::executeCommand|
    // rather than |Document::execCommand|.
    bool executeCommand(const String&);
    bool executeCommand(const String& commandName, const String& value);

    bool insertText(const String&, KeyboardEvent* triggeringEvent);
    bool insertTextWithoutSendingTextEvent(const String&, bool selectInsertedText, TextEvent* triggeringEvent);
    bool insertLineBreak();
    bool insertParagraphSeparator();

    bool isOverwriteModeEnabled() const { return m_overwriteModeEnabled; }
    void toggleOverwriteModeEnabled();

    bool canUndo();
    void undo();
    bool canRedo();
    void redo();

    void setBaseWritingDirection(WritingDirection);

    // smartInsertDeleteEnabled and selectTrailingWhitespaceEnabled are
    // mutually exclusive, meaning that enabling one will disable the other.
    bool smartInsertDeleteEnabled() const;

    bool preventRevealSelection() const { return m_preventRevealSelection; }

    void clear();

    VisibleSelection selectionForCommand(Event*);

    EditingBehavior behavior() const;

    PassRefPtrWillBeRawPtr<Range> selectedRange();

    void pasteAsFragment(PassRefPtrWillBeRawPtr<DocumentFragment>, bool smartReplace, bool matchStyle);
    void pasteAsPlainText(const String&, bool smartReplace);

    Element* findEventTargetFrom(const VisibleSelection&) const;

    bool findString(const String&, FindOptions);
    // FIXME: Switch callers over to the FindOptions version and retire this one.
    bool findString(const String&, bool forward, bool caseFlag, bool wrapFlag, bool startInSelection);

    PassRefPtrWillBeRawPtr<Range> findStringAndScrollToVisible(const String&, Range*, FindOptions);

    const VisibleSelection& mark() const; // Mark, to be used as emacs uses it.
    void setMark(const VisibleSelection&);

    void computeAndSetTypingStyle(StylePropertySet* , EditAction = EditActionUnspecified);

    IntRect firstRectForRange(Range*) const;

    void respondToChangedSelection(const VisibleSelection& oldSelection, FrameSelection::SetSelectionOptions);

    bool markedTextMatchesAreHighlighted() const;
    void setMarkedTextMatchesAreHighlighted(bool);

    void replaceSelectionWithFragment(PassRefPtrWillBeRawPtr<DocumentFragment>, bool selectReplacement, bool smartReplace, bool matchStyle);
    void replaceSelectionWithText(const String&, bool selectReplacement, bool smartReplace);

    EditorParagraphSeparator defaultParagraphSeparator() const { return m_defaultParagraphSeparator; }
    void setDefaultParagraphSeparator(EditorParagraphSeparator separator) { m_defaultParagraphSeparator = separator; }

    class RevealSelectionScope {
        WTF_MAKE_NONCOPYABLE(RevealSelectionScope);
    public:
        RevealSelectionScope(Editor*);
        ~RevealSelectionScope();
    private:
        Editor* m_editor;
    };
    friend class RevealSelectionScope;

    void trace(Visitor*);

private:
    LocalFrame& m_frame;
    RefPtrWillBeMember<CompositeEditCommand> m_lastEditCommand;
    int m_preventRevealSelection;
    bool m_shouldStyleWithCSS;
    VisibleSelection m_mark;
    bool m_areMarkedTextMatchesHighlighted;
    EditorParagraphSeparator m_defaultParagraphSeparator;
    bool m_overwriteModeEnabled;

    explicit Editor(LocalFrame&);

    bool canDeleteRange(Range*) const;

    UndoStack* undoStack() const;

    bool tryDHTMLCopy();
    bool tryDHTMLCut();

    void revealSelectionAfterEditingOperation(const ScrollAlignment& = ScrollAlignment::alignCenterIfNeeded, RevealExtentOption = DoNotRevealExtent);
    void changeSelectionAfterCommand(const VisibleSelection& newSelection, FrameSelection::SetSelectionOptions);
    void notifyComponentsOnChangedSelection(const VisibleSelection& oldSelection, FrameSelection::SetSelectionOptions);

    Element* findEventTargetFromSelection() const;

    PassRefPtrWillBeRawPtr<Range> rangeOfString(const String&, Range*, FindOptions);

    SpellChecker& spellChecker() const;

    bool handleEditingKeyboardEvent(blink::KeyboardEvent*);
};

inline const VisibleSelection& Editor::mark() const
{
    return m_mark;
}

inline void Editor::setMark(const VisibleSelection& selection)
{
    m_mark = selection;
}

inline bool Editor::markedTextMatchesAreHighlighted() const
{
    return m_areMarkedTextMatchesHighlighted;
}


} // namespace blink

#endif // Editor_h
