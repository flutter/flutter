// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MediaQueryInputStream_h
#define MediaQueryInputStream_h

#include "wtf/text/WTFString.h"

namespace blink {

class MediaQueryInputStream {
    WTF_MAKE_NONCOPYABLE(MediaQueryInputStream);
    WTF_MAKE_FAST_ALLOCATED;
public:
    MediaQueryInputStream(String input);

    UChar peek(unsigned);
    inline UChar nextInputChar()
    {
        return peek(0);
    }

    void advance(unsigned = 1);
    void pushBack(UChar);

    inline size_t maxLength()
    {
        return m_string.length() + 1;
    }

    inline size_t leftChars()
    {
        return m_string.length() - m_offset;

    }

    unsigned long long getUInt(unsigned start, unsigned end);
    double getDouble(unsigned start, unsigned end);

    template<bool characterPredicate(UChar)>
    unsigned skipWhilePredicate(unsigned offset)
    {
        while ((m_offset + offset) < m_string.length() && characterPredicate(m_string[m_offset + offset]))
            ++offset;
        return offset;
    }

private:
    size_t m_offset;
    String m_string;
};

} // namespace blink

#endif // MediaQueryInputStream_h

