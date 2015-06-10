/*
 * Copyright (c) 2006, 2007, 2008, Google Inc. All rights reserved.
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

#include "base/logging.h"
#include "sky/engine/config.h"
#include "sky/engine/platform/fonts/FontPlatformData.h"
#include "sky/engine/platform/fonts/FontCache.h"

namespace blink {

void FontPlatformData::setupPaint(SkPaint* paint,
                                  GraphicsContext* context) const {
  paint->setAntiAlias(m_style.useAntiAlias);
  paint->setHinting(static_cast<SkPaint::Hinting>(m_style.hintStyle));
  paint->setEmbeddedBitmapText(m_style.useBitmaps);
  paint->setAutohinted(m_style.useAutoHint);
  if (m_style.useAntiAlias)
    paint->setLCDRenderText(m_style.useSubpixelRendering);
  paint->setSubpixelText(m_style.useSubpixelPositioning);
  const float ts = m_textSize >= 0 ? m_textSize : 12;
  paint->setTextSize(SkFloatToScalar(ts));
  paint->setTypeface(m_typeface.get());
  paint->setFakeBoldText(m_syntheticBold);
  paint->setTextSkewX(m_syntheticItalic ? -SK_Scalar1 / 4 : 0);
}

void FontPlatformData::querySystemForRenderStyle(
    bool useSkiaSubpixelPositioning) {
  if (!m_style.useHinting)
    m_style.hintStyle = SkPaint::kNo_Hinting;
  else if (m_style.useHinting == FontRenderStyle::NoPreference)
    m_style.hintStyle = SkPaint::kNormal_Hinting;
  if (m_style.useBitmaps == FontRenderStyle::NoPreference)
    m_style.useBitmaps = true;
  if (m_style.useAutoHint == FontRenderStyle::NoPreference)
    m_style.useAutoHint = true;
  if (m_style.useAntiAlias == FontRenderStyle::NoPreference)
    m_style.useAntiAlias = true;
  if (m_style.useSubpixelRendering == FontRenderStyle::NoPreference)
    m_style.useSubpixelRendering = false;
  if (m_style.useSubpixelPositioning == FontRenderStyle::NoPreference)
    m_style.useSubpixelPositioning = useSkiaSubpixelPositioning;
}

bool FontPlatformData::defaultUseSubpixelPositioning() {
  return false;
}

void FontCache::getFontForCharacter(
    UChar32 c,
    const char* preferredLocale,
    FontCache::PlatformFallbackFont* fallbackFont) {
  DCHECK(false);
}

}  // namespace blink
