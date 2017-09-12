/*
 * Copyright (c) 2017 Google Inc. All rights reserved.
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

#include "flutter/sky/engine/platform/fonts/FontCache.h"

#include "flutter/sky/engine/platform/Language.h"
#include "flutter/sky/engine/platform/fonts/FontDescription.h"
#include "flutter/sky/engine/platform/fonts/FontFaceCreationParams.h"
#include "flutter/sky/engine/platform/fonts/SimpleFontData.h"
#include "flutter/sky/engine/platform/text/LocaleToScriptMapping.h"
#include "third_party/skia/include/core/SkTypeface.h"
#include "third_party/skia/include/ports/SkFontMgr.h"

namespace blink {

// SkFontMgr requires script-based locale names, like "zh-Hant" and "zh-Hans",
// instead of "zh-CN" and "zh-TW".
static CString toSkFontMgrLocale(const String& locale) {
  if (!locale.startsWith("zh", TextCaseInsensitive))
    return locale.ascii();
  switch (localeToScriptCodeForFontSelection(locale)) {
    case USCRIPT_SIMPLIFIED_HAN:
      return "zh-Hans";
    case USCRIPT_TRADITIONAL_HAN:
      return "zh-Hant";
    default:
      return locale.ascii();
  }
}

static AtomicString getFamilyNameForCharacter(
    UChar32 c,
    const FontDescription& fontDescription) {
  sk_sp<SkFontMgr> fm(SkFontMgr::RefDefault());
  const char* bcp47Locales[2];
  int localeCount = 0;
  CString defaultLocale = toSkFontMgrLocale(defaultLanguage());
  bcp47Locales[localeCount++] = defaultLocale.data();
  CString fontLocale;
  if (!fontDescription.locale().isEmpty()) {
    fontLocale = toSkFontMgrLocale(fontDescription.locale());
    bcp47Locales[localeCount++] = fontLocale.data();
  }
  sk_sp<SkTypeface> typeface(fm->matchFamilyStyleCharacter(
      0, SkFontStyle(), bcp47Locales, localeCount, c));
  if (!typeface)
    return emptyAtom;

  SkString skiaFamilyName;
  typeface->getFamilyName(&skiaFamilyName);
  return skiaFamilyName.c_str();
}

PassRefPtr<SimpleFontData> FontCache::fallbackFontForCharacter(
    const FontDescription& fontDescription,
    UChar32 c,
    const SimpleFontData*) {
  AtomicString familyName = getFamilyNameForCharacter(c, fontDescription);
  if (familyName.isEmpty())
    return getLastResortFallbackFont(fontDescription, DoNotRetain);
  return fontDataFromFontPlatformData(
      getFontPlatformData(fontDescription, FontFaceCreationParams(familyName)),
      DoNotRetain);
}

}  // namespace blink
