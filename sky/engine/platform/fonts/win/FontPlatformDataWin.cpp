/*
 * Copyright (C) 2006, 2007 Apple Computer, Inc.
 * Copyright (c) 2006, 2007, 2008, 2009, 2012 Google Inc. All rights reserved.
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

#include "flutter/sky/engine/wtf/OperatingSystem.h"
#include "platform/fonts/FontPlatformData.h"

#include <windows.h>
#include "SkTypeface.h"
#include "platform/fonts/FontCache.h"
#include "platform/graphics/GraphicsContext.h"

namespace blink {

// Maximum font size, in pixels, at which embedded bitmaps will be used
// if available.
const float kMaxSizeForEmbeddedBitmap = 24.0f;

void FontPlatformData::setupPaint(SkPaint* paint,
                                  GraphicsContext* context) const {
  const float ts = m_textSize >= 0 ? m_textSize : 12;
  paint->setTextSize(SkFloatToScalar(m_textSize));
  paint->setTypeface(m_typeface);
  paint->setFakeBoldText(m_syntheticBold);
  paint->setTextSkewX(m_syntheticItalic ? -SK_Scalar1 / 4 : 0);

  uint32_t textFlags = paintTextFlags();
  uint32_t flags = paint->getFlags();
  static const uint32_t textFlagsMask = SkPaint::kAntiAlias_Flag |
                                        SkPaint::kLCDRenderText_Flag;
  flags &= ~textFlagsMask;

  if (ts <= kMaxSizeForEmbeddedBitmap)
    flags |= SkPaint::kEmbeddedBitmapText_Flag;

  if (ts >= m_minSizeForAntiAlias) {
    if (m_useSubpixelPositioning
        // Disable subpixel text for certain older fonts at smaller sizes as
        // they tend to get quite blurry at non-integer sizes and positions.
        // For high-DPI this workaround isn't required.
        && (ts >= m_minSizeForSubpixel ||
            FontCache::fontCache()->deviceScaleFactor() >= 1.5)

        // Subpixel text positioning looks pretty bad without font
        // smoothing. Disable it unless some type of font smoothing is used.
        // As most tests run without font smoothing we enable it for tests
        // to ensure we get good test coverage matching the more common
        // smoothing enabled behavior.
        && (textFlags & SkPaint::kAntiAlias_Flag))
      flags |= SkPaint::kSubpixelText_Flag;

    SkASSERT(!(textFlags & ~textFlagsMask));
    flags |= textFlags;
  }

  paint->setFlags(flags);
}

// Lookup the current system settings for font smoothing.
// We cache these values for performance, but if the browser has a way to be
// notified when these change, we could re-query them at that time.
static uint32_t getSystemTextFlags() {
  static bool gInited;
  static uint32_t gFlags;
  if (!gInited) {
    BOOL enabled;
    gFlags = 0;
    if (SystemParametersInfo(SPI_GETFONTSMOOTHING, 0, &enabled, 0)) {
      if (enabled) {
        gFlags |= SkPaint::kAntiAlias_Flag;

        UINT smoothType;
        if (SystemParametersInfo(SPI_GETFONTSMOOTHINGTYPE, 0, &smoothType, 0)) {
          if (FE_FONTSMOOTHINGCLEARTYPE == smoothType)
            gFlags |= SkPaint::kLCDRenderText_Flag;
        }
      }
    } else {
      // SystemParametersInfo will fail only under full sandbox lockdown on
      // Win8+. So, we default to settings we know are supported and look good.
      // FIXME(eae): We should be querying the DirectWrite settings directly
      // so we can respect the settings for users who turn off smoothing.
      gFlags = SkPaint::kAntiAlias_Flag | SkPaint::kLCDRenderText_Flag;
    }
    gInited = true;
  }
  return gFlags;
}

static bool isWebFont(const String& familyName) {
  // Web-fonts have artifical names constructed to always be:
  // 1. 24 characters, followed by a '\0'
  // 2. the last two characters are '=='
  return familyName.length() == 24 && '=' == familyName[22] &&
         '=' == familyName[23];
}

static int computePaintTextFlags(String fontFamilyName) {
  int textFlags = getSystemTextFlags();

  // Many web-fonts are so poorly hinted that they are terrible to read when
  // drawn in BW. In these cases, we have decided to FORCE these fonts to be
  // drawn with at least grayscale AA, even when the System (getSystemTextFlags)
  // tells us to draw only in BW.
  if (isWebFont(fontFamilyName))
    textFlags |= SkPaint::kAntiAlias_Flag;

  return textFlags;
}

void FontPlatformData::querySystemForRenderStyle(bool) {
  m_paintTextFlags = computePaintTextFlags(fontFamilyName());
}

bool FontPlatformData::defaultUseSubpixelPositioning() {
  return FontCache::fontCache()->useSubpixelPositioning();
}

}  // namespace blink
