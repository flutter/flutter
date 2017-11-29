/*
 * Copyright (C) 2006, 2008 Apple Inc. All rights reserved.
 * Copyright (C) 2007 Nicholas Shanks <webkit@nickshanks.com>
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 * 3.  Neither the name of Apple Computer, Inc. ("Apple") nor the names of
 *     its contributors may be used to endorse or promote products derived
 *     from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "flutter/sky/engine/platform/fonts/FontCache.h"

#include "flutter/sky/engine/platform/fonts/AlternateFontFamily.h"
#include "flutter/sky/engine/platform/fonts/FontCacheClient.h"
#include "flutter/sky/engine/platform/fonts/FontCacheKey.h"
#include "flutter/sky/engine/platform/fonts/FontDataCache.h"
#include "flutter/sky/engine/platform/fonts/FontDescription.h"
#include "flutter/sky/engine/platform/fonts/FontFallbackList.h"
#include "flutter/sky/engine/platform/fonts/FontPlatformData.h"
#include "flutter/sky/engine/platform/fonts/FontSmoothingMode.h"
#include "flutter/sky/engine/platform/fonts/TextRenderingMode.h"
#include "flutter/sky/engine/platform/fonts/opentype/OpenTypeVerticalData.h"
#include "flutter/sky/engine/wtf/HashMap.h"
#include "flutter/sky/engine/wtf/ListHashSet.h"
#include "flutter/sky/engine/wtf/StdLibExtras.h"
#include "flutter/sky/engine/wtf/Vector.h"
#include "flutter/sky/engine/wtf/text/AtomicStringHash.h"
#include "flutter/sky/engine/wtf/text/StringHash.h"

using namespace WTF;

namespace blink {

#if !OS(WIN)
FontCache::FontCache() : m_purgePreventCount(0) {}
#endif

typedef HashMap<FontCacheKey,
                OwnPtr<FontPlatformData>,
                FontCacheKeyHash,
                FontCacheKeyTraits>
    FontPlatformDataCache;

static FontPlatformDataCache* gFontPlatformDataCache = 0;

#if OS(WIN)
bool FontCache::s_useDirectWrite = false;
IDWriteFactory* FontCache::s_directWriteFactory = 0;
bool FontCache::s_useSubpixelPositioning = false;
float FontCache::s_deviceScaleFactor = 1.0;
#endif

FontCache* FontCache::fontCache() {
  DEFINE_STATIC_LOCAL(FontCache, globalFontCache, ());
  return &globalFontCache;
}

FontPlatformData* FontCache::getFontPlatformData(
    const FontDescription& fontDescription,
    const FontFaceCreationParams& creationParams,
    bool checkingAlternateName) {
  if (!gFontPlatformDataCache) {
    gFontPlatformDataCache = new FontPlatformDataCache;
    platformInit();
  }

  FontCacheKey key = fontDescription.cacheKey(creationParams);
  FontPlatformData* result = 0;
  bool foundResult;
  FontPlatformDataCache::iterator it = gFontPlatformDataCache->find(key);
  if (it == gFontPlatformDataCache->end()) {
    result = createFontPlatformData(fontDescription, creationParams,
                                    fontDescription.effectiveFontSize());
    gFontPlatformDataCache->set(key, adoptPtr(result));
    foundResult = result;
  } else {
    result = it->value.get();
    foundResult = true;
  }

  if (!foundResult && !checkingAlternateName &&
      creationParams.creationType() == CreateFontByFamily) {
    // We were unable to find a font. We have a small set of fonts that we alias
    // to other names, e.g., Arial/Helvetica, Courier/Courier New, etc. Try
    // looking up the font under the aliased name.
    const AtomicString& alternateName =
        alternateFamilyName(creationParams.family());
    if (!alternateName.isEmpty()) {
      FontFaceCreationParams createByAlternateFamily(alternateName);
      result =
          getFontPlatformData(fontDescription, createByAlternateFamily, true);
    }
    if (result)
      gFontPlatformDataCache->set(
          key, adoptPtr(new FontPlatformData(
                   *result)));  // Cache the result under the old name.
  }

  return result;
}

#if ENABLE(OPENTYPE_VERTICAL)
typedef HashMap<FontCache::FontFileKey,
                RefPtr<OpenTypeVerticalData>,
                IntHash<FontCache::FontFileKey>,
                UnsignedWithZeroKeyHashTraits<FontCache::FontFileKey>>
    FontVerticalDataCache;

FontVerticalDataCache& fontVerticalDataCacheInstance() {
  DEFINE_STATIC_LOCAL(FontVerticalDataCache, fontVerticalDataCache, ());
  return fontVerticalDataCache;
}

PassRefPtr<OpenTypeVerticalData> FontCache::getVerticalData(
    const FontFileKey& key,
    const FontPlatformData& platformData) {
  FontVerticalDataCache& fontVerticalDataCache =
      fontVerticalDataCacheInstance();
  FontVerticalDataCache::iterator result = fontVerticalDataCache.find(key);
  if (result != fontVerticalDataCache.end())
    return result.get()->value;

  RefPtr<OpenTypeVerticalData> verticalData =
      OpenTypeVerticalData::create(platformData);
  if (!verticalData->isOpenType())
    verticalData.clear();
  fontVerticalDataCache.set(key, verticalData);
  return verticalData;
}
#endif

static FontDataCache* gFontDataCache = 0;

PassRefPtr<SimpleFontData> FontCache::getFontData(
    const FontDescription& fontDescription,
    const AtomicString& family,
    bool checkingAlternateName,
    ShouldRetain shouldRetain) {
  if (FontPlatformData* platformData = getFontPlatformData(
          fontDescription,
          FontFaceCreationParams(
              adjustFamilyNameToAvoidUnsupportedFonts(family)),
          checkingAlternateName))
    return fontDataFromFontPlatformData(platformData, shouldRetain);

  return nullptr;
}

PassRefPtr<SimpleFontData> FontCache::fontDataFromFontPlatformData(
    const FontPlatformData* platformData,
    ShouldRetain shouldRetain) {
  if (!gFontDataCache)
    gFontDataCache = new FontDataCache;

#if ENABLE(ASSERT)
  if (shouldRetain == DoNotRetain)
    ASSERT(m_purgePreventCount);
#endif

  return gFontDataCache->get(platformData, shouldRetain);
}

bool FontCache::isPlatformFontAvailable(const FontDescription& fontDescription,
                                        const AtomicString& family) {
  bool checkingAlternateName = true;
  return getFontPlatformData(
      fontDescription,
      FontFaceCreationParams(adjustFamilyNameToAvoidUnsupportedFonts(family)),
      checkingAlternateName);
}

SimpleFontData* FontCache::getNonRetainedLastResortFallbackFont(
    const FontDescription& fontDescription) {
  return getLastResortFallbackFont(fontDescription, DoNotRetain).leakRef();
}

void FontCache::releaseFontData(const SimpleFontData* fontData) {
  ASSERT(gFontDataCache);

  gFontDataCache->release(fontData);
}

static inline void purgePlatformFontDataCache() {
  if (!gFontPlatformDataCache)
    return;

  Vector<FontCacheKey> keysToRemove;
  keysToRemove.reserveInitialCapacity(gFontPlatformDataCache->size());
  FontPlatformDataCache::iterator platformDataEnd =
      gFontPlatformDataCache->end();
  for (FontPlatformDataCache::iterator platformData =
           gFontPlatformDataCache->begin();
       platformData != platformDataEnd; ++platformData) {
    if (platformData->value &&
        !gFontDataCache->contains(platformData->value.get()))
      keysToRemove.append(platformData->key);
  }
  gFontPlatformDataCache->removeAll(keysToRemove);
}

static inline void purgeFontVerticalDataCache() {
#if ENABLE(OPENTYPE_VERTICAL)
  FontVerticalDataCache& fontVerticalDataCache =
      fontVerticalDataCacheInstance();
  if (!fontVerticalDataCache.isEmpty()) {
    // Mark & sweep unused verticalData
    FontVerticalDataCache::iterator verticalDataEnd =
        fontVerticalDataCache.end();
    for (FontVerticalDataCache::iterator verticalData =
             fontVerticalDataCache.begin();
         verticalData != verticalDataEnd; ++verticalData) {
      if (verticalData->value)
        verticalData->value->setInFontCache(false);
    }

    gFontDataCache->markAllVerticalData();

    Vector<FontCache::FontFileKey> keysToRemove;
    keysToRemove.reserveInitialCapacity(fontVerticalDataCache.size());
    for (FontVerticalDataCache::iterator verticalData =
             fontVerticalDataCache.begin();
         verticalData != verticalDataEnd; ++verticalData) {
      if (!verticalData->value || !verticalData->value->inFontCache())
        keysToRemove.append(verticalData->key);
    }
    fontVerticalDataCache.removeAll(keysToRemove);
  }
#endif
}

void FontCache::purge(PurgeSeverity PurgeSeverity) {
  // We should never be forcing the purge while the FontCachePurgePreventer is
  // in scope.
  ASSERT(!m_purgePreventCount || PurgeSeverity == PurgeIfNeeded);
  if (m_purgePreventCount)
    return;

  if (!gFontDataCache || !gFontDataCache->purge(PurgeSeverity))
    return;

  purgePlatformFontDataCache();
  purgeFontVerticalDataCache();
}

static bool invalidateFontCache = false;

HashSet<RawPtr<FontCacheClient>>& fontCacheClients() {
  DEFINE_STATIC_LOCAL(OwnPtr<HashSet<RawPtr<FontCacheClient>>>, clients,
                      (adoptPtr(new HashSet<RawPtr<FontCacheClient>>())));
  invalidateFontCache = true;
  return *clients;
}

void FontCache::addClient(FontCacheClient* client) {
  ASSERT(!fontCacheClients().contains(client));
  fontCacheClients().add(client);
}

#if !ENABLE(OILPAN)
void FontCache::removeClient(FontCacheClient* client) {
  ASSERT(fontCacheClients().contains(client));
  fontCacheClients().remove(client);
}
#endif

static unsigned short gGeneration = 0;

unsigned short FontCache::generation() {
  return gGeneration;
}

void FontCache::invalidate() {
  if (!invalidateFontCache) {
    ASSERT(!gFontPlatformDataCache);
    return;
  }

  if (gFontPlatformDataCache) {
    delete gFontPlatformDataCache;
    gFontPlatformDataCache = new FontPlatformDataCache;
  }

  gGeneration++;

  Vector<RefPtr<FontCacheClient>> clients;
  size_t numClients = fontCacheClients().size();
  clients.reserveInitialCapacity(numClients);
  HashSet<RawPtr<FontCacheClient>>::iterator end = fontCacheClients().end();
  for (HashSet<RawPtr<FontCacheClient>>::iterator it =
           fontCacheClients().begin();
       it != end; ++it)
    clients.append(*it);

  ASSERT(numClients == clients.size());
  for (size_t i = 0; i < numClients; ++i)
    clients[i]->fontCacheInvalidated();

  purge(ForcePurge);
}

}  // namespace blink
