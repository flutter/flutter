/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2003, 2004, 2005, 2006, 2007, 2008, 2009 Apple Inc. All rights reserved.
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

#include "config.h"
#include "core/dom/Text.h"

#include "bindings/core/v8/ExceptionState.h"
#include "bindings/core/v8/ExceptionStatePlaceholder.h"
#include "core/css/resolver/StyleResolver.h"
#include "core/dom/ExceptionCode.h"
#include "core/dom/NodeRenderStyle.h"
#include "core/dom/NodeRenderingTraversal.h"
#include "core/dom/NodeTraversal.h"
#include "core/dom/RenderTreeBuilder.h"
#include "core/dom/shadow/ShadowRoot.h"
#include "core/events/ScopedEventQueue.h"
#include "core/rendering/RenderCombineText.h"
#include "core/rendering/RenderText.h"
#include "wtf/text/CString.h"
#include "wtf/text/StringBuilder.h"

namespace blink {

PassRefPtr<Text> Text::create(Document& document, const String& data)
{
    return adoptRef(new Text(document, data, CreateText));
}

PassRefPtr<Text> Text::createEditingText(Document& document, const String& data)
{
    return adoptRef(new Text(document, data, CreateEditingText));
}

PassRefPtr<Node> Text::mergeNextSiblingNodesIfPossible()
{
    RefPtr<Node> protect(this);

    // Remove empty text nodes.
    if (!length()) {
        // Care must be taken to get the next node before removing the current node.
        RefPtr<Node> nextNode(NodeTraversal::nextPostOrder(*this));
        remove(IGNORE_EXCEPTION);
        return nextNode.release();
    }

    // Merge text nodes.
    while (Node* nextSibling = this->nextSibling()) {
        if (nextSibling->nodeType() != TEXT_NODE)
            break;

        RefPtr<Text> nextText = toText(nextSibling);

        // Remove empty text nodes.
        if (!nextText->length()) {
            nextText->remove(IGNORE_EXCEPTION);
            continue;
        }

        // Both non-empty text nodes. Merge them.
        unsigned offset = length();
        String nextTextData = nextText->data();
        String oldTextData = data();
        setDataWithoutUpdate(data() + nextTextData);
        updateTextRenderer(oldTextData.length(), 0);

        // Empty nextText for layout update.
        nextText->setDataWithoutUpdate(emptyString());
        nextText->updateTextRenderer(0, nextTextData.length());

        document().didMergeTextNodes(*nextText, offset);

        // Restore nextText for mutation event.
        nextText->setDataWithoutUpdate(nextTextData);
        nextText->updateTextRenderer(0, 0);

        didModifyData(oldTextData);
        nextText->remove(IGNORE_EXCEPTION);
    }

    return NodeTraversal::nextPostOrder(*this);
}

PassRefPtr<Text> Text::splitText(unsigned offset, ExceptionState& exceptionState)
{
    // IndexSizeError: Raised if the specified offset is negative or greater than
    // the number of 16-bit units in data.
    if (offset > length()) {
        exceptionState.throwDOMException(IndexSizeError, "The offset " + String::number(offset) + " is larger than the Text node's length.");
        return nullptr;
    }

    EventQueueScope scope;
    String oldStr = data();
    RefPtr<Text> newText = cloneWithData(oldStr.substring(offset));
    setDataWithoutUpdate(oldStr.substring(0, offset));

    didModifyData(oldStr);

    if (parentNode())
        parentNode()->insertBefore(newText.get(), nextSibling(), exceptionState);
    if (exceptionState.hadException())
        return nullptr;

    if (renderer())
        renderer()->setTextWithOffset(dataImpl(), 0, oldStr.length());

    if (parentNode())
        document().didSplitTextNode(*this);

    return newText.release();
}

static const Text* earliestLogicallyAdjacentTextNode(const Text* t)
{
    for (const Node* n = t->previousSibling(); n; n = n->previousSibling()) {
        Node::NodeType type = n->nodeType();
        if (type == Node::TEXT_NODE) {
            t = toText(n);
            continue;
        }

        break;
    }
    return t;
}

static const Text* latestLogicallyAdjacentTextNode(const Text* t)
{
    for (const Node* n = t->nextSibling(); n; n = n->nextSibling()) {
        Node::NodeType type = n->nodeType();
        if (type == Node::TEXT_NODE) {
            t = toText(n);
            continue;
        }

        break;
    }
    return t;
}

String Text::wholeText() const
{
    const Text* startText = earliestLogicallyAdjacentTextNode(this);
    const Text* endText = latestLogicallyAdjacentTextNode(this);

    Node* onePastEndText = endText->nextSibling();
    unsigned resultLength = 0;
    for (const Node* n = startText; n != onePastEndText; n = n->nextSibling()) {
        if (!n->isTextNode())
            continue;
        const String& data = toText(n)->data();
        if (std::numeric_limits<unsigned>::max() - data.length() < resultLength)
            CRASH();
        resultLength += data.length();
    }
    StringBuilder result;
    result.reserveCapacity(resultLength);
    for (const Node* n = startText; n != onePastEndText; n = n->nextSibling()) {
        if (!n->isTextNode())
            continue;
        result.append(toText(n)->data());
    }
    ASSERT(result.length() == resultLength);

    return result.toString();
}

PassRefPtr<Text> Text::replaceWholeText(const String& newText)
{
    // Remove all adjacent text nodes, and replace the contents of this one.

    // Protect startText and endText against mutation event handlers removing the last ref
    RefPtr<Text> startText = const_cast<Text*>(earliestLogicallyAdjacentTextNode(this));
    RefPtr<Text> endText = const_cast<Text*>(latestLogicallyAdjacentTextNode(this));

    RefPtr<Text> protectedThis(this); // Mutation event handlers could cause our last ref to go away
    RefPtr<ContainerNode> parent = parentNode(); // Protect against mutation handlers moving this node during traversal
    for (RefPtr<Node> n = startText; n && n != this && n->isTextNode() && n->parentNode() == parent;) {
        RefPtr<Node> nodeToRemove(n.release());
        n = nodeToRemove->nextSibling();
        parent->removeChild(nodeToRemove.get(), IGNORE_EXCEPTION);
    }

    if (this != endText) {
        Node* onePastEndText = endText->nextSibling();
        for (RefPtr<Node> n = nextSibling(); n && n != onePastEndText && n->isTextNode() && n->parentNode() == parent;) {
            RefPtr<Node> nodeToRemove(n.release());
            n = nodeToRemove->nextSibling();
            parent->removeChild(nodeToRemove.get(), IGNORE_EXCEPTION);
        }
    }

    if (newText.isEmpty()) {
        if (parent && parentNode() == parent)
            parent->removeChild(this, IGNORE_EXCEPTION);
        return nullptr;
    }

    setData(newText);
    return protectedThis.release();
}

String Text::nodeName() const
{
    return "#text";
}

Node::NodeType Text::nodeType() const
{
    return TEXT_NODE;
}

PassRefPtr<Node> Text::cloneNode(bool /*deep*/)
{
    return cloneWithData(data());
}

bool Text::textRendererIsNeeded(const RenderStyle& style, const RenderObject& parent)
{
    if (isEditingText())
        return true;

    if (!length())
        return false;

    if (style.display() == NONE)
        return false;

    if (!containsOnlyWhitespace())
        return true;

    if (!parent.canHaveWhitespaceChildren())
        return false;

    if (style.preserveNewline()) // pre/pre-wrap/pre-line always make renderers.
        return true;

    const RenderObject* prev = NodeRenderingTraversal::previousSiblingRenderer(this);

    if (parent.isRenderInline()) {
        // <span><div/> <div/></span>
        if (prev && !prev->isInline())
            return false;
    } else {
        if (parent.isRenderBlock() && !parent.childrenInline() && (!prev || !prev->isInline()))
            return false;

        // Avoiding creation of a Renderer for the text node is a non-essential memory optimization.
        // So to avoid blowing up on very wide DOMs, we limit the number of siblings to visit.
        unsigned maxSiblingsToVisit = 50;

        RenderObject* first = parent.slowFirstChild();
        while (first && first->isFloatingOrOutOfFlowPositioned() && maxSiblingsToVisit--)
            first = first->nextSibling();
        if (!first || NodeRenderingTraversal::nextSiblingRenderer(this) == first)
            // Whitespace at the start of a block just goes away.  Don't even
            // make a render object for this text.
            return false;
    }
    return true;
}

RenderText* Text::createTextRenderer(RenderStyle* style)
{
    if (style->hasTextCombine())
        return new RenderCombineText(this, dataImpl());

    return new RenderText(this, dataImpl());
}

void Text::attach(const AttachContext& context)
{
    RenderTreeBuilder(this, context.resolvedStyle).createRendererForTextIfNeeded();
    CharacterData::attach(context);
}

void Text::recalcTextStyle(StyleRecalcChange change, Text* nextTextSibling)
{
    if (RenderText* renderer = this->renderer()) {
        if (change != NoChange || needsStyleRecalc())
            renderer->setStyle(document().ensureStyleResolver().styleForText(this));
        if (needsStyleRecalc())
            renderer->setText(dataImpl());
        clearNeedsStyleRecalc();
    } else if (needsStyleRecalc() || needsWhitespaceRenderer()) {
        reattach();
        if (this->renderer())
            reattachWhitespaceSiblings(nextTextSibling);
    }
}

// If a whitespace node had no renderer and goes through a recalcStyle it may
// need to create one if the parent style now has white-space: pre.
bool Text::needsWhitespaceRenderer()
{
    ASSERT(!renderer());
    if (RenderStyle* style = parentRenderStyle())
        return style->preserveNewline();
    return false;
}

void Text::updateTextRenderer(unsigned offsetOfReplacedData, unsigned lengthOfReplacedData, RecalcStyleBehavior recalcStyleBehavior)
{
    if (!inActiveDocument())
        return;
    RenderText* textRenderer = renderer();
    if (!textRenderer || !textRendererIsNeeded(*textRenderer->style(), *textRenderer->parent())) {
        lazyReattachIfAttached();
        // FIXME: Editing should be updated so this is not neccesary.
        if (recalcStyleBehavior == DeprecatedRecalcStyleImmediatlelyForEditing)
            document().updateRenderTreeIfNeeded();
        return;
    }
    textRenderer->setTextWithOffset(dataImpl(), offsetOfReplacedData, lengthOfReplacedData);
}

PassRefPtr<Text> Text::cloneWithData(const String& data)
{
    return create(document(), data);
}

#ifndef NDEBUG
void Text::formatForDebugger(char *buffer, unsigned length) const
{
    StringBuilder result;
    String s;

    result.append(nodeName());

    s = data();
    if (s.length() > 0) {
        if (result.length())
            result.appendLiteral("; ");
        result.appendLiteral("value=");
        result.append(s);
    }

    strncpy(buffer, result.toString().utf8().data(), length - 1);
}
#endif

} // namespace blink
