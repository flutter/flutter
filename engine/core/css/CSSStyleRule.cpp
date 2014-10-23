/*
 * (C) 1999-2003 Lars Knoll (knoll@kde.org)
 * (C) 2002-2003 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2002, 2005, 2006, 2008, 2012 Apple Inc. All rights reserved.
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
#include "core/css/CSSStyleRule.h"

#include "core/css/parser/BisonCSSParser.h"
#include "core/css/CSSSelector.h"
#include "core/css/CSSStyleSheet.h"
#include "core/css/PropertySetCSSStyleDeclaration.h"
#include "core/css/StylePropertySet.h"
#include "core/css/StyleRule.h"
#include "wtf/text/StringBuilder.h"

namespace blink {

typedef HashMap<const CSSStyleRule*, String> SelectorTextCache;
static SelectorTextCache& selectorTextCache()
{
    DEFINE_STATIC_LOCAL(SelectorTextCache, cache, ());
    return cache;
}

CSSStyleRule::CSSStyleRule(StyleRule* styleRule, CSSStyleSheet* parent)
    : CSSRule(parent)
    , m_styleRule(styleRule)
{
}

CSSStyleRule::~CSSStyleRule()
{
#if !ENABLE(OILPAN)
    if (m_propertiesCSSOMWrapper)
        m_propertiesCSSOMWrapper->clearParentRule();
#endif
    if (hasCachedSelectorText()) {
        selectorTextCache().remove(this);
        setHasCachedSelectorText(false);
    }
}

CSSStyleDeclaration* CSSStyleRule::style() const
{
    if (!m_propertiesCSSOMWrapper) {
        m_propertiesCSSOMWrapper = StyleRuleCSSStyleDeclaration::create(m_styleRule->mutableProperties(), const_cast<CSSStyleRule*>(this));
    }
    return m_propertiesCSSOMWrapper.get();
}

String CSSStyleRule::generateSelectorText() const
{
    StringBuilder builder;
    for (const CSSSelector* selector = m_styleRule->selectorList().first(); selector; selector = CSSSelectorList::next(*selector)) {
        if (selector != m_styleRule->selectorList().first())
            builder.appendLiteral(", ");
        builder.append(selector->selectorText());
    }
    return builder.toString();
}

String CSSStyleRule::selectorText() const
{
    if (hasCachedSelectorText()) {
        ASSERT(selectorTextCache().contains(this));
        return selectorTextCache().get(this);
    }

    ASSERT(!selectorTextCache().contains(this));
    String text = generateSelectorText();
    selectorTextCache().set(this, text);
    setHasCachedSelectorText(true);
    return text;
}

void CSSStyleRule::setSelectorText(const String& selectorText)
{
    CSSParserContext context(parserContext(), 0);
    BisonCSSParser p(context);
    CSSSelectorList selectorList;
    p.parseSelector(selectorText, selectorList);
    if (!selectorList.isValid())
        return;

    CSSStyleSheet::RuleMutationScope mutationScope(this);

    m_styleRule->wrapperAdoptSelectorList(selectorList);

    if (hasCachedSelectorText()) {
        selectorTextCache().remove(this);
        setHasCachedSelectorText(false);
    }
}

String CSSStyleRule::cssText() const
{
    StringBuilder result;
    result.append(selectorText());
    result.appendLiteral(" { ");
    String decls = m_styleRule->properties().asText();
    result.append(decls);
    if (!decls.isEmpty())
        result.append(' ');
    result.append('}');
    return result.toString();
}

void CSSStyleRule::reattach(StyleRuleBase* rule)
{
    ASSERT(rule);
    m_styleRule = toStyleRule(rule);
    if (m_propertiesCSSOMWrapper)
        m_propertiesCSSOMWrapper->reattach(m_styleRule->mutableProperties());
}

void CSSStyleRule::trace(Visitor* visitor)
{
    visitor->trace(m_styleRule);
    visitor->trace(m_propertiesCSSOMWrapper);
    CSSRule::trace(visitor);
}

} // namespace blink
