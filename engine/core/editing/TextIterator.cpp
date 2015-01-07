/*
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2012 Apple Inc. All rights reserved.
 * Copyright (C) 2005 Alexey Proskuryakov.
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
#include "sky/engine/core/editing/TextIterator.h"

#include <unicode/usearch.h>
#include <unicode/utf16.h>
#include "sky/engine/bindings/core/v8/ExceptionStatePlaceholder.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/NodeTraversal.h"
#include "sky/engine/core/dom/shadow/ShadowRoot.h"
#include "sky/engine/core/editing/VisiblePosition.h"
#include "sky/engine/core/editing/VisibleUnits.h"
#include "sky/engine/core/editing/htmlediting.h"
#include "sky/engine/core/frame/FrameView.h"
#include "sky/engine/core/html/HTMLElement.h"
#include "sky/engine/core/rendering/InlineTextBox.h"
#include "sky/engine/core/rendering/RenderBlock.h"
#include "sky/engine/core/rendering/RenderImage.h"
#include "sky/engine/platform/fonts/Character.h"
#include "sky/engine/platform/fonts/Font.h"
#include "sky/engine/platform/text/TextBoundaries.h"
#include "sky/engine/platform/text/TextBreakIteratorInternalICU.h"
#include "sky/engine/platform/text/UnicodeUtilities.h"
#include "sky/engine/wtf/text/CString.h"
#include "sky/engine/wtf/text/StringBuilder.h"
#include "sky/engine/wtf/unicode/CharacterNames.h"

using namespace WTF::Unicode;

namespace blink {

// Buffer that knows how to compare with a search target.
// Keeps enough of the previous text to be able to search in the future, but no more.
// Non-breaking spaces are always equal to normal spaces.
// Case folding is also done if the CaseInsensitive option is specified.
// Matches are further filtered if the AtWordStarts option is specified, although some
// matches inside a word are permitted if TreatMedialCapitalAsWordStart is specified as well.
class SearchBuffer {
    WTF_MAKE_NONCOPYABLE(SearchBuffer);
public:
    SearchBuffer(const String& target, FindOptions);
    ~SearchBuffer();

    // Returns number of characters appended; guaranteed to be in the range [1, length].
    template<typename CharType>
    void append(const CharType*, size_t length);
    size_t numberOfCharactersJustAppended() const { return m_numberOfCharactersJustAppended; }

    bool needsMoreContext() const;
    void prependContext(const UChar*, size_t length);
    void reachedBreak();

    // Result is the size in characters of what was found.
    // And <startOffset> is the number of characters back to the start of what was found.
    size_t search(size_t& startOffset);
    bool atBreak() const;

private:
    bool isBadMatch(const UChar*, size_t length) const;
    bool isWordStartMatch(size_t start, size_t length) const;

    Vector<UChar> m_target;
    FindOptions m_options;

    Vector<UChar> m_buffer;
    size_t m_overlap;
    size_t m_prefixLength;
    size_t m_numberOfCharactersJustAppended;
    bool m_atBreak;
    bool m_needsMoreContext;

    bool m_targetRequiresKanaWorkaround;
    Vector<UChar> m_normalizedTarget;
    mutable Vector<UChar> m_normalizedMatch;
};

// --------

static const unsigned bitsInWord = sizeof(unsigned) * 8;
static const unsigned bitInWordMask = bitsInWord - 1;

BitStack::BitStack()
    : m_size(0)
{
}

BitStack::~BitStack()
{
}

void BitStack::push(bool bit)
{
    unsigned index = m_size / bitsInWord;
    unsigned shift = m_size & bitInWordMask;
    if (!shift && index == m_words.size()) {
        m_words.grow(index + 1);
        m_words[index] = 0;
    }
    unsigned& word = m_words[index];
    unsigned mask = 1U << shift;
    if (bit)
        word |= mask;
    else
        word &= ~mask;
    ++m_size;
}

void BitStack::pop()
{
    if (m_size)
        --m_size;
}

bool BitStack::top() const
{
    if (!m_size)
        return false;
    unsigned shift = (m_size - 1) & bitInWordMask;
    return m_words.last() & (1U << shift);
}

unsigned BitStack::size() const
{
    return m_size;
}

// --------

#if ENABLE(ASSERT)

static unsigned depthCrossingShadowBoundaries(Node* node)
{
    unsigned depth = 0;
    for (ContainerNode* parent = node->parentOrShadowHostNode(); parent; parent = parent->parentOrShadowHostNode())
        ++depth;
    return depth;
}

#endif

// This function is like Range::pastLastNode, except for the fact that it can climb up out of shadow trees.
static Node* nextInPreOrderCrossingShadowBoundaries(Node* rangeEndContainer, int rangeEndOffset)
{
    if (!rangeEndContainer)
        return 0;
    if (rangeEndOffset >= 0 && !rangeEndContainer->offsetInCharacters()) {
        if (Node* next = NodeTraversal::childAt(*rangeEndContainer, rangeEndOffset))
            return next;
    }
    for (Node* node = rangeEndContainer; node; node = node->parentOrShadowHostNode()) {
        if (Node* next = node->nextSibling())
            return next;
    }
    return 0;
}

// --------

static inline bool fullyClipsContents(Node* node)
{
    RenderObject* renderer = node->renderer();
    if (!renderer || !renderer->isBox() || !renderer->hasOverflowClip())
        return false;
    return toRenderBox(renderer)->size().isEmpty();
}

static inline bool ignoresContainerClip(Node* node)
{
    RenderObject* renderer = node->renderer();
    if (!renderer || renderer->isText())
        return false;
    return renderer->style()->hasOutOfFlowPosition();
}

static void pushFullyClippedState(BitStack& stack, Node* node)
{
    ASSERT(stack.size() == depthCrossingShadowBoundaries(node));

    // FIXME: m_fullyClippedStack was added in response to <https://bugs.webkit.org/show_bug.cgi?id=26364>
    // ("Search can find text that's hidden by overflow:hidden"), but the logic here will not work correctly if
    // a shadow tree redistributes nodes. m_fullyClippedStack relies on the assumption that DOM node hierarchy matches
    // the render tree, which is not necessarily true if there happens to be shadow DOM distribution or other mechanics
    // that shuffle around the render objects regardless of node tree hierarchy (like CSS flexbox).
    //
    // A more appropriate way to handle this situation is to detect overflow:hidden blocks by using only rendering
    // primitives, not with DOM primitives.

    // Push true if this node full clips its contents, or if a parent already has fully
    // clipped and this is not a node that ignores its container's clip.
    stack.push(fullyClipsContents(node) || (stack.top() && !ignoresContainerClip(node)));
}

static void setUpFullyClippedStack(BitStack& stack, Node* node)
{
    // Put the nodes in a vector so we can iterate in reverse order.
    Vector<RawPtr<ContainerNode>, 100> ancestry;
    for (ContainerNode* parent = node->parentOrShadowHostNode(); parent; parent = parent->parentOrShadowHostNode())
        ancestry.append(parent);

    // Call pushFullyClippedState on each node starting with the earliest ancestor.
    size_t size = ancestry.size();
    for (size_t i = 0; i < size; ++i)
        pushFullyClippedState(stack, ancestry[size - i - 1]);
    pushFullyClippedState(stack, node);

    ASSERT(stack.size() == 1 + depthCrossingShadowBoundaries(node));
}

// --------

TextIterator::TextIterator(const Range* range, TextIteratorBehaviorFlags behavior)
    : m_startContainer(nullptr)
    , m_startOffset(0)
    , m_endContainer(nullptr)
    , m_endOffset(0)
    , m_positionNode(nullptr)
    , m_textLength(0)
    , m_needsAnotherNewline(false)
    , m_textBox(0)
    , m_lastTextNode(nullptr)
    , m_lastTextNodeEndedWithCollapsedSpace(false)
    , m_lastCharacter(0)
    , m_sortedTextBoxesPosition(0)
    , m_hasEmitted(false)
    , m_emitsCharactersBetweenAllVisiblePositions(behavior & TextIteratorEmitsCharactersBetweenAllVisiblePositions)
    , m_emitsOriginalText(behavior & TextIteratorEmitsOriginalText)
    , m_ignoresStyleVisibility(behavior & TextIteratorIgnoresStyleVisibility)
    , m_entersAuthorShadowRoots(behavior & TextIteratorEntersAuthorShadowRoots)
    , m_emitsObjectReplacementCharacter(behavior & TextIteratorEmitsObjectReplacementCharacter)
{
    if (range)
        initialize(range->startPosition(), range->endPosition());
}

TextIterator::TextIterator(const Position& start, const Position& end, TextIteratorBehaviorFlags behavior)
    : m_startContainer(nullptr)
    , m_startOffset(0)
    , m_endContainer(nullptr)
    , m_endOffset(0)
    , m_positionNode(nullptr)
    , m_textLength(0)
    , m_needsAnotherNewline(false)
    , m_textBox(0)
    , m_lastTextNode(nullptr)
    , m_lastTextNodeEndedWithCollapsedSpace(false)
    , m_lastCharacter(0)
    , m_sortedTextBoxesPosition(0)
    , m_hasEmitted(false)
    , m_emitsCharactersBetweenAllVisiblePositions(behavior & TextIteratorEmitsCharactersBetweenAllVisiblePositions)
    , m_emitsOriginalText(behavior & TextIteratorEmitsOriginalText)
    , m_ignoresStyleVisibility(behavior & TextIteratorIgnoresStyleVisibility)
    , m_entersAuthorShadowRoots(behavior & TextIteratorEntersAuthorShadowRoots)
    , m_emitsObjectReplacementCharacter(behavior & TextIteratorEmitsObjectReplacementCharacter)
{
    initialize(start, end);
}

void TextIterator::initialize(const Position& start, const Position& end)
{
    ASSERT(comparePositions(start, end) <= 0);

    // Get and validate |start| and |end|.
    Node* startContainer = start.containerNode();
    if (!startContainer)
        return;
    int startOffset = start.computeOffsetInContainerNode();
    Node* endContainer = end.containerNode();
    if (!endContainer)
        return;
    int endOffset = end.computeOffsetInContainerNode();

    // Remember the range - this does not change.
    m_startContainer = startContainer;
    m_startOffset = startOffset;
    m_endContainer = endContainer;
    m_endOffset = endOffset;

    // Figure out the initial value of m_shadowDepth: the depth of startContainer's tree scope from
    // the common ancestor tree scope.
    const TreeScope* commonAncestorTreeScope = startContainer->treeScope().commonAncestorTreeScope(endContainer->treeScope());
    ASSERT(commonAncestorTreeScope);
    m_shadowDepth = 0;
    for (const TreeScope* treeScope = &startContainer->treeScope(); treeScope != commonAncestorTreeScope; treeScope = treeScope->parentTreeScope())
        ++m_shadowDepth;

    // Set up the current node for processing.
    if (startContainer->offsetInCharacters())
        m_node = startContainer;
    else if (Node* child = NodeTraversal::childAt(*startContainer, startOffset))
        m_node = child;
    else if (!startOffset)
        m_node = startContainer;
    else
        m_node = NodeTraversal::nextSkippingChildren(*startContainer);

    if (!m_node)
        return;

    m_node->document().updateLayout();

    setUpFullyClippedStack(m_fullyClippedStack, m_node);
    m_offset = m_node == m_startContainer ? m_startOffset : 0;
    m_iterationProgress = HandledNone;

    // Calculate first out of bounds node.
    m_pastEndNode = nextInPreOrderCrossingShadowBoundaries(endContainer, endOffset);

    // Identify the first run.
    advance();
}

TextIterator::~TextIterator()
{
}

bool TextIterator::isInsideReplacedElement() const
{
    if (atEnd() || length() != 1 || !m_node)
        return false;

    RenderObject* renderer = m_node->renderer();
    return renderer && renderer->isReplaced();
}

void TextIterator::advance()
{
    ASSERT(!m_node || !m_node->document().needsRenderTreeUpdate());

    // reset the run information
    m_positionNode = nullptr;
    m_textLength = 0;

    // handle remembered node that needed a newline after the text node's newline
    if (m_needsAnotherNewline) {
        // Emit the extra newline, and position it *inside* m_node, after m_node's
        // contents, in case it's a block, in the same way that we position the first
        // newline. The range for the emitted newline should start where the line
        // break begins.
        // FIXME: It would be cleaner if we emitted two newlines during the last
        // iteration, instead of using m_needsAnotherNewline.
        Node* baseNode = m_node->lastChild() ? m_node->lastChild() : m_node.get();
        emitCharacter('\n', baseNode->parentNode(), baseNode, 1, 1);
        m_needsAnotherNewline = false;
        return;
    }

    // handle remembered text box
    if (m_textBox) {
        handleTextBox();
        if (m_positionNode)
            return;
    }

    while (m_node && (m_node != m_pastEndNode || m_shadowDepth > 0)) {
        // if the range ends at offset 0 of an element, represent the
        // position, but not the content, of that element e.g. if the
        // node is a blockflow element, emit a newline that
        // precedes the element
        if (m_node == m_endContainer && !m_endOffset) {
            representNodeOffsetZero();
            m_node = nullptr;
            return;
        }

        RenderObject* renderer = m_node->renderer();
        if (!renderer) {
            if (m_node->isShadowRoot()) {
                // A shadow root doesn't have a renderer, but we want to visit children anyway.
                m_iterationProgress = m_iterationProgress < HandledNode ? HandledNode : m_iterationProgress;
            } else {
                m_iterationProgress = HandledChildren;
            }
        } else {
            // Enter author shadow roots, from youngest, if any and if necessary.
            if (m_iterationProgress < HandledAuthorShadowRoots) {
                if (m_entersAuthorShadowRoots && m_node->isElementNode() && toElement(m_node)->hasAuthorShadowRoot()) {
                    ShadowRoot* youngestShadowRoot = toElement(m_node)->shadowRoot();
                    m_node = youngestShadowRoot;
                    m_iterationProgress = HandledNone;
                    ++m_shadowDepth;
                    pushFullyClippedState(m_fullyClippedStack, m_node);
                    continue;
                }

                m_iterationProgress = HandledAuthorShadowRoots;
            }

            // Enter user-agent shadow root, if necessary.
            if (m_iterationProgress < HandledUserAgentShadowRoot)
                m_iterationProgress = HandledUserAgentShadowRoot;

            // Handle the current node according to its type.
            if (m_iterationProgress < HandledNode) {
                bool handledNode = false;
                if (renderer->isText() && m_node->nodeType() == Node::TEXT_NODE) {
                    handledNode = handleTextNode();
                } else if (renderer && renderer->isImage()) {
                    handledNode = handleReplacedElement();
                } else {
                    handledNode = handleNonTextNode();
                }
                if (handledNode)
                    m_iterationProgress = HandledNode;
                if (m_positionNode)
                    return;
            }
        }

        // Find a new current node to handle in depth-first manner,
        // calling exitNode() as we come back thru a parent node.
        //
        // 1. Iterate over child nodes, if we haven't done yet.
        Node* next = m_iterationProgress < HandledChildren ? m_node->firstChild() : 0;
        m_offset = 0;
        if (!next) {
            // 2. If we've already iterated children or they are not available, go to the next sibling node.
            next = m_node->nextSibling();
            if (!next) {
                // 3. If we are at the last child, go up the node tree until we find a next sibling.
                bool pastEnd = NodeTraversal::next(*m_node) == m_pastEndNode;
                ContainerNode* parentNode = m_node->parentNode();
                while (!next && parentNode) {
                    if ((pastEnd && parentNode == m_endContainer) || m_endContainer->isDescendantOf(parentNode))
                        return;
                    bool haveRenderer = m_node->renderer();
                    m_node = parentNode;
                    m_fullyClippedStack.pop();
                    parentNode = m_node->parentNode();
                    if (haveRenderer)
                        exitNode();
                    if (m_positionNode) {
                        m_iterationProgress = HandledChildren;
                        return;
                    }
                    next = m_node->nextSibling();
                }

                if (!next && !parentNode && m_shadowDepth > 0) {
                    // 4. Reached the top of a shadow root.
                    ShadowRoot* shadowRoot = toShadowRoot(m_node);
                    m_node = shadowRoot->host();
                    m_iterationProgress = HandledAuthorShadowRoots;
                    --m_shadowDepth;
                    m_fullyClippedStack.pop();
                    continue;
                }
            }
            m_fullyClippedStack.pop();
        }

        // set the new current node
        m_node = next;
        if (m_node)
            pushFullyClippedState(m_fullyClippedStack, m_node);
        m_iterationProgress = HandledNone;

        // how would this ever be?
        if (m_positionNode)
            return;
    }
}

UChar TextIterator::characterAt(unsigned index) const
{
    ASSERT_WITH_SECURITY_IMPLICATION(index < static_cast<unsigned>(length()));
    if (!(index < static_cast<unsigned>(length())))
        return 0;

    if (m_singleCharacterBuffer) {
        ASSERT(!index);
        ASSERT(length() == 1);
        return m_singleCharacterBuffer;
    }

    return string()[startOffset() + index];
}

String TextIterator::substring(unsigned position, unsigned length) const
{
    ASSERT_WITH_SECURITY_IMPLICATION(position <= static_cast<unsigned>(this->length()));
    ASSERT_WITH_SECURITY_IMPLICATION(position + length <= static_cast<unsigned>(this->length()));
    if (!length)
        return emptyString();
    if (m_singleCharacterBuffer) {
        ASSERT(!position);
        ASSERT(length == 1);
        return String(&m_singleCharacterBuffer, 1);
    }
    return string().substring(startOffset() + position, length);
}

void TextIterator::appendTextToStringBuilder(StringBuilder& builder, unsigned position, unsigned maxLength) const
{
    unsigned lengthToAppend = std::min(static_cast<unsigned>(length()) - position, maxLength);
    if (!lengthToAppend)
        return;
    if (m_singleCharacterBuffer) {
        ASSERT(!position);
        builder.append(m_singleCharacterBuffer);
    } else {
        builder.append(string(), startOffset() + position, lengthToAppend);
    }
}

bool TextIterator::handleTextNode()
{
    if (m_fullyClippedStack.top() && !m_ignoresStyleVisibility)
        return false;

    Text* textNode = toText(m_node);
    RenderText* renderer = textNode->renderer();

    m_lastTextNode = textNode;
    String str = renderer->text();

    // handle pre-formatted text
    if (!renderer->style()->collapseWhiteSpace()) {
        int runStart = m_offset;
        if (m_lastTextNodeEndedWithCollapsedSpace && hasVisibleTextNode(renderer)) {
            emitCharacter(space, textNode, 0, runStart, runStart);
            return false;
        }
        int strLength = str.length();
        int end = (textNode == m_endContainer) ? m_endOffset : INT_MAX;
        int runEnd = std::min(strLength, end);

        if (runStart >= runEnd)
            return true;

        emitText(textNode, textNode->renderer(), runStart, runEnd);
        return true;
    }

    if (renderer->firstTextBox())
        m_textBox = renderer->firstTextBox();

    if (!renderer->firstTextBox() && str.length() > 0) {
        m_lastTextNodeEndedWithCollapsedSpace = true; // entire block is collapsed space
        return true;
    }

    // Used when text boxes are out of order (Hebrew/Arabic w/ embeded LTR text)
    if (renderer->containsReversedText()) {
        m_sortedTextBoxes.clear();
        for (InlineTextBox* textBox = renderer->firstTextBox(); textBox; textBox = textBox->nextTextBox()) {
            m_sortedTextBoxes.append(textBox);
        }
        std::sort(m_sortedTextBoxes.begin(), m_sortedTextBoxes.end(), InlineTextBox::compareByStart);
        m_sortedTextBoxesPosition = 0;
        m_textBox = m_sortedTextBoxes.isEmpty() ? 0 : m_sortedTextBoxes[0];
    }

    handleTextBox();
    return true;
}

void TextIterator::handleTextBox()
{
    RenderText* renderer = toRenderText(m_node->renderer());
    String str = renderer->text();
    unsigned start = m_offset;
    unsigned end = (m_node == m_endContainer) ? static_cast<unsigned>(m_endOffset) : INT_MAX;
    while (m_textBox) {
        unsigned textBoxStart = m_textBox->start();
        unsigned runStart = std::max(textBoxStart, start);

        // Check for collapsed space at the start of this run.
        InlineTextBox* firstTextBox = renderer->containsReversedText() ? (m_sortedTextBoxes.isEmpty() ? 0 : m_sortedTextBoxes[0]) : renderer->firstTextBox();
        bool needSpace = m_lastTextNodeEndedWithCollapsedSpace
            || (m_textBox == firstTextBox && textBoxStart == runStart && runStart > 0);
        if (needSpace && !renderer->style()->isCollapsibleWhiteSpace(m_lastCharacter) && m_lastCharacter) {
            if (m_lastTextNode == m_node && runStart > 0 && str[runStart - 1] == ' ') {
                unsigned spaceRunStart = runStart - 1;
                while (spaceRunStart > 0 && str[spaceRunStart - 1] == ' ')
                    --spaceRunStart;
                emitText(m_node, renderer, spaceRunStart, spaceRunStart + 1);
            } else {
                emitCharacter(space, m_node, 0, runStart, runStart);
            }
            return;
        }
        unsigned textBoxEnd = textBoxStart + m_textBox->len();
        unsigned runEnd = std::min(textBoxEnd, end);

        // Determine what the next text box will be, but don't advance yet
        InlineTextBox* nextTextBox = 0;
        if (renderer->containsReversedText()) {
            if (m_sortedTextBoxesPosition + 1 < m_sortedTextBoxes.size())
                nextTextBox = m_sortedTextBoxes[m_sortedTextBoxesPosition + 1];
        } else {
            nextTextBox = m_textBox->nextTextBox();
        }
        ASSERT(!nextTextBox || nextTextBox->renderer() == renderer);

        if (runStart < runEnd) {
            // Handle either a single newline character (which becomes a space),
            // or a run of characters that does not include a newline.
            // This effectively translates newlines to spaces without copying the text.
            if (str[runStart] == '\n') {
                emitCharacter(space, m_node, 0, runStart, runStart + 1);
                m_offset = runStart + 1;
            } else {
                size_t subrunEnd = str.find('\n', runStart);
                if (subrunEnd == kNotFound || subrunEnd > runEnd)
                    subrunEnd = runEnd;

                m_offset = subrunEnd;
                emitText(m_node, renderer, runStart, subrunEnd);
            }

            // If we are doing a subrun that doesn't go to the end of the text box,
            // come back again to finish handling this text box; don't advance to the next one.
            if (static_cast<unsigned>(m_positionEndOffset) < textBoxEnd)
                return;

            // Advance and return
            unsigned nextRunStart = nextTextBox ? nextTextBox->start() : str.length();
            if (nextRunStart > runEnd)
                m_lastTextNodeEndedWithCollapsedSpace = true; // collapsed space between runs or at the end
            m_textBox = nextTextBox;
            if (renderer->containsReversedText())
                ++m_sortedTextBoxesPosition;
            return;
        }
        // Advance and continue
        m_textBox = nextTextBox;
        if (renderer->containsReversedText())
            ++m_sortedTextBoxesPosition;
    }
}

bool TextIterator::handleReplacedElement()
{
    if (m_fullyClippedStack.top())
        return false;

    if (m_emitsObjectReplacementCharacter) {
        emitCharacter(objectReplacementCharacter, m_node->parentNode(), m_node, 0, 1);
        return true;
    }

    if (m_lastTextNodeEndedWithCollapsedSpace) {
        emitCharacter(space, m_lastTextNode->parentNode(), m_lastTextNode, 1, 1);
        return false;
    }

    m_hasEmitted = true;

    if (m_emitsCharactersBetweenAllVisiblePositions) {
        // We want replaced elements to behave like punctuation for boundary
        // finding, and to simply take up space for the selection preservation
        // code in moveParagraphs, so we use a comma.
        emitCharacter(',', m_node->parentNode(), m_node, 0, 1);
        return true;
    }

    m_positionNode = m_node->parentNode();
    m_positionOffsetBaseNode = m_node;
    m_positionStartOffset = 0;
    m_positionEndOffset = 1;
    m_singleCharacterBuffer = 0;
    m_textLength = 0;
    m_lastCharacter = 0;

    return true;
}

bool TextIterator::hasVisibleTextNode(RenderText* renderer)
{
    return true;
}

static bool shouldEmitNewlinesBeforeAndAfterNode(Node& node)
{
    RenderObject* r = node.renderer();
    return !r->isInline() && r->isRenderBlock()
        && !r->isFloatingOrOutOfFlowPositioned();
}

static bool shouldEmitNewlineAfterNode(Node& node)
{
    // FIXME: It should be better but slower to create a VisiblePosition here.
    if (!shouldEmitNewlinesBeforeAndAfterNode(node))
        return false;
    // Check if this is the very last renderer in the document.
    // If so, then we should not emit a newline.
    Node* next = &node;
    do {
        next = NodeTraversal::nextSkippingChildren(*next);
        if (next && next->renderer())
            return true;
    } while (next);
    return false;
}

static bool shouldEmitNewlineBeforeNode(Node& node)
{
    return shouldEmitNewlinesBeforeAndAfterNode(node);
}

static int collapsedSpaceLength(RenderText* renderer, int textEnd)
{
    const String& text = renderer->text();
    int length = text.length();
    for (int i = textEnd; i < length; ++i) {
        if (!renderer->style()->isCollapsibleWhiteSpace(text[i]))
            return i - textEnd;
    }

    return length - textEnd;
}

static int maxOffsetIncludingCollapsedSpaces(Node* node)
{
    int offset = caretMaxOffset(node);

    if (node->renderer() && node->renderer()->isText())
        offset += collapsedSpaceLength(toRenderText(node->renderer()), offset);

    return offset;
}

// Whether or not we should emit a character as we enter m_node (if it's a container) or as we hit it (if it's atomic).
bool TextIterator::shouldRepresentNodeOffsetZero()
{
    if (m_emitsCharactersBetweenAllVisiblePositions && isRenderedTableElement(m_node))
        return true;

    // Leave element positioned flush with start of a paragraph
    // (e.g. do not insert tab before a table cell at the start of a paragraph)
    if (m_lastCharacter == '\n')
        return false;

    // Otherwise, show the position if we have emitted any characters
    if (m_hasEmitted)
        return true;

    // We've not emitted anything yet. Generally, there is no need for any positioning then.
    // The only exception is when the element is visually not in the same line as
    // the start of the range (e.g. the range starts at the end of the previous paragraph).
    // NOTE: Creating VisiblePositions and comparing them is relatively expensive, so we
    // make quicker checks to possibly avoid that. Another check that we could make is
    // is whether the inline vs block flow changed since the previous visible element.
    // I think we're already in a special enough case that that won't be needed, tho.

    // No character needed if this is the first node in the range.
    if (m_node == m_startContainer)
        return false;

    // If we are outside the start container's subtree, assume we need to emit.
    // FIXME: m_startContainer could be an inline block
    if (!m_node->isDescendantOf(m_startContainer))
        return true;

    // If we started as m_startContainer offset 0 and the current node is a descendant of
    // the start container, we already had enough context to correctly decide whether to
    // emit after a preceding block. We chose not to emit (m_hasEmitted is false),
    // so don't second guess that now.
    // NOTE: Is this really correct when m_node is not a leftmost descendant? Probably
    // immaterial since we likely would have already emitted something by now.
    if (!m_startOffset)
        return false;

    // If this node is unrendered or invisible the VisiblePosition checks below won't have much meaning.
    // Additionally, if the range we are iterating over contains huge sections of unrendered content,
    // we would create VisiblePositions on every call to this function without this check.
    if (!m_node->renderer() || (m_node->renderer()->isRenderBlockFlow() && !toRenderBlock(m_node->renderer())->height()))
        return false;

    // The startPos.isNotNull() check is needed because the start could be before the body,
    // and in that case we'll get null. We don't want to put in newlines at the start in that case.
    // The currPos.isNotNull() check is needed because positions in non-HTML content
    // (like SVG) do not have visible positions, and we don't want to emit for them either.
    VisiblePosition startPos = VisiblePosition(Position(m_startContainer, m_startOffset, Position::PositionIsOffsetInAnchor), DOWNSTREAM);
    VisiblePosition currPos = VisiblePosition(positionBeforeNode(m_node), DOWNSTREAM);
    return startPos.isNotNull() && currPos.isNotNull() && !inSameLine(startPos, currPos);
}

bool TextIterator::shouldEmitSpaceBeforeAndAfterNode(Node* node)
{
    return isRenderedTableElement(node) && (node->renderer()->isInline() || m_emitsCharactersBetweenAllVisiblePositions);
}

void TextIterator::representNodeOffsetZero()
{
    // Emit a character to show the positioning of m_node.

    // When we haven't been emitting any characters, shouldRepresentNodeOffsetZero() can
    // create VisiblePositions, which is expensive. So, we perform the inexpensive checks
    // on m_node to see if it necessitates emitting a character first and will early return
    // before encountering shouldRepresentNodeOffsetZero()s worse case behavior.
    if (shouldEmitNewlineBeforeNode(*m_node)) {
        if (shouldRepresentNodeOffsetZero())
            emitCharacter('\n', m_node->parentNode(), m_node, 0, 0);
    } else if (shouldEmitSpaceBeforeAndAfterNode(m_node)) {
        if (shouldRepresentNodeOffsetZero())
            emitCharacter(space, m_node->parentNode(), m_node, 0, 0);
    }
}

bool TextIterator::handleNonTextNode()
{
    representNodeOffsetZero();
    return true;
}

void TextIterator::exitNode()
{
    // prevent emitting a newline when exiting a collapsed block at beginning of the range
    // FIXME: !m_hasEmitted does not necessarily mean there was a collapsed block... it could
    // have been an hr (e.g.). Also, a collapsed block could have height (e.g. a table) and
    // therefore look like a blank line.
    if (!m_hasEmitted)
        return;

    // Emit with a position *inside* m_node, after m_node's contents, in
    // case it is a block, because the run should start where the
    // emitted character is positioned visually.
    Node* baseNode = m_node->lastChild() ? m_node->lastChild() : m_node.get();
    // FIXME: This shouldn't require the m_lastTextNode to be true, but we can't change that without making
    // the logic in _web_attributedStringFromRange match. We'll get that for free when we switch to use
    // TextIterator in _web_attributedStringFromRange.
    // See <rdar://problem/5428427> for an example of how this mismatch will cause problems.
    if (m_lastTextNode && shouldEmitNewlineAfterNode(*m_node)) {
        // FIXME: We need to emit a '\n' as we leave an empty block(s) that
        // contain a VisiblePosition when doing selection preservation.
        if (m_lastCharacter != '\n') {
            // insert a newline with a position following this block's contents.
            emitCharacter('\n', baseNode->parentNode(), baseNode, 1, 1);
            // remember whether to later add a newline for the current node
            ASSERT(!m_needsAnotherNewline);
            m_needsAnotherNewline = false;
        }
    }

    // If nothing was emitted, see if we need to emit a space.
    if (!m_positionNode && shouldEmitSpaceBeforeAndAfterNode(m_node))
        emitCharacter(space, baseNode->parentNode(), baseNode, 1, 1);
}

void TextIterator::emitCharacter(UChar c, Node* textNode, Node* offsetBaseNode, int textStartOffset, int textEndOffset)
{
    m_hasEmitted = true;

    // remember information with which to construct the TextIterator::range()
    // NOTE: textNode is often not a text node, so the range will specify child nodes of positionNode
    m_positionNode = textNode;
    m_positionOffsetBaseNode = offsetBaseNode;
    m_positionStartOffset = textStartOffset;
    m_positionEndOffset = textEndOffset;

    // remember information with which to construct the TextIterator::characters() and length()
    m_singleCharacterBuffer = c;
    ASSERT(m_singleCharacterBuffer);
    m_textLength = 1;

    // remember some iteration state
    m_lastTextNodeEndedWithCollapsedSpace = false;
    m_lastCharacter = c;
}

void TextIterator::emitText(Node* textNode, RenderText* renderer, int textStartOffset, int textEndOffset)
{
    m_text = m_emitsOriginalText ? renderer->originalText() : renderer->text();
    ASSERT(!m_text.isEmpty());
    ASSERT(0 <= textStartOffset && textStartOffset < static_cast<int>(m_text.length()));
    ASSERT(0 <= textEndOffset && textEndOffset <= static_cast<int>(m_text.length()));
    ASSERT(textStartOffset <= textEndOffset);

    m_positionNode = textNode;
    m_positionOffsetBaseNode = nullptr;
    m_positionStartOffset = textStartOffset;
    m_positionEndOffset = textEndOffset;
    m_singleCharacterBuffer = 0;
    m_textLength = textEndOffset - textStartOffset;
    m_lastCharacter = m_text[textEndOffset - 1];

    m_lastTextNodeEndedWithCollapsedSpace = false;
    m_hasEmitted = true;
}

PassRefPtr<Range> TextIterator::range() const
{
    // use the current run information, if we have it
    if (m_positionNode) {
        if (m_positionOffsetBaseNode) {
            int index = m_positionOffsetBaseNode->nodeIndex();
            m_positionStartOffset += index;
            m_positionEndOffset += index;
            m_positionOffsetBaseNode = nullptr;
        }
        return Range::create(m_positionNode->document(), m_positionNode, m_positionStartOffset, m_positionNode, m_positionEndOffset);
    }

    // otherwise, return the end of the overall range we were given
    if (m_endContainer)
        return Range::create(m_endContainer->document(), m_endContainer, m_endOffset, m_endContainer, m_endOffset);

    return nullptr;
}

Node* TextIterator::node() const
{
    RefPtr<Range> textRange = range();
    if (!textRange)
        return 0;

    Node* node = textRange->startContainer();
    if (!node)
        return 0;
    if (node->offsetInCharacters())
        return node;

    return NodeTraversal::childAt(*node, textRange->startOffset());
}

// --------

SimplifiedBackwardsTextIterator::SimplifiedBackwardsTextIterator(const Range* r, TextIteratorBehaviorFlags behavior)
    : m_node(nullptr)
    , m_offset(0)
    , m_handledNode(false)
    , m_handledChildren(false)
    , m_startNode(nullptr)
    , m_startOffset(0)
    , m_endNode(nullptr)
    , m_endOffset(0)
    , m_positionNode(nullptr)
    , m_positionStartOffset(0)
    , m_positionEndOffset(0)
    , m_textOffset(0)
    , m_textLength(0)
    , m_lastTextNode(nullptr)
    , m_lastCharacter(0)
    , m_singleCharacterBuffer(0)
    , m_havePassedStartNode(false)
{
    ASSERT(behavior == TextIteratorDefaultBehavior);

    if (!r)
        return;

    Node* startNode = r->startContainer();
    if (!startNode)
        return;
    Node* endNode = r->endContainer();
    int startOffset = r->startOffset();
    int endOffset = r->endOffset();

    if (!startNode->offsetInCharacters() && startOffset >= 0) {
        // NodeTraversal::childAt() will return 0 if the offset is out of range. We rely on this behavior
        // instead of calling countChildren() to avoid traversing the children twice.
        if (Node* childAtOffset = NodeTraversal::childAt(*startNode, startOffset)) {
            startNode = childAtOffset;
            startOffset = 0;
        }
    }
    if (!endNode->offsetInCharacters() && endOffset > 0) {
        // NodeTraversal::childAt() will return 0 if the offset is out of range. We rely on this behavior
        // instead of calling countChildren() to avoid traversing the children twice.
        if (Node* childAtOffset = NodeTraversal::childAt(*endNode, endOffset - 1)) {
            endNode = childAtOffset;
            endOffset = lastOffsetInNode(endNode);
        }
    }

    m_node = endNode;
    setUpFullyClippedStack(m_fullyClippedStack, m_node);
    m_offset = endOffset;
    m_handledNode = false;
    m_handledChildren = !endOffset;

    m_startNode = startNode;
    m_startOffset = startOffset;
    m_endNode = endNode;
    m_endOffset = endOffset;

#if ENABLE(ASSERT)
    // Need this just because of the assert.
    m_positionNode = endNode;
#endif

    m_lastTextNode = nullptr;
    m_lastCharacter = '\n';

    m_havePassedStartNode = false;

    advance();
}

void SimplifiedBackwardsTextIterator::advance()
{
    ASSERT(m_positionNode);

    m_positionNode = nullptr;
    m_textLength = 0;

    while (m_node && !m_havePassedStartNode) {
        // Don't handle node if we start iterating at [node, 0].
        if (!m_handledNode && !(m_node == m_endNode && !m_endOffset)) {
            RenderObject* renderer = m_node->renderer();
            if (renderer && renderer->isText() && m_node->nodeType() == Node::TEXT_NODE) {
                if (m_offset > 0)
                    m_handledNode = handleTextNode();
            } else if (renderer && renderer->isImage()) {
                if (m_offset > 0)
                    m_handledNode = handleReplacedElement();
            } else {
                m_handledNode = handleNonTextNode();
            }
            if (m_positionNode)
                return;
        }

        if (!m_handledChildren && m_node->hasChildren()) {
            m_node = m_node->lastChild();
            pushFullyClippedState(m_fullyClippedStack, m_node);
        } else {
            // Exit empty containers as we pass over them or containers
            // where [container, 0] is where we started iterating.
            if (!m_handledNode
                && canHaveChildrenForEditing(m_node)
                && m_node->parentNode()
                && (!m_node->lastChild() || (m_node == m_endNode && !m_endOffset))) {
                exitNode();
                if (m_positionNode) {
                    m_handledNode = true;
                    m_handledChildren = true;
                    return;
                }
            }

            // Exit all other containers.
            while (!m_node->previousSibling()) {
                if (!advanceRespectingRange(m_node->parentOrShadowHostNode()))
                    break;
                m_fullyClippedStack.pop();
                exitNode();
                if (m_positionNode) {
                    m_handledNode = true;
                    m_handledChildren = true;
                    return;
                }
            }

            m_fullyClippedStack.pop();
            if (advanceRespectingRange(m_node->previousSibling()))
                pushFullyClippedState(m_fullyClippedStack, m_node);
            else
                m_node = nullptr;
        }

        // For the purpose of word boundary detection,
        // we should iterate all visible text and trailing (collapsed) whitespaces.
        m_offset = m_node ? maxOffsetIncludingCollapsedSpaces(m_node) : 0;
        m_handledNode = false;
        m_handledChildren = false;

        if (m_positionNode)
            return;
    }
}

bool SimplifiedBackwardsTextIterator::handleTextNode()
{
    m_lastTextNode = toText(m_node);

    // FIXME(sky): Remove this, it's :first-letter related.
    int offsetInNode = 0;
    RenderText* renderer = m_lastTextNode->renderer();
    if (!renderer)
        return true;

    String text = renderer->text();
    if (!renderer->firstTextBox() && text.length() > 0)
        return true;

    m_positionEndOffset = m_offset;
    m_offset = offsetInNode;
    m_positionNode = m_node;
    m_positionStartOffset = m_offset;

    ASSERT(0 <= m_positionStartOffset - offsetInNode && m_positionStartOffset - offsetInNode <= static_cast<int>(text.length()));
    ASSERT(1 <= m_positionEndOffset - offsetInNode && m_positionEndOffset - offsetInNode <= static_cast<int>(text.length()));
    ASSERT(m_positionStartOffset <= m_positionEndOffset);

    m_textLength = m_positionEndOffset - m_positionStartOffset;
    m_textOffset = m_positionStartOffset - offsetInNode;
    m_textContainer = text;
    m_singleCharacterBuffer = 0;
    RELEASE_ASSERT(static_cast<unsigned>(m_textOffset + m_textLength) <= text.length());

    m_lastCharacter = text[m_positionEndOffset - 1];

    return true;
}

bool SimplifiedBackwardsTextIterator::handleReplacedElement()
{
    unsigned index = m_node->nodeIndex();
    // We want replaced elements to behave like punctuation for boundary
    // finding, and to simply take up space for the selection preservation
    // code in moveParagraphs, so we use a comma. Unconditionally emit
    // here because this iterator is only used for boundary finding.
    emitCharacter(',', m_node->parentNode(), index, index + 1);
    return true;
}

bool SimplifiedBackwardsTextIterator::handleNonTextNode()
{
    return true;
}

void SimplifiedBackwardsTextIterator::exitNode()
{
}

void SimplifiedBackwardsTextIterator::emitCharacter(UChar c, Node* node, int startOffset, int endOffset)
{
    m_singleCharacterBuffer = c;
    m_positionNode = node;
    m_positionStartOffset = startOffset;
    m_positionEndOffset = endOffset;
    m_textOffset = 0;
    m_textLength = 1;
    m_lastCharacter = c;
}

bool SimplifiedBackwardsTextIterator::advanceRespectingRange(Node* next)
{
    if (!next)
        return false;
    m_havePassedStartNode |= m_node == m_startNode;
    if (m_havePassedStartNode)
        return false;
    m_node = next;
    return true;
}

PassRefPtr<Range> SimplifiedBackwardsTextIterator::range() const
{
    if (m_positionNode)
        return Range::create(m_positionNode->document(), m_positionNode, m_positionStartOffset, m_positionNode, m_positionEndOffset);

    return Range::create(m_startNode->document(), m_startNode, m_startOffset, m_startNode, m_startOffset);
}

// --------

CharacterIterator::CharacterIterator(const Range* range, TextIteratorBehaviorFlags behavior)
    : m_offset(0)
    , m_runOffset(0)
    , m_atBreak(true)
    , m_textIterator(range, behavior)
{
    initialize();
}

CharacterIterator::CharacterIterator(const Position& start, const Position& end, TextIteratorBehaviorFlags behavior)
    : m_offset(0)
    , m_runOffset(0)
    , m_atBreak(true)
    , m_textIterator(start, end, behavior)
{
    initialize();
}

void CharacterIterator::initialize()
{
    while (!atEnd() && !m_textIterator.length())
        m_textIterator.advance();
}

PassRefPtr<Range> CharacterIterator::range() const
{
    RefPtr<Range> r = m_textIterator.range();
    if (!m_textIterator.atEnd()) {
        if (m_textIterator.length() <= 1) {
            ASSERT(!m_runOffset);
        } else {
            Node* n = r->startContainer();
            ASSERT(n == r->endContainer());
            int offset = r->startOffset() + m_runOffset;
            r->setStart(n, offset, ASSERT_NO_EXCEPTION);
            r->setEnd(n, offset + 1, ASSERT_NO_EXCEPTION);
        }
    }
    return r.release();
}

void CharacterIterator::advance(int count)
{
    if (count <= 0) {
        ASSERT(!count);
        return;
    }

    m_atBreak = false;

    // easy if there is enough left in the current m_textIterator run
    int remaining = m_textIterator.length() - m_runOffset;
    if (count < remaining) {
        m_runOffset += count;
        m_offset += count;
        return;
    }

    // exhaust the current m_textIterator run
    count -= remaining;
    m_offset += remaining;

    // move to a subsequent m_textIterator run
    for (m_textIterator.advance(); !atEnd(); m_textIterator.advance()) {
        int runLength = m_textIterator.length();
        if (!runLength) {
            m_atBreak = true;
        } else {
            // see whether this is m_textIterator to use
            if (count < runLength) {
                m_runOffset = count;
                m_offset += count;
                return;
            }

            // exhaust this m_textIterator run
            count -= runLength;
            m_offset += runLength;
        }
    }

    // ran to the end of the m_textIterator... no more runs left
    m_atBreak = true;
    m_runOffset = 0;
}

static void calculateCharacterSubrange(CharacterIterator& it, int offset, int length, Position& startPosition, Position& endPosition)
{
    it.advance(offset);
    RefPtr<Range> start = it.range();
    startPosition = start->startPosition();

    if (length > 1)
        it.advance(length - 1);
    RefPtr<Range> end = it.range();
    endPosition = end->endPosition();
}

BackwardsCharacterIterator::BackwardsCharacterIterator(const Range* range, TextIteratorBehaviorFlags behavior)
    : m_offset(0)
    , m_runOffset(0)
    , m_atBreak(true)
    , m_textIterator(range, behavior)
{
    while (!atEnd() && !m_textIterator.length())
        m_textIterator.advance();
}

PassRefPtr<Range> BackwardsCharacterIterator::range() const
{
    RefPtr<Range> r = m_textIterator.range();
    if (!m_textIterator.atEnd()) {
        if (m_textIterator.length() <= 1) {
            ASSERT(!m_runOffset);
        } else {
            Node* n = r->startContainer();
            ASSERT(n == r->endContainer());
            int offset = r->endOffset() - m_runOffset;
            r->setStart(n, offset - 1, ASSERT_NO_EXCEPTION);
            r->setEnd(n, offset, ASSERT_NO_EXCEPTION);
        }
    }
    return r.release();
}

void BackwardsCharacterIterator::advance(int count)
{
    if (count <= 0) {
        ASSERT(!count);
        return;
    }

    m_atBreak = false;

    int remaining = m_textIterator.length() - m_runOffset;
    if (count < remaining) {
        m_runOffset += count;
        m_offset += count;
        return;
    }

    count -= remaining;
    m_offset += remaining;

    for (m_textIterator.advance(); !atEnd(); m_textIterator.advance()) {
        int runLength = m_textIterator.length();
        if (!runLength) {
            m_atBreak = true;
        } else {
            if (count < runLength) {
                m_runOffset = count;
                m_offset += count;
                return;
            }

            count -= runLength;
            m_offset += runLength;
        }
    }

    m_atBreak = true;
    m_runOffset = 0;
}

// --------

WordAwareIterator::WordAwareIterator(const Range* range)
    : m_didLookAhead(true) // So we consider the first chunk from the text iterator.
    , m_textIterator(range)
{
    advance(); // Get in position over the first chunk of text.
}

WordAwareIterator::~WordAwareIterator()
{
}

// FIXME: Performance could be bad for huge spans next to each other that don't fall on word boundaries.

void WordAwareIterator::advance()
{
    m_buffer.clear();

    // If last time we did a look-ahead, start with that looked-ahead chunk now
    if (!m_didLookAhead) {
        ASSERT(!m_textIterator.atEnd());
        m_textIterator.advance();
    }
    m_didLookAhead = false;

    // Go to next non-empty chunk.
    while (!m_textIterator.atEnd() && !m_textIterator.length())
        m_textIterator.advance();

    m_range = m_textIterator.range();

    if (m_textIterator.atEnd())
        return;

    while (1) {
        // If this chunk ends in whitespace we can just use it as our chunk.
        if (isSpaceOrNewline(m_textIterator.characterAt(m_textIterator.length() - 1)))
            return;

        // If this is the first chunk that failed, save it in m_buffer before look ahead.
        if (m_buffer.isEmpty())
            m_textIterator.appendTextTo(m_buffer);

        // Look ahead to next chunk. If it is whitespace or a break, we can use the previous stuff
        m_textIterator.advance();
        if (m_textIterator.atEnd() || !m_textIterator.length() || isSpaceOrNewline(m_textIterator.characterAt(0))) {
            m_didLookAhead = true;
            return;
        }

        // Start gobbling chunks until we get to a suitable stopping point
        m_textIterator.appendTextTo(m_buffer);
        m_range->setEnd(m_textIterator.range()->endContainer(), m_textIterator.range()->endOffset(), IGNORE_EXCEPTION);
    }
}

int WordAwareIterator::length() const
{
    if (!m_buffer.isEmpty())
        return m_buffer.size();
    return m_textIterator.length();
}

String WordAwareIterator::substring(unsigned position, unsigned length) const
{
    if (!m_buffer.isEmpty())
        return String(m_buffer.data() + position, length);
    return m_textIterator.substring(position, length);
}

UChar WordAwareIterator::characterAt(unsigned index) const
{
    if (!m_buffer.isEmpty())
        return m_buffer[index];
    return m_textIterator.characterAt(index);
}

// --------

static const size_t minimumSearchBufferSize = 8192;

#if ENABLE(ASSERT)
static bool searcherInUse;
#endif

static UStringSearch* createSearcher()
{
    // Provide a non-empty pattern and non-empty text so usearch_open will not fail,
    // but it doesn't matter exactly what it is, since we don't perform any searches
    // without setting both the pattern and the text.
    UErrorCode status = U_ZERO_ERROR;
    String searchCollatorName = currentSearchLocaleID() + String("@collation=search");
    UStringSearch* searcher = usearch_open(&newlineCharacter, 1, &newlineCharacter, 1, searchCollatorName.utf8().data(), 0, &status);
    ASSERT(status == U_ZERO_ERROR || status == U_USING_FALLBACK_WARNING || status == U_USING_DEFAULT_WARNING);
    return searcher;
}

static UStringSearch* searcher()
{
    static UStringSearch* searcher = createSearcher();
    return searcher;
}

static inline void lockSearcher()
{
#if ENABLE(ASSERT)
    ASSERT(!searcherInUse);
    searcherInUse = true;
#endif
}

static inline void unlockSearcher()
{
#if ENABLE(ASSERT)
    ASSERT(searcherInUse);
    searcherInUse = false;
#endif
}

inline SearchBuffer::SearchBuffer(const String& target, FindOptions options)
    : m_options(options)
    , m_prefixLength(0)
    , m_numberOfCharactersJustAppended(0)
    , m_atBreak(true)
    , m_needsMoreContext(options & AtWordStarts)
    , m_targetRequiresKanaWorkaround(containsKanaLetters(target))
{
    ASSERT(!target.isEmpty());
    target.appendTo(m_target);

    // FIXME: We'd like to tailor the searcher to fold quote marks for us instead
    // of doing it in a separate replacement pass here, but ICU doesn't offer a way
    // to add tailoring on top of the locale-specific tailoring as of this writing.
    foldQuoteMarksAndSoftHyphens(m_target.data(), m_target.size());

    size_t targetLength = m_target.size();
    m_buffer.reserveInitialCapacity(std::max(targetLength * 8, minimumSearchBufferSize));
    m_overlap = m_buffer.capacity() / 4;

    if ((m_options & AtWordStarts) && targetLength) {
        UChar32 targetFirstCharacter;
        U16_GET(m_target.data(), 0, 0, targetLength, targetFirstCharacter);
        // Characters in the separator category never really occur at the beginning of a word,
        // so if the target begins with such a character, we just ignore the AtWordStart option.
        if (isSeparator(targetFirstCharacter)) {
            m_options &= ~AtWordStarts;
            m_needsMoreContext = false;
        }
    }

    // Grab the single global searcher.
    // If we ever have a reason to do more than once search buffer at once, we'll have
    // to move to multiple searchers.
    lockSearcher();

    UStringSearch* searcher = blink::searcher();
    UCollator* collator = usearch_getCollator(searcher);

    UCollationStrength strength = m_options & CaseInsensitive ? UCOL_PRIMARY : UCOL_TERTIARY;
    if (ucol_getStrength(collator) != strength) {
        ucol_setStrength(collator, strength);
        usearch_reset(searcher);
    }

    UErrorCode status = U_ZERO_ERROR;
    usearch_setPattern(searcher, m_target.data(), targetLength, &status);
    ASSERT(status == U_ZERO_ERROR);

    // The kana workaround requires a normalized copy of the target string.
    if (m_targetRequiresKanaWorkaround)
        normalizeCharactersIntoNFCForm(m_target.data(), m_target.size(), m_normalizedTarget);
}

inline SearchBuffer::~SearchBuffer()
{
    // Leave the static object pointing to a valid string.
    UErrorCode status = U_ZERO_ERROR;
    usearch_setPattern(blink::searcher(), &newlineCharacter, 1, &status);
    ASSERT(status == U_ZERO_ERROR);

    unlockSearcher();
}

template<typename CharType>
inline void SearchBuffer::append(const CharType* characters, size_t length)
{
    ASSERT(length);

    if (m_atBreak) {
        m_buffer.shrink(0);
        m_prefixLength = 0;
        m_atBreak = false;
    } else if (m_buffer.size() == m_buffer.capacity()) {
        memcpy(m_buffer.data(), m_buffer.data() + m_buffer.size() - m_overlap, m_overlap * sizeof(UChar));
        m_prefixLength -= std::min(m_prefixLength, m_buffer.size() - m_overlap);
        m_buffer.shrink(m_overlap);
    }

    size_t oldLength = m_buffer.size();
    size_t usableLength = std::min(m_buffer.capacity() - oldLength, length);
    ASSERT(usableLength);
    m_buffer.resize(oldLength + usableLength);
    UChar* destination = m_buffer.data() + oldLength;
    StringImpl::copyChars(destination, characters, usableLength);
    foldQuoteMarksAndSoftHyphens(destination, usableLength);
    m_numberOfCharactersJustAppended = usableLength;
}

inline bool SearchBuffer::needsMoreContext() const
{
    return m_needsMoreContext;
}

inline void SearchBuffer::prependContext(const UChar* characters, size_t length)
{
    ASSERT(m_needsMoreContext);
    ASSERT(m_prefixLength == m_buffer.size());

    if (!length)
        return;

    m_atBreak = false;

    size_t wordBoundaryContextStart = length;
    if (wordBoundaryContextStart) {
        U16_BACK_1(characters, 0, wordBoundaryContextStart);
        wordBoundaryContextStart = startOfLastWordBoundaryContext(characters, wordBoundaryContextStart);
    }

    size_t usableLength = std::min(m_buffer.capacity() - m_prefixLength, length - wordBoundaryContextStart);
    m_buffer.prepend(characters + length - usableLength, usableLength);
    m_prefixLength += usableLength;

    if (wordBoundaryContextStart || m_prefixLength == m_buffer.capacity())
        m_needsMoreContext = false;
}

inline bool SearchBuffer::atBreak() const
{
    return m_atBreak;
}

inline void SearchBuffer::reachedBreak()
{
    m_atBreak = true;
}

inline bool SearchBuffer::isBadMatch(const UChar* match, size_t matchLength) const
{
    // This function implements the kana workaround. If usearch treats
    // it as a match, but we do not want to, then it's a "bad match".
    if (!m_targetRequiresKanaWorkaround)
        return false;

    // Normalize into a match buffer. We reuse a single buffer rather than
    // creating a new one each time.
    normalizeCharactersIntoNFCForm(match, matchLength, m_normalizedMatch);

    return !checkOnlyKanaLettersInStrings(m_normalizedTarget.begin(), m_normalizedTarget.size(), m_normalizedMatch.begin(), m_normalizedMatch.size());
}

inline bool SearchBuffer::isWordStartMatch(size_t start, size_t length) const
{
    ASSERT(m_options & AtWordStarts);

    if (!start)
        return true;

    int size = m_buffer.size();
    int offset = start;
    UChar32 firstCharacter;
    U16_GET(m_buffer.data(), 0, offset, size, firstCharacter);

    if (m_options & TreatMedialCapitalAsWordStart) {
        UChar32 previousCharacter;
        U16_PREV(m_buffer.data(), 0, offset, previousCharacter);

        if (isSeparator(firstCharacter)) {
            // The start of a separator run is a word start (".org" in "webkit.org").
            if (!isSeparator(previousCharacter))
                return true;
        } else if (isASCIIUpper(firstCharacter)) {
            // The start of an uppercase run is a word start ("Kit" in "WebKit").
            if (!isASCIIUpper(previousCharacter))
                return true;
            // The last character of an uppercase run followed by a non-separator, non-digit
            // is a word start ("Request" in "XMLHTTPRequest").
            offset = start;
            U16_FWD_1(m_buffer.data(), offset, size);
            UChar32 nextCharacter = 0;
            if (offset < size)
                U16_GET(m_buffer.data(), 0, offset, size, nextCharacter);
            if (!isASCIIUpper(nextCharacter) && !isASCIIDigit(nextCharacter) && !isSeparator(nextCharacter))
                return true;
        } else if (isASCIIDigit(firstCharacter)) {
            // The start of a digit run is a word start ("2" in "WebKit2").
            if (!isASCIIDigit(previousCharacter))
                return true;
        } else if (isSeparator(previousCharacter) || isASCIIDigit(previousCharacter)) {
            // The start of a non-separator, non-uppercase, non-digit run is a word start,
            // except after an uppercase. ("org" in "webkit.org", but not "ore" in "WebCore").
            return true;
        }
    }

    // Chinese and Japanese lack word boundary marks, and there is no clear agreement on what constitutes
    // a word, so treat the position before any CJK character as a word start.
    if (Character::isCJKIdeographOrSymbol(firstCharacter))
        return true;

    size_t wordBreakSearchStart = start + length;
    while (wordBreakSearchStart > start)
        wordBreakSearchStart = findNextWordFromIndex(m_buffer.data(), m_buffer.size(), wordBreakSearchStart, false /* backwards */);
    return wordBreakSearchStart == start;
}

inline size_t SearchBuffer::search(size_t& start)
{
    size_t size = m_buffer.size();
    if (m_atBreak) {
        if (!size)
            return 0;
    } else {
        if (size != m_buffer.capacity())
            return 0;
    }

    UStringSearch* searcher = blink::searcher();

    UErrorCode status = U_ZERO_ERROR;
    usearch_setText(searcher, m_buffer.data(), size, &status);
    ASSERT(status == U_ZERO_ERROR);

    usearch_setOffset(searcher, m_prefixLength, &status);
    ASSERT(status == U_ZERO_ERROR);

    int matchStart = usearch_next(searcher, &status);
    ASSERT(status == U_ZERO_ERROR);

nextMatch:
    if (!(matchStart >= 0 && static_cast<size_t>(matchStart) < size)) {
        ASSERT(matchStart == USEARCH_DONE);
        return 0;
    }

    // Matches that start in the overlap area are only tentative.
    // The same match may appear later, matching more characters,
    // possibly including a combining character that's not yet in the buffer.
    if (!m_atBreak && static_cast<size_t>(matchStart) >= size - m_overlap) {
        size_t overlap = m_overlap;
        if (m_options & AtWordStarts) {
            // Ensure that there is sufficient context before matchStart the next time around for
            // determining if it is at a word boundary.
            int wordBoundaryContextStart = matchStart;
            U16_BACK_1(m_buffer.data(), 0, wordBoundaryContextStart);
            wordBoundaryContextStart = startOfLastWordBoundaryContext(m_buffer.data(), wordBoundaryContextStart);
            overlap = std::min(size - 1, std::max(overlap, size - wordBoundaryContextStart));
        }
        memcpy(m_buffer.data(), m_buffer.data() + size - overlap, overlap * sizeof(UChar));
        m_prefixLength -= std::min(m_prefixLength, size - overlap);
        m_buffer.shrink(overlap);
        return 0;
    }

    size_t matchedLength = usearch_getMatchedLength(searcher);
    ASSERT_WITH_SECURITY_IMPLICATION(matchStart + matchedLength <= size);

    // If this match is "bad", move on to the next match.
    if (isBadMatch(m_buffer.data() + matchStart, matchedLength) || ((m_options & AtWordStarts) && !isWordStartMatch(matchStart, matchedLength))) {
        matchStart = usearch_next(searcher, &status);
        ASSERT(status == U_ZERO_ERROR);
        goto nextMatch;
    }

    size_t newSize = size - (matchStart + 1);
    memmove(m_buffer.data(), m_buffer.data() + matchStart + 1, newSize * sizeof(UChar));
    m_prefixLength -= std::min<size_t>(m_prefixLength, matchStart + 1);
    m_buffer.shrink(newSize);

    start = size - matchStart;
    return matchedLength;
}

// --------

int TextIterator::rangeLength(const Range* r, bool forSelectionPreservation)
{
    int length = 0;
    TextIteratorBehaviorFlags behaviorFlags = TextIteratorEmitsObjectReplacementCharacter;
    if (forSelectionPreservation)
        behaviorFlags |= TextIteratorEmitsCharactersBetweenAllVisiblePositions;
    for (TextIterator it(r, behaviorFlags); !it.atEnd(); it.advance())
        length += it.length();

    return length;
}

PassRefPtr<Range> TextIterator::subrange(Range* entireRange, int characterOffset, int characterCount)
{
    CharacterIterator entireRangeIterator(entireRange);
    Position start;
    Position end;
    calculateCharacterSubrange(entireRangeIterator, characterOffset, characterCount, start, end);
    return Range::create(entireRange->ownerDocument(), start, end);
}

// --------

String plainText(const Range* r, TextIteratorBehaviorFlags behavior)
{
    // The initial buffer size can be critical for performance: https://bugs.webkit.org/show_bug.cgi?id=81192
    static const unsigned initialCapacity = 1 << 15;

    unsigned bufferLength = 0;
    StringBuilder builder;
    builder.reserveCapacity(initialCapacity);

    for (TextIterator it(r, behavior); !it.atEnd(); it.advance()) {
        it.appendTextToStringBuilder(builder);
        bufferLength += it.length();
    }

    if (!bufferLength)
        return emptyString();

    return builder.toString();
}

static PassRefPtr<Range> collapsedToBoundary(const Range* range, bool forward)
{
    RefPtr<Range> result = range->cloneRange();
    result->collapse(!forward);
    return result.release();
}

// Check if there's any unpaird surrogate code point.
// Non-character code points are not checked.
static bool isValidUTF16(const String& s)
{
    if (s.is8Bit())
        return true;
    const UChar* ustr = s.characters16();
    size_t length = s.length();
    size_t position = 0;
    while (position < length) {
        UChar32 character;
        U16_NEXT(ustr, position, length, character);
        if (U_IS_SURROGATE(character))
            return false;
    }
    return true;
}

static size_t findPlainTextInternal(CharacterIterator& it, const String& target, FindOptions options, size_t& matchStart)
{
    matchStart = 0;
    size_t matchLength = 0;

    if (!isValidUTF16(target))
        return 0;

    SearchBuffer buffer(target, options);

    if (buffer.needsMoreContext()) {
        RefPtr<Range> startRange = it.range();
        RefPtr<Range> beforeStartRange = startRange->ownerDocument().createRange();
        beforeStartRange->setEnd(startRange->startContainer(), startRange->startOffset(), IGNORE_EXCEPTION);
        for (SimplifiedBackwardsTextIterator backwardsIterator(beforeStartRange.get()); !backwardsIterator.atEnd(); backwardsIterator.advance()) {
            Vector<UChar, 1024> characters;
            backwardsIterator.prependTextTo(characters);
            buffer.prependContext(characters.data(), characters.size());
            if (!buffer.needsMoreContext())
                break;
        }
    }

    while (!it.atEnd()) {
        it.appendTextTo(buffer);
        it.advance(buffer.numberOfCharactersJustAppended());
tryAgain:
        size_t matchStartOffset;
        if (size_t newMatchLength = buffer.search(matchStartOffset)) {
            // Note that we found a match, and where we found it.
            size_t lastCharacterInBufferOffset = it.characterOffset();
            ASSERT(lastCharacterInBufferOffset >= matchStartOffset);
            matchStart = lastCharacterInBufferOffset - matchStartOffset;
            matchLength = newMatchLength;
            // If searching forward, stop on the first match.
            // If searching backward, don't stop, so we end up with the last match.
            if (!(options & Backwards))
                break;
            goto tryAgain;
        }
        if (it.atBreak() && !buffer.atBreak()) {
            buffer.reachedBreak();
            goto tryAgain;
        }
    }

    return matchLength;
}

static const TextIteratorBehaviorFlags iteratorFlagsForFindPlainText = TextIteratorEntersAuthorShadowRoots;

PassRefPtr<Range> findPlainText(const Range* range, const String& target, FindOptions options)
{
    // First, find the text.
    size_t matchStart;
    size_t matchLength;
    {
        CharacterIterator findIterator(range, iteratorFlagsForFindPlainText);
        matchLength = findPlainTextInternal(findIterator, target, options, matchStart);
        if (!matchLength)
            return collapsedToBoundary(range, !(options & Backwards));
    }

    // Then, find the document position of the start and the end of the text.
    CharacterIterator computeRangeIterator(range, iteratorFlagsForFindPlainText);
    Position resultStart;
    Position resultEnd;
    calculateCharacterSubrange(computeRangeIterator, matchStart, matchLength, resultStart, resultEnd);
    return Range::create(range->ownerDocument(), resultStart, resultEnd);
}

void findPlainText(const Position& inputStart, const Position& inputEnd, const String& target, FindOptions options, Position& resultStart, Position& resultEnd)
{
    resultStart.clear();
    resultEnd.clear();
    // CharacterIterator requires renderers to be up-to-date.
    if (!inputStart.inDocument())
        return;
    ASSERT(inputStart.document() == inputEnd.document());

    // FIXME: Reduce the code duplication with above (but how?).
    size_t matchStart;
    size_t matchLength;
    {
        CharacterIterator findIterator(inputStart, inputEnd, iteratorFlagsForFindPlainText);
        matchLength = findPlainTextInternal(findIterator, target, options, matchStart);
        if (!matchLength) {
            const Position& collapseTo = options & Backwards ? inputStart : inputEnd;
            resultStart = collapseTo;
            resultEnd = collapseTo;
            return;
        }
    }

    CharacterIterator computeRangeIterator(inputStart, inputEnd, iteratorFlagsForFindPlainText);
    calculateCharacterSubrange(computeRangeIterator, matchStart, matchLength, resultStart, resultEnd);
}

}
