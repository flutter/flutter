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

#ifndef WebRange_h
#define WebRange_h

#include "WebFrame.h"
#include "public/platform/WebCommon.h"
#include "public/platform/WebPrivatePtr.h"
#include "public/platform/WebVector.h"

namespace blink {

class Range;
class WebNode;
class WebString;

// Provides readonly access to some properties of a DOM range.
class WebRange {
public:
    ~WebRange() { reset(); }

    WebRange() { }
    WebRange(const WebRange& r) { assign(r); }
    WebRange& operator=(const WebRange& r)
    {
        assign(r);
        return *this;
    }

    BLINK_EXPORT void reset();
    BLINK_EXPORT void assign(const WebRange&);

    bool isNull() const { return m_private.isNull(); }

    BLINK_EXPORT int startOffset() const;
    BLINK_EXPORT int endOffset() const;
    BLINK_EXPORT WebNode startContainer(int& exceptionCode) const;
    BLINK_EXPORT WebNode endContainer(int& exceptionCode) const;

    BLINK_EXPORT WebString toHTMLText() const;
    BLINK_EXPORT WebString toPlainText() const;

    BLINK_EXPORT WebRange expandedToParagraph() const;

    BLINK_EXPORT static WebRange fromDocumentRange(WebLocalFrame*, int start, int length);

#if BLINK_IMPLEMENTATION
    WebRange(const PassRefPtrWillBeRawPtr<Range>&);
    operator PassRefPtrWillBeRawPtr<Range>() const;
#endif

private:
    WebPrivatePtr<Range> m_private;
};

} // namespace blink

#endif
