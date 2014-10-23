/*
 * Copyright (C) 2004, 2006, 2008 Apple Inc. All rights reserved.
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

#ifndef Position_h
#define Position_h

#include "core/dom/ContainerNode.h"
#include "core/editing/EditingBoundary.h"
#include "core/editing/TextAffinity.h"
#include "platform/text/TextDirection.h"
#include "wtf/Assertions.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefPtr.h"

namespace blink {

class CSSComputedStyleDeclaration;
class Element;
class InlineBox;
class Node;
class RenderObject;
class Text;

enum PositionMoveType {
    CodePoint,       // Move by a single code point.
    Character,       // Move to the next Unicode character break.
    BackwardDeletion // Subject to platform conventions.
};

class Position {
    DISALLOW_ALLOCATION();
public:
    enum AnchorType {
        PositionIsOffsetInAnchor,
        PositionIsBeforeAnchor,
        PositionIsAfterAnchor,
        PositionIsBeforeChildren,
        PositionIsAfterChildren,
    };

    Position()
        : m_offset(0)
        , m_anchorType(PositionIsOffsetInAnchor)
        , m_isLegacyEditingPosition(false)
    {
    }

    // For creating legacy editing positions: (Anchor type will be determined from editingIgnoresContent(node))
    class LegacyEditingOffset {
    public:
        int value() const { return m_offset; }

    private:
        explicit LegacyEditingOffset(int offset) : m_offset(offset) { }

        friend Position createLegacyEditingPosition(PassRefPtrWillBeRawPtr<Node>, int offset);

        int m_offset;
    };
    Position(PassRefPtrWillBeRawPtr<Node> anchorNode, LegacyEditingOffset);

    // For creating before/after positions:
    Position(PassRefPtrWillBeRawPtr<Node> anchorNode, AnchorType);
    Position(PassRefPtrWillBeRawPtr<Text> textNode, unsigned offset);

    // For creating offset positions:
    // FIXME: This constructor should eventually go away. See bug 63040.
    Position(PassRefPtrWillBeRawPtr<Node> anchorNode, int offset, AnchorType);

    AnchorType anchorType() const { return static_cast<AnchorType>(m_anchorType); }

    void clear() { m_anchorNode.clear(); m_offset = 0; m_anchorType = PositionIsOffsetInAnchor; m_isLegacyEditingPosition = false; }

    // These are always DOM compliant values.  Editing positions like [img, 0] (aka [img, before])
    // will return img->parentNode() and img->nodeIndex() from these functions.
    Node* containerNode() const; // NULL for a before/after position anchored to a node with no parent
    Text* containerText() const;

    int computeOffsetInContainerNode() const;  // O(n) for before/after-anchored positions, O(1) for parent-anchored positions
    Position parentAnchoredEquivalent() const; // Convenience method for DOM positions that also fixes up some positions for editing

    // Inline O(1) access for Positions which callers know to be parent-anchored
    int offsetInContainerNode() const
    {
        ASSERT(anchorType() == PositionIsOffsetInAnchor);
        return m_offset;
    }

    // New code should not use this function.
    int deprecatedEditingOffset() const
    {
        if (m_isLegacyEditingPosition || (m_anchorType != PositionIsAfterAnchor && m_anchorType != PositionIsAfterChildren))
            return m_offset;
        return offsetForPositionAfterAnchor();
    }

    // These are convenience methods which are smart about whether the position is neighbor anchored or parent anchored
    Node* computeNodeBeforePosition() const;
    Node* computeNodeAfterPosition() const;

    Node* anchorNode() const { return m_anchorNode.get(); }

    // FIXME: Callers should be moved off of node(), node() is not always the container for this position.
    // For nodes which editingIgnoresContent(node()) returns true, positions like [ignoredNode, 0]
    // will be treated as before ignoredNode (thus node() is really after the position, not containing it).
    Node* deprecatedNode() const { return m_anchorNode.get(); }

    Document* document() const { return m_anchorNode ? &m_anchorNode->document() : 0; }
    bool inDocument() const { return m_anchorNode && m_anchorNode->inDocument(); }
    Element* rootEditableElement() const
    {
        Node* container = containerNode();
        return container ? container->rootEditableElement() : 0;
    }

    // These should only be used for PositionIsOffsetInAnchor positions, unless
    // the position is a legacy editing position.
    void moveToPosition(PassRefPtrWillBeRawPtr<Node> anchorNode, int offset);
    void moveToOffset(int offset);

    bool isNull() const { return !m_anchorNode; }
    bool isNotNull() const { return m_anchorNode; }
    bool isOrphan() const { return m_anchorNode && !m_anchorNode->inDocument(); }

    Element* element() const;
    PassRefPtrWillBeRawPtr<CSSComputedStyleDeclaration> computedStyle() const;

    // Move up or down the DOM by one position.
    // Offsets are computed using render text for nodes that have renderers - but note that even when
    // using composed characters, the result may be inside a single user-visible character if a ligature is formed.
    Position previous(PositionMoveType = CodePoint) const;
    Position next(PositionMoveType = CodePoint) const;
    static int uncheckedPreviousOffset(const Node*, int current);
    static int uncheckedPreviousOffsetForBackwardDeletion(const Node*, int current);
    static int uncheckedNextOffset(const Node*, int current);

    // These can be either inside or just before/after the node, depending on
    // if the node is ignored by editing or not.
    // FIXME: These should go away. They only make sense for legacy positions.
    bool atFirstEditingPositionForNode() const;
    bool atLastEditingPositionForNode() const;

    // Returns true if the visually equivalent positions around have different editability
    bool atEditingBoundary() const;
    Node* parentEditingBoundary() const;

    bool atStartOfTree() const;
    bool atEndOfTree() const;

    // These return useful visually equivalent positions.
    Position upstream(EditingBoundaryCrossingRule = CannotCrossEditingBoundary) const;
    Position downstream(EditingBoundaryCrossingRule = CannotCrossEditingBoundary) const;

    bool isCandidate() const;
    bool inRenderedText() const;
    bool isRenderedCharacter() const;
    bool rendersInDifferentPosition(const Position&) const;

    void getInlineBoxAndOffset(EAffinity, InlineBox*&, int& caretOffset) const;
    void getInlineBoxAndOffset(EAffinity, TextDirection primaryDirection, InlineBox*&, int& caretOffset) const;

    TextDirection primaryDirection() const;

    static bool hasRenderedNonAnonymousDescendantsWithHeight(RenderObject*);
    static bool nodeIsUserSelectNone(Node*);
    static bool nodeIsUserSelectAll(const Node*);
    static Node* rootUserSelectAllForNode(Node*);

    static ContainerNode* findParent(const Node*);

    void debugPosition(const char* msg = "") const;

#ifndef NDEBUG
    void formatForDebugger(char* buffer, unsigned length) const;
    void showAnchorTypeAndOffset() const;
    void showTreeForThis() const;
#endif

    void trace(Visitor*);

private:
    int offsetForPositionAfterAnchor() const;

    int renderedOffset() const;

    static AnchorType anchorTypeForLegacyEditingPosition(Node* anchorNode, int offset);

    RefPtrWillBeMember<Node> m_anchorNode;
    // m_offset can be the offset inside m_anchorNode, or if editingIgnoresContent(m_anchorNode)
    // returns true, then other places in editing will treat m_offset == 0 as "before the anchor"
    // and m_offset > 0 as "after the anchor node".  See parentAnchoredEquivalent for more info.
    int m_offset;
    unsigned m_anchorType : 3;
    bool m_isLegacyEditingPosition : 1;
};

inline Position createLegacyEditingPosition(PassRefPtrWillBeRawPtr<Node> node, int offset)
{
    return Position(node, Position::LegacyEditingOffset(offset));
}

inline bool operator==(const Position& a, const Position& b)
{
    // FIXME: In <div><img></div> [div, 0] != [img, 0] even though most of the
    // editing code will treat them as identical.
    return a.anchorNode() == b.anchorNode() && a.deprecatedEditingOffset() == b.deprecatedEditingOffset() && a.anchorType() == b.anchorType();
}

inline bool operator!=(const Position& a, const Position& b)
{
    return !(a == b);
}

// We define position creation functions to make callsites more readable.
// These are inline to prevent ref-churn when returning a Position object.
// If we ever add a PassPosition we can make these non-inline.

inline Position positionInParentBeforeNode(const Node& node)
{
    // FIXME: This should ASSERT(node.parentNode())
    // At least one caller currently hits this ASSERT though, which indicates
    // that the caller is trying to make a position relative to a disconnected node (which is likely an error)
    // Specifically, editing/deleting/delete-ligature-001.html crashes with ASSERT(node->parentNode())
    return Position(node.parentNode(), node.nodeIndex(), Position::PositionIsOffsetInAnchor);
}

inline Position positionInParentAfterNode(const Node& node)
{
    ASSERT(node.parentNode());
    return Position(node.parentNode(), node.nodeIndex() + 1, Position::PositionIsOffsetInAnchor);
}

// positionBeforeNode and positionAfterNode return neighbor-anchored positions, construction is O(1)
inline Position positionBeforeNode(Node* anchorNode)
{
    ASSERT(anchorNode);
    return Position(anchorNode, Position::PositionIsBeforeAnchor);
}

inline Position positionAfterNode(Node* anchorNode)
{
    ASSERT(anchorNode);
    return Position(anchorNode, Position::PositionIsAfterAnchor);
}

inline int lastOffsetInNode(Node* node)
{
    return node->offsetInCharacters() ? node->maxCharacterOffset() : static_cast<int>(node->countChildren());
}

// firstPositionInNode and lastPositionInNode return parent-anchored positions, lastPositionInNode construction is O(n) due to countChildren()
inline Position firstPositionInNode(Node* anchorNode)
{
    if (anchorNode->isTextNode())
        return Position(anchorNode, 0, Position::PositionIsOffsetInAnchor);
    return Position(anchorNode, Position::PositionIsBeforeChildren);
}

inline Position lastPositionInNode(Node* anchorNode)
{
    if (anchorNode->isTextNode())
        return Position(anchorNode, lastOffsetInNode(anchorNode), Position::PositionIsOffsetInAnchor);
    return Position(anchorNode, Position::PositionIsAfterChildren);
}

inline int minOffsetForNode(Node* anchorNode, int offset)
{
    if (anchorNode->offsetInCharacters())
        return std::min(offset, anchorNode->maxCharacterOffset());

    int newOffset = 0;
    for (Node* node = anchorNode->firstChild(); node && newOffset < offset; node = node->nextSibling())
        newOffset++;

    return newOffset;
}

inline bool offsetIsBeforeLastNodeOffset(int offset, Node* anchorNode)
{
    if (anchorNode->offsetInCharacters())
        return offset < anchorNode->maxCharacterOffset();

    int currentOffset = 0;
    for (Node* node = anchorNode->firstChild(); node && currentOffset < offset; node = node->nextSibling())
        currentOffset++;


    return offset < currentOffset;
}

} // namespace blink

#ifndef NDEBUG
// Outside the WebCore namespace for ease of invocation from gdb.
void showTree(const blink::Position&);
void showTree(const blink::Position*);
#endif

#endif // Position_h
