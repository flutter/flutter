/*
 * Copyright (c) 2006, 2007, 2008, 2009, 2010, 2012 Google Inc. All
 * rights reserved.
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

#include "flutter/sky/engine/platform/fonts/win/FontFallbackWin.h"
#include "flutter/sky/engine/wtf/OperatingSystem.h"

#include <unicode/locid.h>
#include <unicode/uchar.h>
#include <limits>
#include "SkFontMgr.h"
#include "SkTypeface.h"
#include "flutter/sky/engine/platform/fonts/FontCache.h"
#include "flutter/sky/engine/wtf/HashMap.h"
#include "flutter/sky/engine/wtf/text/StringHash.h"
#include "flutter/sky/engine/wtf/text/WTFString.h"

namespace blink {

namespace {

static inline bool isFontPresent(const UChar* fontName,
                                 SkFontMgr* fontManager) {
  String family = fontName;
  sk_sp<SkTypeface> tf(
      fontManager->matchFamilyStyle(family.utf8().data(), SkFontStyle()));
  if (!tf)
    return false;

  SkTypeface::LocalizedStrings* actualFamilies = tf->createFamilyNameIterator();
  bool matchesRequestedFamily = false;
  SkTypeface::LocalizedString actualFamily;
  while (actualFamilies->next(&actualFamily)) {
    if (equalIgnoringCase(
            family, AtomicString::fromUTF8(actualFamily.fString.c_str()))) {
      matchesRequestedFamily = true;
      break;
    }
  }
  actualFamilies->unref();

  return matchesRequestedFamily;
}

// A simple mapping from UScriptCode to family name. This is a sparse array,
// which works well since the range of UScriptCode values is small.
typedef const UChar* ScriptToFontMap[USCRIPT_CODE_LIMIT];

void initializeScriptMonospaceFontMap(ScriptToFontMap& scriptFontMap,
                                      SkFontMgr* fontManager) {
  struct FontMap {
    UScriptCode script;
    const UChar* family;
  };

  static const FontMap fontMap[] = {
      {USCRIPT_HEBREW, L"courier new"},
      {USCRIPT_ARABIC, L"courier new"},
  };

  for (size_t i = 0; i < WTF_ARRAY_LENGTH(fontMap); ++i)
    scriptFontMap[fontMap[i].script] = fontMap[i].family;
}

void initializeScriptFontMap(ScriptToFontMap& scriptFontMap,
                             SkFontMgr* fontManager) {
  struct FontMap {
    UScriptCode script;
    const UChar* family;
  };

  static const FontMap fontMap[] = {
      {USCRIPT_LATIN, L"times new roman"},
      {USCRIPT_GREEK, L"times new roman"},
      {USCRIPT_CYRILLIC, L"times new roman"},
      // FIXME: Consider trying new Vista fonts before XP fonts for CJK.
      // Some Vista users do want to use Vista cleartype CJK fonts. If we
      // did, the results of tests with CJK characters would have to be
      // regenerated for Vista.
      {USCRIPT_SIMPLIFIED_HAN, L"simsun"},
      {USCRIPT_TRADITIONAL_HAN, L"pmingliu"},
      {USCRIPT_HIRAGANA, L"ms pgothic"},
      {USCRIPT_KATAKANA, L"ms pgothic"},
      {USCRIPT_KATAKANA_OR_HIRAGANA, L"ms pgothic"},
      {USCRIPT_HANGUL, L"gulim"},
      {USCRIPT_THAI, L"tahoma"},
      {USCRIPT_HEBREW, L"david"},
      {USCRIPT_ARABIC, L"tahoma"},
      {USCRIPT_DEVANAGARI, L"mangal"},
      {USCRIPT_BENGALI, L"vrinda"},
      {USCRIPT_GURMUKHI, L"raavi"},
      {USCRIPT_GUJARATI, L"shruti"},
      {USCRIPT_TAMIL, L"latha"},
      {USCRIPT_TELUGU, L"gautami"},
      {USCRIPT_KANNADA, L"tunga"},
      {USCRIPT_GEORGIAN, L"sylfaen"},
      {USCRIPT_ARMENIAN, L"sylfaen"},
      {USCRIPT_THAANA, L"mv boli"},
      {USCRIPT_CANADIAN_ABORIGINAL, L"euphemia"},
      {USCRIPT_CHEROKEE, L"plantagenet cherokee"},
      {USCRIPT_MONGOLIAN, L"mongolian balti"},
      // For USCRIPT_COMMON, we map blocks to scripts when
      // that makes sense.
  };

  struct ScriptToFontFamilies {
    UScriptCode script;
    const UChar** families;
  };

  // Kartika on Vista or earlier lacks the support for Chillu
  // letters added to Unicode 5.1.
  // Try AnjaliOldLipi (a very widely used Malaylalam font with the full
  // Unicode 5.x support) before falling back to Kartika.
  static const UChar* malayalamFonts[] = {L"AnjaliOldLipi", L"Lohit Malayalam",
                                          L"Kartika", L"Rachana", 0};
  // Try Khmer OS before Vista fonts because 'Khmer OS' goes along better
  // with Latin and looks better/larger for the same size.
  static const UChar* khmerFonts[] = {L"Khmer OS", L"MoolBoran", L"DaunPenh",
                                      L"Code2000", 0};
  // For the following 6 scripts, two or fonts are listed. The fonts in
  // the 1st slot are not available on Windows XP. To support these
  // scripts on XP, listed in the rest of slots are widely used
  // fonts.
  static const UChar* ethiopicFonts[] = {L"Nyala",
                                         L"Abyssinica SIL",
                                         L"Ethiopia Jiret",
                                         L"Visual Geez Unicode",
                                         L"GF Zemen Unicode",
                                         0};
  static const UChar* oriyaFonts[] = {L"Kalinga", L"ori1Uni", L"Lohit Oriya",
                                      0};
  static const UChar* laoFonts[] = {L"DokChampa", L"Saysettha OT",
                                    L"Phetsarath OT", L"Code2000", 0};
  static const UChar* tibetanFonts[] = {L"Microsoft Himalaya", L"Jomolhari",
                                        L"Tibetan Machine Uni", 0};
  static const UChar* sinhalaFonts[] = {L"Iskoola Pota", L"AksharUnicode", 0};
  static const UChar* yiFonts[] = {L"Microsoft Yi Balti", L"Nuosu SIL",
                                   L"Code2000", 0};
  // http://www.bethmardutho.org/support/meltho/download/index.php
  static const UChar* syriacFonts[] = {L"Estrangelo Edessa",
                                       L"Estrangelo Nisibin", L"Code2000", 0};
  // No Myanmar/Burmese font is shipped with Windows, yet. Try a few
  // widely available/used ones that supports Unicode 5.1 or later.
  static const UChar* myanmarFonts[] = {L"Padauk", L"Parabaik", L"Myanmar3",
                                        L"Code2000", 0};

  static const ScriptToFontFamilies scriptToFontFamilies[] = {
      {USCRIPT_MALAYALAM, malayalamFonts},
      {USCRIPT_KHMER, khmerFonts},
      {USCRIPT_ETHIOPIC, ethiopicFonts},
      {USCRIPT_ORIYA, oriyaFonts},
      {USCRIPT_LAO, laoFonts},
      {USCRIPT_TIBETAN, tibetanFonts},
      {USCRIPT_SINHALA, sinhalaFonts},
      {USCRIPT_YI, yiFonts},
      {USCRIPT_SYRIAC, syriacFonts},
      {USCRIPT_MYANMAR, myanmarFonts},
  };

  for (size_t i = 0; i < WTF_ARRAY_LENGTH(fontMap); ++i)
    scriptFontMap[fontMap[i].script] = fontMap[i].family;

  // FIXME: Instead of scanning the hard-coded list, we have to
  // use EnumFont* to 'inspect' fonts to pick up fonts covering scripts
  // when it's possible (e.g. using OS/2 table). If we do that, this
  // had better be pulled out of here.
  for (size_t i = 0; i < WTF_ARRAY_LENGTH(scriptToFontFamilies); ++i) {
    UScriptCode script = scriptToFontFamilies[i].script;
    scriptFontMap[script] = 0;
    const UChar** familyPtr = scriptToFontFamilies[i].families;
    while (*familyPtr) {
      if (isFontPresent(*familyPtr, fontManager)) {
        scriptFontMap[script] = *familyPtr;
        break;
      }
      ++familyPtr;
    }
  }

  // Initialize the locale-dependent mapping.
  // Since Chrome synchronizes the ICU default locale with its UI locale,
  // this ICU locale tells the current UI locale of Chrome.
  icu::Locale locale = icu::Locale::getDefault();
  const UChar* localeFamily = 0;
  if (locale == icu::Locale::getJapanese()) {
    localeFamily = scriptFontMap[USCRIPT_HIRAGANA];
  } else if (locale == icu::Locale::getKorean()) {
    localeFamily = scriptFontMap[USCRIPT_HANGUL];
  } else if (locale == icu::Locale::getTraditionalChinese()) {
    localeFamily = scriptFontMap[USCRIPT_TRADITIONAL_HAN];
  } else {
    // For other locales, use the simplified Chinese font for Han.
    localeFamily = scriptFontMap[USCRIPT_SIMPLIFIED_HAN];
  }
  if (localeFamily)
    scriptFontMap[USCRIPT_HAN] = localeFamily;
}

// There are a lot of characters in USCRIPT_COMMON that can be covered
// by fonts for scripts closely related to them. See
// http://unicode.org/cldr/utility/list-unicodeset.jsp?a=[:Script=Common:]
// FIXME: make this more efficient with a wider coverage
UScriptCode getScriptBasedOnUnicodeBlock(int ucs4) {
  UBlockCode block = ublock_getCode(ucs4);
  switch (block) {
    case UBLOCK_CJK_SYMBOLS_AND_PUNCTUATION:
      return USCRIPT_HAN;
    case UBLOCK_HIRAGANA:
    case UBLOCK_KATAKANA:
      return USCRIPT_HIRAGANA;
    case UBLOCK_ARABIC:
      return USCRIPT_ARABIC;
    case UBLOCK_THAI:
      return USCRIPT_THAI;
    case UBLOCK_GREEK:
      return USCRIPT_GREEK;
    case UBLOCK_DEVANAGARI:
      // For Danda and Double Danda (U+0964, U+0965), use a Devanagari
      // font for now although they're used by other scripts as well.
      // Without a context, we can't do any better.
      return USCRIPT_DEVANAGARI;
    case UBLOCK_ARMENIAN:
      return USCRIPT_ARMENIAN;
    case UBLOCK_GEORGIAN:
      return USCRIPT_GEORGIAN;
    case UBLOCK_KANNADA:
      return USCRIPT_KANNADA;
    default:
      return USCRIPT_COMMON;
  }
}

UScriptCode getScript(int ucs4) {
  UErrorCode err = U_ZERO_ERROR;
  UScriptCode script = uscript_getScript(ucs4, &err);
  // If script is invalid, common or inherited or there's an error,
  // infer a script based on the unicode block of a character.
  if (script <= USCRIPT_INHERITED || U_FAILURE(err))
    script = getScriptBasedOnUnicodeBlock(ucs4);
  return script;
}

}  // namespace

// FIXME: this is font fallback code version 0.1
//  - Cover all the scripts
//  - Get the default font for each script/generic family from the
//    preference instead of hardcoding in the source.
//    (at least, read values from the registry for IE font settings).
//  - Support generic families (from FontDescription)
//  - If the default font for a script is not available,
//    try some more fonts known to support it. Finally, we can
//    use EnumFontFamilies or similar APIs to come up with a list of
//    fonts supporting the script and cache the result.
//  - Consider using UnicodeSet (or UnicodeMap) converted from
//    GLYPHSET (BMP) or directly read from truetype cmap tables to
//    keep track of which character is supported by which font
//  - Update script_font_cache in response to WM_FONTCHANGE

const UChar* getFontFamilyForScript(UScriptCode script,
                                    FontDescription::GenericFamilyType generic,
                                    SkFontMgr* fontManager) {
  static ScriptToFontMap scriptFontMap;
  static ScriptToFontMap scriptMonospaceFontMap;
  static bool initialized = false;
  if (!initialized) {
    initializeScriptFontMap(scriptFontMap, fontManager);
    initializeScriptMonospaceFontMap(scriptMonospaceFontMap, fontManager);
    initialized = true;
  }
  if (script == USCRIPT_INVALID_CODE)
    return 0;
  ASSERT(script < USCRIPT_CODE_LIMIT);
  if (generic == FontDescription::MonospaceFamily &&
      scriptMonospaceFontMap[script])
    return scriptMonospaceFontMap[script];
  return scriptFontMap[script];
}

// FIXME:
//  - Handle 'Inherited', 'Common' and 'Unknown'
//    (see http://www.unicode.org/reports/tr24/#Usage_Model )
//    For 'Inherited' and 'Common', perhaps we need to
//    accept another parameter indicating the previous family
//    and just return it.
//  - All the characters (or characters up to the point a single
//    font can cover) need to be taken into account
const UChar* getFallbackFamily(UChar32 character,
                               FontDescription::GenericFamilyType generic,
                               UScriptCode* scriptChecked,
                               SkFontMgr* fontManager) {
  ASSERT(character);
  UScriptCode script = getScript(character);

  // For the full-width ASCII characters (U+FF00 - U+FF5E), use the font for
  // Han (determined in a locale-dependent way above). Full-width ASCII
  // characters are rather widely used in Japanese and Chinese documents and
  // they're fully covered by Chinese, Japanese and Korean fonts.
  if (0xFF00 < character && character < 0xFF5F)
    script = USCRIPT_HAN;

  if (script == USCRIPT_COMMON)
    script = getScriptBasedOnUnicodeBlock(character);

  const UChar* family = getFontFamilyForScript(script, generic, fontManager);
  // Another lame work-around to cover non-BMP characters.
  // If the font family for script is not found or the character is
  // not in BMP (> U+FFFF), we resort to the hard-coded list of
  // fallback fonts for now.
  if (!family || character > 0xFFFF) {
    int plane = character >> 16;
    switch (plane) {
      case 1:
        family = L"code2001";
        break;
      case 2:
        // Use a Traditional Chinese ExtB font if in Traditional Chinese locale.
        // Otherwise, use a Simplified Chinese ExtB font. Windows Japanese
        // fonts do support a small subset of ExtB (that are included in JIS X
        // 0213), but its coverage is rather sparse. Eventually, this should be
        // controlled by lang/xml:lang.
        if (icu::Locale::getDefault() == icu::Locale::getTraditionalChinese())
          family = L"pmingliu-extb";
        else
          family = L"simsun-extb";
        break;
      default:
        family = L"lucida sans unicode";
    }
  }

  if (scriptChecked)
    *scriptChecked = script;
  return family;
}

}  // namespace blink
