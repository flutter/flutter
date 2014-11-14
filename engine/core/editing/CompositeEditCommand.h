/*
 * Copyright (C) 2005, 2006, 2008 Apple Inc. All rights reserved.
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

#ifndef CompositeEditCommand_h
#define CompositeEditCommand_h

#include "core/CSSPropertyNames.h"
#include "core/editing/EditCommand.h"
#include "core/editing/UndoStep.h"
#include "wtf/Vector.h"

namespace blink {

class EditingStyle;
class Element;
class HTMLElement;
class Text;

class EditCommandComposition final : public UndoStep {
public:
    static PassRefPtr<EditCommandComposition> create(Document*, const VisibleSelection&, const VisibleSelection&, EditAction);

    virtual bool belongsTo(const LocalFrame&) const override;
    virtual void unapply() override;
    virtual void reapply() override;
    virtual EditAction editingAction() const override { return m_editAction; }
    void append(SimpleEditCommand*);

    const VisibleSelection& startingSelection() const { return m_startingSelection; }
    const VisibleSelection& endingSelection() const { return m_endingSelection; }
    void setStartingSelection(const VisibleSelection&);
    void setEndingSelection(const VisibleSelection&);
    Element* startingRootEditableElement() const { return m_startingRootEditableElement.get(); }
    Element* endingRootEditableElement() const { return m_endingRootEditableElement.get(); }

private:
    EditCommandComposition(Document*, const VisibleSelection& startingSelection, const VisibleSelection& endingSelection, EditAction);

    RefPtr<Document> m_document;
    VisibleSelection m_startingSelection;
    VisibleSelection m_endingSelection;
    Vector<RefPtr<SimpleEditCommand> > m_commands;
    RefPtr<Element> m_startingRootEditableElement;
    RefPtr<Element> m_endingRootEditableElement;
    EditAction m_editAction;
};

class CompositeEditCommand : public EditCommand {
public:
    virtual ~CompositeEditCommand();

    void apply();
    bool isFirstCommand(EditCommand* command) { return !m_commands.isEmpty() && m_commands.first() == command; }
    EditCommandComposition* composition() { return m_composition.get(); }
    EditCommandComposition* ensureComposition();

    virtual bool isTypingCommand() const;
    virtual bool preservesTypingStyle() const;
    virtual void setShouldRetainAutocorrectionIndicator(bool);
    virtual bool shouldStopCaretBlinking() const { return false; }

protected:
    explicit CompositeEditCommand(Document&);

    //
    // sugary-sweet convenience functions to help create and apply edit commands in composite commands
    //
    void appendNode(PassRefPtr<Node>, PassRefPtr<ContainerNode> parent);
    void applyCommandToComposite(PassRefPtr<EditCommand>);
    void applyCommandToComposite(PassRefPtr<CompositeEditCommand>, const VisibleSelection&);
    void removeStyledElement(PassRefPtr<Element>);
    void deleteSelection(bool smartDelete = false, bool mergeBlocksAfterDelete = true, bool expandForSpecialElements = true, bool sanitizeMarkup = true);
    void deleteSelection(const VisibleSelection&, bool smartDelete = false, bool mergeBlocksAfterDelete = true, bool expandForSpecialElements = true, bool sanitizeMarkup = true);
    virtual void deleteTextFromNode(PassRefPtr<Text>, unsigned offset, unsigned count);
    bool isRemovableBlock(const Node*);
    void insertNodeAfter(PassRefPtr<Node>, PassRefPtr<Node> refChild);
    void insertNodeAt(PassRefPtr<Node>, const Position&);
    void insertNodeAtTabSpanPosition(PassRefPtr<Node>, const Position&);
    void insertNodeBefore(PassRefPtr<Node>, PassRefPtr<Node> refChild, ShouldAssumeContentIsAlwaysEditable = DoNotAssumeContentIsAlwaysEditable);
    void insertParagraphSeparator(bool useDefaultParagraphElement = false, bool pasteBlockqutoeIntoUnquotedArea = false);
    void insertTextIntoNode(PassRefPtr<Text>, unsigned offset, const String& text);
    void rebalanceWhitespace();
    void rebalanceWhitespaceAt(const Position&);
    void rebalanceWhitespaceOnTextSubstring(PassRefPtr<Text>, int startOffset, int endOffset);
    void prepareWhitespaceAtPositionForSplit(Position&);
    void replaceCollapsibleWhitespaceWithNonBreakingSpaceIfNeeded(const VisiblePosition&);
    bool canRebalance(const Position&) const;
    bool shouldRebalanceLeadingWhitespaceFor(const String&) const;
    void removeChildrenInRange(PassRefPtr<Node>, unsigned from, unsigned to);
    virtual void removeNode(PassRefPtr<Node>, ShouldAssumeContentIsAlwaysEditable = DoNotAssumeContentIsAlwaysEditable);
    void removeNodePreservingChildren(PassRefPtr<Node>, ShouldAssumeContentIsAlwaysEditable = DoNotAssumeContentIsAlwaysEditable);
    void removeNodeAndPruneAncestors(PassRefPtr<Node>, Node* excludeNode = 0);
    void moveRemainingSiblingsToNewParent(Node*, Node* pastLastNodeToMove, PassRefPtr<Element> prpNewParent);
    void updatePositionForNodeRemovalPreservingChildren(Position&, Node&);
    void prune(PassRefPtr<Node>, Node* excludeNode = 0);
    void replaceTextInNode(PassRefPtr<Text>, unsigned offset, unsigned count, const String& replacementText);
    Position replaceSelectedTextInNode(const String&);
    void replaceTextInNodePreservingMarkers(PassRefPtr<Text>, unsigned offset, unsigned count, const String& replacementText);
    Position positionOutsideTabSpan(const Position&);
    void splitElement(PassRefPtr<Element>, PassRefPtr<Node> atChild);
    void splitTextNode(PassRefPtr<Text>, unsigned offset);
    void splitTextNodeContainingElement(PassRefPtr<Text>, unsigned offset);

    void deleteInsignificantText(PassRefPtr<Text>, unsigned start, unsigned end);
    void deleteInsignificantText(const Position& start, const Position& end);
    void deleteInsignificantTextDownstream(const Position&);

    void removePlaceholderAt(const Position&);

    PassRefPtr<HTMLElement> insertNewDefaultParagraphElementAt(const Position&);

    PassRefPtr<HTMLElement> moveParagraphContentsToNewBlockIfNecessary(const Position&);

    void pushAnchorElementDown(Element*);

    // FIXME: preserveSelection and preserveStyle should be enums
    void moveParagraph(const VisiblePosition&, const VisiblePosition&, const VisiblePosition&, bool preserveSelection = false, bool preserveStyle = true, Node* constrainingAncestor = 0);
    void moveParagraphs(const VisiblePosition&, const VisiblePosition&, const VisiblePosition&, bool preserveSelection = false, bool preserveStyle = true, Node* constrainingAncestor = 0);
    void moveParagraphWithClones(const VisiblePosition& startOfParagraphToMove, const VisiblePosition& endOfParagraphToMove, HTMLElement* blockElement, Node* outerNode);
    void cloneParagraphUnderNewElement(const Position& start, const Position& end, Node* outerNode, Element* blockElement);
    void cleanupAfterDeletion(VisiblePosition destination = VisiblePosition());

    bool breakOutOfEmptyListItem();
    bool breakOutOfEmptyMailBlockquotedParagraph();

    Position positionAvoidingSpecialElementBoundary(const Position&);

    PassRefPtr<Node> splitTreeToNode(Node*, Node*, bool splitAncestor = false);

    Vector<RefPtr<EditCommand> > m_commands;

private:
    virtual bool isCompositeEditCommand() const override final { return true; }

    RefPtr<EditCommandComposition> m_composition;
};

DEFINE_TYPE_CASTS(CompositeEditCommand, EditCommand, command, command->isCompositeEditCommand(), command.isCompositeEditCommand());

} // namespace blink

#endif // CompositeEditCommand_h
