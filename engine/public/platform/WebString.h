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

#ifndef WebString_h
#define WebString_h

#include "WebCommon.h"
#include "WebPrivatePtr.h"
#include <string>

#if INSIDE_BLINK
#include "wtf/Forward.h"
#else
#include <base/strings/latin1_string_conversions.h>
#include <base/strings/nullable_string16.h>
#include <base/strings/string16.h>
#endif

namespace WTF {
class StringImpl;
}

namespace blink {

class WebCString;

// A UTF-16 string container.  It is inexpensive to copy a WebString
// object.
//
// WARNING: It is not safe to pass a WebString across threads!!!
//
class WebString {
public:
    ~WebString() { reset(); }

    WebString() { }

    WebString(const WebUChar* data, size_t len)
    {
        assign(data, len);
    }

    WebString(const WebString& s) { assign(s); }

    WebString& operator=(const WebString& s)
    {
        assign(s);
        return *this;
    }

    BLINK_COMMON_EXPORT void reset();
    BLINK_COMMON_EXPORT void assign(const WebString&);
    BLINK_COMMON_EXPORT void assign(const WebUChar* data, size_t len);

    BLINK_COMMON_EXPORT bool equals(const WebString&) const;

    BLINK_COMMON_EXPORT size_t length() const;

    // Caller must check bounds.
    BLINK_COMMON_EXPORT WebUChar at(unsigned) const;

    bool isEmpty() const { return !length(); }
    bool isNull() const { return m_private.isNull(); }

    BLINK_COMMON_EXPORT std::string utf8() const;

    BLINK_COMMON_EXPORT static WebString fromUTF8(const char* data, size_t length);
    BLINK_COMMON_EXPORT static WebString fromUTF8(const char* data);

    static WebString fromUTF8(const std::string& s)
    {
        return fromUTF8(s.data(), s.length());
    }

    BLINK_COMMON_EXPORT std::string latin1() const;

    BLINK_COMMON_EXPORT static WebString fromLatin1(const WebLChar* data, size_t length);

    static WebString fromLatin1(const std::string& s)
    {
        return fromLatin1(reinterpret_cast<const WebLChar*>(s.data()), s.length());
    }

    template <int N> WebString(const char (&data)[N])
    {
        assign(fromUTF8(data, N - 1));
    }

    template <int N> WebString& operator=(const char (&data)[N])
    {
        assign(fromUTF8(data, N - 1));
        return *this;
    }

#if INSIDE_BLINK
    BLINK_COMMON_EXPORT WebString(const WTF::String&);
    BLINK_COMMON_EXPORT WebString& operator=(const WTF::String&);
    BLINK_COMMON_EXPORT operator WTF::String() const;

    BLINK_COMMON_EXPORT WebString(const WTF::AtomicString&);
    BLINK_COMMON_EXPORT WebString& operator=(const WTF::AtomicString&);
    BLINK_COMMON_EXPORT operator WTF::AtomicString() const;
#else
    WebString(const base::string16& s)
    {
        assign(s.data(), s.length());
    }

    WebString& operator=(const base::string16& s)
    {
        assign(s.data(), s.length());
        return *this;
    }

    operator base::string16() const
    {
        return base::Latin1OrUTF16ToUTF16(length(), data8(), data16());
    }

    WebString(const base::NullableString16& s)
    {
        if (s.is_null())
            reset();
        else
            assign(s.string().data(), s.string().length());
    }

    WebString& operator=(const base::NullableString16& s)
    {
        if (s.is_null())
            reset();
        else
            assign(s.string().data(), s.string().length());
        return *this;
    }

    operator base::NullableString16() const
    {
        return base::NullableString16(operator base::string16(), m_private.isNull());
    }
#endif

private:
    BLINK_COMMON_EXPORT bool is8Bit() const;
    BLINK_COMMON_EXPORT const WebLChar* data8() const;
    BLINK_COMMON_EXPORT const WebUChar* data16() const;

    BLINK_COMMON_EXPORT void assign(WTF::StringImpl*);

    WebPrivatePtr<WTF::StringImpl> m_private;
};

inline bool operator==(const WebString& a, const WebString& b)
{
    return a.equals(b);
}

inline bool operator!=(const WebString& a, const WebString& b)
{
    return !(a == b);
}

} // namespace blink

#endif
