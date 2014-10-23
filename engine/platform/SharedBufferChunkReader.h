/*
 * Copyright (C) 2011 Google Inc. All rights reserved.
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

#ifndef SharedBufferChunkReader_h
#define SharedBufferChunkReader_h

#include "platform/PlatformExport.h"
#include "wtf/Vector.h"
#include "wtf/text/WTFString.h"

namespace blink {

class SharedBuffer;

class PLATFORM_EXPORT SharedBufferChunkReader {
public:
    SharedBufferChunkReader(SharedBuffer*, const Vector<char>& separator);
    SharedBufferChunkReader(SharedBuffer*, const char* separator);

    void setSeparator(const Vector<char>&);
    void setSeparator(const char*);

    // Returns false when the end of the buffer was reached.
    bool nextChunk(Vector<char>& data, bool includeSeparator = false);

    // Returns a null string when the end of the buffer has been reached.
    String nextChunkAsUTF8StringWithLatin1Fallback(bool includeSeparator = false);

    // Reads size bytes at the current location in the buffer, without changing the buffer position.
    // Returns the number of bytes read. That number might be less than the specified size if the end of the buffer was reached.
    size_t peek(Vector<char>&, size_t);

private:
    SharedBuffer* m_buffer;
    size_t m_bufferPosition;
    const char* m_segment;
    size_t m_segmentLength;
    size_t m_segmentIndex;
    bool m_reachedEndOfFile;
    Vector<char> m_separator;
    size_t m_separatorIndex;
};

}

#endif
