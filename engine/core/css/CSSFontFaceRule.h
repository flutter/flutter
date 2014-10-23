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

#ifndef CSSFontFaceRule_h
#define CSSFontFaceRule_h

#include "core/css/CSSRule.h"
#include "platform/heap/Handle.h"

namespace blink {

class CSSStyleDeclaration;
class StyleRuleFontFace;
class StyleRuleCSSStyleDeclaration;

class CSSFontFaceRule FINAL : public CSSRule {
public:
    static PassRefPtrWillBeRawPtr<CSSFontFaceRule> create(StyleRuleFontFace* rule, CSSStyleSheet* sheet)
    {
        return adoptRefWillBeNoop(new CSSFontFaceRule(rule, sheet));
    }

    virtual ~CSSFontFaceRule();

    virtual CSSRule::Type type() const OVERRIDE { return FONT_FACE_RULE; }
    virtual String cssText() const OVERRIDE;
    virtual void reattach(StyleRuleBase*) OVERRIDE;

    CSSStyleDeclaration* style() const;

    StyleRuleFontFace* styleRule() const { return m_fontFaceRule.get(); }

    virtual void trace(Visitor*) OVERRIDE;

private:
    CSSFontFaceRule(StyleRuleFontFace*, CSSStyleSheet* parent);

    RefPtrWillBeMember<StyleRuleFontFace> m_fontFaceRule;
    mutable RefPtrWillBeMember<StyleRuleCSSStyleDeclaration> m_propertiesCSSOMWrapper;
};

DEFINE_CSS_RULE_TYPE_CASTS(CSSFontFaceRule, FONT_FACE_RULE);

} // namespace blink

#endif // CSSFontFaceRule_h
