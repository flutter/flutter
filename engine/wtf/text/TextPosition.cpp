/*
 * Copyright (C) 2013, Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "wtf/text/TextPosition.h"

#include "wtf/PassOwnPtr.h"
#include "wtf/StdLibExtras.h"

namespace WTF {

PassOwnPtr<Vector<unsigned> > lineEndings(const String& text)
{
    OwnPtr<Vector<unsigned> > result(adoptPtr(new Vector<unsigned>()));

    unsigned start = 0;
    while (start < text.length()) {
        size_t lineEnd = text.find('\n', start);
        if (lineEnd == kNotFound)
            break;

        result->append(static_cast<unsigned>(lineEnd));
        start = lineEnd + 1;
    }
    result->append(text.length());

    return result.release();
}

OrdinalNumber TextPosition::toOffset(const Vector<unsigned>& lineEndings)
{
    unsigned lineStartOffset = m_line != OrdinalNumber::first() ? lineEndings.at(m_line.zeroBasedInt() - 1) + 1 : 0;
    return OrdinalNumber::fromZeroBasedInt(lineStartOffset + m_column.zeroBasedInt());
}

TextPosition TextPosition::fromOffsetAndLineEndings(unsigned offset, const Vector<unsigned>& lineEndings)
{
    const unsigned* foundLineEnding = std::lower_bound(lineEndings.begin(), lineEndings.end(), offset);
    int lineIndex = foundLineEnding - &lineEndings.at(0);
    unsigned lineStartOffset = lineIndex > 0 ? lineEndings.at(lineIndex - 1) + 1 : 0;
    int column = offset - lineStartOffset;
    return TextPosition(OrdinalNumber::fromZeroBasedInt(lineIndex), OrdinalNumber::fromZeroBasedInt(column));
}

} // namespace WTF
