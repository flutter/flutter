/*
 * Copyright (c) 2010 Google Inc. All rights reserved.
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
#include "core/css/CSSOMUtils.h"

#include "wtf/HexNumber.h"
#include "wtf/text/StringBuilder.h"

namespace blink {

void serializeCharacter(UChar32 c, StringBuilder& appendTo)
{
    appendTo.append('\\');
    appendTo.append(c);
}

void serializeCharacterAsCodePoint(UChar32 c, StringBuilder& appendTo)
{
    appendTo.append('\\');
    appendUnsignedAsHex(c, appendTo, Lowercase);
    appendTo.append(' ');
}

void serializeIdentifier(const String& identifier, StringBuilder& appendTo)
{
    bool isFirst = true;
    bool isSecond = false;
    bool isFirstCharHyphen = false;
    unsigned index = 0;
    while (index < identifier.length()) {
        UChar32 c = identifier.characterStartingAt(index);
        index += U16_LENGTH(c);

        if (c <= 0x1f || (0x30 <= c && c <= 0x39 && (isFirst || (isSecond && isFirstCharHyphen))))
            serializeCharacterAsCodePoint(c, appendTo);
        else if (c == 0x2d && isSecond && isFirstCharHyphen)
            serializeCharacter(c, appendTo);
        else if (0x80 <= c || c == 0x2d || c == 0x5f || (0x30 <= c && c <= 0x39) || (0x41 <= c && c <= 0x5a) || (0x61 <= c && c <= 0x7a))
            appendTo.append(c);
        else
            serializeCharacter(c, appendTo);

        if (isFirst) {
            isFirst = false;
            isSecond = true;
            isFirstCharHyphen = (c == 0x2d);
        } else if (isSecond) {
            isSecond = false;
        }
    }
}

void serializeString(const String& string, StringBuilder& appendTo)
{
    appendTo.append('\"');

    unsigned index = 0;
    while (index < string.length()) {
        UChar32 c = string.characterStartingAt(index);
        index += U16_LENGTH(c);
        if (c <= 0x1f)
            serializeCharacterAsCodePoint(c, appendTo);
        else if (c == 0x22 || c == 0x5c)
            serializeCharacter(c, appendTo);
        else
            appendTo.append(c);
    }

    appendTo.append('\"');
}

} // namespace blink
