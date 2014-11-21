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

#include "sky/engine/config.h"
#include "sky/engine/public/web/WebRange.h"

#include "sky/engine/bindings/core/v8/ExceptionState.h"
#include "sky/engine/bindings/core/v8/ExceptionStatePlaceholder.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/Element.h"
#include "sky/engine/core/dom/Range.h"
#include "sky/engine/core/dom/shadow/ShadowRoot.h"
#include "sky/engine/core/editing/FrameSelection.h"
#include "sky/engine/core/editing/PlainTextRange.h"
#include "sky/engine/core/frame/FrameView.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/public/platform/WebString.h"
#include "sky/engine/public/web/WebExceptionCode.h"
#include "sky/engine/public/web/WebNode.h"
#include "sky/engine/web/WebLocalFrameImpl.h"
#include "sky/engine/wtf/PassRefPtr.h"

namespace blink {

void WebRange::reset()
{
    m_private.reset();
}

void WebRange::assign(const WebRange& other)
{
    m_private = other.m_private;
}

int WebRange::startOffset() const
{
    return m_private->startOffset();
}

int WebRange::endOffset() const
{
    return m_private->endOffset();
}

WebNode WebRange::startContainer(WebExceptionCode& exceptionCode) const
{
    // FIXME: Create a wrapper class that just sets the internal int.
    RefPtr<Node> node(m_private->startContainer());
    exceptionCode = 0;
    return node.release();
}

WebNode WebRange::endContainer(WebExceptionCode& exceptionCode) const
{
    // FIXME: Create a wrapper class that just sets the internal int.
    RefPtr<Node> node(m_private->endContainer());
    exceptionCode = 0;
    return node.release();
}

WebString WebRange::toHTMLText() const
{
    return m_private->toHTML();
}

WebString WebRange::toPlainText() const
{
    return m_private->text();
}

WebRange WebRange::expandedToParagraph() const
{
    WebRange copy(*this);
    copy.m_private->expand("block", IGNORE_EXCEPTION);
    return copy;
}

// static
WebRange WebRange::fromDocumentRange(WebLocalFrame* frame, int start, int length)
{
    LocalFrame* webFrame = toWebLocalFrameImpl(frame)->frame();
    Element* selectionRoot = webFrame->selection().rootEditableElement();
    ContainerNode* scope = selectionRoot ? selectionRoot : webFrame->document()->documentElement();
    return PlainTextRange(start, start + length).createRange(*scope);
}

WebRange::WebRange(const PassRefPtr<Range>& range)
    : m_private(range)
{
}

WebRange::operator PassRefPtr<Range>() const
{
    return m_private.get();
}

} // namespace blink
