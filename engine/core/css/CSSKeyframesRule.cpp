/*
 * Copyright (C) 2007, 2008, 2012 Apple Inc. All rights reserved.
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
#include "core/css/CSSKeyframesRule.h"

#include "core/css/CSSKeyframeRule.h"
#include "core/css/parser/BisonCSSParser.h"
#include "core/css/CSSRuleList.h"
#include "core/css/CSSStyleSheet.h"
#include "core/frame/UseCounter.h"
#include "wtf/text/StringBuilder.h"

namespace blink {

StyleRuleKeyframes::StyleRuleKeyframes()
    : StyleRuleBase(Keyframes)
{
}

StyleRuleKeyframes::StyleRuleKeyframes(const StyleRuleKeyframes& o)
    : StyleRuleBase(o)
    , m_keyframes(o.m_keyframes)
    , m_name(o.m_name)
    , m_isPrefixed(o.m_isPrefixed)
{
}

StyleRuleKeyframes::~StyleRuleKeyframes()
{
}

void StyleRuleKeyframes::parserAppendKeyframe(PassRefPtrWillBeRawPtr<StyleKeyframe> keyframe)
{
    if (!keyframe)
        return;
    m_keyframes.append(keyframe);
}

void StyleRuleKeyframes::wrapperAppendKeyframe(PassRefPtrWillBeRawPtr<StyleKeyframe> keyframe)
{
    m_keyframes.append(keyframe);
}

void StyleRuleKeyframes::wrapperRemoveKeyframe(unsigned index)
{
    m_keyframes.remove(index);
}

int StyleRuleKeyframes::findKeyframeIndex(const String& key) const
{
    String percentageString;
    if (equalIgnoringCase(key, "from"))
        percentageString = "0%";
    else if (equalIgnoringCase(key, "to"))
        percentageString = "100%";
    else
        percentageString = key;

    for (unsigned i = 0; i < m_keyframes.size(); ++i) {
        if (m_keyframes[i]->keyText() == percentageString)
            return i;
    }
    return -1;
}

void StyleRuleKeyframes::traceAfterDispatch(Visitor* visitor)
{
    visitor->trace(m_keyframes);
    StyleRuleBase::traceAfterDispatch(visitor);
}

CSSKeyframesRule::CSSKeyframesRule(StyleRuleKeyframes* keyframesRule, CSSStyleSheet* parent)
    : CSSRule(parent)
    , m_keyframesRule(keyframesRule)
    , m_childRuleCSSOMWrappers(keyframesRule->keyframes().size())
    , m_isPrefixed(keyframesRule->isVendorPrefixed())
{
}

CSSKeyframesRule::~CSSKeyframesRule()
{
#if !ENABLE(OILPAN)
    ASSERT(m_childRuleCSSOMWrappers.size() == m_keyframesRule->keyframes().size());
    for (unsigned i = 0; i < m_childRuleCSSOMWrappers.size(); ++i) {
        if (m_childRuleCSSOMWrappers[i])
            m_childRuleCSSOMWrappers[i]->setParentRule(0);
    }
#endif
}

void CSSKeyframesRule::setName(const String& name)
{
    CSSStyleSheet::RuleMutationScope mutationScope(this);

    m_keyframesRule->setName(name);
}

void CSSKeyframesRule::insertRule(const String& ruleText)
{
    ASSERT(m_childRuleCSSOMWrappers.size() == m_keyframesRule->keyframes().size());

    CSSStyleSheet* styleSheet = parentStyleSheet();
    CSSParserContext context(parserContext(), UseCounter::getFrom(styleSheet));
    BisonCSSParser parser(context);
    RefPtrWillBeRawPtr<StyleKeyframe> keyframe = parser.parseKeyframeRule(styleSheet ? styleSheet->contents() : 0, ruleText);
    if (!keyframe)
        return;

    CSSStyleSheet::RuleMutationScope mutationScope(this);

    m_keyframesRule->wrapperAppendKeyframe(keyframe);

    m_childRuleCSSOMWrappers.grow(length());
}

void CSSKeyframesRule::deleteRule(const String& s)
{
    ASSERT(m_childRuleCSSOMWrappers.size() == m_keyframesRule->keyframes().size());

    int i = m_keyframesRule->findKeyframeIndex(s);
    if (i < 0)
        return;

    CSSStyleSheet::RuleMutationScope mutationScope(this);

    m_keyframesRule->wrapperRemoveKeyframe(i);

    if (m_childRuleCSSOMWrappers[i])
        m_childRuleCSSOMWrappers[i]->setParentRule(0);
    m_childRuleCSSOMWrappers.remove(i);
}

CSSKeyframeRule* CSSKeyframesRule::findRule(const String& s)
{
    int i = m_keyframesRule->findKeyframeIndex(s);
    return (i >= 0) ? item(i) : 0;
}

String CSSKeyframesRule::cssText() const
{
    StringBuilder result;
    if (isVendorPrefixed())
        result.appendLiteral("@-webkit-keyframes ");
    else
        result.appendLiteral("@keyframes ");
    result.append(name());
    result.appendLiteral(" { \n");

    unsigned size = length();
    for (unsigned i = 0; i < size; ++i) {
        result.appendLiteral("  ");
        result.append(m_keyframesRule->keyframes()[i]->cssText());
        result.append('\n');
    }
    result.append('}');
    return result.toString();
}

unsigned CSSKeyframesRule::length() const
{
    return m_keyframesRule->keyframes().size();
}

CSSKeyframeRule* CSSKeyframesRule::item(unsigned index) const
{
    if (index >= length())
        return 0;

    ASSERT(m_childRuleCSSOMWrappers.size() == m_keyframesRule->keyframes().size());
    RefPtrWillBeMember<CSSKeyframeRule>& rule = m_childRuleCSSOMWrappers[index];
    if (!rule)
        rule = adoptRefWillBeNoop(new CSSKeyframeRule(m_keyframesRule->keyframes()[index].get(), const_cast<CSSKeyframesRule*>(this)));

    return rule.get();
}

CSSRuleList* CSSKeyframesRule::cssRules()
{
    if (!m_ruleListCSSOMWrapper)
        m_ruleListCSSOMWrapper = LiveCSSRuleList<CSSKeyframesRule>::create(this);
    return m_ruleListCSSOMWrapper.get();
}

void CSSKeyframesRule::reattach(StyleRuleBase* rule)
{
    ASSERT(rule);
    m_keyframesRule = toStyleRuleKeyframes(rule);
}

void CSSKeyframesRule::trace(Visitor* visitor)
{
    CSSRule::trace(visitor);
#if ENABLE(OILPAN)
    visitor->trace(m_childRuleCSSOMWrappers);
#endif
    visitor->trace(m_keyframesRule);
    visitor->trace(m_ruleListCSSOMWrapper);
}

} // namespace blink
