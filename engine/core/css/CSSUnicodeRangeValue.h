/*
 * Copyright (C) 2008 Apple Inc. All rights reserved.
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

#ifndef CSSUnicodeRangeValue_h
#define CSSUnicodeRangeValue_h

#include "core/css/CSSValue.h"
#include "wtf/PassRefPtr.h"

namespace blink {

class CSSUnicodeRangeValue : public CSSValue {
public:
    static PassRefPtrWillBeRawPtr<CSSUnicodeRangeValue> create(UChar32 from, UChar32 to)
    {
        return adoptRefWillBeNoop(new CSSUnicodeRangeValue(from, to));
    }

    UChar32 from() const { return m_from; }
    UChar32 to() const { return m_to; }

    String customCSSText() const;

    bool equals(const CSSUnicodeRangeValue&) const;

    void traceAfterDispatch(Visitor* visitor) { CSSValue::traceAfterDispatch(visitor); }

private:
    CSSUnicodeRangeValue(UChar32 from, UChar32 to)
        : CSSValue(UnicodeRangeClass)
        , m_from(from)
        , m_to(to)
    {
    }

    UChar32 m_from;
    UChar32 m_to;
};

DEFINE_CSS_VALUE_TYPE_CASTS(CSSUnicodeRangeValue, isUnicodeRangeValue());

} // namespace blink

#endif // CSSUnicodeRangeValue_h
