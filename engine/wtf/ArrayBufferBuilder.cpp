/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
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

#include "config.h"
#include "wtf/ArrayBufferBuilder.h"

#include "wtf/Assertions.h"
#include <limits>

namespace WTF {

static const int defaultBufferCapacity = 32768;

ArrayBufferBuilder::ArrayBufferBuilder()
    : m_bytesUsed(0)
    , m_variableCapacity(true)
{
    m_buffer = ArrayBuffer::create(defaultBufferCapacity, 1);
}

bool ArrayBufferBuilder::expandCapacity(unsigned sizeToIncrease)
{
    unsigned currentBufferSize = m_buffer->byteLength();

    // If the size of the buffer exceeds max of unsigned, it can't be grown any
    // more.
    if (sizeToIncrease > std::numeric_limits<unsigned>::max() - m_bytesUsed)
        return false;

    unsigned newBufferSize = m_bytesUsed + sizeToIncrease;

    // Grow exponentially if possible.
    unsigned exponentialGrowthNewBufferSize = std::numeric_limits<unsigned>::max();
    if (currentBufferSize <= std::numeric_limits<unsigned>::max() / 2)
        exponentialGrowthNewBufferSize = currentBufferSize * 2;
    if (exponentialGrowthNewBufferSize > newBufferSize)
        newBufferSize = exponentialGrowthNewBufferSize;

    // Copy existing data in current buffer to new buffer.
    RefPtr<ArrayBuffer> newBuffer = ArrayBuffer::create(newBufferSize, 1);
    if (!newBuffer)
        return false;

    memcpy(newBuffer->data(), m_buffer->data(), m_bytesUsed);
    m_buffer = newBuffer;
    return true;
}

unsigned ArrayBufferBuilder::append(const char* data, unsigned length)
{
    ASSERT(length > 0);

    unsigned currentBufferSize = m_buffer->byteLength();

    ASSERT(m_bytesUsed <= currentBufferSize);

    unsigned remainingBufferSpace = currentBufferSize - m_bytesUsed;

    unsigned bytesToSave = length;

    if (length > remainingBufferSpace) {
        if (m_variableCapacity) {
            if (!expandCapacity(length))
                return 0;
        } else {
            bytesToSave = remainingBufferSpace;
        }
    }

    memcpy(static_cast<char*>(m_buffer->data()) + m_bytesUsed, data, bytesToSave);
    m_bytesUsed += bytesToSave;

    return bytesToSave;
}

PassRefPtr<ArrayBuffer> ArrayBufferBuilder::toArrayBuffer()
{
    // Fully used. Return m_buffer as-is.
    if (m_buffer->byteLength() == m_bytesUsed)
        return m_buffer;

    return m_buffer->slice(0, m_bytesUsed);
}

String ArrayBufferBuilder::toString()
{
    return String(static_cast<const char*>(m_buffer->data()), m_bytesUsed);
}

void ArrayBufferBuilder::shrinkToFit()
{
    ASSERT(m_bytesUsed <= m_buffer->byteLength());

    if (m_buffer->byteLength() > m_bytesUsed)
        m_buffer = m_buffer->slice(0, m_bytesUsed);
}

} // namespace WTF
