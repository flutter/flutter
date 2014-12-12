/*
 * Copyright (C) 2007, 2008 Apple Inc. All rights reserved.
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

#ifndef SKY_ENGINE_CORE_CSS_CSSFONTFACESRCVALUE_H_
#define SKY_ENGINE_CORE_CSS_CSSFONTFACESRCVALUE_H_

#include "sky/engine/core/css/CSSValue.h"
#include "sky/engine/core/fetch/ResourcePtr.h"
#include "sky/engine/platform/weborigin/Referrer.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/text/WTFString.h"

namespace blink {

class FontResource;
class Document;
class SVGFontFaceElement;

class CSSFontFaceSrcValue : public CSSValue {
public:
    static PassRefPtr<CSSFontFaceSrcValue> create(const String& resource)
    {
        return adoptRef(new CSSFontFaceSrcValue(resource, false));
    }
    static PassRefPtr<CSSFontFaceSrcValue> createLocal(const String& resource)
    {
        return adoptRef(new CSSFontFaceSrcValue(resource, true));
    }

    const String& resource() const { return m_resource; }
    const String& format() const { return m_format; }
    bool isLocal() const { return m_isLocal; }

    void setFormat(const String& format) { m_format = format; }
    void setReferrer(const Referrer& referrer) { m_referrer = referrer; }

    bool isSupportedFormat() const;

    String customCSSText() const;

    FontResource* fetch(Document*);

    bool equals(const CSSFontFaceSrcValue&) const;

private:
    CSSFontFaceSrcValue(const String& resource, bool local)
        : CSSValue(FontFaceSrcClass)
        , m_resource(resource)
        , m_isLocal(local)
    {
    }

    void restoreCachedResourceIfNeeded(Document*);

    String m_resource;
    String m_format;
    Referrer m_referrer;
    bool m_isLocal;

    ResourcePtr<FontResource> m_fetched;
};

DEFINE_CSS_VALUE_TYPE_CASTS(CSSFontFaceSrcValue, isFontFaceSrcValue());

}

#endif  // SKY_ENGINE_CORE_CSS_CSSFONTFACESRCVALUE_H_
