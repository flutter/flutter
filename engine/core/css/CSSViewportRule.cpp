/*
 * Copyright (C) 2012 Intel Corporation. All rights reserved.
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

#include "config.h"
#include "core/css/CSSViewportRule.h"

#include "core/css/PropertySetCSSStyleDeclaration.h"
#include "core/css/StylePropertySet.h"
#include "core/css/StyleRule.h"
#include "wtf/text/StringBuilder.h"

namespace blink {

CSSViewportRule::CSSViewportRule(StyleRuleViewport* viewportRule, CSSStyleSheet* sheet)
    : CSSRule(sheet)
    , m_viewportRule(viewportRule)
{
}

CSSViewportRule::~CSSViewportRule()
{
#if !ENABLE(OILPAN)
    if (m_propertiesCSSOMWrapper)
        m_propertiesCSSOMWrapper->clearParentRule();
#endif
}

CSSStyleDeclaration* CSSViewportRule::style() const
{
    if (!m_propertiesCSSOMWrapper)
        m_propertiesCSSOMWrapper = StyleRuleCSSStyleDeclaration::create(m_viewportRule->mutableProperties(), const_cast<CSSViewportRule*>(this));

    return m_propertiesCSSOMWrapper.get();
}

String CSSViewportRule::cssText() const
{
    StringBuilder result;
    result.appendLiteral("@viewport { ");

    String decls = m_viewportRule->properties().asText();
    result.append(decls);
    if (!decls.isEmpty())
        result.append(' ');

    result.append('}');

    return result.toString();
}

void CSSViewportRule::reattach(StyleRuleBase* rule)
{
    ASSERT(rule);
    m_viewportRule = toStyleRuleViewport(rule);
    if (m_propertiesCSSOMWrapper)
        m_propertiesCSSOMWrapper->reattach(m_viewportRule->mutableProperties());
}

void CSSViewportRule::trace(Visitor* visitor)
{
    visitor->trace(m_viewportRule);
    visitor->trace(m_propertiesCSSOMWrapper);
    CSSRule::trace(visitor);
}

} // namespace blink
