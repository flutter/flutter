/*
 * Copyright (C) 2004, 2005, 2006, 2007 Apple Inc. All rights reserved.
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
#include "core/editing/htmlediting.h"

#include "bindings/core/v8/ExceptionState.h"
#include "bindings/core/v8/ExceptionStatePlaceholder.h"
#include "core/HTMLElementFactory.h"
#include "core/dom/Document.h"
#include "core/dom/ElementTraversal.h"
#include "core/dom/NodeTraversal.h"
#include "core/dom/PositionIterator.h"
#include "core/dom/Range.h"
#include "core/dom/Text.h"
#include "core/dom/shadow/ShadowRoot.h"
#include "core/editing/Editor.h"
#include "core/editing/HTMLInterchange.h"
#include "core/editing/PlainTextRange.h"
#include "core/editing/TextIterator.h"
#include "core/editing/VisiblePosition.h"
#include "core/editing/VisibleSelection.h"
#include "core/editing/VisibleUnits.h"
#include "core/frame/LocalFrame.h"
#include "core/frame/UseCounter.h"
#include "core/rendering/RenderObject.h"
#include "wtf/Assertions.h"
#include "wtf/StdLibExtras.h"
#include "wtf/text/StringBuilder.h"

namespace blink {

// Atomic means that the node has no children, or has children which are ignored for the
// purposes of editing.
bool isAtomicNode(const Node *node)
{
    return node && (!node->hasChildren() || editingIgnoresContent(node));
}

// Compare two positions, taking into account the possibility that one or both
// could be inside a shadow tree. Only works for non-null values.
int comparePositions(const Position& a, const Position& b)
{
    ASSERT(a.isNotNull());
    ASSERT(b.isNotNull());
    TreeScope* commonScope = commonTreeScope(a.containerNode(), b.containerNode());

    ASSERT(commonScope);
    if (!commonScope)
        return 0;

    Node* nodeA = commonScope->ancestorInThisScope(a.containerNode());
    ASSERT(nodeA);
    bool hasDescendentA = nodeA != a.containerNode();
    int offsetA = hasDescendentA ? 0 : a.computeOffsetInContainerNode();

    Node* nodeB = commonScope->ancestorInThisScope(b.containerNode());
    ASSERT(nodeB);
    bool hasDescendentB = nodeB != b.containerNode();
    int offsetB = hasDescendentB ? 0 : b.computeOffsetInContainerNode();

    int bias = 0;
    if (nodeA == nodeB) {
        if (hasDescendentA)
            bias = -1;
        else if (hasDescendentB)
            bias = 1;
    }

    int result = Range::compareBoundaryPoints(nodeA, offsetA, nodeB, offsetB, IGNORE_EXCEPTION);
    return result ? result : bias;
}

int comparePositions(const PositionWithAffinity& a, const PositionWithAffinity& b)
{
    return comparePositions(a.position(), b.position());
}

int comparePositions(const VisiblePosition& a, const VisiblePosition& b)
{
    return comparePositions(a.deepEquivalent(), b.deepEquivalent());
}

ContainerNode* highestEditableRoot(const Position& position, EditableType editableType)
{
    if (position.isNull())
        return 0;

    ContainerNode* highestRoot = editableRootForPosition(position, editableType);
    if (!highestRoot)
        return 0;

    ContainerNode* node = highestRoot->parentNode();
    while (node) {
        if (node->hasEditableStyle(editableType))
            highestRoot = node;
        node = node->parentNode();
    }

    return highestRoot;
}

Element* lowestEditableAncestor(Node* node)
{
    while (node) {
        if (node->hasEditableStyle())
            return node->rootEditableElement();
        node = node->parentNode();
    }

    return 0;
}

bool isEditablePosition(const Position& p, EditableType editableType, EUpdateStyle updateStyle)
{
    Node* node = p.parentAnchoredEquivalent().anchorNode();
    if (!node)
        return false;
    if (updateStyle == UpdateStyle)
        node->document().updateLayoutIgnorePendingStylesheets();
    else
        ASSERT(updateStyle == DoNotUpdateStyle);

    return node->hasEditableStyle(editableType);
}

bool isAtUnsplittableElement(const Position& pos)
{
    Node* node = pos.deprecatedNode();
    return node == editableRootForPosition(pos);
}


bool isRichlyEditablePosition(const Position& p, EditableType editableType)
{
    Node* node = p.deprecatedNode();
    if (!node)
        return false;

    return node->rendererIsRichlyEditable(editableType);
}

Element* editableRootForPosition(const Position& p, EditableType editableType)
{
    Node* node = p.containerNode();
    if (!node)
        return 0;

    return node->rootEditableElement(editableType);
}

// Finds the enclosing element until which the tree can be split.
// When a user hits ENTER, he/she won't expect this element to be split into two.
// You may pass it as the second argument of splitTreeToNode.
Element* unsplittableElementForPosition(const Position& p)
{
    return editableRootForPosition(p);
}

Position nextCandidate(const Position& position)
{
    PositionIterator p = position;
    while (!p.atEnd()) {
        p.increment();
        if (p.isCandidate())
            return p;
    }
    return Position();
}

Position nextVisuallyDistinctCandidate(const Position& position)
{
    Position p = position;
    Position downstreamStart = p.downstream();
    while (!p.atEndOfTree()) {
        p = p.next(Character);
        if (p.isCandidate() && p.downstream() != downstreamStart)
            return p;
    }
    return Position();
}

Position previousCandidate(const Position& position)
{
    PositionIterator p = position;
    while (!p.atStart()) {
        p.decrement();
        if (p.isCandidate())
            return p;
    }
    return Position();
}

Position previousVisuallyDistinctCandidate(const Position& position)
{
    Position p = position;
    Position downstreamStart = p.downstream();
    while (!p.atStartOfTree()) {
        p = p.previous(Character);
        if (p.isCandidate() && p.downstream() != downstreamStart)
            return p;
    }
    return Position();
}

VisiblePosition firstEditableVisiblePositionAfterPositionInRoot(const Position& position, ContainerNode* highestRoot)
{
    // position falls before highestRoot.
    if (comparePositions(position, firstPositionInNode(highestRoot)) == -1 && highestRoot->hasEditableStyle())
        return VisiblePosition(firstPositionInNode(highestRoot));

    Position editablePosition = position;

    if (position.deprecatedNode()->treeScope() != highestRoot->treeScope()) {
        Node* shadowAncestor = highestRoot->treeScope().ancestorInThisScope(editablePosition.deprecatedNode());
        if (!shadowAncestor)
            return VisiblePosition();

        editablePosition = positionAfterNode(shadowAncestor);
    }

    while (editablePosition.deprecatedNode() && !isEditablePosition(editablePosition) && editablePosition.deprecatedNode()->isDescendantOf(highestRoot))
        editablePosition = isAtomicNode(editablePosition.deprecatedNode()) ? positionInParentAfterNode(*editablePosition.deprecatedNode()) : nextVisuallyDistinctCandidate(editablePosition);

    if (editablePosition.deprecatedNode() && editablePosition.deprecatedNode() != highestRoot && !editablePosition.deprecatedNode()->isDescendantOf(highestRoot))
        return VisiblePosition();

    return VisiblePosition(editablePosition);
}

VisiblePosition lastEditableVisiblePositionBeforePositionInRoot(const Position& position, ContainerNode* highestRoot)
{
    return VisiblePosition(lastEditablePositionBeforePositionInRoot(position, highestRoot));
}

Position lastEditablePositionBeforePositionInRoot(const Position& position, Node* highestRoot)
{
    // When position falls after highestRoot, the result is easy to compute.
    if (comparePositions(position, lastPositionInNode(highestRoot)) == 1)
        return lastPositionInNode(highestRoot);

    Position editablePosition = position;

    if (position.deprecatedNode()->treeScope() != highestRoot->treeScope()) {
        Node* shadowAncestor = highestRoot->treeScope().ancestorInThisScope(editablePosition.deprecatedNode());
        if (!shadowAncestor)
            return Position();

        editablePosition = firstPositionInOrBeforeNode(shadowAncestor);
    }

    while (editablePosition.deprecatedNode() && !isEditablePosition(editablePosition) && editablePosition.deprecatedNode()->isDescendantOf(highestRoot))
        editablePosition = isAtomicNode(editablePosition.deprecatedNode()) ? positionInParentBeforeNode(*editablePosition.deprecatedNode()) : previousVisuallyDistinctCandidate(editablePosition);

    if (editablePosition.deprecatedNode() && editablePosition.deprecatedNode() != highestRoot && !editablePosition.deprecatedNode()->isDescendantOf(highestRoot))
        return Position();
    return editablePosition;
}

// FIXME: The method name, comment, and code say three different things here!
// Whether or not content before and after this node will collapse onto the same line as it.
bool isBlock(const Node* node)
{
    return node && node->renderer() && !node->renderer()->isInline();
}

bool isInline(const Node* node)
{
    return node && node->renderer() && node->renderer()->isInline();
}

// FIXME: Deploy this in all of the places where enclosingBlockFlow/enclosingBlockFlowOrTableElement are used.
// FIXME: Pass a position to this function. The enclosing block of [table, x] for example, should be the
// block that contains the table and not the table, and this function should be the only one responsible for
// knowing about these kinds of special cases.
Element* enclosingBlock(Node* node, EditingBoundaryCrossingRule rule)
{
    Node* enclosingNode = enclosingNodeOfType(firstPositionInOrBeforeNode(node), isBlock, rule);
    return enclosingNode && enclosingNode->isElementNode() ? toElement(enclosingNode) : 0;
}

Element* enclosingBlockFlowElement(Node& node)
{
    if (isBlockFlowElement(node))
        return &toElement(node);

    for (Node* n = node.parentNode(); n; n = n->parentNode()) {
        if (isBlockFlowElement(*n))
            return toElement(n);
    }
    return 0;
}

bool inSameContainingBlockFlowElement(Node* a, Node* b)
{
    return a && b && enclosingBlockFlowElement(*a) == enclosingBlockFlowElement(*b);
}

TextDirection directionOfEnclosingBlock(const Position& position)
{
    Element* enclosingBlockElement = enclosingBlock(position.containerNode());
    if (!enclosingBlockElement)
        return LTR;
    RenderObject* renderer = enclosingBlockElement->renderer();
    return renderer ? renderer->style()->direction() : LTR;
}

// This method is used to create positions in the DOM. It returns the maximum valid offset
// in a node. It returns 1 for some elements even though they do not have children, which
// creates technically invalid DOM Positions. Be sure to call parentAnchoredEquivalent
// on a Position before using it to create a DOM Range, or an exception will be thrown.
int lastOffsetForEditing(const Node* node)
{
    ASSERT(node);
    if (!node)
        return 0;
    if (node->offsetInCharacters())
        return node->maxCharacterOffset();

    if (node->hasChildren())
        return node->countChildren();

    // NOTE: This should preempt the childNodeCount for, e.g., select nodes
    if (editingIgnoresContent(node))
        return 1;

    return 0;
}

String stringWithRebalancedWhitespace(const String& string, bool startIsStartOfParagraph, bool endIsEndOfParagraph)
{
    unsigned length = string.length();

    StringBuilder rebalancedString;
    rebalancedString.reserveCapacity(length);

    bool previousCharacterWasSpace = false;
    for (size_t i = 0; i < length; i++) {
        UChar c = string[i];
        if (!isWhitespace(c)) {
            rebalancedString.append(c);
            previousCharacterWasSpace = false;
            continue;
        }

        if (previousCharacterWasSpace || (!i && startIsStartOfParagraph) || (i + 1 == length && endIsEndOfParagraph)) {
            rebalancedString.append(noBreakSpace);
            previousCharacterWasSpace = false;
        } else {
            rebalancedString.append(' ');
            previousCharacterWasSpace = true;
        }
    }

    ASSERT(rebalancedString.length() == length);

    return rebalancedString.toString();
}

const String& nonBreakingSpaceString()
{
    DEFINE_STATIC_LOCAL(String, nonBreakingSpaceString, (&noBreakSpace, 1));
    return nonBreakingSpaceString;
}

// FIXME: need to dump this
bool isSpecialHTMLElement(const Node* n)
{
    if (!n)
        return false;

    if (!n->isHTMLElement())
        return false;

    if (n->isLink())
        return true;

    RenderObject* renderer = n->renderer();
    if (!renderer)
        return false;

    if (renderer->style()->isFloating())
        return true;

    return false;
}

static HTMLElement* firstInSpecialElement(const Position& pos)
{
    Element* rootEditableElement = pos.containerNode()->rootEditableElement();
    for (Node* n = pos.deprecatedNode(); n && n->rootEditableElement() == rootEditableElement; n = n->parentNode()) {
        if (isSpecialHTMLElement(n)) {
            HTMLElement* specialElement = toHTMLElement(n);
            VisiblePosition vPos = VisiblePosition(pos, DOWNSTREAM);
            VisiblePosition firstInElement = VisiblePosition(firstPositionInOrBeforeNode(specialElement), DOWNSTREAM);
            if (isRenderedTableElement(specialElement) && vPos == firstInElement.next())
                return specialElement;
            if (vPos == firstInElement)
                return specialElement;
        }
    }
    return 0;
}

static HTMLElement* lastInSpecialElement(const Position& pos)
{
    Element* rootEditableElement = pos.containerNode()->rootEditableElement();
    for (Node* n = pos.deprecatedNode(); n && n->rootEditableElement() == rootEditableElement; n = n->parentNode()) {
        if (isSpecialHTMLElement(n)) {
            HTMLElement* specialElement = toHTMLElement(n);
            VisiblePosition vPos = VisiblePosition(pos, DOWNSTREAM);
            VisiblePosition lastInElement = VisiblePosition(lastPositionInOrAfterNode(specialElement), DOWNSTREAM);
            if (isRenderedTableElement(specialElement) && vPos == lastInElement.previous())
                return specialElement;
            if (vPos == lastInElement)
                return specialElement;
        }
    }
    return 0;
}

Position positionBeforeContainingSpecialElement(const Position& pos, HTMLElement** containingSpecialElement)
{
    HTMLElement* n = firstInSpecialElement(pos);
    if (!n)
        return pos;
    Position result = positionInParentBeforeNode(*n);
    if (result.isNull() || result.deprecatedNode()->rootEditableElement() != pos.deprecatedNode()->rootEditableElement())
        return pos;
    if (containingSpecialElement)
        *containingSpecialElement = n;
    return result;
}

Position positionAfterContainingSpecialElement(const Position& pos, HTMLElement** containingSpecialElement)
{
    HTMLElement* n = lastInSpecialElement(pos);
    if (!n)
        return pos;
    Position result = positionInParentAfterNode(*n);
    if (result.isNull() || result.deprecatedNode()->rootEditableElement() != pos.deprecatedNode()->rootEditableElement())
        return pos;
    if (containingSpecialElement)
        *containingSpecialElement = n;
    return result;
}

Element* isFirstPositionAfterTable(const VisiblePosition& visiblePosition)
{
    Position upstream(visiblePosition.deepEquivalent().upstream());
    if (isRenderedTableElement(upstream.deprecatedNode()) && upstream.atLastEditingPositionForNode())
        return toElement(upstream.deprecatedNode());

    return 0;
}

Element* isLastPositionBeforeTable(const VisiblePosition& visiblePosition)
{
    Position downstream(visiblePosition.deepEquivalent().downstream());
    if (isRenderedTableElement(downstream.deprecatedNode()) && downstream.atFirstEditingPositionForNode())
        return toElement(downstream.deprecatedNode());

    return 0;
}

// Returns the visible position at the beginning of a node
VisiblePosition visiblePositionBeforeNode(Node& node)
{
    if (node.hasChildren())
        return VisiblePosition(firstPositionInOrBeforeNode(&node), DOWNSTREAM);
    ASSERT(node.parentNode());
    ASSERT(!node.parentNode()->isShadowRoot());
    return VisiblePosition(positionInParentBeforeNode(node));
}

// Returns the visible position at the ending of a node
VisiblePosition visiblePositionAfterNode(Node& node)
{
    if (node.hasChildren())
        return VisiblePosition(lastPositionInOrAfterNode(&node), DOWNSTREAM);
    ASSERT(node.parentNode());
    ASSERT(!node.parentNode()->isShadowRoot());
    return VisiblePosition(positionInParentAfterNode(node));
}

// Create a range object with two visible positions, start and end.
// create(Document*, const Position&, const Position&); will use deprecatedEditingOffset
// Use this function instead of create a regular range object (avoiding editing offset).
PassRefPtr<Range> createRange(Document& document, const VisiblePosition& start, const VisiblePosition& end, ExceptionState& exceptionState)
{
    RefPtr<Range> selectedRange = Range::create(document);
    selectedRange->setStart(start.deepEquivalent().containerNode(), start.deepEquivalent().computeOffsetInContainerNode(), exceptionState);
    if (!exceptionState.hadException())
        selectedRange->setEnd(end.deepEquivalent().containerNode(), end.deepEquivalent().computeOffsetInContainerNode(), exceptionState);
    return selectedRange.release();
}

Element* enclosingElementWithTag(const Position& p, const QualifiedName& tagName)
{
    if (p.isNull())
        return 0;

    ContainerNode* root = highestEditableRoot(p);
    Element* ancestor = p.deprecatedNode()->isElementNode() ? toElement(p.deprecatedNode()) : p.deprecatedNode()->parentElement();
    for (; ancestor; ancestor = ancestor->parentElement()) {
        if (root && !ancestor->hasEditableStyle())
            continue;
        if (ancestor->hasTagName(tagName))
            return ancestor;
        if (ancestor == root)
            return 0;
    }

    return 0;
}

Node* enclosingNodeOfType(const Position& p, bool (*nodeIsOfType)(const Node*), EditingBoundaryCrossingRule rule)
{
    // FIXME: support CanSkipCrossEditingBoundary
    ASSERT(rule == CanCrossEditingBoundary || rule == CannotCrossEditingBoundary);
    if (p.isNull())
        return 0;

    ContainerNode* root = rule == CannotCrossEditingBoundary ? highestEditableRoot(p) : 0;
    for (Node* n = p.deprecatedNode(); n; n = n->parentNode()) {
        // Don't return a non-editable node if the input position was editable, since
        // the callers from editing will no doubt want to perform editing inside the returned node.
        if (root && !n->hasEditableStyle())
            continue;
        if (nodeIsOfType(n))
            return n;
        if (n == root)
            return 0;
    }

    return 0;
}

Node* highestEnclosingNodeOfType(const Position& p, bool (*nodeIsOfType)(const Node*), EditingBoundaryCrossingRule rule, Node* stayWithin)
{
    Node* highest = 0;
    ContainerNode* root = rule == CannotCrossEditingBoundary ? highestEditableRoot(p) : 0;
    for (Node* n = p.containerNode(); n && n != stayWithin; n = n->parentNode()) {
        if (root && !n->hasEditableStyle())
            continue;
        if (nodeIsOfType(n))
            highest = n;
        if (n == root)
            break;
    }

    return highest;
}

static bool hasARenderedDescendant(Node* node, Node* excludedNode)
{
    for (Node* n = node->firstChild(); n;) {
        if (n == excludedNode) {
            n = NodeTraversal::nextSkippingChildren(*n, node);
            continue;
        }
        if (n->renderer())
            return true;
        n = NodeTraversal::next(*n, node);
    }
    return false;
}

Node* highestNodeToRemoveInPruning(Node* node, Node* excludeNode)
{
    Node* previousNode = 0;
    Element* rootEditableElement = node ? node->rootEditableElement() : 0;
    for (; node; node = node->parentNode()) {
        if (RenderObject* renderer = node->renderer()) {
            if (!renderer->canHaveChildren() || hasARenderedDescendant(node, previousNode) || rootEditableElement == node || excludeNode == node)
                return previousNode;
        }
        previousNode = node;
    }
    return 0;
}

Element* enclosingAnchorElement(const Position& p)
{
    if (p.isNull())
        return 0;

    for (Element* ancestor = ElementTraversal::firstAncestorOrSelf(*p.deprecatedNode()); ancestor; ancestor = ElementTraversal::firstAncestor(*ancestor)) {
        if (ancestor->isLink())
            return ancestor;
    }
    return 0;
}

bool canMergeLists(Element* firstList, Element* secondList)
{
    if (!firstList || !secondList || !firstList->isHTMLElement() || !secondList->isHTMLElement())
        return false;

    return firstList->hasTagName(secondList->tagQName()) // make sure the list types match (ol vs. ul)
    && firstList->hasEditableStyle() && secondList->hasEditableStyle() // both lists are editable
    && firstList->rootEditableElement() == secondList->rootEditableElement() // don't cross editing boundaries
    && isVisiblyAdjacent(positionInParentAfterNode(*firstList), positionInParentBeforeNode(*secondList));
    // Make sure there is no visible content between this li and the previous list
}

bool isRenderedTableElement(const Node* node)
{
    return false;
}

bool isEmptyTableCell(const Node* node)
{
    return false;
}

PassRefPtr<HTMLElement> createDefaultParagraphElement(Document& document)
{
    return nullptr;
}

PassRefPtr<HTMLElement> createHTMLElement(Document& document, const QualifiedName& name)
{
    return createHTMLElement(document, name.localName());
}

PassRefPtr<HTMLElement> createHTMLElement(Document& document, const AtomicString& tagName)
{
    return HTMLElementFactory::createHTMLElement(tagName, document, false);
}

bool isNodeRendered(const Node *node)
{
    return node && node->renderer();
}

// return first preceding DOM position rendered at a different location, or "this"
static Position previousCharacterPosition(const Position& position, EAffinity affinity)
{
    if (position.isNull())
        return Position();

    Element* fromRootEditableElement = position.anchorNode()->rootEditableElement();

    bool atStartOfLine = isStartOfLine(VisiblePosition(position, affinity));
    bool rendered = position.isCandidate();

    Position currentPos = position;
    while (!currentPos.atStartOfTree()) {
        currentPos = currentPos.previous();

        if (currentPos.anchorNode()->rootEditableElement() != fromRootEditableElement)
            return position;

        if (atStartOfLine || !rendered) {
            if (currentPos.isCandidate())
                return currentPos;
        } else if (position.rendersInDifferentPosition(currentPos)) {
            return currentPos;
        }
    }

    return position;
}

// This assumes that it starts in editable content.
Position leadingWhitespacePosition(const Position& position, EAffinity affinity, WhitespacePositionOption option)
{
    ASSERT(isEditablePosition(position, ContentIsEditable, DoNotUpdateStyle));
    if (position.isNull())
        return Position();

    Position prev = previousCharacterPosition(position, affinity);
    if (prev != position && inSameContainingBlockFlowElement(prev.anchorNode(), position.anchorNode()) && prev.anchorNode()->isTextNode()) {
        String string = toText(prev.anchorNode())->data();
        UChar previousCharacter = string[prev.deprecatedEditingOffset()];
        bool isSpace = option == ConsiderNonCollapsibleWhitespace ? (isSpaceOrNewline(previousCharacter) || previousCharacter == noBreakSpace) : isCollapsibleWhitespace(previousCharacter);
        if (isSpace && isEditablePosition(prev))
            return prev;
    }

    return Position();
}

// This assumes that it starts in editable content.
Position trailingWhitespacePosition(const Position& position, EAffinity, WhitespacePositionOption option)
{
    ASSERT(isEditablePosition(position, ContentIsEditable, DoNotUpdateStyle));
    if (position.isNull())
        return Position();

    VisiblePosition visiblePosition(position);
    UChar characterAfterVisiblePosition = visiblePosition.characterAfter();
    bool isSpace = option == ConsiderNonCollapsibleWhitespace ? (isSpaceOrNewline(characterAfterVisiblePosition) || characterAfterVisiblePosition == noBreakSpace) : isCollapsibleWhitespace(characterAfterVisiblePosition);
    // The space must not be in another paragraph and it must be editable.
    if (isSpace && !isEndOfParagraph(visiblePosition) && visiblePosition.next(CannotCrossEditingBoundary).isNotNull())
        return position;
    return Position();
}

unsigned numEnclosingMailBlockquotes(const Position& p)
{
    return 0;
}

void updatePositionForNodeRemoval(Position& position, Node& node)
{
    if (position.isNull())
        return;
    switch (position.anchorType()) {
    case Position::PositionIsBeforeChildren:
        if (position.containerNode() == node)
            position = positionInParentBeforeNode(node);
        break;
    case Position::PositionIsAfterChildren:
        if (position.containerNode() == node)
            position = positionInParentAfterNode(node);
        break;
    case Position::PositionIsOffsetInAnchor:
        if (position.containerNode() == node.parentNode() && static_cast<unsigned>(position.offsetInContainerNode()) > node.nodeIndex())
            position.moveToOffset(position.offsetInContainerNode() - 1);
        else if (node.containsIncludingShadowDOM(position.containerNode()))
            position = positionInParentBeforeNode(node);
        break;
    case Position::PositionIsAfterAnchor:
        if (node.containsIncludingShadowDOM(position.anchorNode()))
            position = positionInParentAfterNode(node);
        break;
    case Position::PositionIsBeforeAnchor:
        if (node.containsIncludingShadowDOM(position.anchorNode()))
            position = positionInParentBeforeNode(node);
        break;
    }
}

bool isMailHTMLBlockquoteElement(const Node* node)
{
    return false;
}

int caretMinOffset(const Node* n)
{
    RenderObject* r = n->renderer();
    ASSERT(!n->isCharacterDataNode() || !r || r->isText()); // FIXME: This was a runtime check that seemingly couldn't fail; changed it to an assertion for now.
    return r ? r->caretMinOffset() : 0;
}

// If a node can contain candidates for VisiblePositions, return the offset of the last candidate, otherwise
// return the number of children for container nodes and the length for unrendered text nodes.
int caretMaxOffset(const Node* n)
{
    // For rendered text nodes, return the last position that a caret could occupy.
    if (n->isTextNode() && n->renderer())
        return n->renderer()->caretMaxOffset();
    // For containers return the number of children. For others do the same as above.
    return lastOffsetForEditing(n);
}

bool lineBreakExistsAtVisiblePosition(const VisiblePosition& visiblePosition)
{
    return lineBreakExistsAtPosition(visiblePosition.deepEquivalent().downstream());
}

bool lineBreakExistsAtPosition(const Position& position)
{
    if (position.isNull())
        return false;

    if (!position.anchorNode()->renderer())
        return false;

    if (!position.anchorNode()->isTextNode() || !position.anchorNode()->renderer()->style()->preserveNewline())
        return false;

    Text* textNode = toText(position.anchorNode());
    unsigned offset = position.offsetInContainerNode();
    return offset < textNode->length() && textNode->data()[offset] == '\n';
}

// Modifies selections that have an end point at the edge of a table
// that contains the other endpoint so that they don't confuse
// code that iterates over selected paragraphs.
VisibleSelection selectionForParagraphIteration(const VisibleSelection& original)
{
    VisibleSelection newSelection(original);
    VisiblePosition startOfSelection(newSelection.visibleStart());
    VisiblePosition endOfSelection(newSelection.visibleEnd());

    // If the end of the selection to modify is just after a table, and
    // if the start of the selection is inside that table, then the last paragraph
    // that we'll want modify is the last one inside the table, not the table itself
    // (a table is itself a paragraph).
    if (Element* table = isFirstPositionAfterTable(endOfSelection))
        if (startOfSelection.deepEquivalent().deprecatedNode()->isDescendantOf(table))
            newSelection = VisibleSelection(startOfSelection, endOfSelection.previous(CannotCrossEditingBoundary));

    // If the start of the selection to modify is just before a table,
    // and if the end of the selection is inside that table, then the first paragraph
    // we'll want to modify is the first one inside the table, not the paragraph
    // containing the table itself.
    if (Element* table = isLastPositionBeforeTable(startOfSelection))
        if (endOfSelection.deepEquivalent().deprecatedNode()->isDescendantOf(table))
            newSelection = VisibleSelection(startOfSelection.next(CannotCrossEditingBoundary), endOfSelection);

    return newSelection;
}

// FIXME: indexForVisiblePosition and visiblePositionForIndex use TextIterators to convert between
// VisiblePositions and indices. But TextIterator iteration using TextIteratorEmitsCharactersBetweenAllVisiblePositions
// does not exactly match VisiblePosition iteration, so using them to preserve a selection during an editing
// opertion is unreliable. TextIterator's TextIteratorEmitsCharactersBetweenAllVisiblePositions mode needs to be fixed,
// or these functions need to be changed to iterate using actual VisiblePositions.
// FIXME: Deploy these functions everywhere that TextIterators are used to convert between VisiblePositions and indices.
int indexForVisiblePosition(const VisiblePosition& visiblePosition, RefPtr<ContainerNode>& scope)
{
    if (visiblePosition.isNull())
        return 0;

    Position p(visiblePosition.deepEquivalent());
    Document& document = *p.document();
    ShadowRoot* shadowRoot = p.anchorNode()->containingShadowRoot();

    if (shadowRoot)
        scope = shadowRoot;
    else
        scope = document.documentElement();

    RefPtr<Range> range = Range::create(document, firstPositionInNode(scope.get()), p.parentAnchoredEquivalent());

    return TextIterator::rangeLength(range.get(), true);
}

VisiblePosition visiblePositionForIndex(int index, ContainerNode* scope)
{
    if (!scope)
        return VisiblePosition();
    RefPtr<Range> range = PlainTextRange(index).createRangeForSelection(*scope);
    // Check for an invalid index. Certain editing operations invalidate indices because
    // of problems with TextIteratorEmitsCharactersBetweenAllVisiblePositions.
    if (!range)
        return VisiblePosition();
    return VisiblePosition(range->startPosition());
}

// Determines whether two positions are visibly next to each other (first then second)
// while ignoring whitespaces and unrendered nodes
bool isVisiblyAdjacent(const Position& first, const Position& second)
{
    return VisiblePosition(first) == VisiblePosition(second.upstream());
}

// Determines whether a node is inside a range or visibly starts and ends at the boundaries of the range.
// Call this function to determine whether a node is visibly fit inside selectedRange
bool isNodeVisiblyContainedWithin(Node& node, const Range& selectedRange)
{
    // If the node is inside the range, then it surely is contained within
    if (selectedRange.compareNode(&node, IGNORE_EXCEPTION) == Range::NODE_INSIDE)
        return true;

    bool startIsVisuallySame = visiblePositionBeforeNode(node) == VisiblePosition(selectedRange.startPosition());
    if (startIsVisuallySame && comparePositions(positionInParentAfterNode(node), selectedRange.endPosition()) < 0)
        return true;

    bool endIsVisuallySame = visiblePositionAfterNode(node) == VisiblePosition(selectedRange.endPosition());
    if (endIsVisuallySame && comparePositions(selectedRange.startPosition(), positionInParentBeforeNode(node)) < 0)
        return true;

    return startIsVisuallySame && endIsVisuallySame;
}

bool isRenderedAsNonInlineTableImageOrHR(const Node* node)
{
    return false;
}

bool areIdenticalElements(const Node* first, const Node* second)
{
    if (!first->isElementNode() || !second->isElementNode())
        return false;

    const Element* firstElement = toElement(first);
    const Element* secondElement = toElement(second);
    if (!firstElement->hasTagName(secondElement->tagQName()))
        return false;

    return firstElement->hasEquivalentAttributes(secondElement);
}

bool isBlockFlowElement(const Node& node)
{
    RenderObject* renderer = node.renderer();
    return node.isElementNode() && renderer && renderer->isRenderBlockFlow();
}

Position adjustedSelectionStartForStyleComputation(const VisibleSelection& selection)
{
    // This function is used by range style computations to avoid bugs like:
    // <rdar://problem/4017641> REGRESSION (Mail): you can only bold/unbold a selection starting from end of line once
    // It is important to skip certain irrelevant content at the start of the selection, so we do not wind up
    // with a spurious "mixed" style.

    VisiblePosition visiblePosition(selection.start());
    if (visiblePosition.isNull())
        return Position();

    // if the selection is a caret, just return the position, since the style
    // behind us is relevant
    if (selection.isCaret())
        return visiblePosition.deepEquivalent();

    // if the selection starts just before a paragraph break, skip over it
    if (isEndOfParagraph(visiblePosition))
        return visiblePosition.next().deepEquivalent().downstream();

    // otherwise, make sure to be at the start of the first selected node,
    // instead of possibly at the end of the last node before the selection
    return visiblePosition.deepEquivalent().downstream();
}

} // namespace blink
