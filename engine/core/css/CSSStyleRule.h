/*
 * (C) 1999-2003 Lars Knoll (knoll@kde.org)
 * (C) 2002-2003 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2002, 2006, 2008, 2012 Apple Inc. All rights reserved.
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

#ifndef CSSStyleRule_h
#define CSSStyleRule_h

#include "core/css/CSSRule.h"
#include "platform/heap/Handle.h"

namespace blink {

class CSSStyleDeclaration;
class StyleRuleCSSStyleDeclaration;
class StyleRule;

class CSSStyleRule FINAL : public CSSRule {
public:
    static PassRefPtrWillBeRawPtr<CSSStyleRule> create(StyleRule* rule, CSSStyleSheet* sheet)
    {
        return adoptRefWillBeNoop(new CSSStyleRule(rule, sheet));
    }

    virtual ~CSSStyleRule();

    virtual CSSRule::Type type() const OVERRIDE { return STYLE_RULE; }
    virtual String cssText() const OVERRIDE;
    virtual void reattach(StyleRuleBase*) OVERRIDE;

    String selectorText() const;
    void setSelectorText(const String&);

    CSSStyleDeclaration* style() const;

    // FIXME: Not CSSOM. Remove.
    StyleRule* styleRule() const { return m_styleRule.get(); }

    virtual void trace(Visitor*) OVERRIDE;

private:
    CSSStyleRule(StyleRule*, CSSStyleSheet*);

    String generateSelectorText() const;

    RefPtrWillBeMember<StyleRule> m_styleRule;
    mutable RefPtrWillBeMember<StyleRuleCSSStyleDeclaration> m_propertiesCSSOMWrapper;
};

DEFINE_CSS_RULE_TYPE_CASTS(CSSStyleRule, STYLE_RULE);

} // namespace blink

#endif // CSSStyleRule_h
