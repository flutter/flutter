/*
 * Copyright (C) 2005, 2006, 2008 Apple Inc. All rights reserved.
 * Copyright (C) 2009, 2010, 2011 Google Inc. All rights reserved.
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

#include "sky/engine/core/editing/ReplaceSelectionCommand.h"

#include "gen/sky/core/CSSPropertyNames.h"
#include "gen/sky/core/HTMLNames.h"
#include "sky/engine/bindings/exception_state_placeholder.h"
#include "sky/engine/core/css/CSSStyleDeclaration.h"
#include "sky/engine/core/css/StylePropertySet.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/DocumentFragment.h"
#include "sky/engine/core/dom/Element.h"
#include "sky/engine/core/dom/Text.h"
#include "sky/engine/core/editing/FrameSelection.h"
#include "sky/engine/core/editing/HTMLInterchange.h"
#include "sky/engine/core/editing/SmartReplace.h"
#include "sky/engine/core/editing/TextIterator.h"
#include "sky/engine/core/editing/VisibleUnits.h"
#include "sky/engine/core/editing/htmlediting.h"
#include "sky/engine/core/events/BeforeTextInsertedEvent.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/html/HTMLElement.h"
#include "sky/engine/core/rendering/RenderObject.h"
#include "sky/engine/core/rendering/RenderText.h"
#include "sky/engine/wtf/StdLibExtras.h"
#include "sky/engine/wtf/Vector.h"

namespace blink {

enum EFragmentType { EmptyFragment, SingleTextNodeFragment, TreeFragment };

// --- ReplacementFragment helper class

class ReplacementFragment final {
    WTF_MAKE_NONCOPYABLE(ReplacementFragment);
    STACK_ALLOCATED();
public:
    ReplacementFragment(Document*, DocumentFragment*, const VisibleSelection&);

    Node* firstChild() const;
    Node* lastChild() const;

    bool isEmpty() const;

    bool hasInterchangeNewlineAtStart() const { return m_hasInterchangeNewlineAtStart; }
    bool hasInterchangeNewlineAtEnd() const { return m_hasInterchangeNewlineAtEnd; }

    void removeNode(PassRefPtr<Node>);
    void removeNodePreservingChildren(PassRefPtr<ContainerNode>);

private:
    PassRefPtr<HTMLElement> insertFragmentForTestRendering(Element* rootEditableElement);
    void removeUnrenderedNodes(ContainerNode*);
    void restoreAndRemoveTestRenderingNodesToFragment(Element*);
    void removeInterchangeNodes(ContainerNode*);

    void insertNodeBefore(PassRefPtr<Node>, Node* refNode);

    RefPtr<Document> m_document;
    RefPtr<DocumentFragment> m_fragment;
    bool m_hasInterchangeNewlineAtStart;
    bool m_hasInterchangeNewlineAtEnd;
};

static Position positionAvoidingPrecedingNodes(Position pos)
{
    // If we're already on a break, it's probably a placeholder and we shouldn't change our position.
    if (editingIgnoresContent(pos.deprecatedNode()))
        return pos;

    // We also stop when changing block flow elements because even though the visual position is the
    // same.  E.g.,
    //   <div>foo^</div>^
    // The two positions above are the same visual position, but we want to stay in the same block.
    Element* enclosingBlockElement = enclosingBlock(pos.containerNode());
    for (Position nextPosition = pos; nextPosition.containerNode() != enclosingBlockElement; pos = nextPosition) {
        if (lineBreakExistsAtPosition(pos))
            break;

        if (pos.containerNode()->nonShadowBoundaryParentNode())
            nextPosition = positionInParentAfterNode(*pos.containerNode());

        if (nextPosition == pos
            || enclosingBlock(nextPosition.containerNode()) != enclosingBlockElement
            || VisiblePosition(pos) != VisiblePosition(nextPosition))
            break;
    }
    return pos;
}

ReplacementFragment::ReplacementFragment(Document* document, DocumentFragment* fragment, const VisibleSelection& selection)
    : m_document(document),
      m_fragment(fragment),
      m_hasInterchangeNewlineAtStart(false),
      m_hasInterchangeNewlineAtEnd(false)
{
    if (!m_document)
        return;
    if (!m_fragment || !m_fragment->hasChildren())
        return;

    RefPtr<Element> editableRoot = selection.rootEditableElement();
    ASSERT(editableRoot);
    if (!editableRoot)
        return;

    Element* shadowAncestorElement;
    if (editableRoot->isInShadowTree())
        shadowAncestorElement = editableRoot->shadowHost();
    else
        shadowAncestorElement = editableRoot.get();

    if (editableRoot->rendererIsRichlyEditable()) {
        removeInterchangeNodes(m_fragment.get());
        return;
    }

    RefPtr<HTMLElement> holder = insertFragmentForTestRendering(editableRoot.get());
    if (!holder) {
        removeInterchangeNodes(m_fragment.get());
        return;
    }

    RefPtr<Range> range = VisibleSelection::selectionFromContentsOfNode(holder.get()).toNormalizedRange();
    String text = plainText(range.get(), static_cast<TextIteratorBehavior>(TextIteratorEmitsOriginalText | TextIteratorIgnoresStyleVisibility));

    removeInterchangeNodes(holder.get());
    removeUnrenderedNodes(holder.get());
    restoreAndRemoveTestRenderingNodesToFragment(holder.get());

    // Give the root a chance to change the text.
    RefPtr<BeforeTextInsertedEvent> evt = BeforeTextInsertedEvent::create(text);
    editableRoot->dispatchEvent(evt, ASSERT_NO_EXCEPTION);
    if (text != evt->text() || !editableRoot->rendererIsRichlyEditable()) {
        restoreAndRemoveTestRenderingNodesToFragment(holder.get());
        m_fragment = nullptr;
        return;
    }
}

bool ReplacementFragment::isEmpty() const
{
    return (!m_fragment || !m_fragment->hasChildren()) && !m_hasInterchangeNewlineAtStart && !m_hasInterchangeNewlineAtEnd;
}

Node* ReplacementFragment::firstChild() const
{
    return m_fragment ? m_fragment->firstChild() : 0;
}

Node* ReplacementFragment::lastChild() const
{
    return m_fragment ? m_fragment->lastChild() : 0;
}

void ReplacementFragment::removeNodePreservingChildren(PassRefPtr<ContainerNode> node)
{
    if (!node)
        return;

    while (RefPtr<Node> n = node->firstChild()) {
        removeNode(n);
        insertNodeBefore(n.release(), node.get());
    }
    removeNode(node);
}

void ReplacementFragment::removeNode(PassRefPtr<Node> node)
{
    if (!node)
        return;

    ContainerNode* parent = node->nonShadowBoundaryParentNode();
    if (!parent)
        return;

    parent->removeChild(node.get());
}

void ReplacementFragment::insertNodeBefore(PassRefPtr<Node> node, Node* refNode)
{
    if (!node || !refNode)
        return;

    ContainerNode* parent = refNode->nonShadowBoundaryParentNode();
    if (!parent)
        return;

    parent->insertBefore(node, refNode);
}

PassRefPtr<HTMLElement> ReplacementFragment::insertFragmentForTestRendering(Element* rootEditableElement)
{
    ASSERT(m_document);
    RefPtr<HTMLElement> holder = createDefaultParagraphElement(*m_document.get());

    holder->appendChild(m_fragment);
    rootEditableElement->appendChild(holder.get());
    m_document->updateLayout();

    return holder.release();
}

void ReplacementFragment::restoreAndRemoveTestRenderingNodesToFragment(Element* holder)
{
    if (!holder)
        return;

    while (RefPtr<Node> node = holder->firstChild()) {
        holder->removeChild(node.get());
        m_fragment->appendChild(node.get());
    }

    removeNode(holder);
}

void ReplacementFragment::removeUnrenderedNodes(ContainerNode* holder)
{
    Vector<RefPtr<Node> > unrendered;

    for (Node* node = holder->firstChild(); node; node = NodeTraversal::next(*node, holder)) {
        if (!isNodeRendered(node))
            unrendered.append(node);
    }

    size_t n = unrendered.size();
    for (size_t i = 0; i < n; ++i)
        removeNode(unrendered[i]);
}

void ReplacementFragment::removeInterchangeNodes(ContainerNode* container)
{
}

inline void ReplaceSelectionCommand::InsertedNodes::respondToNodeInsertion(Node& node)
{
    if (!m_firstNodeInserted)
        m_firstNodeInserted = &node;

    m_lastNodeInserted = &node;
}

inline void ReplaceSelectionCommand::InsertedNodes::willRemoveNodePreservingChildren(Node& node)
{
    if (m_firstNodeInserted.get() == node)
        m_firstNodeInserted = NodeTraversal::next(node);
    if (m_lastNodeInserted.get() == node)
        m_lastNodeInserted = node.lastChild() ? node.lastChild() : NodeTraversal::nextSkippingChildren(node);
}

inline void ReplaceSelectionCommand::InsertedNodes::willRemoveNode(Node& node)
{
    if (m_firstNodeInserted.get() == node && m_lastNodeInserted.get() == node) {
        m_firstNodeInserted = nullptr;
        m_lastNodeInserted = nullptr;
    } else if (m_firstNodeInserted.get() == node) {
        m_firstNodeInserted = NodeTraversal::nextSkippingChildren(*m_firstNodeInserted);
    } else if (m_lastNodeInserted.get() == node) {
        m_lastNodeInserted = NodeTraversal::previousSkippingChildren(*m_lastNodeInserted);
    }
}

inline void ReplaceSelectionCommand::InsertedNodes::didReplaceNode(Node& node, Node& newNode)
{
    if (m_firstNodeInserted.get() == node)
        m_firstNodeInserted = &newNode;
    if (m_lastNodeInserted.get() == node)
        m_lastNodeInserted = &newNode;
}

ReplaceSelectionCommand::ReplaceSelectionCommand(Document& document, PassRefPtr<DocumentFragment> fragment, CommandOptions options, EditAction editAction)
    : CompositeEditCommand(document)
    , m_selectReplacement(options & SelectReplacement)
    , m_smartReplace(options & SmartReplace)
    , m_matchStyle(options & MatchStyle)
    , m_documentFragment(fragment)
    , m_preventNesting(options & PreventNesting)
    , m_movingParagraph(options & MovingParagraph)
    , m_editAction(editAction)
    , m_shouldMergeEnd(false)
{
}

static bool hasMatchingQuoteLevel(VisiblePosition endOfExistingContent, VisiblePosition endOfInsertedContent)
{
    Position existing = endOfExistingContent.deepEquivalent();
    Position inserted = endOfInsertedContent.deepEquivalent();
    bool isInsideMailBlockquote = enclosingNodeOfType(inserted, isMailHTMLBlockquoteElement, CanCrossEditingBoundary);
    return isInsideMailBlockquote && (numEnclosingMailBlockquotes(existing) == numEnclosingMailBlockquotes(inserted));
}

bool ReplaceSelectionCommand::shouldMergeStart(bool selectionStartWasStartOfParagraph, bool fragmentHasInterchangeNewlineAtStart, bool selectionStartWasInsideMailBlockquote)
{
    if (m_movingParagraph)
        return false;

    VisiblePosition startOfInsertedContent(positionAtStartOfInsertedContent());
    VisiblePosition prev = startOfInsertedContent.previous(CannotCrossEditingBoundary);
    if (prev.isNull())
        return false;

    // When we have matching quote levels, its ok to merge more frequently.
    // For a successful merge, we still need to make sure that the inserted content starts with the beginning of a paragraph.
    // And we should only merge here if the selection start was inside a mail blockquote.  This prevents against removing a
    // blockquote from newly pasted quoted content that was pasted into an unquoted position.  If that unquoted position happens
    // to be right after another blockquote, we don't want to merge and risk stripping a valid block (and newline) from the pasted content.
    if (isStartOfParagraph(startOfInsertedContent) && selectionStartWasInsideMailBlockquote && hasMatchingQuoteLevel(prev, positionAtEndOfInsertedContent()))
        return true;

    return !selectionStartWasStartOfParagraph
        && !fragmentHasInterchangeNewlineAtStart
        && isStartOfParagraph(startOfInsertedContent)
        && shouldMerge(startOfInsertedContent, prev);
}

bool ReplaceSelectionCommand::shouldMergeEnd(bool selectionEndWasEndOfParagraph)
{
    VisiblePosition endOfInsertedContent(positionAtEndOfInsertedContent());
    VisiblePosition next = endOfInsertedContent.next(CannotCrossEditingBoundary);
    if (next.isNull())
        return false;

    return !selectionEndWasEndOfParagraph
        && isEndOfParagraph(endOfInsertedContent)
        && shouldMerge(endOfInsertedContent, next);
}

static bool isMailPasteAsQuotationHTMLBlockQuoteElement(const Node* node)
{
    return false;
}

static bool haveSameTagName(Element* a, Element* b)
{
    return a && b && a->tagName() == b->tagName();
}

bool ReplaceSelectionCommand::shouldMerge(const VisiblePosition& source, const VisiblePosition& destination)
{
    if (source.isNull() || destination.isNull())
        return false;

    Node* sourceNode = source.deepEquivalent().deprecatedNode();
    Node* destinationNode = destination.deepEquivalent().deprecatedNode();
    Element* sourceBlock = enclosingBlock(sourceNode);
    Element* destinationBlock = enclosingBlock(destinationNode);
    return !enclosingNodeOfType(source.deepEquivalent(), &isMailPasteAsQuotationHTMLBlockQuoteElement)
        && sourceBlock && (isMailHTMLBlockquoteElement(sourceBlock))
        && haveSameTagName(sourceBlock, destinationBlock)
        // Don't merge to or from a position before or after a block because it would
        // be a no-op and cause infinite recursion.
        && !isBlock(sourceNode) && !isBlock(destinationNode);
}

// Style rules that match just inserted elements could change their appearance, like
// a div inserted into a document with div { display:inline; }.
void ReplaceSelectionCommand::removeRedundantStylesAndKeepStyleSpanInline(InsertedNodes& insertedNodes)
{
}

void ReplaceSelectionCommand::makeInsertedContentRoundTrippableWithHTMLTreeBuilder(const InsertedNodes& insertedNodes)
{
}

void ReplaceSelectionCommand::moveElementOutOfAncestor(PassRefPtr<Element> prpElement, PassRefPtr<ContainerNode> prpAncestor)
{
    RefPtr<Element> element = prpElement;
    RefPtr<ContainerNode> ancestor = prpAncestor;

    if (!ancestor->parentNode()->hasEditableStyle())
        return;

    VisiblePosition positionAtEndOfNode(lastPositionInOrAfterNode(element.get()));
    VisiblePosition lastPositionInParagraph(lastPositionInNode(ancestor.get()));
    if (positionAtEndOfNode == lastPositionInParagraph) {
        removeNode(element);
        if (ancestor->nextSibling())
            insertNodeBefore(element, ancestor->nextSibling());
        else
            appendNode(element, ancestor->parentNode());
    } else {
        RefPtr<Node> nodeToSplitTo = splitTreeToNode(element.get(), ancestor.get(), true);
        removeNode(element);
        insertNodeBefore(element, nodeToSplitTo);
    }
    if (!ancestor->hasChildren())
        removeNode(ancestor.release());
}

static inline bool nodeHasVisibleRenderText(Text& text)
{
    return text.renderer() && text.renderer()->renderedTextLength() > 0;
}

void ReplaceSelectionCommand::removeUnrenderedTextNodesAtEnds(InsertedNodes& insertedNodes)
{
    document().updateLayout();

    Node* lastLeafInserted = insertedNodes.lastLeafInserted();
    if (lastLeafInserted && lastLeafInserted->isTextNode() && !nodeHasVisibleRenderText(toText(*lastLeafInserted))
        && !enclosingElementWithTag(firstPositionInOrBeforeNode(lastLeafInserted), HTMLNames::scriptTag)) {
        insertedNodes.willRemoveNode(*lastLeafInserted);
        removeNode(lastLeafInserted);
    }

    // We don't have to make sure that firstNodeInserted isn't inside a select or script element, because
    // it is a top level node in the fragment and the user can't insert into those elements.
    Node* firstNodeInserted = insertedNodes.firstNodeInserted();
    if (firstNodeInserted && firstNodeInserted->isTextNode() && !nodeHasVisibleRenderText(toText(*firstNodeInserted))) {
        insertedNodes.willRemoveNode(*firstNodeInserted);
        removeNode(firstNodeInserted);
    }
}

VisiblePosition ReplaceSelectionCommand::positionAtEndOfInsertedContent() const
{
    return VisiblePosition(m_endOfInsertedContent);
}

VisiblePosition ReplaceSelectionCommand::positionAtStartOfInsertedContent() const
{
    return VisiblePosition(m_startOfInsertedContent);
}

void ReplaceSelectionCommand::mergeEndIfNeeded()
{
    if (!m_shouldMergeEnd)
        return;

    VisiblePosition startOfInsertedContent(positionAtStartOfInsertedContent());
    VisiblePosition endOfInsertedContent(positionAtEndOfInsertedContent());

    // Bail to avoid infinite recursion.
    if (m_movingParagraph) {
        ASSERT_NOT_REACHED();
        return;
    }

    // Merging two paragraphs will destroy the moved one's block styles.  Always move the end of inserted forward
    // to preserve the block style of the paragraph already in the document, unless the paragraph to move would
    // include the what was the start of the selection that was pasted into, so that we preserve that paragraph's
    // block styles.
    bool mergeForward = !(inSameParagraph(startOfInsertedContent, endOfInsertedContent) && !isStartOfParagraph(startOfInsertedContent));

    VisiblePosition destination = mergeForward ? endOfInsertedContent.next() : endOfInsertedContent;
    VisiblePosition startOfParagraphToMove = mergeForward ? startOfParagraph(endOfInsertedContent) : endOfInsertedContent.next();

    moveParagraph(startOfParagraphToMove, endOfParagraph(startOfParagraphToMove), destination);

    // Merging forward will remove m_endOfInsertedContent from the document.
    if (mergeForward) {
        if (m_startOfInsertedContent.isOrphan())
            m_startOfInsertedContent = endingSelection().visibleStart().deepEquivalent();
         m_endOfInsertedContent = endingSelection().visibleEnd().deepEquivalent();
        // If we merged text nodes, m_endOfInsertedContent could be null. If this is the case, we use m_startOfInsertedContent.
        if (m_endOfInsertedContent.isNull())
            m_endOfInsertedContent = m_startOfInsertedContent;
    }
}

static bool isInlineHTMLElementWithStyle(const Node* node)
{
    // We don't want to skip over any block elements.
    if (isBlock(node))
        return false;

    if (!node->isElementNode())
        return false;

    // We can skip over elements whose class attribute is
    // one of our internal classes.
    const Element* element = toElement(node);
    const AtomicString& classAttributeValue = element->getAttribute(HTMLNames::classAttr);
    if (classAttributeValue == AppleTabSpanClass)
        return true;
    if (classAttributeValue == AppleConvertedSpace)
        return true;
    if (classAttributeValue == ApplePasteAsQuotation)
        return true;

    return EditingStyle::elementIsStyledSpanOrHTMLEquivalent(element);
}

static inline HTMLElement* elementToSplitToAvoidPastingIntoInlineElementsWithStyle(const Position& insertionPos)
{
    Element* containingBlock = enclosingBlock(insertionPos.containerNode());
    return toHTMLElement(highestEnclosingNodeOfType(insertionPos, isInlineHTMLElementWithStyle, CannotCrossEditingBoundary, containingBlock));
}

void ReplaceSelectionCommand::doApply()
{
    VisibleSelection selection = endingSelection();
    ASSERT(selection.isCaretOrRange());
    ASSERT(selection.start().deprecatedNode());
    if (!selection.isNonOrphanedCaretOrRange() || !selection.start().deprecatedNode())
        return;

    if (!selection.rootEditableElement())
        return;

    ReplacementFragment fragment(&document(), m_documentFragment.get(), selection);
    if (performTrivialReplace(fragment))
        return;

    // We can skip matching the style if the selection is plain text.
    if ((selection.start().deprecatedNode()->renderer() && selection.start().deprecatedNode()->renderer()->style()->userModify() == READ_WRITE_PLAINTEXT_ONLY)
        && (selection.end().deprecatedNode()->renderer() && selection.end().deprecatedNode()->renderer()->style()->userModify() == READ_WRITE_PLAINTEXT_ONLY))
        m_matchStyle = false;

    if (m_matchStyle) {
        m_insertionStyle = EditingStyle::create(selection.start());
        m_insertionStyle->mergeTypingStyle(&document());
    }

    VisiblePosition visibleStart = selection.visibleStart();
    VisiblePosition visibleEnd = selection.visibleEnd();

    bool selectionEndWasEndOfParagraph = isEndOfParagraph(visibleEnd);
    bool selectionStartWasStartOfParagraph = isStartOfParagraph(visibleStart);

    Element* enclosingBlockOfVisibleStart = enclosingBlock(visibleStart.deepEquivalent().deprecatedNode());

    Position insertionPos = selection.start();
    bool startIsInsideMailBlockquote = enclosingNodeOfType(insertionPos, isMailHTMLBlockquoteElement, CanCrossEditingBoundary);
    bool selectionIsPlainText = !selection.isContentRichlyEditable();
    Element* currentRoot = selection.rootEditableElement();

    if ((selectionStartWasStartOfParagraph && selectionEndWasEndOfParagraph && !startIsInsideMailBlockquote) ||
        enclosingBlockOfVisibleStart == currentRoot || selectionIsPlainText)
        m_preventNesting = false;

    if (selection.isRange()) {
        // When the end of the selection being pasted into is at the end of a paragraph, and that selection
        // spans multiple blocks, not merging may leave an empty line.
        // When the start of the selection being pasted into is at the start of a block, not merging
        // will leave hanging block(s).
        // Merge blocks if the start of the selection was in a Mail blockquote, since we handle
        // that case specially to prevent nesting.
        bool mergeBlocksAfterDelete = startIsInsideMailBlockquote || isEndOfParagraph(visibleEnd) || isStartOfBlock(visibleStart);
        // FIXME: We should only expand to include fully selected special elements if we are copying a
        // selection and pasting it on top of itself.
        deleteSelection(false, mergeBlocksAfterDelete, false);
        visibleStart = endingSelection().visibleStart();
        if (fragment.hasInterchangeNewlineAtStart()) {
            if (isEndOfParagraph(visibleStart) && !isStartOfParagraph(visibleStart)) {
                if (!isEndOfEditableOrNonEditableContent(visibleStart))
                    setEndingSelection(visibleStart.next());
            } else
                insertParagraphSeparator();
        }
        insertionPos = endingSelection().start();
    } else {
        ASSERT(selection.isCaret());
        if (fragment.hasInterchangeNewlineAtStart()) {
            VisiblePosition next = visibleStart.next(CannotCrossEditingBoundary);
            if (isEndOfParagraph(visibleStart) && !isStartOfParagraph(visibleStart) && next.isNotNull())
                setEndingSelection(next);
            else  {
                insertParagraphSeparator();
                visibleStart = endingSelection().visibleStart();
            }
        }
        // We split the current paragraph in two to avoid nesting the blocks from the fragment inside the current block.
        // For example paste <div>foo</div><div>bar</div><div>baz</div> into <div>x^x</div>, where ^ is the caret.
        // As long as the  div styles are the same, visually you'd expect: <div>xbar</div><div>bar</div><div>bazx</div>,
        // not <div>xbar<div>bar</div><div>bazx</div></div>.
        // Don't do this if the selection started in a Mail blockquote.
        if (m_preventNesting && !startIsInsideMailBlockquote && !isEndOfParagraph(visibleStart) && !isStartOfParagraph(visibleStart)) {
            insertParagraphSeparator();
            setEndingSelection(endingSelection().visibleStart().previous());
        }
        insertionPos = endingSelection().start();
    }

    // Inserting content could cause whitespace to collapse, e.g. inserting <div>foo</div> into hello^ world.
    prepareWhitespaceAtPositionForSplit(insertionPos);

    // If the downstream node has been removed there's no point in continuing.
    if (!insertionPos.downstream().deprecatedNode())
      return;

    RefPtr<Element> enclosingBlockOfInsertionPos = enclosingBlock(insertionPos.deprecatedNode());

    // Adjust insertionPos to prevent nesting.
    // If the start was in a Mail blockquote, we will have already handled adjusting insertionPos above.
    if (m_preventNesting && enclosingBlockOfInsertionPos && !startIsInsideMailBlockquote) {
        ASSERT(enclosingBlockOfInsertionPos != currentRoot);
        VisiblePosition visibleInsertionPos(insertionPos);
        if (isEndOfBlock(visibleInsertionPos) && !(isStartOfBlock(visibleInsertionPos) && fragment.hasInterchangeNewlineAtEnd()))
            insertionPos = positionInParentAfterNode(*enclosingBlockOfInsertionPos);
        else if (isStartOfBlock(visibleInsertionPos))
            insertionPos = positionInParentBeforeNode(*enclosingBlockOfInsertionPos);
    }

    // Paste at start or end of link goes outside of link.
    insertionPos = positionAvoidingSpecialElementBoundary(insertionPos);

    // FIXME: Can this wait until after the operation has been performed?  There doesn't seem to be
    // any work performed after this that queries or uses the typing style.
    if (LocalFrame* frame = document().frame())
        frame->selection().clearTypingStyle();

    // We don't want the destination to end up inside nodes that weren't selected.  To avoid that, we move the
    // position forward without changing the visible position so we're still at the same visible location, but
    // outside of preceding tags.
    insertionPos = positionAvoidingPrecedingNodes(insertionPos);

    // Paste into run of tabs splits the tab span.
    insertionPos = positionOutsideTabSpan(insertionPos);

    // We're finished if there is nothing to add.
    if (fragment.isEmpty() || !fragment.firstChild())
        return;

    // If we are not trying to match the destination style we prefer a position
    // that is outside inline elements that provide style.
    // This way we can produce a less verbose markup.
    // We can skip this optimization for fragments not wrapped in one of
    // our style spans and for positions inside list items
    // since insertAsListItems already does the right thing.
    if (!m_matchStyle) {
        if (insertionPos.containerNode()->isTextNode() && insertionPos.offsetInContainerNode() && !insertionPos.atLastEditingPositionForNode()) {
            splitTextNode(insertionPos.containerText(), insertionPos.offsetInContainerNode());
            insertionPos = firstPositionInNode(insertionPos.containerNode());
        }

        if (RefPtr<HTMLElement> elementToSplitTo = elementToSplitToAvoidPastingIntoInlineElementsWithStyle(insertionPos)) {
            if (insertionPos.containerNode() != elementToSplitTo->parentNode()) {
                Node* splitStart = insertionPos.computeNodeAfterPosition();
                if (!splitStart)
                    splitStart = insertionPos.containerNode();
                RefPtr<Node> nodeToSplitTo = splitTreeToNode(splitStart, elementToSplitTo->parentNode()).get();
                insertionPos = positionInParentBeforeNode(*nodeToSplitTo);
            }
        }
    }

    // FIXME: When pasting rich content we're often prevented from heading down the fast path by style spans.  Try
    // again here if they've been removed.

    // 1) Insert the content.
    // 2) Remove redundant styles and style tags, this inner <b> for example: <b>foo <b>bar</b> baz</b>.
    // 3) Merge the start of the added content with the content before the position being pasted into.
    // 4) Do one of the following: a) expand the last br if the fragment ends with one and it collapsed,
    // b) merge the last paragraph of the incoming fragment with the paragraph that contained the
    // end of the selection that was pasted into, or c) handle an interchange newline at the end of the
    // incoming fragment.
    // 5) Add spaces for smart replace.
    // 6) Select the replacement if requested, and match style if requested.

    InsertedNodes insertedNodes;
    RefPtr<Node> refNode = fragment.firstChild();
    ASSERT(refNode);
    RefPtr<Node> node = refNode->nextSibling();

    fragment.removeNode(refNode);

    insertNodeAt(refNode, insertionPos);
    insertedNodes.respondToNodeInsertion(*refNode);

    // Mutation events (bug 22634) may have already removed the inserted content
    if (!refNode->inDocument())
        return;

    while (node) {
        RefPtr<Node> next = node->nextSibling();
        fragment.removeNode(node.get());
        insertNodeAfter(node, refNode);
        insertedNodes.respondToNodeInsertion(*node);

        // Mutation events (bug 22634) may have already removed the inserted content
        if (!node->inDocument())
            return;

        refNode = node;
        node = next;
    }

    removeUnrenderedTextNodesAtEnds(insertedNodes);

    // Mutation events (bug 20161) may have already removed the inserted content
    if (!insertedNodes.firstNodeInserted() || !insertedNodes.firstNodeInserted()->inDocument())
        return;

    // Scripts specified in javascript protocol may remove |enclosingBlockOfInsertionPos|
    // during insertion, e.g. <iframe src="javascript:...">
    if (enclosingBlockOfInsertionPos && !enclosingBlockOfInsertionPos->inDocument())
        enclosingBlockOfInsertionPos = nullptr;

    VisiblePosition startOfInsertedContent(firstPositionInOrBeforeNode(insertedNodes.firstNodeInserted()));

    makeInsertedContentRoundTrippableWithHTMLTreeBuilder(insertedNodes);

    removeRedundantStylesAndKeepStyleSpanInline(insertedNodes);

    // Setup m_startOfInsertedContent and m_endOfInsertedContent. This should be the last two lines of code that access insertedNodes.
    m_startOfInsertedContent = firstPositionInOrBeforeNode(insertedNodes.firstNodeInserted());
    m_endOfInsertedContent = lastPositionInOrAfterNode(insertedNodes.lastLeafInserted());

    // Determine whether or not we should merge the end of inserted content with what's after it before we do
    // the start merge so that the start merge doesn't effect our decision.
    m_shouldMergeEnd = shouldMergeEnd(selectionEndWasEndOfParagraph);

    if (shouldMergeStart(selectionStartWasStartOfParagraph, fragment.hasInterchangeNewlineAtStart(), startIsInsideMailBlockquote)) {
        VisiblePosition startOfParagraphToMove = positionAtStartOfInsertedContent();
        VisiblePosition destination = startOfParagraphToMove.previous();

        // FIXME: Maintain positions for the start and end of inserted content instead of keeping nodes.  The nodes are
        // only ever used to create positions where inserted content starts/ends.
        moveParagraph(startOfParagraphToMove, endOfParagraph(startOfParagraphToMove), destination);
        m_startOfInsertedContent = endingSelection().visibleStart().deepEquivalent().downstream();
        if (m_endOfInsertedContent.isOrphan())
            m_endOfInsertedContent = endingSelection().visibleEnd().deepEquivalent().upstream();
    }

    Position lastPositionToSelect;
    if (fragment.hasInterchangeNewlineAtEnd()) {
        VisiblePosition endOfInsertedContent = positionAtEndOfInsertedContent();
        VisiblePosition next = endOfInsertedContent.next(CannotCrossEditingBoundary);

        if (selectionEndWasEndOfParagraph || !isEndOfParagraph(endOfInsertedContent) || next.isNull()) {
            if (!isStartOfParagraph(endOfInsertedContent)) {
                setEndingSelection(endOfInsertedContent);
                // Use a default paragraph element (a plain div) for the empty paragraph, using the last paragraph
                // block's style seems to annoy users.
                insertParagraphSeparator(true, !startIsInsideMailBlockquote && highestEnclosingNodeOfType(endOfInsertedContent.deepEquivalent(),
                    isMailHTMLBlockquoteElement, CannotCrossEditingBoundary, insertedNodes.firstNodeInserted()->parentNode()));

                // Select up to the paragraph separator that was added.
                lastPositionToSelect = endingSelection().visibleStart().deepEquivalent();
                updateNodesInserted(lastPositionToSelect.deprecatedNode());
            }
        } else {
            // Select up to the beginning of the next paragraph.
            lastPositionToSelect = next.deepEquivalent().downstream();
        }
    } else {
        mergeEndIfNeeded();
    }

    if (shouldPerformSmartReplace())
        addSpacesForSmartReplace();

    completeHTMLReplacement(lastPositionToSelect);
}

bool ReplaceSelectionCommand::shouldPerformSmartReplace() const
{
    return m_smartReplace;
}

static bool isCharacterSmartReplaceExemptConsideringNonBreakingSpace(UChar32 character, bool previousCharacter)
{
    return isCharacterSmartReplaceExempt(character == noBreakSpace ? ' ' : character, previousCharacter);
}

void ReplaceSelectionCommand::addSpacesForSmartReplace()
{
    VisiblePosition startOfInsertedContent = positionAtStartOfInsertedContent();
    VisiblePosition endOfInsertedContent = positionAtEndOfInsertedContent();

    Position endUpstream = endOfInsertedContent.deepEquivalent().upstream();
    Node* endNode = endUpstream.computeNodeBeforePosition();
    int endOffset = endNode && endNode->isTextNode() ? toText(endNode)->length() : 0;
    if (endUpstream.anchorType() == Position::PositionIsOffsetInAnchor) {
        endNode = endUpstream.containerNode();
        endOffset = endUpstream.offsetInContainerNode();
    }

    bool needsTrailingSpace = !isEndOfParagraph(endOfInsertedContent) && !isCharacterSmartReplaceExemptConsideringNonBreakingSpace(endOfInsertedContent.characterAfter(), false);
    if (needsTrailingSpace && endNode) {
        bool collapseWhiteSpace = !endNode->renderer() || endNode->renderer()->style()->collapseWhiteSpace();
        if (endNode->isTextNode()) {
            insertTextIntoNode(toText(endNode), endOffset, collapseWhiteSpace ? nonBreakingSpaceString() : " ");
            if (m_endOfInsertedContent.containerNode() == endNode)
                m_endOfInsertedContent.moveToOffset(m_endOfInsertedContent.offsetInContainerNode() + 1);
        } else {
            RefPtr<Text> node = document().createEditingTextNode(collapseWhiteSpace ? nonBreakingSpaceString() : " ");
            insertNodeAfter(node, endNode);
            updateNodesInserted(node.get());
        }
    }

    document().updateLayout();

    Position startDownstream = startOfInsertedContent.deepEquivalent().downstream();
    Node* startNode = startDownstream.computeNodeAfterPosition();
    unsigned startOffset = 0;
    if (startDownstream.anchorType() == Position::PositionIsOffsetInAnchor) {
        startNode = startDownstream.containerNode();
        startOffset = startDownstream.offsetInContainerNode();
    }

    bool needsLeadingSpace = !isStartOfParagraph(startOfInsertedContent) && !isCharacterSmartReplaceExemptConsideringNonBreakingSpace(startOfInsertedContent.previous().characterAfter(), true);
    if (needsLeadingSpace && startNode) {
        bool collapseWhiteSpace = !startNode->renderer() || startNode->renderer()->style()->collapseWhiteSpace();
        if (startNode->isTextNode()) {
            insertTextIntoNode(toText(startNode), startOffset, collapseWhiteSpace ? nonBreakingSpaceString() : " ");
            if (m_endOfInsertedContent.containerNode() == startNode && m_endOfInsertedContent.offsetInContainerNode())
                m_endOfInsertedContent.moveToOffset(m_endOfInsertedContent.offsetInContainerNode() + 1);
        } else {
            RefPtr<Text> node = document().createEditingTextNode(collapseWhiteSpace ? nonBreakingSpaceString() : " ");
            // Don't updateNodesInserted. Doing so would set m_endOfInsertedContent to be the node containing the leading space,
            // but m_endOfInsertedContent is supposed to mark the end of pasted content.
            insertNodeBefore(node, startNode);
            m_startOfInsertedContent = firstPositionInNode(node.get());
        }
    }
}

void ReplaceSelectionCommand::completeHTMLReplacement(const Position &lastPositionToSelect)
{
    Position start = positionAtStartOfInsertedContent().deepEquivalent();
    Position end = positionAtEndOfInsertedContent().deepEquivalent();

    // Mutation events may have deleted start or end
    if (start.isNotNull() && !start.isOrphan() && end.isNotNull() && !end.isOrphan()) {
        // FIXME (11475): Remove this and require that the creator of the fragment to use nbsps.
        rebalanceWhitespaceAt(start);
        rebalanceWhitespaceAt(end);

        if (lastPositionToSelect.isNotNull())
            end = lastPositionToSelect;

        mergeTextNodesAroundPosition(start, end);
    } else if (lastPositionToSelect.isNotNull())
        start = end = lastPositionToSelect;
    else
        return;

    if (m_selectReplacement)
        setEndingSelection(VisibleSelection(start, end, SEL_DEFAULT_AFFINITY, endingSelection().isDirectional()));
    else
        setEndingSelection(VisibleSelection(end, SEL_DEFAULT_AFFINITY, endingSelection().isDirectional()));
}

void ReplaceSelectionCommand::mergeTextNodesAroundPosition(Position& position, Position& positionOnlyToBeUpdated)
{
    bool positionIsOffsetInAnchor = position.anchorType() == Position::PositionIsOffsetInAnchor;
    bool positionOnlyToBeUpdatedIsOffsetInAnchor = positionOnlyToBeUpdated.anchorType() == Position::PositionIsOffsetInAnchor;
    RefPtr<Text> text = nullptr;
    if (positionIsOffsetInAnchor && position.containerNode() && position.containerNode()->isTextNode())
        text = toText(position.containerNode());
    else {
        Node* before = position.computeNodeBeforePosition();
        if (before && before->isTextNode())
            text = toText(before);
        else {
            Node* after = position.computeNodeAfterPosition();
            if (after && after->isTextNode())
                text = toText(after);
        }
    }
    if (!text)
        return;

    if (text->previousSibling() && text->previousSibling()->isTextNode()) {
        RefPtr<Text> previous = toText(text->previousSibling());
        insertTextIntoNode(text, 0, previous->data());

        if (positionIsOffsetInAnchor)
            position.moveToOffset(previous->length() + position.offsetInContainerNode());
        else
            updatePositionForNodeRemoval(position, *previous);

        if (positionOnlyToBeUpdatedIsOffsetInAnchor) {
            if (positionOnlyToBeUpdated.containerNode() == text)
                positionOnlyToBeUpdated.moveToOffset(previous->length() + positionOnlyToBeUpdated.offsetInContainerNode());
            else if (positionOnlyToBeUpdated.containerNode() == previous)
                positionOnlyToBeUpdated.moveToPosition(text, positionOnlyToBeUpdated.offsetInContainerNode());
        } else {
            updatePositionForNodeRemoval(positionOnlyToBeUpdated, *previous);
        }

        removeNode(previous);
    }
    if (text->nextSibling() && text->nextSibling()->isTextNode()) {
        RefPtr<Text> next = toText(text->nextSibling());
        unsigned originalLength = text->length();
        insertTextIntoNode(text, originalLength, next->data());

        if (!positionIsOffsetInAnchor)
            updatePositionForNodeRemoval(position, *next);

        if (positionOnlyToBeUpdatedIsOffsetInAnchor && positionOnlyToBeUpdated.containerNode() == next)
            positionOnlyToBeUpdated.moveToPosition(text, originalLength + positionOnlyToBeUpdated.offsetInContainerNode());
        else
            updatePositionForNodeRemoval(positionOnlyToBeUpdated, *next);

        removeNode(next);
    }
}

EditAction ReplaceSelectionCommand::editingAction() const
{
    return m_editAction;
}

// If the user is inserting a list into an existing list, instead of nesting the list,
// we put the list items into the existing list.
Node* ReplaceSelectionCommand::insertAsListItems(PassRefPtr<HTMLElement> prpListElement, Element* insertionBlock, const Position& insertPos, InsertedNodes& insertedNodes)
{
    RefPtr<HTMLElement> listElement = prpListElement;

    bool isStart = isStartOfParagraph(VisiblePosition(insertPos));
    bool isEnd = isEndOfParagraph(VisiblePosition(insertPos));
    bool isMiddle = !isStart && !isEnd;
    Node* lastNode = insertionBlock;

    // If we're in the middle of a list item, we should split it into two separate
    // list items and insert these nodes between them.
    if (isMiddle) {
        int textNodeOffset = insertPos.offsetInContainerNode();
        if (insertPos.deprecatedNode()->isTextNode() && textNodeOffset > 0)
            splitTextNode(toText(insertPos.deprecatedNode()), textNodeOffset);
        splitTreeToNode(insertPos.deprecatedNode(), lastNode, true);
    }

    while (RefPtr<Node> listItem = listElement->firstChild()) {
        listElement->removeChild(listItem.get(), ASSERT_NO_EXCEPTION);
        if (isStart || isMiddle) {
            insertNodeBefore(listItem, lastNode);
            insertedNodes.respondToNodeInsertion(*listItem);
        } else if (isEnd) {
            insertNodeAfter(listItem, lastNode);
            insertedNodes.respondToNodeInsertion(*listItem);
            lastNode = listItem.get();
        } else
            ASSERT_NOT_REACHED();
    }
    if (isStart || isMiddle) {
        if (Node* node = lastNode->previousSibling())
            return node;
    }
    return lastNode;
}

void ReplaceSelectionCommand::updateNodesInserted(Node *node)
{
    if (!node)
        return;

    if (m_startOfInsertedContent.isNull())
        m_startOfInsertedContent = firstPositionInOrBeforeNode(node);

    m_endOfInsertedContent = lastPositionInOrAfterNode(&NodeTraversal::lastWithinOrSelf(*node));
}

// During simple pastes, where we're just pasting a text node into a run of text, we insert the text node
// directly into the text node that holds the selection.  This is much faster than the generalized code in
// ReplaceSelectionCommand, and works around <https://bugs.webkit.org/show_bug.cgi?id=6148> since we don't
// split text nodes.
bool ReplaceSelectionCommand::performTrivialReplace(const ReplacementFragment& fragment)
{
    if (!fragment.firstChild() || fragment.firstChild() != fragment.lastChild() || !fragment.firstChild()->isTextNode())
        return false;

    // FIXME: Would be nice to handle smart replace in the fast path.
    if (m_smartReplace || fragment.hasInterchangeNewlineAtStart() || fragment.hasInterchangeNewlineAtEnd())
        return false;

    // e.g. when "bar" is inserted after "foo" in <div><u>foo</u></div>, "bar" should not be underlined.
    if (elementToSplitToAvoidPastingIntoInlineElementsWithStyle(endingSelection().start()))
        return false;

    RefPtr<Node> nodeAfterInsertionPos = endingSelection().end().downstream().anchorNode();
    Text* textNode = toText(fragment.firstChild());
    // Our fragment creation code handles tabs, spaces, and newlines, so we don't have to worry about those here.

    Position start = endingSelection().start();
    Position end = replaceSelectedTextInNode(textNode->data());
    if (end.isNull())
        return false;

    VisibleSelection selectionAfterReplace(m_selectReplacement ? start : end, end);

    setEndingSelection(selectionAfterReplace);

    return true;
}

} // namespace blink
