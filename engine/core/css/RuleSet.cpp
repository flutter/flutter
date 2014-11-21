/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 2004-2005 Allan Sandfeld Jensen (kde@carewolf.com)
 * Copyright (C) 2006, 2007 Nicholas Shanks (webkit@nickshanks.com)
 * Copyright (C) 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012 Apple Inc. All rights reserved.
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
#include "sky/engine/core/css/RuleSet.h"

#include "gen/sky/platform/RuntimeEnabledFeatures.h"
#include "sky/engine/core/css/CSSFontSelector.h"
#include "sky/engine/core/css/CSSSelector.h"
#include "sky/engine/core/css/CSSSelectorList.h"
#include "sky/engine/core/css/SelectorChecker.h"
#include "sky/engine/core/css/StyleSheetContents.h"
#include "sky/engine/platform/TraceEvent.h"

#include "sky/engine/wtf/TerminatedArrayBuilder.h"

namespace blink {

// -----------------------------------------------------------------

// FIXME(sky): Track attribute selectors properly in maps.
static inline bool selectorListContainsAttributeSelector(const CSSSelector* selector)
{
    const CSSSelectorList* selectorList = selector->selectorList();
    if (!selectorList)
        return false;
    for (const CSSSelector* selector = selectorList->first(); selector; selector = CSSSelectorList::next(*selector)) {
        for (const CSSSelector* component = selector; component; component = component->tagHistory()) {
            if (component->isAttributeSelector())
                return true;
        }
    }
    return false;
}

static inline bool containsAttributeSelector(const CSSSelector& selector)
{
    for (const CSSSelector* current = &selector; current; current = current->tagHistory()) {
        if (current->isAttributeSelector())
            return true;
        if (selectorListContainsAttributeSelector(current))
            return true;
    }
    return false;
}

RuleData::RuleData(StyleRule* rule, unsigned selectorIndex, unsigned position, AddRuleFlags addRuleFlags)
    : m_rule(rule)
    , m_selectorIndex(selectorIndex)
    , m_isLastInArray(false)
    , m_position(position)
    , m_containsAttributeSelector(blink::containsAttributeSelector(selector()))
{
    ASSERT(m_position == position);
    ASSERT(m_selectorIndex == selectorIndex);
}

void RuleSet::addToRuleSet(const AtomicString& key, PendingRuleMap& map, const RuleData& ruleData)
{
    OwnPtr<LinkedStack<RuleData> >& rules = map.add(key, nullptr).storedValue->value;
    if (!rules)
        rules = adoptPtr(new LinkedStack<RuleData>);
    rules->push(ruleData);
}

static void extractValuesforSelector(const CSSSelector* selector, AtomicString& id, AtomicString& className, AtomicString& customPseudoElementName, AtomicString& tagName)
{
    switch (selector->match()) {
    case CSSSelector::Id:
        id = selector->value();
        break;
    case CSSSelector::Class:
        className = selector->value();
        break;
    case CSSSelector::Tag:
        if (selector->tagQName().localName() != starAtom)
            tagName = selector->tagQName().localName();
        break;
    default:
        break;
    }
    if (selector->isCustomPseudoElement())
        customPseudoElementName = selector->value();
}

bool RuleSet::findBestRuleSetAndAdd(const CSSSelector& component, RuleData& ruleData)
{
    AtomicString id;
    AtomicString className;
    AtomicString customPseudoElementName;
    AtomicString tagName;

#ifndef NDEBUG
    m_allRules.append(ruleData);
#endif

    const CSSSelector* it = &component;
    for (; it; it = it->tagHistory()) {
        extractValuesforSelector(it, id, className, customPseudoElementName, tagName);
    }
    // FIXME: this null check should not be necessary. See crbug.com/358475
    if (it)
        extractValuesforSelector(it, id, className, customPseudoElementName, tagName);

    // Prefer rule sets in order of most likely to apply infrequently.
    if (!id.isEmpty()) {
        addToRuleSet(id, ensurePendingRules()->idRules, ruleData);
        return true;
    }
    if (!className.isEmpty()) {
        addToRuleSet(className, ensurePendingRules()->classRules, ruleData);
        return true;
    }
    if (!customPseudoElementName.isEmpty()) {
        // Custom pseudos come before ids and classes in the order of tagHistory, and have a relation of
        // ShadowPseudo between them. Therefore we should never be a situation where extractValuesforSelector
        // finsd id and className in addition to custom pseudo.
        ASSERT(id.isEmpty() && className.isEmpty());
        addToRuleSet(customPseudoElementName, ensurePendingRules()->shadowPseudoElementRules, ruleData);
        return true;
    }

    if (!tagName.isEmpty()) {
        addToRuleSet(tagName, ensurePendingRules()->tagRules, ruleData);
        return true;
    }

    return false;
}

void RuleSet::addRule(StyleRule* rule, unsigned selectorIndex, AddRuleFlags addRuleFlags)
{
    RuleData ruleData(rule, selectorIndex, m_ruleCount++, addRuleFlags);
    m_features.collectFeaturesFromRuleData(ruleData);

    if (!findBestRuleSetAndAdd(ruleData.selector(), ruleData)) {
        // If we didn't find a specialized map to stick it in, file under universal rules.
        m_universalRules.append(ruleData);
    }
}

void RuleSet::addFontFaceRule(StyleRuleFontFace* rule)
{
    ensurePendingRules(); // So that m_fontFaceRules.shrinkToFit() gets called.
    m_fontFaceRules.append(rule);
}

void RuleSet::addKeyframesRule(StyleRuleKeyframes* rule)
{
    ensurePendingRules(); // So that m_keyframesRules.shrinkToFit() gets called.
    m_keyframesRules.append(rule);
}

void RuleSet::addChildRules(const Vector<RefPtr<StyleRuleBase> >& rules, const MediaQueryEvaluator& medium, AddRuleFlags addRuleFlags)
{
    for (unsigned i = 0; i < rules.size(); ++i) {
        StyleRuleBase* rule = rules[i].get();

        if (rule->isStyleRule()) {
            StyleRule* styleRule = toStyleRule(rule);

            const CSSSelectorList& selectorList = styleRule->selectorList();
            for (size_t selectorIndex = 0; selectorIndex != kNotFound; selectorIndex = selectorList.indexOfNextSelectorAfter(selectorIndex))
                addRule(styleRule, selectorIndex, addRuleFlags);
        } else if (rule->isMediaRule()) {
            StyleRuleMedia* mediaRule = toStyleRuleMedia(rule);
            if ((!mediaRule->mediaQueries() || medium.eval(mediaRule->mediaQueries(), &m_viewportDependentMediaQueryResults)))
                addChildRules(mediaRule->childRules(), medium, addRuleFlags);
        } else if (rule->isFontFaceRule()) {
            addFontFaceRule(toStyleRuleFontFace(rule));
        } else if (rule->isKeyframesRule()) {
            addKeyframesRule(toStyleRuleKeyframes(rule));
        } else if (rule->isSupportsRule() && toStyleRuleSupports(rule)->conditionIsSupported()) {
            addChildRules(toStyleRuleSupports(rule)->childRules(), medium, addRuleFlags);
        }
    }
}

void RuleSet::addRulesFromSheet(StyleSheetContents* sheet, const MediaQueryEvaluator& medium, AddRuleFlags addRuleFlags)
{
    TRACE_EVENT0("blink", "RuleSet::addRulesFromSheet");
    ASSERT(sheet);
    addRuleFlags = static_cast<AddRuleFlags>(addRuleFlags | RuleCanUseFastCheckSelector);
    addChildRules(sheet->childRules(), medium, addRuleFlags);
}

void RuleSet::addStyleRule(StyleRule* rule, AddRuleFlags addRuleFlags)
{
    for (size_t selectorIndex = 0; selectorIndex != kNotFound; selectorIndex = rule->selectorList().indexOfNextSelectorAfter(selectorIndex))
        addRule(rule, selectorIndex, addRuleFlags);
}

void RuleSet::compactPendingRules(PendingRuleMap& pendingMap, CompactRuleMap& compactMap)
{
    PendingRuleMap::iterator end = pendingMap.end();
    for (PendingRuleMap::iterator it = pendingMap.begin(); it != end; ++it) {
        OwnPtr<LinkedStack<RuleData> > pendingRules = it->value.release();
        CompactRuleMap::ValueType* compactRules = compactMap.add(it->key, nullptr).storedValue;

        TerminatedArrayBuilder<RuleData> builder(compactRules->value.release());
        builder.grow(pendingRules->size());
        while (!pendingRules->isEmpty()) {
            builder.append(pendingRules->peek());
            pendingRules->pop();
        }

        compactRules->value = builder.release();
    }
}

void RuleSet::compactRules()
{
    ASSERT(m_pendingRules);
    OwnPtr<PendingRuleMaps> pendingRules = m_pendingRules.release();
    compactPendingRules(pendingRules->idRules, m_idRules);
    compactPendingRules(pendingRules->classRules, m_classRules);
    compactPendingRules(pendingRules->tagRules, m_tagRules);
    compactPendingRules(pendingRules->shadowPseudoElementRules, m_shadowPseudoElementRules);
    m_universalRules.shrinkToFit();
    m_fontFaceRules.shrinkToFit();
    m_keyframesRules.shrinkToFit();
}

#ifndef NDEBUG
void RuleSet::show()
{
    for (Vector<RuleData>::const_iterator it = m_allRules.begin(); it != m_allRules.end(); ++it)
        it->selector().show();
}
#endif

} // namespace blink
