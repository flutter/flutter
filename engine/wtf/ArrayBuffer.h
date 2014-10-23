/*
 * Copyright (C) 2009 Apple Inc. All rights reserved.
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

#ifndef ArrayBuffer_h
#define ArrayBuffer_h

#include "wtf/ArrayBufferContents.h"
#include "wtf/HashSet.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefCounted.h"
#include "wtf/WTFExport.h"

namespace WTF {

class ArrayBuffer;
class ArrayBufferView;

class WTF_EXPORT ArrayBuffer : public RefCounted<ArrayBuffer> {
public:
    static inline PassRefPtr<ArrayBuffer> create(unsigned numElements, unsigned elementByteSize);
    static inline PassRefPtr<ArrayBuffer> create(ArrayBuffer*);
    static inline PassRefPtr<ArrayBuffer> create(const void* source, unsigned byteLength);
    static inline PassRefPtr<ArrayBuffer> create(ArrayBufferContents&);

    // Only for use by Uint8ClampedArray::createUninitialized and SharedBuffer::getAsArrayBuffer.
    static inline PassRefPtr<ArrayBuffer> createUninitialized(unsigned numElements, unsigned elementByteSize);

    inline void* data();
    inline const void* data() const;
    inline unsigned byteLength() const;

    // Creates a new ArrayBuffer object with copy of bytes in this object
    // ranging from |begin| upto but not including |end|.
    inline PassRefPtr<ArrayBuffer> slice(int begin, int end) const;
    inline PassRefPtr<ArrayBuffer> slice(int begin) const;

    void addView(ArrayBufferView*);
    void removeView(ArrayBufferView*);

    bool transfer(ArrayBufferContents&);
    bool isNeutered() { return m_isNeutered; }

    void setDeallocationObserver(ArrayBufferDeallocationObserver* observer) { m_contents.setDeallocationObserver(observer); }

    ~ArrayBuffer() { }

private:
    static inline PassRefPtr<ArrayBuffer> create(unsigned numElements, unsigned elementByteSize, ArrayBufferContents::InitializationPolicy);

    inline ArrayBuffer(ArrayBufferContents&);
    inline PassRefPtr<ArrayBuffer> sliceImpl(unsigned begin, unsigned end) const;
    inline unsigned clampIndex(int index) const;
    static inline int clampValue(int x, int left, int right);

    ArrayBufferContents m_contents;
    ArrayBufferView* m_firstView;
    bool m_isNeutered;
};

int ArrayBuffer::clampValue(int x, int left, int right)
{
    ASSERT(left <= right);
    if (x < left)
        x = left;
    if (right < x)
        x = right;
    return x;
}

PassRefPtr<ArrayBuffer> ArrayBuffer::create(unsigned numElements, unsigned elementByteSize)
{
    return create(numElements, elementByteSize, ArrayBufferContents::ZeroInitialize);
}

PassRefPtr<ArrayBuffer> ArrayBuffer::create(ArrayBuffer* other)
{
    return ArrayBuffer::create(other->data(), other->byteLength());
}

PassRefPtr<ArrayBuffer> ArrayBuffer::create(const void* source, unsigned byteLength)
{
    ArrayBufferContents contents(byteLength, 1, ArrayBufferContents::ZeroInitialize);
    if (!contents.data())
        return nullptr;
    RefPtr<ArrayBuffer> buffer = adoptRef(new ArrayBuffer(contents));
    memcpy(buffer->data(), source, byteLength);
    return buffer.release();
}

PassRefPtr<ArrayBuffer> ArrayBuffer::create(ArrayBufferContents& contents)
{
    return adoptRef(new ArrayBuffer(contents));
}

PassRefPtr<ArrayBuffer> ArrayBuffer::createUninitialized(unsigned numElements, unsigned elementByteSize)
{
    return create(numElements, elementByteSize, ArrayBufferContents::DontInitialize);
}

PassRefPtr<ArrayBuffer> ArrayBuffer::create(unsigned numElements, unsigned elementByteSize, ArrayBufferContents::InitializationPolicy policy)
{
    ArrayBufferContents contents(numElements, elementByteSize, policy);
    if (!contents.data())
        return nullptr;
    return adoptRef(new ArrayBuffer(contents));
}

ArrayBuffer::ArrayBuffer(ArrayBufferContents& contents)
    : m_firstView(0), m_isNeutered(false)
{
    contents.transfer(m_contents);
}

void* ArrayBuffer::data()
{
    return m_contents.data();
}

const void* ArrayBuffer::data() const
{
    return m_contents.data();
}

unsigned ArrayBuffer::byteLength() const
{
    return m_contents.sizeInBytes();
}

PassRefPtr<ArrayBuffer> ArrayBuffer::slice(int begin, int end) const
{
    return sliceImpl(clampIndex(begin), clampIndex(end));
}

PassRefPtr<ArrayBuffer> ArrayBuffer::slice(int begin) const
{
    return sliceImpl(clampIndex(begin), byteLength());
}

PassRefPtr<ArrayBuffer> ArrayBuffer::sliceImpl(unsigned begin, unsigned end) const
{
    unsigned size = begin <= end ? end - begin : 0;
    return ArrayBuffer::create(static_cast<const char*>(data()) + begin, size);
}

unsigned ArrayBuffer::clampIndex(int index) const
{
    unsigned currentLength = byteLength();
    if (index < 0)
        index = currentLength + index;
    return clampValue(index, 0, currentLength);
}

} // namespace WTF

using WTF::ArrayBuffer;

#endif // ArrayBuffer_h
