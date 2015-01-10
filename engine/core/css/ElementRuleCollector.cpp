/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 2004-2005 Allan Sandfeld Jensen (kde@carewolf.com)
 * Copyright (C) 2006, 2007 Nicholas Shanks (webkit@nickshanks.com)
 * Copyright (C) 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013 Apple Inc. All rights reserved.
 * Copyright (C) 2007 Alexey Proskuryakov <ap@webkit.org>
 * Copyright (C) 2007, 2008 Eric Seidel <eric@webkit.org>
 * Copyright (C) 2008, 2009 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
 * Copyright (c) 2011, Code Aurora Forum. All rights reserved.
 * Copyright (C) Research In Motion Limited 2011. All rights reserved.
 * Copyright (C) 2012 Google Inc. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */

#include "sky/engine/config.h"
#include "sky/engine/core/css/ElementRuleCollector.h"

#include "sky/engine/core/css/CSSSelector.h"
#include "sky/engine/core/css/CSSStyleSheet.h"
#include "sky/engine/core/css/StylePropertySet.h"
#include "sky/engine/core/css/resolver/StyleResolver.h"
#include "sky/engine/core/dom/shadow/ShadowRoot.h"
#include "sky/engine/core/rendering/style/RenderStyle.h"
#include "sky/engine/core/rendering/style/StyleInheritedData.h"

namespace blink {

ElementRuleCollector::ElementRuleCollector(const ElementResolveContext& context,
    RenderStyle* style)
    : m_context(context)
    , m_style(style)
{ }

ElementRuleCollector::~ElementRuleCollector()
{
}

MatchResult& ElementRuleCollector::matchedResult()
{
    return m_result;
}

inline void ElementRuleCollector::addMatchedRule(const RuleData* rule, CascadeOrder cascadeOrder, unsigned styleSheetIndex, const CSSStyleSheet* parentStyleSheet)
{
    if (!m_matchedRules)
        m_matchedRules = adoptPtr(new Vector<MatchedRule, 32>);
    m_matchedRules->append(MatchedRule(rule, cascadeOrder, styleSheetIndex, parentStyleSheet));
}

void ElementRuleCollector::clearMatchedRules()
{
    if (!m_matchedRules)
        return;
    m_matchedRules->clear();
}

void ElementRuleCollector::addElementStyleProperties(const StylePropertySet* propertySet, bool isCacheable)
{
    if (!propertySet)
        return;
    m_result.ranges.lastAuthorRule = m_result.matchedProperties.size();
    if (m_result.ranges.firstAuthorRule == -1)
        m_result.ranges.firstAuthorRule = m_result.ranges.lastAuthorRule;
    m_result.addMatchedProperties(propertySet);
    if (!isCacheable)
        m_result.isCacheable = false;
}

void ElementRuleCollector::collectMatchingRules(const MatchRequest& matchRequest, RuleRange& ruleRange, CascadeOrder cascadeOrder)
{
    ASSERT(matchRequest.ruleSet);
    ASSERT(m_context.element());

    Element& element = *m_context.element();

    // We need to collect the rules for id, class, tag, and everything else into a buffer and
    // then sort the buffer.
    if (element.hasID())
        collectMatchingRulesForList(matchRequest.ruleSet->idRules(element.idForStyleResolution()), cascadeOrder, matchRequest, ruleRange);
    if (element.isStyledElement() && element.hasClass()) {
        for (size_t i = 0; i < element.classNames().size(); ++i)
            collectMatchingRulesForList(matchRequest.ruleSet->classRules(element.classNames()[i]), cascadeOrder, matchRequest, ruleRange);
    }

    collectMatchingRulesForList(matchRequest.ruleSet->tagRules(element.localName()), cascadeOrder, matchRequest, ruleRange);
    collectMatchingRulesForList(matchRequest.ruleSet->universalRules(), cascadeOrder, matchRequest, ruleRange);
}

void ElementRuleCollector::collectMatchingHostRules(const MatchRequest& matchRequest, RuleRange& ruleRange, CascadeOrder cascadeOrder)
{
    collectMatchingRulesForList(matchRequest.ruleSet->hostRules(), cascadeOrder, matchRequest, ruleRange);
}

void ElementRuleCollector::sortAndTransferMatchedRules()
{
    if (!m_matchedRules || m_matchedRules->isEmpty())
        return;

    sortMatchedRules();

    Vector<MatchedRule, 32>& matchedRules = *m_matchedRules;

    // Now transfer the set of matched rules over to our list of declarations.
    for (unsigned i = 0; i < matchedRules.size(); i++) {
        const RuleData* ruleData = matchedRules[i].ruleData();
        m_result.addMatchedProperties(&ruleData->rule()->properties());
    }
}

inline bool ElementRuleCollector::ruleMatches(const RuleData& ruleData)
{
    SelectorChecker checker(*m_context.element());
    if (checker.match(ruleData.selector())) {
        if (checker.matchedAttributeSelector())
            m_style->setUnique();
        if (checker.matchedFocusSelector())
            m_style->setAffectedByFocus();
        if (checker.matchedHoverSelector())
            m_style->setAffectedByHover();
        if (checker.matchedActiveSelector())
            m_style->setAffectedByActive();
        return true;
    }
    return false;
}

void ElementRuleCollector::collectRuleIfMatches(const RuleData& ruleData, CascadeOrder cascadeOrder, const MatchRequest& matchRequest, RuleRange& ruleRange)
{
    StyleRule* rule = ruleData.rule();
    if (ruleMatches(ruleData)) {
        // If the rule has no properties to apply, then ignore it in the non-debug mode.
        const StylePropertySet& properties = rule->properties();
        if (properties.isEmpty())
            return;

        // Update our first/last rule indices in the matched rules array.
        ++ruleRange.lastRuleIndex;
        if (ruleRange.firstRuleIndex == -1)
            ruleRange.firstRuleIndex = ruleRange.lastRuleIndex;

        // Add this rule to our list of matched rules.
        addMatchedRule(&ruleData, cascadeOrder, matchRequest.styleSheetIndex, matchRequest.styleSheet);
    }
}

static inline bool compareRules(const MatchedRule& matchedRule1, const MatchedRule& matchedRule2)
{
    return matchedRule1.position() < matchedRule2.position();
}

void ElementRuleCollector::sortMatchedRules()
{
    ASSERT(m_matchedRules);
    std::sort(m_matchedRules->begin(), m_matchedRules->end(), compareRules);
}

} // namespace blink
