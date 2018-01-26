// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "txt/asset_font_style_set.h"
#include "lib/fxl/logging.h"

namespace txt {

AssetFontStyleSet::AssetFontStyleSet() = default;

AssetFontStyleSet::~AssetFontStyleSet() = default;

void AssetFontStyleSet::registerTypeface(sk_sp<SkTypeface> typeface) {
  if (typeface == nullptr) {
    return;
  }
  typefaces_.emplace_back(std::move(typeface));
}

int AssetFontStyleSet::count() {
  return typefaces_.size();
}

void AssetFontStyleSet::getStyle(int index, SkFontStyle*, SkString* style) {
  FXL_DCHECK(false);
}

SkTypeface* AssetFontStyleSet::createTypeface(int index) {
  auto index_cast = static_cast<size_t>(index);
  if (index_cast >= typefaces_.size()) {
    return nullptr;
  }
  return typefaces_[index_cast].get();
}

SkTypeface* AssetFontStyleSet::matchStyle(const SkFontStyle& pattern) {
  if (typefaces_.empty())
    return nullptr;

  for (const sk_sp<SkTypeface>& typeface : typefaces_)
    if (typeface->fontStyle() == pattern)
      return typeface.get();

  return typefaces_[0].get();
}

}  // namespace txt
