/*
 * Copyright (C) 2013 Adobe Systems Incorporated. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER "AS IS" AND ANY
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

#ifndef CSSFilterRule_h
#define CSSFilterRule_h

#include "core/css/CSSRule.h"
#include "platform/heap/Handle.h"

namespace blink {

class CSSStyleDeclaration;
class StyleRuleFilter;
class StyleRuleCSSStyleDeclaration;

class CSSFilterRule final : public CSSRule {
public:
    static PassRefPtrWillBeRawPtr<CSSFilterRule> create(StyleRuleFilter* rule, CSSStyleSheet* sheet)
    {
        return adoptRefWillBeNoop(new CSSFilterRule(rule, sheet));
    }

    virtual ~CSSFilterRule();

    virtual CSSRule::Type type() const override { return WEBKIT_FILTER_RULE; }
    virtual String cssText() const override;
    virtual void reattach(StyleRuleBase*) override;

    CSSStyleDeclaration* style() const;

    virtual void trace(Visitor*) override;

private:
    CSSFilterRule(StyleRuleFilter*, CSSStyleSheet* parent);

    RefPtrWillBeMember<StyleRuleFilter> m_filterRule;
    mutable RefPtrWillBeMember<StyleRuleCSSStyleDeclaration> m_propertiesCSSOMWrapper;
};

DEFINE_CSS_RULE_TYPE_CASTS(CSSFilterRule, WEBKIT_FILTER_RULE);

}


#endif // CSSFilterRule_h
