/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "platform/fonts/FontDataCache.h"

#include "platform/fonts/SimpleFontData.h"

using namespace WTF;

namespace blink {

#if !OS(ANDROID)
const unsigned cMaxInactiveFontData = 250;
const unsigned cTargetInactiveFontData = 200;
#else
const unsigned cMaxInactiveFontData = 225;
const unsigned cTargetInactiveFontData = 200;
#endif

PassRefPtr<SimpleFontData> FontDataCache::get(const FontPlatformData* platformData, ShouldRetain shouldRetain)
{
    if (!platformData)
        return nullptr;

    Cache::iterator result = m_cache.find(*platformData);
    if (result == m_cache.end()) {
        pair<RefPtr<SimpleFontData>, unsigned> newValue(SimpleFontData::create(*platformData), shouldRetain == Retain ? 1 : 0);
        m_cache.set(*platformData, newValue);
        if (shouldRetain == DoNotRetain)
            m_inactiveFontData.add(newValue.first);
        return newValue.first.release();
    }

    if (!result.get()->value.second) {
        ASSERT(m_inactiveFontData.contains(result.get()->value.first));
        m_inactiveFontData.remove(result.get()->value.first);
    }

    if (shouldRetain == Retain) {
        result.get()->value.second++;
    } else if (!result.get()->value.second) {
        // If shouldRetain is DoNotRetain and count is 0, we want to remove the fontData from
        // m_inactiveFontData (above) and re-add here to update LRU position.
        m_inactiveFontData.add(result.get()->value.first);
    }

    return result.get()->value.first;
}

bool FontDataCache::contains(const FontPlatformData* fontPlatformData) const
{
    return m_cache.contains(*fontPlatformData);
}

void FontDataCache::release(const SimpleFontData* fontData)
{
    ASSERT(!fontData->isCustomFont());

    Cache::iterator it = m_cache.find(fontData->platformData());
    ASSERT(it != m_cache.end());
    if (it == m_cache.end())
        return;

    ASSERT(it->value.second);
    if (!--it->value.second)
        m_inactiveFontData.add(it->value.first);
}

void FontDataCache::markAllVerticalData()
{
#if ENABLE(OPENTYPE_VERTICAL)
    Cache::iterator end = m_cache.end();
    for (Cache::iterator fontData = m_cache.begin(); fontData != end; ++fontData) {
        OpenTypeVerticalData* verticalData = const_cast<OpenTypeVerticalData*>(fontData->value.first->verticalData());
        if (verticalData)
            verticalData->setInFontCache(true);
    }
#endif
}

bool FontDataCache::purge(PurgeSeverity PurgeSeverity)
{
    if (PurgeSeverity == ForcePurge)
        return purgeLeastRecentlyUsed(INT_MAX);

    if (m_inactiveFontData.size() > cMaxInactiveFontData)
        return purgeLeastRecentlyUsed(m_inactiveFontData.size() - cTargetInactiveFontData);

    return false;
}

bool FontDataCache::purgeLeastRecentlyUsed(int count)
{
    static bool isPurging; // Guard against reentry when e.g. a deleted FontData releases its small caps FontData.
    if (isPurging)
        return false;

    isPurging = true;

    Vector<RefPtr<SimpleFontData>, 20> fontDataToDelete;
    ListHashSet<RefPtr<SimpleFontData> >::iterator end = m_inactiveFontData.end();
    ListHashSet<RefPtr<SimpleFontData> >::iterator it = m_inactiveFontData.begin();
    for (int i = 0; i < count && it != end; ++it, ++i) {
        RefPtr<SimpleFontData>& fontData = *it.get();
        m_cache.remove(fontData->platformData());
        // We should not delete SimpleFontData here because deletion can modify m_inactiveFontData. See http://trac.webkit.org/changeset/44011
        fontDataToDelete.append(fontData);
    }

    if (it == end) {
        // Removed everything
        m_inactiveFontData.clear();
    } else {
        for (int i = 0; i < count; ++i)
            m_inactiveFontData.remove(m_inactiveFontData.begin());
    }

    bool didWork = fontDataToDelete.size();

    fontDataToDelete.clear();

    isPurging = false;

    return didWork;
}

} // namespace blink
