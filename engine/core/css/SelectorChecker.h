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

#ifndef SKY_ENGINE_CORE_CSS_SELECTORCHECKER_H_
#define SKY_ENGINE_CORE_CSS_SELECTORCHECKER_H_

#include "sky/engine/core/css/CSSSelector.h"
#include "sky/engine/core/dom/Element.h"

namespace blink {

class CSSSelector;
class ContainerNode;
class Element;
class RenderStyle;

class SelectorChecker {
    WTF_MAKE_NONCOPYABLE(SelectorChecker);
public:
    explicit SelectorChecker();

    struct SelectorCheckingContext {
        STACK_ALLOCATED();
    public:
        // Initial selector constructor
        SelectorCheckingContext(const CSSSelector& selector, const Element* element)
            : selector(&selector)
            , element(element)
            , scope(nullptr)
        {
        }

        const CSSSelector* selector;
        const Element* element;
        RawPtr<const ContainerNode> scope;
    };

    bool match(const SelectorCheckingContext&);

    bool matchedAttributeSelector() const { return m_matchedAttributeSelector; }
    bool matchedFocusSelector() const { return m_matchedFocusSelector; }
    bool matchedHoverSelector() const { return m_matchedHoverSelector; }
    bool matchedActiveSelector() const { return m_matchedActiveSelector; }

    static bool tagMatches(const Element&, const QualifiedName&);
    static bool isHostInItsShadowTree(const Element&, const ContainerNode* scope);

private:
    bool checkPseudoClass(const SelectorCheckingContext&);
    bool checkOne(const SelectorCheckingContext&);

    static bool checkExactAttribute(const Element&, const QualifiedName& selectorAttributeName, const StringImpl* value);
    static bool matchesFocusPseudoClass(const Element&);

    bool m_matchedAttributeSelector;
    bool m_matchedFocusSelector;
    bool m_matchedHoverSelector;
    bool m_matchedActiveSelector;
};

inline bool SelectorChecker::tagMatches(const Element& element, const QualifiedName& tagQName)
{
    const AtomicString& localName = tagQName.localName();
    return localName == starAtom || localName == element.localName();
}

inline bool SelectorChecker::checkExactAttribute(const Element& element, const QualifiedName& selectorAttributeName, const StringImpl* value)
{
    AttributeCollection attributes = element.attributesWithoutUpdate();
    AttributeCollection::iterator end = attributes.end();
    for (AttributeCollection::iterator it = attributes.begin(); it != end; ++it) {
        if (it->matches(selectorAttributeName) && (!value || it->value().impl() == value))
            return true;
    }
    return false;
}

inline bool SelectorChecker::isHostInItsShadowTree(const Element& element, const ContainerNode* scope)
{
    return scope && scope->isInShadowTree() && scope->shadowHost() == element;
}

}

#endif  // SKY_ENGINE_CORE_CSS_SELECTORCHECKER_H_
