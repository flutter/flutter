/*
 * (C) 1999-2003 Lars Knoll (knoll@kde.org)
 * (C) 2002-2003 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2002, 2006, 2008, 2012, 2013 Apple Inc. All rights reserved.
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

#ifndef SKY_ENGINE_CORE_CSS_STYLERULE_H_
#define SKY_ENGINE_CORE_CSS_STYLERULE_H_

#include "sky/engine/core/css/CSSSelectorList.h"
#include "sky/engine/core/css/MediaList.h"
#include "sky/engine/wtf/Noncopyable.h"
#include "sky/engine/wtf/RefPtr.h"

namespace blink {

class StylePropertySet;

class StyleRuleBase : public RefCounted<StyleRuleBase> {
    WTF_MAKE_FAST_ALLOCATED;
public:
    enum Type {
        Unknown, // Not used.
        Style,
        Media,
        FontFace = 4,
        Keyframes = 5,
        Keyframe, // Not used. These are internally non-rule StyleKeyframe objects.
        Supports = 12,
        Filter = 17
    };

    Type type() const { return static_cast<Type>(m_type); }

    bool isFontFaceRule() const { return type() == FontFace; }
    bool isKeyframesRule() const { return type() == Keyframes; }
    bool isMediaRule() const { return type() == Media; }
    bool isStyleRule() const { return type() == Style; }
    bool isSupportsRule() const { return type() == Supports; }
    bool isFilterRule() const { return type() == Filter; }

    void deref()
    {
        if (derefBase())
            destroy();
    }

protected:
    StyleRuleBase(Type type) : m_type(type) { }

    ~StyleRuleBase() { }

private:
    void destroy();

    unsigned m_type : 5;
};

class StyleRule final : public StyleRuleBase {
    WTF_MAKE_FAST_ALLOCATED;
    WTF_MAKE_NONCOPYABLE(StyleRule);
public:
    static PassRefPtr<StyleRule> create() { return adoptRef(new StyleRule()); }

    ~StyleRule();

    const CSSSelectorList& selectorList() const { return m_selectorList; }
    const StylePropertySet& properties() const { return *m_properties; }

    void parserAdoptSelectorVector(Vector<OwnPtr<CSSParserSelector> >& selectors) { m_selectorList.adoptSelectorVector(selectors); }
    void wrapperAdoptSelectorList(CSSSelectorList& selectors) { m_selectorList.adopt(selectors); }
    void setProperties(PassRefPtr<StylePropertySet>);

    static unsigned averageSizeInBytes();

private:
    StyleRule();

    RefPtr<StylePropertySet> m_properties; // Cannot be null.
    CSSSelectorList m_selectorList;
};

class StyleRuleFontFace final : public StyleRuleBase {
    WTF_MAKE_NONCOPYABLE(StyleRuleFontFace);
public:
    static PassRefPtr<StyleRuleFontFace> create() { return adoptRef(new StyleRuleFontFace); }

    ~StyleRuleFontFace();

    const StylePropertySet& properties() const { return *m_properties; }

    void setProperties(PassRefPtr<StylePropertySet>);

private:
    StyleRuleFontFace();

    RefPtr<StylePropertySet> m_properties; // Cannot be null.
};

class StyleRuleGroup : public StyleRuleBase {
public:
    const Vector<RefPtr<StyleRuleBase> >& childRules() const { return m_childRules; }

protected:
    StyleRuleGroup(Type, Vector<RefPtr<StyleRuleBase> >& adoptRule);

private:
    Vector<RefPtr<StyleRuleBase> > m_childRules;
};

class StyleRuleMedia final : public StyleRuleGroup {
    WTF_MAKE_NONCOPYABLE(StyleRuleMedia);
public:
    static PassRefPtr<StyleRuleMedia> create(PassRefPtr<MediaQuerySet> media, Vector<RefPtr<StyleRuleBase> >& adoptRules)
    {
        return adoptRef(new StyleRuleMedia(media, adoptRules));
    }

    MediaQuerySet* mediaQueries() const { return m_mediaQueries.get(); }

private:
    StyleRuleMedia(PassRefPtr<MediaQuerySet>, Vector<RefPtr<StyleRuleBase> >& adoptRules);

    RefPtr<MediaQuerySet> m_mediaQueries;
};

class StyleRuleSupports final : public StyleRuleGroup {
    WTF_MAKE_NONCOPYABLE(StyleRuleSupports);
public:
    static PassRefPtr<StyleRuleSupports> create(const String& conditionText, bool conditionIsSupported, Vector<RefPtr<StyleRuleBase> >& adoptRules)
    {
        return adoptRef(new StyleRuleSupports(conditionText, conditionIsSupported, adoptRules));
    }

    String conditionText() const { return m_conditionText; }
    bool conditionIsSupported() const { return m_conditionIsSupported; }

private:
    StyleRuleSupports(const String& conditionText, bool conditionIsSupported, Vector<RefPtr<StyleRuleBase> >& adoptRules);

    String m_conditionText;
    bool m_conditionIsSupported;
};

class StyleRuleFilter final : public StyleRuleBase {
    WTF_MAKE_NONCOPYABLE(StyleRuleFilter);
public:
    static PassRefPtr<StyleRuleFilter> create(const String& filterName) { return adoptRef(new StyleRuleFilter(filterName)); }

    ~StyleRuleFilter();

    const String& filterName() const { return m_filterName; }

    const StylePropertySet& properties() const { return *m_properties; }

    void setProperties(PassRefPtr<StylePropertySet>);

private:
    StyleRuleFilter(const String&);

    String m_filterName;
    RefPtr<StylePropertySet> m_properties;
};

#define DEFINE_STYLE_RULE_TYPE_CASTS(Type) \
    DEFINE_TYPE_CASTS(StyleRule##Type, StyleRuleBase, rule, rule->is##Type##Rule(), rule.is##Type##Rule())

DEFINE_TYPE_CASTS(StyleRule, StyleRuleBase, rule, rule->isStyleRule(), rule.isStyleRule());
DEFINE_STYLE_RULE_TYPE_CASTS(FontFace);
DEFINE_STYLE_RULE_TYPE_CASTS(Media);
DEFINE_STYLE_RULE_TYPE_CASTS(Supports);
DEFINE_STYLE_RULE_TYPE_CASTS(Filter);

} // namespace blink

#endif  // SKY_ENGINE_CORE_CSS_STYLERULE_H_
