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
#include "core/css/StyleRule.h"

#include "core/css/CSSFilterRule.h"
#include "core/css/CSSFontFaceRule.h"
#include "core/css/CSSKeyframesRule.h"
#include "core/css/CSSMediaRule.h"
#include "core/css/CSSStyleRule.h"
#include "core/css/CSSSupportsRule.h"
#include "core/css/StylePropertySet.h"

namespace blink {

struct SameSizeAsStyleRuleBase : public RefCounted<SameSizeAsStyleRuleBase> {
    unsigned bitfields;
};

COMPILE_ASSERT(sizeof(StyleRuleBase) <= sizeof(SameSizeAsStyleRuleBase), StyleRuleBase_should_stay_small);

PassRefPtr<CSSRule> StyleRuleBase::createCSSOMWrapper(CSSStyleSheet* parentSheet) const
{
    return createCSSOMWrapper(parentSheet, 0);
}

PassRefPtr<CSSRule> StyleRuleBase::createCSSOMWrapper(CSSRule* parentRule) const
{
    return createCSSOMWrapper(0, parentRule);
}

void StyleRuleBase::destroy()
{
    switch (type()) {
    case Style:
        delete toStyleRule(this);
        return;
    case FontFace:
        delete toStyleRuleFontFace(this);
        return;
    case Media:
        delete toStyleRuleMedia(this);
        return;
    case Supports:
        delete toStyleRuleSupports(this);
        return;
    case Keyframes:
        delete toStyleRuleKeyframes(this);
        return;
    case Filter:
        delete toStyleRuleFilter(this);
        return;
    case Unknown:
    case Keyframe:
        ASSERT_NOT_REACHED();
        return;
    }
    ASSERT_NOT_REACHED();
}

PassRefPtr<StyleRuleBase> StyleRuleBase::copy() const
{
    switch (type()) {
    case Style:
        return toStyleRule(this)->copy();
    case FontFace:
        return toStyleRuleFontFace(this)->copy();
    case Media:
        return toStyleRuleMedia(this)->copy();
    case Supports:
        return toStyleRuleSupports(this)->copy();
    case Keyframes:
        return toStyleRuleKeyframes(this)->copy();
    case Filter:
        return toStyleRuleFilter(this)->copy();
    case Unknown:
    case Keyframe:
        ASSERT_NOT_REACHED();
        return nullptr;
    }
    ASSERT_NOT_REACHED();
    return nullptr;
}

PassRefPtr<CSSRule> StyleRuleBase::createCSSOMWrapper(CSSStyleSheet* parentSheet, CSSRule* parentRule) const
{
    RefPtr<CSSRule> rule = nullptr;
    StyleRuleBase* self = const_cast<StyleRuleBase*>(this);
    switch (type()) {
    case Style:
        rule = CSSStyleRule::create(toStyleRule(self), parentSheet);
        break;
    case FontFace:
        rule = CSSFontFaceRule::create(toStyleRuleFontFace(self), parentSheet);
        break;
    case Media:
        rule = CSSMediaRule::create(toStyleRuleMedia(self), parentSheet);
        break;
    case Supports:
        rule = CSSSupportsRule::create(toStyleRuleSupports(self), parentSheet);
        break;
    case Keyframes:
        rule = CSSKeyframesRule::create(toStyleRuleKeyframes(self), parentSheet);
        break;
    case Filter:
        rule = CSSFilterRule::create(toStyleRuleFilter(self), parentSheet);
        break;
    case Unknown:
    case Keyframe:
        ASSERT_NOT_REACHED();
        return nullptr;
    }
    if (parentRule)
        rule->setParentRule(parentRule);
    return rule.release();
}

unsigned StyleRule::averageSizeInBytes()
{
    return sizeof(StyleRule) + sizeof(CSSSelector) + StylePropertySet::averageSizeInBytes();
}

StyleRule::StyleRule()
    : StyleRuleBase(Style)
{
}

StyleRule::StyleRule(const StyleRule& o)
    : StyleRuleBase(o)
    , m_properties(o.m_properties->mutableCopy())
    , m_selectorList(o.m_selectorList)
{
}

StyleRule::~StyleRule()
{
}

MutableStylePropertySet& StyleRule::mutableProperties()
{
    if (!m_properties->isMutable())
        m_properties = m_properties->mutableCopy();
    return *toMutableStylePropertySet(m_properties.get());
}

void StyleRule::setProperties(PassRefPtr<StylePropertySet> properties)
{
    m_properties = properties;
}

StyleRuleFontFace::StyleRuleFontFace()
    : StyleRuleBase(FontFace)
{
}

StyleRuleFontFace::StyleRuleFontFace(const StyleRuleFontFace& o)
    : StyleRuleBase(o)
    , m_properties(o.m_properties->mutableCopy())
{
}

StyleRuleFontFace::~StyleRuleFontFace()
{
}

MutableStylePropertySet& StyleRuleFontFace::mutableProperties()
{
    if (!m_properties->isMutable())
        m_properties = m_properties->mutableCopy();
    return *toMutableStylePropertySet(m_properties);
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

StyleRuleGroup::StyleRuleGroup(const StyleRuleGroup& o)
    : StyleRuleBase(o)
    , m_childRules(o.m_childRules.size())
{
    for (unsigned i = 0; i < m_childRules.size(); ++i)
        m_childRules[i] = o.m_childRules[i]->copy();
}

void StyleRuleGroup::wrapperInsertRule(unsigned index, PassRefPtr<StyleRuleBase> rule)
{
    m_childRules.insert(index, rule);
}

void StyleRuleGroup::wrapperRemoveRule(unsigned index)
{
    m_childRules.remove(index);
}

StyleRuleMedia::StyleRuleMedia(PassRefPtr<MediaQuerySet> media, Vector<RefPtr<StyleRuleBase> >& adoptRules)
    : StyleRuleGroup(Media, adoptRules)
    , m_mediaQueries(media)
{
}

StyleRuleMedia::StyleRuleMedia(const StyleRuleMedia& o)
    : StyleRuleGroup(o)
{
    if (o.m_mediaQueries)
        m_mediaQueries = o.m_mediaQueries->copy();
}

StyleRuleSupports::StyleRuleSupports(const String& conditionText, bool conditionIsSupported, Vector<RefPtr<StyleRuleBase> >& adoptRules)
    : StyleRuleGroup(Supports, adoptRules)
    , m_conditionText(conditionText)
    , m_conditionIsSupported(conditionIsSupported)
{
}

StyleRuleSupports::StyleRuleSupports(const StyleRuleSupports& o)
    : StyleRuleGroup(o)
    , m_conditionText(o.m_conditionText)
    , m_conditionIsSupported(o.m_conditionIsSupported)
{
}

StyleRuleFilter::StyleRuleFilter(const String& filterName)
    : StyleRuleBase(Filter)
    , m_filterName(filterName)
{
}

StyleRuleFilter::StyleRuleFilter(const StyleRuleFilter& o)
    : StyleRuleBase(o)
    , m_filterName(o.m_filterName)
    , m_properties(o.m_properties->mutableCopy())
{
}

StyleRuleFilter::~StyleRuleFilter()
{
}

MutableStylePropertySet& StyleRuleFilter::mutableProperties()
{
    if (!m_properties->isMutable())
        m_properties = m_properties->mutableCopy();
    return *toMutableStylePropertySet(m_properties);
}

void StyleRuleFilter::setProperties(PassRefPtr<StylePropertySet> properties)
{
    m_properties = properties;
}

} // namespace blink
