// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TXT_SRC_TXT_TEST_FONT_MANAGER_H_
#define FLUTTER_TXT_SRC_TXT_TEST_FONT_MANAGER_H_

#include <memory>
#include <string>
#include <vector>

#include "flutter/fml/macros.h"
#include "third_party/skia/include/core/SkFontMgr.h"
#include "txt/asset_font_manager.h"
#include "txt/font_asset_provider.h"

namespace txt {

// A font manager intended for tests that matches all requested fonts using
// one family.
class TestFontManager : public AssetFontManager {
 public:
  TestFontManager(std::unique_ptr<FontAssetProvider> font_provider,
                  std::vector<std::string> test_font_family_names);

  ~TestFontManager() override;

 private:
  std::vector<std::string> test_font_family_names_;

  sk_sp<SkFontStyleSet> onMatchFamily(const char family_name[]) const override;

  FML_DISALLOW_COPY_AND_ASSIGN(TestFontManager);
};

}  // namespace txt

#endif  // FLUTTER_TXT_SRC_TXT_TEST_FONT_MANAGER_H_
