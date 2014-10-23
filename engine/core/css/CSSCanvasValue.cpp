/*
 * Copyright (C) 2008 Apple Inc.  All rights reserved.
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

#include "config.h"
#include "core/css/CSSCanvasValue.h"

#include "core/rendering/RenderObject.h"
#include "wtf/text/StringBuilder.h"

namespace blink {

CSSCanvasValue::~CSSCanvasValue()
{
#if !ENABLE(OILPAN)
    if (m_element)
        m_element->removeObserver(m_canvasObserver.get());
#endif
}

String CSSCanvasValue::customCSSText() const
{
    StringBuilder result;
    result.appendLiteral("-webkit-canvas(");
    result.append(m_name);
    result.append(')');
    return result.toString();
}

void CSSCanvasValue::canvasChanged(HTMLCanvasElement*, const FloatRect& changedRect)
{
    IntRect imageChangeRect = enclosingIntRect(changedRect);
    RenderObjectSizeCountMap::const_iterator end = clients().end();
    for (RenderObjectSizeCountMap::const_iterator curr = clients().begin(); curr != end; ++curr)
        const_cast<RenderObject*>(curr->key)->imageChanged(static_cast<WrappedImagePtr>(this), &imageChangeRect);
}

void CSSCanvasValue::canvasResized(HTMLCanvasElement*)
{
    RenderObjectSizeCountMap::const_iterator end = clients().end();
    for (RenderObjectSizeCountMap::const_iterator curr = clients().begin(); curr != end; ++curr)
        const_cast<RenderObject*>(curr->key)->imageChanged(static_cast<WrappedImagePtr>(this));
}

#if !ENABLE(OILPAN)
void CSSCanvasValue::canvasDestroyed(HTMLCanvasElement* element)
{
    ASSERT_UNUSED(element, element == m_element);
    m_element = nullptr;
}
#endif

IntSize CSSCanvasValue::fixedSize(const RenderObject* renderer)
{
    if (HTMLCanvasElement* elt = element(&renderer->document()))
        return IntSize(elt->width(), elt->height());
    return IntSize();
}

HTMLCanvasElement* CSSCanvasValue::element(Document* document)
{
     if (!m_element) {
        m_element = &document->getCSSCanvasElement(m_name);
        m_element->addObserver(m_canvasObserver.get());
    }
    return m_element;
}

PassRefPtr<Image> CSSCanvasValue::image(RenderObject* renderer, const IntSize& /*size*/)
{
    ASSERT(clients().contains(renderer));
    HTMLCanvasElement* elt = element(&renderer->document());
    if (!elt || !elt->buffer())
        return nullptr;
    return elt->copiedImage();
}

bool CSSCanvasValue::equals(const CSSCanvasValue& other) const
{
    return m_name == other.m_name;
}

void CSSCanvasValue::traceAfterDispatch(Visitor* visitor)
{
    visitor->trace(m_canvasObserver);
    visitor->trace(m_element);
    CSSImageGeneratorValue::traceAfterDispatch(visitor);
}

} // namespace blink
