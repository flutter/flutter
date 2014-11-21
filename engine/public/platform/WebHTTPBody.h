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

#ifndef SKY_ENGINE_PUBLIC_PLATFORM_WEBHTTPBODY_H_
#define SKY_ENGINE_PUBLIC_PLATFORM_WEBHTTPBODY_H_

#include "sky/engine/public/platform/WebData.h"
#include "sky/engine/public/platform/WebNonCopyable.h"
#include "sky/engine/public/platform/WebString.h"
#include "sky/engine/public/platform/WebURL.h"

#if INSIDE_BLINK
namespace WTF { template <typename T> class PassRefPtr; }
#endif

namespace blink {

class FormData;
class WebHTTPBodyPrivate;

class WebHTTPBody {
public:
    struct Element {
        enum Type { TypeData } type;
        WebData data;
    };

    ~WebHTTPBody() { reset(); }

    WebHTTPBody() : m_private(0) { }
    WebHTTPBody(const WebHTTPBody& b) : m_private(0) { assign(b); }
    WebHTTPBody& operator=(const WebHTTPBody& b)
    {
        assign(b);
        return *this;
    }

    BLINK_PLATFORM_EXPORT void initialize();
    BLINK_PLATFORM_EXPORT void reset();
    BLINK_PLATFORM_EXPORT void assign(const WebHTTPBody&);

    bool isNull() const { return !m_private; }

    // Returns the number of elements comprising the http body.
    BLINK_PLATFORM_EXPORT size_t elementCount() const;

    // Sets the values of the element at the given index. Returns false if
    // index is out of bounds.
    BLINK_PLATFORM_EXPORT bool elementAt(size_t index, Element&) const;

    // Append to the list of elements.
    BLINK_PLATFORM_EXPORT void appendData(const WebData&);

    // Identifies a particular form submission instance. A value of 0 is
    // used to indicate an unspecified identifier.
    BLINK_PLATFORM_EXPORT long long identifier() const;
    BLINK_PLATFORM_EXPORT void setIdentifier(long long);

    BLINK_PLATFORM_EXPORT bool containsPasswordData() const;
    BLINK_PLATFORM_EXPORT void setContainsPasswordData(bool);

#if INSIDE_BLINK
    BLINK_PLATFORM_EXPORT WebHTTPBody(const WTF::PassRefPtr<FormData>&);
    BLINK_PLATFORM_EXPORT WebHTTPBody& operator=(const WTF::PassRefPtr<FormData>&);
    BLINK_PLATFORM_EXPORT operator WTF::PassRefPtr<FormData>() const;
#endif

private:
    BLINK_PLATFORM_EXPORT void assign(WebHTTPBodyPrivate*);
    BLINK_PLATFORM_EXPORT void ensureMutable();

    WebHTTPBodyPrivate* m_private;
};

} // namespace blink

#endif  // SKY_ENGINE_PUBLIC_PLATFORM_WEBHTTPBODY_H_
