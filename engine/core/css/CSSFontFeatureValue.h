/*
 * Copyright (C) 2011 Google Inc. All rights reserved.
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

#ifndef CSSFontFeatureValue_h
#define CSSFontFeatureValue_h

#include "core/css/CSSValue.h"
#include "wtf/text/WTFString.h"

namespace blink {

class CSSFontFeatureValue : public CSSValue {
public:
    static PassRefPtrWillBeRawPtr<CSSFontFeatureValue> create(const AtomicString& tag, int value)
    {
        return adoptRefWillBeNoop(new CSSFontFeatureValue(tag, value));
    }

    const AtomicString& tag() const { return m_tag; }
    int value() const { return m_value; }
    String customCSSText() const;

    bool equals(const CSSFontFeatureValue&) const;

    void traceAfterDispatch(Visitor* visitor) { CSSValue::traceAfterDispatch(visitor); }

private:
    CSSFontFeatureValue(const AtomicString& tag, int value);

    AtomicString m_tag;
    const int m_value;
};

DEFINE_CSS_VALUE_TYPE_CASTS(CSSFontFeatureValue, isFontFeatureValue());

} // namespace

#endif
