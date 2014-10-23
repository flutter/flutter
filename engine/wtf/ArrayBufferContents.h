/*
 * Copyright (C) 2009 Apple Inc. All rights reserved.
 * Copyright (C) 2013 Google Inc. All rights reserved.
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

#ifndef ArrayBufferContents_h
#define ArrayBufferContents_h

#include "wtf/ArrayBufferDeallocationObserver.h"
#include "wtf/Noncopyable.h"
#include "wtf/WTFExport.h"

namespace WTF {

class WTF_EXPORT ArrayBufferContents {
    WTF_MAKE_NONCOPYABLE(ArrayBufferContents);
public:
    enum InitializationPolicy {
        ZeroInitialize,
        DontInitialize
    };

    ArrayBufferContents();
    ArrayBufferContents(unsigned numElements, unsigned elementByteSize, ArrayBufferContents::InitializationPolicy);

    // Use with care. data must be allocated with allocateMemory.
    // ArrayBufferContents will take ownership of the data and free it (using freeMemorY)
    // upon destruction.
    // This constructor will not call observer->StartObserving(), so it is a responsibility
    // of the caller to make sure JS knows about external memory.
    ArrayBufferContents(void* data, unsigned sizeInBytes, ArrayBufferDeallocationObserver*);

    ~ArrayBufferContents();

    void clear();

    void* data() const { return m_data; }
    unsigned sizeInBytes() const { return m_sizeInBytes; }

    void setDeallocationObserver(ArrayBufferDeallocationObserver* observer)
    {
        if (!m_deallocationObserver) {
            m_deallocationObserver = observer;
            m_deallocationObserver->blinkAllocatedMemory(m_sizeInBytes);
        }
    }

    void transfer(ArrayBufferContents& other);
    void copyTo(ArrayBufferContents& other);

    static void allocateMemory(size_t, InitializationPolicy, void*&);
    static void freeMemory(void*, size_t);

private:
    void* m_data;
    unsigned m_sizeInBytes;
    ArrayBufferDeallocationObserver* m_deallocationObserver;
};

} // namespace WTF

#endif // ArrayBufferContents_h
