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
#include "core/css/CSSFilterValue.h"

#include "wtf/text/StringBuilder.h"

namespace blink {

CSSFilterValue::CSSFilterValue(FilterOperationType operationType)
    : CSSValueList(CSSFilterClass, CommaSeparator)
    , m_type(operationType)
{
}

String CSSFilterValue::customCSSText() const
{
    StringBuilder result;
    switch (m_type) {
    case ReferenceFilterOperation:
        result.appendLiteral("url(");
        break;
    case GrayscaleFilterOperation:
        result.appendLiteral("grayscale(");
        break;
    case SepiaFilterOperation:
        result.appendLiteral("sepia(");
        break;
    case SaturateFilterOperation:
        result.appendLiteral("saturate(");
        break;
    case HueRotateFilterOperation:
        result.appendLiteral("hue-rotate(");
        break;
    case InvertFilterOperation:
        result.appendLiteral("invert(");
        break;
    case OpacityFilterOperation:
        result.appendLiteral("opacity(");
        break;
    case BrightnessFilterOperation:
        result.appendLiteral("brightness(");
        break;
    case ContrastFilterOperation:
        result.appendLiteral("contrast(");
        break;
    case BlurFilterOperation:
        result.appendLiteral("blur(");
        break;
    case DropShadowFilterOperation:
        result.appendLiteral("drop-shadow(");
        break;
    default:
        break;
    }

    result.append(CSSValueList::customCSSText());
    result.append(')');
    return result.toString();
}

CSSFilterValue::CSSFilterValue(const CSSFilterValue& cloneFrom)
    : CSSValueList(cloneFrom)
    , m_type(cloneFrom.m_type)
{
}

PassRefPtrWillBeRawPtr<CSSFilterValue> CSSFilterValue::cloneForCSSOM() const
{
    return adoptRefWillBeNoop(new CSSFilterValue(*this));
}

bool CSSFilterValue::equals(const CSSFilterValue& other) const
{
    return m_type == other.m_type && CSSValueList::equals(other);
}

}

