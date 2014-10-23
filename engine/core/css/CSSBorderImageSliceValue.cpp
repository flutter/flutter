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
#include "core/css/CSSBorderImageSliceValue.h"

#include "wtf/text/WTFString.h"

namespace blink {

CSSBorderImageSliceValue::CSSBorderImageSliceValue(PassRefPtrWillBeRawPtr<CSSPrimitiveValue> slices, bool fill)
    : CSSValue(BorderImageSliceClass)
    , m_slices(slices)
    , m_fill(fill)
{
}

String CSSBorderImageSliceValue::customCSSText() const
{
    // Dump the slices first.
    String text = m_slices->cssText();

    // Now the fill keywords if it is present.
    if (m_fill)
        return text + " fill";
    return text;
}

bool CSSBorderImageSliceValue::equals(const CSSBorderImageSliceValue& other) const
{
    return m_fill == other.m_fill && compareCSSValuePtr(m_slices, other.m_slices);
}

void CSSBorderImageSliceValue::traceAfterDispatch(Visitor* visitor)
{
    visitor->trace(m_slices);
    CSSValue::traceAfterDispatch(visitor);
}

} // namespace blink
