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

#ifndef SKY_ENGINE_CORE_CSS_RULEFEATURE_H_
#define SKY_ENGINE_CORE_CSS_RULEFEATURE_H_

#include "sky/engine/core/css/CSSSelector.h"
#include "sky/engine/wtf/Forward.h"
#include "sky/engine/wtf/HashSet.h"
#include "sky/engine/wtf/text/AtomicStringHash.h"

namespace blink {

class CSSSelectorList;
class Element;
class QualifiedName;
class RuleData;
class SpaceSplitString;

class RuleFeatureSet {
public:
    RuleFeatureSet();
    ~RuleFeatureSet();

    void add(const RuleFeatureSet&);
    void clear();

    void collectFeaturesFromSelector(const CSSSelector&);

    inline bool hasSelectorForAttribute(const AtomicString& attributeName) const
    {
        ASSERT(!attributeName.isEmpty());
        return m_attributeNames.contains(attributeName);
    }

    inline bool hasSelectorForClass(const AtomicString& classValue) const
    {
        ASSERT(!classValue.isEmpty());
        return m_classNames.contains(classValue);
    }

    inline bool hasSelectorForId(const AtomicString& idValue) const
    {
        ASSERT(!idValue.isEmpty());
        return m_idNames.contains(idValue);
    }

    void scheduleStyleInvalidationForClassChange(const SpaceSplitString& changedClasses, Element&);
    void scheduleStyleInvalidationForClassChange(const SpaceSplitString& oldClasses, const SpaceSplitString& newClasses, Element&);

    void scheduleStyleInvalidationForClassChange(const AtomicString& className, Element& element);
    void scheduleStyleInvalidationForAttributeChange(const QualifiedName& attributeName, Element&);
    void scheduleStyleInvalidationForIdChange(const AtomicString& oldId, const AtomicString& newId, Element&);

private:
    void addSelectorFeatures(const CSSSelector&);
    void collectFeaturesFromSelectorList(const CSSSelectorList*);

    HashSet<AtomicString> m_classNames;
    HashSet<AtomicString> m_attributeNames;
    HashSet<AtomicString> m_idNames;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_CSS_RULEFEATURE_H_
