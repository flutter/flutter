/*
 * (C) 1999 Lars Knoll (knoll@kde.org)
 * (C) 2000 Gunnstein Lye (gunnstein@netcom.no)
 * (C) 2000 Frederik Holljen (frederik.holljen@hig.no)
 * (C) 2001 Peter Kelly (pmk@post.com)
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011 Apple Inc. All rights reserved.
 * Copyright (C) 2011 Motorola Mobility. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */

#include "sky/engine/config.h"
#include "sky/engine/core/dom/Range.h"

#include "sky/engine/bindings/core/v8/ExceptionState.h"
#include "sky/engine/core/dom/ClientRect.h"
#include "sky/engine/core/dom/ClientRectList.h"
#include "sky/engine/core/dom/DocumentFragment.h"
#include "sky/engine/core/dom/ExceptionCode.h"
#include "sky/engine/core/dom/Node.h"
#include "sky/engine/core/dom/NodeTraversal.h"
#include "sky/engine/core/dom/NodeWithIndex.h"
#include "sky/engine/core/dom/Text.h"
#include "sky/engine/core/editing/markup.h"
#include "sky/engine/core/editing/TextIterator.h"
#include "sky/engine/core/editing/VisiblePosition.h"
#include "sky/engine/core/editing/VisibleUnits.h"
#include "sky/engine/core/events/ScopedEventQueue.h"
#include "sky/engine/core/html/HTMLElement.h"
#include "sky/engine/core/rendering/RenderBoxModelObject.h"
#include "sky/engine/core/rendering/RenderText.h"
#include "sky/engine/platform/geometry/FloatQuad.h"
#include "sky/engine/wtf/RefCountedLeakCounter.h"
#include "sky/engine/wtf/text/CString.h"
#include "sky/engine/wtf/text/StringBuilder.h"
#ifndef NDEBUG
#include <stdio.h>
#endif

namespace blink {

DEFINE_DEBUG_ONLY_GLOBAL(WTF::RefCountedLeakCounter, rangeCounter, ("Range"));

inline Range::Range(Document& ownerDocument)
    : m_ownerDocument(&ownerDocument)
    , m_start(m_ownerDocument)
    , m_end(m_ownerDocument)
{
#ifndef NDEBUG
    rangeCounter.increment();
#endif

    m_ownerDocument->attachRange(this);
}

PassRefPtr<Range> Range::create(Document& ownerDocument)
{
    return adoptRef(new Range(ownerDocument));
}

inline Range::Range(Document& ownerDocument, Node* startContainer, int startOffset, Node* endContainer, int endOffset)
    : m_ownerDocument(&ownerDocument)
    , m_start(m_ownerDocument)
    , m_end(m_ownerDocument)
{
#ifndef NDEBUG
    rangeCounter.increment();
#endif

    m_ownerDocument->attachRange(this);

    // Simply setting the containers and offsets directly would not do any of the checking
    // that setStart and setEnd do, so we call those functions.
    setStart(startContainer, startOffset);
    setEnd(endContainer, endOffset);
}

PassRefPtr<Range> Range::create(Document& ownerDocument, Node* startContainer, int startOffset, Node* endContainer, int endOffset)
{
    return adoptRef(new Range(ownerDocument, startContainer, startOffset, endContainer, endOffset));
}

PassRefPtr<Range> Range::create(Document& ownerDocument, const Position& start, const Position& end)
{
    return adoptRef(new Range(ownerDocument, start.containerNode(), start.computeOffsetInContainerNode(), end.containerNode(), end.computeOffsetInContainerNode()));
}

Range::~Range()
{
#if !ENABLE(OILPAN)
    // Always detach (even if we've already detached) to fix https://bugs.webkit.org/show_bug.cgi?id=26044
    m_ownerDocument->detachRange(this);
#endif

#ifndef NDEBUG
    rangeCounter.decrement();
#endif
}

void Range::setDocument(Document& document)
{
    ASSERT(m_ownerDocument != document);
    ASSERT(m_ownerDocument);
    m_ownerDocument->detachRange(this);
    m_ownerDocument = &document;
    m_start.setToStartOfNode(document);
    m_end.setToStartOfNode(document);
    m_ownerDocument->attachRange(this);
}

Node* Range::commonAncestorContainer() const
{
    return commonAncestorContainer(m_start.container(), m_end.container());
}

Node* Range::commonAncestorContainer(Node* containerA, Node* containerB)
{
    for (Node* parentA = containerA; parentA; parentA = parentA->parentNode()) {
        for (Node* parentB = containerB; parentB; parentB = parentB->parentNode()) {
            if (parentA == parentB)
                return parentA;
        }
    }
    return 0;
}

static inline bool checkForDifferentRootContainer(const RangeBoundaryPoint& start, const RangeBoundaryPoint& end)
{
    Node* endRootContainer = end.container();
    while (endRootContainer->parentNode())
        endRootContainer = endRootContainer->parentNode();
    Node* startRootContainer = start.container();
    while (startRootContainer->parentNode())
        startRootContainer = startRootContainer->parentNode();

    return startRootContainer != endRootContainer || (Range::compareBoundaryPoints(start, end, ASSERT_NO_EXCEPTION) > 0);
}

void Range::setStart(PassRefPtr<Node> refNode, int offset, ExceptionState& exceptionState)
{
    if (!refNode) {
        exceptionState.throwDOMException(NotFoundError, "The node provided was null.");
        return;
    }

    bool didMoveDocument = false;
    if (refNode->document() != m_ownerDocument) {
        setDocument(refNode->document());
        didMoveDocument = true;
    }

    Node* childNode = checkNodeWOffset(refNode.get(), offset, exceptionState);
    if (exceptionState.hadException())
        return;

    m_start.set(refNode, offset, childNode);

    if (didMoveDocument || checkForDifferentRootContainer(m_start, m_end))
        collapse(true);
}

void Range::setEnd(PassRefPtr<Node> refNode, int offset, ExceptionState& exceptionState)
{
    if (!refNode) {
        exceptionState.throwDOMException(NotFoundError, "The node provided was null.");
        return;
    }

    bool didMoveDocument = false;
    if (refNode->document() != m_ownerDocument) {
        setDocument(refNode->document());
        didMoveDocument = true;
    }

    Node* childNode = checkNodeWOffset(refNode.get(), offset, exceptionState);
    if (exceptionState.hadException())
        return;

    m_end.set(refNode, offset, childNode);

    if (didMoveDocument || checkForDifferentRootContainer(m_start, m_end))
        collapse(false);
}

void Range::setStart(const Position& start, ExceptionState& exceptionState)
{
    Position parentAnchored = start.parentAnchoredEquivalent();
    setStart(parentAnchored.containerNode(), parentAnchored.offsetInContainerNode(), exceptionState);
}

void Range::setEnd(const Position& end, ExceptionState& exceptionState)
{
    Position parentAnchored = end.parentAnchoredEquivalent();
    setEnd(parentAnchored.containerNode(), parentAnchored.offsetInContainerNode(), exceptionState);
}

void Range::collapse(bool toStart)
{
    if (toStart)
        m_end = m_start;
    else
        m_start = m_end;
}

bool Range::isPointInRange(Node* refNode, int offset, ExceptionState& exceptionState)
{
    if (!refNode) {
        exceptionState.throwDOMException(HierarchyRequestError, "The node provided was null.");
        return false;
    }

    if (!refNode->inActiveDocument() || refNode->document() != m_ownerDocument) {
        return false;
    }

    checkNodeWOffset(refNode, offset, exceptionState);
    if (exceptionState.hadException())
        return false;

    return compareBoundaryPoints(refNode, offset, m_start.container(), m_start.offset(), exceptionState) >= 0 && !exceptionState.hadException()
        && compareBoundaryPoints(refNode, offset, m_end.container(), m_end.offset(), exceptionState) <= 0 && !exceptionState.hadException();
}

short Range::comparePoint(Node* refNode, int offset, ExceptionState& exceptionState) const
{
    // http://developer.mozilla.org/en/docs/DOM:range.comparePoint
    // This method returns -1, 0 or 1 depending on if the point described by the
    // refNode node and an offset within the node is before, same as, or after the range respectively.

    if (!refNode->inActiveDocument()) {
        exceptionState.throwDOMException(WrongDocumentError, "The node provided is not in an active document.");
        return 0;
    }

    if (refNode->document() != m_ownerDocument) {
        exceptionState.throwDOMException(WrongDocumentError, "The node provided is not in this Range's Document.");
        return 0;
    }

    checkNodeWOffset(refNode, offset, exceptionState);
    if (exceptionState.hadException())
        return 0;

    // compare to start, and point comes before
    if (compareBoundaryPoints(refNode, offset, m_start.container(), m_start.offset(), exceptionState) < 0)
        return -1;

    if (exceptionState.hadException())
        return 0;

    // compare to end, and point comes after
    if (compareBoundaryPoints(refNode, offset, m_end.container(), m_end.offset(), exceptionState) > 0 && !exceptionState.hadException())
        return 1;

    // point is in the middle of this range, or on the boundary points
    return 0;
}

Range::CompareResults Range::compareNode(Node* refNode, ExceptionState& exceptionState) const
{
    // http://developer.mozilla.org/en/docs/DOM:range.compareNode
    // This method returns 0, 1, 2, or 3 based on if the node is before, after,
    // before and after(surrounds), or inside the range, respectively

    if (!refNode) {
        exceptionState.throwDOMException(NotFoundError, "The node provided was null.");
        return NODE_BEFORE;
    }

    if (!refNode->inActiveDocument()) {
        // Firefox doesn't throw an exception for this case; it returns 0.
        return NODE_BEFORE;
    }

    if (refNode->document() != m_ownerDocument) {
        // Firefox doesn't throw an exception for this case; it returns 0.
        return NODE_BEFORE;
    }

    ContainerNode* parentNode = refNode->parentNode();
    int nodeIndex = refNode->nodeIndex();

    if (!parentNode) {
        // if the node is the top document we should return NODE_BEFORE_AND_AFTER
        // but we throw to match firefox behavior
        exceptionState.throwDOMException(NotFoundError, "The provided node has no parent.");
        return NODE_BEFORE;
    }

    if (comparePoint(parentNode, nodeIndex, exceptionState) < 0) { // starts before
        if (comparePoint(parentNode, nodeIndex + 1, exceptionState) > 0) // ends after the range
            return NODE_BEFORE_AND_AFTER;
        return NODE_BEFORE; // ends before or in the range
    }
    // starts at or after the range start
    if (comparePoint(parentNode, nodeIndex + 1, exceptionState) > 0) // ends after the range
        return NODE_AFTER;
    return NODE_INSIDE; // ends inside the range
}

short Range::compareBoundaryPoints(CompareHow how, const Range* sourceRange, ExceptionState& exceptionState) const
{
    if (!(how == START_TO_START || how == START_TO_END || how == END_TO_END || how == END_TO_START)) {
        exceptionState.throwDOMException(NotSupportedError, "The comparison method provided must be one of 'START_TO_START', 'START_TO_END', 'END_TO_END', or 'END_TO_START'.");
        return 0;
    }

    Node* thisCont = commonAncestorContainer();
    Node* sourceCont = sourceRange->commonAncestorContainer();
    if (thisCont->document() != sourceCont->document()) {
        exceptionState.throwDOMException(WrongDocumentError, "The source range is in a different document than this range.");
        return 0;
    }

    Node* thisTop = thisCont;
    Node* sourceTop = sourceCont;
    while (thisTop->parentNode())
        thisTop = thisTop->parentNode();
    while (sourceTop->parentNode())
        sourceTop = sourceTop->parentNode();
    if (thisTop != sourceTop) { // in different DocumentFragments
        exceptionState.throwDOMException(WrongDocumentError, "The source range is in a different document than this range.");
        return 0;
    }

    switch (how) {
        case START_TO_START:
            return compareBoundaryPoints(m_start, sourceRange->m_start, exceptionState);
        case START_TO_END:
            return compareBoundaryPoints(m_end, sourceRange->m_start, exceptionState);
        case END_TO_END:
            return compareBoundaryPoints(m_end, sourceRange->m_end, exceptionState);
        case END_TO_START:
            return compareBoundaryPoints(m_start, sourceRange->m_end, exceptionState);
    }

    ASSERT_NOT_REACHED();
    return 0;
}

short Range::compareBoundaryPoints(Node* containerA, int offsetA, Node* containerB, int offsetB, ExceptionState& exceptionState)
{
    ASSERT(containerA);
    ASSERT(containerB);

    if (!containerA)
        return -1;
    if (!containerB)
        return 1;

    // see DOM2 traversal & range section 2.5

    // case 1: both points have the same container
    if (containerA == containerB) {
        if (offsetA == offsetB)
            return 0;           // A is equal to B
        if (offsetA < offsetB)
            return -1;          // A is before B
        else
            return 1;           // A is after B
    }

    // case 2: node C (container B or an ancestor) is a child node of A
    Node* c = containerB;
    while (c && c->parentNode() != containerA)
        c = c->parentNode();
    if (c) {
        int offsetC = 0;
        Node* n = containerA->firstChild();
        while (n != c && offsetC < offsetA) {
            offsetC++;
            n = n->nextSibling();
        }

        if (offsetA <= offsetC)
            return -1;              // A is before B
        else
            return 1;               // A is after B
    }

    // case 3: node C (container A or an ancestor) is a child node of B
    c = containerA;
    while (c && c->parentNode() != containerB)
        c = c->parentNode();
    if (c) {
        int offsetC = 0;
        Node* n = containerB->firstChild();
        while (n != c && offsetC < offsetB) {
            offsetC++;
            n = n->nextSibling();
        }

        if (offsetC < offsetB)
            return -1;              // A is before B
        else
            return 1;               // A is after B
    }

    // case 4: containers A & B are siblings, or children of siblings
    // ### we need to do a traversal here instead
    Node* commonAncestor = commonAncestorContainer(containerA, containerB);
    if (!commonAncestor) {
        exceptionState.throwDOMException(WrongDocumentError, "The two ranges are in separate documents.");
        return 0;
    }
    Node* childA = containerA;
    while (childA && childA->parentNode() != commonAncestor)
        childA = childA->parentNode();
    if (!childA)
        childA = commonAncestor;
    Node* childB = containerB;
    while (childB && childB->parentNode() != commonAncestor)
        childB = childB->parentNode();
    if (!childB)
        childB = commonAncestor;

    if (childA == childB)
        return 0; // A is equal to B

    Node* n = commonAncestor->firstChild();
    while (n) {
        if (n == childA)
            return -1; // A is before B
        if (n == childB)
            return 1; // A is after B
        n = n->nextSibling();
    }

    // Should never reach this point.
    ASSERT_NOT_REACHED();
    return 0;
}

short Range::compareBoundaryPoints(const RangeBoundaryPoint& boundaryA, const RangeBoundaryPoint& boundaryB, ExceptionState& exceptionState)
{
    return compareBoundaryPoints(boundaryA.container(), boundaryA.offset(), boundaryB.container(), boundaryB.offset(), exceptionState);
}

bool Range::boundaryPointsValid() const
{
    TrackExceptionState exceptionState;
    return compareBoundaryPoints(m_start, m_end, exceptionState) <= 0 && !exceptionState.hadException();
}

void Range::deleteContents(ExceptionState& exceptionState)
{
    ASSERT(boundaryPointsValid());

    {
        EventQueueScope eventQueueScope;
        processContents(DELETE_CONTENTS, exceptionState);
    }
}

bool Range::intersectsNode(Node* refNode, ExceptionState& exceptionState)
{
    // http://developer.mozilla.org/en/docs/DOM:range.intersectsNode
    // Returns a bool if the node intersects the range.
    if (!refNode) {
        exceptionState.throwDOMException(NotFoundError, "The node provided is null.");
        return false;
    }

    if (!refNode->inActiveDocument() || refNode->document() != m_ownerDocument) {
        // Firefox doesn't throw an exception for these cases; it returns false.
        return false;
    }

    ContainerNode* parentNode = refNode->parentNode();
    int nodeIndex = refNode->nodeIndex();

    if (!parentNode) {
        // if the node is the top document we should return NODE_BEFORE_AND_AFTER
        // but we throw to match firefox behavior
        exceptionState.throwDOMException(NotFoundError, "The node provided has no parent.");
        return false;
    }

    if (comparePoint(parentNode, nodeIndex, exceptionState) < 0 // starts before start
        && comparePoint(parentNode, nodeIndex + 1, exceptionState) < 0) { // ends before start
        return false;
    }

    if (comparePoint(parentNode, nodeIndex, exceptionState) > 0 // starts after end
        && comparePoint(parentNode, nodeIndex + 1, exceptionState) > 0) { // ends after end
        return false;
    }

    return true; // all other cases
}

static inline Node* highestAncestorUnderCommonRoot(Node* node, Node* commonRoot)
{
    if (node == commonRoot)
        return 0;

    ASSERT(commonRoot->contains(node));

    while (node->parentNode() != commonRoot)
        node = node->parentNode();

    return node;
}

static inline Node* childOfCommonRootBeforeOffset(Node* container, unsigned offset, Node* commonRoot)
{
    ASSERT(container);
    ASSERT(commonRoot);

    if (!commonRoot->contains(container))
        return 0;

    if (container == commonRoot) {
        container = container->firstChild();
        for (unsigned i = 0; container && i < offset; i++)
            container = container->nextSibling();
    } else {
        while (container->parentNode() != commonRoot)
            container = container->parentNode();
    }

    return container;
}

PassRefPtr<DocumentFragment> Range::processContents(ActionType action, ExceptionState& exceptionState)
{
    typedef Vector<RefPtr<Node> > NodeVector;

    RefPtr<DocumentFragment> fragment = nullptr;
    if (action == EXTRACT_CONTENTS || action == CLONE_CONTENTS)
        fragment = DocumentFragment::create(*m_ownerDocument.get());

    if (collapsed())
        return fragment.release();

    RefPtr<Node> commonRoot = commonAncestorContainer();
    ASSERT(commonRoot);

    if (m_start.container() == m_end.container()) {
        processContentsBetweenOffsets(action, fragment, m_start.container(), m_start.offset(), m_end.offset(), exceptionState);
        return fragment;
    }

    // Since mutation observers can modify the range during the process, the boundary points need to be saved.
    RangeBoundaryPoint originalStart(m_start);
    RangeBoundaryPoint originalEnd(m_end);

    // what is the highest node that partially selects the start / end of the range?
    RefPtr<Node> partialStart = highestAncestorUnderCommonRoot(originalStart.container(), commonRoot.get());
    RefPtr<Node> partialEnd = highestAncestorUnderCommonRoot(originalEnd.container(), commonRoot.get());

    // Start and end containers are different.
    // There are three possibilities here:
    // 1. Start container == commonRoot (End container must be a descendant)
    // 2. End container == commonRoot (Start container must be a descendant)
    // 3. Neither is commonRoot, they are both descendants
    //
    // In case 3, we grab everything after the start (up until a direct child
    // of commonRoot) into leftContents, and everything before the end (up until
    // a direct child of commonRoot) into rightContents. Then we process all
    // commonRoot children between leftContents and rightContents
    //
    // In case 1 or 2, we skip either processing of leftContents or rightContents,
    // in which case the last lot of nodes either goes from the first or last
    // child of commonRoot.
    //
    // These are deleted, cloned, or extracted (i.e. both) depending on action.

    // Note that we are verifying that our common root hierarchy is still intact
    // after any DOM mutation event, at various stages below. See webkit bug 60350.

    RefPtr<Node> leftContents = nullptr;
    if (originalStart.container() != commonRoot && commonRoot->contains(originalStart.container())) {
        leftContents = processContentsBetweenOffsets(action, nullptr, originalStart.container(), originalStart.offset(), originalStart.container()->lengthOfContents(), exceptionState);
        leftContents = processAncestorsAndTheirSiblings(action, originalStart.container(), ProcessContentsForward, leftContents, commonRoot.get(), exceptionState);
    }

    RefPtr<Node> rightContents = nullptr;
    if (m_end.container() != commonRoot && commonRoot->contains(originalEnd.container())) {
        rightContents = processContentsBetweenOffsets(action, nullptr, originalEnd.container(), 0, originalEnd.offset(), exceptionState);
        rightContents = processAncestorsAndTheirSiblings(action, originalEnd.container(), ProcessContentsBackward, rightContents, commonRoot.get(), exceptionState);
    }

    // delete all children of commonRoot between the start and end container
    RefPtr<Node> processStart = childOfCommonRootBeforeOffset(originalStart.container(), originalStart.offset(), commonRoot.get());
    if (processStart && originalStart.container() != commonRoot) // processStart contains nodes before m_start.
        processStart = processStart->nextSibling();
    RefPtr<Node> processEnd = childOfCommonRootBeforeOffset(originalEnd.container(), originalEnd.offset(), commonRoot.get());

    // Collapse the range, making sure that the result is not within a node that was partially selected.
    if (action == EXTRACT_CONTENTS || action == DELETE_CONTENTS) {
        if (partialStart && commonRoot->contains(partialStart.get())) {
            // FIXME: We should not continue if we have an earlier error.
            exceptionState.clearException();
            setStart(partialStart->parentNode(), partialStart->nodeIndex() + 1, exceptionState);
        } else if (partialEnd && commonRoot->contains(partialEnd.get())) {
            // FIXME: We should not continue if we have an earlier error.
            exceptionState.clearException();
            setStart(partialEnd->parentNode(), partialEnd->nodeIndex(), exceptionState);
        }
        if (exceptionState.hadException())
            return nullptr;
        m_end = m_start;
    }

    originalStart.clear();
    originalEnd.clear();

    // Now add leftContents, stuff in between, and rightContents to the fragment
    // (or just delete the stuff in between)

    if ((action == EXTRACT_CONTENTS || action == CLONE_CONTENTS) && leftContents)
        fragment->appendChild(leftContents, exceptionState);

    if (processStart) {
        NodeVector nodes;
        for (Node* n = processStart.get(); n && n != processEnd; n = n->nextSibling())
            nodes.append(n);
        processNodes(action, nodes, commonRoot, fragment, exceptionState);
    }

    if ((action == EXTRACT_CONTENTS || action == CLONE_CONTENTS) && rightContents)
        fragment->appendChild(rightContents, exceptionState);

    return fragment.release();
}

static inline void deleteCharacterData(PassRefPtr<CharacterData> data, unsigned startOffset, unsigned endOffset, ExceptionState& exceptionState)
{
    if (data->length() - endOffset)
        data->deleteData(endOffset, data->length() - endOffset, exceptionState);
    if (startOffset)
        data->deleteData(0, startOffset, exceptionState);
}

PassRefPtr<Node> Range::processContentsBetweenOffsets(ActionType action, PassRefPtr<DocumentFragment> fragment,
    Node* container, unsigned startOffset, unsigned endOffset, ExceptionState& exceptionState)
{
    ASSERT(container);
    ASSERT(startOffset <= endOffset);

    // This switch statement must be consistent with that of Node::lengthOfContents.
    RefPtr<Node> result = nullptr;
    switch (container->nodeType()) {
    case Node::TEXT_NODE:
        endOffset = std::min(endOffset, toCharacterData(container)->length());
        if (action == EXTRACT_CONTENTS || action == CLONE_CONTENTS) {
            RefPtr<CharacterData> c = static_pointer_cast<CharacterData>(container->cloneNode(true));
            deleteCharacterData(c, startOffset, endOffset, exceptionState);
            if (fragment) {
                result = fragment;
                result->appendChild(c.release(), exceptionState);
            } else
                result = c.release();
        }
        if (action == EXTRACT_CONTENTS || action == DELETE_CONTENTS)
            toCharacterData(container)->deleteData(startOffset, endOffset - startOffset, exceptionState);
        break;
    case Node::ELEMENT_NODE:
    case Node::DOCUMENT_NODE:
    case Node::DOCUMENT_FRAGMENT_NODE:
        // FIXME: Should we assert that some nodes never appear here?
        if (action == EXTRACT_CONTENTS || action == CLONE_CONTENTS) {
            if (fragment)
                result = fragment;
            else
                result = container->cloneNode(false);
        }

        Node* n = container->firstChild();
        Vector<RefPtr<Node> > nodes;
        for (unsigned i = startOffset; n && i; i--)
            n = n->nextSibling();
        for (unsigned i = startOffset; n && i < endOffset; i++, n = n->nextSibling())
            nodes.append(n);

        processNodes(action, nodes, container, result, exceptionState);
        break;
    }

    return result.release();
}

void Range::processNodes(ActionType action, Vector<RefPtr<Node> >& nodes, PassRefPtr<Node> oldContainer, PassRefPtr<Node> newContainer, ExceptionState& exceptionState)
{
    for (unsigned i = 0; i < nodes.size(); i++) {
        switch (action) {
        case DELETE_CONTENTS:
            oldContainer->removeChild(nodes[i].get(), exceptionState);
            break;
        case EXTRACT_CONTENTS:
            newContainer->appendChild(nodes[i].release(), exceptionState); // will remove n from its parent
            break;
        case CLONE_CONTENTS:
            newContainer->appendChild(nodes[i]->cloneNode(true), exceptionState);
            break;
        }
    }
}

PassRefPtr<Node> Range::processAncestorsAndTheirSiblings(ActionType action, Node* container, ContentsProcessDirection direction, PassRefPtr<Node> passedClonedContainer, Node* commonRoot, ExceptionState& exceptionState)
{
    typedef Vector<RefPtr<Node> > NodeVector;

    RefPtr<Node> clonedContainer = passedClonedContainer;
    NodeVector ancestors;
    for (ContainerNode* n = container->parentNode(); n && n != commonRoot; n = n->parentNode())
        ancestors.append(n);

    RefPtr<Node> firstChildInAncestorToProcess = direction == ProcessContentsForward ? container->nextSibling() : container->previousSibling();
    for (NodeVector::const_iterator it = ancestors.begin(); it != ancestors.end(); ++it) {
        RefPtr<Node> ancestor = *it;
        if (action == EXTRACT_CONTENTS || action == CLONE_CONTENTS) {
            if (RefPtr<Node> clonedAncestor = ancestor->cloneNode(false)) { // Might have been removed already during mutation event.
                clonedAncestor->appendChild(clonedContainer, exceptionState);
                clonedContainer = clonedAncestor;
            }
        }

        // Copy siblings of an ancestor of start/end containers
        // FIXME: This assertion may fail if DOM is modified during mutation event
        // FIXME: Share code with Range::processNodes
        ASSERT(!firstChildInAncestorToProcess || firstChildInAncestorToProcess->parentNode() == ancestor);

        NodeVector nodes;
        for (Node* child = firstChildInAncestorToProcess.get(); child;
            child = (direction == ProcessContentsForward) ? child->nextSibling() : child->previousSibling())
            nodes.append(child);

        for (NodeVector::const_iterator it = nodes.begin(); it != nodes.end(); ++it) {
            Node* child = it->get();
            switch (action) {
            case DELETE_CONTENTS:
                // Prior call of ancestor->removeChild() may cause a tree change due to DOMSubtreeModified event.
                // Therefore, we need to make sure |ancestor| is still |child|'s parent.
                if (ancestor == child->parentNode())
                    ancestor->removeChild(child, exceptionState);
                break;
            case EXTRACT_CONTENTS: // will remove child from ancestor
                if (direction == ProcessContentsForward)
                    clonedContainer->appendChild(child, exceptionState);
                else
                    clonedContainer->insertBefore(child, clonedContainer->firstChild(), exceptionState);
                break;
            case CLONE_CONTENTS:
                if (direction == ProcessContentsForward)
                    clonedContainer->appendChild(child->cloneNode(true), exceptionState);
                else
                    clonedContainer->insertBefore(child->cloneNode(true), clonedContainer->firstChild(), exceptionState);
                break;
            }
        }
        firstChildInAncestorToProcess = direction == ProcessContentsForward ? ancestor->nextSibling() : ancestor->previousSibling();
    }

    return clonedContainer.release();
}

PassRefPtr<DocumentFragment> Range::extractContents(ExceptionState& exceptionState)
{
    checkExtractPrecondition(exceptionState);
    if (exceptionState.hadException())
        return nullptr;

    return processContents(EXTRACT_CONTENTS, exceptionState);
}

PassRefPtr<DocumentFragment> Range::cloneContents(ExceptionState& exceptionState)
{
    return processContents(CLONE_CONTENTS, exceptionState);
}

void Range::insertNode(PassRefPtr<Node> prpNewNode, ExceptionState& exceptionState)
{
    RefPtr<Node> newNode = prpNewNode;

    if (!newNode) {
        exceptionState.throwDOMException(NotFoundError, "The node provided is null.");
        return;
    }

    // HierarchyRequestError: Raised if the container of the start of the Range is of a type that
    // does not allow children of the type of newNode or if newNode is an ancestor of the container.

    // an extra one here - if a text node is going to split, it must have a parent to insert into
    bool startIsText = m_start.container()->isTextNode();
    if (startIsText && !m_start.container()->parentNode()) {
        exceptionState.throwDOMException(HierarchyRequestError, "This operation would split a text node, but there's no parent into which to insert.");
        return;
    }

    // In the case where the container is a text node, we check against the container's parent, because
    // text nodes get split up upon insertion.
    Node* checkAgainst;
    if (startIsText)
        checkAgainst = m_start.container()->parentNode();
    else
        checkAgainst = m_start.container();

    Node::NodeType newNodeType = newNode->nodeType();
    int numNewChildren;
    if (newNodeType == Node::DOCUMENT_FRAGMENT_NODE && !newNode->isShadowRoot()) {
        // check each child node, not the DocumentFragment itself
        numNewChildren = 0;
        for (Node* c = toDocumentFragment(newNode)->firstChild(); c; c = c->nextSibling()) {
            ++numNewChildren;
        }
    } else {
        numNewChildren = 1;
    }

    for (Node* n = m_start.container(); n; n = n->parentNode()) {
        if (n == newNode) {
            exceptionState.throwDOMException(HierarchyRequestError, "The node to be inserted contains the insertion point; it may not be inserted into itself.");
            return;
        }
    }

    // InvalidNodeTypeError: Raised if newNode is an Attr, Entity, Notation, ShadowRoot or Document node.
    switch (newNodeType) {
    case Node::DOCUMENT_NODE:
        exceptionState.throwDOMException(InvalidNodeTypeError, "The node to be inserted is a '" + newNode->nodeName() + "' node, which may not be inserted here.");
        return;
    default:
        if (newNode->isShadowRoot()) {
            exceptionState.throwDOMException(InvalidNodeTypeError, "The node to be inserted is a shadow root, which may not be inserted here.");
            return;
        }
        break;
    }

    EventQueueScope scope;
    bool collapsed = m_start == m_end;
    RefPtr<Node> container = nullptr;
    if (startIsText) {
        container = m_start.container();
        RefPtr<Text> newText = toText(container)->splitText(m_start.offset(), exceptionState);
        if (exceptionState.hadException())
            return;

        container = m_start.container();
        container->parentNode()->insertBefore(newNode.release(), newText.get(), exceptionState);
        if (exceptionState.hadException())
            return;

        if (collapsed) {
            // The load event would be fired regardless of EventQueueScope;
            // e.g. by ContainerNode::updateTreeAfterInsertion
            // Given circumstance may mutate the tree so newText->parentNode() may become null
            if (!newText->parentNode()) {
                exceptionState.throwDOMException(HierarchyRequestError, "This operation would set range's end to parent with new offset, but there's no parent into which to continue.");
                return;
            }
            m_end.setToBeforeChild(*newText);
        }
    } else {
        RefPtr<Node> lastChild = (newNodeType == Node::DOCUMENT_FRAGMENT_NODE) ? toDocumentFragment(newNode)->lastChild() : newNode.get();
        if (lastChild && lastChild == m_start.childBefore()) {
            // The insertion will do nothing, but we need to extend the range to include
            // the inserted nodes.
            Node* firstChild = (newNodeType == Node::DOCUMENT_FRAGMENT_NODE) ? toDocumentFragment(newNode)->firstChild() : newNode.get();
            ASSERT(firstChild);
            m_start.setToBeforeChild(*firstChild);
            return;
        }

        container = m_start.container();
        container->insertBefore(newNode.release(), NodeTraversal::childAt(*container, m_start.offset()), exceptionState);
        if (exceptionState.hadException())
            return;

        // Note that m_start.offset() may have changed as a result of container->insertBefore,
        // when the node we are inserting comes before the range in the same container.
        if (collapsed && numNewChildren)
            m_end.set(m_start.container(), m_start.offset() + numNewChildren, lastChild.get());
    }
}

String Range::toString() const
{
    StringBuilder builder;

    Node* pastLast = pastLastNode();
    for (Node* n = firstNode(); n != pastLast; n = NodeTraversal::next(*n)) {
        Node::NodeType type = n->nodeType();
        if (type == Node::TEXT_NODE) {
            String data = toCharacterData(n)->data();
            int length = data.length();
            int start = (n == m_start.container()) ? std::min(std::max(0, m_start.offset()), length) : 0;
            int end = (n == m_end.container()) ? std::min(std::max(start, m_end.offset()), length) : length;
            builder.append(data, start, end - start);
        }
    }

    return builder.toString();
}

String Range::toHTML() const
{
    return createMarkup(this);
}

String Range::text() const
{
    return plainText(this, TextIteratorEmitsObjectReplacementCharacter);
}

void Range::detach()
{
    // This is now a no-op as per the DOM specification.
}

Node* Range::checkNodeWOffset(Node* n, int offset, ExceptionState& exceptionState) const
{
    switch (n->nodeType()) {
        case Node::TEXT_NODE:
            if (static_cast<unsigned>(offset) > toCharacterData(n)->length())
                exceptionState.throwDOMException(IndexSizeError, "The offset " + String::number(offset) + " is larger than or equal to the node's length (" + String::number(toCharacterData(n)->length()) + ").");
            return 0;
        case Node::DOCUMENT_FRAGMENT_NODE:
        case Node::DOCUMENT_NODE:
        case Node::ELEMENT_NODE: {
            if (!offset)
                return 0;
            Node* childBefore = NodeTraversal::childAt(*n, offset - 1);
            if (!childBefore)
                exceptionState.throwDOMException(IndexSizeError, "There is no child at offset " + String::number(offset) + ".");
            return childBefore;
        }
    }
    ASSERT_NOT_REACHED();
    return 0;
}

void Range::checkNodeBA(Node* n, ExceptionState& exceptionState) const
{
    if (!n) {
        exceptionState.throwDOMException(NotFoundError, "The node provided is null.");
        return;
    }

    // InvalidNodeTypeError: Raised if the root container of refNode is not an
    // Attr, Document, DocumentFragment or ShadowRoot node, or part of a SVG shadow DOM tree,
    // or if refNode is a Document, DocumentFragment, ShadowRoot, Attr, Entity, or Notation node.

    if (!n->parentNode()) {
        exceptionState.throwDOMException(InvalidNodeTypeError, "the given Node has no parent.");
        return;
    }

    switch (n->nodeType()) {
        case Node::DOCUMENT_FRAGMENT_NODE:
        case Node::DOCUMENT_NODE:
            exceptionState.throwDOMException(InvalidNodeTypeError, "The node provided is of type '" + n->nodeName() + "'.");
            return;
        case Node::ELEMENT_NODE:
        case Node::TEXT_NODE:
            break;
    }

    Node* root = n;
    while (ContainerNode* parent = root->parentNode())
        root = parent;

    switch (root->nodeType()) {
        case Node::DOCUMENT_NODE:
        case Node::DOCUMENT_FRAGMENT_NODE:
        case Node::ELEMENT_NODE:
            break;
        case Node::TEXT_NODE:
            exceptionState.throwDOMException(InvalidNodeTypeError, "The node provided is of type '" + n->nodeName() + "'.");
            return;
    }
}

PassRefPtr<Range> Range::cloneRange() const
{
    return Range::create(*m_ownerDocument.get(), m_start.container(), m_start.offset(), m_end.container(), m_end.offset());
}

void Range::setStartAfter(Node* refNode, ExceptionState& exceptionState)
{
    checkNodeBA(refNode, exceptionState);
    if (exceptionState.hadException())
        return;

    setStart(refNode->parentNode(), refNode->nodeIndex() + 1, exceptionState);
}

void Range::setEndBefore(Node* refNode, ExceptionState& exceptionState)
{
    checkNodeBA(refNode, exceptionState);
    if (exceptionState.hadException())
        return;

    setEnd(refNode->parentNode(), refNode->nodeIndex(), exceptionState);
}

void Range::setEndAfter(Node* refNode, ExceptionState& exceptionState)
{
    checkNodeBA(refNode, exceptionState);
    if (exceptionState.hadException())
        return;

    setEnd(refNode->parentNode(), refNode->nodeIndex() + 1, exceptionState);
}

void Range::selectNode(Node* refNode, ExceptionState& exceptionState)
{
    if (!refNode) {
        exceptionState.throwDOMException(NotFoundError, "The node provided is null.");
        return;
    }

    if (!refNode->parentNode()) {
        exceptionState.throwDOMException(InvalidNodeTypeError, "the given Node has no parent.");
        return;
    }

    // InvalidNodeTypeError: Raised if an ancestor of refNode is an Entity, Notation or
    // DocumentType node or if refNode is a Document, DocumentFragment, ShadowRoot, Attr, Entity, or Notation
    // node.
    switch (refNode->nodeType()) {
        case Node::ELEMENT_NODE:
        case Node::TEXT_NODE:
            break;
        case Node::DOCUMENT_FRAGMENT_NODE:
        case Node::DOCUMENT_NODE:
            exceptionState.throwDOMException(InvalidNodeTypeError, "The node provided is of type '" + refNode->nodeName() + "'.");
            return;
    }

    if (m_ownerDocument != refNode->document())
        setDocument(refNode->document());

    setStartBefore(refNode);
    setEndAfter(refNode);
}

void Range::selectNodeContents(Node* refNode, ExceptionState& exceptionState)
{
    if (!refNode) {
        exceptionState.throwDOMException(NotFoundError, "The node provided is null.");
        return;
    }

    if (m_ownerDocument != refNode->document())
        setDocument(refNode->document());

    m_start.setToStartOfNode(*refNode);
    m_end.setToEndOfNode(*refNode);
}

void Range::surroundContents(PassRefPtr<Node> passNewParent, ExceptionState& exceptionState)
{
    RefPtr<Node> newParent = passNewParent;
    if (!newParent) {
        exceptionState.throwDOMException(NotFoundError, "The node provided is null.");
        return;
    }

    // InvalidStateError: Raised if the Range partially selects a non-Text node.
    Node* startNonTextContainer = m_start.container();
    if (startNonTextContainer->nodeType() == Node::TEXT_NODE)
        startNonTextContainer = startNonTextContainer->parentNode();
    Node* endNonTextContainer = m_end.container();
    if (endNonTextContainer->nodeType() == Node::TEXT_NODE)
        endNonTextContainer = endNonTextContainer->parentNode();
    if (startNonTextContainer != endNonTextContainer) {
        exceptionState.throwDOMException(InvalidStateError, "The Range has partially selected a non-Text node.");
        return;
    }

    // InvalidNodeTypeError: Raised if node is an Attr, Entity, DocumentType, Notation,
    // Document, or DocumentFragment node.
    switch (newParent->nodeType()) {
        case Node::DOCUMENT_FRAGMENT_NODE:
        case Node::DOCUMENT_NODE:
            exceptionState.throwDOMException(InvalidNodeTypeError, "The node provided is of type '" + newParent->nodeName() + "'.");
            return;
        case Node::ELEMENT_NODE:
        case Node::TEXT_NODE:
            break;
    }

    // Raise a HierarchyRequestError if m_start.container() doesn't accept children like newParent.
    Node* parentOfNewParent = m_start.container();

    // If m_start.container() is a character data node, it will be split and it will be its parent that will
    // need to accept newParent (or in the case of a comment, it logically "would" be inserted into the parent,
    // although this will fail below for another reason).
    if (parentOfNewParent->isCharacterDataNode())
        parentOfNewParent = parentOfNewParent->parentNode();

    if (!parentOfNewParent) {
        exceptionState.throwDOMException(HierarchyRequestError, "The container node is a detached character data node; no parent node is available for insertion.");
        return;
    }

    if (newParent->contains(m_start.container())) {
        exceptionState.throwDOMException(HierarchyRequestError, "The node provided contains the insertion point; it may not be inserted into itself.");
        return;
    }

    // FIXME: Do we need a check if the node would end up with a child node of a type not
    // allowed by the type of node?

    while (Node* n = newParent->firstChild()) {
        toContainerNode(newParent)->removeChild(n, exceptionState);
        if (exceptionState.hadException())
            return;
    }
    RefPtr<DocumentFragment> fragment = extractContents(exceptionState);
    if (exceptionState.hadException())
        return;
    insertNode(newParent, exceptionState);
    if (exceptionState.hadException())
        return;
    newParent->appendChild(fragment.release(), exceptionState);
    if (exceptionState.hadException())
        return;
    selectNode(newParent.get(), exceptionState);
}

void Range::setStartBefore(Node* refNode, ExceptionState& exceptionState)
{
    checkNodeBA(refNode, exceptionState);
    if (exceptionState.hadException())
        return;

    setStart(refNode->parentNode(), refNode->nodeIndex(), exceptionState);
}

void Range::checkExtractPrecondition(ExceptionState&)
{
    // FIXME: Remove.
}

Node* Range::firstNode() const
{
    if (m_start.container()->offsetInCharacters())
        return m_start.container();
    if (Node* child = NodeTraversal::childAt(*m_start.container(), m_start.offset()))
        return child;
    if (!m_start.offset())
        return m_start.container();
    return NodeTraversal::nextSkippingChildren(*m_start.container());
}

ShadowRoot* Range::shadowRoot() const
{
    return startContainer() ? startContainer()->containingShadowRoot() : 0;
}

Node* Range::pastLastNode() const
{
    if (m_end.container()->offsetInCharacters())
        return NodeTraversal::nextSkippingChildren(*m_end.container());
    if (Node* child = NodeTraversal::childAt(*m_end.container(), m_end.offset()))
        return child;
    return NodeTraversal::nextSkippingChildren(*m_end.container());
}

IntRect Range::boundingBox() const
{
    IntRect result;
    Vector<IntRect> rects;
    textRects(rects);
    const size_t n = rects.size();
    for (size_t i = 0; i < n; ++i)
        result.unite(rects[i]);
    return result;
}

void Range::textRects(Vector<IntRect>& rects, bool useSelectionHeight) const
{
    Node* startContainer = m_start.container();
    ASSERT(startContainer);
    Node* endContainer = m_end.container();
    ASSERT(endContainer);

    Node* stopNode = pastLastNode();
    for (Node* node = firstNode(); node != stopNode; node = NodeTraversal::next(*node)) {
        RenderObject* r = node->renderer();
        if (!r || !r->isText())
            continue;
        RenderText* renderText = toRenderText(r);
        int startOffset = node == startContainer ? m_start.offset() : 0;
        int endOffset = node == endContainer ? m_end.offset() : std::numeric_limits<int>::max();
        renderText->absoluteRectsForRange(rects, startOffset, endOffset, useSelectionHeight);
    }
}

void Range::textQuads(Vector<FloatQuad>& quads, bool useSelectionHeight) const
{
    Node* startContainer = m_start.container();
    ASSERT(startContainer);
    Node* endContainer = m_end.container();
    ASSERT(endContainer);

    Node* stopNode = pastLastNode();
    for (Node* node = firstNode(); node != stopNode; node = NodeTraversal::next(*node)) {
        RenderObject* r = node->renderer();
        if (!r || !r->isText())
            continue;
        RenderText* renderText = toRenderText(r);
        int startOffset = node == startContainer ? m_start.offset() : 0;
        int endOffset = node == endContainer ? m_end.offset() : std::numeric_limits<int>::max();
        renderText->absoluteQuadsForRange(quads, startOffset, endOffset, useSelectionHeight);
    }
}

#ifndef NDEBUG
void Range::formatForDebugger(char* buffer, unsigned length) const
{
    StringBuilder result;

    const int FormatBufferSize = 1024;
    char s[FormatBufferSize];
    result.appendLiteral("from offset ");
    result.appendNumber(m_start.offset());
    result.appendLiteral(" of ");
    m_start.container()->formatForDebugger(s, FormatBufferSize);
    result.append(s);
    result.appendLiteral(" to offset ");
    result.appendNumber(m_end.offset());
    result.appendLiteral(" of ");
    m_end.container()->formatForDebugger(s, FormatBufferSize);
    result.append(s);

    strncpy(buffer, result.toString().utf8().data(), length - 1);
}
#endif

bool areRangesEqual(const Range* a, const Range* b)
{
    if (a == b)
        return true;
    if (!a || !b)
        return false;
    return a->startPosition() == b->startPosition() && a->endPosition() == b->endPosition();
}

PassRefPtr<Range> rangeOfContents(Node* node)
{
    ASSERT(node);
    RefPtr<Range> range = Range::create(node->document());
    range->selectNodeContents(node, IGNORE_EXCEPTION);
    return range.release();
}

static inline void boundaryNodeChildrenChanged(RangeBoundaryPoint& boundary, ContainerNode* container)
{
    if (!boundary.childBefore())
        return;
    if (boundary.container() != container)
        return;
    boundary.invalidateOffset();
}

void Range::nodeChildrenChanged(ContainerNode* container)
{
    ASSERT(container);
    ASSERT(container->document() == m_ownerDocument);
    boundaryNodeChildrenChanged(m_start, container);
    boundaryNodeChildrenChanged(m_end, container);
}

static inline void boundaryNodeChildrenWillBeRemoved(RangeBoundaryPoint& boundary, ContainerNode& container)
{
    for (Node* nodeToBeRemoved = container.firstChild(); nodeToBeRemoved; nodeToBeRemoved = nodeToBeRemoved->nextSibling()) {
        if (boundary.childBefore() == nodeToBeRemoved) {
            boundary.setToStartOfNode(container);
            return;
        }

        for (Node* n = boundary.container(); n; n = n->parentNode()) {
            if (n == nodeToBeRemoved) {
                boundary.setToStartOfNode(container);
                return;
            }
        }
    }
}

void Range::nodeChildrenWillBeRemoved(ContainerNode& container)
{
    ASSERT(container.document() == m_ownerDocument);
    boundaryNodeChildrenWillBeRemoved(m_start, container);
    boundaryNodeChildrenWillBeRemoved(m_end, container);
}

static inline void boundaryNodeWillBeRemoved(RangeBoundaryPoint& boundary, Node& nodeToBeRemoved)
{
    if (boundary.childBefore() == nodeToBeRemoved) {
        boundary.childBeforeWillBeRemoved();
        return;
    }

    for (Node* n = boundary.container(); n; n = n->parentNode()) {
        if (n == nodeToBeRemoved) {
            boundary.setToBeforeChild(nodeToBeRemoved);
            return;
        }
    }
}

void Range::nodeWillBeRemoved(Node& node)
{
    ASSERT(node.document() == m_ownerDocument);
    ASSERT(node != m_ownerDocument.get());

    // FIXME: Once DOMNodeRemovedFromDocument mutation event removed, we
    // should change following if-statement to ASSERT(!node->parentNode).
    if (!node.parentNode())
        return;
    boundaryNodeWillBeRemoved(m_start, node);
    boundaryNodeWillBeRemoved(m_end, node);
}

static inline void boundaryTextInserted(RangeBoundaryPoint& boundary, Node* text, unsigned offset, unsigned length)
{
    if (boundary.container() != text)
        return;
    unsigned boundaryOffset = boundary.offset();
    if (offset >= boundaryOffset)
        return;
    boundary.setOffset(boundaryOffset + length);
}

void Range::didInsertText(Node* text, unsigned offset, unsigned length)
{
    ASSERT(text);
    ASSERT(text->document() == m_ownerDocument);
    boundaryTextInserted(m_start, text, offset, length);
    boundaryTextInserted(m_end, text, offset, length);
}

static inline void boundaryTextRemoved(RangeBoundaryPoint& boundary, Node* text, unsigned offset, unsigned length)
{
    if (boundary.container() != text)
        return;
    unsigned boundaryOffset = boundary.offset();
    if (offset >= boundaryOffset)
        return;
    if (offset + length >= boundaryOffset)
        boundary.setOffset(offset);
    else
        boundary.setOffset(boundaryOffset - length);
}

void Range::didRemoveText(Node* text, unsigned offset, unsigned length)
{
    ASSERT(text);
    ASSERT(text->document() == m_ownerDocument);
    boundaryTextRemoved(m_start, text, offset, length);
    boundaryTextRemoved(m_end, text, offset, length);
}

static inline void boundaryTextNodesMerged(RangeBoundaryPoint& boundary, const NodeWithIndex& oldNode, unsigned offset)
{
    if (boundary.container() == oldNode.node())
        boundary.set(oldNode.node().previousSibling(), boundary.offset() + offset, 0);
    else if (boundary.container() == oldNode.node().parentNode() && boundary.offset() == oldNode.index())
        boundary.set(oldNode.node().previousSibling(), offset, 0);
}

void Range::didMergeTextNodes(const NodeWithIndex& oldNode, unsigned offset)
{
    ASSERT(oldNode.node().document() == m_ownerDocument);
    ASSERT(oldNode.node().parentNode());
    ASSERT(oldNode.node().isTextNode());
    ASSERT(oldNode.node().previousSibling());
    ASSERT(oldNode.node().previousSibling()->isTextNode());
    boundaryTextNodesMerged(m_start, oldNode, offset);
    boundaryTextNodesMerged(m_end, oldNode, offset);
}

void Range::updateOwnerDocumentIfNeeded()
{
    ASSERT(m_start.container());
    ASSERT(m_end.container());
    Document& newDocument = m_start.container()->document();
    ASSERT(newDocument == m_end.container()->document());
    if (newDocument == m_ownerDocument)
        return;
    m_ownerDocument->detachRange(this);
    m_ownerDocument = &newDocument;
    m_ownerDocument->attachRange(this);
}

static inline void boundaryTextNodeSplit(RangeBoundaryPoint& boundary, Text& oldNode)
{
    Node* boundaryContainer = boundary.container();
    unsigned boundaryOffset = boundary.offset();
    if (boundary.childBefore() == &oldNode)
        boundary.set(boundaryContainer, boundaryOffset + 1, oldNode.nextSibling());
    else if (boundary.container() == &oldNode && boundaryOffset > oldNode.length())
        boundary.set(oldNode.nextSibling(), boundaryOffset - oldNode.length(), 0);
}

void Range::didSplitTextNode(Text& oldNode)
{
    ASSERT(oldNode.document() == m_ownerDocument);
    ASSERT(oldNode.parentNode());
    ASSERT(oldNode.nextSibling());
    ASSERT(oldNode.nextSibling()->isTextNode());
    boundaryTextNodeSplit(m_start, oldNode);
    boundaryTextNodeSplit(m_end, oldNode);
    ASSERT(boundaryPointsValid());
}

void Range::expand(const String& unit, ExceptionState& exceptionState)
{
    VisiblePosition start(startPosition());
    VisiblePosition end(endPosition());
    if (unit == "word") {
        start = startOfWord(start);
        end = endOfWord(end);
    } else if (unit == "sentence") {
        start = startOfSentence(start);
        end = endOfSentence(end);
    } else if (unit == "block") {
        start = startOfParagraph(start);
        end = endOfParagraph(end);
    } else if (unit == "document") {
        start = startOfDocument(start);
        end = endOfDocument(end);
    } else
        return;
    setStart(start.deepEquivalent().containerNode(), start.deepEquivalent().computeOffsetInContainerNode(), exceptionState);
    setEnd(end.deepEquivalent().containerNode(), end.deepEquivalent().computeOffsetInContainerNode(), exceptionState);
}

PassRefPtr<ClientRectList> Range::getClientRects() const
{
    m_ownerDocument->updateLayoutIgnorePendingStylesheets();

    Vector<FloatQuad> quads;
    getBorderAndTextQuads(quads);

    return ClientRectList::create(quads);
}

PassRefPtr<ClientRect> Range::getBoundingClientRect() const
{
    return ClientRect::create(boundingRect());
}

void Range::getBorderAndTextQuads(Vector<FloatQuad>& quads) const
{
    Node* startContainer = m_start.container();
    Node* endContainer = m_end.container();
    Node* stopNode = pastLastNode();

    HashSet<RawPtr<Node> > nodeSet;
    for (Node* node = firstNode(); node != stopNode; node = NodeTraversal::next(*node)) {
        if (node->isElementNode())
            nodeSet.add(node);
    }

    for (Node* node = firstNode(); node != stopNode; node = NodeTraversal::next(*node)) {
        if (node->isElementNode()) {
            if (!nodeSet.contains(node->parentNode())) {
                if (RenderBoxModelObject* renderBoxModelObject = toElement(node)->renderBoxModelObject()) {
                    Vector<FloatQuad> elementQuads;
                    renderBoxModelObject->absoluteQuads(elementQuads);
                    m_ownerDocument->adjustFloatQuadsForScroll(elementQuads);

                    quads.appendVector(elementQuads);
                }
            }
        } else if (node->isTextNode()) {
            if (RenderText* renderText = toText(node)->renderer()) {
                int startOffset = (node == startContainer) ? m_start.offset() : 0;
                int endOffset = (node == endContainer) ? m_end.offset() : INT_MAX;

                Vector<FloatQuad> textQuads;
                renderText->absoluteQuadsForRange(textQuads, startOffset, endOffset);
                m_ownerDocument->adjustFloatQuadsForScroll(textQuads);

                quads.appendVector(textQuads);
            }
        }
    }
}

FloatRect Range::boundingRect() const
{
    m_ownerDocument->updateLayoutIgnorePendingStylesheets();

    Vector<FloatQuad> quads;
    getBorderAndTextQuads(quads);
    if (quads.isEmpty())
        return FloatRect();

    FloatRect result;
    for (size_t i = 0; i < quads.size(); ++i)
        result.unite(quads[i].boundingBox());

    return result;
}

} // namespace blink

#ifndef NDEBUG

void showTree(const blink::Range* range)
{
    if (range && range->boundaryPointsValid()) {
        range->startContainer()->showTreeAndMark(range->startContainer(), "S", range->endContainer(), "E");
        fprintf(stderr, "start offset: %d, end offset: %d\n", range->startOffset(), range->endOffset());
    }
}

#endif
