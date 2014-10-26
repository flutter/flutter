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

#ifndef StyleRule_h
#define StyleRule_h

#include "core/css/CSSSelectorList.h"
#include "core/css/MediaList.h"
#include "platform/heap/Handle.h"
#include "wtf/RefPtr.h"

namespace blink {

class CSSRule;
class CSSStyleRule;
class CSSStyleSheet;
class MutableStylePropertySet;
class StylePropertySet;

class StyleRuleBase : public RefCountedWillBeGarbageCollectedFinalized<StyleRuleBase> {
    WTF_MAKE_FAST_ALLOCATED_WILL_BE_REMOVED;
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

    PassRefPtrWillBeRawPtr<StyleRuleBase> copy() const;

#if !ENABLE(OILPAN)
    void deref()
    {
        if (derefBase())
            destroy();
    }
#endif // !ENABLE(OILPAN)

    // FIXME: There shouldn't be any need for the null parent version.
    PassRefPtrWillBeRawPtr<CSSRule> createCSSOMWrapper(CSSStyleSheet* parentSheet = 0) const;
    PassRefPtrWillBeRawPtr<CSSRule> createCSSOMWrapper(CSSRule* parentRule) const;

    void trace(Visitor*);
    void traceAfterDispatch(Visitor*) { };
    void finalizeGarbageCollectedObject();

protected:
    StyleRuleBase(Type type) : m_type(type) { }
    StyleRuleBase(const StyleRuleBase& o) : m_type(o.m_type) { }

    ~StyleRuleBase() { }

private:
    void destroy();

    PassRefPtrWillBeRawPtr<CSSRule> createCSSOMWrapper(CSSStyleSheet* parentSheet, CSSRule* parentRule) const;

    unsigned m_type : 5;
};

class StyleRule : public StyleRuleBase {
    WTF_MAKE_FAST_ALLOCATED_WILL_BE_REMOVED;
public:
    static PassRefPtrWillBeRawPtr<StyleRule> create() { return adoptRefWillBeNoop(new StyleRule()); }

    ~StyleRule();

    const CSSSelectorList& selectorList() const { return m_selectorList; }
    const StylePropertySet& properties() const { return *m_properties; }
    MutableStylePropertySet& mutableProperties();

    void parserAdoptSelectorVector(Vector<OwnPtr<CSSParserSelector> >& selectors) { m_selectorList.adoptSelectorVector(selectors); }
    void wrapperAdoptSelectorList(CSSSelectorList& selectors) { m_selectorList.adopt(selectors); }
    void setProperties(PassRefPtrWillBeRawPtr<StylePropertySet>);

    PassRefPtrWillBeRawPtr<StyleRule> copy() const { return adoptRefWillBeNoop(new StyleRule(*this)); }

    static unsigned averageSizeInBytes();

    void traceAfterDispatch(Visitor*);

private:
    StyleRule();
    StyleRule(const StyleRule&);

    RefPtrWillBeMember<StylePropertySet> m_properties; // Cannot be null.
    CSSSelectorList m_selectorList;
};

class StyleRuleFontFace : public StyleRuleBase {
public:
    static PassRefPtrWillBeRawPtr<StyleRuleFontFace> create() { return adoptRefWillBeNoop(new StyleRuleFontFace); }

    ~StyleRuleFontFace();

    const StylePropertySet& properties() const { return *m_properties; }
    MutableStylePropertySet& mutableProperties();

    void setProperties(PassRefPtrWillBeRawPtr<StylePropertySet>);

    PassRefPtrWillBeRawPtr<StyleRuleFontFace> copy() const { return adoptRefWillBeNoop(new StyleRuleFontFace(*this)); }

    void traceAfterDispatch(Visitor*);

private:
    StyleRuleFontFace();
    StyleRuleFontFace(const StyleRuleFontFace&);

    RefPtrWillBeMember<StylePropertySet> m_properties; // Cannot be null.
};

class StyleRuleGroup : public StyleRuleBase {
public:
    const WillBeHeapVector<RefPtrWillBeMember<StyleRuleBase> >& childRules() const { return m_childRules; }

    void wrapperInsertRule(unsigned, PassRefPtrWillBeRawPtr<StyleRuleBase>);
    void wrapperRemoveRule(unsigned);

    void traceAfterDispatch(Visitor*);

protected:
    StyleRuleGroup(Type, WillBeHeapVector<RefPtrWillBeMember<StyleRuleBase> >& adoptRule);
    StyleRuleGroup(const StyleRuleGroup&);

private:
    WillBeHeapVector<RefPtrWillBeMember<StyleRuleBase> > m_childRules;
};

class StyleRuleMedia : public StyleRuleGroup {
public:
    static PassRefPtrWillBeRawPtr<StyleRuleMedia> create(PassRefPtrWillBeRawPtr<MediaQuerySet> media, WillBeHeapVector<RefPtrWillBeMember<StyleRuleBase> >& adoptRules)
    {
        return adoptRefWillBeNoop(new StyleRuleMedia(media, adoptRules));
    }

    MediaQuerySet* mediaQueries() const { return m_mediaQueries.get(); }

    PassRefPtrWillBeRawPtr<StyleRuleMedia> copy() const { return adoptRefWillBeNoop(new StyleRuleMedia(*this)); }

    void traceAfterDispatch(Visitor*);

private:
    StyleRuleMedia(PassRefPtrWillBeRawPtr<MediaQuerySet>, WillBeHeapVector<RefPtrWillBeMember<StyleRuleBase> >& adoptRules);
    StyleRuleMedia(const StyleRuleMedia&);

    RefPtrWillBeMember<MediaQuerySet> m_mediaQueries;
};

class StyleRuleSupports : public StyleRuleGroup {
public:
    static PassRefPtrWillBeRawPtr<StyleRuleSupports> create(const String& conditionText, bool conditionIsSupported, WillBeHeapVector<RefPtrWillBeMember<StyleRuleBase> >& adoptRules)
    {
        return adoptRefWillBeNoop(new StyleRuleSupports(conditionText, conditionIsSupported, adoptRules));
    }

    String conditionText() const { return m_conditionText; }
    bool conditionIsSupported() const { return m_conditionIsSupported; }
    PassRefPtrWillBeRawPtr<StyleRuleSupports> copy() const { return adoptRefWillBeNoop(new StyleRuleSupports(*this)); }

    void traceAfterDispatch(Visitor* visitor) { StyleRuleGroup::traceAfterDispatch(visitor); }

private:
    StyleRuleSupports(const String& conditionText, bool conditionIsSupported, WillBeHeapVector<RefPtrWillBeMember<StyleRuleBase> >& adoptRules);
    StyleRuleSupports(const StyleRuleSupports&);

    String m_conditionText;
    bool m_conditionIsSupported;
};

class StyleRuleFilter : public StyleRuleBase {
public:
    static PassRefPtrWillBeRawPtr<StyleRuleFilter> create(const String& filterName) { return adoptRefWillBeNoop(new StyleRuleFilter(filterName)); }

    ~StyleRuleFilter();

    const String& filterName() const { return m_filterName; }

    const StylePropertySet& properties() const { return *m_properties; }
    MutableStylePropertySet& mutableProperties();

    void setProperties(PassRefPtrWillBeRawPtr<StylePropertySet>);

    PassRefPtrWillBeRawPtr<StyleRuleFilter> copy() const { return adoptRefWillBeNoop(new StyleRuleFilter(*this)); }

    void traceAfterDispatch(Visitor*);

private:
    StyleRuleFilter(const String&);
    StyleRuleFilter(const StyleRuleFilter&);

    String m_filterName;
    RefPtrWillBeMember<StylePropertySet> m_properties;
};

#define DEFINE_STYLE_RULE_TYPE_CASTS(Type) \
    DEFINE_TYPE_CASTS(StyleRule##Type, StyleRuleBase, rule, rule->is##Type##Rule(), rule.is##Type##Rule())

DEFINE_TYPE_CASTS(StyleRule, StyleRuleBase, rule, rule->isStyleRule(), rule.isStyleRule());
DEFINE_STYLE_RULE_TYPE_CASTS(FontFace);
DEFINE_STYLE_RULE_TYPE_CASTS(Media);
DEFINE_STYLE_RULE_TYPE_CASTS(Supports);
DEFINE_STYLE_RULE_TYPE_CASTS(Filter);

} // namespace blink

#endif // StyleRule_h
