/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011 Apple Inc. All rights reserved.
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
 *
 */

#ifndef SKY_ENGINE_CORE_CSS_ELEMENTRULECOLLECTOR_H_
#define SKY_ENGINE_CORE_CSS_ELEMENTRULECOLLECTOR_H_

#include "sky/engine/core/css/SelectorChecker.h"
#include "sky/engine/core/css/resolver/ElementResolveContext.h"
#include "sky/engine/core/css/resolver/MatchRequest.h"
#include "sky/engine/core/css/resolver/MatchResult.h"
#include "sky/engine/wtf/RefPtr.h"
#include "sky/engine/wtf/Vector.h"

namespace blink {

class CSSStyleSheet;
class CSSRuleList;
class RuleData;
class RuleSet;
class ScopedStyleResolver;
class StaticCSSRuleList;

typedef unsigned CascadeScope;
typedef unsigned CascadeOrder;

const CascadeScope ignoreCascadeScope = 0;
const CascadeOrder ignoreCascadeOrder = 0;

class MatchedRule {
    ALLOW_ONLY_INLINE_ALLOCATION();
public:
    MatchedRule(const RuleData* ruleData, CascadeScope cascadeScope, CascadeOrder cascadeOrder, unsigned styleSheetIndex, const CSSStyleSheet* parentStyleSheet)
        : m_ruleData(ruleData)
        , m_cascadeScope(cascadeScope)
        , m_parentStyleSheet(parentStyleSheet)
    {
        ASSERT(m_ruleData);
        static const unsigned BitsForPositionInRuleData = 18;
        static const unsigned BitsForStyleSheetIndex = 32;
        m_position = ((uint64_t)cascadeOrder << (BitsForStyleSheetIndex + BitsForPositionInRuleData)) + ((uint64_t)styleSheetIndex << BitsForPositionInRuleData)+ m_ruleData->position();
    }

    const RuleData* ruleData() const { return m_ruleData; }
    uint32_t cascadeScope() const { return m_cascadeScope; }
    uint64_t position() const { return m_position; }
    const CSSStyleSheet* parentStyleSheet() const { return m_parentStyleSheet; }

private:
    // FIXME: Oilpan: RuleData is in the oilpan heap and this pointer
    // really should be traced. However, RuleData objects are
    // allocated inside larger TerminatedArray objects and we cannot
    // trace a raw rule data pointer at this point.
    const RuleData* m_ruleData;
    CascadeScope m_cascadeScope;
    uint64_t m_position;
    RawPtr<const CSSStyleSheet> m_parentStyleSheet;
};

} // namespace blink

WTF_ALLOW_MOVE_AND_INIT_WITH_MEM_FUNCTIONS(blink::MatchedRule);

namespace blink {

// FIXME: oilpan: when transition types are gone this class can be replaced with HeapVector.
class StyleRuleList final : public RefCounted<StyleRuleList> {
public:
    static PassRefPtr<StyleRuleList> create() { return adoptRef(new StyleRuleList()); }

    Vector<RawPtr<StyleRule> > m_list;
};

// ElementRuleCollector is designed to be used as a stack object.
// Create one, ask what rules the ElementResolveContext matches
// and then let it go out of scope.
// FIXME: Currently it modifies the RenderStyle but should not!
class ElementRuleCollector {
    STACK_ALLOCATED();
    WTF_MAKE_NONCOPYABLE(ElementRuleCollector);
public:
    ElementRuleCollector(const ElementResolveContext&, RenderStyle* = 0);
    ~ElementRuleCollector();

    void setMode(SelectorChecker::Mode mode) { m_mode = mode; }

    void setMatchingUARules(bool matchingUARules) { m_matchingUARules = matchingUARules; }
    bool hasAnyMatchingRules(RuleSet*);

    MatchResult& matchedResult();
    PassRefPtr<StyleRuleList> matchedStyleRuleList();
    PassRefPtr<CSSRuleList> matchedCSSRuleList();

    void collectMatchingRules(const MatchRequest&, RuleRange&, SelectorChecker::ContextFlags = SelectorChecker::DefaultBehavior, CascadeScope = ignoreCascadeScope, CascadeOrder = ignoreCascadeOrder);
    void sortAndTransferMatchedRules();
    void clearMatchedRules();
    void addElementStyleProperties(const StylePropertySet*, bool isCacheable = true);

private:
    void collectRuleIfMatches(const RuleData&, SelectorChecker::ContextFlags, CascadeScope, CascadeOrder, const MatchRequest&, RuleRange&);

    template<typename RuleDataListType>
    void collectMatchingRulesForList(const RuleDataListType* rules, SelectorChecker::ContextFlags contextFlags, CascadeScope cascadeScope, CascadeOrder cascadeOrder, const MatchRequest& matchRequest, RuleRange& ruleRange)
    {
        if (!rules)
            return;

        for (typename RuleDataListType::const_iterator it = rules->begin(), end = rules->end(); it != end; ++it)
            collectRuleIfMatches(*it, contextFlags, cascadeScope, cascadeOrder, matchRequest, ruleRange);
    }

    bool ruleMatches(const RuleData&, const ContainerNode* scope, SelectorChecker::ContextFlags);

    CSSRuleList* nestedRuleList(CSSRule*);
    template<class CSSRuleCollection>
    CSSRule* findStyleRule(CSSRuleCollection*, StyleRule*);
    void appendCSSOMWrapperForRule(CSSStyleSheet*, StyleRule*);

    void sortMatchedRules();
    void addMatchedRule(const RuleData*, CascadeScope, CascadeOrder, unsigned styleSheetIndex, const CSSStyleSheet* parentStyleSheet);

    StaticCSSRuleList* ensureRuleList();
    StyleRuleList* ensureStyleRuleList();

private:
    const ElementResolveContext& m_context;
    RefPtr<RenderStyle> m_style; // FIXME: This can be mutated during matching!

    SelectorChecker::Mode m_mode;
    bool m_matchingUARules;

    OwnPtr<Vector<MatchedRule, 32> > m_matchedRules;

    // Output.
    RefPtr<StaticCSSRuleList> m_cssRuleList;
    RefPtr<StyleRuleList> m_styleRuleList;
    MatchResult m_result;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_CSS_ELEMENTRULECOLLECTOR_H_
