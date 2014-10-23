/*
 * Copyright (C) 2004, 2008 Apple Inc.  All rights reserved.
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
#include "core/editing/HTMLInterchange.h"

#include "core/dom/Text.h"
#include "core/editing/htmlediting.h"
#include "core/rendering/RenderObject.h"
#include "core/rendering/RenderText.h"
#include "wtf/text/StringBuilder.h"
#include "wtf/unicode/CharacterNames.h"

namespace blink {

String convertHTMLTextToInterchangeFormat(const String& in, const Text& node)
{
    // Assume all the text comes from node.
    if (node.renderer() && node.renderer()->style()->preserveNewline())
        return in;

    const char convertedSpaceString[] = "<span class=\"" AppleConvertedSpace "\">\xA0</span>";
    COMPILE_ASSERT((static_cast<unsigned char>('\xA0') == noBreakSpace), ConvertedSpaceStringSpaceIsNoBreakSpace);

    StringBuilder s;

    unsigned i = 0;
    unsigned consumed = 0;
    while (i < in.length()) {
        consumed = 1;
        if (isCollapsibleWhitespace(in[i])) {
            // count number of adjoining spaces
            unsigned j = i + 1;
            while (j < in.length() && isCollapsibleWhitespace(in[j]))
                j++;
            unsigned count = j - i;
            consumed = count;
            while (count) {
                unsigned add = count % 3;
                switch (add) {
                    case 0:
                        s.appendLiteral(convertedSpaceString);
                        s.append(' ');
                        s.appendLiteral(convertedSpaceString);
                        add = 3;
                        break;
                    case 1:
                        if (i == 0 || i + 1 == in.length()) // at start or end of string
                            s.appendLiteral(convertedSpaceString);
                        else
                            s.append(' ');
                        break;
                    case 2:
                        if (i == 0) {
                             // at start of string
                            s.appendLiteral(convertedSpaceString);
                            s.append(' ');
                        } else if (i + 2 == in.length()) {
                             // at end of string
                            s.appendLiteral(convertedSpaceString);
                            s.appendLiteral(convertedSpaceString);
                        } else {
                            s.appendLiteral(convertedSpaceString);
                            s.append(' ');
                        }
                        break;
                }
                count -= add;
            }
        } else
            s.append(in[i]);
        i += consumed;
    }

    return s.toString();
}

} // namespace blink
