/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011 Apple Inc. All rights reserved.
 * Copyright (C) 2012 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "sky/engine/config.h"
#include "sky/engine/core/css/resolver/ScopedStyleResolver.h"

#include "sky/engine/core/css/CSSStyleSheet.h"
#include "sky/engine/core/css/RuleFeature.h"
#include "sky/engine/core/css/StyleRule.h"
#include "sky/engine/core/css/StyleSheetContents.h"
#include "sky/engine/core/css/resolver/StyleResolver.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/shadow/ElementShadow.h"
#include "sky/engine/core/dom/shadow/ShadowRoot.h"
#include "sky/engine/core/html/HTMLStyleElement.h"

namespace blink {

ScopedStyleResolver::ScopedStyleResolver(TreeScope& scope)
    : m_scope(scope)
{
}

void ScopedStyleResolver::addRulesFromSheet(CSSStyleSheet* cssSheet, StyleResolver* resolver)
{
    m_authorStyleSheets.append(cssSheet);
    unsigned index = m_authorStyleSheets.size() - 1;
    StyleSheetContents* sheet = cssSheet->contents();

    AddRuleFlags addRuleFlags = RuleHasNoSpecialState;
    const RuleSet& ruleSet = sheet->ensureRuleSet(addRuleFlags);
    resolver->addMediaQueryResults(ruleSet.viewportDependentMediaQueryResults());
    resolver->processScopedRules(ruleSet, cssSheet, index, treeScope().rootNode());
}

void ScopedStyleResolver::collectFeaturesTo(RuleFeatureSet& features, HashSet<const StyleSheetContents*>& visitedSharedStyleSheetContents) const
{
    for (size_t i = 0; i < m_authorStyleSheets.size(); ++i) {
        StyleSheetContents* contents = m_authorStyleSheets[i]->contents();
        if (visitedSharedStyleSheetContents.add(contents).isNewEntry)
            features.add(contents->ruleSet().features());
    }
}

void ScopedStyleResolver::resetAuthorStyle()
{
    m_authorStyleSheets.clear();
    m_keyframesRuleMap.clear();
}

const StyleRuleKeyframes* ScopedStyleResolver::keyframeStylesForAnimation(const StringImpl* animationName)
{
    if (m_keyframesRuleMap.isEmpty())
        return 0;

    KeyframesRuleMap::iterator it = m_keyframesRuleMap.find(animationName);
    if (it == m_keyframesRuleMap.end())
        return 0;

    return it->value.get();
}

void ScopedStyleResolver::addKeyframeStyle(PassRefPtr<StyleRuleKeyframes> rule)
{
    AtomicString s(rule->name());
    if (rule->isVendorPrefixed()) {
        KeyframesRuleMap::iterator it = m_keyframesRuleMap.find(rule->name().impl());
        if (it == m_keyframesRuleMap.end())
            m_keyframesRuleMap.set(s.impl(), rule);
        else if (it->value->isVendorPrefixed())
            m_keyframesRuleMap.set(s.impl(), rule);
    } else {
        m_keyframesRuleMap.set(s.impl(), rule);
    }
}

void ScopedStyleResolver::collectMatchingAuthorRules(ElementRuleCollector& collector, bool includeEmptyRules, bool applyAuthorStyles, CascadeScope cascadeScope, CascadeOrder cascadeOrder)
{
    unsigned contextFlags = SelectorChecker::DefaultBehavior;

    if (!applyAuthorStyles)
        contextFlags |= SelectorChecker::ScopeContainsLastMatchedElement;

    RuleRange ruleRange = collector.matchedResult().ranges.authorRuleRange();
    for (size_t i = 0; i < m_authorStyleSheets.size(); ++i) {
        MatchRequest matchRequest(&m_authorStyleSheets[i]->contents()->ruleSet(), includeEmptyRules, &m_scope->rootNode(), m_authorStyleSheets[i], applyAuthorStyles, i);
        collector.collectMatchingRules(matchRequest, ruleRange, static_cast<SelectorChecker::ContextFlags>(contextFlags), cascadeScope, cascadeOrder);
    }
}

} // namespace blink
