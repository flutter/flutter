/*
 * Copyright (c) 2014, Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of Opera Software ASA nor the names of its
 *    contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "sky/engine/config.h"
#include "sky/engine/core/css/CSSTestHelper.h"

#include "sky/engine/core/css/CSSStyleSheet.h"
#include "sky/engine/core/css/RuleSet.h"
#include "sky/engine/core/css/StyleSheetContents.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/wtf/text/WTFString.h"

#include <gtest/gtest.h>

namespace blink {

CSSTestHelper::~CSSTestHelper()
{
}

CSSTestHelper::CSSTestHelper()
{
    m_document = Document::create();
    TextPosition position;
    m_styleSheet = CSSStyleSheet::create(m_document.get(), KURL(), position);
}

RuleSet& CSSTestHelper::ruleSet()
{
    RuleSet& ruleSet = m_styleSheet->contents()->ensureRuleSet(MediaQueryEvaluator(), RuleHasNoSpecialState);
    ruleSet.compactRulesIfNeeded();
    return ruleSet;
}

void CSSTestHelper::addCSSRules(const char* cssText)
{
    TextPosition position;
    unsigned sheetLength = m_styleSheet->length();
    ASSERT_TRUE(m_styleSheet->contents()->parseString(cssText));
    ASSERT_TRUE(m_styleSheet->length() > sheetLength);
}

} // namespace blink
