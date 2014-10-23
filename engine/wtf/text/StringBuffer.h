/*
 * Copyright (C) 2008, 2010 Apple Inc. All rights reserved.
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
 * 3.  Neither the name of Apple Inc. ("Apple") nor the names of its
 *     contributors may be used to endorse or promote products derived
 *     from this software without specific prior written permission.
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

#ifndef StringBuffer_h
#define StringBuffer_h

#include "wtf/Assertions.h"
#include "wtf/text/StringImpl.h"
#include "wtf/unicode/Unicode.h"

namespace WTF {

template <typename CharType>
class StringBuffer {
    WTF_MAKE_NONCOPYABLE(StringBuffer);
public:
    StringBuffer() { }

    explicit StringBuffer(unsigned length)
    {
        CharType* characters;
        m_data = StringImpl::createUninitialized(length, characters);
    }

    ~StringBuffer()
    {
    }

    void shrink(unsigned newLength);
    void resize(unsigned newLength)
    {
        if (!m_data) {
            CharType* characters;
            m_data = StringImpl::createUninitialized(newLength, characters);
            return;
        }
        if (newLength > m_data->length()) {
            m_data = StringImpl::reallocate(m_data.release(), newLength);
            return;
        }
        shrink(newLength);
    }

    unsigned length() const { return m_data ? m_data->length() : 0; }
    CharType* characters() { return length() ? const_cast<CharType*>(m_data->getCharacters<CharType>()) : 0; }

    CharType& operator[](unsigned i) { ASSERT_WITH_SECURITY_IMPLICATION(i < length()); return characters()[i]; }

    PassRefPtr<StringImpl> release() { return m_data.release(); }

private:
    RefPtr<StringImpl> m_data;
};

template <typename CharType>
void StringBuffer<CharType>::shrink(unsigned newLength)
{
    ASSERT(m_data);
    if (m_data->length() == newLength)
        return;
    m_data->truncateAssumingIsolated(newLength);
}

} // namespace WTF

using WTF::StringBuffer;

#endif // StringBuffer_h
