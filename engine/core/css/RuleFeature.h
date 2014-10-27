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

#ifndef RuleFeature_h
#define RuleFeature_h

#include "core/css/CSSSelector.h"
#include "core/css/invalidation/StyleInvalidator.h"
#include "wtf/Forward.h"
#include "wtf/HashSet.h"
#include "wtf/text/AtomicStringHash.h"

namespace blink {

class CSSSelectorList;
class DescendantInvalidationSet;
class Document;
class Node;
class QualifiedName;
class RuleData;
class ShadowRoot;
class SpaceSplitString;
class StyleRule;

struct RuleFeature {
    ALLOW_ONLY_INLINE_ALLOCATION();
public:
    RuleFeature(StyleRule* rule, unsigned selectorIndex);

    void trace(Visitor*);

    RawPtr<StyleRule> rule;
    unsigned selectorIndex;
};

class RuleFeatureSet {
    DISALLOW_ALLOCATION();
public:
    RuleFeatureSet();
    ~RuleFeatureSet();

    void add(const RuleFeatureSet&);
    void clear();

    void collectFeaturesFromSelector(const CSSSelector&);
    void collectFeaturesFromRuleData(const RuleData&);

    inline bool hasSelectorForAttribute(const AtomicString& attributeName) const
    {
        ASSERT(!attributeName.isEmpty());
        return m_attributeInvalidationSets.contains(attributeName);
    }

    inline bool hasSelectorForClass(const AtomicString& classValue) const
    {
        ASSERT(!classValue.isEmpty());
        return m_classInvalidationSets.contains(classValue);
    }

    inline bool hasSelectorForId(const AtomicString& idValue) const
    {
        return m_idInvalidationSets.contains(idValue);
    }

    void scheduleStyleInvalidationForClassChange(const SpaceSplitString& changedClasses, Element&);
    void scheduleStyleInvalidationForClassChange(const SpaceSplitString& oldClasses, const SpaceSplitString& newClasses, Element&);
    void scheduleStyleInvalidationForAttributeChange(const QualifiedName& attributeName, Element&);
    void scheduleStyleInvalidationForIdChange(const AtomicString& oldId, const AtomicString& newId, Element&);
    void scheduleStyleInvalidationForPseudoChange(CSSSelector::PseudoType, Element&);

    bool hasIdsInSelectors() const
    {
        return m_idInvalidationSets.size() > 0;
    }

    // Marks the given attribute name as "appearing in a selector". Used for
    // CSS properties such as content: ... attr(...) ...
    // FIXME: record these internally to this class instead calls from StyleResolver to here.
    void addContentAttr(const AtomicString& attributeName);

    StyleInvalidator& styleInvalidator();

    void trace(Visitor*);

    Vector<RuleFeature> attributeRules;

private:
    typedef HashMap<AtomicString, RefPtr<DescendantInvalidationSet> > InvalidationSetMap;
    typedef HashMap<CSSSelector::PseudoType, RefPtr<DescendantInvalidationSet>, WTF::IntHash<unsigned>, WTF::UnsignedWithZeroKeyHashTraits<unsigned> > PseudoTypeInvalidationSetMap;

    enum InvalidationSetMode {
        AddFeatures,
        UseLocalStyleChange,
        UseSubtreeStyleChange
    };

    static InvalidationSetMode invalidationSetModeForSelector(const CSSSelector&);

    void collectFeaturesFromSelector(const CSSSelector&, InvalidationSetMode);
    void collectFeaturesFromSelectorList(const CSSSelectorList*, InvalidationSetMode);

    DescendantInvalidationSet& ensureClassInvalidationSet(const AtomicString& className);
    DescendantInvalidationSet& ensureAttributeInvalidationSet(const AtomicString& attributeName);
    DescendantInvalidationSet& ensureIdInvalidationSet(const AtomicString& attributeName);
    DescendantInvalidationSet& ensurePseudoInvalidationSet(CSSSelector::PseudoType);
    DescendantInvalidationSet* invalidationSetForSelector(const CSSSelector&);

    InvalidationSetMode updateInvalidationSets(const CSSSelector&);

    struct InvalidationSetFeatures {
        InvalidationSetFeatures()
            : customPseudoElement(false)
            , treeBoundaryCrossing(false)
            , wholeSubtree(false)
        { }
        Vector<AtomicString> classes;
        Vector<AtomicString> attributes;
        AtomicString id;
        AtomicString tagName;
        bool customPseudoElement;
        bool treeBoundaryCrossing;
        bool wholeSubtree;
    };

    static void extractInvalidationSetFeature(const CSSSelector&, InvalidationSetFeatures&);
    const CSSSelector* extractInvalidationSetFeatures(const CSSSelector&, InvalidationSetFeatures&, bool negated);
    void addFeaturesToInvalidationSets(const CSSSelector&, InvalidationSetFeatures&);

    void addClassToInvalidationSet(const AtomicString& className, Element&);

    InvalidationSetMap m_classInvalidationSets;
    InvalidationSetMap m_attributeInvalidationSets;
    InvalidationSetMap m_idInvalidationSets;
    PseudoTypeInvalidationSetMap m_pseudoInvalidationSets;
    bool m_targetedStyleRecalcEnabled;
    StyleInvalidator m_styleInvalidator;
};


} // namespace blink

namespace WTF {

template <> struct VectorTraits<blink::RuleFeature> : VectorTraitsBase<blink::RuleFeature> {
    static const bool needsDestruction = false;
    static const bool canInitializeWithMemset = true;
    static const bool canMoveWithMemcpy = true;
};

} // namespace WTF

#endif // RuleFeature_h
