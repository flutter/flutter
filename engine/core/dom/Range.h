/*
 * (C) 1999 Lars Knoll (knoll@kde.org)
 * (C) 2000 Gunnstein Lye (gunnstein@netcom.no)
 * (C) 2000 Frederik Holljen (frederik.holljen@hig.no)
 * (C) 2001 Peter Kelly (pmk@post.com)
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009 Apple Inc. All rights reserved.
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
 *
 */

#ifndef Range_h
#define Range_h

#include "sky/engine/bindings/core/v8/ExceptionStatePlaceholder.h"
#include "sky/engine/bindings/core/v8/ScriptWrappable.h"
#include "sky/engine/core/dom/RangeBoundaryPoint.h"
#include "sky/engine/platform/geometry/FloatRect.h"
#include "sky/engine/platform/geometry/IntRect.h"
#include "sky/engine/platform/heap/Handle.h"
#include "sky/engine/wtf/Forward.h"
#include "sky/engine/wtf/RefCounted.h"

namespace blink {

class ClientRect;
class ClientRectList;
class ContainerNode;
class Document;
class DocumentFragment;
class ExceptionState;
class FloatQuad;
class Node;
class NodeWithIndex;
class Text;

class Range final : public RefCounted<Range>, public ScriptWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtr<Range> create(Document&);
    static PassRefPtr<Range> create(Document&, Node* startContainer, int startOffset, Node* endContainer, int endOffset);
    static PassRefPtr<Range> create(Document&, const Position&, const Position&);
    ~Range();

    Document& ownerDocument() const { ASSERT(m_ownerDocument); return *m_ownerDocument.get(); }
    Node* startContainer() const { return m_start.container(); }
    int startOffset() const { return m_start.offset(); }
    Node* endContainer() const { return m_end.container(); }
    int endOffset() const { return m_end.offset(); }

    bool collapsed() const { return m_start == m_end; }

    Node* commonAncestorContainer() const;
    static Node* commonAncestorContainer(Node* containerA, Node* containerB);
    void setStart(PassRefPtr<Node> container, int offset, ExceptionState& = ASSERT_NO_EXCEPTION);
    void setEnd(PassRefPtr<Node> container, int offset, ExceptionState& = ASSERT_NO_EXCEPTION);
    void collapse(bool toStart);
    bool isPointInRange(Node* refNode, int offset, ExceptionState&);
    short comparePoint(Node* refNode, int offset, ExceptionState&) const;
    enum CompareResults { NODE_BEFORE, NODE_AFTER, NODE_BEFORE_AND_AFTER, NODE_INSIDE };
    CompareResults compareNode(Node* refNode, ExceptionState&) const;
    enum CompareHow { START_TO_START, START_TO_END, END_TO_END, END_TO_START };
    short compareBoundaryPoints(CompareHow, const Range* sourceRange, ExceptionState&) const;
    static short compareBoundaryPoints(Node* containerA, int offsetA, Node* containerB, int offsetB, ExceptionState&);
    static short compareBoundaryPoints(const RangeBoundaryPoint& boundaryA, const RangeBoundaryPoint& boundaryB, ExceptionState&);
    bool boundaryPointsValid() const;
    bool intersectsNode(Node* refNode, ExceptionState&);
    void deleteContents(ExceptionState&);
    PassRefPtr<DocumentFragment> extractContents(ExceptionState&);
    PassRefPtr<DocumentFragment> cloneContents(ExceptionState&);
    void insertNode(PassRefPtr<Node>, ExceptionState&);
    String toString() const;

    String toHTML() const;
    String text() const;

    void detach();
    PassRefPtr<Range> cloneRange() const;

    void setStartAfter(Node*, ExceptionState& = ASSERT_NO_EXCEPTION);
    void setEndBefore(Node*, ExceptionState& = ASSERT_NO_EXCEPTION);
    void setEndAfter(Node*, ExceptionState& = ASSERT_NO_EXCEPTION);
    void selectNode(Node*, ExceptionState& = ASSERT_NO_EXCEPTION);
    void selectNodeContents(Node*, ExceptionState&);
    void surroundContents(PassRefPtr<Node>, ExceptionState&);
    void setStartBefore(Node*, ExceptionState& = ASSERT_NO_EXCEPTION);

    const Position startPosition() const { return m_start.toPosition(); }
    const Position endPosition() const { return m_end.toPosition(); }
    void setStart(const Position&, ExceptionState& = ASSERT_NO_EXCEPTION);
    void setEnd(const Position&, ExceptionState& = ASSERT_NO_EXCEPTION);

    Node* firstNode() const;
    Node* pastLastNode() const;

    ShadowRoot* shadowRoot() const;

    // Not transform-friendly
    void textRects(Vector<IntRect>&, bool useSelectionHeight = false) const;
    IntRect boundingBox() const;

    // Transform-friendly
    void textQuads(Vector<FloatQuad>&, bool useSelectionHeight = false) const;
    void getBorderAndTextQuads(Vector<FloatQuad>&) const;
    FloatRect boundingRect() const;

    void nodeChildrenChanged(ContainerNode*);
    void nodeChildrenWillBeRemoved(ContainerNode&);
    void nodeWillBeRemoved(Node&);

    void didInsertText(Node*, unsigned offset, unsigned length);
    void didRemoveText(Node*, unsigned offset, unsigned length);
    void didMergeTextNodes(const NodeWithIndex& oldNode, unsigned offset);
    void didSplitTextNode(Text& oldNode);
    void updateOwnerDocumentIfNeeded();

    // Expand range to a unit (word or sentence or block or document) boundary.
    // Please refer to https://bugs.webkit.org/show_bug.cgi?id=27632 comment #5
    // for details.
    void expand(const String&, ExceptionState&);

    PassRefPtr<ClientRectList> getClientRects() const;
    PassRefPtr<ClientRect> getBoundingClientRect() const;

#ifndef NDEBUG
    void formatForDebugger(char* buffer, unsigned length) const;
#endif

private:
    explicit Range(Document&);
    Range(Document&, Node* startContainer, int startOffset, Node* endContainer, int endOffset);

    void setDocument(Document&);

    Node* checkNodeWOffset(Node*, int offset, ExceptionState&) const;
    void checkNodeBA(Node*, ExceptionState&) const;
    void checkExtractPrecondition(ExceptionState&);

    enum ActionType { DELETE_CONTENTS, EXTRACT_CONTENTS, CLONE_CONTENTS };
    PassRefPtr<DocumentFragment> processContents(ActionType, ExceptionState&);
    static PassRefPtr<Node> processContentsBetweenOffsets(ActionType, PassRefPtr<DocumentFragment>, Node*, unsigned startOffset, unsigned endOffset, ExceptionState&);
    static void processNodes(ActionType, Vector<RefPtr<Node> >&, PassRefPtr<Node> oldContainer, PassRefPtr<Node> newContainer, ExceptionState&);
    enum ContentsProcessDirection { ProcessContentsForward, ProcessContentsBackward };
    static PassRefPtr<Node> processAncestorsAndTheirSiblings(ActionType, Node* container, ContentsProcessDirection, PassRefPtr<Node> clonedContainer, Node* commonRoot, ExceptionState&);

    RefPtr<Document> m_ownerDocument; // Cannot be null.
    RangeBoundaryPoint m_start;
    RangeBoundaryPoint m_end;
};

PassRefPtr<Range> rangeOfContents(Node*);

bool areRangesEqual(const Range*, const Range*);

} // namespace blink

#ifndef NDEBUG
// Outside the WebCore namespace for ease of invocation from gdb.
void showTree(const blink::Range*);
#endif

#endif // Range_h
