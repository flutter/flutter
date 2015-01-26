/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011 Apple Inc. All rights reserved.
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
 *
 */

#ifndef SKY_ENGINE_CORE_CSS_RESOLVER_STYLERESOLVER_H_
#define SKY_ENGINE_CORE_CSS_RESOLVER_STYLERESOLVER_H_

#include "sky/engine/core/css/MediaQueryEvaluator.h"
#include "sky/engine/core/css/resolver/MatchedPropertiesCache.h"
#include "sky/engine/core/css/resolver/ScopedStyleResolver.h"
#include "sky/engine/platform/heap/Handle.h"
#include "sky/engine/wtf/Deque.h"
#include "sky/engine/wtf/HashMap.h"
#include "sky/engine/wtf/RefPtr.h"
#include "sky/engine/wtf/Vector.h"

namespace blink {

class AnimatableValue;
class CSSValue;
class Document;
class Element;
class ElementRuleCollector;
class Interpolation;
class StylePropertySet;
class StyleResolverStats;
class MatchResult;

const unsigned styleSharingListSize = 15;
typedef Deque<Element*, styleSharingListSize> StyleSharingList;

struct CSSPropertyValue {
    STACK_ALLOCATED();
public:
    CSSPropertyValue(CSSPropertyID property, CSSValue* value)
        : property(property), value(value) { }
    // Stores value=propertySet.getPropertyCSSValue(id).get().
    CSSPropertyValue(CSSPropertyID, const StylePropertySet&);
    CSSPropertyID property;
    RawPtr<CSSValue> value;
};

// This class selects a RenderStyle for a given element based on a collection of stylesheets.
class StyleResolver final {
    WTF_MAKE_NONCOPYABLE(StyleResolver); WTF_MAKE_FAST_ALLOCATED;
public:
    explicit StyleResolver(Document&);
    virtual ~StyleResolver();

    PassRefPtr<RenderStyle> styleForElement(Element*, RenderStyle* parentStyle = 0);

    static PassRefPtr<AnimatableValue> createAnimatableValueSnapshot(Element&, CSSPropertyID, CSSValue&);
    static PassRefPtr<AnimatableValue> createAnimatableValueSnapshot(StyleResolverState&, CSSPropertyID, CSSValue&);

    PassRefPtr<RenderStyle> defaultStyleForElement();
    PassRefPtr<RenderStyle> styleForText(Text*);

    static PassRefPtr<RenderStyle> styleForDocument(Document&);

    // |properties| is an array with |count| elements.
    void applyPropertiesToStyle(const CSSPropertyValue* properties, size_t count, RenderStyle*);

    // FIXME: Rename to reflect the purpose, like didChangeFontSize or something.
    void invalidateMatchedPropertiesCache();

    void notifyResizeForViewportUnits();

    StyleSharingList& styleSharingList() { return m_styleSharingList; }

    void addToStyleSharingList(Element&);
    void clearStyleSharingList();

    StyleResolverStats* stats() { return m_styleResolverStats.get(); }
    StyleResolverStats* statsTotals() { return m_styleResolverStatsTotals.get(); }
    enum StatsReportType { ReportDefaultStats, ReportSlowStats };
    void enableStats(StatsReportType = ReportDefaultStats);
    void disableStats();
    void printStats();

private:
    // FIXME: This should probably go away, folded into FontBuilder.
    void updateFont(StyleResolverState&);

    void loadPendingResources(StyleResolverState&);

    void matchRules(Element&, ElementRuleCollector&);

    void applyMatchedProperties(StyleResolverState&, const MatchResult&);
    bool applyAnimatedProperties(StyleResolverState&, Element* animatingElement);

    enum StyleApplicationPass {
        HighPriorityProperties,
        LowPriorityProperties
    };
    template <StyleResolver::StyleApplicationPass pass>
    static inline CSSPropertyID firstCSSPropertyId();
    template <StyleResolver::StyleApplicationPass pass>
    static inline CSSPropertyID lastCSSPropertyId();
    template <StyleResolver::StyleApplicationPass pass>
    static inline bool isPropertyForPass(CSSPropertyID);
    template <StyleApplicationPass pass>
    void applyMatchedProperties(StyleResolverState&, const MatchResult&, bool inheritedOnly);
    template <StyleApplicationPass pass>
    void applyProperties(StyleResolverState&, const StylePropertySet* properties, bool inheritedOnly);
    template <StyleApplicationPass pass>
    void applyAnimatedProperties(StyleResolverState&, const HashMap<CSSPropertyID, RefPtr<Interpolation> >&);
    template <StyleResolver::StyleApplicationPass pass>
    void applyAllProperty(StyleResolverState&, CSSValue*);

    MatchedPropertiesCache m_matchedPropertiesCache;

    Document& m_document;

    StyleSharingList m_styleSharingList;

    OwnPtr<StyleResolverStats> m_styleResolverStats;
    OwnPtr<StyleResolverStats> m_styleResolverStatsTotals;
    unsigned m_styleResolverStatsSequence;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_CSS_RESOLVER_STYLERESOLVER_H_
