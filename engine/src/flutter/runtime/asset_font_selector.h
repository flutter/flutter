// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_RUNTIME_ASSET_FONT_SELECTOR_H_
#define FLUTTER_RUNTIME_ASSET_FONT_SELECTOR_H_

#include <unordered_map>
#include <vector>

#include "flutter/assets/zip_asset_store.h"
#include "flutter/sky/engine/platform/fonts/FontCacheKey.h"
#include "flutter/sky/engine/platform/fonts/FontSelector.h"
#include "flutter/sky/engine/platform/fonts/SimpleFontData.h"

namespace blink {

// A FontSelector implementation that resolves custon font names to assets
// loaded from the FLX.
class AssetFontSelector : public FontSelector {
 public:
  struct FlutterFontAttributes;

  ~AssetFontSelector() override;

  static void Install(fxl::RefPtr<ZipAssetStore> asset_store);

  PassRefPtr<FontData> getFontData(const FontDescription& font_description,
                                   const AtomicString& family_name) override;

  void willUseFontData(const FontDescription& font_description,
                       const AtomicString& family,
                       UChar32 character) override;

  unsigned version() const override;

  void fontCacheInvalidated() override;

 private:
  struct TypefaceAsset;

  explicit AssetFontSelector(fxl::RefPtr<ZipAssetStore> asset_store);

  void parseFontManifest();

  sk_sp<SkTypeface> getTypefaceAsset(const FontDescription& font_description,
                                     const AtomicString& family_name);

  fxl::RefPtr<ZipAssetStore> asset_store_;

  HashMap<AtomicString, std::vector<FlutterFontAttributes>> font_family_map_;

  std::unordered_map<std::string, std::unique_ptr<TypefaceAsset>>
      typeface_cache_;

  typedef HashMap<FontCacheKey,
                  RefPtr<SimpleFontData>,
                  FontCacheKeyHash,
                  FontCacheKeyTraits>
      FontPlatformDataCache;

  FontPlatformDataCache font_platform_data_cache_;
};

}  // namespace blink

#endif  // FLUTTER_RUNTIME_ASSET_FONT_SELECTOR_H_
