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

#include "config.h"
#include "core/css/CSSTestHelper.h"
#include "core/css/RuleSet.h"

#include <gtest/gtest.h>

namespace blink {

TEST(RuleSetTest, findBestRuleSetAndAdd_CustomPseudoElements)
{
    CSSTestHelper helper;

    helper.addCSSRules("summary::-webkit-details-marker { }");
    RuleSet& ruleSet = helper.ruleSet();
    AtomicString str("-webkit-details-marker");
    const TerminatedArray<RuleData>* rules = ruleSet.shadowPseudoElementRules(str);
    ASSERT_EQ(1u, rules->size());
    ASSERT_EQ(str, rules->at(0).selector().value());
}

TEST(RuleSetTest, findBestRuleSetAndAdd_Id)
{
    CSSTestHelper helper;

    helper.addCSSRules("#id { }");
    RuleSet& ruleSet = helper.ruleSet();
    AtomicString str("id");
    const TerminatedArray<RuleData>* rules = ruleSet.idRules(str);
    ASSERT_EQ(1u, rules->size());
    ASSERT_EQ(str, rules->at(0).selector().value());
}

TEST(RuleSetTest, findBestRuleSetAndAdd_NthChild)
{
    CSSTestHelper helper;

    helper.addCSSRules("div:nth-child(2) { }");
    RuleSet& ruleSet = helper.ruleSet();
    AtomicString str("div");
    const TerminatedArray<RuleData>* rules = ruleSet.tagRules(str);
    ASSERT_EQ(1u, rules->size());
    ASSERT_EQ(str, rules->at(0).selector().tagQName().localName());
}

TEST(RuleSetTest, findBestRuleSetAndAdd_ClassThenId)
{
    CSSTestHelper helper;

    helper.addCSSRules(".class#id { }");
    RuleSet& ruleSet = helper.ruleSet();
    AtomicString str("id");
    // id is prefered over class even if class preceeds it in the selector.
    const TerminatedArray<RuleData>* rules = ruleSet.idRules(str);
    ASSERT_EQ(1u, rules->size());
    AtomicString classStr("class");
    ASSERT_EQ(classStr, rules->at(0).selector().value());
}

TEST(RuleSetTest, findBestRuleSetAndAdd_IdThenClass)
{
    CSSTestHelper helper;

    helper.addCSSRules("#id.class { }");
    RuleSet& ruleSet = helper.ruleSet();
    AtomicString str("id");
    const TerminatedArray<RuleData>* rules = ruleSet.idRules(str);
    ASSERT_EQ(1u, rules->size());
    ASSERT_EQ(str, rules->at(0).selector().value());
}

TEST(RuleSetTest, findBestRuleSetAndAdd_AttrThenId)
{
    CSSTestHelper helper;

    helper.addCSSRules("[attr]#id { }");
    RuleSet& ruleSet = helper.ruleSet();
    AtomicString str("id");
    const TerminatedArray<RuleData>* rules = ruleSet.idRules(str);
    ASSERT_EQ(1u, rules->size());
    AtomicString attrStr("attr");
    ASSERT_EQ(attrStr, rules->at(0).selector().attribute().localName());
}

TEST(RuleSetTest, findBestRuleSetAndAdd_TagThenAttrThenId)
{
    CSSTestHelper helper;

    helper.addCSSRules("div[attr]#id { }");
    RuleSet& ruleSet = helper.ruleSet();
    AtomicString str("id");
    const TerminatedArray<RuleData>* rules = ruleSet.idRules(str);
    ASSERT_EQ(1u, rules->size());
    AtomicString tagStr("div");
    ASSERT_EQ(tagStr, rules->at(0).selector().tagQName().localName());
}

TEST(RuleSetTest, findBestRuleSetAndAdd_DivWithContent)
{
    CSSTestHelper helper;

    helper.addCSSRules("div::content { }");
    RuleSet& ruleSet = helper.ruleSet();
    AtomicString str("div");
    const TerminatedArray<RuleData>* rules = ruleSet.tagRules(str);
    ASSERT_EQ(1u, rules->size());
    AtomicString valueStr("content");
    ASSERT_EQ(valueStr, rules->at(0).selector().value());
}

} // namespace blink
