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

#include "config.h"
#include "core/css/CSSTransformValue.h"

#include "wtf/text/WTFString.h"

namespace blink {

// These names must be kept in sync with TransformOperationType.
const char* const transformNamePrefixes[] = {
    0,
    "translate(",
    "translateX(",
    "translateY(",
    "rotate(",
    "scale(",
    "scaleX(",
    "scaleY(",
    "skew(",
    "skewX(",
    "skewY(",
    "matrix(",
    "translateZ(",
    "translate3d(",
    "rotateX(",
    "rotateY(",
    "rotateZ(",
    "rotate3d(",
    "scaleZ(",
    "scale3d(",
    "perspective(",
    "matrix3d("
};

static inline String transformValueToCssString(CSSTransformValue::TransformOperationType operation, const String& value)
{
    if (operation != CSSTransformValue::UnknownTransformOperation) {
        ASSERT_WITH_SECURITY_IMPLICATION(static_cast<size_t>(operation) < WTF_ARRAY_LENGTH(transformNamePrefixes));
        return transformNamePrefixes[operation] + value + ")";
    }
    return String();
}

CSSTransformValue::CSSTransformValue(TransformOperationType op)
    : CSSValueList(CSSTransformClass, CommaSeparator)
    , m_type(op)
{
}

String CSSTransformValue::customCSSText() const
{
    return transformValueToCssString(m_type, CSSValueList::customCSSText());
}

CSSTransformValue::CSSTransformValue(const CSSTransformValue& cloneFrom)
    : CSSValueList(cloneFrom)
    , m_type(cloneFrom.m_type)
{
}

PassRefPtrWillBeRawPtr<CSSTransformValue> CSSTransformValue::cloneForCSSOM() const
{
    return adoptRefWillBeNoop(new CSSTransformValue(*this));
}

}
