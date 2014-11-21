/*
 * Copyright (C) 2008 Apple Inc. All Rights Reserved.
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

#ifndef SKY_ENGINE_CORE_HTML_PARSER_HTMLENTITYPARSER_H_
#define SKY_ENGINE_CORE_HTML_PARSER_HTMLENTITYPARSER_H_

#include "sky/engine/platform/text/SegmentedString.h"

namespace blink {

class HTMLEntityParser {
public:
    typedef Vector<UChar, 32> OutputBuffer;

    HTMLEntityParser();
    ~HTMLEntityParser();

    void reset();
    bool parse(SegmentedString&);

    const OutputBuffer& result() const { return m_buffer; }

private:
    enum EntityState {
        Initial,
        Numeric,
        PossiblyHex,
        Hex,
        Decimal,
        Named
    };

    void finalizeNumericEntity();
    void finalizeNamedEntity();

    EntityState m_state;
    UChar32 m_result;
    OutputBuffer m_buffer;
};

}

#endif  // SKY_ENGINE_CORE_HTML_PARSER_HTMLENTITYPARSER_H_
