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

#include "config.h"
#include "public/web/WebDocument.h"

#include "bindings/core/v8/Dictionary.h"
#include "bindings/core/v8/ExceptionState.h"
#include "bindings/core/v8/ScriptState.h"
#include "bindings/core/v8/ScriptValue.h"
#include "core/css/StyleSheetContents.h"
#include "core/dom/Document.h"
#include "core/dom/Element.h"
#include "core/dom/StyleEngine.h"
#include "core/events/Event.h"
#include "core/html/HTMLElement.h"
#include "core/rendering/RenderObject.h"
#include "core/rendering/RenderView.h"
#include "public/platform/WebURL.h"
#include "public/web/WebDOMEvent.h"
#include "public/web/WebDocumentType.h"
#include "public/web/WebElement.h"
#include "web/WebLocalFrameImpl.h"
#include "wtf/PassRefPtr.h"
#include <v8.h>

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

WebDOMEvent WebDocument::createEvent(const WebString& eventType)
{
    TrackExceptionState exceptionState;
    WebDOMEvent event(unwrap<Document>()->createEvent(eventType, exceptionState));
    if (exceptionState.hadException())
        return WebDOMEvent();
    return event;
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

WebSize WebDocument::scrollOffset() const
{
    if (FrameView* view = constUnwrap<Document>()->view())
        return view->scrollOffset();
    return WebSize();
}

WebSize WebDocument::minimumScrollOffset() const
{
    if (FrameView* view = constUnwrap<Document>()->view())
        return toIntSize(view->minimumScrollPosition());
    return WebSize();
}

WebSize WebDocument::maximumScrollOffset() const
{
    if (FrameView* view = constUnwrap<Document>()->view())
        return toIntSize(view->maximumScrollPosition());
    return WebSize();
}

v8::Handle<v8::Value> WebDocument::registerEmbedderCustomElement(const WebString& name, v8::Handle<v8::Value> options, WebExceptionCode& ec)
{
    v8::Isolate* isolate = v8::Isolate::GetCurrent();
    Document* document = unwrap<Document>();
    Dictionary dictionary(options, isolate);
    TrackExceptionState exceptionState;
    ScriptValue constructor = document->registerElement(ScriptState::current(isolate), name, dictionary, exceptionState, CustomElement::EmbedderNames);
    ec = exceptionState.code();
    if (exceptionState.hadException())
        return v8::Handle<v8::Value>();
    return constructor.v8Value();
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
