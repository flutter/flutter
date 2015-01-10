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

#include "sky/engine/config.h"
#include "sky/engine/core/css/SelectorChecker.h"

#include "sky/engine/core/css/CSSSelector.h"
#include "sky/engine/core/css/CSSSelectorList.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/shadow/ShadowRoot.h"
#include "sky/engine/core/editing/FrameSelection.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/html/parser/HTMLParserIdioms.h"
#include "sky/engine/core/page/FocusController.h"
#include "sky/engine/core/rendering/style/RenderStyle.h"

namespace blink {

static bool matchesFocusPseudoClass(const Element& element)
{
    if (!element.focused())
        return false;
    LocalFrame* frame = element.document().frame();
    if (!frame)
        return false;
    if (!frame->selection().isFocusedAndActive())
        return false;
    return true;
}

SelectorChecker::SelectorChecker(const Element& element)
    : m_element(element)
    , m_matchedAttributeSelector(false)
    , m_matchedFocusSelector(false)
    , m_matchedHoverSelector(false)
    , m_matchedActiveSelector(false)
{
}

bool SelectorChecker::match(const CSSSelector& selector)
{
    const CSSSelector* current = &selector;

    do {
        if (!checkOne(*current))
            return false;
        current = current->tagHistory();
    } while (current);

    return true;
}

static bool anyAttributeMatches(const Element& element, CSSSelector::Match match, const CSSSelector& selector)
{
    const QualifiedName& selectorAttr = selector.attribute();
    ASSERT(selectorAttr.localName() != starAtom); // Should not be possible from the CSS grammar.

    if (match == CSSSelector::Set)
        return element.hasAttribute(selectorAttr);

    ASSERT(match == CSSSelector::Exact);

    const AtomicString& selectorValue = selector.value();
    const AtomicString& value = element.getAttribute(selectorAttr);

    if (value.isNull())
        return false;
    if (selector.attributeMatchType() == CSSSelector::CaseInsensitive)
        return equalIgnoringCase(selectorValue, value);
    return selectorValue == value;
}

bool SelectorChecker::checkOne(const CSSSelector& selector)
{
    switch (selector.match()) {
    case CSSSelector::Tag:
        {
            const AtomicString& localName = selector.tagQName().localName();
            return localName == starAtom || localName == m_element.localName();
        }
    case CSSSelector::Class:
        return m_element.hasClass() && m_element.classNames().contains(selector.value());
    case CSSSelector::Id:
        return m_element.hasID() && m_element.idForStyleResolution() == selector.value();
    case CSSSelector::Exact:
    case CSSSelector::Set:
        if (anyAttributeMatches(m_element, selector.match(), selector)) {
            m_matchedAttributeSelector = true;
            return true;
        }
        return false;
    case CSSSelector::PseudoClass:
        return checkPseudoClass(selector);
    // FIXME(sky): Remove pseudo elements completely.
    case CSSSelector::PseudoElement:
    case CSSSelector::Unknown:
        return false;
    }
    ASSERT_NOT_REACHED();
    return false;
}

bool SelectorChecker::checkPseudoClass(const CSSSelector& selector)
{
    switch (selector.pseudoType()) {
    case CSSSelector::PseudoFocus:
        m_matchedFocusSelector = true;
        return matchesFocusPseudoClass(m_element);

    case CSSSelector::PseudoHover:
        m_matchedHoverSelector = true;
        return m_element.hovered();

    case CSSSelector::PseudoActive:
        m_matchedActiveSelector = true;
        return m_element.active();

    case CSSSelector::PseudoLang:
        {
            AtomicString value = m_element.computeInheritedLanguage();
            const AtomicString& argument = selector.argument();
            if (value.isEmpty() || !value.startsWith(argument, false))
                break;
            if (value.length() != argument.length() && value[argument.length()] != '-')
                break;
            return true;
        }

    case CSSSelector::PseudoUnresolved:
        return m_element.isUnresolvedCustomElement();

    case CSSSelector::PseudoHost:
        {
            // We can only get here if the selector was defined in the right
            // scope so we don't need to check it.

            // For empty parameter case, i.e. just :host or :host().
            if (!selector.selectorList())
                return true;
            for (const CSSSelector* current = selector.selectorList()->first(); current; current = CSSSelectorList::next(*current)) {
                if (match(*current))
                    return true;
            }
            return false;
        }

    case CSSSelector::PseudoUnknown:
    case CSSSelector::PseudoNotParsed:
    case CSSSelector::PseudoUserAgentCustomElement:
        return false;
    }
    ASSERT_NOT_REACHED();
    return false;
}

}
