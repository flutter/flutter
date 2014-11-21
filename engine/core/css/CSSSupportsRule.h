/* Copyright (C) 2012 Motorola Mobility Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above
 *    copyright notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with the distribution.
 * 3. Neither the name of Motorola Mobility Inc. nor the names of its
 *    contributors may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef SKY_ENGINE_CORE_CSS_CSSSUPPORTSRULE_H_
#define SKY_ENGINE_CORE_CSS_CSSSUPPORTSRULE_H_

#include "sky/engine/core/css/CSSGroupingRule.h"

namespace blink {

class CSSRule;
class StyleRuleSupports;

class CSSSupportsRule final : public CSSGroupingRule {
public:
    static PassRefPtr<CSSSupportsRule> create(StyleRuleSupports* rule, CSSStyleSheet* sheet)
    {
        return adoptRef(new CSSSupportsRule(rule, sheet));
    }

    virtual ~CSSSupportsRule() { }

    virtual CSSRule::Type type() const override { return SUPPORTS_RULE; }
    virtual String cssText() const override;

    String conditionText() const;

private:
    CSSSupportsRule(StyleRuleSupports*, CSSStyleSheet*);
};

DEFINE_CSS_RULE_TYPE_CASTS(CSSSupportsRule, SUPPORTS_RULE);

} // namespace blink

#endif  // SKY_ENGINE_CORE_CSS_CSSSUPPORTSRULE_H_
