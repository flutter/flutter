/*
 * Copyright (C) 2006, 2008 Apple Computer, Inc.  All rights reserved.
 * Copyright (C) 2007-2008 Torch Mobile, Inc.
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

#ifndef SKY_ENGINE_PLATFORM_FONTS_FONTCACHE_H_
#define SKY_ENGINE_PLATFORM_FONTS_FONTCACHE_H_

#include <limits.h>
#include "flutter/sky/engine/platform/PlatformExport.h"
#include "flutter/sky/engine/platform/fonts/FontFaceCreationParams.h"
#include "flutter/sky/engine/wtf/Forward.h"
#include "flutter/sky/engine/wtf/HashMap.h"
#include "flutter/sky/engine/wtf/PassRefPtr.h"
#include "flutter/sky/engine/wtf/RefPtr.h"
#include "flutter/sky/engine/wtf/text/CString.h"
#include "flutter/sky/engine/wtf/text/WTFString.h"
#include "flutter/sky/engine/wtf/unicode/Unicode.h"
#include "third_party/skia/include/core/SkRefCnt.h"

#if OS(WIN)
#include "SkFontMgr.h"
struct IDWriteFactory;
#endif

#if OS(ANDROID)
#include <unicode/uscript.h>
#endif

class SkTypeface;

namespace blink {

class FontCacheClient;
class FontFaceCreationParams;
class FontPlatformData;
class FontDescription;
class OpenTypeVerticalData;
class SimpleFontData;

enum ShouldRetain { Retain, DoNotRetain };
enum PurgeSeverity { PurgeIfNeeded, ForcePurge };

class PLATFORM_EXPORT FontCache {
  friend class FontCachePurgePreventer;

  WTF_MAKE_NONCOPYABLE(FontCache);
  WTF_MAKE_FAST_ALLOCATED;

 public:
  static FontCache* fontCache();

  void releaseFontData(const SimpleFontData*);

  // This method is implemented by the plaform and used by
  // FontFastPath to lookup the font for a given character.
  PassRefPtr<SimpleFontData> fallbackFontForCharacter(
      const FontDescription&,
      UChar32,
      const SimpleFontData* fontDataToSubstitute);

  // Also implemented by the platform.
  void platformInit();

  PassRefPtr<SimpleFontData> getFontData(const FontDescription&,
                                         const AtomicString&,
                                         bool checkingAlternateName = false,
                                         ShouldRetain = Retain);
  PassRefPtr<SimpleFontData> getLastResortFallbackFont(const FontDescription&,
                                                       ShouldRetain = Retain);
  SimpleFontData* getNonRetainedLastResortFallbackFont(const FontDescription&);
  bool isPlatformFontAvailable(const FontDescription&, const AtomicString&);

  void addClient(FontCacheClient*);
#if !ENABLE(OILPAN)
  void removeClient(FontCacheClient*);
#endif

  unsigned short generation();
  void invalidate();

#if OS(WIN)
  bool useSubpixelPositioning() const { return s_useSubpixelPositioning; }
  SkFontMgr* fontManager() { return m_fontManager.get(); }
  static bool useDirectWrite() { return s_useDirectWrite; }
  static float deviceScaleFactor() { return s_deviceScaleFactor; }
  static void setUseDirectWrite(bool useDirectWrite) {
    s_useDirectWrite = useDirectWrite;
  }
  static void setDirectWriteFactory(IDWriteFactory* factory) {
    s_directWriteFactory = factory;
  }
  static void setDeviceScaleFactor(float deviceScaleFactor) {
    s_deviceScaleFactor = deviceScaleFactor;
  }
  static void setUseSubpixelPositioning(bool useSubpixelPositioning) {
    s_useSubpixelPositioning = useSubpixelPositioning;
  }
  static void addSideloadedFontForTesting(SkTypeface*);
  // Functions to cache and retrieve the system font metrics.
  static void setMenuFontMetrics(const wchar_t* familyName, int32_t fontHeight);
  static void setSmallCaptionFontMetrics(const wchar_t* familyName,
                                         int32_t fontHeight);
  static void setStatusFontMetrics(const wchar_t* familyName,
                                   int32_t fontHeight);
  static int32_t menuFontHeight() { return s_menuFontHeight; }
  static const AtomicString& menuFontFamily() {
    return *s_smallCaptionFontFamilyName;
  }
  static int32_t smallCaptionFontHeight() { return s_smallCaptionFontHeight; }
  static const AtomicString& smallCaptionFontFamily() {
    return *s_smallCaptionFontFamilyName;
  }
  static int32_t statusFontHeight() { return s_statusFontHeight; }
  static const AtomicString& statusFontFamily() {
    return *s_statusFontFamilyName;
  }
#endif

#if ENABLE(OPENTYPE_VERTICAL)
  typedef uint32_t FontFileKey;
  PassRefPtr<OpenTypeVerticalData> getVerticalData(const FontFileKey&,
                                                   const FontPlatformData&);
#endif

#if !OS(ANDROID) && !OS(IOS)
  struct PlatformFallbackFont {
    String name;
    CString filename;
    int fontconfigInterfaceId;
    int ttcIndex;
    bool isBold;
    bool isItalic;
  };
  static void getFontForCharacter(UChar32,
                                  const char* preferredLocale,
                                  PlatformFallbackFont*);
#endif

 private:
  FontCache();
  ~FontCache();

  void purge(PurgeSeverity = PurgeIfNeeded);

  void disablePurging() { m_purgePreventCount++; }
  void enablePurging() {
    ASSERT(m_purgePreventCount);
    if (!--m_purgePreventCount)
      purge(PurgeIfNeeded);
  }

  // FIXME: This method should eventually be removed.
  FontPlatformData* getFontPlatformData(const FontDescription&,
                                        const FontFaceCreationParams&,
                                        bool checkingAlternateName = false);

  // These methods are implemented by each platform.
  FontPlatformData* createFontPlatformData(const FontDescription&,
                                           const FontFaceCreationParams&,
                                           float fontSize);

  // Implemented on skia platforms.
  sk_sp<SkTypeface> createTypeface(const FontDescription&,
                                   const FontFaceCreationParams&,
                                   CString& name);

  PassRefPtr<SimpleFontData> fontDataFromFontPlatformData(
      const FontPlatformData*,
      ShouldRetain = Retain);
  PassRefPtr<SimpleFontData> fallbackOnStandardFontStyle(const FontDescription&,
                                                         UChar32);

  // Don't purge if this count is > 0;
  int m_purgePreventCount;

#if OS(WIN)
  sk_sp<SkFontMgr> m_fontManager;
  static bool s_useDirectWrite;
  static IDWriteFactory* s_directWriteFactory;
  static float s_deviceScaleFactor;
  static bool s_useSubpixelPositioning;
  static HashMap<String, RefPtr<SkTypeface>>* s_sideloadedFonts;
  // The system font metrics cache.
  static AtomicString* s_menuFontFamilyName;
  static int32_t s_menuFontHeight;
  static AtomicString* s_smallCaptionFontFamilyName;
  static int32_t s_smallCaptionFontHeight;
  static AtomicString* s_statusFontFamilyName;
  static int32_t s_statusFontHeight;
#endif

#if OS(ANDROID)
  friend class ComplexTextController;
#endif
  friend class SimpleFontData;  // For fontDataFromFontPlatformData
  friend class FontFallbackList;
};

class PLATFORM_EXPORT FontCachePurgePreventer {
 public:
  FontCachePurgePreventer() { FontCache::fontCache()->disablePurging(); }
  ~FontCachePurgePreventer() { FontCache::fontCache()->enablePurging(); }
};

}  // namespace blink

#endif  // SKY_ENGINE_PLATFORM_FONTS_FONTCACHE_H_
