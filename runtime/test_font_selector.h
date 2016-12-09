// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_RUNTIME_TEST_FONT_SELECTOR_H_
#define FLUTTER_RUNTIME_TEST_FONT_SELECTOR_H_

#include "flutter/sky/engine/platform/fonts/FontSelector.h"
#include "flutter/sky/engine/wtf/RefPtr.h"
#include "lib/ftl/macros.h"

namespace blink {

class TestFontSelector : public FontSelector {
 public:
  static void Install();

  ~TestFontSelector() override;

  PassRefPtr<FontData> getFontData(const FontDescription&,
                                   const AtomicString& familyName) override;

  void willUseFontData(const FontDescription&,
                       const AtomicString& familyName,
                       UChar32) override;

  unsigned version() const override;

  void fontCacheInvalidated() override;

 private:
  WTF::RefPtr<FontData> test_font_data_;

  TestFontSelector();

  FTL_DISALLOW_COPY_AND_ASSIGN(TestFontSelector);
};

}  // namespace blink

#endif  // FLUTTER_RUNTIME_TEST_FONT_SELECTOR_H_
