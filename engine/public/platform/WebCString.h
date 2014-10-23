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

#ifndef WebCString_h
#define WebCString_h

#include "WebCommon.h"
#include "WebPrivatePtr.h"

#if INSIDE_BLINK
#include "wtf/Forward.h"
#endif
#if !INSIDE_BLINK || defined(UNIT_TEST)
#include <string>
#endif

namespace WTF {
class CString;
class CStringBuffer;
}

namespace blink {

class WebString;

// A single-byte string container with unspecified encoding.  It is
// inexpensive to copy a WebCString object.
//
// WARNING: It is not safe to pass a WebCString across threads!!!
//
class WebCString {
public:
    ~WebCString() { reset(); }

    WebCString() { }

    WebCString(const char* data, size_t len)
    {
        assign(data, len);
    }

    WebCString(const WebCString& s) { assign(s); }

    WebCString& operator=(const WebCString& s)
    {
        assign(s);
        return *this;
    }

    // Returns 0 if both strings are equals, a value greater than zero if the
    // first character that does not match has a greater value in this string
    // than in |other|, or a value less than zero to indicate the opposite.
    BLINK_COMMON_EXPORT int compare(const WebCString& other) const;

    BLINK_COMMON_EXPORT void reset();
    BLINK_COMMON_EXPORT void assign(const WebCString&);
    BLINK_COMMON_EXPORT void assign(const char* data, size_t len);

    BLINK_COMMON_EXPORT size_t length() const;
    BLINK_COMMON_EXPORT const char* data() const;

    bool isEmpty() const { return !length(); }
    bool isNull() const { return m_private.isNull(); }

    BLINK_COMMON_EXPORT WebString utf16() const;

#if INSIDE_BLINK
    BLINK_COMMON_EXPORT WebCString(const WTF::CString&);
    BLINK_COMMON_EXPORT WebCString& operator=(const WTF::CString&);
    BLINK_COMMON_EXPORT operator WTF::CString() const;
#else
    WebCString(const std::string& s)
    {
        assign(s.data(), s.length());
    }

    WebCString& operator=(const std::string& s)
    {
        assign(s.data(), s.length());
        return *this;
    }
#endif
#if !INSIDE_BLINK || defined(UNIT_TEST)
    operator std::string() const
    {
        size_t len = length();
        return len ? std::string(data(), len) : std::string();
    }

    template <class UTF16String>
    static WebCString fromUTF16(const UTF16String& s)
    {
        return fromUTF16(s.data(), s.length());
    }
#endif

private:
    BLINK_COMMON_EXPORT void assign(WTF::CStringBuffer*);
    WebPrivatePtr<WTF::CStringBuffer> m_private;
};

inline bool operator<(const WebCString& a, const WebCString& b)
{
    return a.compare(b) < 0;
}

} // namespace blink

#endif
