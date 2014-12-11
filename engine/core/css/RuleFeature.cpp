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
#include "sky/engine/core/css/RuleFeature.h"

#include "sky/engine/core/css/CSSSelector.h"
#include "sky/engine/core/css/CSSSelectorList.h"
#include "sky/engine/core/css/RuleSet.h"
#include "sky/engine/core/css/StyleRule.h"
#include "sky/engine/core/dom/Element.h"
#include "sky/engine/core/dom/Node.h"
#include "sky/engine/wtf/BitVector.h"

namespace blink {

RuleFeatureSet::RuleFeatureSet()
{
}

RuleFeatureSet::~RuleFeatureSet()
{
}

void RuleFeatureSet::addSelectorFeatures(const CSSSelector& selector)
{
    if (selector.match() == CSSSelector::Class)
        m_classNames.add(selector.value());
    else if (selector.match() == CSSSelector::Id)
        m_idNames.add(selector.value());
    else if (selector.isAttributeSelector())
        m_attributeNames.add(selector.attribute().localName());
}

void RuleFeatureSet::collectFeaturesFromSelector(const CSSSelector& selector)
{
    for (const CSSSelector* current = &selector; current; current = current->tagHistory()) {
        addSelectorFeatures(*current);
        collectFeaturesFromSelectorList(current->selectorList());
   }
}

void RuleFeatureSet::collectFeaturesFromSelectorList(const CSSSelectorList* selectorList)
{
    if (!selectorList)
        return;

    for (const CSSSelector* selector = selectorList->first(); selector; selector = CSSSelectorList::next(*selector))
        collectFeaturesFromSelector(*selector);
}

void RuleFeatureSet::add(const RuleFeatureSet& other)
{
    for (HashSet<AtomicString>::const_iterator it = other.m_classNames.begin(); it != other.m_classNames.end(); ++it)
        m_classNames.add(*it);
    for (HashSet<AtomicString>::const_iterator it = other.m_attributeNames.begin(); it != other.m_attributeNames.end(); ++it)
        m_attributeNames.add(*it);
    for (HashSet<AtomicString>::const_iterator it = other.m_idNames.begin(); it != other.m_idNames.end(); ++it)
        m_idNames.add(*it);
}

void RuleFeatureSet::clear()
{
    m_classNames.clear();
    m_attributeNames.clear();
    m_idNames.clear();
}

void RuleFeatureSet::scheduleStyleInvalidationForClassChange(const SpaceSplitString& changedClasses, Element& element)
{
    unsigned changedSize = changedClasses.size();
    for (unsigned i = 0; i < changedSize; ++i) {
        scheduleStyleInvalidationForClassChange(changedClasses[i], element);
    }
}

void RuleFeatureSet::scheduleStyleInvalidationForClassChange(const SpaceSplitString& oldClasses, const SpaceSplitString& newClasses, Element& element)
{
    if (!oldClasses.size()) {
        scheduleStyleInvalidationForClassChange(newClasses, element);
        return;
    }

    // Class vectors tend to be very short. This is faster than using a hash table.
    BitVector remainingClassBits;
    remainingClassBits.ensureSize(oldClasses.size());

    for (unsigned i = 0; i < newClasses.size(); ++i) {
        bool found = false;
        for (unsigned j = 0; j < oldClasses.size(); ++j) {
            if (newClasses[i] == oldClasses[j]) {
                // Mark each class that is still in the newClasses so we can skip doing
                // an n^2 search below when looking for removals. We can't break from
                // this loop early since a class can appear more than once.
                remainingClassBits.quickSet(j);
                found = true;
            }
        }
        // Class was added.
        if (!found)
            scheduleStyleInvalidationForClassChange(newClasses[i], element);
    }

    for (unsigned i = 0; i < oldClasses.size(); ++i) {
        if (remainingClassBits.quickGet(i))
            continue;
        // Class was removed.
        scheduleStyleInvalidationForClassChange(oldClasses[i], element);
    }
}

void RuleFeatureSet::scheduleStyleInvalidationForAttributeChange(const QualifiedName& attributeName, Element& element)
{
    if (m_attributeNames.contains(attributeName.localName()))
        element.setNeedsStyleRecalc(LocalStyleChange);
}

void RuleFeatureSet::scheduleStyleInvalidationForIdChange(const AtomicString& oldId, const AtomicString& newId, Element& element)
{
    if (!oldId.isEmpty()) {
        if (m_idNames.contains(oldId))
            element.setNeedsStyleRecalc(LocalStyleChange);
    }
    if (!newId.isEmpty()) {
        if (m_idNames.contains(newId))
            element.setNeedsStyleRecalc(LocalStyleChange);
    }
}

void RuleFeatureSet::scheduleStyleInvalidationForClassChange(const AtomicString& className, Element& element)
{
    if (m_classNames.contains(className))
        element.setNeedsStyleRecalc(LocalStyleChange);
}

} // namespace blink
