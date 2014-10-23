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

#include "config.h"

#include "platform/graphics/ThreadSafeDataTransport.h"

#include "platform/SharedBuffer.h"

namespace blink {

ThreadSafeDataTransport::ThreadSafeDataTransport()
    : m_readBuffer(SharedBuffer::create())
    , m_allDataReceived(false)
    , m_readPosition(0)
{
}

ThreadSafeDataTransport::~ThreadSafeDataTransport()
{
}

void ThreadSafeDataTransport::setData(SharedBuffer* buffer, bool allDataReceived)
{
    ASSERT(buffer->size() >= m_readPosition);
    Vector<RefPtr<SharedBuffer> > newBufferQueue;

    const char* segment = 0;
    while (size_t length = buffer->getSomeData(segment, m_readPosition)) {
        m_readPosition += length;
        newBufferQueue.append(SharedBuffer::create(segment, length));
    }

    MutexLocker locker(m_mutex);
    m_newBufferQueue.appendVector(newBufferQueue);
    m_allDataReceived = allDataReceived;
}

void ThreadSafeDataTransport::data(SharedBuffer** buffer, bool* allDataReceived)
{
    Vector<RefPtr<SharedBuffer> > newBufferQueue;
    {
        MutexLocker lock(m_mutex);
        m_newBufferQueue.swap(newBufferQueue);
    }
    for (size_t i = 0; i < newBufferQueue.size(); ++i)
        m_readBuffer->append(newBufferQueue[i].get());
    ASSERT(buffer);
    ASSERT(allDataReceived);
    *buffer = m_readBuffer.get();
    *allDataReceived = m_allDataReceived;
}

bool ThreadSafeDataTransport::hasNewData()
{
    MutexLocker lock(m_mutex);
    return !m_newBufferQueue.isEmpty();
}

} // namespace blink
