// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TXT_ASSET_FONT_STYLE_SET_H_
#define TXT_ASSET_FONT_STYLE_SET_H_

#include <vector>
#include "lib/ftl/macros.h"
#include "third_party/skia/include/core/SkFontStyle.h"
#include "third_party/skia/include/core/SkTypeface.h"
#include "third_party/skia/include/ports/SkFontMgr.h"

namespace txt {

class AssetFontStyleSet : public SkFontStyleSet {
 public:
  AssetFontStyleSet();

  ~AssetFontStyleSet() override;

  void registerTypeface(sk_sp<SkTypeface> typeface);

  // |SkFontStyleSet|
  int count() override;

  // |SkFontStyleSet|
  void getStyle(int index, SkFontStyle*, SkString* style) override;

  // |SkFontStyleSet|
  SkTypeface* createTypeface(int index) override;

  // |SkFontStyleSet|
  SkTypeface* matchStyle(const SkFontStyle& pattern) override;

 private:
  std::vector<sk_sp<SkTypeface>> typefaces_;

  FTL_DISALLOW_COPY_AND_ASSIGN(AssetFontStyleSet);
};

}  // namespace txt

#endif  // TXT_ASSET_FONT_STYLE_SET_H_
