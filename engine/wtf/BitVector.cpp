/*
 * Copyright (C) 2011 Apple Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "BitVector.h"

#include "wtf/LeakAnnotations.h"
#include "wtf/PartitionAlloc.h"
#include "wtf/PrintStream.h"
#include "wtf/WTF.h"
#include <algorithm>
#include <string.h>

namespace WTF {

void BitVector::setSlow(const BitVector& other)
{
    uintptr_t newBitsOrPointer;
    if (other.isInline())
        newBitsOrPointer = other.m_bitsOrPointer;
    else {
        OutOfLineBits* newOutOfLineBits = OutOfLineBits::create(other.size());
        memcpy(newOutOfLineBits->bits(), other.bits(), byteCount(other.size()));
        newBitsOrPointer = bitwise_cast<uintptr_t>(newOutOfLineBits) >> 1;
    }
    if (!isInline())
        OutOfLineBits::destroy(outOfLineBits());
    m_bitsOrPointer = newBitsOrPointer;
}

void BitVector::resize(size_t numBits)
{
    if (numBits <= maxInlineBits()) {
        if (isInline())
            return;

        OutOfLineBits* myOutOfLineBits = outOfLineBits();
        m_bitsOrPointer = makeInlineBits(*myOutOfLineBits->bits());
        OutOfLineBits::destroy(myOutOfLineBits);
        return;
    }

    resizeOutOfLine(numBits);
}

void BitVector::clearAll()
{
    if (isInline())
        m_bitsOrPointer = makeInlineBits(0);
    else
        memset(outOfLineBits()->bits(), 0, byteCount(size()));
}

BitVector::OutOfLineBits* BitVector::OutOfLineBits::create(size_t numBits)
{
    // Because of the way BitVector stores the pointer, memory tools
    // will erroneously report a leak here.
    WTF_ANNOTATE_SCOPED_MEMORY_LEAK;
    numBits = (numBits + bitsInPointer() - 1) & ~(bitsInPointer() - 1);
    size_t size = sizeof(OutOfLineBits) + sizeof(uintptr_t) * (numBits / bitsInPointer());
    void* allocation = partitionAllocGeneric(Partitions::getBufferPartition(), size);
    OutOfLineBits* result = new (NotNull, allocation) OutOfLineBits(numBits);
    return result;
}

void BitVector::OutOfLineBits::destroy(OutOfLineBits* outOfLineBits)
{
    partitionFreeGeneric(Partitions::getBufferPartition(), outOfLineBits);
}

void BitVector::resizeOutOfLine(size_t numBits)
{
    ASSERT(numBits > maxInlineBits());
    OutOfLineBits* newOutOfLineBits = OutOfLineBits::create(numBits);
    size_t newNumWords = newOutOfLineBits->numWords();
    if (isInline()) {
        // Make sure that all of the bits are zero in case we do a no-op resize.
        *newOutOfLineBits->bits() = m_bitsOrPointer & ~(static_cast<uintptr_t>(1) << maxInlineBits());
        memset(newOutOfLineBits->bits() + 1, 0, (newNumWords - 1) * sizeof(void*));
    } else {
        if (numBits > size()) {
            size_t oldNumWords = outOfLineBits()->numWords();
            memcpy(newOutOfLineBits->bits(), outOfLineBits()->bits(), oldNumWords * sizeof(void*));
            memset(newOutOfLineBits->bits() + oldNumWords, 0, (newNumWords - oldNumWords) * sizeof(void*));
        } else
            memcpy(newOutOfLineBits->bits(), outOfLineBits()->bits(), newOutOfLineBits->numWords() * sizeof(void*));
        OutOfLineBits::destroy(outOfLineBits());
    }
    m_bitsOrPointer = bitwise_cast<uintptr_t>(newOutOfLineBits) >> 1;
}

void BitVector::dump(PrintStream& out)
{
    for (size_t i = 0; i < size(); ++i) {
        if (get(i))
            out.printf("1");
        else
            out.printf("-");
    }
}

} // namespace WTF
