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

#include "sky/engine/core/css/StyleRule.h"

#include "sky/engine/core/css/StylePropertySet.h"

namespace blink {

struct SameSizeAsStyleRuleBase : public RefCounted<SameSizeAsStyleRuleBase> {
    unsigned bitfields;
};

COMPILE_ASSERT(sizeof(StyleRuleBase) <= sizeof(SameSizeAsStyleRuleBase), StyleRuleBase_should_stay_small);

void StyleRuleBase::destroy()
{
    switch (type()) {
    case Style:
        delete toStyleRule(this);
        return;
    case FontFace:
        delete toStyleRuleFontFace(this);
        return;
    case Supports:
        delete toStyleRuleSupports(this);
        return;
    case Unknown:
        ASSERT_NOT_REACHED();
        return;
    }
    ASSERT_NOT_REACHED();
}

unsigned StyleRule::averageSizeInBytes()
{
    return sizeof(StyleRule) + sizeof(CSSSelector) + StylePropertySet::averageSizeInBytes();
}

StyleRule::StyleRule()
    : StyleRuleBase(Style)
{
}

StyleRule::~StyleRule()
{
}

void StyleRule::setProperties(PassRefPtr<StylePropertySet> properties)
{
    m_properties = properties;
}

StyleRuleFontFace::StyleRuleFontFace()
    : StyleRuleBase(FontFace)
{
}

StyleRuleFontFace::~StyleRuleFontFace()
{
}

void StyleRuleFontFace::setProperties(PassRefPtr<StylePropertySet> properties)
{
    m_properties = properties;
}

StyleRuleGroup::StyleRuleGroup(Type type, Vector<RefPtr<StyleRuleBase> >& adoptRule)
    : StyleRuleBase(type)
{
    m_childRules.swap(adoptRule);
}

StyleRuleSupports::StyleRuleSupports(const String& conditionText, bool conditionIsSupported, Vector<RefPtr<StyleRuleBase> >& adoptRules)
    : StyleRuleGroup(Supports, adoptRules)
    , m_conditionText(conditionText)
    , m_conditionIsSupported(conditionIsSupported)
{
}

} // namespace blink
