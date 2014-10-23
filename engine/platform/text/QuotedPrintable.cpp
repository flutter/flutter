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

#include "config.h"
#include "platform/text/QuotedPrintable.h"

#include "wtf/ASCIICType.h"

namespace blink {

static const size_t maximumLineLength = 76;

static const char crlfLineEnding[] = "\r\n";

static size_t lengthOfLineEndingAtIndex(const char* input, size_t inputLength, size_t index)
{
    ASSERT_WITH_SECURITY_IMPLICATION(index < inputLength);
    if (input[index] == '\n')
        return 1; // Single LF.

    if (input[index] == '\r') {
        if ((index + 1) == inputLength || input[index + 1] != '\n')
            return 1; // Single CR (Classic Mac OS).
        return 2; // CR-LF.
    }

    return 0;
}

void quotedPrintableEncode(const Vector<char>& in, Vector<char>& out)
{
    quotedPrintableEncode(in.data(), in.size(), out);
}

void quotedPrintableEncode(const char* input, size_t inputLength, Vector<char>& out)
{
    out.clear();
    out.reserveCapacity(inputLength);
    size_t currentLineLength = 0;
    for (size_t i = 0; i < inputLength; ++i) {
        bool isLastCharacter = (i == inputLength - 1);
        char currentCharacter = input[i];
        bool requiresEncoding = false;
        // All non-printable ASCII characters and = require encoding.
        if ((currentCharacter < ' ' || currentCharacter > '~' || currentCharacter == '=') && currentCharacter != '\t')
            requiresEncoding = true;

        // Space and tab characters have to be encoded if they appear at the end of a line.
        if (!requiresEncoding && (currentCharacter == '\t' || currentCharacter == ' ') && (isLastCharacter || lengthOfLineEndingAtIndex(input, inputLength, i + 1)))
            requiresEncoding = true;

        // End of line should be converted to CR-LF sequences.
        if (!isLastCharacter) {
            size_t lengthOfLineEnding = lengthOfLineEndingAtIndex(input, inputLength, i);
            if (lengthOfLineEnding) {
                out.append(crlfLineEnding, strlen(crlfLineEnding));
                currentLineLength = 0;
                i += (lengthOfLineEnding - 1); // -1 because we'll ++ in the for() above.
                continue;
            }
        }

        size_t lengthOfEncodedCharacter = 1;
        if (requiresEncoding)
            lengthOfEncodedCharacter += 2;
        if (!isLastCharacter)
            lengthOfEncodedCharacter += 1; // + 1 for the = (soft line break).

        // Insert a soft line break if necessary.
        if (currentLineLength + lengthOfEncodedCharacter > maximumLineLength) {
            out.append('=');
            out.append(crlfLineEnding, strlen(crlfLineEnding));
            currentLineLength = 0;
        }

        // Finally, insert the actual character(s).
        if (requiresEncoding) {
            out.append('=');
            out.append(upperNibbleToASCIIHexDigit(currentCharacter));
            out.append(lowerNibbleToASCIIHexDigit(currentCharacter));
            currentLineLength += 3;
        } else {
            out.append(currentCharacter);
            currentLineLength++;
        }
    }
}

void quotedPrintableDecode(const Vector<char>& in, Vector<char>& out)
{
    quotedPrintableDecode(in.data(), in.size(), out);
}

void quotedPrintableDecode(const char* data, size_t dataLength, Vector<char>& out)
{
    out.clear();
    if (!dataLength)
        return;

    for (size_t i = 0; i < dataLength; ++i) {
        char currentCharacter = data[i];
        if (currentCharacter != '=') {
            out.append(currentCharacter);
            continue;
        }
        // We are dealing with a '=xx' sequence.
        if (dataLength - i < 3) {
            // Unfinished = sequence, append as is.
            out.append(currentCharacter);
            continue;
        }
        char upperCharacter = data[++i];
        char lowerCharacter = data[++i];
        if (upperCharacter == '\r' && lowerCharacter == '\n')
            continue;

        if (!isASCIIHexDigit(upperCharacter) || !isASCIIHexDigit(lowerCharacter)) {
            // Invalid sequence, = followed by non hex digits, just insert the characters as is.
            out.append('=');
            out.append(upperCharacter);
            out.append(lowerCharacter);
            continue;
        }
        out.append(static_cast<char>(toASCIIHexValue(upperCharacter, lowerCharacter)));
    }
}

}
