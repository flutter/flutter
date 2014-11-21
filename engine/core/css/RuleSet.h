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

#ifndef RuleSet_h
#define RuleSet_h

#include "sky/engine/core/css/CSSKeyframesRule.h"
#include "sky/engine/core/css/MediaQueryEvaluator.h"
#include "sky/engine/core/css/RuleFeature.h"
#include "sky/engine/core/css/StyleRule.h"
#include "sky/engine/core/css/resolver/MediaQueryResult.h"
#include "sky/engine/wtf/Forward.h"
#include "sky/engine/wtf/HashMap.h"
#include "sky/engine/wtf/LinkedStack.h"
#include "sky/engine/wtf/TerminatedArray.h"

namespace blink {

enum AddRuleFlags {
    RuleHasNoSpecialState         = 0,
    RuleCanUseFastCheckSelector   = 1,
};

class CSSSelector;
class MediaQueryEvaluator;
class StyleSheetContents;

class RuleData {
    ALLOW_ONLY_INLINE_ALLOCATION();
public:
    RuleData(StyleRule*, unsigned selectorIndex, unsigned position, AddRuleFlags);

    unsigned position() const { return m_position; }
    StyleRule* rule() const { return m_rule; }
    const CSSSelector& selector() const { return m_rule->selectorList().selectorAt(m_selectorIndex); }
    unsigned selectorIndex() const { return m_selectorIndex; }

    bool isLastInArray() const { return m_isLastInArray; }
    void setLastInArray(bool flag) { m_isLastInArray = flag; }

    bool containsAttributeSelector() const { return m_containsAttributeSelector; }

private:
    RawPtr<StyleRule> m_rule;
    unsigned m_selectorIndex : 12;
    unsigned m_isLastInArray : 1; // We store an array of RuleData objects in a primitive array.
    // This number was picked fairly arbitrarily. We can probably lower it if we need to.
    // Some simple testing showed <100,000 RuleData's on large sites.
    unsigned m_position : 17;
    unsigned m_containsAttributeSelector : 1;
};

struct SameSizeAsRuleData {
    void* a;
    unsigned b;
};

COMPILE_ASSERT(sizeof(RuleData) == sizeof(SameSizeAsRuleData), RuleData_should_stay_small);

class RuleSet {
    WTF_MAKE_NONCOPYABLE(RuleSet);
    WTF_MAKE_FAST_ALLOCATED;
public:
    static PassOwnPtr<RuleSet> create() { return adoptPtr(new RuleSet); }

    void addRulesFromSheet(StyleSheetContents*, const MediaQueryEvaluator&, AddRuleFlags = RuleHasNoSpecialState);
    void addStyleRule(StyleRule*, AddRuleFlags);
    void addRule(StyleRule*, unsigned selectorIndex, AddRuleFlags);

    const RuleFeatureSet& features() const { return m_features; }

    const TerminatedArray<RuleData>* idRules(const AtomicString& key) const { ASSERT(!m_pendingRules); return m_idRules.get(key); }
    const TerminatedArray<RuleData>* classRules(const AtomicString& key) const { ASSERT(!m_pendingRules); return m_classRules.get(key); }
    const TerminatedArray<RuleData>* tagRules(const AtomicString& key) const { ASSERT(!m_pendingRules); return m_tagRules.get(key); }
    const TerminatedArray<RuleData>* shadowPseudoElementRules(const AtomicString& key) const { ASSERT(!m_pendingRules); return m_shadowPseudoElementRules.get(key); }
    const Vector<RuleData>* universalRules() const { ASSERT(!m_pendingRules); return &m_universalRules; }
    const Vector<RawPtr<StyleRuleFontFace> >& fontFaceRules() const { return m_fontFaceRules; }
    const Vector<RawPtr<StyleRuleKeyframes> >& keyframesRules() const { return m_keyframesRules; }
    const MediaQueryResultList& viewportDependentMediaQueryResults() const { return m_viewportDependentMediaQueryResults; }

    unsigned ruleCount() const { return m_ruleCount; }

    void compactRulesIfNeeded()
    {
        if (!m_pendingRules)
            return;
        compactRules();
    }

#ifndef NDEBUG
    void show();
#endif

private:
    typedef HashMap<AtomicString, OwnPtr<LinkedStack<RuleData> > > PendingRuleMap;
    typedef HashMap<AtomicString, OwnPtr<TerminatedArray<RuleData> > > CompactRuleMap;

    RuleSet()
        : m_ruleCount(0)
    {
    }

    void addToRuleSet(const AtomicString& key, PendingRuleMap&, const RuleData&);
    void addFontFaceRule(StyleRuleFontFace*);
    void addKeyframesRule(StyleRuleKeyframes*);

    void addChildRules(const Vector<RefPtr<StyleRuleBase> >&, const MediaQueryEvaluator& medium, AddRuleFlags);
    bool findBestRuleSetAndAdd(const CSSSelector&, RuleData&);

    void compactRules();
    static void compactPendingRules(PendingRuleMap&, CompactRuleMap&);

    class PendingRuleMaps {
    public:
        static PassOwnPtr<PendingRuleMaps> create() { return adoptPtr(new PendingRuleMaps); }

        PendingRuleMap idRules;
        PendingRuleMap classRules;
        PendingRuleMap tagRules;
        PendingRuleMap shadowPseudoElementRules;

    private:
        PendingRuleMaps() { }
    };

    PendingRuleMaps* ensurePendingRules()
    {
        if (!m_pendingRules)
            m_pendingRules = PendingRuleMaps::create();
        return m_pendingRules.get();
    }

    CompactRuleMap m_idRules;
    CompactRuleMap m_classRules;
    CompactRuleMap m_tagRules;
    CompactRuleMap m_shadowPseudoElementRules;
    Vector<RuleData> m_universalRules;
    RuleFeatureSet m_features;
    Vector<RawPtr<StyleRuleFontFace> > m_fontFaceRules;
    Vector<RawPtr<StyleRuleKeyframes> > m_keyframesRules;

    MediaQueryResultList m_viewportDependentMediaQueryResults;

    unsigned m_ruleCount;
    OwnPtr<PendingRuleMaps> m_pendingRules;

#ifndef NDEBUG
    Vector<RuleData> m_allRules;
#endif
};

} // namespace blink

WTF_ALLOW_MOVE_AND_INIT_WITH_MEM_FUNCTIONS(blink::RuleData);

#endif // RuleSet_h
