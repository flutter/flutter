// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/runtime/test_font_selector.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "flutter/runtime/test_font_data.h"
#include "flutter/sky/engine/platform/fonts/SimpleFontData.h"

namespace blink {

void TestFontSelector::Install() {
  auto font_selector = adoptRef(new TestFontSelector());
  UIDartState::Current()->set_font_selector(font_selector);
}

TestFontSelector::TestFontSelector() = default;

TestFontSelector::~TestFontSelector() = default;

PassRefPtr<FontData> TestFontSelector::getFontData(
    const FontDescription& fontDescription,
    const AtomicString& familyName) {
  if (!test_typeface_) {
    test_typeface_ = SkTypeface::MakeFromStream(GetTestFontData().release());
  }

  bool syntheticBold = (fontDescription.weight() >= FontWeight600 ||
                        fontDescription.isSyntheticBold());
  bool syntheticItalic =
      (fontDescription.style() || fontDescription.isSyntheticItalic());
  FontPlatformData platform_data(
      test_typeface_, GetTestFontFamilyName().c_str(),
      fontDescription.effectiveFontSize(), syntheticBold, syntheticItalic,
      fontDescription.orientation(), fontDescription.useSubpixelPositioning());

  return SimpleFontData::create(platform_data, CustomFontData::create());
}

void TestFontSelector::willUseFontData(const FontDescription&,
                                       const AtomicString& familyName,
                                       UChar32) {}

unsigned TestFontSelector::version() const {
  return 0;
}

void TestFontSelector::fontCacheInvalidated() {}

}  // namespace blink
