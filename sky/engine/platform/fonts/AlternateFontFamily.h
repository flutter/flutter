/*
 * Copyright (C) 2006, 2008 Apple Inc. All rights reserved.
 * Copyright (C) 2007 Nicholas Shanks <webkit@nickshanks.com>
 * Copyright (C) 2013 Google, Inc. All rights reserved.
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

#ifndef SKY_ENGINE_PLATFORM_FONTS_ALTERNATEFONTFAMILY_H_
#define SKY_ENGINE_PLATFORM_FONTS_ALTERNATEFONTFAMILY_H_

#include "flutter/sky/engine/platform/fonts/FontDescription.h"
#include "flutter/sky/engine/wtf/text/AtomicString.h"

namespace blink {

// We currently do not support bitmap fonts on windows.
// Instead of trying to construct a bitmap font and then going down the fallback
// path map certain common bitmap fonts to their truetype equivalent up front.
inline const AtomicString& adjustFamilyNameToAvoidUnsupportedFonts(
    const AtomicString& familyName) {
  return familyName;
}

inline const AtomicString& alternateFamilyName(const AtomicString& familyName) {
  // Alias Courier <-> Courier New
  DEFINE_STATIC_LOCAL(AtomicString, courier,
                      ("Courier", AtomicString::ConstructFromLiteral));
  DEFINE_STATIC_LOCAL(AtomicString, courierNew,
                      ("Courier New", AtomicString::ConstructFromLiteral));
  if (equalIgnoringCase(familyName, courier))
    return courierNew;
  // On Windows, Courier New (truetype font) is always present and
  // Courier is a bitmap font. So, we don't want to map Courier New to
  // Courier.
  if (equalIgnoringCase(familyName, courierNew))
    return courier;

  // Alias Times and Times New Roman.
  DEFINE_STATIC_LOCAL(AtomicString, times,
                      ("Times", AtomicString::ConstructFromLiteral));
  DEFINE_STATIC_LOCAL(AtomicString, timesNewRoman,
                      ("Times New Roman", AtomicString::ConstructFromLiteral));
  if (equalIgnoringCase(familyName, times))
    return timesNewRoman;
  if (equalIgnoringCase(familyName, timesNewRoman))
    return times;

  // Alias Arial and Helvetica
  DEFINE_STATIC_LOCAL(AtomicString, arial,
                      ("Arial", AtomicString::ConstructFromLiteral));
  DEFINE_STATIC_LOCAL(AtomicString, helvetica,
                      ("Helvetica", AtomicString::ConstructFromLiteral));
  if (equalIgnoringCase(familyName, arial))
    return helvetica;
  if (equalIgnoringCase(familyName, helvetica))
    return arial;

  return emptyAtom;
}

inline const AtomicString getFallbackFontFamily(
    const FontDescription& description) {
  DEFINE_STATIC_LOCAL(const AtomicString, sansStr,
                      ("sans-serif", AtomicString::ConstructFromLiteral));
  DEFINE_STATIC_LOCAL(const AtomicString, serifStr,
                      ("serif", AtomicString::ConstructFromLiteral));
  DEFINE_STATIC_LOCAL(const AtomicString, monospaceStr,
                      ("monospace", AtomicString::ConstructFromLiteral));
  DEFINE_STATIC_LOCAL(const AtomicString, cursiveStr,
                      ("cursive", AtomicString::ConstructFromLiteral));
  DEFINE_STATIC_LOCAL(const AtomicString, fantasyStr,
                      ("fantasy", AtomicString::ConstructFromLiteral));

  switch (description.genericFamily()) {
    case FontDescription::SansSerifFamily:
      return sansStr;
    case FontDescription::SerifFamily:
      return serifStr;
    case FontDescription::MonospaceFamily:
      return monospaceStr;
    case FontDescription::CursiveFamily:
      return cursiveStr;
    case FontDescription::FantasyFamily:
      return fantasyStr;
    default:
      // Let the caller use the system default font.
      return emptyAtom;
  }
}

}  // namespace blink

#endif  // SKY_ENGINE_PLATFORM_FONTS_ALTERNATEFONTFAMILY_H_
