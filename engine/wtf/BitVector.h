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

#ifndef BitVector_h
#define BitVector_h

#include "wtf/Assertions.h"
#include "wtf/StdLibExtras.h"
#include "wtf/WTFExport.h"

namespace WTF {

class PrintStream;

// This is a space-efficient, resizeable bitvector class. In the common case it
// occupies one word, but if necessary, it will inflate this one word to point
// to a single chunk of out-of-line allocated storage to store an arbitrary number
// of bits.
//
// - The bitvector remembers the bound of how many bits can be stored, but this
//   may be slightly greater (by as much as some platform-specific constant)
//   than the last argument passed to ensureSize().
//
// - The bitvector can resize itself automatically (set, clear, get) or can be used
//   in a manual mode, which is faster (quickSet, quickClear, quickGet, ensureSize).
//
// - Accesses ASSERT that you are within bounds.
//
// - Bits are automatically initialized to zero.
//
// On the other hand, this BitVector class may not be the fastest around, since
// it does conditionals on every get/set/clear. But it is great if you need to
// juggle a lot of variable-length BitVectors and you're worried about wasting
// space.

class WTF_EXPORT BitVector {
public:
    BitVector()
        : m_bitsOrPointer(makeInlineBits(0))
    {
    }

    explicit BitVector(size_t numBits)
        : m_bitsOrPointer(makeInlineBits(0))
    {
        ensureSize(numBits);
    }

    BitVector(const BitVector& other)
        : m_bitsOrPointer(makeInlineBits(0))
    {
        (*this) = other;
    }


    ~BitVector()
    {
        if (isInline())
            return;
        OutOfLineBits::destroy(outOfLineBits());
    }

    BitVector& operator=(const BitVector& other)
    {
        if (isInline() && other.isInline())
            m_bitsOrPointer = other.m_bitsOrPointer;
        else
            setSlow(other);
        return *this;
    }

    size_t size() const
    {
        if (isInline())
            return maxInlineBits();
        return outOfLineBits()->numBits();
    }

    void ensureSize(size_t numBits)
    {
        if (numBits <= size())
            return;
        resizeOutOfLine(numBits);
    }

    // Like ensureSize(), but supports reducing the size of the bitvector.
    void resize(size_t numBits);

    void clearAll();

    bool quickGet(size_t bit) const
    {
        ASSERT_WITH_SECURITY_IMPLICATION(bit < size());
        return !!(bits()[bit / bitsInPointer()] & (static_cast<uintptr_t>(1) << (bit & (bitsInPointer() - 1))));
    }

    void quickSet(size_t bit)
    {
        ASSERT_WITH_SECURITY_IMPLICATION(bit < size());
        bits()[bit / bitsInPointer()] |= (static_cast<uintptr_t>(1) << (bit & (bitsInPointer() - 1)));
    }

    void quickClear(size_t bit)
    {
        ASSERT_WITH_SECURITY_IMPLICATION(bit < size());
        bits()[bit / bitsInPointer()] &= ~(static_cast<uintptr_t>(1) << (bit & (bitsInPointer() - 1)));
    }

    void quickSet(size_t bit, bool value)
    {
        if (value)
            quickSet(bit);
        else
            quickClear(bit);
    }

    bool get(size_t bit) const
    {
        if (bit >= size())
            return false;
        return quickGet(bit);
    }

    void set(size_t bit)
    {
        ensureSize(bit + 1);
        quickSet(bit);
    }

    void ensureSizeAndSet(size_t bit, size_t size)
    {
        ensureSize(size);
        quickSet(bit);
    }

    void clear(size_t bit)
    {
        if (bit >= size())
            return;
        quickClear(bit);
    }

    void set(size_t bit, bool value)
    {
        if (value)
            set(bit);
        else
            clear(bit);
    }

    void dump(PrintStream& out);

private:
    static unsigned bitsInPointer()
    {
        return sizeof(void*) << 3;
    }

    static unsigned maxInlineBits()
    {
        return bitsInPointer() - 1;
    }

    static size_t byteCount(size_t bitCount)
    {
        return (bitCount + 7) >> 3;
    }

    static uintptr_t makeInlineBits(uintptr_t bits)
    {
        ASSERT(!(bits & (static_cast<uintptr_t>(1) << maxInlineBits())));
        return bits | (static_cast<uintptr_t>(1) << maxInlineBits());
    }

    class WTF_EXPORT OutOfLineBits {
    public:
        size_t numBits() const { return m_numBits; }
        size_t numWords() const { return (m_numBits + bitsInPointer() - 1) / bitsInPointer(); }
        uintptr_t* bits() { return bitwise_cast<uintptr_t*>(this + 1); }
        const uintptr_t* bits() const { return bitwise_cast<const uintptr_t*>(this + 1); }

        static OutOfLineBits* create(size_t numBits);

        static void destroy(OutOfLineBits*);

    private:
        OutOfLineBits(size_t numBits)
            : m_numBits(numBits)
        {
        }

        size_t m_numBits;
    };

    bool isInline() const { return m_bitsOrPointer >> maxInlineBits(); }

    const OutOfLineBits* outOfLineBits() const { return bitwise_cast<const OutOfLineBits*>(m_bitsOrPointer << 1); }
    OutOfLineBits* outOfLineBits() { return bitwise_cast<OutOfLineBits*>(m_bitsOrPointer << 1); }

    void resizeOutOfLine(size_t numBits);
    void setSlow(const BitVector& other);

    uintptr_t* bits()
    {
        if (isInline())
            return &m_bitsOrPointer;
        return outOfLineBits()->bits();
    }

    const uintptr_t* bits() const
    {
        if (isInline())
            return &m_bitsOrPointer;
        return outOfLineBits()->bits();
    }

    uintptr_t m_bitsOrPointer;
};

} // namespace WTF

using WTF::BitVector;

#endif // BitVector_h
