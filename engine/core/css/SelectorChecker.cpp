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

#include "sky/engine/core/css/CSSSelectorList.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/shadow/ShadowRoot.h"
#include "sky/engine/core/editing/FrameSelection.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/html/parser/HTMLParserIdioms.h"
#include "sky/engine/core/page/FocusController.h"
#include "sky/engine/core/rendering/style/RenderStyle.h"

namespace blink {

SelectorChecker::SelectorChecker()
    : m_matchedAttributeSelector(false)
    , m_matchedFocusSelector(false)
    , m_matchedHoverSelector(false)
    , m_matchedActiveSelector(false)
{
}

static bool scopeContainsLastMatchedElement(const SelectorChecker::SelectorCheckingContext& context)
{
    if (!context.scope)
        return true;

    ASSERT(context.scope);
    if (context.scope->treeScope() == context.element->treeScope())
        return true;

    // Because Blink treats a shadow host's TreeScope as a separate one from its descendent shadow roots,
    // if the last matched element is a shadow host, the condition above isn't met, even though it
    // should be.
    return context.element == context.scope->shadowHost();
}

bool SelectorChecker::match(const SelectorCheckingContext& context)
{
    // FIXME(sky): Get rid of SelectorCheckingContext.
    SelectorCheckingContext matchContext(context);

    bool isShadowHost = isHostInItsShadowTree(*context.element, context.scope);

    while (true) {
        const CSSSelector& selector = *matchContext.selector;
        // Only :host and :host-context() should match the host:
        // http://drafts.csswg.org/css-scoping/#host-element
        if (isShadowHost && !selector.isHostPseudoClass())
            return false;
        if (!checkOne(matchContext))
            return false;
        if (selector.isLastInTagHistory())
            return scopeContainsLastMatchedElement(matchContext);
        matchContext.selector = selector.tagHistory();
    }

    ASSERT_NOT_REACHED();
    return false;
}

template<typename CharType>
static inline bool containsHTMLSpaceTemplate(const CharType* string, unsigned length)
{
    for (unsigned i = 0; i < length; ++i)
        if (isHTMLSpace<CharType>(string[i]))
            return true;
    return false;
}

static inline bool containsHTMLSpace(const AtomicString& string)
{
    if (LIKELY(string.is8Bit()))
        return containsHTMLSpaceTemplate<LChar>(string.characters8(), string.length());
    return containsHTMLSpaceTemplate<UChar>(string.characters16(), string.length());
}

static bool attributeValueMatches(const Attribute& attributeItem, CSSSelector::Match match, const AtomicString& selectorValue, bool caseSensitive)
{
    const AtomicString& value = attributeItem.value();
    if (value.isNull())
        return false;

    switch (match) {
    case CSSSelector::Exact:
        if (caseSensitive ? selectorValue != value : !equalIgnoringCase(selectorValue, value))
            return false;
        break;
    case CSSSelector::List:
        {
            // Ignore empty selectors or selectors containing HTML spaces
            if (selectorValue.isEmpty() || containsHTMLSpace(selectorValue))
                return false;

            unsigned startSearchAt = 0;
            while (true) {
                size_t foundPos = value.find(selectorValue, startSearchAt, caseSensitive);
                if (foundPos == kNotFound)
                    return false;
                if (!foundPos || isHTMLSpace<UChar>(value[foundPos - 1])) {
                    unsigned endStr = foundPos + selectorValue.length();
                    if (endStr == value.length() || isHTMLSpace<UChar>(value[endStr]))
                        break; // We found a match.
                }

                // No match. Keep looking.
                startSearchAt = foundPos + 1;
            }
            break;
        }
    case CSSSelector::Contain:
        if (!value.contains(selectorValue, caseSensitive) || selectorValue.isEmpty())
            return false;
        break;
    case CSSSelector::Begin:
        if (!value.startsWith(selectorValue, caseSensitive) || selectorValue.isEmpty())
            return false;
        break;
    case CSSSelector::End:
        if (!value.endsWith(selectorValue, caseSensitive) || selectorValue.isEmpty())
            return false;
        break;
    case CSSSelector::Hyphen:
        if (value.length() < selectorValue.length())
            return false;
        if (!value.startsWith(selectorValue, caseSensitive))
            return false;
        // It they start the same, check for exact match or following '-':
        if (value.length() != selectorValue.length() && value[selectorValue.length()] != '-')
            return false;
        break;
    default:
        break;
    }

    return true;
}

static bool anyAttributeMatches(const Element& element, CSSSelector::Match match, const CSSSelector& selector)
{
    const QualifiedName& selectorAttr = selector.attribute();
    ASSERT(selectorAttr.localName() != starAtom); // Should not be possible from the CSS grammar.

    // Synchronize the attribute in case it is lazy-computed.
    element.synchronizeAttribute(selectorAttr.localName());

    const AtomicString& selectorValue = selector.value();
    bool caseInsensitive = selector.attributeMatchType() == CSSSelector::CaseInsensitive;

    AttributeCollection attributes = element.attributesWithoutUpdate();
    AttributeCollection::iterator end = attributes.end();
    for (AttributeCollection::iterator it = attributes.begin(); it != end; ++it) {
        const Attribute& attributeItem = *it;

        if (!attributeItem.matches(selectorAttr))
            continue;

        if (attributeValueMatches(attributeItem, match, selectorValue, !caseInsensitive))
            return true;
    }

    return false;
}

bool SelectorChecker::checkOne(const SelectorCheckingContext& context)
{
    ASSERT(context.element);
    const Element& element = *context.element;
    ASSERT(context.selector);
    const CSSSelector& selector = *context.selector;

    switch (selector.match()) {
    case CSSSelector::Tag:
        return tagMatches(element, selector.tagQName());
    case CSSSelector::Class:
        return element.hasClass() && element.classNames().contains(selector.value());
    case CSSSelector::Id:
        return element.hasID() && element.idForStyleResolution() == selector.value();
    case CSSSelector::Exact:
    case CSSSelector::Set:
    case CSSSelector::Hyphen:
    case CSSSelector::List:
    case CSSSelector::Contain:
    case CSSSelector::Begin:
    case CSSSelector::End:
        if (anyAttributeMatches(element, selector.match(), selector)) {
            m_matchedAttributeSelector = true;
            return true;
        }
        return false;
    case CSSSelector::PseudoClass:
        return checkPseudoClass(context);
    // FIXME(sky): Remove pseudo elements completely.
    case CSSSelector::PseudoElement:
    case CSSSelector::Unknown:
        return false;
    }
    ASSERT_NOT_REACHED();
    return false;
}

bool SelectorChecker::checkPseudoClass(const SelectorCheckingContext& context)
{
    ASSERT(context.element);
    const Element& element = *context.element;
    ASSERT(context.selector);
    const CSSSelector& selector = *context.selector;
    ASSERT(selector.match() == CSSSelector::PseudoClass);

    // Normal element pseudo class checking.
    switch (selector.pseudoType()) {
    case CSSSelector::PseudoFocus:
        m_matchedFocusSelector = true;
        return matchesFocusPseudoClass(element);

    case CSSSelector::PseudoHover:
        m_matchedHoverSelector = true;
        return element.hovered();

    case CSSSelector::PseudoActive:
        m_matchedActiveSelector = true;
        return element.active();

    case CSSSelector::PseudoLang:
        {
            AtomicString value = element.computeInheritedLanguage();
            const AtomicString& argument = selector.argument();
            if (value.isEmpty() || !value.startsWith(argument, false))
                break;
            if (value.length() != argument.length() && value[argument.length()] != '-')
                break;
            return true;
        }

    case CSSSelector::PseudoUnresolved:
        return element.isUnresolvedCustomElement();

    case CSSSelector::PseudoHost:
        {
            // :host only matches a shadow host when :host is in a shadow tree of the shadow host.
            if (!context.scope)
                return false;
            const ContainerNode* shadowHost = context.scope->shadowHost();
            if (!shadowHost || shadowHost != element)
                return false;
            ASSERT(element.shadow());

            // For empty parameter case, i.e. just :host or :host().
            if (!selector.selectorList())
                return true;

            SelectorCheckingContext subContext(context);

            // Treat the inside of :host() rules as if they were defined in the
            // same scope as the host.
            subContext.scope = &context.element->treeScope().rootNode();

            for (subContext.selector = selector.selectorList()->first(); subContext.selector; subContext.selector = CSSSelectorList::next(*subContext.selector)) {
                if (match(subContext))
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

bool SelectorChecker::matchesFocusPseudoClass(const Element& element)
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

}
