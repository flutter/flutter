/*
 * Copyright (c) 2006, 2007, 2008, 2009 Google Inc. All rights reserved.
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

#include <unicode/locid.h>
#include "flutter/sky/engine/platform/NotImplemented.h"
#include "flutter/sky/engine/platform/fonts/AlternateFontFamily.h"
#include "flutter/sky/engine/platform/fonts/FontCache.h"
#include "flutter/sky/engine/platform/fonts/FontDescription.h"
#include "flutter/sky/engine/platform/fonts/FontFaceCreationParams.h"
#include "flutter/sky/engine/platform/fonts/SimpleFontData.h"
#include "flutter/sky/engine/public/platform/Platform.h"
#include "flutter/sky/engine/wtf/Assertions.h"
#include "flutter/sky/engine/wtf/text/AtomicString.h"
#include "flutter/sky/engine/wtf/text/CString.h"
#include "third_party/skia/include/core/SkStream.h"
#include "third_party/skia/include/core/SkTypeface.h"
#include "third_party/skia/include/ports/SkFontMgr.h"

#if !OS(WIN) && !OS(ANDROID)
#include "third_party/skia/include/ports/SkFontConfigInterface.h"
#endif

namespace blink {

#if !OS(FUCHSIA)

static int toSkiaWeight(FontWeight weight) {
  switch (weight) {
    case FontWeight100:
      return SkFontStyle::kThin_Weight;
    case FontWeight200:
      return SkFontStyle::kExtraLight_Weight;
    case FontWeight300:
      return SkFontStyle::kLight_Weight;
    case FontWeight400:
      return SkFontStyle::kNormal_Weight;
    case FontWeight500:
      return SkFontStyle::kMedium_Weight;
    case FontWeight600:
      return SkFontStyle::kSemiBold_Weight;
    case FontWeight700:
      return SkFontStyle::kBold_Weight;
    case FontWeight800:
      return SkFontStyle::kExtraBold_Weight;
    case FontWeight900:
      return SkFontStyle::kBlack_Weight;
  }
  ASSERT_NOT_REACHED();
  return SkFontStyle::kNormal_Weight;
}

static SkFontStyle::Slant toSkiaSlant(FontStyle style) {
  switch (style) {
    case FontStyleNormal:
      return SkFontStyle::kUpright_Slant;
    case FontStyleItalic:
      return SkFontStyle::kItalic_Slant;
  }
  ASSERT_NOT_REACHED();
  return SkFontStyle::kUpright_Slant;
}

static int toSkiaWidth(FontStretch stretch) {
  // Numeric values matching OS/2 & Windows Metrics usWidthClass table.
  // https://www.microsoft.com/typography/otspec/os2.htm
  return static_cast<int>(stretch);
}

static SkFontStyle toSkiaFontStyle(const FontDescription& fontDescription) {
  return SkFontStyle(toSkiaWeight(fontDescription.weight()),
                     toSkiaWidth(fontDescription.stretch()),
                     toSkiaSlant(fontDescription.style()));
}

#endif  // !OS(FUCHSIA)

void FontCache::platformInit() {}

PassRefPtr<SimpleFontData> FontCache::fallbackOnStandardFontStyle(
    const FontDescription& fontDescription,
    UChar32 character) {
  FontDescription substituteDescription(fontDescription);
  substituteDescription.setStyle(FontStyleNormal);
  substituteDescription.setWeight(FontWeightNormal);

  FontFaceCreationParams creationParams(
      substituteDescription.family().family());
  FontPlatformData* substitutePlatformData =
      getFontPlatformData(substituteDescription, creationParams);
  if (substitutePlatformData &&
      substitutePlatformData->fontContainsCharacter(character)) {
    FontPlatformData platformData = FontPlatformData(*substitutePlatformData);
    platformData.setSyntheticBold(fontDescription.weight() >= FontWeight600);
    platformData.setSyntheticItalic(fontDescription.style() == FontStyleItalic);
    return fontDataFromFontPlatformData(&platformData, DoNotRetain);
  }

  return nullptr;
}

#if !OS(WIN) && !OS(ANDROID) && !OS(IOS)
PassRefPtr<SimpleFontData> FontCache::fallbackFontForCharacter(
    const FontDescription& fontDescription,
    UChar32 c,
    const SimpleFontData*) {
  // First try the specified font with standard style & weight.
  if (fontDescription.style() == FontStyleItalic ||
      fontDescription.weight() >= FontWeight600) {
    RefPtr<SimpleFontData> fontData =
        fallbackOnStandardFontStyle(fontDescription, c);
    if (fontData)
      return fontData;
  }

  FontCache::PlatformFallbackFont fallbackFont;
  FontCache::getFontForCharacter(c, "", &fallbackFont);
  if (fallbackFont.name.isEmpty())
    return nullptr;

  FontFaceCreationParams creationParams;
  creationParams = FontFaceCreationParams(fallbackFont.filename,
                                          fallbackFont.fontconfigInterfaceId,
                                          fallbackFont.ttcIndex);

  // Changes weight and/or italic of given FontDescription depends on
  // the result of fontconfig so that keeping the correct font mapping
  // of the given character. See http://crbug.com/32109 for details.
  bool shouldSetSyntheticBold = false;
  bool shouldSetSyntheticItalic = false;
  FontDescription description(fontDescription);
  if (fallbackFont.isBold && description.weight() < FontWeightBold)
    description.setWeight(FontWeightBold);
  if (!fallbackFont.isBold && description.weight() >= FontWeightBold) {
    shouldSetSyntheticBold = true;
    description.setWeight(FontWeightNormal);
  }
  if (fallbackFont.isItalic && description.style() == FontStyleNormal)
    description.setStyle(FontStyleItalic);
  if (!fallbackFont.isItalic && description.style() == FontStyleItalic) {
    shouldSetSyntheticItalic = true;
    description.setStyle(FontStyleNormal);
  }

  FontPlatformData* substitutePlatformData =
      getFontPlatformData(description, creationParams);
  if (!substitutePlatformData)
    return nullptr;
  FontPlatformData platformData = FontPlatformData(*substitutePlatformData);
  platformData.setSyntheticBold(shouldSetSyntheticBold);
  platformData.setSyntheticItalic(shouldSetSyntheticItalic);
  return fontDataFromFontPlatformData(&platformData, DoNotRetain);
}

#endif  // !OS(WIN) && !OS(ANDROID)

PassRefPtr<SimpleFontData> FontCache::getLastResortFallbackFont(
    const FontDescription& description,
    ShouldRetain shouldRetain) {
  const FontFaceCreationParams fallbackCreationParams(
      getFallbackFontFamily(description));
  const FontPlatformData* fontPlatformData =
      getFontPlatformData(description, fallbackCreationParams);

  // We should at least have Sans or Arial which is the last resort fallback of
  // SkFontHost ports.
  if (!fontPlatformData) {
    DEFINE_STATIC_LOCAL(
        const FontFaceCreationParams, sansCreationParams,
        (AtomicString("Sans", AtomicString::ConstructFromLiteral)));
    fontPlatformData = getFontPlatformData(description, sansCreationParams);
  }
  if (!fontPlatformData) {
    DEFINE_STATIC_LOCAL(
        const FontFaceCreationParams, arialCreationParams,
        (AtomicString("Arial", AtomicString::ConstructFromLiteral)));
    fontPlatformData = getFontPlatformData(description, arialCreationParams);
  }

  ASSERT(fontPlatformData);
  return fontDataFromFontPlatformData(fontPlatformData, shouldRetain);
}

#if !OS(FUCHSIA)
sk_sp<SkTypeface> FontCache::createTypeface(
    const FontDescription& fontDescription,
    const FontFaceCreationParams& creationParams,
    CString& name) {
#if !OS(WIN) && !OS(ANDROID)
  if (creationParams.creationType() == CreateFontByFciIdAndTtcIndex) {
    return SkTypeface::MakeFromFile(creationParams.filename().data());
  }
#endif

  AtomicString family = creationParams.family();
  // If we're creating a fallback font (e.g. "-webkit-monospace"), convert the
  // name into the fallback name (like "monospace") that fontconfig understands.
  if (!family.length() || family.startsWith("-webkit-")) {
    name = getFallbackFontFamily(fontDescription).string().utf8();
  } else {
    // convert the name to utf8
    name = family.utf8();
  }

  SkFontStyle style = toSkiaFontStyle(fontDescription);
  sk_sp<SkFontMgr> fm(SkFontMgr::RefDefault());
  sk_sp<SkTypeface> typeface(fm->matchFamilyStyle(name.data(), style));
  if (typeface)
    return typeface;

  return SkTypeface::MakeFromName(name.data(), style);
}
#endif

#if !OS(WIN)
FontPlatformData* FontCache::createFontPlatformData(
    const FontDescription& fontDescription,
    const FontFaceCreationParams& creationParams,
    float fontSize) {
  CString name;
  sk_sp<SkTypeface> tf = createTypeface(fontDescription, creationParams, name);
  if (!tf)
    return 0;

  FontPlatformData* result = new FontPlatformData(
      tf, name.data(), fontSize,
      (fontDescription.weight() >= FontWeight600 && !tf->isBold()) ||
          fontDescription.isSyntheticBold(),
      (fontDescription.style() && !tf->isItalic()) ||
          fontDescription.isSyntheticItalic(),
      fontDescription.orientation(), fontDescription.useSubpixelPositioning());
  return result;
}
#endif  // !OS(WIN)

}  // namespace blink
