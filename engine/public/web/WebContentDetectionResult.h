/*
* Copyright (C) 2012 Google Inc. All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions
* are met:
*
* 1.  Redistributions of source code must retain the above copyright
*     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef WebContentDetectionResult_h
#define WebContentDetectionResult_h

#include "../platform/WebString.h"
#include "../platform/WebURL.h"
#include "WebRange.h"

namespace blink {

class WebContentDetectionResult {
public:
    WebContentDetectionResult()
        : m_isValid(false)
    {
    }

    WebContentDetectionResult(const WebRange& range, const WebString& string, const WebURL& intent)
        : m_isValid(true)
        , m_range(range)
        , m_string(string)
        , m_intent(intent)
    {
    }

    bool isValid() const { return m_isValid; }
    const WebRange& range() const { return m_range; }
    const WebString& string() const { return m_string; }
    const WebURL& intent() const { return m_intent; }

private:
    bool m_isValid;
    WebRange m_range;
    WebString m_string;
    WebURL m_intent;
};

} // namespace blink

#endif
