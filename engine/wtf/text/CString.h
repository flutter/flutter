/*
 * Copyright (C) 2003, 2006, 2008, 2009, 2010, 2012 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef CString_h
#define CString_h

#include "wtf/RefCounted.h"
#include "wtf/RefPtr.h"
#include "wtf/WTFExport.h"

namespace WTF {

// CStringBuffer is the ref-counted storage class for the characters in a CString.
// The data is implicitly allocated 1 character longer than length(), as it is zero-terminated.
class WTF_EXPORT CStringBuffer : public RefCounted<CStringBuffer> {
public:
    const char* data() { return mutableData(); }
    size_t length() const { return m_length; }

private:
    friend class CString;
    friend class RefCounted<CStringBuffer>;
    // CStringBuffers are allocated out of the WTF buffer partition.
    void* operator new(size_t, void* ptr) { return ptr; };
    void operator delete(void*);

    static PassRefPtr<CStringBuffer> createUninitialized(size_t length);

    CStringBuffer(size_t length) : m_length(length) { }
    char* mutableData() { return reinterpret_cast<char*>(this + 1); }

    const unsigned m_length;
};

// A container for a null-terminated char array supporting copy-on-write
// assignment.  The contained char array may be null.
class WTF_EXPORT CString {
public:
    CString() { }
    CString(const char*);
    CString(const char*, size_t length);
    CString(CStringBuffer* buffer) : m_buffer(buffer) { }
    static CString newUninitialized(size_t length, char*& characterBuffer);

    const char* data() const
    {
        return m_buffer ? m_buffer->data() : 0;
    }
    char* mutableData();
    size_t length() const
    {
        return m_buffer ? m_buffer->length() : 0;
    }

    bool isNull() const { return !m_buffer; }
    bool isSafeToSendToAnotherThread() const;

    CStringBuffer* buffer() const { return m_buffer.get(); }

private:
    void copyBufferIfNeeded();
    void init(const char*, size_t length);
    RefPtr<CStringBuffer> m_buffer;
};

WTF_EXPORT bool operator==(const CString& a, const CString& b);
inline bool operator!=(const CString& a, const CString& b) { return !(a == b); }
WTF_EXPORT bool operator==(const CString& a, const char* b);
inline bool operator!=(const CString& a, const char* b) { return !(a == b); }

} // namespace WTF

using WTF::CString;

#endif // CString_h
