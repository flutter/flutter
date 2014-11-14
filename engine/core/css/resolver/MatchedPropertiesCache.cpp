/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 2004-2005 Allan Sandfeld Jensen (kde@carewolf.com)
 * Copyright (C) 2006, 2007 Nicholas Shanks (webkit@nickshanks.com)
 * Copyright (C) 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013 Apple Inc. All rights reserved.
 * Copyright (C) 2007 Alexey Proskuryakov <ap@webkit.org>
 * Copyright (C) 2007, 2008 Eric Seidel <eric@webkit.org>
 * Copyright (C) 2008, 2009 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
 * Copyright (c) 2011, Code Aurora Forum. All rights reserved.
 * Copyright (C) Research In Motion Limited 2011. All rights reserved.
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
 */

#include "config.h"
#include "core/css/resolver/MatchedPropertiesCache.h"

#include "core/css/StylePropertySet.h"
#include "core/css/resolver/StyleResolverState.h"
#include "core/rendering/style/RenderStyle.h"

namespace blink {

void CachedMatchedProperties::set(const RenderStyle* style, const RenderStyle* parentStyle, const MatchResult& matchResult)
{
    matchedProperties.appendVector(matchResult.matchedProperties);
    ranges = matchResult.ranges;

    // Note that we don't cache the original RenderStyle instance. It may be further modified.
    // The RenderStyle in the cache is really just a holder for the substructures and never used as-is.
    this->renderStyle = RenderStyle::clone(style);
    this->parentRenderStyle = RenderStyle::clone(parentStyle);
}

void CachedMatchedProperties::clear()
{
    matchedProperties.clear();
    renderStyle = nullptr;
    parentRenderStyle = nullptr;
}

MatchedPropertiesCache::MatchedPropertiesCache()
    : m_additionsSinceLastSweep(0)
    , m_sweepTimer(this, &MatchedPropertiesCache::sweep)
{
}

const CachedMatchedProperties* MatchedPropertiesCache::find(unsigned hash, const StyleResolverState& styleResolverState, const MatchResult& matchResult)
{
    ASSERT(hash);

    Cache::iterator it = m_cache.find(hash);
    if (it == m_cache.end())
        return 0;
    CachedMatchedProperties* cacheItem = it->value.get();
    ASSERT(cacheItem);

    size_t size = matchResult.matchedProperties.size();
    if (size != cacheItem->matchedProperties.size())
        return 0;
    for (size_t i = 0; i < size; ++i) {
        if (matchResult.matchedProperties[i] != cacheItem->matchedProperties[i])
            return 0;
    }
    if (cacheItem->ranges != matchResult.ranges)
        return 0;
    return cacheItem;
}

void MatchedPropertiesCache::add(const RenderStyle* style, const RenderStyle* parentStyle, unsigned hash, const MatchResult& matchResult)
{
    static const unsigned maxAdditionsBetweenSweeps = 100;
    if (++m_additionsSinceLastSweep >= maxAdditionsBetweenSweeps
        && !m_sweepTimer.isActive()) {
        static const unsigned sweepTimeInSeconds = 60;
        m_sweepTimer.startOneShot(sweepTimeInSeconds, FROM_HERE);
    }

    ASSERT(hash);
    Cache::AddResult addResult = m_cache.add(hash, nullptr);
    if (addResult.isNewEntry)
        addResult.storedValue->value = adoptPtr(new CachedMatchedProperties);

    CachedMatchedProperties* cacheItem = addResult.storedValue->value.get();
    if (!addResult.isNewEntry)
        cacheItem->clear();

    cacheItem->set(style, parentStyle, matchResult);
}

void MatchedPropertiesCache::clear()
{
    m_cache.clear();
}

void MatchedPropertiesCache::clearViewportDependent()
{
    Vector<unsigned, 16> toRemove;
    for (Cache::iterator it = m_cache.begin(); it != m_cache.end(); ++it) {
        CachedMatchedProperties* cacheItem = it->value.get();
        if (cacheItem->renderStyle->hasViewportUnits())
            toRemove.append(it->key);
    }
    m_cache.removeAll(toRemove);
}

void MatchedPropertiesCache::sweep(Timer<MatchedPropertiesCache>*)
{
    // FIXME(sky): Do we still need this now that we removed PresentationAttributeStyle?
    Vector<unsigned, 16> toRemove;
    Cache::iterator it = m_cache.begin();
    Cache::iterator end = m_cache.end();
    for (; it != end; ++it) {
        CachedMatchedProperties* cacheItem = it->value.get();
        Vector<MatchedProperties>& matchedProperties = cacheItem->matchedProperties;
        for (size_t i = 0; i < matchedProperties.size(); ++i) {
            if (matchedProperties[i].properties->hasOneRef()) {
                toRemove.append(it->key);
                break;
            }
        }
    }
    m_cache.removeAll(toRemove);
    m_additionsSinceLastSweep = 0;
}

bool MatchedPropertiesCache::isCacheable(const Element* element, const RenderStyle* style, const RenderStyle* parentStyle)
{
    if (style->unique() || (style->styleType() != NOPSEUDO && parentStyle->unique()))
        return false;
    if (style->hasCurrentColor())
        return false;
    // The cache assumes static knowledge about which properties are inherited.
    if (parentStyle->hasExplicitlyInheritedProperties())
        return false;
    return true;
}

}
