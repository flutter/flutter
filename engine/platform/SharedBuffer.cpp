/*
 * Copyright (C) 2006, 2008 Apple Inc. All rights reserved.
 * Copyright (C) Research In Motion Limited 2009-2010. All rights reserved.
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
#include "platform/SharedBuffer.h"

#include "wtf/unicode/Unicode.h"
#include "wtf/unicode/UTF8.h"

#undef SHARED_BUFFER_STATS

#ifdef SHARED_BUFFER_STATS
#include "wtf/DataLog.h"
#include "wtf/MainThread.h"
#endif

namespace blink {

static const unsigned segmentSize = 0x1000;
static const unsigned segmentPositionMask = 0x0FFF;

static inline unsigned segmentIndex(unsigned position)
{
    return position / segmentSize;
}

static inline unsigned offsetInSegment(unsigned position)
{
    return position & segmentPositionMask;
}

static inline char* allocateSegment()
{
    return static_cast<char*>(fastMalloc(segmentSize));
}

static inline void freeSegment(char* p)
{
    fastFree(p);
}

#ifdef SHARED_BUFFER_STATS

static Mutex& statsMutex()
{
    DEFINE_STATIC_LOCAL(Mutex, mutex, ());
    return mutex;
}

static HashSet<SharedBuffer*>& liveBuffers()
{
    DEFINE_STATIC_LOCAL(HashSet<SharedBuffer*>, buffers, ());
    return buffers;
}

static bool sizeComparator(SharedBuffer* a, SharedBuffer* b)
{
    return a->size() > b->size();
}

static CString snippetForBuffer(SharedBuffer* sharedBuffer)
{
    const unsigned kMaxSnippetLength = 64;
    char* snippet = 0;
    unsigned snippetLength = std::min(sharedBuffer->size(), kMaxSnippetLength);
    CString result = CString::newUninitialized(snippetLength, snippet);

    const char* segment;
    unsigned offset = 0;
    while (unsigned segmentLength = sharedBuffer->getSomeData(segment, offset)) {
        unsigned length = std::min(segmentLength, snippetLength - offset);
        memcpy(snippet + offset, segment, length);
        offset += segmentLength;
        if (offset >= snippetLength)
            break;
    }

    for (unsigned i = 0; i < snippetLength; ++i) {
        if (!isASCIIPrintable(snippet[i]))
            snippet[i] = '?';
    }

    return result;
}

static void printStats(void*)
{
    MutexLocker locker(statsMutex());
    Vector<SharedBuffer*> buffers;
    for (HashSet<SharedBuffer*>::const_iterator iter = liveBuffers().begin(); iter != liveBuffers().end(); ++iter)
        buffers.append(*iter);
    std::sort(buffers.begin(), buffers.end(), sizeComparator);

    dataLogF("---- Shared Buffer Stats ----\n");
    for (size_t i = 0; i < buffers.size() && i < 64; ++i) {
        CString snippet = snippetForBuffer(buffers[i]);
        dataLogF("Buffer size=%8u %s\n", buffers[i]->size(), snippet.data());
    }
}

static void didCreateSharedBuffer(SharedBuffer* buffer)
{
    MutexLocker locker(statsMutex());
    liveBuffers().add(buffer);

    callOnMainThread(printStats, 0);
}

static void willDestroySharedBuffer(SharedBuffer* buffer)
{
    MutexLocker locker(statsMutex());
    liveBuffers().remove(buffer);
}

#endif

SharedBuffer::SharedBuffer()
    : m_size(0)
    , m_buffer(PurgeableVector::NotPurgeable)
{
#ifdef SHARED_BUFFER_STATS
    didCreateSharedBuffer(this);
#endif
}

SharedBuffer::SharedBuffer(size_t size)
    : m_size(size)
    , m_buffer(PurgeableVector::NotPurgeable)
{
    m_buffer.reserveCapacity(size);
    m_buffer.grow(size);
#ifdef SHARED_BUFFER_STATS
    didCreateSharedBuffer(this);
#endif
}

SharedBuffer::SharedBuffer(const char* data, int size)
    : m_size(0)
    , m_buffer(PurgeableVector::NotPurgeable)
{
    // FIXME: Use unsigned consistently, and check for invalid casts when calling into SharedBuffer from other code.
    if (size < 0)
        CRASH();

    append(data, size);

#ifdef SHARED_BUFFER_STATS
    didCreateSharedBuffer(this);
#endif
}

SharedBuffer::SharedBuffer(const char* data, int size, PurgeableVector::PurgeableOption purgeable)
    : m_size(0)
    , m_buffer(purgeable)
{
    // FIXME: Use unsigned consistently, and check for invalid casts when calling into SharedBuffer from other code.
    if (size < 0)
        CRASH();

    append(data, size);

#ifdef SHARED_BUFFER_STATS
    didCreateSharedBuffer(this);
#endif
}

SharedBuffer::SharedBuffer(const unsigned char* data, int size)
    : m_size(0)
    , m_buffer(PurgeableVector::NotPurgeable)
{
    // FIXME: Use unsigned consistently, and check for invalid casts when calling into SharedBuffer from other code.
    if (size < 0)
        CRASH();

    append(reinterpret_cast<const char*>(data), size);

#ifdef SHARED_BUFFER_STATS
    didCreateSharedBuffer(this);
#endif
}

SharedBuffer::~SharedBuffer()
{
    clear();

#ifdef SHARED_BUFFER_STATS
    willDestroySharedBuffer(this);
#endif
}

PassRefPtr<SharedBuffer> SharedBuffer::adoptVector(Vector<char>& vector)
{
    RefPtr<SharedBuffer> buffer = create();
    buffer->m_buffer.adopt(vector);
    buffer->m_size = buffer->m_buffer.size();
    return buffer.release();
}

unsigned SharedBuffer::size() const
{
    return m_size;
}

const char* SharedBuffer::data() const
{
    mergeSegmentsIntoBuffer();
    return m_buffer.data();
}

void SharedBuffer::append(PassRefPtr<SharedBuffer> data)
{
    const char* segment;
    size_t position = 0;
    while (size_t length = data->getSomeData(segment, position)) {
        append(segment, length);
        position += length;
    }
}

void SharedBuffer::append(const char* data, unsigned length)
{
    ASSERT(isLocked());
    if (!length)
        return;

    ASSERT(m_size >= m_buffer.size());
    unsigned positionInSegment = offsetInSegment(m_size - m_buffer.size());
    m_size += length;

    if (m_size <= segmentSize) {
        // No need to use segments for small resource data.
        m_buffer.append(data, length);
        return;
    }

    char* segment;
    if (!positionInSegment) {
        segment = allocateSegment();
        m_segments.append(segment);
    } else
        segment = m_segments.last() + positionInSegment;

    unsigned segmentFreeSpace = segmentSize - positionInSegment;
    unsigned bytesToCopy = std::min(length, segmentFreeSpace);

    for (;;) {
        memcpy(segment, data, bytesToCopy);
        if (static_cast<unsigned>(length) == bytesToCopy)
            break;

        length -= bytesToCopy;
        data += bytesToCopy;
        segment = allocateSegment();
        m_segments.append(segment);
        bytesToCopy = std::min(length, segmentSize);
    }
}

void SharedBuffer::append(const Vector<char>& data)
{
    append(data.data(), data.size());
}

void SharedBuffer::clear()
{
    for (unsigned i = 0; i < m_segments.size(); ++i)
        freeSegment(m_segments[i]);

    m_segments.clear();
    m_size = 0;
    m_buffer.clear();
}

PassRefPtr<SharedBuffer> SharedBuffer::copy() const
{
    RefPtr<SharedBuffer> clone(adoptRef(new SharedBuffer));
    clone->m_size = m_size;
    clone->m_buffer.reserveCapacity(m_size);
    clone->m_buffer.append(m_buffer.data(), m_buffer.size());
    if (!m_segments.isEmpty()) {
        const char* segment = 0;
        unsigned position = m_buffer.size();
        while (unsigned segmentSize = getSomeData(segment, position)) {
            clone->m_buffer.append(segment, segmentSize);
            position += segmentSize;
        }
        ASSERT(position == clone->size());
    }
    return clone.release();
}

void SharedBuffer::mergeSegmentsIntoBuffer() const
{
    unsigned bufferSize = m_buffer.size();
    if (m_size > bufferSize) {
        m_buffer.reserveCapacity(m_size);
        unsigned bytesLeft = m_size - bufferSize;
        for (unsigned i = 0; i < m_segments.size(); ++i) {
            unsigned bytesToCopy = std::min(bytesLeft, segmentSize);
            m_buffer.append(m_segments[i], bytesToCopy);
            bytesLeft -= bytesToCopy;
            freeSegment(m_segments[i]);
        }
        m_segments.clear();
    }
}

unsigned SharedBuffer::getSomeData(const char*& someData, unsigned position) const
{
    ASSERT(isLocked());
    unsigned totalSize = size();
    if (position >= totalSize) {
        someData = 0;
        return 0;
    }

    ASSERT_WITH_SECURITY_IMPLICATION(position < m_size);
    unsigned consecutiveSize = m_buffer.size();
    if (position < consecutiveSize) {
        someData = m_buffer.data() + position;
        return consecutiveSize - position;
    }

    position -= consecutiveSize;
    unsigned segments = m_segments.size();
    unsigned maxSegmentedSize = segments * segmentSize;
    unsigned segment = segmentIndex(position);
    if (segment < segments) {
        unsigned bytesLeft = totalSize - consecutiveSize;
        unsigned segmentedSize = std::min(maxSegmentedSize, bytesLeft);

        unsigned positionInSegment = offsetInSegment(position);
        someData = m_segments[segment] + positionInSegment;
        return segment == segments - 1 ? segmentedSize - position : segmentSize - positionInSegment;
    }
    ASSERT_NOT_REACHED();
    return 0;
}

PassRefPtr<ArrayBuffer> SharedBuffer::getAsArrayBuffer() const
{
    RefPtr<ArrayBuffer> arrayBuffer = ArrayBuffer::createUninitialized(static_cast<unsigned>(size()), 1);

    if (!arrayBuffer)
        return nullptr;

    const char* segment = 0;
    unsigned position = 0;
    while (unsigned segmentSize = getSomeData(segment, position)) {
        memcpy(static_cast<char*>(arrayBuffer->data()) + position, segment, segmentSize);
        position += segmentSize;
    }

    if (position != arrayBuffer->byteLength()) {
        ASSERT_NOT_REACHED();
        // Don't return the incomplete ArrayBuffer.
        return nullptr;
    }

    return arrayBuffer;
}

PassRefPtr<SkData> SharedBuffer::getAsSkData() const
{
    unsigned bufferLength = size();
    char* buffer = static_cast<char*>(sk_malloc_throw(bufferLength));
    const char* segment = 0;
    unsigned position = 0;
    while (unsigned segmentSize = getSomeData(segment, position)) {
        memcpy(buffer + position, segment, segmentSize);
        position += segmentSize;
    }

    if (position != bufferLength) {
        ASSERT_NOT_REACHED();
        // Don't return the incomplete SkData.
        return nullptr;
    }
    return adoptRef(SkData::NewFromMalloc(buffer, bufferLength));
}

bool SharedBuffer::lock()
{
    return m_buffer.lock();
}

void SharedBuffer::unlock()
{
    mergeSegmentsIntoBuffer();
    m_buffer.unlock();
}

bool SharedBuffer::isLocked() const
{
    return m_buffer.isLocked();
}

} // namespace blink
