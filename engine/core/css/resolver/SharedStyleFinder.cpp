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
 * Copyright (C) 2013 Google Inc. All rights reserved.
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

#include "config.h"
#include "core/css/resolver/SharedStyleFinder.h"

#include "core/HTMLNames.h"
#include "core/css/resolver/StyleResolver.h"
#include "core/css/resolver/StyleResolverStats.h"
#include "core/dom/ContainerNode.h"
#include "core/dom/Document.h"
#include "core/dom/ElementTraversal.h"
#include "core/dom/Node.h"
#include "core/dom/NodeRenderStyle.h"
#include "core/dom/QualifiedName.h"
#include "core/dom/SpaceSplitString.h"
#include "core/dom/shadow/ElementShadow.h"
#include "core/dom/shadow/InsertionPoint.h"
#include "core/html/HTMLElement.h"
#include "core/rendering/style/RenderStyle.h"
#include "wtf/HashSet.h"
#include "wtf/text/AtomicString.h"

namespace blink {

bool SharedStyleFinder::classNamesAffectedByRules(const SpaceSplitString& classNames) const
{
    unsigned count = classNames.size();
    for (unsigned i = 0; i < count; ++i) {
        if (m_features.hasSelectorForClass(classNames[i]))
            return true;
    }
    return false;
}

bool SharedStyleFinder::sharingCandidateHasIdenticalStyleAffectingAttributes(Element& candidate) const
{
    if (element().sharesSameElementData(candidate))
        return true;
    if (element().getAttribute(HTMLNames::langAttr) != candidate.getAttribute(HTMLNames::langAttr))
        return false;

    if (!m_elementAffectedByClassRules) {
        if (candidate.hasClass() && classNamesAffectedByRules(candidate.classNames()))
            return false;
    } else if (candidate.hasClass()) {
        if (element().classNames() != candidate.classNames())
            return false;
    } else {
        return false;
    }

    return true;
}

bool SharedStyleFinder::sharingCandidateCanShareHostStyles(Element& candidate) const
{
    const ElementShadow* elementShadow = element().shadow();
    const ElementShadow* candidateShadow = candidate.shadow();

    if (!elementShadow && !candidateShadow)
        return true;

    if (static_cast<bool>(elementShadow) != static_cast<bool>(candidateShadow))
        return false;

    return elementShadow->hasSameStyles(candidateShadow);
}

bool SharedStyleFinder::sharingCandidateDistributedToSameInsertionPoint(Element& candidate) const
{
    Vector<RawPtr<InsertionPoint>, 8> insertionPoints, candidateInsertionPoints;
    collectDestinationInsertionPoints(element(), insertionPoints);
    collectDestinationInsertionPoints(candidate, candidateInsertionPoints);
    if (insertionPoints.size() != candidateInsertionPoints.size())
        return false;
    for (size_t i = 0; i < insertionPoints.size(); ++i) {
        if (insertionPoints[i] != candidateInsertionPoints[i])
            return false;
    }
    return true;
}

bool SharedStyleFinder::canShareStyleWithElement(Element& candidate) const
{
    if (element() == candidate)
        return false;
    Element* parent = candidate.parentOrShadowHostElement();
    RenderStyle* style = candidate.renderStyle();
    if (!style)
        return false;
    if (!style->isSharable())
        return false;
    if (!parent)
        return false;
    if (element().parentOrShadowHostElement()->renderStyle() != parent->renderStyle())
        return false;
    if (candidate.tagQName() != element().tagQName())
        return false;
    if (candidate.inlineStyle())
        return false;
    if (candidate.needsStyleRecalc())
        return false;
    if (!sharingCandidateHasIdenticalStyleAffectingAttributes(candidate))
        return false;
    if (candidate.hasID() && m_features.hasSelectorForId(candidate.idForStyleResolution()))
        return false;
    if (!sharingCandidateCanShareHostStyles(candidate))
        return false;
    if (!sharingCandidateDistributedToSameInsertionPoint(candidate))
        return false;
    if (candidate.isUnresolvedCustomElement() != element().isUnresolvedCustomElement())
        return false;

    if (element().parentOrShadowHostElement() != parent) {
        if (!parent->isStyledElement())
            return false;
        if (parent->inlineStyle())
            return false;
        if (parent->hasID() && m_features.hasSelectorForId(parent->idForStyleResolution()))
            return false;
    }

    return true;
}

bool SharedStyleFinder::documentContainsValidCandidate() const
{
    for (Element* element = document().documentElement(); element; element = ElementTraversal::next(*element)) {
        if (element->supportsStyleSharing() && canShareStyleWithElement(*element))
            return true;
    }
    return false;
}

inline Element* SharedStyleFinder::findElementForStyleSharing() const
{
    StyleSharingList& styleSharingList = m_styleResolver.styleSharingList();
    for (StyleSharingList::iterator it = styleSharingList.begin(); it != styleSharingList.end(); ++it) {
        Element& candidate = **it;
        if (!canShareStyleWithElement(candidate))
            continue;
        if (it != styleSharingList.begin()) {
            // Move the element to the front of the LRU
            styleSharingList.remove(it);
            styleSharingList.prepend(&candidate);
        }
        return &candidate;
    }
    m_styleResolver.addToStyleSharingList(element());
    return 0;
}

bool SharedStyleFinder::matchesRuleSet(RuleSet* ruleSet)
{
    if (!ruleSet)
        return false;
    ElementRuleCollector collector(m_context);
    return collector.hasAnyMatchingRules(ruleSet);
}

RenderStyle* SharedStyleFinder::findSharedStyle()
{
    INCREMENT_STYLE_STATS_COUNTER(m_styleResolver, sharedStyleLookups);

    if (!element().supportsStyleSharing())
        return 0;

    // Cache whether context.element() is affected by any known class selectors.
    m_elementAffectedByClassRules = element().hasClass() && classNamesAffectedByRules(element().classNames());

    Element* shareElement = findElementForStyleSharing();

    if (!shareElement) {
        if (m_styleResolver.stats() && m_styleResolver.stats()->printMissedCandidateCount && documentContainsValidCandidate())
            INCREMENT_STYLE_STATS_COUNTER(m_styleResolver, sharedStyleMissed);
        return 0;
    }

    INCREMENT_STYLE_STATS_COUNTER(m_styleResolver, sharedStyleFound);

    if (matchesRuleSet(m_attributeRuleSet)) {
        INCREMENT_STYLE_STATS_COUNTER(m_styleResolver, sharedStyleRejectedByAttributeRules);
        return 0;
    }

    return shareElement->renderStyle();
}

}
