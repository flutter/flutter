/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
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

#ifndef ThreadSafeDataTransport_h
#define ThreadSafeDataTransport_h

#include "platform/PlatformExport.h"
#include "wtf/OwnPtr.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/RefPtr.h"
#include "wtf/ThreadingPrimitives.h"
#include "wtf/Vector.h"

namespace blink {

class SharedBuffer;

// The purpose of this class is to allow the transfer of data stored in
// SharedBuffer in a thread-safe manner, and to minimize memory copies
// and thread contention.
//
// This class is designed such that there is only one producer and
// one consumer.
class PLATFORM_EXPORT ThreadSafeDataTransport {
public:
    ThreadSafeDataTransport();
    ~ThreadSafeDataTransport();

    // This method is being called subsequently with an expanding
    // SharedBuffer.
    void setData(SharedBuffer*, bool allDataReceived);

    // Get the data submitted to this class so far.
    void data(SharedBuffer**, bool* allDataReceived);

    // Return true of there is new data submitted to this class
    // since last time data() was called.
    bool hasNewData();

private:
    Mutex m_mutex;

    Vector<RefPtr<SharedBuffer> > m_newBufferQueue;
    RefPtr<SharedBuffer> m_readBuffer;
    bool m_allDataReceived;
    size_t m_readPosition;
};

} // namespace blink

#endif
