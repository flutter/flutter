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

#ifndef MatchedPropertiesCache_h
#define MatchedPropertiesCache_h

#include "core/css/StylePropertySet.h"
#include "core/css/resolver/MatchResult.h"
#include "platform/Timer.h"
#include "platform/heap/Handle.h"
#include "wtf/Forward.h"
#include "wtf/HashMap.h"
#include "wtf/Noncopyable.h"

namespace blink {

class RenderStyle;
class StyleResolverState;

class CachedMatchedProperties FINAL : public NoBaseWillBeGarbageCollectedFinalized<CachedMatchedProperties> {

public:
    WillBeHeapVector<MatchedProperties> matchedProperties;
    MatchRanges ranges;
    RefPtr<RenderStyle> renderStyle;
    RefPtr<RenderStyle> parentRenderStyle;

    void set(const RenderStyle*, const RenderStyle* parentStyle, const MatchResult&);
    void clear();
    void trace(Visitor* visitor) { visitor->trace(matchedProperties); }
};

// Specialize the HashTraits for CachedMatchedProperties to check for dead
// entries in the MatchedPropertiesCache.
#if ENABLE(OILPAN)
struct CachedMatchedPropertiesHashTraits : HashTraits<Member<CachedMatchedProperties> > {
    static const WTF::WeakHandlingFlag weakHandlingFlag = WTF::WeakHandlingInCollections;
    static bool traceInCollection(Visitor*, Member<CachedMatchedProperties>&, WTF::ShouldWeakPointersBeMarkedStrongly);
};
#endif

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

    void trace(Visitor*);

private:
#if ENABLE(OILPAN)
    typedef HeapHashMap<unsigned, Member<CachedMatchedProperties>, DefaultHash<unsigned>::Hash, HashTraits<unsigned>, CachedMatchedPropertiesHashTraits > Cache;
#else
    // Every N additions to the matched declaration cache trigger a sweep where entries holding
    // the last reference to a style declaration are garbage collected.
    void sweep(Timer<MatchedPropertiesCache>*);

    unsigned m_additionsSinceLastSweep;

    typedef HashMap<unsigned, OwnPtr<CachedMatchedProperties> > Cache;
    Timer<MatchedPropertiesCache> m_sweepTimer;
#endif
    Cache m_cache;
};

}

#endif
