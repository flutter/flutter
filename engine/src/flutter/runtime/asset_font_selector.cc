// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/runtime/asset_font_selector.h"

#include "flutter/assets/zip_asset_store.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "flutter/sky/engine/platform/fonts/FontData.h"
#include "flutter/sky/engine/platform/fonts/FontFaceCreationParams.h"
#include "flutter/sky/engine/platform/fonts/SimpleFontData.h"
#include "lib/fxl/arraysize.h"
#include "third_party/rapidjson/rapidjson/document.h"
#include "third_party/skia/include/core/SkStream.h"
#include "third_party/skia/include/core/SkTypeface.h"
#include "third_party/skia/include/ports/SkFontMgr.h"

namespace blink {

// Style attributes of a Flutter font asset.
struct AssetFontSelector::FlutterFontAttributes {
  FlutterFontAttributes(const std::string& path);
  ~FlutterFontAttributes();
  std::string asset_path;
  int weight;
  FontStyle style;
};

// A Skia typeface along with a buffer holding the raw typeface asset data.
struct AssetFontSelector::TypefaceAsset {
  TypefaceAsset();
  ~TypefaceAsset();
  sk_sp<SkTypeface> typeface;
  std::vector<uint8_t> data;
};

namespace {

const char kFontManifestAssetPath[] = "FontManifest.json";

// Weight values corresponding to the members of the FontWeight enum.
const int kFontWeightValue[] = {100, 200, 300, 400, 500, 600, 700, 800, 900};

const int kFontWeightNormal = kFontWeightValue[FontWeight::FontWeightNormal];

int getFontWeightValue(FontWeight weight) {
  size_t weight_index = weight;
  return (weight_index < arraysize(kFontWeightValue))
             ? kFontWeightValue[weight_index]
             : kFontWeightNormal;
}

// Compares fonts within a family to determine which one most closely matches
// a FontDescription.
struct FontMatcher {
  using FlutterFontAttributes = AssetFontSelector::FlutterFontAttributes;

  FontMatcher(const FontDescription& description)
      : description_(description),
        target_weight_(getFontWeightValue(description.weight())) {}

  bool operator()(const FlutterFontAttributes& font1,
                  const FlutterFontAttributes& font2) {
    if (font1.style != font2.style) {
      if (font1.style == description_.style())
        return true;
      if (font2.style == description_.style())
        return false;
    }

    int weight_delta1 = abs(font1.weight - target_weight_);
    int weight_delta2 = abs(font2.weight - target_weight_);
    return weight_delta1 < weight_delta2;
  }

 private:
  const FontDescription& description_;
  int target_weight_;
};

}  // namespace

void AssetFontSelector::Install(fxl::RefPtr<ZipAssetStore> asset_store) {
  RefPtr<AssetFontSelector> font_selector =
      adoptRef(new AssetFontSelector(std::move(asset_store)));
  font_selector->parseFontManifest();
  UIDartState::Current()->set_font_selector(font_selector);
}

AssetFontSelector::AssetFontSelector(fxl::RefPtr<ZipAssetStore> asset_store)
    : asset_store_(std::move(asset_store)) {}

AssetFontSelector::~AssetFontSelector() {}

AssetFontSelector::TypefaceAsset::TypefaceAsset() {}

AssetFontSelector::TypefaceAsset::~TypefaceAsset() {}

AssetFontSelector::FlutterFontAttributes::FlutterFontAttributes(
    const std::string& path)
    : asset_path(path),
      weight(kFontWeightNormal),
      style(FontStyle::FontStyleNormal) {}

AssetFontSelector::FlutterFontAttributes::~FlutterFontAttributes() {}

void AssetFontSelector::parseFontManifest() {
  std::vector<uint8_t> font_manifest_data;
  if (!asset_store_->GetAsBuffer(kFontManifestAssetPath, &font_manifest_data))
    return;

  rapidjson::Document document;
  document.Parse(reinterpret_cast<const char*>(font_manifest_data.data()),
                 font_manifest_data.size());

  if (document.HasParseError())
    return;

  if (!document.IsArray())
    return;

  for (auto& family : document.GetArray()) {
    if (!family.IsObject())
      continue;

    auto family_name = family.FindMember("family");
    if (family_name == family.MemberEnd() || !family_name->value.IsString())
      continue;

    auto font_list = family.FindMember("fonts");
    if (font_list == family.MemberEnd() || !font_list->value.IsArray())
      continue;

    AtomicString family_key =
        AtomicString::fromUTF8(family_name->value.GetString());
    auto set_result =
        font_family_map_.set(family_key, std::vector<FlutterFontAttributes>());
    std::vector<FlutterFontAttributes>& family_assets =
        set_result.storedValue->value;

    for (auto& list_entry : font_list->value.GetArray()) {
      if (!list_entry.IsObject())
        continue;

      auto asset_path = list_entry.FindMember("asset");
      if (asset_path == list_entry.MemberEnd() || !asset_path->value.IsString())
        continue;

      FlutterFontAttributes attributes(asset_path->value.GetString());

      auto weight = list_entry.FindMember("weight");
      if (weight != list_entry.MemberEnd() && weight->value.IsInt())
        attributes.weight = weight->value.GetInt();

      auto style = list_entry.FindMember("style");
      if (style != list_entry.MemberEnd() && style->value.IsString()) {
        if (std::string(style->value.GetString()) == "italic")
          attributes.style = FontStyle::FontStyleItalic;
      }

      family_assets.push_back(attributes);
    }
  }
}

PassRefPtr<FontData> AssetFontSelector::getFontData(
    const FontDescription& font_description,
    const AtomicString& family_name) {
  FontFaceCreationParams creationParams(family_name);
  FontCacheKey key = font_description.cacheKey(creationParams);
  RefPtr<SimpleFontData> font_data = font_platform_data_cache_.get(key);

  if (font_data == nullptr) {
    sk_sp<SkTypeface> typeface =
        getTypefaceAsset(font_description, family_name);
    if (!typeface)
      return nullptr;

    bool synthetic_bold =
        (font_description.weight() >= FontWeight600 && !typeface->isBold()) ||
        font_description.isSyntheticBold();
    bool synthetic_italic =
        (font_description.style() && !typeface->isItalic()) ||
        font_description.isSyntheticItalic();
    FontPlatformData platform_data(typeface, family_name.utf8().data(),
                                   font_description.effectiveFontSize(),
                                   synthetic_bold, synthetic_italic,
                                   font_description.orientation(),
                                   font_description.useSubpixelPositioning());

    font_data = SimpleFontData::create(platform_data, CustomFontData::create());
    font_platform_data_cache_.set(key, font_data);
  }

  return font_data;
}

sk_sp<SkTypeface> AssetFontSelector::getTypefaceAsset(
    const FontDescription& font_description,
    const AtomicString& family_name) {
  auto family_iter = font_family_map_.find(family_name);
  if (family_iter == font_family_map_.end())
    return nullptr;

  const std::vector<FlutterFontAttributes>& fonts = family_iter->value;
  if (fonts.empty())
    return nullptr;

  std::vector<FlutterFontAttributes>::const_iterator font_iter;
  if (fonts.size() == 1) {
    font_iter = fonts.begin();
  } else {
    font_iter = std::min_element(fonts.begin(), fonts.end(),
                                 FontMatcher(font_description));
  }

  const std::string& asset_path = font_iter->asset_path;
  auto typeface_iter = typeface_cache_.find(asset_path);
  if (typeface_iter != typeface_cache_.end()) {
    const TypefaceAsset* cache_asset = typeface_iter->second.get();
    return cache_asset ? cache_asset->typeface : nullptr;
  }

  std::unique_ptr<TypefaceAsset> typeface_asset(new TypefaceAsset);
  if (!asset_store_->GetAsBuffer(asset_path, &typeface_asset->data)) {
    typeface_cache_.insert(std::make_pair(asset_path, nullptr));
    return nullptr;
  }

  sk_sp<SkFontMgr> font_mgr(SkFontMgr::RefDefault());
  std::unique_ptr<SkStreamAsset> typeface_stream =
      std::make_unique<SkMemoryStream>(typeface_asset->data.data(),
                                       typeface_asset->data.size());
  typeface_asset->typeface =
      font_mgr->makeFromStream(std::move(typeface_stream));
  if (typeface_asset->typeface == nullptr) {
    typeface_cache_.insert(std::make_pair(asset_path, nullptr));
    return nullptr;
  }

  sk_sp<SkTypeface> result = typeface_asset->typeface;
  typeface_cache_.insert(std::make_pair(asset_path, std::move(typeface_asset)));

  return result;
}

void AssetFontSelector::willUseFontData(const FontDescription& font_description,
                                        const AtomicString& family,
                                        UChar32 character) {}

unsigned AssetFontSelector::version() const {
  return 0;
}

void AssetFontSelector::fontCacheInvalidated() {}

}  // namespace blink
