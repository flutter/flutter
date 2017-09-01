// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "txt/asset_font_style_set.h"
#include "lib/ftl/logging.h"

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
  FTL_DCHECK(false);
}

SkTypeface* AssetFontStyleSet::createTypeface(int index) {
  auto index_cast = static_cast<size_t>(index);
  if (index_cast >= typefaces_.size()) {
    return nullptr;
  }
  return typefaces_[index_cast].get();
}

SkTypeface* AssetFontStyleSet::matchStyle(const SkFontStyle& pattern) {
  FTL_DCHECK(false);
  return nullptr;
}

}  // namespace txt
