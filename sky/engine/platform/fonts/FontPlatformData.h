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

#ifndef SKY_ENGINE_PLATFORM_FONTS_FONTPLATFORMDATA_H_
#define SKY_ENGINE_PLATFORM_FONTS_FONTPLATFORMDATA_H_

#include "flutter/sky/engine/platform/SharedBuffer.h"
#include "flutter/sky/engine/platform/fonts/FontDescription.h"
#include "flutter/sky/engine/platform/fonts/FontOrientation.h"
#include "flutter/sky/engine/platform/fonts/FontRenderStyle.h"
#include "flutter/sky/engine/platform/fonts/opentype/OpenTypeVerticalData.h"
#include "flutter/sky/engine/wtf/Forward.h"
#include "flutter/sky/engine/wtf/HashTableDeletedValueType.h"
#include "flutter/sky/engine/wtf/RefPtr.h"
#include "flutter/sky/engine/wtf/text/CString.h"
#include "flutter/sky/engine/wtf/text/StringImpl.h"
#include "third_party/skia/include/core/SkPaint.h"

class SkTypeface;
typedef uint32_t SkFontID;

namespace blink {

class GraphicsContext;
class HarfBuzzFace;

class PLATFORM_EXPORT FontPlatformData {
 public:
  // Used for deleted values in the font cache's hash tables. The hash table
  // will create us with this structure, and it will compare other values
  // to this "Deleted" one. It expects the Deleted one to be differentiable
  // from the 0 one (created with the empty constructor), so we can't just
  // set everything to 0.
  FontPlatformData(WTF::HashTableDeletedValueType);
  FontPlatformData();
  FontPlatformData(float textSize, bool syntheticBold, bool syntheticItalic);
  FontPlatformData(const FontPlatformData&);
  FontPlatformData(sk_sp<SkTypeface>,
                   const char* name,
                   float textSize,
                   bool syntheticBold,
                   bool syntheticItalic,
                   FontOrientation = Horizontal,
                   bool subpixelTextPosition = defaultUseSubpixelPositioning());
  FontPlatformData(const FontPlatformData& src, float textSize);
  ~FontPlatformData();

  String fontFamilyName() const;
  float size() const { return m_textSize; }
  bool isFixedPitch() const;

  SkTypeface* typeface() const { return m_typeface.get(); }
  HarfBuzzFace* harfBuzzFace() const;
  SkFontID uniqueID() const;
  unsigned hash() const;

  FontOrientation orientation() const { return m_orientation; }
  void setOrientation(FontOrientation orientation) {
    m_orientation = orientation;
  }
  void setSyntheticBold(bool syntheticBold) { m_syntheticBold = syntheticBold; }
  void setSyntheticItalic(bool syntheticItalic) {
    m_syntheticItalic = syntheticItalic;
  }
  bool operator==(const FontPlatformData&) const;
  FontPlatformData& operator=(const FontPlatformData&);
  bool isHashTableDeletedValue() const { return m_isHashTableDeletedValue; }
  bool fontContainsCharacter(UChar32 character);

#if ENABLE(OPENTYPE_VERTICAL)
  PassRefPtr<OpenTypeVerticalData> verticalData() const;
  PassRefPtr<SharedBuffer> openTypeTable(uint32_t table) const;
#endif

#ifndef NDEBUG
  String description() const;
#endif

  // The returned styles are all actual styles without
  // FontRenderStyle::NoPreference.
  const FontRenderStyle& fontRenderStyle() const { return m_style; }
  void setupPaint(SkPaint*, GraphicsContext* = 0) const;

  static void setHinting(SkPaint::Hinting);
  static void setAutoHint(bool);
  static void setUseBitmaps(bool);
  static void setAntiAlias(bool);
  static void setSubpixelRendering(bool);

 private:
  bool static defaultUseSubpixelPositioning();
  void querySystemForRenderStyle(bool useSkiaSubpixelPositioning);

  sk_sp<SkTypeface> m_typeface;
  CString m_family;
  float m_textSize;
  bool m_syntheticBold;
  bool m_syntheticItalic;
  FontOrientation m_orientation;
  FontRenderStyle m_style;
  mutable RefPtr<HarfBuzzFace> m_harfBuzzFace;
  bool m_isHashTableDeletedValue;
};

}  // namespace blink

#endif  // SKY_ENGINE_PLATFORM_FONTS_FONTPLATFORMDATA_H_
