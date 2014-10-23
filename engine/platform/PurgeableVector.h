/*
 * Copyright (C) 2014 Google Inc. All rights reserved.
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

#ifndef PurgeableVector_h
#define PurgeableVector_h

#include "platform/PlatformExport.h"
#include "wtf/Forward.h"
#include "wtf/Noncopyable.h"
#include "wtf/Vector.h"

namespace blink {

class WebDiscardableMemory;

// A simple vector implementation that supports purgeable memory. The vector is
// already locked at construction and locking uses an internal counter which
// means that N calls to lock() must be followed by N+1 calls to unlock() to
// actually make the vector purgeable.
class PLATFORM_EXPORT PurgeableVector {
    WTF_MAKE_NONCOPYABLE(PurgeableVector);
public:
    enum PurgeableOption {
        NotPurgeable,
        Purgeable,
    };

    // Clients who know in advance that they will call unlock() should construct
    // the instance with the Purgeable option so that the instance uses
    // discardable memory from the start and unlock() doesn't cause a memcpy().
    PurgeableVector(PurgeableOption = Purgeable);

    ~PurgeableVector();

    // WARNING: This causes a memcpy() if the instance was constructed with the
    // Purgeable hint or had its internal vector moved to discardable memory
    // after a call to unlock().
    void adopt(Vector<char>& other);

    void append(const char* data, size_t length);

    void grow(size_t);

    void clear();

    // The instance must be locked before calling this.
    char* data();

    size_t size() const;

    // Returns whether the memory is still resident.
    bool lock();

    // WARNING: Calling unlock() on an instance that wasn't created with the
    // Purgeable option does an extra memcpy().
    void unlock();

    bool isLocked() const;

    // Note that this method should be used carefully since it may not use
    // exponential growth internally. This means that repeated/invalid uses of
    // it can result in O(N^2) append(). If you don't exactly know what you are
    // doing then you should probably not call this method.
    void reserveCapacity(size_t capacity);

private:
    enum PurgeableAllocationStrategy {
        UseExactCapacity,
        UseExponentialGrowth,
    };

    // Copies data from the discardable buffer to the vector and clears the
    // discardable buffer.
    void moveDataFromDiscardableToVector();

    void clearDiscardable();

    bool reservePurgeableCapacity(size_t capacity, PurgeableAllocationStrategy);

    size_t adjustPurgeableCapacity(size_t capacity) const;

    // Vector used when the instance is constructed without the purgeability
    // hint or when discardable memory allocation fails.
    // Note that there can't be data both in |m_vector| and
    // |m_discardable|, i.e. only one of them is used at a given time.
    Vector<char> m_vector;
    OwnPtr<WebDiscardableMemory> m_discardable;
    size_t m_discardableCapacity;
    size_t m_discardableSize;
    bool m_isPurgeable;
    int m_locksCount;
};

} // namespace blink

#endif // PurgeableVector_h
