/*
 * Copyright (C) 2012 Adobe Systems Incorporated. All rights reserved.
 * Copyright (C) 2012 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer.
 * 2. Redistributions in binary form must reproduce the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer in the documentation and/or other materials
 *    provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER “AS IS” AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
 * OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
 * THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#ifndef SKY_ENGINE_CORE_CSS_PARSER_CSSPARSERMODE_H_
#define SKY_ENGINE_CORE_CSS_PARSER_CSSPARSERMODE_H_

#include "sky/engine/platform/weborigin/KURL.h"
#include "sky/engine/platform/weborigin/Referrer.h"

namespace blink {

class Document;

enum CSSParserMode {
    HTMLStandardMode,
};

inline bool isQuirksModeBehavior(CSSParserMode mode)
{
    return false;
}

inline bool isUASheetBehavior(CSSParserMode mode)
{
    return false;
}

inline bool isInternalPropertyAndValueParsingEnabledForMode(CSSParserMode mode)
{
    return false;
}

inline bool isUnitLessLengthParsingEnabledForMode(CSSParserMode mode)
{
    return false;
}

inline bool isCSSViewportParsingEnabledForMode(CSSParserMode mode)
{
    return false;
}

class CSSParserContext {
    WTF_MAKE_FAST_ALLOCATED;
public:
    explicit CSSParserContext();
    CSSParserContext(const Document&, const KURL& baseURL = KURL());
    CSSParserContext(const CSSParserContext&);

    bool operator==(const CSSParserContext&) const;
    bool operator!=(const CSSParserContext& other) const { return !(*this == other); }

    CSSParserMode mode() const { return HTMLStandardMode; }
    const KURL& baseURL() const { return m_baseURL; }
    const Referrer& referrer() const { return m_referrer; }

    // This causes CSS parsing to be case insensitive and should be removed.
    bool isHTMLDocument() const { return true; }

    // FIXME: These setters shouldn't exist, however the current lifetime of CSSParserContext
    // is not well understood and thus we sometimes need to override these fields.
    void setBaseURL(const KURL& baseURL) { m_baseURL = baseURL; }
    void setReferrer(const Referrer& referrer) { m_referrer = referrer; }

    KURL completeURL(const String& url) const;

private:
    KURL m_baseURL;
    Referrer m_referrer;
};

const CSSParserContext& strictCSSParserContext();

};

#endif  // SKY_ENGINE_CORE_CSS_PARSER_CSSPARSERMODE_H_
