/*
 * Copyright (C) 2011 Google Inc. All rights reserved.
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

#ifndef WebIconURL_h
#define WebIconURL_h

#include "public/platform/WebSize.h"
#include "public/platform/WebURL.h"
#include "public/platform/WebVector.h"

namespace blink {

class WebIconURL {
public:
    enum Type {
        TypeInvalid = 0,
        TypeFavicon = 1 << 0,
        TypeTouch = 1 << 1,
        TypeTouchPrecomposed = 1 << 2
    };

    WebIconURL()
        : m_iconType(TypeInvalid)
    {
    }

    WebIconURL(const WebURL& url, Type type)
        : m_iconType(type)
        , m_iconURL(url)
    {
    }

    Type iconType() const
    {
        return m_iconType;
    }

    const WebURL& iconURL() const
    {
        return m_iconURL;
    }

    const WebVector<WebSize>& sizes() const
    {
        return m_sizes;
    }

private:
    Type m_iconType;
    WebURL m_iconURL;
    WebVector<WebSize> m_sizes;
};

}

#endif // WebIconURL_h
