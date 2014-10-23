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

#ifndef CSSFilterValue_h
#define CSSFilterValue_h

#include "core/css/CSSValueList.h"
#include "wtf/PassRefPtr.h"

namespace blink {

class CSSFilterValue : public CSSValueList {
public:
    // NOTE: these have to match the values in the IDL
    enum FilterOperationType {
        UnknownFilterOperation,
        ReferenceFilterOperation,
        GrayscaleFilterOperation,
        SepiaFilterOperation,
        SaturateFilterOperation,
        HueRotateFilterOperation,
        InvertFilterOperation,
        OpacityFilterOperation,
        BrightnessFilterOperation,
        ContrastFilterOperation,
        BlurFilterOperation,
        DropShadowFilterOperation,
    };

    static bool typeUsesSpaceSeparator(FilterOperationType);

    static PassRefPtrWillBeRawPtr<CSSFilterValue> create(FilterOperationType type)
    {
        return adoptRefWillBeNoop(new CSSFilterValue(type));
    }

    String customCSSText() const;

    FilterOperationType operationType() const { return m_type; }

    PassRefPtrWillBeRawPtr<CSSFilterValue> cloneForCSSOM() const;

    bool equals(const CSSFilterValue&) const;

    void traceAfterDispatch(Visitor* visitor) { CSSValueList::traceAfterDispatch(visitor); }

private:
    explicit CSSFilterValue(FilterOperationType);
    explicit CSSFilterValue(const CSSFilterValue& cloneFrom);

    FilterOperationType m_type;
};

DEFINE_CSS_VALUE_TYPE_CASTS(CSSFilterValue, isFilterValue());

}


#endif
