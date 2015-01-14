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
#include "sky/engine/public/web/WebDocument.h"

#include "sky/engine/bindings/core/v8/Dictionary.h"
#include "sky/engine/bindings/core/v8/ExceptionState.h"
#include "sky/engine/bindings/core/v8/ScriptState.h"
#include "sky/engine/bindings/core/v8/ScriptValue.h"
#include "sky/engine/core/animation/AnimationTimeline.h"
#include "sky/engine/core/css/StyleSheetContents.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/Element.h"
#include "sky/engine/core/dom/StyleEngine.h"
#include "sky/engine/core/events/Event.h"
#include "sky/engine/core/html/HTMLElement.h"
#include "sky/engine/core/rendering/RenderObject.h"
#include "sky/engine/core/rendering/RenderView.h"
#include "sky/engine/public/platform/WebURL.h"
#include "sky/engine/public/web/WebElement.h"
#include "sky/engine/web/WebLocalFrameImpl.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "v8/include/v8.h"

namespace blink {

WebURL WebDocument::url() const
{
    return constUnwrap<Document>()->url();
}

WebString WebDocument::encoding() const
{
    return constUnwrap<Document>()->encodingName();
}

WebString WebDocument::contentLanguage() const
{
    return constUnwrap<Document>()->contentLanguage();
}

WebString WebDocument::referrer() const
{
    return constUnwrap<Document>()->referrer();
}

WebURL WebDocument::openSearchDescriptionURL() const
{
    return const_cast<Document*>(constUnwrap<Document>())->openSearchDescriptionURL();
}

WebLocalFrame* WebDocument::frame() const
{
    return WebLocalFrameImpl::fromFrame(constUnwrap<Document>()->frame());
}

bool WebDocument::isHTMLDocument() const
{
    return constUnwrap<Document>()->isHTMLDocument();
}

WebElement WebDocument::documentElement() const
{
    return WebElement(constUnwrap<Document>()->documentElement());
}

WebString WebDocument::title() const
{
    return WebString(constUnwrap<Document>()->title());
}

WebURL WebDocument::completeURL(const WebString& partialURL) const
{
    return constUnwrap<Document>()->completeURL(partialURL);
}

WebElement WebDocument::getElementById(const WebString& id) const
{
    return WebElement(constUnwrap<Document>()->getElementById(id));
}

WebElement WebDocument::focusedElement() const
{
    return WebElement(constUnwrap<Document>()->focusedElement());
}

WebReferrerPolicy WebDocument::referrerPolicy() const
{
    return static_cast<WebReferrerPolicy>(constUnwrap<Document>()->referrerPolicy());
}

WebElement WebDocument::createElement(const WebString& tagName)
{
    TrackExceptionState exceptionState;
    WebElement element(unwrap<Document>()->createElement(tagName, exceptionState));
    if (exceptionState.hadException())
        return WebElement();
    return element;
}

void WebDocument::pauseAnimationsForTesting(double pauseTime) const {
    constUnwrap<Document>()->frame()->view()->updateLayoutAndStyleForPainting();
    constUnwrap<Document>()->timeline().pauseAnimationsForTesting(pauseTime);
}

WebDocument::WebDocument(const PassRefPtr<Document>& elem)
    : WebNode(elem)
{
}

WebDocument& WebDocument::operator=(const PassRefPtr<Document>& elem)
{
    m_private = elem;
    return *this;
}

WebDocument::operator PassRefPtr<Document>() const
{
    return toDocument(m_private.get());
}

} // namespace blink
