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

#ifndef WebData_h
#define WebData_h

#include "WebCommon.h"
#include "WebPrivatePtr.h"

namespace blink {

class SharedBuffer;
class WebDataPrivate;

// A container for raw bytes.  It is inexpensive to copy a WebData object.
//
// WARNING: It is not safe to pass a WebData across threads!!!
//
class BLINK_PLATFORM_EXPORT WebData {
public:
    ~WebData() { reset(); }

    WebData() { }

    WebData(const char* data, size_t size)
    {
        assign(data, size);
    }

    template <int N>
    WebData(const char (&data)[N])
    {
        assign(data, N - 1);
    }

    WebData(const WebData& d) { assign(d); }

    WebData& operator=(const WebData& d)
    {
        assign(d);
        return *this;
    }

    void reset();
    void assign(const WebData&);
    void assign(const char* data, size_t size);

    size_t size() const;
    const char* data() const;

    bool isEmpty() const { return !size(); }
    bool isNull() const { return m_private.isNull(); }

#if INSIDE_BLINK
    WebData(const PassRefPtr<SharedBuffer>&);
    WebData& operator=(const PassRefPtr<SharedBuffer>&);
    operator PassRefPtr<SharedBuffer>() const;
#else
    template <class C>
    WebData(const C& c)
    {
        assign(c.data(), c.size());
    }

    template <class C>
    WebData& operator=(const C& c)
    {
        assign(c.data(), c.size());
        return *this;
    }
#endif

private:
    WebPrivatePtr<SharedBuffer> m_private;
};

} // namespace blink

#endif
