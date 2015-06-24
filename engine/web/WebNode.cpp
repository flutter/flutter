/*
 * Copyright (C) 2009 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "sky/engine/public/web/WebNode.h"

#include "sky/engine/bindings/exception_state.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/Element.h"
#include "sky/engine/core/dom/Node.h"
#include "sky/engine/core/dom/NodeList.h"
#include "sky/engine/core/events/Event.h"
#include "sky/engine/core/html/HTMLElement.h"
#include "sky/engine/core/rendering/RenderObject.h"
#include "sky/engine/platform/Widget.h"
#include "sky/engine/public/platform/WebString.h"
#include "sky/engine/public/platform/WebVector.h"
#include "sky/engine/public/web/WebDocument.h"
#include "sky/engine/public/web/WebElement.h"
#include "sky/engine/web/FrameLoaderClientImpl.h"
#include "sky/engine/web/WebLocalFrameImpl.h"

namespace blink {

void WebNode::reset()
{
    m_private.reset();
}

void WebNode::assign(const WebNode& other)
{
    m_private = other.m_private;
}

bool WebNode::equals(const WebNode& n) const
{
    return m_private.get() == n.m_private.get();
}

bool WebNode::lessThan(const WebNode& n) const
{
    return m_private.get() < n.m_private.get();
}

WebNode::NodeType WebNode::nodeType() const
{
    return static_cast<NodeType>(m_private->nodeType());
}

WebNode WebNode::parentNode() const
{
    return WebNode(const_cast<ContainerNode*>(m_private->parentNode()));
}

WebString WebNode::nodeName() const
{
    return m_private->nodeName();
}

WebDocument WebNode::document() const
{
    return WebDocument(&m_private->document());
}

WebNode WebNode::firstChild() const
{
    return WebNode(m_private->firstChild());
}

WebNode WebNode::lastChild() const
{
    return WebNode(m_private->lastChild());
}

WebNode WebNode::previousSibling() const
{
    return WebNode(m_private->previousSibling());
}

WebNode WebNode::nextSibling() const
{
    return WebNode(m_private->nextSibling());
}

bool WebNode::hasChildNodes() const
{
    return m_private->hasChildren();
}

bool WebNode::isLink() const
{
    return m_private->isLink();
}

bool WebNode::isTextNode() const
{
    return m_private->isTextNode();
}

bool WebNode::isFocusable() const
{
    if (!m_private->isElementNode())
        return false;
    m_private->document().updateLayout();
    return toElement(m_private.get())->isFocusable();
}

bool WebNode::isContentEditable() const
{
    return m_private->isContentEditable();
}

bool WebNode::isElementNode() const
{
    return m_private->isElementNode();
}

WebElement WebNode::querySelector(const WebString& tag, WebExceptionCode& ec) const
{
    TrackExceptionState exceptionState;
    WebElement element;
    if (m_private->isContainerNode())
        element = toContainerNode(m_private.get())->querySelector(tag, exceptionState);
    ec = exceptionState.code();
    return element;
}

WebElement WebNode::rootEditableElement() const
{
    return WebElement(m_private->rootEditableElement());
}

bool WebNode::focused() const
{
    return m_private->focused();
}

bool WebNode::remove()
{
    TrackExceptionState exceptionState;
    m_private->remove(exceptionState);
    return !exceptionState.had_exception();
}

bool WebNode::containsIncludingShadowDOM(const WebNode& other) const
{
    return m_private->containsIncludingShadowDOM(other.m_private.get());
}

WebElement WebNode::shadowHost() const
{
    if (isNull())
        return WebElement();
    const Node* coreNode = constUnwrap<Node>();
    return WebElement(coreNode->shadowHost());
}

WebNode::WebNode(const PassRefPtr<Node>& node)
    : m_private(node)
{
}

WebNode& WebNode::operator=(const PassRefPtr<Node>& node)
{
    m_private = node;
    return *this;
}

WebNode::operator PassRefPtr<Node>() const
{
    return m_private.get();
}

} // namespace blink
