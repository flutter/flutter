/*
 * Copyright (C) 2013 Google, Inc.
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
 */

#ifndef SKY_ENGINE_CORE_CSS_RESOLVER_SHAREDSTYLEFINDER_H_
#define SKY_ENGINE_CORE_CSS_RESOLVER_SHAREDSTYLEFINDER_H_

#include "sky/engine/core/css/resolver/ElementResolveContext.h"
#include "sky/engine/core/dom/Element.h"

namespace blink {

class Element;
class Node;
class RenderStyle;
class RuleFeatureSet;
class RuleSet;
class SpaceSplitString;
class StyleResolver;

class SharedStyleFinder {
    STACK_ALLOCATED();
public:
    // RuleSets are passed non-const as the act of matching against them can cause them
    // to be compacted. :(
    SharedStyleFinder(const ElementResolveContext& context,
        const RuleFeatureSet& features, StyleResolver& styleResolver)
        : m_elementAffectedByClassRules(false)
        , m_features(features)
        , m_styleResolver(styleResolver)
        , m_context(context)
        , m_renderingParent(nullptr)
    { }

    RenderStyle* findSharedStyle();

private:
    Element* findElementForStyleSharing() const;

    // Only used when we're collecting stats on styles.
    bool documentContainsValidCandidate() const;

    bool classNamesAffectedByRules(const Element&) const;
    bool attributesAffectedByRules(const Element&) const;

    bool canShareStyleWithElement(Element& candidate) const;
    bool sharingCandidateHasIdenticalStyleAffectingAttributes(Element& candidate) const;
    bool sharingCandidateCanShareHostStyles(Element& candidate) const;
    bool sharingCandidateDistributedToSameInsertionPoint(Element& candidate) const;

    Element& element() const { return *m_context.element(); }
    Document& document() const { return element().document(); }

    bool m_elementAffectedByClassRules;
    const RuleFeatureSet& m_features;
    StyleResolver& m_styleResolver;
    const ElementResolveContext& m_context;
    ContainerNode* m_renderingParent;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_CSS_RESOLVER_SHAREDSTYLEFINDER_H_
