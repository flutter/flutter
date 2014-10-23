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
#include "core/css/CSSFontFaceRule.h"

#include "core/css/PropertySetCSSStyleDeclaration.h"
#include "core/css/StylePropertySet.h"
#include "core/css/StyleRule.h"
#include "wtf/text/StringBuilder.h"

namespace blink {

CSSFontFaceRule::CSSFontFaceRule(StyleRuleFontFace* fontFaceRule, CSSStyleSheet* parent)
    : CSSRule(parent)
    , m_fontFaceRule(fontFaceRule)
{
}

CSSFontFaceRule::~CSSFontFaceRule()
{
#if !ENABLE(OILPAN)
    if (m_propertiesCSSOMWrapper)
        m_propertiesCSSOMWrapper->clearParentRule();
#endif
}

CSSStyleDeclaration* CSSFontFaceRule::style() const
{
    if (!m_propertiesCSSOMWrapper)
        m_propertiesCSSOMWrapper = StyleRuleCSSStyleDeclaration::create(m_fontFaceRule->mutableProperties(), const_cast<CSSFontFaceRule*>(this));
    return m_propertiesCSSOMWrapper.get();
}

String CSSFontFaceRule::cssText() const
{
    StringBuilder result;
    result.appendLiteral("@font-face { ");
    String descs = m_fontFaceRule->properties().asText();
    result.append(descs);
    if (!descs.isEmpty())
        result.append(' ');
    result.append('}');
    return result.toString();
}

void CSSFontFaceRule::reattach(StyleRuleBase* rule)
{
    ASSERT(rule);
    m_fontFaceRule = toStyleRuleFontFace(rule);
    if (m_propertiesCSSOMWrapper)
        m_propertiesCSSOMWrapper->reattach(m_fontFaceRule->mutableProperties());
}

void CSSFontFaceRule::trace(Visitor* visitor)
{
    visitor->trace(m_fontFaceRule);
    visitor->trace(m_propertiesCSSOMWrapper);
    CSSRule::trace(visitor);
}

} // namespace blink
