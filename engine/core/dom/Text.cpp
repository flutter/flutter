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

#include "sky/engine/config.h"
#include "sky/engine/core/dom/Text.h"

#include "sky/engine/bindings/core/v8/ExceptionState.h"
#include "sky/engine/bindings/core/v8/ExceptionStatePlaceholder.h"
#include "sky/engine/core/css/resolver/StyleResolver.h"
#include "sky/engine/core/dom/ExceptionCode.h"
#include "sky/engine/core/dom/NodeRenderStyle.h"
#include "sky/engine/core/dom/NodeRenderingTraversal.h"
#include "sky/engine/core/dom/NodeTraversal.h"
#include "sky/engine/core/dom/RenderTreeBuilder.h"
#include "sky/engine/core/dom/shadow/ShadowRoot.h"
#include "sky/engine/core/events/ScopedEventQueue.h"
#include "sky/engine/core/rendering/RenderText.h"
#include "sky/engine/wtf/text/CString.h"
#include "sky/engine/wtf/text/StringBuilder.h"

namespace blink {

PassRefPtr<Text> Text::create(Document& document, const String& data)
{
    return adoptRef(new Text(document, data, CreateText));
}

PassRefPtr<Text> Text::createEditingText(Document& document, const String& data)
{
    return adoptRef(new Text(document, data, CreateEditingText));
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
        if (parent.isRenderBlock() && !parent.isRenderParagraph() && (!prev || !prev->isInline()))
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
            renderer->setStyle(document().styleResolver().styleForText(this));
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
