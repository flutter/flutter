/*
 * Copyright (C) 2013 Google, Inc. All Rights Reserved.
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
 * THIS SOFTWARE IS PROVIDED BY GOOGLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL GOOGLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef BackgroundHTMLInputStream_h
#define BackgroundHTMLInputStream_h

#include "platform/text/SegmentedString.h"
#include "wtf/Vector.h"
#include "wtf/text/WTFString.h"

namespace blink {

typedef size_t HTMLInputCheckpoint;

class BackgroundHTMLInputStream {
    WTF_MAKE_NONCOPYABLE(BackgroundHTMLInputStream);
public:
    BackgroundHTMLInputStream();

    void append(const String&);
    void close();

    SegmentedString& current() { return m_current; }

    // An HTMLInputCheckpoint is valid until the next call to rewindTo, at which
    // point all outstanding checkpoints are invalidated.
    HTMLInputCheckpoint createCheckpoint(size_t tokensExtractedSincePreviousCheckpoint);
    void invalidateCheckpointsBefore(HTMLInputCheckpoint);

    size_t totalCheckpointTokenCount() const { return m_totalCheckpointTokenCount; }

private:
    struct Checkpoint {
        Checkpoint(size_t n, size_t t) : numberOfSegmentsAlreadyAppended(n), tokensExtractedSincePreviousCheckpoint(t) { }

        size_t numberOfSegmentsAlreadyAppended;
        size_t tokensExtractedSincePreviousCheckpoint;

        void clear() { numberOfSegmentsAlreadyAppended = 0; tokensExtractedSincePreviousCheckpoint = 0;}
    };

    SegmentedString m_current;
    Vector<String> m_segments;
    Vector<Checkpoint> m_checkpoints;

    // Note: These indicies may === vector.size(), in which case there are no valid checkpoints/segments at this time.
    size_t m_firstValidCheckpointIndex;
    size_t m_firstValidSegmentIndex;
    size_t m_totalCheckpointTokenCount;

    void updateTotalCheckpointTokenCount();
};

}

#endif
