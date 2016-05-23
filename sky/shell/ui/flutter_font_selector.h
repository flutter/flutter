// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_UI_FLUTTER_FONT_SELECTOR_H_
#define SKY_SHELL_UI_FLUTTER_FONT_SELECTOR_H_

#include <unordered_map>
#include <vector>

#include "sky/engine/platform/fonts/FontCacheKey.h"
#include "sky/engine/platform/fonts/FontSelector.h"
#include "sky/engine/platform/fonts/SimpleFontData.h"

namespace mojo {
namespace asset_bundle {
class ZipAssetBundle;
}
}

namespace sky {
namespace shell {

// A FontSelector implementation that resolves custon font names to assets
// loaded from the FLX.
class FlutterFontSelector : public blink::FontSelector {
 public:
  struct FlutterFontAttributes;

  ~FlutterFontSelector() override;

  static void install(
      const scoped_refptr<mojo::asset_bundle::ZipAssetBundle>& zip_asset_bundle);

  PassRefPtr<blink::FontData> getFontData(
      const blink::FontDescription& font_description,
      const AtomicString& family_name) override;

  void willUseFontData(const blink::FontDescription& font_description,
                       const AtomicString& family,
                       UChar32 character) override;

  unsigned version() const override;

  void fontCacheInvalidated() override;

 private:
  struct TypefaceAsset;

  FlutterFontSelector(
      const scoped_refptr<mojo::asset_bundle::ZipAssetBundle>& zip_asset_bundle);

  void parseFontManifest();

  sk_sp<SkTypeface> getTypefaceAsset(
      const blink::FontDescription& font_description,
      const AtomicString& family_name);

  scoped_refptr<mojo::asset_bundle::ZipAssetBundle> zip_asset_bundle_;

  HashMap<AtomicString, std::vector<FlutterFontAttributes>> font_family_map_;

  std::unordered_map<std::string, std::unique_ptr<TypefaceAsset>>
      typeface_cache_;

  typedef HashMap<blink::FontCacheKey, RefPtr<blink::SimpleFontData>,
                  blink::FontCacheKeyHash, blink::FontCacheKeyTraits>
      FontPlatformDataCache;

  FontPlatformDataCache font_platform_data_cache_;
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_UI_FLUTTER_FONT_SELECTOR_H_
