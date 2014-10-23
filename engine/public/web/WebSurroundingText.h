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

#ifndef WebSurroundingText_h
#define WebSurroundingText_h

#include "../platform/WebPrivateOwnPtr.h"
#include "../platform/WebString.h"
#include "WebNode.h"
#include "WebRange.h"

namespace blink {

class SurroundingText;
class WebHitTestResult;
class WebNode;
class WebRange;
struct WebPoint;

// WebSurroundingText is a Blink API that gives access to the SurroundingText
// API. It allows caller to know the text surrounding a point or a range.
class WebSurroundingText {
public:
    WebSurroundingText() { }
    ~WebSurroundingText() { reset(); }

    BLINK_EXPORT bool isNull() const;
    BLINK_EXPORT void reset();

    // Initializes the object to get the surrounding text centered in the
    // position relative to a provided node.
    // The maximum length of the contents retrieved is defined by maxLength.
    BLINK_EXPORT void initialize(const WebNode&, const WebPoint&, size_t maxLength);

    // Initializes the object to get the text surrounding a given range.
    // The maximum length of the contents retrieved is defined by maxLength.
    // It does not include the text inside the range.
    BLINK_EXPORT void initialize(const WebRange&, size_t maxLength);

    // Surrounding text content retrieved.
    BLINK_EXPORT WebString textContent() const;

    // Offset in the text content of the initial hit position (or provided
    // offset in the node).
    // This should only be called when WebSurroundingText has been initialized
    // with a WebPoint.
    // DEPRECATED: use startOffsetInTextContent() or endOffsetInTextContent().
    BLINK_EXPORT size_t hitOffsetInTextContent() const;

    // Start offset of the initial text in the text content.
    BLINK_EXPORT size_t startOffsetInTextContent() const;

    // End offset of the initial text in the text content.
    BLINK_EXPORT size_t endOffsetInTextContent() const;

    // Convert start/end positions in the content text string into a WebKit text
    // range.
    BLINK_EXPORT WebRange rangeFromContentOffsets(size_t startOffsetInContent, size_t endOffsetInContent);

protected:
    WebPrivateOwnPtr<SurroundingText> m_private;
};

} // namespace blink

#endif
