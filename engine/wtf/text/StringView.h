/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
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

#ifndef WTF_StringView_h
#define WTF_StringView_h

#include "wtf/text/StringImpl.h"

namespace WTF {

class WTF_EXPORT StringView {
public:
    StringView()
        : m_offset(0)
        , m_length(0)
    {
    }

    explicit StringView(PassRefPtr<StringImpl> impl)
        : m_impl(impl)
        , m_offset(0)
        , m_length(m_impl->length())
    {
    }

    StringView(PassRefPtr<StringImpl> impl, unsigned offset, unsigned length)
        : m_impl(impl)
        , m_offset(offset)
        , m_length(length)
    {
        ASSERT_WITH_SECURITY_IMPLICATION(offset + length <= m_impl->length());
    }

    void narrow(unsigned offset, unsigned length)
    {
        ASSERT_WITH_SECURITY_IMPLICATION(offset + length <= m_length);
        m_offset += offset;
        m_length = length;
    }

    bool isEmpty() const { return !m_length; }
    unsigned length() const { return m_length; }

    bool is8Bit() const { return m_impl->is8Bit(); }

    const LChar* characters8() const
    {
        if (!m_impl)
            return 0;
        ASSERT(is8Bit());
        return m_impl->characters8() + m_offset;
    }

    const UChar* characters16() const
    {
        if (!m_impl)
            return 0;
        ASSERT(!is8Bit());
        return m_impl->characters16() + m_offset;
    }

    PassRefPtr<StringImpl> toString() const
    {
        if (!m_impl)
            return m_impl;
        if (m_impl->is8Bit())
            return StringImpl::create(characters8(), m_length);
        return StringImpl::create(characters16(), m_length);
    }

private:
    RefPtr<StringImpl> m_impl;
    unsigned m_offset;
    unsigned m_length;
};

}

using WTF::StringView;

#endif
