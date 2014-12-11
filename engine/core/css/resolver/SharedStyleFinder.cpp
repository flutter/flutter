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

#include "sky/engine/config.h"
#include "sky/engine/core/css/resolver/SharedStyleFinder.h"

#include "gen/sky/core/HTMLNames.h"
#include "sky/engine/core/css/resolver/StyleResolver.h"
#include "sky/engine/core/css/resolver/StyleResolverStats.h"
#include "sky/engine/core/dom/ContainerNode.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/ElementTraversal.h"
#include "sky/engine/core/dom/Node.h"
#include "sky/engine/core/dom/NodeRenderStyle.h"
#include "sky/engine/core/dom/QualifiedName.h"
#include "sky/engine/core/dom/SpaceSplitString.h"
#include "sky/engine/core/dom/shadow/ElementShadow.h"
#include "sky/engine/core/dom/shadow/InsertionPoint.h"
#include "sky/engine/core/html/HTMLElement.h"
#include "sky/engine/core/rendering/style/RenderStyle.h"
#include "sky/engine/wtf/HashSet.h"
#include "sky/engine/wtf/text/AtomicString.h"

namespace blink {

bool SharedStyleFinder::classNamesAffectedByRules(const Element& element) const
{
    const SpaceSplitString& classNames = element.classNames();
    unsigned count = classNames.size();
    for (unsigned i = 0; i < count; ++i) {
        if (m_features.hasSelectorForClass(classNames[i]))
            return true;
    }
    return false;
}

bool SharedStyleFinder::attributesAffectedByRules(const Element& element) const
{
    for (auto& attribute : element.attributesWithoutUpdate()) {
        if (m_features.hasSelectorForAttribute(attribute.localName()))
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
        if (candidate.hasClass() && classNamesAffectedByRules(candidate))
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

RenderStyle* SharedStyleFinder::findSharedStyle()
{
    INCREMENT_STYLE_STATS_COUNTER(m_styleResolver, sharedStyleLookups);

    if (!element().supportsStyleSharing())
        return 0;

    if (attributesAffectedByRules(element())) {
        INCREMENT_STYLE_STATS_COUNTER(m_styleResolver, sharedStyleRejectedByAttributeRules);
        return 0;
    }

    // Cache whether context.element() is affected by any known class selectors.
    m_elementAffectedByClassRules = element().hasClass() && classNamesAffectedByRules(element());

    Element* shareElement = findElementForStyleSharing();

    if (!shareElement) {
        if (m_styleResolver.stats() && m_styleResolver.stats()->printMissedCandidateCount && documentContainsValidCandidate())
            INCREMENT_STYLE_STATS_COUNTER(m_styleResolver, sharedStyleMissed);
        return 0;
    }

    INCREMENT_STYLE_STATS_COUNTER(m_styleResolver, sharedStyleFound);

    if (attributesAffectedByRules(*shareElement)) {
        INCREMENT_STYLE_STATS_COUNTER(m_styleResolver, sharedStyleRejectedByAttributeRules);
        return 0;
    }

    return shareElement->renderStyle();
}

}
