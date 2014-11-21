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

#ifndef SKY_ENGINE_CORE_HTML_PARSER_COMPACTHTMLTOKEN_H_
#define SKY_ENGINE_CORE_HTML_PARSER_COMPACTHTMLTOKEN_H_

#include "sky/engine/core/html/parser/HTMLToken.h"
#include "sky/engine/wtf/Vector.h"
#include "sky/engine/wtf/text/TextPosition.h"
#include "sky/engine/wtf/text/WTFString.h"

namespace blink {

class QualifiedName;

class CompactHTMLToken {
public:
    struct Attribute {
        Attribute(const String& name, const String& value)
            : name(name)
            , value(value)
        {
        }

        String name;
        String value;
    };

    CompactHTMLToken(const HTMLToken*, const TextPosition&);

    bool isSafeToSendToAnotherThread() const;

    HTMLToken::Type type() const { return static_cast<HTMLToken::Type>(m_type); }
    const String& data() const { return m_data; }
    bool selfClosing() const { return m_selfClosing; }
    bool isAll8BitData() const { return m_isAll8BitData; }
    const Vector<Attribute>& attributes() const { return m_attributes; }
    const Attribute* getAttributeItem(const QualifiedName&) const;
    const TextPosition& textPosition() const { return m_textPosition; }

private:
    unsigned m_type : 4;
    unsigned m_selfClosing : 1;
    unsigned m_isAll8BitData : 1;

    String m_data; // "name", "characters", or "data" depending on m_type
    Vector<Attribute> m_attributes;
    TextPosition m_textPosition;
};

typedef Vector<CompactHTMLToken> CompactHTMLTokenStream;

}

#endif  // SKY_ENGINE_CORE_HTML_PARSER_COMPACTHTMLTOKEN_H_
