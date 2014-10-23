/*
 * Copyright (C) 2010 Google, Inc. All Rights Reserved.
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

#ifndef HTMLInputStream_h
#define HTMLInputStream_h

#include "core/html/parser/InputStreamPreprocessor.h"
#include "platform/text/SegmentedString.h"

namespace blink {

// The InputStream is made up of a sequence of SegmentedStrings:
//
// [--current--][--next--][--next--] ... [--next--]
//            /\                         (also called m_last)
//            L_ current insertion point
//
// The current segmented string is stored in InputStream.  Each of the
// afterInsertionPoint buffers are stored in InsertionPointRecords on the
// stack.
//
// We remove characters from the "current" string in the InputStream.
// document.write() will add characters at the current insertion point,
// which appends them to the "current" string.
//
// m_last is a pointer to the last of the afterInsertionPoint strings.
// The network adds data at the end of the InputStream, which appends
// them to the "last" string.
class HTMLInputStream {
    WTF_MAKE_NONCOPYABLE(HTMLInputStream);
public:
    HTMLInputStream()
        : m_last(&m_first)
    {
    }

    void appendToEnd(const SegmentedString& string)
    {
        m_last->append(string);
    }

    void insertAtCurrentInsertionPoint(const SegmentedString& string)
    {
        m_first.append(string);
    }

    bool hasInsertionPoint() const
    {
        return &m_first != m_last;
    }

    void markEndOfFile()
    {
        m_last->append(SegmentedString(String(&kEndOfFileMarker, 1)));
        m_last->close();
    }

    void closeWithoutMarkingEndOfFile()
    {
        m_last->close();
    }

    bool haveSeenEndOfFile() const
    {
        return m_last->isClosed();
    }

    SegmentedString& current() { return m_first; }
    const SegmentedString& current() const { return m_first; }

    void splitInto(SegmentedString& next)
    {
        next = m_first;
        m_first = SegmentedString();
        if (m_last == &m_first) {
            // We used to only have one SegmentedString in the InputStream
            // but now we have two.  That means m_first is no longer also
            // the m_last string, |next| is now the last one.
            m_last = &next;
        }
    }

    void mergeFrom(SegmentedString& next)
    {
        m_first.append(next);
        if (m_last == &next) {
            // The string |next| used to be the last SegmentedString in
            // the InputStream.  Now that it's been merged into m_first,
            // that makes m_first the last one.
            m_last = &m_first;
        }
        if (next.isClosed()) {
            // We also need to merge the "closed" state from next to
            // m_first.  Arguably, this work could be done in append().
            m_first.close();
        }
    }

private:
    SegmentedString m_first;
    SegmentedString* m_last;
};

class InsertionPointRecord {
    WTF_MAKE_NONCOPYABLE(InsertionPointRecord);
public:
    explicit InsertionPointRecord(HTMLInputStream& inputStream)
        : m_inputStream(&inputStream)
    {
        m_line = m_inputStream->current().currentLine();
        m_column = m_inputStream->current().currentColumn();
        m_inputStream->splitInto(m_next);
        // We 'fork' current position and use it for the generated script part.
        // This is a bit weird, because generated part does not have positions within an HTML document.
        m_inputStream->current().setCurrentPosition(m_line, m_column, 0);
    }

    ~InsertionPointRecord()
    {
        // Some inserted text may have remained in input stream. E.g. if script has written "&amp" or "<table",
        // it stays in buffer because it cannot be properly tokenized before we see next part.
        int unparsedRemainderLength = m_inputStream->current().length();
        m_inputStream->mergeFrom(m_next);
        // We restore position for the character that goes right after unparsed remainder.
        m_inputStream->current().setCurrentPosition(m_line, m_column, unparsedRemainderLength);
    }

private:
    HTMLInputStream* m_inputStream;
    SegmentedString m_next;
    OrdinalNumber m_line;
    OrdinalNumber m_column;
};

}

#endif
