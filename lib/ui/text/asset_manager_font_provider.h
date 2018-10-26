// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_TEXT_ASSET_MANAGER_FONT_PROVIDER_H_
#define FLUTTER_LIB_UI_TEXT_ASSET_MANAGER_FONT_PROVIDER_H_

#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

#include "flutter/assets/asset_manager.h"
#include "flutter/fml/macros.h"
#include "third_party/skia/include/core/SkFontMgr.h"
#include "third_party/skia/include/core/SkTypeface.h"
#include "txt/font_asset_provider.h"

namespace blink {

class AssetManagerFontStyleSet : public SkFontStyleSet {
 public:
  AssetManagerFontStyleSet(std::shared_ptr<blink::AssetManager> asset_manager);

  ~AssetManagerFontStyleSet() override;

  void registerAsset(std::string asset);

  // |SkFontStyleSet|
  int count() override;

  // |SkFontStyleSet|
  void getStyle(int index, SkFontStyle*, SkString* style) override;

  // |SkFontStyleSet|
  SkTypeface* createTypeface(int index) override;

  // |SkFontStyleSet|
  SkTypeface* matchStyle(const SkFontStyle& pattern) override;

 private:
  std::shared_ptr<blink::AssetManager> asset_manager_;

  struct TypefaceAsset {
    TypefaceAsset(std::string a) : asset(std::move(a)) {}
    std::string asset;
    sk_sp<SkTypeface> typeface;
  };
  std::vector<TypefaceAsset> assets_;

  FML_DISALLOW_COPY_AND_ASSIGN(AssetManagerFontStyleSet);
};

class AssetManagerFontProvider : public txt::FontAssetProvider {
 public:
  AssetManagerFontProvider(std::shared_ptr<blink::AssetManager> asset_manager);

  ~AssetManagerFontProvider() override;

  void RegisterAsset(std::string family_name, std::string asset);

  // |FontAssetProvider|
  size_t GetFamilyCount() const override;

  // |FontAssetProvider|
  std::string GetFamilyName(int index) const override;

  // |FontAssetProvider|
  SkFontStyleSet* MatchFamily(const std::string& family_name) override;

 private:
  std::shared_ptr<AssetManager> asset_manager_;
  std::unordered_map<std::string, AssetManagerFontStyleSet>
      registered_families_;
  std::vector<std::string> family_names_;

  FML_DISALLOW_COPY_AND_ASSIGN(AssetManagerFontProvider);
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_TEXT_ASSET_MANAGER_FONT_PROVIDER_H_
