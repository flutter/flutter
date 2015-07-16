/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011 Apple Inc. All rights reserved.
 * Copyright (C) 2013 Google Inc. All rights reserved.
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

#ifndef SKY_ENGINE_CORE_CSS_RESOLVER_MATCHEDPROPERTIESCACHE_H_
#define SKY_ENGINE_CORE_CSS_RESOLVER_MATCHEDPROPERTIESCACHE_H_

#include "sky/engine/core/css/StylePropertySet.h"
#include "sky/engine/core/css/resolver/MatchResult.h"
#include "sky/engine/platform/Timer.h"
#include "sky/engine/platform/heap/Handle.h"
#include "sky/engine/wtf/Forward.h"
#include "sky/engine/wtf/HashMap.h"
#include "sky/engine/wtf/Noncopyable.h"

namespace blink {

class RenderStyle;
class StyleResolverState;

class CachedMatchedProperties final {
public:
    Vector<RefPtr<StylePropertySet>> matchedProperties;
    RefPtr<RenderStyle> renderStyle;
    RefPtr<RenderStyle> parentRenderStyle;

    void set(const RenderStyle*, const RenderStyle* parentStyle, const MatchResult&);
    void clear();
};

class MatchedPropertiesCache {
    DISALLOW_ALLOCATION();
    WTF_MAKE_NONCOPYABLE(MatchedPropertiesCache);
public:
    MatchedPropertiesCache();

    const CachedMatchedProperties* find(unsigned hash, const StyleResolverState&, const MatchResult&);
    void add(const RenderStyle*, const RenderStyle* parentStyle, unsigned hash, const MatchResult&);

    void clear();
    void clearViewportDependent();

    static bool isCacheable(const Element*, const RenderStyle*, const RenderStyle* parentStyle);

private:
    // Every N additions to the matched declaration cache trigger a sweep where entries holding
    // the last reference to a style declaration are garbage collected.
    void sweep(Timer<MatchedPropertiesCache>*);

    unsigned m_additionsSinceLastSweep;

    typedef HashMap<unsigned, OwnPtr<CachedMatchedProperties> > Cache;
    Timer<MatchedPropertiesCache> m_sweepTimer;
    Cache m_cache;
};

}

#endif  // SKY_ENGINE_CORE_CSS_RESOLVER_MATCHEDPROPERTIESCACHE_H_
