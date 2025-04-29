// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "txt/test_font_manager.h"
#include "flutter/fml/logging.h"

namespace txt {

TestFontManager::TestFontManager(
    std::unique_ptr<FontAssetProvider> font_provider,
    std::vector<std::string> test_font_family_names)
    : AssetFontManager(std::move(font_provider)),
      test_font_family_names_(std::move(test_font_family_names)) {}

TestFontManager::~TestFontManager() = default;

sk_sp<SkFontStyleSet> TestFontManager::onMatchFamily(
    const char family_name[]) const {
  // Find the requested name in the list, if not found, default to the first
  // font family in the test font family list.
  std::string requested_name(family_name);
  std::string sanitized_name = test_font_family_names_[0];
  for (const std::string& test_family : test_font_family_names_) {
    if (requested_name == test_family) {
      sanitized_name = test_family;
    }
  }
  return AssetFontManager::onMatchFamily(sanitized_name.c_str());
}

}  // namespace txt
