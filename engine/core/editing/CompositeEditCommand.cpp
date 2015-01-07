/*
 * Copyright (C) 2005, 2006, 2007, 2008 Apple Inc. All rights reserved.
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
#include "sky/engine/core/editing/CompositeEditCommand.h"

#include "sky/engine/bindings/core/v8/ExceptionStatePlaceholder.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/DocumentFragment.h"
#include "sky/engine/core/dom/DocumentMarkerController.h"
#include "sky/engine/core/dom/ElementTraversal.h"
#include "sky/engine/core/dom/NodeTraversal.h"
#include "sky/engine/core/dom/Range.h"
#include "sky/engine/core/dom/Text.h"
#include "sky/engine/core/editing/AppendNodeCommand.h"
#include "sky/engine/core/editing/DeleteFromTextNodeCommand.h"
#include "sky/engine/core/editing/DeleteSelectionCommand.h"
#include "sky/engine/core/editing/Editor.h"
#include "sky/engine/core/editing/InsertIntoTextNodeCommand.h"
#include "sky/engine/core/editing/InsertLineBreakCommand.h"
#include "sky/engine/core/editing/InsertNodeBeforeCommand.h"
#include "sky/engine/core/editing/InsertParagraphSeparatorCommand.h"
#include "sky/engine/core/editing/PlainTextRange.h"
#include "sky/engine/core/editing/RemoveNodeCommand.h"
#include "sky/engine/core/editing/RemoveNodePreservingChildrenCommand.h"
#include "sky/engine/core/editing/ReplaceSelectionCommand.h"
#include "sky/engine/core/editing/SpellChecker.h"
#include "sky/engine/core/editing/SplitElementCommand.h"
#include "sky/engine/core/editing/SplitTextNodeCommand.h"
#include "sky/engine/core/editing/TextIterator.h"
#include "sky/engine/core/editing/VisibleUnits.h"
#include "sky/engine/core/editing/htmlediting.h"
#include "sky/engine/core/events/ScopedEventQueue.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/html/HTMLElement.h"
#include "sky/engine/core/rendering/InlineTextBox.h"
#include "sky/engine/core/rendering/RenderBlock.h"
#include "sky/engine/core/rendering/RenderText.h"

namespace blink {

PassRefPtr<EditCommandComposition> EditCommandComposition::create(Document* document,
    const VisibleSelection& startingSelection, const VisibleSelection& endingSelection, EditAction editAction)
{
    return adoptRef(new EditCommandComposition(document, startingSelection, endingSelection, editAction));
}

EditCommandComposition::EditCommandComposition(Document* document, const VisibleSelection& startingSelection, const VisibleSelection& endingSelection, EditAction editAction)
    : m_document(document)
    , m_startingSelection(startingSelection)
    , m_endingSelection(endingSelection)
    , m_startingRootEditableElement(startingSelection.rootEditableElement())
    , m_endingRootEditableElement(endingSelection.rootEditableElement())
    , m_editAction(editAction)
{
}

bool EditCommandComposition::belongsTo(const LocalFrame& frame) const
{
    ASSERT(m_document);
    return m_document->frame() == &frame;
}

void EditCommandComposition::unapply()
{
    ASSERT(m_document);
    RefPtr<LocalFrame> frame = m_document->frame();
    ASSERT(frame);

    // Changes to the document may have been made since the last editing operation that require a layout, as in <rdar://problem/5658603>.
    // Low level operations, like RemoveNodeCommand, don't require a layout because the high level operations that use them perform one
    // if one is necessary (like for the creation of VisiblePositions).
    m_document->updateLayout();

    {
        size_t size = m_commands.size();
        for (size_t i = size; i; --i)
            m_commands[i - 1]->doUnapply();
    }

    frame->editor().unappliedEditing(this);
}

void EditCommandComposition::reapply()
{
    ASSERT(m_document);
    RefPtr<LocalFrame> frame = m_document->frame();
    ASSERT(frame);

    // Changes to the document may have been made since the last editing operation that require a layout, as in <rdar://problem/5658603>.
    // Low level operations, like RemoveNodeCommand, don't require a layout because the high level operations that use them perform one
    // if one is necessary (like for the creation of VisiblePositions).
    m_document->updateLayout();

    {
        size_t size = m_commands.size();
        for (size_t i = 0; i != size; ++i)
            m_commands[i]->doReapply();
    }

    frame->editor().reappliedEditing(this);
}

void EditCommandComposition::append(SimpleEditCommand* command)
{
    m_commands.append(command);
}

void EditCommandComposition::setStartingSelection(const VisibleSelection& selection)
{
    m_startingSelection = selection;
    m_startingRootEditableElement = selection.rootEditableElement();
}

void EditCommandComposition::setEndingSelection(const VisibleSelection& selection)
{
    m_endingSelection = selection;
    m_endingRootEditableElement = selection.rootEditableElement();
}

CompositeEditCommand::CompositeEditCommand(Document& document)
    : EditCommand(document)
{
}

CompositeEditCommand::~CompositeEditCommand()
{
    ASSERT(isTopLevelCommand() || !m_composition);
}

void CompositeEditCommand::apply()
{
    if (!endingSelection().isContentRichlyEditable()) {
        switch (editingAction()) {
        case EditActionTyping:
        case EditActionPaste:
        case EditActionDrag:
        case EditActionSetWritingDirection:
        case EditActionCut:
        case EditActionUnspecified:
            break;
        default:
            ASSERT_NOT_REACHED();
            return;
        }
    }
    ensureComposition();

    // Changes to the document may have been made since the last editing operation that require a layout, as in <rdar://problem/5658603>.
    // Low level operations, like RemoveNodeCommand, don't require a layout because the high level operations that use them perform one
    // if one is necessary (like for the creation of VisiblePositions).
    document().updateLayout();

    LocalFrame* frame = document().frame();
    ASSERT(frame);
    {
        EventQueueScope eventQueueScope;
        doApply();
    }

    // Only need to call appliedEditing for top-level commands,
    // and TypingCommands do it on their own (see TypingCommand::typingAddedToOpenCommand).
    if (!isTypingCommand())
        frame->editor().appliedEditing(this);
    setShouldRetainAutocorrectionIndicator(false);
}

EditCommandComposition* CompositeEditCommand::ensureComposition()
{
    CompositeEditCommand* command = this;
    while (command && command->parent())
        command = command->parent();
    if (!command->m_composition)
        command->m_composition = EditCommandComposition::create(&document(), startingSelection(), endingSelection(), editingAction());
    return command->m_composition.get();
}

bool CompositeEditCommand::preservesTypingStyle() const
{
    return false;
}

bool CompositeEditCommand::isTypingCommand() const
{
    return false;
}

void CompositeEditCommand::setShouldRetainAutocorrectionIndicator(bool)
{
}

//
// sugary-sweet convenience functions to help create and apply edit commands in composite commands
//
void CompositeEditCommand::applyCommandToComposite(PassRefPtr<EditCommand> prpCommand)
{
    RefPtr<EditCommand> command = prpCommand;
    command->setParent(this);
    command->doApply();
    if (command->isSimpleEditCommand()) {
        command->setParent(0);
        ensureComposition()->append(toSimpleEditCommand(command.get()));
    }
    m_commands.append(command.release());
}

void CompositeEditCommand::applyCommandToComposite(PassRefPtr<CompositeEditCommand> command, const VisibleSelection& selection)
{
    command->setParent(this);
    if (selection != command->endingSelection()) {
        command->setStartingSelection(selection);
        command->setEndingSelection(selection);
    }
    command->doApply();
    m_commands.append(command);
}

void CompositeEditCommand::insertParagraphSeparator(bool useDefaultParagraphElement, bool pasteBlockqutoeIntoUnquotedArea)
{
    applyCommandToComposite(InsertParagraphSeparatorCommand::create(document(), useDefaultParagraphElement, pasteBlockqutoeIntoUnquotedArea));
}

bool CompositeEditCommand::isRemovableBlock(const Node* node)
{
    return false;
}

void CompositeEditCommand::insertNodeBefore(PassRefPtr<Node> insertChild, PassRefPtr<Node> refChild, ShouldAssumeContentIsAlwaysEditable shouldAssumeContentIsAlwaysEditable)
{
    applyCommandToComposite(InsertNodeBeforeCommand::create(insertChild, refChild, shouldAssumeContentIsAlwaysEditable));
}

void CompositeEditCommand::insertNodeAfter(PassRefPtr<Node> insertChild, PassRefPtr<Node> refChild)
{
    ASSERT(insertChild);
    ASSERT(refChild);
    ContainerNode* parent = refChild->parentNode();
    ASSERT(parent);
    ASSERT(!parent->isShadowRoot());
    if (parent->lastChild() == refChild)
        appendNode(insertChild, parent);
    else {
        ASSERT(refChild->nextSibling());
        insertNodeBefore(insertChild, refChild->nextSibling());
    }
}

void CompositeEditCommand::insertNodeAt(PassRefPtr<Node> insertChild, const Position& editingPosition)
{
    ASSERT(isEditablePosition(editingPosition, ContentIsEditable, DoNotUpdateStyle));
    // For editing positions like [table, 0], insert before the table,
    // likewise for replaced elements, brs, etc.
    Position p = editingPosition.parentAnchoredEquivalent();
    Node* refChild = p.deprecatedNode();
    int offset = p.deprecatedEditingOffset();

    if (canHaveChildrenForEditing(refChild)) {
        Node* child = refChild->firstChild();
        for (int i = 0; child && i < offset; i++)
            child = child->nextSibling();
        if (child)
            insertNodeBefore(insertChild, child);
        else
            appendNode(insertChild, toContainerNode(refChild));
    } else if (caretMinOffset(refChild) >= offset)
        insertNodeBefore(insertChild, refChild);
    else if (refChild->isTextNode() && caretMaxOffset(refChild) > offset) {
        splitTextNode(toText(refChild), offset);

        // Mutation events (bug 22634) from the text node insertion may have removed the refChild
        if (!refChild->inDocument())
            return;
        insertNodeBefore(insertChild, refChild);
    } else
        insertNodeAfter(insertChild, refChild);
}

void CompositeEditCommand::appendNode(PassRefPtr<Node> node, PassRefPtr<ContainerNode> parent)
{
    ASSERT(canHaveChildrenForEditing(parent.get()));
    applyCommandToComposite(AppendNodeCommand::create(parent, node));
}

void CompositeEditCommand::removeChildrenInRange(PassRefPtr<Node> node, unsigned from, unsigned to)
{
    Vector<RefPtr<Node> > children;
    Node* child = NodeTraversal::childAt(*node, from);
    for (unsigned i = from; child && i < to; i++, child = child->nextSibling())
        children.append(child);

    size_t size = children.size();
    for (size_t i = 0; i < size; ++i)
        removeNode(children[i].release());
}

void CompositeEditCommand::removeNode(PassRefPtr<Node> node, ShouldAssumeContentIsAlwaysEditable shouldAssumeContentIsAlwaysEditable)
{
    if (!node || !node->nonShadowBoundaryParentNode())
        return;
    applyCommandToComposite(RemoveNodeCommand::create(node, shouldAssumeContentIsAlwaysEditable));
}

void CompositeEditCommand::removeNodePreservingChildren(PassRefPtr<Node> node, ShouldAssumeContentIsAlwaysEditable shouldAssumeContentIsAlwaysEditable)
{
    applyCommandToComposite(RemoveNodePreservingChildrenCommand::create(node, shouldAssumeContentIsAlwaysEditable));
}

void CompositeEditCommand::removeNodeAndPruneAncestors(PassRefPtr<Node> node, Node* excludeNode)
{
    ASSERT(node.get() != excludeNode);
    RefPtr<ContainerNode> parent = node->parentNode();
    removeNode(node);
    prune(parent.release(), excludeNode);
}

void CompositeEditCommand::moveRemainingSiblingsToNewParent(Node* node, Node* pastLastNodeToMove, PassRefPtr<Element> prpNewParent)
{
    NodeVector nodesToRemove;
    RefPtr<Element> newParent = prpNewParent;

    for (; node && node != pastLastNodeToMove; node = node->nextSibling())
        nodesToRemove.append(node);

    for (unsigned i = 0; i < nodesToRemove.size(); i++) {
        removeNode(nodesToRemove[i]);
        appendNode(nodesToRemove[i], newParent);
    }
}

void CompositeEditCommand::updatePositionForNodeRemovalPreservingChildren(Position& position, Node& node)
{
    int offset = (position.anchorType() == Position::PositionIsOffsetInAnchor) ? position.offsetInContainerNode() : 0;
    updatePositionForNodeRemoval(position, node);
    if (offset)
        position.moveToOffset(offset);
}

void CompositeEditCommand::prune(PassRefPtr<Node> node, Node* excludeNode)
{
    if (RefPtr<Node> highestNodeToRemove = highestNodeToRemoveInPruning(node.get(), excludeNode))
        removeNode(highestNodeToRemove.release());
}

void CompositeEditCommand::splitTextNode(PassRefPtr<Text> node, unsigned offset)
{
    applyCommandToComposite(SplitTextNodeCommand::create(node, offset));
}

void CompositeEditCommand::splitElement(PassRefPtr<Element> element, PassRefPtr<Node> atChild)
{
    applyCommandToComposite(SplitElementCommand::create(element, atChild));
}

void CompositeEditCommand::insertTextIntoNode(PassRefPtr<Text> node, unsigned offset, const String& text)
{
    if (!text.isEmpty())
        applyCommandToComposite(InsertIntoTextNodeCommand::create(node, offset, text));
}

void CompositeEditCommand::deleteTextFromNode(PassRefPtr<Text> node, unsigned offset, unsigned count)
{
    applyCommandToComposite(DeleteFromTextNodeCommand::create(node, offset, count));
}

void CompositeEditCommand::replaceTextInNode(PassRefPtr<Text> prpNode, unsigned offset, unsigned count, const String& replacementText)
{
    RefPtr<Text> node(prpNode);
    applyCommandToComposite(DeleteFromTextNodeCommand::create(node, offset, count));
    if (!replacementText.isEmpty())
        applyCommandToComposite(InsertIntoTextNodeCommand::create(node, offset, replacementText));
}

Position CompositeEditCommand::replaceSelectedTextInNode(const String& text)
{
    Position start = endingSelection().start();
    Position end = endingSelection().end();
    if (start.containerNode() != end.containerNode() || !start.containerNode()->isTextNode())
        return Position();

    RefPtr<Text> textNode = start.containerText();
    replaceTextInNode(textNode, start.offsetInContainerNode(), end.offsetInContainerNode() - start.offsetInContainerNode(), text);

    return Position(textNode.release(), start.offsetInContainerNode() + text.length());
}

static void copyMarkerTypesAndDescriptions(const DocumentMarkerVector& markerPointers, Vector<DocumentMarker::MarkerType>& types, Vector<String>& descriptions)
{
    size_t arraySize = markerPointers.size();
    types.reserveCapacity(arraySize);
    descriptions.reserveCapacity(arraySize);
    for (size_t i = 0; i < arraySize; ++i) {
        types.append(markerPointers[i]->type());
        descriptions.append(markerPointers[i]->description());
    }
}

void CompositeEditCommand::replaceTextInNodePreservingMarkers(PassRefPtr<Text> prpNode, unsigned offset, unsigned count, const String& replacementText)
{
    RefPtr<Text> node(prpNode);
    DocumentMarkerController& markerController = document().markers();
    Vector<DocumentMarker::MarkerType> types;
    Vector<String> descriptions;
    copyMarkerTypesAndDescriptions(markerController.markersInRange(Range::create(document(), node.get(), offset, node.get(), offset + count).get(), DocumentMarker::AllMarkers()), types, descriptions);
    replaceTextInNode(node, offset, count, replacementText);
    RefPtr<Range> newRange = Range::create(document(), node.get(), offset, node.get(), offset + replacementText.length());
    ASSERT(types.size() == descriptions.size());
    for (size_t i = 0; i < types.size(); ++i)
        markerController.addMarker(newRange.get(), types[i], descriptions[i]);
}

Position CompositeEditCommand::positionOutsideTabSpan(const Position& pos)
{
    return pos;
}

void CompositeEditCommand::insertNodeAtTabSpanPosition(PassRefPtr<Node> node, const Position& pos)
{
    // insert node before, after, or at split of tab span
    insertNodeAt(node, positionOutsideTabSpan(pos));
}

void CompositeEditCommand::deleteSelection(bool smartDelete, bool mergeBlocksAfterDelete, bool expandForSpecialElements, bool sanitizeMarkup)
{
    if (endingSelection().isRange())
        applyCommandToComposite(DeleteSelectionCommand::create(document(), smartDelete, mergeBlocksAfterDelete, expandForSpecialElements, sanitizeMarkup));
}

void CompositeEditCommand::deleteSelection(const VisibleSelection &selection, bool smartDelete, bool mergeBlocksAfterDelete, bool expandForSpecialElements, bool sanitizeMarkup)
{
    if (selection.isRange())
        applyCommandToComposite(DeleteSelectionCommand::create(selection, smartDelete, mergeBlocksAfterDelete, expandForSpecialElements, sanitizeMarkup));
}

static inline bool containsOnlyWhitespace(const String& text)
{
    for (unsigned i = 0; i < text.length(); ++i) {
        if (!isWhitespace(text[i]))
            return false;
    }

    return true;
}

bool CompositeEditCommand::shouldRebalanceLeadingWhitespaceFor(const String& text) const
{
    return containsOnlyWhitespace(text);
}

bool CompositeEditCommand::canRebalance(const Position& position) const
{
    Node* node = position.containerNode();
    if (position.anchorType() != Position::PositionIsOffsetInAnchor || !node || !node->isTextNode())
        return false;

    Text* textNode = toText(node);
    if (textNode->length() == 0)
        return false;

    RenderText* renderer = textNode->renderer();
    if (renderer && !renderer->style()->collapseWhiteSpace())
        return false;

    return true;
}

// FIXME: Doesn't go into text nodes that contribute adjacent text (siblings, cousins, etc).
void CompositeEditCommand::rebalanceWhitespaceAt(const Position& position)
{
    Node* node = position.containerNode();
    if (!canRebalance(position))
        return;

    // If the rebalance is for the single offset, and neither text[offset] nor text[offset - 1] are some form of whitespace, do nothing.
    int offset = position.deprecatedEditingOffset();
    String text = toText(node)->data();
    if (!isWhitespace(text[offset])) {
        offset--;
        if (offset < 0 || !isWhitespace(text[offset]))
            return;
    }

    rebalanceWhitespaceOnTextSubstring(toText(node), position.offsetInContainerNode(), position.offsetInContainerNode());
}

void CompositeEditCommand::rebalanceWhitespaceOnTextSubstring(PassRefPtr<Text> prpTextNode, int startOffset, int endOffset)
{
    RefPtr<Text> textNode = prpTextNode;

    String text = textNode->data();
    ASSERT(!text.isEmpty());

    // Set upstream and downstream to define the extent of the whitespace surrounding text[offset].
    int upstream = startOffset;
    while (upstream > 0 && isWhitespace(text[upstream - 1]))
        upstream--;

    int downstream = endOffset;
    while ((unsigned)downstream < text.length() && isWhitespace(text[downstream]))
        downstream++;

    int length = downstream - upstream;
    if (!length)
        return;

    VisiblePosition visibleUpstreamPos(Position(textNode, upstream));
    VisiblePosition visibleDownstreamPos(Position(textNode, downstream));

    String string = text.substring(upstream, length);
    String rebalancedString = stringWithRebalancedWhitespace(string,
    // FIXME: Because of the problem mentioned at the top of this function, we must also use nbsps at the start/end of the string because
    // this function doesn't get all surrounding whitespace, just the whitespace in the current text node.
                                                             isStartOfParagraph(visibleUpstreamPos) || upstream == 0,
                                                             isEndOfParagraph(visibleDownstreamPos) || (unsigned)downstream == text.length());

    if (string != rebalancedString)
        replaceTextInNodePreservingMarkers(textNode.release(), upstream, length, rebalancedString);
}

void CompositeEditCommand::prepareWhitespaceAtPositionForSplit(Position& position)
{
    Node* node = position.deprecatedNode();
    if (!node || !node->isTextNode())
        return;
    Text* textNode = toText(node);

    if (textNode->length() == 0)
        return;
    RenderText* renderer = textNode->renderer();
    if (renderer && !renderer->style()->collapseWhiteSpace())
        return;

    // Delete collapsed whitespace so that inserting nbsps doesn't uncollapse it.
    Position upstreamPos = position.upstream();
    deleteInsignificantText(upstreamPos, position.downstream());
    position = upstreamPos.downstream();

    VisiblePosition visiblePos(position);
    VisiblePosition previousVisiblePos(visiblePos.previous());
    replaceCollapsibleWhitespaceWithNonBreakingSpaceIfNeeded(previousVisiblePos);
    replaceCollapsibleWhitespaceWithNonBreakingSpaceIfNeeded(visiblePos);
}

void CompositeEditCommand::replaceCollapsibleWhitespaceWithNonBreakingSpaceIfNeeded(const VisiblePosition& visiblePosition)
{
    if (!isCollapsibleWhitespace(visiblePosition.characterAfter()))
        return;
    Position pos = visiblePosition.deepEquivalent().downstream();
    if (!pos.containerNode() || !pos.containerNode()->isTextNode())
        return;
    replaceTextInNodePreservingMarkers(pos.containerText(), pos.offsetInContainerNode(), 1, nonBreakingSpaceString());
}

void CompositeEditCommand::rebalanceWhitespace()
{
    VisibleSelection selection = endingSelection();
    if (selection.isNone())
        return;

    rebalanceWhitespaceAt(selection.start());
    if (selection.isRange())
        rebalanceWhitespaceAt(selection.end());
}

void CompositeEditCommand::deleteInsignificantText(PassRefPtr<Text> textNode, unsigned start, unsigned end)
{
    if (!textNode || start >= end)
        return;

    document().updateLayout();

    RenderText* textRenderer = textNode->renderer();
    if (!textRenderer)
        return;

    Vector<InlineTextBox*> sortedTextBoxes;
    size_t sortedTextBoxesPosition = 0;

    for (InlineTextBox* textBox = textRenderer->firstTextBox(); textBox; textBox = textBox->nextTextBox())
        sortedTextBoxes.append(textBox);

    // If there is mixed directionality text, the boxes can be out of order,
    // (like Arabic with embedded LTR), so sort them first.
    if (textRenderer->containsReversedText())
        std::sort(sortedTextBoxes.begin(), sortedTextBoxes.end(), InlineTextBox::compareByStart);
    InlineTextBox* box = sortedTextBoxes.isEmpty() ? 0 : sortedTextBoxes[sortedTextBoxesPosition];

    if (!box) {
        // whole text node is empty
        removeNode(textNode);
        return;
    }

    unsigned length = textNode->length();
    if (start >= length || end > length)
        return;

    unsigned removed = 0;
    InlineTextBox* prevBox = 0;
    String str;

    // This loop structure works to process all gaps preceding a box,
    // and also will look at the gap after the last box.
    while (prevBox || box) {
        unsigned gapStart = prevBox ? prevBox->start() + prevBox->len() : 0;
        if (end < gapStart)
            // No more chance for any intersections
            break;

        unsigned gapEnd = box ? box->start() : length;
        bool indicesIntersect = start <= gapEnd && end >= gapStart;
        int gapLen = gapEnd - gapStart;
        if (indicesIntersect && gapLen > 0) {
            gapStart = std::max(gapStart, start);
            if (str.isNull())
                str = textNode->data().substring(start, end - start);
            // remove text in the gap
            str.remove(gapStart - start - removed, gapLen);
            removed += gapLen;
        }

        prevBox = box;
        if (box) {
            if (++sortedTextBoxesPosition < sortedTextBoxes.size())
                box = sortedTextBoxes[sortedTextBoxesPosition];
            else
                box = 0;
        }
    }

    if (!str.isNull()) {
        // Replace the text between start and end with our pruned version.
        if (!str.isEmpty())
            replaceTextInNode(textNode, start, end - start, str);
        else {
            // Assert that we are not going to delete all of the text in the node.
            // If we were, that should have been done above with the call to
            // removeNode and return.
            ASSERT(start > 0 || end - start < textNode->length());
            deleteTextFromNode(textNode, start, end - start);
        }
    }
}

void CompositeEditCommand::deleteInsignificantText(const Position& start, const Position& end)
{
    if (start.isNull() || end.isNull())
        return;

    if (comparePositions(start, end) >= 0)
        return;

    Vector<RefPtr<Text> > nodes;
    for (Node* node = start.deprecatedNode(); node; node = NodeTraversal::next(*node)) {
        if (node->isTextNode())
            nodes.append(toText(node));
        if (node == end.deprecatedNode())
            break;
    }

    for (size_t i = 0; i < nodes.size(); ++i) {
        Text* textNode = nodes[i].get();
        int startOffset = textNode == start.deprecatedNode() ? start.deprecatedEditingOffset() : 0;
        int endOffset = textNode == end.deprecatedNode() ? end.deprecatedEditingOffset() : static_cast<int>(textNode->length());
        deleteInsignificantText(textNode, startOffset, endOffset);
    }
}

void CompositeEditCommand::deleteInsignificantTextDownstream(const Position& pos)
{
    Position end = VisiblePosition(pos, VP_DEFAULT_AFFINITY).next().deepEquivalent().downstream();
    deleteInsignificantText(pos, end);
}

// Assumes that the position is at a placeholder and does the removal without much checking.
void CompositeEditCommand::removePlaceholderAt(const Position& p)
{
    ASSERT(lineBreakExistsAtPosition(p));
    deleteTextFromNode(toText(p.anchorNode()), p.offsetInContainerNode(), 1);
}

void CompositeEditCommand::pushAnchorElementDown(Element* anchorNode)
{
    if (!anchorNode)
        return;

    ASSERT(anchorNode->isLink());

    setEndingSelection(VisibleSelection::selectionFromContentsOfNode(anchorNode));
    // Clones of anchorNode have been pushed down, now remove it.
    if (anchorNode->inDocument())
        removeNodePreservingChildren(anchorNode);
}

// There are bugs in deletion when it removes a fully selected table/list.
// It expands and removes the entire table/list, but will let content
// before and after the table/list collapse onto one line.
// Deleting a paragraph will leave a placeholder. Remove it (and prune
// empty or unrendered parents).

void CompositeEditCommand::cleanupAfterDeletion(VisiblePosition destination)
{
    VisiblePosition caretAfterDelete = endingSelection().visibleStart();
    Node* destinationNode = destination.deepEquivalent().anchorNode();
    if (caretAfterDelete != destination && isStartOfParagraph(caretAfterDelete) && isEndOfParagraph(caretAfterDelete)) {
        // Note: We want the rightmost candidate.
        Position position = caretAfterDelete.deepEquivalent().downstream();
        Node* node = position.deprecatedNode();

        // Bail if we'd remove an ancestor of our destination.
        if (destinationNode && destinationNode->isDescendantOf(node))
            return;

        if (isBlock(node)) {
            // If caret position after deletion and destination position coincides,
            // node should not be removed.
            if (!position.rendersInDifferentPosition(destination.deepEquivalent())) {
                prune(node, destinationNode);
                return;
            }
            removeNodeAndPruneAncestors(node, destinationNode);
        }
        else if (lineBreakExistsAtPosition(position)) {
            // There is a preserved '\n' at caretAfterDelete.
            // We can safely assume this is a text node.
            Text* textNode = toText(node);
            if (textNode->length() == 1)
                removeNodeAndPruneAncestors(node, destinationNode);
            else
                deleteTextFromNode(textNode, position.deprecatedEditingOffset(), 1);
        }
    }
}

void CompositeEditCommand::moveParagraph(const VisiblePosition& startOfParagraphToMove, const VisiblePosition& endOfParagraphToMove, const VisiblePosition& destination, bool preserveSelection, bool preserveStyle, Node* constrainingAncestor)
{
    ASSERT(isStartOfParagraph(startOfParagraphToMove));
    ASSERT(isEndOfParagraph(endOfParagraphToMove));
    moveParagraphs(startOfParagraphToMove, endOfParagraphToMove, destination, preserveSelection, preserveStyle, constrainingAncestor);
}

void CompositeEditCommand::moveParagraphs(const VisiblePosition& startOfParagraphToMove, const VisiblePosition& endOfParagraphToMove, const VisiblePosition& destination, bool preserveSelection, bool preserveStyle, Node* constrainingAncestor)
{
    // FIXME(sky): Remove.
    // We've probably broken editiing badly by deleting this function...
}

// Operations use this function to avoid inserting content into an anchor when at the start or the end of
// that anchor, as in NSTextView.
// FIXME: This is only an approximation of NSTextViews insertion behavior, which varies depending on how
// the caret was made.
Position CompositeEditCommand::positionAvoidingSpecialElementBoundary(const Position& original)
{
    if (original.isNull())
        return original;

    VisiblePosition visiblePos(original);
    Element* enclosingAnchor = enclosingAnchorElement(original);
    Position result = original;

    if (!enclosingAnchor)
        return result;

    // Don't avoid block level anchors, because that would insert content into the wrong paragraph.
    if (enclosingAnchor && !isBlock(enclosingAnchor)) {
        VisiblePosition firstInAnchor(firstPositionInNode(enclosingAnchor));
        VisiblePosition lastInAnchor(lastPositionInNode(enclosingAnchor));
        // If visually just after the anchor, insert *inside* the anchor unless it's the last
        // VisiblePosition in the document, to match NSTextView.
        if (visiblePos == lastInAnchor) {
            // Make sure anchors are pushed down before avoiding them so that we don't
            // also avoid structural elements like lists and blocks (5142012).
            if (original.deprecatedNode() != enclosingAnchor && original.deprecatedNode()->parentNode() != enclosingAnchor) {
                pushAnchorElementDown(enclosingAnchor);
                enclosingAnchor = enclosingAnchorElement(original);
                if (!enclosingAnchor)
                    return original;
            }
            // Don't insert outside an anchor if doing so would skip over a line break.  It would
            // probably be safe to move the line break so that we could still avoid the anchor here.
            Position downstream(visiblePos.deepEquivalent().downstream());
            if (lineBreakExistsAtVisiblePosition(visiblePos) && downstream.deprecatedNode()->isDescendantOf(enclosingAnchor))
                return original;

            result = positionInParentAfterNode(*enclosingAnchor);
        }
        // If visually just before an anchor, insert *outside* the anchor unless it's the first
        // VisiblePosition in a paragraph, to match NSTextView.
        if (visiblePos == firstInAnchor) {
            // Make sure anchors are pushed down before avoiding them so that we don't
            // also avoid structural elements like lists and blocks (5142012).
            if (original.deprecatedNode() != enclosingAnchor && original.deprecatedNode()->parentNode() != enclosingAnchor) {
                pushAnchorElementDown(enclosingAnchor);
                enclosingAnchor = enclosingAnchorElement(original);
            }
            if (!enclosingAnchor)
                return original;

            result = positionInParentBeforeNode(*enclosingAnchor);
        }
    }

    if (result.isNull() || !editableRootForPosition(result))
        result = original;

    return result;
}

// Splits the tree parent by parent until we reach the specified ancestor. We use VisiblePositions
// to determine if the split is necessary. Returns the last split node.
PassRefPtr<Node> CompositeEditCommand::splitTreeToNode(Node* start, Node* end, bool shouldSplitAncestor)
{
    ASSERT(start);
    ASSERT(end);
    ASSERT(start != end);

    if (shouldSplitAncestor && end->parentNode())
        end = end->parentNode();
    if (!start->isDescendantOf(end))
        return end;

    RefPtr<Node> endNode = end;
    RefPtr<Node> node = nullptr;
    for (node = start; node->parentNode() != endNode; node = node->parentNode()) {
        Element* parentElement = node->parentElement();
        if (!parentElement)
            break;
        // Do not split a node when doing so introduces an empty node.
        VisiblePosition positionInParent(firstPositionInNode(parentElement));
        VisiblePosition positionInNode(firstPositionInOrBeforeNode(node.get()));
        if (positionInParent != positionInNode)
            splitElement(parentElement, node);
    }

    return node.release();
}

} // namespace blink
