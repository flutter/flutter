/*
 * Copyright (C) 2008, 2010 Apple Inc. All Rights Reserved.
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

#include "config.h"
#include "core/css/CSSFunctionValue.h"

#include "core/css/CSSValueList.h"
#include "wtf/text/StringBuilder.h"

namespace blink {

CSSFunctionValue::CSSFunctionValue(String name, PassRefPtrWillBeRawPtr<CSSValueList> args)
    : CSSValue(FunctionClass)
    , m_name(name)
    , m_args(args)
{
}

String CSSFunctionValue::customCSSText() const
{
    StringBuilder result;
    result.append(m_name); // Includes the '('
    if (m_args)
        result.append(m_args->cssText());
    result.append(')');
    return result.toString();
}

bool CSSFunctionValue::equals(const CSSFunctionValue& other) const
{
    return m_name == other.m_name && compareCSSValuePtr(m_args, other.m_args);
}

void CSSFunctionValue::traceAfterDispatch(Visitor* visitor)
{
    visitor->trace(m_args);
    CSSValue::traceAfterDispatch(visitor);
}

}
