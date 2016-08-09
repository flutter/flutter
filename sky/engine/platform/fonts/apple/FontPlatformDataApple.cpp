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

#include "flutter/sky/engine/platform/fonts/FontPlatformData.h"
#include "third_party/skia/include/core/SkTypeface.h"

namespace blink {

void FontPlatformData::setupPaint(SkPaint* paint,
                                  GraphicsContext* context) const {
  bool shouldSmoothFonts = true;
  bool shouldAntialias = true;
  bool useSubpixelText = true;
  paint->setAntiAlias(shouldAntialias);
  paint->setEmbeddedBitmapText(false);
  const float ts = m_textSize >= 0 ? m_textSize : 12;
  paint->setTextSize(SkFloatToScalar(ts));
  paint->setTypeface(m_typeface);
  paint->setFakeBoldText(m_syntheticBold);
  paint->setTextSkewX(m_syntheticItalic ? -SK_Scalar1 / 4 : 0);
  paint->setAutohinted(false);  // freetype specific
  paint->setLCDRenderText(shouldSmoothFonts);
  paint->setSubpixelText(useSubpixelText);
  paint->setHinting(SkPaint::kNo_Hinting);
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

}  // namespace  blink
