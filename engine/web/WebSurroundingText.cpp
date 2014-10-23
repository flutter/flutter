/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "public/web/WebSurroundingText.h"

#include "core/dom/Element.h"
#include "core/dom/Node.h"
#include "core/dom/Range.h"
#include "core/dom/Text.h"
#include "core/editing/SurroundingText.h"
#include "core/editing/VisiblePosition.h"
#include "core/rendering/RenderObject.h"
#include "public/platform/WebPoint.h"
#include "public/web/WebHitTestResult.h"

namespace blink {

void WebSurroundingText::initialize(const WebNode& webNode, const WebPoint& nodePoint, size_t maxLength)
{
    const Node* node = webNode.constUnwrap<Node>();
    if (!node || !node->renderer())
        return;

    m_private.reset(new SurroundingText(VisiblePosition(node->renderer()->positionForPoint(static_cast<IntPoint>(nodePoint))).deepEquivalent().parentAnchoredEquivalent(), maxLength));
}

void WebSurroundingText::initialize(const WebRange& webRange, size_t maxLength)
{
    if (RefPtrWillBeRawPtr<Range> range = static_cast<PassRefPtrWillBeRawPtr<Range> >(webRange))
        m_private.reset(new SurroundingText(*range, maxLength));
}

WebString WebSurroundingText::textContent() const
{
    return m_private->content();
}

size_t WebSurroundingText::hitOffsetInTextContent() const
{
    ASSERT(m_private->startOffsetInContent() == m_private->endOffsetInContent());
    return m_private->startOffsetInContent();
}

size_t WebSurroundingText::startOffsetInTextContent() const
{
    return m_private->startOffsetInContent();
}

size_t WebSurroundingText::endOffsetInTextContent() const
{
    return m_private->endOffsetInContent();
}

WebRange WebSurroundingText::rangeFromContentOffsets(size_t startOffsetInContent, size_t endOffsetInContent)
{
    return m_private->rangeFromContentOffsets(startOffsetInContent, endOffsetInContent);
}

bool WebSurroundingText::isNull() const
{
    return !m_private.get();
}

void WebSurroundingText::reset()
{
    m_private.reset(0);
}

} // namespace blink
