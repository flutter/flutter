/*
 * Copyright (C) 2011 Apple Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "core/css/CSSLineBoxContainValue.h"

#include "wtf/text/StringBuilder.h"
#include "wtf/text/WTFString.h"

namespace blink {

CSSLineBoxContainValue::CSSLineBoxContainValue(unsigned value)
    : CSSValue(LineBoxContainClass)
    , m_value(value)
{
}

String CSSLineBoxContainValue::customCSSText() const
{
    StringBuilder text;

    if (m_value & LineBoxContainBlock)
        text.appendLiteral("block");
    if (m_value & LineBoxContainInline) {
        if (!text.isEmpty())
            text.append(' ');
        text.appendLiteral("inline");
    }
    if (m_value & LineBoxContainFont) {
        if (!text.isEmpty())
            text.append(' ');
        text.appendLiteral("font");
    }
    if (m_value & LineBoxContainGlyphs) {
        if (!text.isEmpty())
            text.append(' ');
        text.appendLiteral("glyphs");
    }
    if (m_value & LineBoxContainReplaced) {
        if (!text.isEmpty())
            text.append(' ');
        text.appendLiteral("replaced");
    }
    if (m_value & LineBoxContainInlineBox) {
        if (!text.isEmpty())
            text.append(' ');
        text.appendLiteral("inline-box");
    }

    return text.toString();
}

}
